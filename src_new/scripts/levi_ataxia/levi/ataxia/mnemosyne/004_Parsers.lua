--[[mudlet
type: script
name: Mnemosyne Parsers
hierarchy:
- Levi_Ataxia
- Ataxia
- Mnemosyne
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    MNEMOSYNE RUN TRACKER - GAME-TEXT PARSERS
    ============================================================================
    Turns multi-line game blocks (effects, boons offered) into API payloads.

    Both blocks use a "Name:  <padded>  description" layout inside dashed
    dividers, and descriptions word-wrap onto un-prefixed continuation lines.
    We capture the raw block with a temporary catch-all line trigger (same idea
    as item_catalog's scan), then parse it with pure-Lua string logic that joins
    wrapped continuation lines back onto their entry.

    Gating:
      * onRunStart / onRipple / onGo gate on M._auto() -- they establish or
        bootstrap the run (onRunStart and onRipple both set M.run.active).
      * onMonsters / onEffectsHeader / onBoonsOffered / onBoonClaim gate on
        M._inRun() so the generic-sounding game phrases can't report outside a
        tracked run.

    Depends on 001-003.
    ============================================================================
]]--

ataxia.mnemosyne = ataxia.mnemosyne or {}
local M = ataxia.mnemosyne

-- Longest plausible boon/effect name; a longer "Name:" match is treated as
-- wrapped continuation text rather than a new entry.
local MAX_NAME_LEN = 40

-- A dashed divider line (game uses ~80 dashes; accept 3+ for robustness).
local function isDivider(ln)
  return ln:match("^%-%-%-+") ~= nil
end

-- ---------------------------------------------------------------------------
-- Generic block capture: catch every line until onLine says "stop" (or the
-- timeout fires), then hand the collected lines to onDone.
--   opts.onLine(line) -> "stop" | "skip" | nil
--   opts.timeout      -> seconds of silence before flushing (backstop)
--   opts.onDone(lines)
-- Reentrancy-guarded: only one capture runs at a time.
-- ---------------------------------------------------------------------------
function M._captureLines(opts)
  -- Force-finish a prior capture that is somehow still "in progress" instead of DROPPING this new
  -- block. The single-slot lock used to silently IGNORE a new capture while one was active; if the
  -- prior one ever wedged (e.g. a stream of lines kept resetting its silence timeout so `finish`
  -- never fired), every later boon/effects capture was lost and the report never posted. Flushing
  -- the stale one first guarantees this capture actually runs.
  if M._capturing and M._captureForceFinish then pcall(M._captureForceFinish) end
  M._capturing = true

  local lines, tid, timer = {}, nil, nil
  local done = false

  local function finish()
    if done then return end
    done = true
    M._capturing = false
    M._captureForceFinish = nil
    if tid then pcall(killTrigger, tid) end
    if timer then pcall(killTimer, timer) end
    local ok, err = pcall(opts.onDone, lines)
    if not ok then M.echo("Parse error: " .. tostring(err)) end
  end
  M._captureForceFinish = finish

  local function bump()
    if timer then killTimer(timer) end
    timer = tempTimer(opts.timeout or 1.5, finish)
  end

  tid = tempRegexTrigger([[^.*$]], function()
    local ln = line
    local res = opts.onLine and opts.onLine(ln)
    if res == "stop" then return finish() end
    if res ~= "skip" then table.insert(lines, ln) end
    bump()
  end)
  bump()
  return finish
end

-- Parse "Name:  description" lines into {name, description}, joining wrapped
-- continuation lines (no "Name:" prefix) onto the previous entry.
function M._parseNamedBlock(lines)
  local out = {}
  for _, ln in ipairs(lines) do
    if not (ln:match("^%s*$") or isDivider(ln)) then
      local name, desc = ln:match("^(%S.-):%s%s+(%S.*)$")
      if name and #name <= MAX_NAME_LEN then
        out[#out + 1] = {
          name = name:gsub("%s+$", ""),
          description = desc:gsub("%s+$", ""),
        }
      elseif #out > 0 then
        local cont = ln:match("^%s*(%S.-)%s*$")
        if cont then
          out[#out].description = out[#out].description .. " " .. cont
        end
      end
    end
  end
  return out
end

-- ---------------------------------------------------------------------------
-- Handlers (called by trigger bodies)
-- ---------------------------------------------------------------------------

-- "You whisper to the Mnemosyne and beseech that it grow still for a time."
-- PAUSE: this suspends the current run WITHOUT ending it server-side -- the next wade re-enters
-- the SAME wade. Mark it so onRunStart RESUMES (via /run_exists) instead of minting a brand-new
-- run (which would orphan all the paused run's progress under a fresh public_id). Set the flag
-- unconditionally (like the boon flags); onRunStart consumes it under the _auto() gate.
function M.onRunPause()
  M.run.paused = true
  M.decho("Run paused (beseeched still) -- next wade resumes the same run.")
end

-- "You begin to wade out into the depths of the Mnemosyne..."
function M.onRunStart()
  if not M._auto() then return end
  if M.run.paused then
    -- Re-entering a run we PAUSED: it's the same wade, so resume the existing server run rather
    -- than starting a new one. /run_exists re-syncs active + ripple (and safely no-ops to inactive
    -- if the server no longer has it).
    M.run.paused = nil
    M.runExists()
  else
    M.startRun()
  end
end

-- "The Mnemosyne releases its hold, weaving N shimmering threads into your
-- possession." -- marks the run's end (Mnemosyne is an endless climb with no
-- victory; it ends on true death or WADE LEAVE). BUT this exact reward text ALSO
-- prints verbatim when you re-read the stored Achaea message mid-run, so on its
-- own it can't be trusted -- ending on a re-read would falsely stop telemetry. A
-- real run-end is immediately followed by "You just received message #N from
-- Achaea."; arm a short confirmation window and only commit the end if it fires.
-- Armed regardless of telemetry state: a confirmed run-end both clears bard
-- boons (bardWarmarch) and, if a run is being tracked, ends it -- so the bard
-- flag isn't wrongly cleared on a mid-run re-read either.
function M.onRunEndMaybe()
  if M._runEndTrig then pcall(killTrigger, M._runEndTrig); M._runEndTrig = nil end
  if M._runEndTimer then pcall(killTimer, M._runEndTimer); M._runEndTimer = nil end
  M._runEndTrig = tempRegexTrigger([[^You just received message #\d+ from Achaea\.$]], function()
    if M._runEndTrig then pcall(killTrigger, M._runEndTrig); M._runEndTrig = nil end
    if M._runEndTimer then pcall(killTimer, M._runEndTimer); M._runEndTimer = nil end
    M.onRunEnd()
  end)
  M._runEndTimer = tempTimer(2, function()
    -- No confirmation within 2s -> it was a re-read, not a real end. Drop it.
    if M._runEndTrig then pcall(killTrigger, M._runEndTrig); M._runEndTrig = nil end
    M._runEndTimer = nil
  end)
end

-- Commit the run end (called only once the confirmation above has fired). Clear
-- bard boons unconditionally (independent of telemetry); end the tracked run only
-- if one is active. A normal life-loss death (the /death trigger) keeps it going.
function M.onRunEnd()
  bardWarmarch = false -- boons gone on a confirmed run-end
  mnemSongstep = false -- boons gone on a confirmed run-end
  -- Borrowed Power is per-RUN, and it swapped a paragon out of the armour. Putting it back is
  -- the half that matters: left alone we would quietly bash the whole rest of the day without
  -- the crit paragon. Guarded so it only fires when the boon was actually held.
  if mnemBorrowedPower then
    mnemBorrowedPower = false
    if ataxia and ataxia.armour and ataxia.armour.borrowedPower then
      pcall(ataxia.armour.borrowedPower, false)
    end
  end
  bmShatteredStar = false -- boons gone on a confirmed run-end
  magiKkractle = false -- boons gone on a confirmed run-end
  magiHotSprings = false -- boons gone on a confirmed run-end
  mnemHammerAnvil = false -- boons gone on a confirmed run-end
  bmBladedReflexes = false -- boons gone on a confirmed run-end
  mnemSleuth = false -- boons gone on a confirmed run-end
  mnemRollHide = false -- boons gone on a confirmed run-end
  mnemReaper = false -- boons gone on a confirmed run-end
  mnemBloodscent = false -- boons gone on a confirmed run-end
  mnemKaiUnleashed = false -- boons gone on a confirmed run-end
  mnemSenselessFlurry = false -- boons gone on a confirmed run-end
  psionPanoply = false -- boons gone on a confirmed run-end
  dragonMightSycaerunax = false -- boons gone on a confirmed run-end
  dragonRampage = false -- boons gone on a confirmed run-end
  dwFlashforward = false -- boons gone on a confirmed run-end
  infArmyOfDead = false -- boons gone on a confirmed run-end
  infDaemonJaws = false -- boons gone on a confirmed run-end
  infIndiscriminate = false -- boons gone on a confirmed run-end
  infNecroticAura = false -- boons gone on a confirmed run-end
  infFuryOfAges = false -- boons gone on a confirmed run-end
  mnemWintersHeart = false -- boons gone on a confirmed run-end
  mnemResourceful = false -- boons gone on a confirmed run-end
  mnemFalconersTactics = false -- boons gone on a confirmed run-end
  mnemHomebound = false -- boons gone on a confirmed run-end
  mnemHammerAndNail = false -- boons gone on a confirmed run-end
  mnemRageFuelled = false   -- boons gone on a confirmed run-end
  mnemThunderclap = false   -- boons gone on a confirmed run-end
  mnemStormcleaver = false
  mnemTruthseeker = false
  mnemToughCrowd, mnemElusiveFoolery, mnemApostatic = false, false, false
  mnemDivineThunder = false -- boons gone on a confirmed run-end
  if ataxiaTemp then ataxiaTemp.mnemNulled = nil end
  ataxiaTemp.brFreeCharge = nil -- ...and any charge it had banked
  if ataxiaTemp and ataxiaTemp.infFuryOn then
    -- The boon is gone but FURY may still be running with its quadrupled endurance
    -- cost and no payoff. Turn it off rather than leaving it draining EP.
    ataxiaTemp.infFuryOn = nil
    send("fury off", false)
  end
  mnemHaemophiliac = false -- affixes gone on a confirmed run-end (pacing back to normal)
  mnemLastWord = false -- affixes gone on a confirmed run-end (pacing back to normal)
  mnemBravado = false -- affixes gone on a confirmed run-end (barriers work again)
  mnemTantrum = false -- boons gone on a confirmed run-end
  if M.clearBoonFlags then M.clearBoonFlags() end -- ...and every generically-latched boon
  if ataxiaTemp then
    ataxiaTemp.tantrumRipple = nil
    ataxiaTemp.phialBursts = nil -- the boss phial tally dies with the run
  end
  mnemDeluge = false -- affixes gone on a confirmed run-end (flight available again)
  ataxiaTemp.mnemAblazeAt = nil   -- per-room burn state cannot outlive the run
  if ataxiaTemp then
    ataxiaTemp.reaperKills = nil -- the +1%/kill tally dies with the run
    ataxiaTemp.kaiUnleashedAt = nil -- the burst cooldown stamp dies with it
    ataxiaTemp.kaiChokePendingAt = nil -- ...and the unconfirmed-choke retry guard
  end
  -- Clear the pause flag UNCONDITIONALLY (like the boon flags above), not only via the
  -- _inRun()-gated endRun()->_resetRun(): with telemetry off (the shipped default) that path
  -- never runs, so a paused-then-ended run would leave paused=true and misfire the NEXT fresh
  -- wade into a resume (runExists) that never /run_start's the new run. onRunEnd fires only on the
  -- confirmed end, never between a pause and its same-wade re-wade, so this can't break a resume.
  M.run.paused = nil
  -- The wade lifecycle brackets our presence in the tower, so the confirmed end is the
  -- authoritative "we are out" -- never gmcp's area, which Creville's Legacy (incurable
  -- dementia) can fake into a real place while we are still inside. Cleared here rather than
  -- on the deferred maybe, so a mid-run message re-read cannot drop no-flee. Unconditional
  -- (independent of telemetry), like the boon flags above.
  if ataxiaBasher and ataxiaBasher.inMnemosyne then
    if ataxiaBasher_mnemStillHere then ataxiaBasher_mnemStillHere() end -- drop any pending ask
    -- Through the shared leave hook, not a direct write: it owns the transition guard and
    -- raises "mnemosyne left", which is what releases every tower-only mode (curing profile,
    -- no-flee). A direct clear here would strand them on for the rest of the session.
    -- Nil-guarded like the call above -- it lives in basher/001 and this is a cross-file call;
    -- the fallback still clears the flag so no-flee can never be stranded ON by a load order.
    if ataxiaBasher_mnemLeft then
      ataxiaBasher_mnemLeft("wade ended")
    else
      ataxiaBasher.inMnemosyne = false
      ataxiaEcho("Mnemosyne wade ended -- no-flee mode OFF.")
    end
  end
  M.releaseTreeReserve() -- a boss tree-reserve must not outlive the run
  M.run.boss = nil
  if ataxiaBasher_mnemLdeckReset then ataxiaBasher_mnemLdeckReset() end
  M.restoreTreeCuring() -- Splinterbark over -> tattoo untainted, turn game tree curing back on
  if M._inRun() then M.endRun() end
end

-- Reaper boon (legendary): each denizen kill permanently (for the run) adds +1%
-- damage dealt, announced by "You reap a tithe of power from your fallen foe."
-- (trigger 023). The game never shows the running total, so count the tithes and
-- echo the cumulative bonus after each kill (user spec: "You now have X increased
-- damage total"). The tithe line only prints with Reaper up, so it is its own
-- proof -- seeing it also sets mnemReaper, and a missed claim/BOONS row can't
-- desync the tally. Counter lives in ataxiaTemp so a SYSUPDATE reload mid-run
-- keeps it; reset on run start (trigger 001) + the confirmed run-end above.
function M.onReaperTithe()
  mnemReaper = true
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.reaperKills = (tonumber(ataxiaTemp.reaperKills) or 0) + 1
  local n = ataxiaTemp.reaperKills
  M.echo("<orange>Reaper<reset>: you now have <green>+" .. n .. "%<reset> damage total ("
    .. n .. " kill" .. (n == 1 and "" or "s") .. " this run).")
end

-- Wade-start hook for the Reaper tally, called by trigger 001 BEFORE onRunStart()
-- (which CONSUMES run.paused on a resume). A resume-after-pause wade (WADE STILL ->
-- wade back in) re-enters the SAME server-side run, so the +1%/kill tally must
-- survive it -- the game never prints a running total, so a wiped count is
-- unrecoverable (adversarial-review catch, v4.7.118). Only a genuinely fresh wade
-- resets it. Telemetry-independent, like the boon-flag resets: run.paused is SET
-- unconditionally by onRunPause and cleared unconditionally by the confirmed
-- onRunEnd, so it is a reliable resume marker in both telemetry modes here.
function M.reaperOnWade()
  local resuming = (M.run and M.run.paused) and true or false
  if not resuming and ataxiaTemp then ataxiaTemp.reaperKills = nil end
  return resuming
end

-- Splinterbark ongoing-effect safety (telemetry-INDEPENDENT: driven by a plain status-screen
-- trigger, not the _inRun()-gated affix parse). The "Splinterbark" affix taints our tree tattoo
-- so every touch by the game's curing bleeds us and inflicts a random malady. While it is active
-- we keep the game's tree curing OFF; onRunEnd restores it. Called by the Splinterbark trigger
-- each time the status screen shows the effect; the M._treeCuringOff guard means we send the
-- command only on the OFF transition, not on every status re-read. Gated on inMnemosyne so a
-- `mnem affixes`/library read outside a run cannot toggle curing.
function M.onSplinterbarkSeen()
  if not (ataxiaBasher and ataxiaBasher.inMnemosyne) then return end
  if M._treeCuringOff then return end
  M._treeCuringOff = true
  send("curing tree off")
  if not M._quiet() then
    M.echo("<red>Splinterbark<reset> active -- <red>curing tree off<reset> (tree touch bleeds/afflicts)")
  end
end

-- Haemophiliac ongoing-effect pacing (same telemetry-INDEPENDENT shape as Splinterbark:
-- a plain status-screen trigger, 029). The affix -- "Defeating a denizen causes you to
-- bleed significantly and your mana costs are increased by 20%." -- bleeds THOUSANDS
-- after every kill (live report 2026-07-26). While the flag is set the explorer wades
-- slower: after a room clears, navigation holds until HP recovers (008 _haemoHold).
-- Transition-guarded echo; gated on inMnemosyne so a `mnem affixes` read outside a run
-- cannot arm it. Cleared on run start (trigger 001) + the confirmed run end.
function M.onHaemophiliacSeen()
  if not (ataxiaBasher and ataxiaBasher.inMnemosyne) then return end
  if mnemHaemophiliac then return end
  mnemHaemophiliac = true
  if not M._quiet() then
    M.echo("<red>Haemophiliac<reset> active -- kills bleed heavily; wading slower (moves hold until HP recovers)")
  end
end

-- TANTRUM boon: "Your first battlerage ability per ripple costs no rage."
--
-- Mechanically this is Rage-Fuelled with a different trigger. That one banks a free
-- battlerage per KILL (trigger 340_Slain); this one banks it per RIPPLE. Both are the same
-- STATE -- "one battlerage is free right now" -- so both arm the same
-- `ataxiaTemp.brFreeCharge`, and the entire payoff comes for nothing: `ataxiaBasher_brFree()`
-- already short-circuits all 37 `rageAfford` call sites AND the eight culling-reap gates, and
-- `brCommit`/`brSent` already spend it. Holding BOTH boons is fine and needs no special case;
-- one boolean correctly means "a free battlerage is banked", whichever granted it.
--
-- ARMED ONCE PER RIPPLE, guarded on the ripple NUMBER rather than just fired from onRipple.
-- The flag can be (re-)latched mid-ripple -- `_relatchBoons`, a BOONS-list row, the claim
-- alias -- and re-arming on any of those would hand out a SECOND free battlerage in a ripple
-- where the first was already spent. The guard makes every path idempotent, so the flag
-- handlers can call this freely.
function M.tantrumArm()
  if not mnemTantrum then return end
  if not (ataxiaBasher and ataxiaBasher.inMnemosyne) then return end
  ataxiaTemp = ataxiaTemp or {}
  local r = tonumber(M.run and M.run.ripple) or 0
  if ataxiaTemp.tantrumRipple == r then return end
  ataxiaTemp.tantrumRipple = r
  ataxiaTemp.brFreeCharge = true
  if not M._quiet() then
    M.echo("<green>Tantrum<reset> -- first battlerage this ripple is free")
  end
end

-- Bravado affix: "You are perpetually reckless and unable to benefit from shields, prismatic
-- barriers, or blood barriers." It removes answers rather than adding a threat, which is the
-- more dangerous shape -- `touch shield`, the Maran prismatic barrier and the cloak's blood
-- barrier all keep COSTING while returning nothing, and the basher goes on believing it is
-- covered. Gated at their spend sites on `ataxiaBasher_bravado()`; the swarm hit-and-run
-- threshold clamps to 2 (user rule -- with no mitigations left, "we will never know our
-- health pool"). Same shape as the other affixes.
function M.onBravadoSeen()
  if not (ataxiaBasher and ataxiaBasher.inMnemosyne) then return end
  if mnemBravado then return end
  mnemBravado = true
  if not M._quiet() then
    M.echo("<red>Bravado<reset> active -- shields/prismatic/blood barriers do NOTHING; "
      .. "hit-and-run drops to 2 denizens")
  end
end

-- Last Word affix ("Denizens explode on death!"): the damage arrives at the exact moment
-- the room goes quiet, which is precisely when the sweep wants to walk on. That makes it the
-- same PACING problem as Haemophiliac and it reuses the same post-clear hold -- move only at
-- >= 90% HP (user spec, 2026-08-02), so the next room's fight never starts on a pool the
-- last room's corpse already took a bite out of.
--
-- Note the difference from Haemophiliac despite the shared threshold: haemophiliac damage is
-- a BLEED that SSC clots down, so that hold also waits on `ataxia.vitals.bleed`. An explosion
-- is instantaneous -- there is nothing to clot, only HP to regain. Same telemetry-independent
-- shape as the others: status-row trigger, inMnemosyne gate, transition guard; reset on run
-- start and cleared on the confirmed run end.
function M.onLastWordSeen()
  if not (ataxiaBasher and ataxiaBasher.inMnemosyne) then return end
  if mnemLastWord then return end
  mnemLastWord = true
  if not M._quiet() then
    M.echo("<red>Last Word<reset> active -- denizens explode on death; holding each room until 90% HP")
  end
end

-- Deluge affix ("All rooms are underwater."): FLY is impossible underwater, so the
-- swarm module's escape ladder and fly-kite must take their GROUNDED branches
-- (retreat / shield) instead of wedging on a rejected fly (user report 2026-07-28).
-- Same telemetry-independent shape as Haemophiliac: status-row trigger, inMnemosyne
-- gate, transition guard; reset on run start, cleared on the confirmed run end.
function M.onDelugeSeen()
  if not (ataxiaBasher and ataxiaBasher.inMnemosyne) then return end
  if mnemDeluge then return end
  mnemDeluge = true
  if not M._quiet() then
    M.echo("<red>Deluge<reset> active -- rooms are UNDERWATER: no flying (escape ladder goes grounded)")
  end
end

-- ABLAZE ROOM (v4.7.167, live 2026-07-30). The room description carries "The area is
-- ablaze!" and the ground then burns us for ~800 every few seconds ("The roaring
-- inferno engulfs you as you fight to find a way out.") for as long as we stand in it.
--
-- Unlike Splinterbark/Deluge this is a per-ROOM state, not a run-wide affix, so it is
-- latched by the burn line itself rather than a status row and it EXPIRES: if no burn
-- has landed for a while we have either left or it has gone out. Kept telemetry-
-- independent for the same reason as the other three -- the safety must work with
-- reporting off.
--
-- What reads it: the swarm low-HP escape ladder. Its outdoor branch flies up and HOVERS
-- until fully healed, which is a fine plan in a normal room and a bad one over a fire
-- we cannot out-heal. `S._canHover()` consults this so the ladder takes the grounded
-- retreat instead.
M.ABLAZE_STALE = 12 -- seconds without a burn tick -> assume we are clear of it

function M.onAblazeBurn()
  if not (ataxiaBasher and ataxiaBasher.inMnemosyne) then return end
  ataxiaTemp = ataxiaTemp or {}
  local first = not ataxiaTemp.mnemAblazeAt
  ataxiaTemp.mnemAblazeAt = getEpoch and getEpoch() or 0
  if first and not M._quiet() then
    M.echo("<indian_red>The ground is BURNING<reset> -- hover-healing is off until we leave.")
  end
end

-- True while the room is actively burning us. Lazy expiry so leaving the room clears it
-- without needing a "the fire goes out" line we have never captured.
function M.roomAblaze()
  if not ataxiaTemp.mnemAblazeAt then return false end
  local nowT = getEpoch and getEpoch() or 0
  if (nowT - ataxiaTemp.mnemAblazeAt) > (M.ABLAZE_STALE or 12) then
    ataxiaTemp.mnemAblazeAt = nil
    return false
  end
  return true
end

-- DAMAGE-TYPE SUPPRESSION AFFIXES (v4.7.186). The WADE STATUS "Ongoing effects:" block can
-- carry rows like:
--     Null Magic:              All magic damage you deal is reduced by 33%.
-- and the affix NAME varies per damage type, but the effect TEXT always names the type
-- itself. So this parses the sentence rather than the affix name -- one trigger covers every
-- present and future member of the family without us having to learn their names.
--
-- Stored on ataxiaTemp (transient, never serialized -- `ataxia.mnemosyne` lives under the
-- SAVED `ataxia` namespace, so a run-scoped fact must not go there or it would persist
-- across sessions). Telemetry-independent, the Splinterbark/Deluge shape: a status-row
-- trigger, inMnemosyne-gated, so the safety works with reporting off.
--
-- Cleared on RIPPLE CHANGE as well as run start/end: the effects block is re-read from each
-- ripple's WADE STATUS, so re-latching per ripple is both correct and self-healing.
function M.onDamageNulled(dtype, pct)
  if not (ataxiaBasher and ataxiaBasher.inMnemosyne) then return end
  if type(dtype) ~= "string" or dtype == "" then return end
  dtype = dtype:lower()
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.mnemNulled = ataxiaTemp.mnemNulled or {}
  local was = ataxiaTemp.mnemNulled[dtype]
  ataxiaTemp.mnemNulled[dtype] = tonumber(pct) or 33
  if not was and not M._quiet() then
    M.echo("<indian_red>" .. dtype:upper() .. " damage -" .. tostring(pct) ..
      "%<reset> this ripple -- avoiding it where we can choose.")
  end
end

-- Is this damage type suppressed right now? Class logic asks by TYPE, never by affix name.
function M.damageNulled(dtype)
  local t = ataxiaTemp and ataxiaTemp.mnemNulled
  if not (t and type(dtype) == "string") then return nil end
  return t[dtype:lower()]
end

-- Restore game tree curing iff Splinterbark had forced it off. Called from onRunEnd (run over ->
-- untainted). No-op unless we turned it off, so it never spuriously re-enables curing.
function M.restoreTreeCuring()
  if not M._treeCuringOff then return end
  M._treeCuringOff = nil
  send("curing tree on")
  if not M._quiet() then M.echo("Splinterbark cleared -- <green>curing tree on<reset>") end
end

-- "You wade N ripples deep into the tides of memory:" (WADE STATUS output).
-- Seeing this proves we're in a run, so (re)assert active, set the ripple
-- first, then flush any buffered monsters so /ripple_level precedes /monsters.
function M.onRipple(n)
  -- Reset the ripple map on level change (independent of telemetry reporting).
  if ataxia.mnemosyne.map and ataxia.mnemosyne.map.onRipple then ataxia.mnemosyne.map.onRipple(n) end
  -- A tree reserve must never outlive its boss ripple (telemetry-independent).
  M.releaseTreeReserve()
  M.run.boss = nil -- re-learned from the new ripple's Objective line
  -- A new ripple is a new boss: the chase budget and any stale panic go with it (v4.7.255).
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.bossChases, ataxiaTemp.bossPanicAt, ataxiaTemp.bossPanicName = nil, nil, nil
  -- Re-latch owned boon flags. Called from HERE as well as the explorer because onRipple
  -- fires in every mode, whereas the explorer entry points only exist for `mnem explore`
  -- users -- a manual-mode basher would otherwise never get the re-latch at all (review
  -- finding, v4.7.192). The once-per-run guard on ataxiaTemp keeps it to a single send.
  if M._relatchBoons then M._relatchBoons() end
  -- Ongoing effects are re-read from each ripple's WADE STATUS, so damage-suppression
  -- affixes re-latch per ripple rather than being assumed to persist.
  if ataxiaTemp then
    ataxiaTemp.mnemNulled = nil
    -- Her phial bursts are counted PER RIPPLE: a new ripple is a new fight, so the
    -- disengage threshold must not be pre-armed by the last boss.
    ataxiaTemp.phialBursts = nil
  end
  -- Tantrum: a fresh ripple re-banks the free battlerage. Placed BEFORE the `_auto()` gate
  -- below on purpose -- like every other boon flag, it must work with reporting switched off.
  if M.tantrumArm then M.tantrumArm() end
  -- Forget per-room / in-flight card state; the per-card intervals deliberately
  -- survive (charges are global and regenerate hourly, not per ripple).
  if ataxiaBasher_mnemLdeckReset then ataxiaBasher_mnemLdeckReset() end
  if not M._auto() then return end
  -- Context guard: a stray/re-read "You wade N deep" seen outside a dive must not
  -- BOOTSTRAP a phantom run. Require in-Mnemosyne context to first assert active;
  -- once a run is genuinely active, later ripples advance normally (robust to the
  -- inMnemosyne survey flag flickering between floors). The map reset above is
  -- deliberately NOT gated on this.
  if not M.run.active and not (ataxiaBasher and ataxiaBasher.inMnemosyne) then return end
  if not M.run.active and M._historyNewRun then M._historyNewRun() end -- bootstrapped run (start line missed) gets its own history bucket
  M.run.active = true
  M.setRipple(n)
  M._flushMonsters()
end

-- Verbs a mob group's spawn line uses right after the subject noun phrase
-- ("...a host of malagmae JOINS...", "...the trolls of Riagath WADE..."). Used to
-- bound the "of"-phrase extraction below.
local MOB_VERBS = {
  join = true, joins = true, step = true, steps = true, emerge = true,
  emerges = true, appear = true, appears = true, arrive = true, arrives = true,
  march = true, marches = true, charge = true, charges = true, rush = true,
  rushes = true, pour = true, pours = true, spill = true, spills = true,
  descend = true, descends = true, crawl = true, crawls = true, slither = true,
  slithers = true, stalk = true, stalks = true, creep = true, creeps = true,
  swarm = true, swarms = true, burst = true, bursts = true, move = true,
  moves = true, walk = true, walks = true, scuttle = true, scuttles = true,
  prowl = true, prowls = true, advance = true, advances = true, approach = true,
  approaches = true, form = true, forms = true, gather = true, gathers = true,
  flood = true, floods = true, rise = true, rises = true, fall = true,
  falls = true, drop = true, drops = true, fly = true, flies = true,
  swoop = true, swoops = true, lumber = true, lumbers = true, shamble = true,
  shambles = true, slink = true, slinks = true, pad = true, pads = true,
  bound = true, bounds = true, leap = true, leaps = true, spring = true,
  springs = true, come = true, comes = true, enter = true, enters = true,
  stride = true, strides = true, saunter = true, saunters = true, wander = true,
  wanders = true, materialise = true, materialises = true, materialize = true,
  materializes = true, stream = true, streams = true, file = true, files = true,
  slide = true, slides = true, roll = true, rolls = true, tumble = true,
  tumbles = true, stomp = true, stomps = true, trot = true, trots = true,
  gallop = true, gallops = true, skitter = true, skitters = true, glide = true,
  glides = true, sweep = true, sweeps = true, spawn = true, spawns = true,
  wade = true, wades = true, surge = true, surges = true, swell = true,
  swells = true, teem = true, teems = true, pool = true, pools = true,
  spread = true, spreads = true, coalesce = true, coalesces = true,
}

-- Extract the mob's noun phrase from a spawn line, or nil. The subject is a noun
-- phrase containing "of" -- "a host of malagmae", "the trolls of Riagath", "a
-- ghastly horde of the restless dead" -- and is followed by a verb. Anchor on each
-- "of": walk left to the article that begins the phrase (stopping at "as"/comma),
-- collect the object to the right, and accept the phrase only when a mob verb
-- immediately follows the object (i.e. it is the sentence subject, not flavour).
function M._extractMob(str)
  if type(str) ~= "string" then return nil end
  local words = {}
  for w in str:gmatch("%S+") do words[#words + 1] = w end
  local function bare(w) return (w:lower():gsub("%p", "")) end
  local function trimp(w) return (w:gsub("%p+$", "")) end
  local function isArticle(w)
    local b = bare(w)
    return b == "a" or b == "an" or b == "the"
  end

  for o = 2, #words - 1 do
    if bare(words[o]) == "of" then
      -- Walk left to the outermost article before an "as"/comma clause boundary.
      local leftStart
      for k = o - 1, math.max(1, o - 6), -1 do
        if bare(words[k]) == "as" then break end
        if isArticle(words[k]) then leftStart = k end
        if words[k]:match(",$") then break end
      end
      if leftStart then
        -- Collect the object after "of"; must be followed by a mob verb.
        local obj, verbAfter = {}, false
        for m = o + 1, math.min(#words, o + 5) do
          local w = words[m]
          if MOB_VERBS[w:lower():gsub("%p+$", "")] then
            verbAfter = true
            break
          end
          table.insert(obj, trimp(w))
          if w:match("[%.,;:!?]$") then break end
        end
        if verbAfter and #obj > 0 then
          local parts = {}
          for p = leftStart, o do parts[#parts + 1] = trimp(words[p]) end
          for _, x in ipairs(obj) do parts[#parts + 1] = x end
          return table.concat(parts, " ")
        end
      end
    end
  end
  return nil
end

-- Decide what a post-countdown line means for mob capture. The wave prints
-- "<countdown 0>\n<mob spawn line>\n<GO!>", so after the "0" we want the first real
-- prose line. Returns true when the one-shot capture should STOP (it consumed a
-- meaningful line), false to keep waiting. Crucially it must SURVIVE blank and
-- all-digit lines: the `^.*$` trigger is armed while the "0" is being processed and
-- Mudlet fires it on that very "0" (and any further countdown digits), so treating
-- a digit as "done" -- as the old code did by killing before this check -- killed
-- the trigger on the "0" and it never lived to see the spawn line. That was the bug
-- that stopped monsters from ever being reported.
function M._mobCaptureLine(ln)
  ln = tostring(ln or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if ln == "" or ln:match("^%d+$") then return false end -- blank / countdown digit: keep waiting
  if ln ~= "GO!" then M._mobCandidate = ln end -- first real line = the full spawn line
  return true -- GO! (no mob this wave) or captured: one-shot is done either way
end

-- On the "0", arm a one-shot capture of the spawn line into M._mobCandidate; onGo
-- commits it when GO! follows. Deterministic -- unlike reading back with getLines.
-- Gate on _auto()/inMnemosyne (not strict _inRun): arming just fills a local var,
-- and onGo re-checks _inRun before it actually reports.
function M.onCountdownZero()
  local mnem = ataxiaBasher and ataxiaBasher.inMnemosyne
  if not (M._auto() or mnem) then return end
  M._mobCandidate = nil
  if M._mobTrig then pcall(killTrigger, M._mobTrig); M._mobTrig = nil end
  M._mobTrig = tempRegexTrigger([[^.*$]], function()
    if M._mobCaptureLine(line) then
      if M._mobTrig then pcall(killTrigger, M._mobTrig); M._mobTrig = nil end
    end
  end)
end

-- "GO!" -- a new wave has begun. Commit the mob line captured after the "0" (the
-- FULL spawn line, e.g. "Mandibles clatter... as a swarm of Rapo'kir horkval
-- closes in..." -- the tracker convention is the whole line, not a trimmed
-- phrase), then auto-send WADE STATUS so its output drives ripple-level/effects
-- reporting. Gated on _auto() (not _inRun) for the wade status so it can bootstrap
-- a run whose start line was missed. (M._extractMob is retained as a utility.)
function M.onGo()
  -- Fire for telemetry OR just for the ripple map (so WADE STATUS -> the ripple
  -- line drives the per-ripple map reset even with reporting off).
  local mnem = ataxiaBasher and ataxiaBasher.inMnemosyne
  if not (M._auto() or mnem) then return end
  if M._mobTrig then pcall(killTrigger, M._mobTrig); M._mobTrig = nil end
  if M._inRun() and M._mobCandidate then
    M.onMonsters(M._mobCandidate) -- the whole spawn line, verbatim
  end
  M._mobCandidate = nil
  send("wade status", false)
end

-- "Objective:  defeat <X>" from the WADE STATUS block. A boss ripple names the
-- boss ("defeat Seasone the Industrious"); a normal ripple says "defeat N waves
-- of enemies". Report only the boss case. Fires after onRipple within the same
-- WADE STATUS output, so /ripple_level still precedes /boss.
function M.onObjective(text)
  if type(text) ~= "string" then return end
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  local target = text:match("^defeat (.+)$")
  if not target then return end
  if target:match("^%d+ waves? of enemies") then return end -- normal wave, not a boss
  -- Remember WHO the boss is (cleared at the ripple/run boundary below). The
  -- legend-deck layer reads it: Xylthus cannot bind a boss, so a charge must
  -- never be spent trying.
  M.run.boss = target
  -- Boss tactics fire regardless of telemetry (Splinterbark's independence rule):
  -- a reserve-boss objective arms the tree reserve even with reporting off.
  M.reserveTreeForBoss(target)
  if not M._inRun() then return end
  M.reportBoss(target)
end

-- ---------------------------------------------------------------------------
-- Boss tactics: tree reserve (Seasone the Industrious)
-- ---------------------------------------------------------------------------
-- Seasone throws "a handful of fragile glass phials ... in a venom-filled
-- explosion of kalmia, gecko, slike and more" -- a DENIZEN-dealt truelock (live
-- log 2026-07-27: IMP SLI AST ANO, locks soft+hard, with the tree on cooldown
-- from routine curing -- the exact failure this prevents; user doctrine: "save
-- tree until this happens"). While her boss ripple is up the tree is RESERVED
-- (curing tree off, so SSC can't burn it on incidental afflictions); the phial
-- line (trigger 032) RELEASES it (curing tree on -> SSC spends it on the lock
-- immediately). Splinterbark always wins: a tainted tree is never re-enabled.
-- Telemetry-independent (called from onObjective BEFORE its _inRun gate),
-- inMnemosyne-gated; released on ripple change / confirmed run end.
M.TREE_RESERVE_BOSSES = { seasone = true }

function M.reserveTreeForBoss(boss)
  if not (ataxiaBasher and ataxiaBasher.inMnemosyne) then return end
  if type(boss) ~= "string" then return end
  local lower = boss:lower()
  local hit = false
  for key in pairs(M.TREE_RESERVE_BOSSES) do
    if lower:find(key, 1, true) then hit = true; break end
  end
  if not hit then return end
  if M._treeReserved or M._treeCuringOff then return end
  M._treeReserved = true
  send("curing tree off")
  if not M._quiet() then
    M.echo("<yellow>" .. boss .. "<reset> -- TREE RESERVED for the phial lock (curing tree off)")
  end
end

-- The lock signature the phials build (kalmia/gecko/slike "and more" -> AST/SLI/ANO/IMP).
-- Any ONE of these blocks a cure CHANNEL, which is what makes the lock lethal.
local PHIAL_LOCK = { "anorexia", "slickness", "asthma", "impatience" }

function M._phialLocked()
  local a = (ataxia and ataxia.afflictions) or {}
  for _, aff in ipairs(PHIAL_LOCK) do
    if a[aff] then return true end
  end
  return false
end

-- SPEND THE TREE WHEN IT MATTERS, NOT WHEN THE PHIALS LAND (v4.7.213).
--
-- From a death log, 2026-08-04. Seasone bursts REPEATEDLY -- twice in ~8 seconds -- and the
-- old handler touched tree the instant the first burst landed. That burst was survivable
-- (51% HP, and SSC was curing through it), so the tattoo was spent on a lock we were winning.
-- Eight seconds later the second burst landed at 27% and the tree was still on cooldown:
--     Your tree of life tattoo glows faintly for a moment then fades, leaving you unchanged.
-- repeated until death. The user's read is exactly right -- "we should be saving the tree for
-- the right time".
--
-- So the burst now ARMS a watcher rather than firing. The tree goes out when the lock is
-- still up AND either
--   * HP has fallen to `treeHp` (default 50%) -- the lock is actually killing us, or
--   * `treeGrace` seconds have passed (default 5) -- SSC has had its chance and failed.
-- If SSC breaks the lock on its own, the tattoo stays banked for the next burst. That is the
-- whole point: against a boss that locks repeatedly, the tree is a limited resource and
-- spending it on the first lock guarantees having none for the second.
--
-- Gated on `ataxiaTemp.usedTree` (the real cooldown flag, set by the touch/"unchanged" lines
-- and cleared by "You may utilise the tree tattoo again."), so we no longer fire blind into a
-- cooldown -- the old 3/6/10s timers did exactly that, three times per burst.
-- THE FULL LOCK IS A DIFFERENT EVENT FROM THE BURST (v4.7.235).
--
-- User: "When we get imp sli ast ano we should be touching tree and also shielding would help
-- here. So pause the attack touch tree and shield as we dont have paralysis yet."
--
-- v4.7.213 was right that the BURST is not the moment to spend the tattoo -- burst one is
-- survivable and SSC often wins it. But when all four land and the game itself reports
-- "(Locks: soft, hard)", the argument for waiting is gone: slickness blocks salves and
-- anorexia blocks eating, so there is no cure route left that does not start with the tattoo.
-- Waiting out `treeGrace` from there just donates five seconds.
--
-- Three actions, in this order, and the order is the point:
--   1. STOP SWINGING. Every attack sends `queue addclearfull`, which clears the full queue --
--      that is what ate the escape in the death log. Holding first means the tree and shield
--      cannot be thrown away the same way.
--   2. TOUCH TREE -- the only cure channel the lock does not close.
--   3. TOUCH SHIELD -- user: "shielding would help here ... as we dont have paralysis yet".
--      Gated on exactly that: a shield needs an arm and a free action, so paralysis or an
--      existing shield means skip it rather than spend the round on a refusal.
local PHIAL_FULL = { "anorexia", "slickness", "asthma", "impatience" }

-- AN AFFLICTION WE CANNOT GET COUNTS AS PRESENT (v4.7.241).
--
-- Requiring all four to be actively on us looks right and is not: the catalogue has boons that
-- make one of them impossible -- `Coarse Flesh` grants immunity to SLICKNESS, `Kevadrin's
-- Patience` to IMPATIENCE. Hold either and this could never return true, so the tree-and-shield
-- response never fired against the exact fight it was written for. The lock is "every channel
-- that can be closed IS closed", and a channel that cannot be closed is not an exception to
-- that -- it is the best possible version of it.
function M._phialFullLock()
  local a = (ataxia and ataxia.afflictions) or {}
  local imm = M.runImmunities and M.runImmunities() or {}
  for _, aff in ipairs(PHIAL_FULL) do
    if not a[aff] and not imm[aff] then return false end
  end
  return true
end

-- Bounded hold so a missed cure can never park the basher permanently.
M.PHIAL_HOLD = 4

function M._phialLockResponse()
  if not (ataxiaBasher and ataxiaBasher.inMnemosyne) then return false end
  if not M._phialFullLock() then return false end
  ataxiaTemp = ataxiaTemp or {}
  if ataxiaTemp.phialResponded then return false end -- once per lock, not once per tick
  ataxiaTemp.phialResponded = true

  -- 1. Stop swinging.
  ataxiaTemp.phialHold = true
  if M._phialHoldT then pcall(killTimer, M._phialHoldT) end
  M._phialHoldT = tempTimer(tonumber(M.PHIAL_HOLD) or 4, function()
    M._phialHoldT = nil
    if ataxiaTemp then ataxiaTemp.phialHold = nil end
  end)

  local a = (ataxia and ataxia.afflictions) or {}
  local parts = {}
  -- 2. Tree, unless it is tainted or already spent.
  if not M._treeCuringOff and not ataxiaTemp.usedTree then
    parts[#parts + 1] = "touch tree"
  end
  -- 3. Shield, unless paralysed (no free action) or already up.
  local shielded = ataxia and ataxia.defences and ataxia.defences.shield
  if not a.paralysis and not shielded then
    parts[#parts + 1] = "touch shield"
  end
  if #parts == 0 then return false end

  local sep = (ataxia.settings and ataxia.settings.separator) or ";"
  -- `cq all` first: whatever is queued was decided before the lock existed.
  send("cq all" .. sep .. table.concat(parts, sep))
  if not M._quiet() then
    M.echo("<indian_red>FULL PHIAL LOCK<reset> (IMP SLI AST ANO) -- attack held, <cyan>"
      .. table.concat(parts, "<reset> + <cyan>") .. "<reset>.")
  end
  return true
end

function M._phialTreeTick()
  if not ataxiaTemp or not ataxiaTemp.phialLockAt then return end
  if M._treeCuringOff then return M._phialTreeStop() end       -- Splinterbark: tainted tree
  if not (ataxiaBasher and ataxiaBasher.inMnemosyne) then return M._phialTreeStop() end
  if not M._phialLocked() then return M._phialTreeStop() end   -- SSC won; tree stays banked

  local now = (getEpoch and getEpoch()) or 0
  local waited = now - (tonumber(ataxiaTemp.phialLockAt) or now)
  if waited > (tonumber(M.PHIAL_TREE_MAX) or 25) then return M._phialTreeStop() end

  -- Full lock: act now rather than banking. See M._phialLockResponse.
  if M._phialLockResponse() then return end

  if ataxiaTemp.usedTree then return end -- on cooldown: wait for the ready line, do not spam

  local hp = tonumber(ataxia and ataxia.vitals and ataxia.vitals.hpp) or 100
  local hpGate = tonumber(ataxia.mnemosyne and ataxia.mnemosyne.treeHp) or 50
  local grace = tonumber(ataxia.mnemosyne and ataxia.mnemosyne.treeGrace) or 5
  -- Banking ends the moment we decide to leave (phialSpendTree, set on the disengage burst).
  -- The bank exists to keep a charge for the NEXT burst; once we are breaking off there is no
  -- next burst to keep it for, and holding it then is just the old bug wearing a new hat.
  if hp > hpGate and waited < grace and not ataxiaTemp.phialSpendTree then return end

  send("touch tree")
  if not M._quiet() then
    M.echo("<indian_red>PHIAL LOCK<reset> -- spending the tree ("
      .. (hp <= hpGate and (hp .. "% hp") or (math.floor(waited) .. "s locked")) .. ")")
  end
  M._phialTreeStop()
end

function M._phialTreeStop()
  if ataxiaTemp then
    ataxiaTemp.phialLockAt, ataxiaTemp.phialSpendTree = nil, nil
    ataxiaTemp.phialResponded, ataxiaTemp.phialHold = nil, nil
  end
  if M._phialHoldT then pcall(killTimer, M._phialHoldT); M._phialHoldT = nil end
  if M._phialTreeT then pcall(killTimer, M._phialTreeT); M._phialTreeT = nil end
end

-- Re-checked from the tree-ready line as well as the timer, so the instant the tattoo comes
-- off cooldown mid-lock it goes straight out (trigger curing_bals/004).
function M.onTreeReady()
  if ataxiaTemp and ataxiaTemp.phialLockAt then M._phialTreeTick() end
end

function M.onSeasonePhials()
  local reserved = M._treeReserved
  M._treeReserved = nil
  if not (ataxiaBasher and ataxiaBasher.inMnemosyne) then return end
  ataxiaTemp = ataxiaTemp or {}

  -- SPLINTERBARK does NOT skip this handler, only the tattoo half of it (v4.7.215). The
  -- affix taints the tree, so the escape ladder is the ONLY answer left to a phial lock --
  -- the one situation where leaving matters most. The old early `return` sat above every
  -- line in this function, so a Splinterbark Seasone got no tree AND no disengage.
  local tainted = M._treeCuringOff and true or false
  if not tainted then
    -- Hand the tattoo back to SSC (the reserve exists so it is available for exactly this),
    -- but do NOT spend it yet -- see M._phialTreeTick.
    if reserved then send("curing tree on") end

    ataxiaTemp.phialLockAt = (getEpoch and getEpoch()) or 0
    if M._phialTreeT then pcall(killTimer, M._phialTreeT) end
    if tempTimer then
      M._phialTreeT = tempTimer(1, function() M._phialTreeT = nil; M._phialTreeTick() end)
      -- Re-arm each second until the lock clears, the tree is spent, or the window closes.
      for _, d in ipairs({2, 3, 4, 5, 6, 8, 10, 13, 16, 20}) do
        tempTimer(d, function() M._phialTreeTick() end)
      end
    end
  end
  -- DISENGAGE ON THE SECOND BURST (v4.7.215).
  --
  -- v4.7.213 stopped us wasting the tattoo on burst one, but rationing a single charge only
  -- ever buys ONE extra burst -- and the death log shows Seasone throwing more than two. The
  -- honest read is that this fight is not winnable by out-curing her: each burst is a fresh
  -- truelock and there is exactly one tattoo. So the second burst is not a cue to cure
  -- harder, it is the cue to LEAVE -- while we can still act, rather than at escapeAt% with
  -- a lock already up.
  --
  -- Counted per ripple (her boss ripple), on ataxiaTemp so a reload never resurrects a stale
  -- count and a fresh ripple starts from zero. Set `ataxia.mnemosyne.phialDisengage` to 0 to
  -- disable, or to 3+ to stand and fight longer.
  ataxiaTemp.phialBursts = (tonumber(ataxiaTemp.phialBursts) or 0) + 1
  local bursts = ataxiaTemp.phialBursts
  local at = tonumber(ataxia.mnemosyne and ataxia.mnemosyne.phialDisengage) or 2
  -- FONT OF LIFE (v4.7.241): "The Earthmother empowers your tree tattoo to now cure two
  -- afflictions." The disengage exists because ONE tattoo cannot answer a four-affliction lock
  -- twice. Curing two at a time is not a small improvement -- it halves what the lock costs to
  -- break -- so it buys exactly one more burst before leaving is the better call. Gated on the
  -- boon: without it the tattoo cures one and burst two is still the moment to go.
  if mnemFontOfLife and at > 0 then at = at + 1 end
  -- With the tree tainted there is no charge to ration, so the reasoning that makes burst
  -- one survivable does not apply: leave on the first one.
  if tainted and at > 1 then at = 1 end
  local leaving = at > 0 and bursts >= at
  if leaving then
    -- Unbank the tattoo: we are conceding the room, so there is no later burst to save it
    -- for, and the tree is what keeps us alive during the retreat. Set the flag and let the
    -- ALREADY-ARMED watcher spend it (<=1s away) -- do NOT tick here. The afflictions arrive
    -- by GMCP a beat after this line, so an immediate tick would see no lock, take the
    -- `_phialTreeStop()` branch and tear down the whole watcher. That asynchrony is exactly
    -- why the existing code arms at t+1 instead of firing at t+0.
    if not tainted then ataxiaTemp.phialSpendTree = true end
    local S = ataxia.mnemosyne and ataxia.mnemosyne.swarm
    local out = S and S.disengage and S.disengage("phial burst #" .. bursts)
    if not M._quiet() then
      if out then
        M.echo("<indian_red>PHIAL BURST #" .. bursts .. "<reset> -- <yellow>DISENGAGING<reset>"
          .. " (one tattoo cannot answer repeat locks)"
          .. (tainted and "; tree TAINTED." or "; tree unbanked."))
      else
        -- No route out: say so plainly. This is the case that killed us, and a silent
        -- failure here would read exactly like a successful disengage.
        M.echo("<indian_red>PHIAL BURST #" .. bursts .. "<reset> -- <indian_red>NO ESCAPE ROUTE"
          .. "<reset>" .. (tainted and "; tree TAINTED" or "; tree unbanked") .. ", fighting it out.")
      end
    end
    return
  end
  if not M._quiet() then
    M.echo("<indian_red>PHIAL BURST<reset> -- "
      .. (tainted and "tree TAINTED (Splinterbark) and disengage disabled -- on our own"
          or ("lock armed; holding the tree until it counts"
              .. (reserved and " (reserve released)" or ""))))
  end
end

-- Ripple boundary / run end: a reserve must never outlive the boss fight.
function M.releaseTreeReserve()
  if not M._treeReserved then return end
  M._treeReserved = nil
  if M._treeCuringOff then return end
  send("curing tree on")
end

-- "Ongoing effects:" (inside the ripple status block). Skip the immediate
-- divider, collect effect lines, stop on a blank line or the closing divider.
function M.onEffectsHeader()
  if not M._inRun() then return end
  local skippedDash = false
  M._captureLines({
    timeout = 1.5,
    onLine = function(ln)
      if ln:match("^%s*$") then return "stop" end
      if isDivider(ln) then
        if not skippedDash then
          skippedDash = true
          return "skip"
        end
        return "stop"
      end
      return nil
    end,
    onDone = function(lines)
      local list = M._parseNamedBlock(lines)
      if #list > 0 then
        if M._recordAffixes then M._recordAffixes(list) end -- local history (#6)
        M.reportEffects(list)
      end
    end,
  })
end

-- "As the Mnemosyne stretches ever on... you see flickers of power..."
-- Content sits between two dividers and ends at "BOON CLAIM ...".
-- NOT gated on _inRun(). The boon LIBRARY is local data, but _inRun() = _auto() and run.active,
-- and _auto() = cfg().enabled and _hasToken() -- and the shipped default is reporting disabled
-- with no token. Gating the whole handler meant the catalogue never learned a single description
-- for anyone not running the remote tracker, i.e. for the default install: every BOONS row then
-- printed "no description learned yet" forever. So: always capture and learn locally; gate only
-- the telemetry POST below.
-- ---------------------------------------------------------------------------
-- GENERIC BOON LATCH (v4.7.241)
-- ---------------------------------------------------------------------------
-- Sixty-odd boons currently each own a hand-written trigger. That was reasonable when each one
-- needed bespoke parsing, and it is not reasonable for the next ten, which only need a flag
-- set when the boon is held. So: a NAME -> FLAG table, latched from the two places that
-- already tell us what we own -- the BOON CLAIM (as it happens) and the BOONS list (on demand,
-- and after a reload).
--
-- EVERY consumer stays gated on its flag. A boon we do not hold must change nothing: the
-- abilities below do not exist without it, and sending them is a refusal that costs a round.
-- That is the whole contract of this table.
M.BOON_FLAGS = {
  ["Vitalising Tincture"]  = "mnemVitalisingTincture",
  ["Font of Life"]         = "mnemFontOfLife",
  ["Shadow Tempo"]         = "mnemShadowTempo",
  ["Revel in Slaughter"]   = "mnemRevelInSlaughter",
  ["Morudai"]              = "mnemMorudai",
  ["Stormcleaver"]         = "mnemStormcleaver",
  ["Convocation"]          = "mnemConvocation",
  ["Mutated Jaws"]         = "mnemMutatedJaws",
  ["Wrath and Righteousness"] = "mnemWrathRighteousness",
  ["Pyrrhic Victory"]      = "mnemPyrrhicVictory",
  ["Razor Leaf"]           = "mnemRazorLeaf",
}

-- An (ECHO) row names the same boon; a second copy does not make it a different one.
local function boonFlagFor(name)
  if type(name) ~= "string" then return nil end
  local clean = name:gsub("^%(ECHO%)%s*", ""):gsub("^%s+", ""):gsub("%s+$", "")
  return M.BOON_FLAGS[clean], clean
end

-- Latch one boon we are confirmed to hold. Returns the flag name, or nil.
function M.latchBoonFlag(name)
  local flag, clean = boonFlagFor(name)
  if not flag then return nil end
  if _G[flag] then return flag end -- already known: stay quiet
  _G[flag] = true
  if not M._quiet() then
    M.echo("<pale_green>Boon<reset> <gold>" .. clean .. "<reset> -- <cyan>" .. flag .. "<reset> armed.")
  end
  return flag
end

-- Clear them all. Boons are per-RUN, so this belongs with the other run-end resets.
function M.clearBoonFlags()
  for _, flag in pairs(M.BOON_FLAGS) do _G[flag] = false end
end

-- ---------------------------------------------------------------------------
-- Affliction IMMUNITY from boons (v4.7.224)
-- ---------------------------------------------------------------------------
-- User: "We select boons that make us immune to an affliction and I would love for it to echo
-- on the boon option screen to be able to state we have the immunity to this boon's downside."
--
-- Several boons trade a drawback for a benefit ("Stone Stomach: ...but you can no longer drink
-- health or mana"). When the drawback is an affliction we are ALREADY immune to -- Sure-Footed
-- grants immunity to dizziness -- that boon is strictly free for us, and the offer screen is
-- the only moment the information is worth anything. Three seconds later the choice is made.
--
-- Derived from the run's CLAIM HISTORY rather than a flag we set and hope to clear: claims
-- already carry their description (007), already reset per run, and already survive a
-- SYSUPDATE reload. A parallel latch would be a third thing to keep in sync with two that
-- already work.
local IMMUNE_PAT = "immune to the%s+(.-)%s+affliction"

-- Word forms a boon might use for the same affliction. The grant says "dizziness"; a drawback
-- may well say "dizzy", and no amount of stemming turns one into the other safely ("dizziness"
-- minus "ness" is "dizzi"). So this is a DATA table, extended as real lines are seen, rather
-- than a clever rule that is wrong in ways nobody notices. Keys are lowercase.
M.IMMUNITY_ALIASES = M.IMMUNITY_ALIASES or {
  dizziness = { "dizzy" },
}

-- ONE BOON CAN GRANT SEVERAL (v4.7.236). Live miss: Outlaw reads
--
--   "You are immune to the justice and guilt afflictions."
--
-- The old single-capture version grabbed "justice and guilt" and then its own runaway-guard
-- rejected it for containing a space -- so the boon registered NOTHING, and Corrupted Mind
-- ("...but you suffer permanent guilt") was never flagged as free. The guard was right to
-- exist and wrong to be the last word: a multi-word capture is not automatically junk, it is
-- sometimes a LIST.
--
-- Split on "and" / commas, then apply the length-and-space guard to each PART. A real
-- affliction name is one word, so a part that still has a space after splitting is genuine
-- runaway text and is dropped -- the protection survives, it just runs at the right level.
function M._immunitiesFrom(desc)
  local out = {}
  if type(desc) ~= "string" then return out end
  local low = desc:lower()
  -- "affliction" or "afflictionS": the plural is what a multi-affliction grant uses.
  local body = low:match("immune to the%s+(.-)%s+afflictions?%f[%A]")
  -- SHORTER PHRASING (v4.7.238). Live: "Inflammable: You are immune to burning, but suffer
  -- permanent shivering." No "the", no "affliction" -- so the pattern above misses it entirely
  -- and the boon registered nothing. Fall back to reading up to the first comma or full stop,
  -- which is where the grant clause ends in every example seen.
  if not body or body == "" then
    -- To the SENTENCE end, not the first comma (v4.7.240). Found by running this parser over
    -- all 294 boons in the community catalogue: "Careless Whisperer: You are immune to
    -- masochism, hallucinations, and paranoia, and you always walk with a zealous warding
    -- against the Outer Cold." Stopping at the first comma read ONE of three.
    --
    -- Capturing generously is safe because the per-PART guard below is the real protection: a
    -- real affliction name is one word, so the trailing "you always walk with a zealous
    -- warding..." is dropped while the three names survive. Guard at the right level again --
    -- the same lesson as v4.7.236.
    body = low:match("immune to ([^%.;]+)")
    if body then
      body = body:gsub("^the%s+", ""):gsub("%s+afflictions?$", "")
    end
  end
  if not body or body == "" then return out end
  if #body > 200 then return out end -- a paragraph, not a list of names
  body = body:gsub("%s+and%s+", ",")
  for part in body:gmatch("[^,]+") do
    part = part:gsub("^%s+", ""):gsub("%s+$", "")
    if part ~= "" and #part <= 24 and not part:find("%s") then
      out[#out + 1] = part
    end
  end
  return out
end

-- Back-compat single-value form: the first immunity, or nil. Kept because the cost scan asks
-- only "is this line a GRANT at all", for which the first answer is enough.
function M._immunityFrom(desc)
  local list = M._immunitiesFrom(desc)
  return list[1]
end

-- { [affliction] = <boon that granted it> } for the CURRENT run. Empty table when none.
function M.runImmunities()
  local out = {}
  local h = M.history
  if not h or type(h.claims) ~= "table" then return out end
  for _, c in ipairs(h.claims) do
    if c.run == h.run then
      -- The claim record's own description first; fall back to the all-time library, which is
      -- populated from the offer screen and may be richer for a boon claimed before we learned
      -- to store descriptions on the claim.
      local desc = c.description
      if type(desc) ~= "string" or desc == "" then
        local info = M.boonInfo and M.boonInfo(c.name)
        desc = info and info.description
      end
      for _, aff in ipairs(M._immunitiesFrom(desc)) do out[aff] = c.name end
    end
  end
  return out
end

-- Afflictions that can plausibly appear in a boon's prose, from the canonical curing table
-- (001_Default_Curing_Prios). Deliberately FILTERED, not the whole 115: the limb compounds
-- ("brokenleftarm") never appear in prose, and the ordinary-English ones -- fear, peace, guilt,
-- justice, generosity, burning, frozen, prone, bound, sleeping, itching, pressure -- would
-- match innocent sentences. Scanning free text for "peace" and calling it an affliction is how
-- an annotation stops being trusted.
local DRAWBACK_AFFS = {
  "agoraphobia", "hallucinations", "claustrophobia", "hypochondria", "whisperingmadness",
  "wristfractures", "temperedmelancholic", "temperedphlegmatic", "temperedcholeric",
  "temperedsanguine", "recklessness", "haemophilia", "hypersomnia", "hypothermia",
  "healthleech", "manaleech", "sensitivity", "impatience", "clumsiness", "tenderskin",
  "stuttering", "depression", "loneliness", "addiction", "confusion", "darkshade",
  "dizziness", "epilepsy", "masochism", "paralysis", "blindness", "weariness", "stupidity",
  "slickness", "lethargy", "insomnia", "paranoia", "dementia", "deafness", "anorexia",
  "hyperactivity", "shyness", "nausea", "asthma", "vertigo", "voyria", "webbed", "aeon",
  -- Added v4.7.236 after a live miss. These ARE real afflictions; they were held out with the
  -- genuinely generic words (fear, peace, pressure, burning, frozen, prone, sleeping, bound)
  -- because they read as ordinary English. But the cost-clause restriction already does that
  -- work -- the scan only looks after "but" / "you suffer" / "at the cost of" -- and
  -- "Corrupted Mind: ...but you suffer permanent guilt" is exactly the line being missed.
  -- The truly generic ones stay out; these are nouns Achaea uses as affliction names.
  "generosity", "disloyalty", "justice", "guilt", "itching",
  -- v4.7.237, from a live offer screen: "Corrupted Cold: ...but you suffer permanent
  -- dehydration and tenderskin." `dehydration` was in neither this list nor the canonical
  -- curing table it was derived from -- so the cost was only ever half-reported.
  "dehydration",
  -- v4.7.238, live: "Inflammable: ...but suffer permanent shivering." `shivering` was held out
  -- with the generic words; it is a real affliction and the cost clause makes it unambiguous.
  -- `burning` stays OUT of this list deliberately -- it is also a damage type ("deals burning
  -- damage"), so a cost clause is not enough to disambiguate it. It still works as a GRANT,
  -- which reads the affliction straight out of the sentence rather than scanning for names.
  "shivering",
  -- v4.7.240. Found by auditing this parser against all 294 boons in the community catalogue
  -- rather than waiting for each to turn up on an offer screen -- which is how the previous
  -- five gaps were found, one release at a time.
  "fulmination", "hamstrung", "timeflux",
}

-- Clause markers that introduce a COST. The drawback scan runs only on the text after one of
-- these, which is what keeps the ordinary-English risk down to nothing worth worrying about:
-- "Your poison resistance is increased by 66% BUT YOU SUFFER permanent nausea." Without the
-- restriction, a boon reading "you are immune to X" would have its own benefit reported as a
-- drawback, which is the exact opposite of the truth.
local COST_MARKERS = { " but ", " however", " at the cost of ", " in exchange", " you suffer ",
                       " causes you to ", " causing " }

-- EVERY affliction a boon inflicts as its cost. The mirror of the multi-grant fix in
-- v4.7.236, and found the same way -- a live offer screen (v4.7.237):
--
--   "Corrupted Cold: Your cold resistance is increased by 66%, but you suffer permanent
--    dehydration and tenderskin."
--
-- Returning only the first match under-reported the cost, which is worse than saying nothing:
-- a boon whose price is two afflictions reads as though it costs one. Grants had already been
-- taught to be lists; costs had not, and there was no reason to expect the game to be
-- one-sided about it.
function M._boonDrawbacks(desc)
  local out, seen = {}, {}
  if type(desc) ~= "string" or desc == "" then return out end
  local low = " " .. desc:lower() .. " "
  local tail
  for _, mark in ipairs(COST_MARKERS) do
    local at = low:find(mark, 1, true)
    if at then
      local seg = low:sub(at)
      if not tail or #seg > #tail then tail = seg end
    end
  end
  if not tail then return out end
  -- A GRANT INSIDE THE COST CLAUSE IS STILL A GRANT (v4.7.238). This check used to run on the
  -- WHOLE description and bail out entirely -- which was right for "Your damage is halved, but
  -- you are immune to nausea" and catastrophically wrong for "You are immune to burning, but
  -- suffer permanent shivering", where the boon is a grant AND has a cost. A boon can be both;
  -- what matters is which CLAUSE the affliction sits in. Checking the tail rather than the
  -- whole line keeps the original protection and stops it eating the common case.
  if M._immunityFrom(tail) then return out end
  for _, aff in ipairs(DRAWBACK_AFFS) do
    if tail:find(aff, 1, true) and not seen[aff] then
      seen[aff] = true
      out[#out + 1] = aff
    end
  end
  return out
end

-- Back-compat single-value form: the first cost, or nil.
function M._boonDrawback(desc)
  if type(desc) ~= "string" or desc == "" then return nil end
  local low = " " .. desc:lower() .. " "
  -- An immunity GRANT is never a drawback, even though it names an affliction.
  if M._immunityFrom(desc) then return nil end
  local tail
  for _, mark in ipairs(COST_MARKERS) do
    local at = low:find(mark, 1, true)
    if at then
      local seg = low:sub(at)
      -- Earliest marker wins: "X but you suffer Y" must not be read from " you suffer ".
      if not tail or #seg > #tail then tail = seg end
    end
  end
  if not tail then return nil end
  for _, aff in ipairs(DRAWBACK_AFFS) do
    if tail:find(aff, 1, true) then return aff end
  end
  return nil
end

-- Does `desc` mention `aff` (or one of its known word forms)?
function M._mentionsAff(desc, aff)
  if type(desc) ~= "string" or type(aff) ~= "string" then return false end
  local low = desc:lower()
  if low:find(aff, 1, true) then return true end
  for _, alt in ipairs(M.IMMUNITY_ALIASES[aff] or {}) do
    if low:find(alt, 1, true) then return true end
  end
  return false
end

-- Annotate the offer screen with immunities we already hold. Deliberately NOT gated on
-- `_inRun()`/telemetry: this is decision support for the player, and it has to work whether or
-- not the tracker is reporting.
-- TWO TIERS, because the two questions carry different false-positive risk (v4.7.225).
--
--   A. "Is this boon's cost something we already block?" -- scanned against the immunities we
--      actually HOLD, which is a set of one or two specific words, so it needs no clause
--      restriction and catches alternate word forms via M.IMMUNITY_ALIASES. This is the
--      original v4.7.224 behaviour and stays exactly as safe as it was.
--
--   B. "Does this boon have a cost at all, that we do NOT block?" -- has to scan against every
--      plausible affliction, so it is restricted to a COST CLAUSE. Without that restriction a
--      boon reading "you are immune to X" would have its own BENEFIT reported as a drawback,
--      which is the precise opposite of the truth.
--
-- Boons that GRANT an immunity are flagged in their own right: that is what taking one buys,
-- and it makes every later boon costing that affliction free.
function M._echoImmunities(list)
  local imm = M.runImmunities()
  local names = {}
  for aff in pairs(imm) do names[#names + 1] = aff end
  table.sort(names)

  local said = false
  for _, b in ipairs(list or {}) do
    local grants = M._immunityFrom(b.description)
    if grants then
      said = true
      -- A GRANT CAN ALSO HAVE A PRICE (v4.7.238). "Inflammable: You are immune to burning, but
      -- suffer permanent shivering." Reporting only the grant sells it as pure upside, which
      -- is the same confident-wrong-answer failure as calling a partly-blocked boon "free".
      local costs = M._boonDrawbacks(b.description)
      local all = M._immunitiesFrom(b.description)
      local line = "<pale_green>GRANTS IMMUNITY<reset> -- <gold>" .. tostring(b.name)
        .. "<reset> blocks <cyan>" .. table.concat(all, "<reset> + <cyan>") .. "<reset>"
      if #costs > 0 then
        line = line .. ", but costs <indian_red>"
          .. table.concat(costs, "<reset> + <indian_red>") .. "<reset>"
      end
      M.echo(line .. ".")
    else
      -- Tier A: a cost we already block, by name or known word form.
      local blocked, via
      for _, aff in ipairs(names) do
        if M._mentionsAff(b.description, aff) then blocked, via = aff, imm[aff]; break end
      end
      if blocked then
        said = true
        -- PARTIALLY free is not free (v4.7.237). "Corrupted Cold" costs dehydration AND
        -- tenderskin; blocking one of them still leaves the other, and calling that "free for
        -- us" is the kind of confident wrong answer that gets someone killed on a boon screen.
        local costs = M._boonDrawbacks(b.description)
        local unblocked = {}
        for _, c in ipairs(costs) do
          if not imm[c] then
            local covered = false
            for aff in pairs(imm) do if M._mentionsAff(c, aff) then covered = true end end
            if not covered then unblocked[#unblocked + 1] = c end
          end
        end
        if #unblocked > 0 then
          M.echo("<pale_green>PARTLY IMMUNE<reset> -- <gold>" .. tostring(b.name)
            .. "<reset>: <cyan>" .. blocked .. "<reset> blocked by <gold>" .. tostring(via)
            .. "<reset>, but still costs <indian_red>"
            .. table.concat(unblocked, "<reset> + <indian_red>") .. "<reset>.")
        else
          M.echo("<pale_green>IMMUNE<reset> -- <gold>" .. tostring(b.name) .. "<reset> costs <cyan>"
            .. blocked .. "<reset>, blocked by <gold>" .. tostring(via) .. "<reset>. Free for us.")
        end
      else
        -- Tier B: costs we do not block. ALL of them -- a boon whose price is two afflictions
        -- reading as though it costs one is worse than saying nothing at all.
        local costs = M._boonDrawbacks(b.description)
        if #costs > 0 then
          said = true
          M.echo("<gold>" .. tostring(b.name) .. "<reset> costs <indian_red>"
            .. table.concat(costs, "<reset> + <indian_red>")
            .. "<reset> -- <indian_red>not immune<reset>.")
        end
      end
    end
  end

  -- The standing list whenever we hold any. The per-boon scan can only catch wording we have
  -- seen, so showing what we are immune to lets the player spot a cost the matcher missed --
  -- the difference between decision support and a false all-clear.
  if #names > 0 then
    M.echo("<pale_green>Immune this run<reset>: <cyan>" .. table.concat(names, "<reset>, <cyan>")
      .. "<reset>.")
  end
end

function M.onBoonsOffered()
  local seenDash = false
  M._captureLines({
    timeout = 3,
    onLine = function(ln)
      if ln:find("BOON CLAIM", 1, true) then return "stop" end
      if isDivider(ln) then
        if seenDash then return "stop" end
        seenDash = true
        return "skip"
      end
      if not seenDash then return "skip" end
      return nil
    end,
    onDone = function(lines)
      local list = M._parseNamedBlock(lines)
      if #list == 0 then return end

      -- Local catalogue FIRST and unconditionally: the offer screen is the only place a boon's
      -- description is ever shown, so if we don't take it here it is gone the moment you claim.
      if M._learnBoon then
        for _, b in ipairs(list) do M._learnBoon(b.name, b.description) end
        M._historySave()
      end

      -- Immunity annotation (v4.7.224). Above the telemetry gate on purpose: this is decision
      -- support shown while the offer screen is up, and it must not depend on `mnem` reporting
      -- being switched on. pcall'd because nothing about a display nicety justifies breaking
      -- the capture that feeds the catalogue and the API.
      if M._echoImmunities then pcall(M._echoImmunities, list) end

      -- Everything below is telemetry.
      if not M._inRun() then return end
      -- Remember canonical names so a later BOON CLAIM can be reported
      -- with the exact spelling the game used.
      M.run.lastOffered = {}
      for _, b in ipairs(list) do table.insert(M.run.lastOffered, b.name) end
      M._reportBoonsOfferedEnriched(list)
    end,
  })
end

-- Buffer (accumulate, de-duped) a mob spawn line captured by onGo. Spawns arrive
-- just before the "GO!" that triggers WADE STATUS, so they're flushed after
-- /ripple_level in onRipple. The whole spawn line is kept.
function M.onMonsters(str)
  if not M._inRun() then return end
  if type(str) ~= "string" then return end
  str = str:gsub("^%s+", ""):gsub("%s+$", "")
  if str == "" then return end
  M.run.pendingMonsters = M.run.pendingMonsters or {}
  for _, m in ipairs(M.run.pendingMonsters) do
    if m == str then return end -- de-dupe repeated spawn lines
  end
  table.insert(M.run.pendingMonsters, str)
end

-- Fires from the BOON CLAIM alias. Only report a selection that matches one of
-- the boons we saw offered (resolving the game's exact spelling); a typo or
-- stale claim reports nothing rather than a bogus selection.
function M.onBoonClaim(name)
  if not M._inRun() then return end
  if type(name) ~= "string" then return end
  name = name:gsub("^%s+", ""):gsub("%s+$", "")
  if name == "" then return end
  local canonical = M._resolveClaim(name, M.run.lastOffered)
  if not canonical then
    return M.decho("BOON CLAIM '" .. name .. "' not resolvable against last offered set; not reporting.")
  end
  if M._recordClaim then M._recordClaim(canonical) end -- local history (#6)
  if M.latchBoonFlag then M.latchBoonFlag(canonical) end -- generic flags (v4.7.241)
  M.reportBoonsSelected(canonical)
end

-- Resolve a "boon claim <arg>" argument to a canonical offered name: a slot
-- NUMBER (boon claim 2 -> the 2nd offered boon), an exact case-insensitive name,
-- or a UNIQUE case-insensitive prefix (boon claim hammer). Returns nil if
-- unresolved or if a prefix is ambiguous (matches more than one offered boon).
function M._resolveClaim(name, offered)
  offered = offered or {}
  local n = name:match("^%d+$")
  if n then return offered[tonumber(n)] end -- slot number (array is in offer order)
  local lower = name:lower()
  for _, off in ipairs(offered) do -- exact, case-insensitive
    if off:lower() == lower then return off end
  end
  local match, count = nil, 0 -- unique case-insensitive prefix
  for _, off in ipairs(offered) do
    if off:lower():sub(1, #lower) == lower then
      match = off
      count = count + 1
    end
  end
  if count == 1 then return match end
  return nil
end

-- Enrichment: when `contemplate` is enabled, BOON CONTEMPLATE each offered boon
-- to fill rarity/quote/num_echoes_possible before reporting; otherwise send the
-- name + description straight through.
function M._reportBoonsOfferedEnriched(list)
  -- Post the offer to the API IMMEDIATELY, with the name+description straight off the offer screen.
  -- The old design gated the report behind a slow (~2.5s/boon) BOON CONTEMPLATE enrichment chain,
  -- which (a) races the NEXT ripple's captures for the single `_capturing` slot -- when it loses, the
  -- chain STALLS and the ENTIRE /boons_offered is silently dropped (the reported bug: monsters posted,
  -- boons never did), and (b) even when it completes it can post AFTER the player has waded, landing
  -- the boons on the wrong ripple. Name+description is what the tracker shows; rarity/echoes are
  -- optional and are still learned locally from the BOONS list (trigger 013) + `mnem boonfill`.
  if M._recordOffers then M._recordOffers(list) end -- local history (#6)
  M.reportBoonsOffered(list)
end

-- Sequentially BOON CONTEMPLATE each boon, merge the parsed detail into the
-- entry, then send the fully-populated /boons_offered.
function M._contemplateNext(list, i)
  if i > #list then
    if M._recordOffers then M._recordOffers(list) end -- local history (#6), now enriched
    return M.reportBoonsOffered(list)
  end
  local boon = list[i]
  M._captureContemplate(function(info)
    M._applyContemplate(boon, info)
    tempTimer(0.5, function() M._contemplateNext(list, i + 1) end)
  end)
  send("boon contemplate " .. boon.name, false)
end

-- Backfill the boon catalogue: BOON CONTEMPLATE everything we own but have no description for.
--
-- The BOONS list gives name/echoes/rarity but never a description, and the offer screen -- the
-- only place a description is ever shown -- is long gone for anything claimed before the
-- catalogue existed. CONTEMPLATE re-prints the full detail on demand, so we can recover them
-- all: it is the one way to learn a boon you already hold.
--
-- Names come from ataxiaTemp.boonsOwned, filled by trigger 013 as the BOONS list scrolls past,
-- so BOONS must be run first. Sequential with the same 0.5s spacing as the offer-screen
-- enrichment -- deliberately not parallel, since each CONTEMPLATE is a captured block and they
-- would interleave.
function M.boonFill()
  local owned = (ataxiaTemp and ataxiaTemp.boonsOwned) or {}
  local seen, todo = 0, {}
  for name in pairs(owned) do
    seen = seen + 1
    local rec = M.boonInfo and M.boonInfo(name)
    if not (rec and rec.description and rec.description ~= "") then todo[#todo + 1] = name end
  end
  table.sort(todo)
  if seen == 0 then
    return M.echo("No boons seen yet -- run <cyan>BOONS<grey> first, then <cyan>mnem boonfill<grey>.")
  end
  if #todo == 0 then
    return M.echo("Boon catalogue already complete for all <cyan>" .. seen .. "<grey> owned boon(s).")
  end
  M.echo("Contemplating <cyan>" .. #todo .. "<grey> boon(s) to learn what they do (~" ..
         string.format("%.0f", #todo * 0.6) .. "s)...")
  M._boonFillNext(todo, 1, 0)
end

function M._boonFillNext(todo, i, learned)
  if i > #todo then
    M._historySave()
    return M.echo("Boon catalogue updated: <cyan>" .. learned .. "<grey> learned. Run <cyan>BOONS<grey> to see them.")
  end
  local name = todo[i]
  M._captureContemplate(function(info)
    if info and info.description and info.description ~= "" and M._learnBoon then
      M._learnBoon(name, info.description, info.rarity, info.num_echoes_possible)
      learned = learned + 1
    end
    tempTimer(0.5, function() M._boonFillNext(todo, i + 1, learned) end)
  end)
  send("boon contemplate " .. name, false)
end

-- Merge contemplate detail into an offered boon: rarity/quote/echoes ONLY. The
-- description is kept from the offered block (authoritative, already wrap-joined).
-- We deliberately do NOT take contemplate's description: it is redundant, and the
-- first boon's contemplate is armed right beside the "BOON CLAIM ..." offered
-- footer, which was corrupting the first boon's description.
function M._applyContemplate(boon, info)
  if not info then return end
  if info.rarity then boon.rarity = info.rarity end
  if info.quote then boon.quote = info.quote end
  if info.num_echoes_possible ~= nil then boon.num_echoes_possible = info.num_echoes_possible end
end

-- Capture one BOON CONTEMPLATE block (skip the "<name>:" header + opening
-- divider; stop at the closing divider) and hand parsed detail to cb.
function M._captureContemplate(cb)
  local seenDash, called = false, false
  M._captureLines({
    timeout = 2,
    onLine = function(ln)
      if ln:find("BOON CLAIM", 1, true) then return "skip" end -- never capture the offered footer
      if isDivider(ln) then
        if seenDash then return "stop" end
        seenDash = true
        return "skip"
      end
      if not seenDash then return "skip" end -- header line before the first divider
      return nil
    end,
    onDone = function(lines)
      if called then return end
      called = true
      cb(M._parseContemplate(lines))
    end,
  })
end

-- Parse a captured CONTEMPLATE block into { rarity, num_echoes_possible,
-- description, quote }. Layout: "Rarity: <r>", "Can echo: <Yes/No>", the
-- description paragraph, a blank line, then the quote in double quotes.
function M._parseContemplate(lines)
  local info = {}
  local descParts, quoteParts = {}, {}
  local section = "meta" -- meta -> desc -> quote
  for _, ln in ipairs(lines) do
    local rar = ln:match("^Rarity:%s+(.+)$")
    local echo = ln:match("^Can echo:%s+(.+)$")
    local maxe = ln:match("^Maximum echoes:%s+(%d+)")
    if rar then
      info.rarity = rar:gsub("%s+$", "")
    elseif maxe then
      -- Authoritative echo count (printed only for echo-capable boons); overrides
      -- the "Can echo: Yes" floor of 1 regardless of which line arrives first.
      info.num_echoes_possible = tonumber(maxe)
    elseif echo then
      echo = echo:gsub("%s+$", ""):lower()
      if echo == "no" then
        info.num_echoes_possible = 0
      elseif echo == "yes" then
        -- Floor of 1; a "Maximum echoes: N" line, if present, refines this to N.
        info.num_echoes_possible = info.num_echoes_possible or 1
      else
        info.num_echoes_possible = tonumber(echo)
      end
    elseif ln:match("^%s*$") then
      if section == "desc" then section = "quote" end
    else
      local t = ln:gsub("^%s+", ""):gsub("%s+$", "")
      if section == "meta" then section = "desc" end
      if section == "desc" then
        table.insert(descParts, t)
      else
        table.insert(quoteParts, t)
      end
    end
  end
  if #descParts > 0 then info.description = table.concat(descParts, " ") end
  if #quoteParts > 0 then
    info.quote = (table.concat(quoteParts, " "):gsub('^"', ""):gsub('"$', ""))
  end
  return info
end
