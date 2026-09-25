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
  -- ...and TELL the server (v4.7.298). `/run_pause` has been on the API the whole time and we
  -- had never called it: the flag above is what makes OUR next wade resume rather than start
  -- afresh, but with nothing on the wire the tracker cannot tell a deliberate pause from a
  -- player who simply stopped.
  --
  -- GATED ON `_auto()`, NOT `_inRun()` (deep review). `_inRun()` additionally requires
  -- `run.active`, which is OUR belief about the server's state and can be wrong in exactly the
  -- window that matters: after a reload or SYSUPDATE mid-run, `active` is false until the
  -- load handler's delayed `/run_exists` answers -- and that request has no `onError`, so a
  -- slow or unreachable tracker leaves it false indefinitely. A pause landing in that window
  -- would be silently unreported with no retry, reproducing the very problem this call fixes.
  -- The whisper is an exact, anchored, Mnemosyne-only trigger line (trigger 016), so it cannot
  -- fire outside a dive: if the game says we paused a run, the run exists and the server is the
  -- authority on it. A stale POST is answered by `ok:false`, which is now surfaced.
  if M._auto() then M.reportRunPause() end
end

-- "You begin to wade out into the depths of the Mnemosyne..."
function M.onRunStart()
  -- Cleared on the way IN as well as on the confirmed way out, and deliberately ABOVE the
  -- `_auto()` gate: telemetry is off by default, so anything below it never runs for most users
  -- and a run-scoped fact would carry over between dives. A RESUME keeps the baseline -- it is
  -- the same server-side run, and re-baselining mid-dive would measure the boons already claimed
  -- as if they were the starting point.
  local resuming = M.run and M.run.paused
  if M.audit and not resuming then
    M.audit.baseline, M.audit.baselineRun, M.audit.current = nil, nil, nil
  end
  -- SESSION STATS -- kills, gold, DPS, damage taken; the `tarc` HUD (user-directed, 2026-09-02):
  -- reset on a FRESH run, kept across a RESUME, for exactly the reason just above -- `WHISPER
  -- ... beseech that it grow still` pauses the run without ending it server-side, and the next
  -- wade re-enters the SAME run. A dive interrupted by a pause is not a new dive, so wiping
  -- kills/gold/DPS on every pause/resume would lose real progress for nothing.
  --
  -- ABOVE the `_auto()` gate below, like the audit baseline: session stats are a core basher
  -- feature with no dependency on the REST telemetry, so a user with reporting OFF must still
  -- get a fresh session on a fresh dive. Unlike the run's ~40 boon flags -- reset
  -- UNCONDITIONALLY in trigger 001, because they answer "do we hold this boon RIGHT NOW" and a
  -- resume is not evidence either way, so a stale TRUE would be actively wrong -- session stats
  -- carry no such correctness requirement, so keeping them across a resume is strictly better.
  if not resuming and resetBashingStats then resetBashingStats(true) end
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
  mnemBloodscent = false -- boons gone on a confirmed run-end
  mnemKaiUnleashed = false -- boons gone on a confirmed run-end
  mnemSenselessFlurry = false -- boons gone on a confirmed run-end
  mnemSpiritRend = false -- boons gone on a confirmed run-end
  mnemObligateCarnivore = false -- boons gone on a confirmed run-end
  mnemDeadlyFlourish = false -- boons gone on a confirmed run-end
  mnemDeathStare = false -- boons gone on a confirmed run-end
  mnemDeadBreath = false -- ...and BELCH goes back to being a single-target nuisance (v4.7.337)
  mnemDeathtempest = false -- ...and SOULSTORM stops being worth the equilibrium (v4.7.338)
  mnemSearingLight = false -- boons gone on a confirmed run-end
  mnemHealingMetabolism = false -- boons gone on a confirmed run-end
  -- Berserker's Edge pinned the rage floor to 100 (basher/001). Putting it back is the half that
  -- matters -- left alone we would quietly hoard battlerage the whole rest of the day for a bonus
  -- that no longer applies. Same shape as the Borrowed Power revert just above.
  if mnemBerserkersEdge then
    mnemBerserkersEdge = false
    if ataxiaBasher_berserkersEdgeRevert then ataxiaBasher_berserkersEdgeRevert() end
  end
  psionPanoply = false -- boons gone on a confirmed run-end
  psionBloodletter = false -- ...and the rupturesight keeper stands down (v4.7.349)
  psionRazorClarity = false -- ...and the clarity keeper with it (v4.7.349)
  psionMindbreak = false -- ...and shatter goes back to ordinary damage (v4.7.349)
  psionPsiwave = false -- ...and the equilibrium attack goes back to shatter (v4.7.355)
  psionEarthquake = false -- ...and upheaval leaves the round (v4.7.357)
  psionProphet = false -- ...and foresight is PvP-only again (v4.7.358)
  dragonMightSycaerunax = false -- boons gone on a confirmed run-end
  dragonRampage = false -- boons gone on a confirmed run-end
  dwFlashforward = false -- boons gone on a confirmed run-end
  infArmyOfDead = false -- boons gone on a confirmed run-end
  mnemGraveborn = false -- ...and the gravehands go back to being worth a crowd (v4.7.348)
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
  dwTimequake = false
  dwHeraldInfirmity = false
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
  mnemRimewrought = false -- ...and tattoos work again (v4.7.333)
  mnemFamine = false -- ...and food is worth what it says again (v4.7.333)
  mnemTantrum = false -- boons gone on a confirmed run-end
  if M.clearBoonFlags then M.clearBoonFlags() end -- ...and every generically-latched boon
  if ataxiaTemp then
    ataxiaTemp.tantrumRipple = nil
    ataxiaTemp.phialBursts = nil -- the boss phial tally dies with the run
  end
  mnemDeluge = false -- affixes gone on a confirmed run-end (flight available again)
  ataxiaTemp.mnemAblazeAt = nil   -- per-room burn state cannot outlive the run
  if ataxiaTemp then
    ataxiaTemp.kaiUnleashedAt = nil -- the burst cooldown stamp dies with it
    ataxiaTemp.kaiChokePendingAt = nil -- ...and the unconfirmed-choke retry guard
    ataxiaTemp.spiritRendAt = nil -- Spirit Rend's 60s clock is run-scoped like the burst's
    ataxiaTemp.spiritRendPendingAt = nil
    ataxiaTemp.spiritRendNoHpWarned = nil -- re-arm the once-per-run unreadable-target warning
    ataxiaTemp.corpseAteAt = nil -- the corpse-eat throttle is run-scoped like the rest
    ataxiaTemp.bardFlourishAt = nil -- Deadly Flourish's 15s clock is run-scoped like the rest
    ataxiaTemp.bardFlourishPendingAt = nil -- ...and its in-flight replay hold
    ataxiaTemp.bardFlourishSideSince = nil -- ...and the bounded side-position hold
    ataxiaTemp.deathStareRipple, ataxiaTemp.deathStareRippleAt = nil, nil -- Death Stare's per-ripple charge
    ataxiaTemp.deathStareUsed, ataxiaTemp.deathStareTries = nil, nil
    ataxiaTemp.deathStarePendingAt, ataxiaTemp.deathStarePendingTarget = nil, nil
    ataxiaTemp.lightwallRoom, ataxiaTemp.lightwallPendingAt = nil, nil -- Searing Light's per-room state
    ataxiaTemp.lightwallDir, ataxiaTemp.lightwallBlocked = nil, nil
    ataxiaTemp.lightwallRipple, ataxiaTemp.lightwallRooms = nil, nil -- ...and the rooms conjured this ripple
  end
  -- THE AUDIT BASELINE IS PER-RUN AND WAS NEVER CLEARED (deep review, v4.7.291). It was guarded
  -- only by `baselineRun == M.history.run`, and on a BOOTSTRAPPED run (start line missed) the
  -- history counter is not bumped until `onRipple` parses the async wade-status reply -- which
  -- lands AFTER `GO!`, i.e. after `auditBaselineOnWade` has already asked. So the check matched
  -- the previous run's number, no fresh AUDIT was sent, and the last run's figures stood in as
  -- this run's baseline until ripple 2. Clearing here makes the guard belt-and-braces instead of
  -- the only thing holding it up: an ordering hazard should not be the sole defence.
  if M.audit then M.audit.baseline, M.audit.baselineRun, M.audit.current = nil, nil, nil end
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
  M.restoreTattooKeepup() -- Rimewrought over -> tattoos work again, keep them up again (v4.7.334)
  if M._inRun() then M.endRun() end
end

-- REAPER / REAPED / REAVER WERE DELETED FROM THE GAME (2026-09-01, v4.7.288).
--
-- What lived here: `M.onReaperTithe` counted "You reap a tithe of power from your fallen foe."
-- into `ataxiaTemp.reaperKills` and echoed the running +N% (the game never showed a total), plus
-- `M.reaperOnWade`, which spared the tally across a pause-resume wade because a wiped count was
-- unrecoverable. Trigger `mnemosyne/023` fed it and the BOON CLAIM alias latched `mnemReaper`.
--
-- All of it is gone rather than left inert. A trigger whose line can no longer be printed is the
-- exact shape `tools/check_orphans.py` exists to catch (v4.7.261): it stays live, costs a pattern
-- match on every line, and reads as working code to the next person. The boon is not nerfed, it
-- is REMOVED -- so there is no state to preserve and nothing to re-enable.

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
-- RIMEWROUGHT affix (v4.7.333, user: "When we have this ongoing effect or affix. We cannot use
-- tattoos"):
--
--   Rimewrought:   Perpetual ice coats your body, rendering tattoos ineffective, and denizens
--                  cause additional freezing on their attacks.
--
-- The same shape as Bravado -- it takes an answer away rather than adding a threat, which is the
-- dangerous kind: `touch shield` and `touch tree` keep costing a command and a balance while
-- returning nothing, and the basher goes on believing it shielded. Every tattoo we SEND is gated
-- on `ataxiaBasher_tattoosDead()`; the game's own tree curing is turned off here, because SSC
-- would otherwise spend the tattoo on every burst for no cure (the Splinterbark machinery, reused
-- wholesale -- `restoreTreeCuring` on run end already puts it back).
--
-- Not covered, and deliberately: tattoo DEFENCES kept up by SSC (`keepadd` moss/boar/cloak). They
-- are raised server-side, we never send them, and stripping the keep-up list would have to be
-- undone exactly on run end -- worth doing only with a live sample of what the game actually
-- refuses.
-- FAMINE affix (v4.7.333, user: "When we have this we need to eat to full every room"):
--
--   Famine:   Taking damage has a chance to make you more hungry, and your healing received from
--             elixirs, moss, and potash is reduced by 20%.
--
-- Hunger normally arrives on its own slow clock, so feeding has been an emergency (the horn) or a
-- boon upkeep (Obligate Carnivore / Healing Metabolism). This affix drives hunger off DAMAGE
-- TAKEN, which in a wade is continuous -- so the same upkeep has to run whether or not those
-- boons are held, and it has to run on the tower's own rhythm rather than waiting for the game to
-- say we are starving. Starvation ends in unconsciousness, and unconscious in a swarm is a death.
--
-- The feed itself is the existing one (`ataxia_hornSatiate`): corpse first when Obligate Carnivore
-- makes corpses edible, the horn otherwise, chained and verified by a SCORE read until the row
-- says "utterly satiated". What this affix changes is only WHEN it is allowed to run.
function M.onFamineSeen()
  if not (ataxiaBasher and ataxiaBasher.inMnemosyne) then return end
  if mnemFamine then return end
  mnemFamine = true
  if not M._quiet() then
    M.echo("<red>Famine<reset> active -- damage makes us hungry and elixirs/moss/potash heal 20% "
      .. "less; <green>topping food up every room<reset>")
  end
  -- Start full rather than waiting for the first room to end.
  if ataxia_hornSatiate then pcall(ataxia_hornSatiate, "famine seen") end
end

-- Every defence the deffing tables call a TATTOO (`ataxiaTables.classDefences.tattoos`:
-- mindseye, cloak, moss, boar, moon, megalith). Read from that table rather than listed here, so a
-- tattoo added there is covered without touching this file.
local function tattooDefences()
  local t = ataxiaTables and ataxiaTables.classDefences and ataxiaTables.classDefences.tattoos
  if not t and sortedDefenceShow then
    pcall(sortedDefenceShow)
    t = ataxiaTables and ataxiaTables.classDefences and ataxiaTables.classDefences.tattoos
  end
  local out = {}
  for def in pairs(t or {}) do out[#out + 1] = def end
  table.sort(out) -- a stable command, and a stable test
  return out
end

-- KEEP-UP IS A STANDING ORDER TO SSC (v4.7.334, user: "We need to not keepup mindseye, cloak,
-- (anything else that is a tattoo) because it will just spam"). A defence in the profile sits at
-- `curing priority defence <def> 25`, which is what makes SSC re-raise it the moment it lapses --
-- so under Rimewrought it retries a tattoo that cannot work, forever. Reset exactly the tattoos
-- the CURRENT profile asks for, remember which, and put those back on run end.
--
-- The profile itself is never edited. `ataxia.settings.defences` is saved to disk, and a config
-- edited by an affix is a config that stays edited when a session ends the wrong way -- the user
-- would find their keep-up list quietly shortened. The priority is a game-side setting, like the
-- tree curing above, so this is the same shape as Splinterbark: turn it off, restore what we
-- turned off.
function M.stripTattooKeepup()
  local d = ataxia and ataxia.settings and ataxia.settings.defences
  local cur = d and d.current
  local prof = (cur and cur ~= "" and d.defup) and d.defup[cur] or nil
  if not prof then return false end
  local off = {}
  for _, def in ipairs(tattooDefences()) do
    if prof[def] then off[#off + 1] = def end
  end
  if #off == 0 then return false end
  local cmd = "curing priority defence"
  for _, def in ipairs(off) do cmd = cmd .. " " .. def .. " reset" end
  send(cmd, false)
  M._rimeTattoosOff = off
  return off
end

-- Put back exactly what `stripTattooKeepup` took off -- never a tattoo the profile did not ask
-- for. Called from onRunEnd beside `restoreTreeCuring`.
function M.restoreTattooKeepup()
  local off = M._rimeTattoosOff
  M._rimeTattoosOff = nil
  if type(off) ~= "table" or #off == 0 then return false end
  local cmd = "curing priority defence"
  for _, def in ipairs(off) do cmd = cmd .. " " .. def .. " 25" end
  send(cmd, false)
  if not M._quiet() then
    M.echo("Rimewrought over -- <green>keep-up restored<reset> for " .. table.concat(off, ", "))
  end
  return true
end

function M.onRimewroughtSeen()
  if not (ataxiaBasher and ataxiaBasher.inMnemosyne) then return end
  if mnemRimewrought then return end
  mnemRimewrought = true
  -- The tree of life is a tattoo: while this is up, every SSC tree touch is a wasted cure.
  if not M._treeCuringOff then
    M._treeCuringOff = true
    send("curing tree off")
  end
  -- ...and stop SSC re-raising the tattoo DEFENCES, which is the same waste one layer out.
  local stripped = M.stripTattooKeepup()
  if not M._quiet() then
    M.echo("<red>Rimewrought<reset> active -- <red>tattoos do NOTHING<reset> (shield, tree); "
      .. "curing tree off, and denizens add freezing"
      .. (stripped and (". <grey>Keep-up off for <white>" .. table.concat(stripped, ", ")) or ""))
  end
end

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

-- ---------------------------------------------------------------------------
-- TWO NUMBERS IN THE WADE STATUS BLOCK WE WERE THROWING AWAY (v4.7.278)
-- ---------------------------------------------------------------------------
--
-- Found by reviewing MediaRes' standalone Mnemosyne tracker, which reads both:
--
--   Wave progress:   <n>      how far through clearing this ripple we are
--   Remaining lives: <n>      how many deaths this RUN can still absorb
--
-- LIVES IS THE OPERATIONALLY IMPORTANT ONE, and it is the only run-scoped stake this
-- package has never known. Every risk decision we make -- the escape ladder, the panic
-- tumble, the boss chase budget, the forced disengage -- is priced in HP, which measures
-- how close THIS FIGHT is to going wrong. Lives measure what dying actually COSTS: at
-- three lives a death is a setback, at one it ends the run and everything claimed in it.
-- The same 20% HP reading deserves different answers at 3 lives and at 1.
--
-- CAPTURED AND SURFACED, NOT YET WIRED, deliberately. Turning it into policy means
-- choosing thresholds (chase on the last life or not? drop escapeAt to 50%?) and a wrong
-- guess there gets us killed in a no-flee instance -- so the number is made available and
-- the decision is the user's. `mnem status` shows it.
--
-- Anchorless patterns on purpose: these lines sit inside an indented status block and
-- CLAUDE.md's own trigger guidance is to avoid ^/$ unless necessary. Both phrases are
-- distinctive enough that a false positive is not credible.
function M.onWaveProgress(n)
  n = tonumber(n)
  if not n then return end
  M.run = M.run or {}
  M.run.waveProgress = n
end

-- Lives are per RUN, so unlike the affixes this must NOT be cleared per ripple -- only on
-- a run boundary. It lives on M.run beside the ripple for exactly that reason.
function M.onLivesLeft(n)
  n = tonumber(n)
  if not n then return end
  M.run = M.run or {}
  local was = M.run.lives
  M.run.lives = n
  -- Say it when it CHANGES, not on every wade status: a number that prints every ripple is
  -- a number nobody reads, and the moment worth noticing is the moment one is spent.
  if was and n < was then
    M.echo("<indian_red>a life spent<reset> -- <white>" .. n .. "<reset> remaining"
      .. (n <= 1 and " <indian_red>(LAST ONE)" or ""))
  end
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
  -- New ripple, new affixes -- the panel's first section changes even when no boon does.
  if M.bonuses and M.bonuses.refresh then pcall(M.bonuses.refresh) end
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
  -- A ripple boundary is well past the CLAIM_CONFIRM_WINDOW of anything claimed at the boon
  -- screen we just left, so this is the natural place to notice a claim that was never
  -- confirmed. Polled rather than timered so it is reload-safe (never serialize a tempTimer id).
  if M.checkClaimVerify then M.checkClaimVerify() end
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
  -- AFTER setRipple, never before: the queue is serial, so /ripple_level must be enqueued
  -- first for the offer behind it to be filed under this ripple rather than the last one.
  M._flushMonsters()
  M._flushPendingOffer("ripple")
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
  -- THE BOON SCREEN IS OVER. Ends the reroll chain (see M._rerollBump): a wave has to be fought
  -- between one genuine offer and the next, and GO! is where that wave starts -- so any offer
  -- screen after this point is a new one, not a reroll of the last.
  --
  -- ABOVE the gate below, and deliberately not keyed on the ripple NUMBER: at the boon screen
  -- `_offerAfterRipple` sends its own `wade status`, so `run.ripple` can advance BETWEEN two
  -- offer screens of the same chain. Keying the chain on it would miss exactly the reroll it
  -- exists to count.
  M._rerollReset()
  -- ...and any contemplate run still going stops at its next step (v4.7.324): this wave's captures
  -- own the single slot now, and `_captureLines` would force-finish whichever came first.
  M._fillGen = (M._fillGen or 0) + 1
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
  -- Every boss named this RUN, not just this ripple: a boss corpse stays in the pack for the
  -- whole dive and Obligate Carnivore must never try to eat it (`ataxia_corpseInedible`). On
  -- ataxiaTemp because `M.run` is serialized; reset with the run in `_resetRun`.
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.mnemBossNames = ataxiaTemp.mnemBossNames or {}
  ataxiaTemp.mnemBossNames[target] = true
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
  -- 3. Shield, unless paralysed (no free action), already up, or iced over (v4.7.333: under
  -- Rimewrought the shield tattoo is inert, and the lock is the worst moment to spend a command
  -- on nothing).
  local shielded = ataxia and ataxia.defences and ataxia.defences.shield
  if not a.paralysis and not shielded and not mnemRimewrought then
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
  ["Dead Breath"]          = "mnemDeadBreath",
  ["Deathtempest"]         = "mnemDeathtempest",
  ["Graveborn"]            = "mnemGraveborn",
  ["Bloodletter's Fury"]   = "psionBloodletter",
  ["Razor Clarity"]        = "psionRazorClarity",
  ["Mindbreak"]            = "psionMindbreak",
  ["Psiwave"]              = "psionPsiwave",
  ["Earthquake"]           = "psionEarthquake",
  ["Prophet of Creation"]  = "psionProphet",
  ["Vitalising Tincture"]  = "mnemVitalisingTincture",
  ["Font of Life"]         = "mnemFontOfLife",
  ["Shadow Tempo"]         = "mnemShadowTempo",
  ["Revel in Slaughter"]   = "mnemRevelInSlaughter",
  ["Morudai"]              = "mnemMorudai",
  ["Stormcleaver"]         = "mnemStormcleaver",
  ["Timequake"]            = "dwTimequake",
  ["Herald of Infirmity"]  = "dwHeraldInfirmity",
  ["Convocation"]          = "mnemConvocation",
  ["Mutated Jaws"]         = "mnemMutatedJaws",
  ["Wrath and Righteousness"] = "mnemWrathRighteousness",
  ["Pyrrhic Victory"]      = "mnemPyrrhicVictory",
  ["Razor Leaf"]           = "mnemRazorLeaf",
  ["Sharp Mind"]           = "mnemSharpMind", -- v4.7.320: Monk transmute becomes a top-up (basher/002)
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

-- ---------------------------------------------------------------------------
-- BOON CONFLICTS (v4.7.325, user-directed)
-- ---------------------------------------------------------------------------
-- User, with a BOON CONTEMPLATE block: "This should be echo the conflicts and highlight them."
--
--   Careless Whisperer:
--   --------------------------------------------------------------------------------
--   Rarity:             rare
--   Category:           Utility
--   Can echo:           No
--   Conflicts With:     Self-Preservation and Truther
--
--   You are immune to masochism, hallucinations, and paranoia, and you always walk ...
--
-- The list is joined with " and " (and presumably commas for three or more). " and " also occurs
-- INSIDE real boon names ("Hammer and Anvil", "Hammer and Nail"), so a list is split into fragments
-- and adjacent fragments are re-joined wherever that makes a KNOWN boon name, longest first.

function M._baseBoonName(name)
  if type(name) ~= "string" then return nil end
  local clean = name:gsub("^%(ECHO%)%s*", ""):gsub("^%s+", ""):gsub("%s+$", "")
  return clean ~= "" and clean or nil
end

-- Every boon name we know of: the catalogue and the seed.
function M._knownBoonNames()
  local set = {}
  for n in pairs((M.history and M.history.boonLibrary) or {}) do
    local b = M._baseBoonName(n)
    if b then set[b] = true end
  end
  for n in pairs(M.BOON_SEED or {}) do set[n] = true end
  return set
end

-- "Self-Preservation and Truther" -> { "Self-Preservation", "Truther" };
-- "Hammer and Anvil and Truther" -> { "Hammer and Anvil", "Truther" } when "Hammer and Anvil" is known;
-- "A, B, and C" -> { "A", "B", "C" }. A trailing full stop is ignored.
function M._splitBoonList(s, known)
  if type(s) ~= "string" then return {} end
  known = known or M._knownBoonNames()
  s = s:gsub("^%s+", ""):gsub("[%s%.]+$", "")
  local frags = {}
  for part in (s .. ","):gmatch("([^,]*),") do
    part = part:gsub("^%s+", ""):gsub("%s+$", ""):gsub("^and%s+", "")
    local rest = part
    while true do
      local a, b = rest:find(" and ", 1, true)
      if not a then break end
      frags[#frags + 1] = rest:sub(1, a - 1)
      rest = rest:sub(b + 1)
    end
    if rest ~= "" then frags[#frags + 1] = rest end
  end
  -- A TRAILING CONNECTOR IS NOT A NAME (v4.7.328 review). "A, B, and" (a list whose tail wrapped,
  -- or one the game ended oddly) produced a phantom boon literally called "and", which then sat in
  -- a recipe as a component nobody can ever hold.
  for k = #frags, 1, -1 do
    local f = frags[k]:gsub("^%s+", ""):gsub("%s+$", "")
    if f == "" or f:lower() == "and" then table.remove(frags, k) end
  end
  local out, i = {}, 1
  while i <= #frags do
    local take = 1
    for j = #frags, i + 1, -1 do
      if known[table.concat(frags, " and ", i, j)] then take = j - i + 1; break end
    end
    out[#out + 1] = table.concat(frags, " and ", i, i + take - 1)
    i = i + take
  end
  return out
end

-- Is every name in this list one we know? Used to tell a WRAPPED conflicts list's tail from the
-- first line of the description: a description line never splits into known boon names.
function M._allKnownBoons(s, known)
  known = known or M._knownBoonNames()
  local names = M._splitBoonList(s, known)
  if #names == 0 then return false end
  for _, n in ipairs(names) do if not known[n] then return false end end
  return true
end

-- The boons we hold THIS run: the run's claims. (`ataxiaTemp.boonsOwned` is never cleared, so it
-- can still list the last run's boons.) Empty outside a run.
function M._heldBoons()
  local held = {}
  local h = M.history
  if not (M.run and M.run.active) or not h or type(h.claims) ~= "table" then return held end
  for _, c in ipairs(h.claims) do
    if c.run == h.run then
      local b = M._baseBoonName(c.name)
      if b then held[b] = true end
    end
  end
  return held
end

-- What `name` conflicts with: its own list, plus any held boon whose list names it (the game
-- prints the pair from both sides, but our catalogue may have seen only one).
function M._conflictsFor(name, held)
  local out, seen = {}, {}
  local rec = M.boonInfo and M.boonInfo(name)
  for _, n in ipairs((type(rec) == "table" and type(rec.conflictsWith) == "table") and rec.conflictsWith or {}) do
    if not seen[n] then seen[n] = true; out[#out + 1] = n end
  end
  local heldNames = {}
  for h in pairs(held or {}) do heldNames[#heldNames + 1] = h end
  table.sort(heldNames)
  for _, h in ipairs(heldNames) do
    local hr = M.boonInfo and M.boonInfo(h)
    if type(hr) == "table" and type(hr.conflictsWith) == "table" and not seen[h] then
      for _, n in ipairs(hr.conflictsWith) do
        if n == name then seen[h] = true; out[#out + 1] = h; break end
      end
    end
  end
  return out
end

-- One colour per meaning: a boon we HOLD is the one that matters (red), one also on this screen is
-- the other half of a choice (yellow), the rest are just named (gold).
function M._fmtConflicts(names, held, offered)
  local parts = {}
  for _, n in ipairs(names or {}) do
    if held and held[n] then
      parts[#parts + 1] = "<red>" .. n .. "<reset> (you have it)"
    elseif offered and offered[n] then
      parts[#parts + 1] = "<yellow>" .. n .. "<reset> (also offered)"
    else
      parts[#parts + 1] = "<gold>" .. n .. "<reset>"
    end
  end
  return table.concat(parts, ", ")
end

-- The CONTEMPLATE line itself (trigger mnemosyne/092), for any contemplate -- ours or typed by hand.
-- Highlights each conflicting name in the line -- red if we hold it, gold otherwise, the same
-- colours the summary uses -- and adds the list to the block's summary line.
function M.onConflictsLine(value)
  if type(value) ~= "string" then return end
  local low = value:gsub("[%s%.]+$", ""):lower()
  if low == "" or low == "none" or low == "nothing" then return end
  local names = M._splitBoonList(value)
  if #names == 0 then return end
  local held = M._heldBoons()
  if selectString and fg then
    for _, n in ipairs(names) do
      if selectString(n, 1) > -1 then
        fg(held[n] and "red" or "gold")
        if setBold then setBold(true) end
        if deselect then deselect() end
        if resetFormat then resetFormat() end
      end
    end
  end
  local hit = false
  for _, n in ipairs(names) do if held[n] then hit = true end end
  -- Into the block's one summary line (v4.7.326), beside its combo and echo call-outs.
  M._calloutAdd("conflicts", "conflicts with " .. M._fmtConflicts(names, held), hit)
end

-- ---------------------------------------------------------------------------
-- CONTEMPLATE CALL-OUTS: combo, echo, conflicts (v4.7.326, user-directed)
-- ---------------------------------------------------------------------------
-- User, with Flameheart's block: "Also should called out if the boon can combo and echo."
--
--   Rarity:             uncommon
--   Category:           Utility
--   Combo Boon?:        Yes
--   Can echo:           No
--
-- (Which also PROVES "Combo Boon?" is a CONTEMPLATE line -- v4.7.322 only had the tracker's glued
-- text to go on.) Each meta line is highlighted where it stands, and the block gets ONE summary
-- line beneath it, printed when the block ENDS: at its closing divider, or at the `Rarity:` line
-- that opens the next block. Both boundaries matter because the call-outs are module-global and a
-- contemplate chain sends the next block 0.5s after the last one closed -- without a boundary, two
-- blocks could merge into one summary under the wrong boon (review, v4.7.326). The quiet timer is
-- only the backstop for a block that never closes; it stays under the chain's 0.5s spacing.
local CALLOUT_ORDER = { "combo", "echo", "conflicts" }
local CALLOUT_QUIET = 0.4

-- A reload must not inherit a half-gathered block or a timer from the old copy of this file.
if M._calloutT and killTimer then pcall(killTimer, M._calloutT) end
M._callout, M._calloutT = nil, nil

function M._calloutAdd(key, text, hit)
  M._callout = M._callout or {}
  M._callout[key] = text
  if hit then M._callout.hit = true end
  if M._calloutT then pcall(killTimer, M._calloutT) end
  M._calloutT = tempTimer(CALLOUT_QUIET, function()
    M._calloutT = nil
    M._calloutFlush()
  end)
end

function M._calloutFlush()
  if M._calloutT then
    if killTimer then pcall(killTimer, M._calloutT) end
    M._calloutT = nil
  end
  local c = M._callout
  M._callout = nil
  if not c then return end
  local parts = {}
  for _, k in ipairs(CALLOUT_ORDER) do if c[k] then parts[#parts + 1] = c[k] end end
  if #parts == 0 then return end
  M.echo((c.hit and "<indian_red>CONFLICT<reset> -- " or "") .. table.concat(parts, "<reset>; ") .. "<reset>.")
end

-- Colour one word of the line being printed, if the game's line holds it.
local function highlight(word, colour)
  if not (selectString and fg) then return end
  if selectString(word, 1) > -1 then
    fg(colour)
    if setBold then setBold(true) end
    if deselect then deselect() end
    if resetFormat then resetFormat() end
  end
end

local YES = { yes = true }

-- One meta line of a contemplate (trigger mnemosyne/093), classified here.
function M.onCalloutLine(ln)
  if type(ln) ~= "string" then return end
  -- A block boundary: whatever the last block gathered is printed now, under that block.
  if ln:match("^%-%-%-") or ln:match("^Rarity:") then
    if M._callout or M._calloutT then M._calloutFlush() end
    return
  end
  local v = ln:match("^Combo Boon%?:%s+(%a+)")
  if v then
    if YES[v:lower()] then
      highlight(v, "green")
      M._calloutAdd("combo", "<pale_green>COMBO boon")
    end
    return
  end
  v = ln:match("^Can echo:%s+(%a+)")
  if v then
    if YES[v:lower()] then
      highlight(v, "cyan")
      -- A "Maximum echoes: N" line, if one follows, refines this.
      if not (M._callout and M._callout.echo) then M._calloutAdd("echo", "<cyan>can echo") end
    end
    return
  end
  v = ln:match("^Maximum echoes:%s+(%d+)")
  if v then
    highlight(v, "cyan")
    M._calloutAdd("echo", "<cyan>can echo (max " .. v .. ")")
  end
end

-- The same call-outs for the OFFER screen, from what the catalogue knows: combo status, how many
-- echoes the boon allows (or the seed's echo text), and its conflicts -- with a boon we hold in
-- red and one also on this screen in yellow. One line per offered boon that has anything to say.
function M._echoBoonCallouts(list)
  local held = M._heldBoons()
  local offered = {}
  for _, b in ipairs(list or {}) do
    local n = M._baseBoonName(type(b) == "table" and b.name or nil)
    if n then offered[n] = true end
  end
  for _, b in ipairs(list or {}) do
    local name = M._baseBoonName(type(b) == "table" and b.name or nil)
    if name then
      local rec = M.boonInfo and M.boonInfo(name)
      rec = type(rec) == "table" and rec or {}
      local parts, hit = {}, false
      if rec.comboBoon == true then parts[#parts + 1] = "<pale_green>COMBO boon<reset>" end
      local maxE = tonumber(rec.maxEchoes)
      local seed = M.BOON_SEED and M.BOON_SEED[name]
      if maxE and maxE > 0 then
        -- A 1 learned from a bare "Can echo: Yes" is a floor, not a count (`echoFloor`).
        if rec.echoFloor == true and maxE == 1 then
          parts[#parts + 1] = "<cyan>can echo<reset>"
        else
          parts[#parts + 1] = "<cyan>can echo (max " .. maxE .. ")<reset>"
        end
      elseif maxE == nil and type(seed) == "table" and type(seed.echo) == "string" and seed.echo ~= "" then
        parts[#parts + 1] = "<cyan>can echo<reset>"
      end
      local cw = M._conflictsFor(name, held)
      if #cw > 0 then
        local others = {}
        for n in pairs(offered) do if n ~= name then others[n] = true end end
        for _, n in ipairs(cw) do if held[n] then hit = true end end
        parts[#parts + 1] = "conflicts with " .. M._fmtConflicts(cw, held, others)
      end
      if #parts > 0 then
        M.echo((hit and "<indian_red>CONFLICT<reset> -- " or "") .. "<gold>" .. name .. "<reset> -- "
          .. table.concat(parts, "; ") .. ".")
      end
    end
  end
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
-- ---------------------------------------------------------------------------
-- Attune-gated boons (v4.7.264)
-- ---------------------------------------------------------------------------
--
-- Four boons in the seed DB do nothing at all unless a specific SPIRIT is attuned:
--
--   Echoing Hydra (legendary)  -> Arius   Full Mettle Alchemist (rare) -> Aspar
--   Viridian Balm (uncommon)   -> Daina   Knight's Resolve (common)    -> Garon
--
-- ...and nothing in the package connected them to `shaman.spiritlore.attunements`, so holding one
-- with the wrong loadout was completely SILENT. You get three attune slots, so this is a real
-- choice made at a screen that gave you no way to see it: a live `sp list` had Bashing2 attuning
-- [Aelkesh, Marak, Ri'shen], which turns off a Knight's Resolve the character had already claimed.
--
-- PARSE THE SENTENCE, NOT A NAME TABLE. Every one of these descriptions says "attuned to <Spirit>"
-- in its own words, exactly as the damage-suppression affixes always name their own damage type
-- (v4.7.186). A boon->spirit lookup table would cover today's four and go stale on the fifth.
function M._spiritGate(description)
  if type(description) ~= "string" then return nil end
  return description:match("attuned to ([A-Z][%a']+)")
end

-- Is that spirit attuned RIGHT NOW? Three-state on purpose: true / false / nil = "cannot tell".
-- `shaman.spiritlore` is populated by text triggers off SPIRIT BINDINGS, so on a non-Shaman -- or
-- before the first read -- the honest answer is unknown, and claiming "not attuned" there would be
-- a confident wrong answer at a screen where the user is choosing.
function M._attuned(spirit)
  if not spirit then return nil end
  local sl = shaman and shaman.spiritlore
  local list = sl and sl.attunements
  if type(list) ~= "table" or next(list) == nil then return nil end
  for _, s in ipairs(list) do
    if type(s) == "string" and s:lower() == spirit:lower() then return true end
  end
  return false
end

-- Which saved `sp` profile would satisfy it -- the actionable half. Sorted so the answer is
-- deterministic rather than pairs-order roulette.
function M._profileWith(spirit)
  local sl = shaman and shaman.spiritlore
  if not (spirit and sl and type(sl.profiles) == "table") then return nil end
  local hits = {}
  for name, prof in pairs(sl.profiles) do
    for _, s in ipairs((prof and prof.attunements) or {}) do
      if type(s) == "string" and s:lower() == spirit:lower() then hits[#hits + 1] = name; break end
    end
  end
  table.sort(hits)
  return hits[1]
end

-- Offer-screen annotation, beside _echoImmunities. Says nothing when no offered boon is gated.
function M._echoAttuneGated(list)
  for _, b in ipairs(list or {}) do
    local spirit = M._spiritGate(b.description)
    if spirit then
      local on = M._attuned(spirit)
      if on == true then
        M.echo("<pale_green>ATTUNED<reset> -- <gold>" .. tostring(b.name)
          .. "<reset> needs <cyan>" .. spirit .. "<reset>, which is up.")
      elseif on == false then
        local prof = M._profileWith(spirit)
        M.echo("<indian_red>INERT<reset> -- <gold>" .. tostring(b.name)
          .. "<reset> does nothing unless <cyan>" .. spirit .. "<reset> is attuned"
          .. (prof and (" (<white>sp " .. prof .. "<reset> has it)") or "") .. ".")
      else
        M.echo("<gold>" .. tostring(b.name) .. "<reset> needs <cyan>" .. spirit
          .. "<reset> attuned -- <DimGrey>attunements unknown, check <white>sp list<reset>.")
      end
    end
  end
end

-- Claim-time warning. Louder than the offer note, because by now it is spent.
function M._warnAttuneOnClaim(name)
  if not name or name == "" then return end
  -- History first (this run's offer screen carries the live wording), then the SEED DB. The
  -- fallback is load-bearing, not belt-and-braces: _histBoonInfo only reads offers recorded this
  -- session, so a claim made without a parsed offer screen -- a re-latch, a manual BOON CLAIM,
  -- a missed capture -- would have no description at all, and the warning would silently never
  -- fire on exactly the paths where the user is least likely to have seen the offer note.
  local _, description = M._histBoonInfo(name)
  if (not description or description == "") and M.BOON_SEED then
    local seed = M.BOON_SEED[name]
    description = seed and seed.description or description
  end
  local spirit = M._spiritGate(description)
  if not spirit then return end
  if M._attuned(spirit) == false then
    local prof = M._profileWith(spirit)
    M.echo("<indian_red>WARNING<reset> -- <gold>" .. tostring(name)
      .. "<reset> is INERT: <cyan>" .. spirit .. "<reset> is not attuned"
      .. (prof and (", try <white>sp " .. prof) or "") .. "<reset>.")
  end
end

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

-- REROLLS ARE INFERRED FROM THE SCREEN, NEVER FROM A COMMAND (v4.7.298).
--
-- `BoonsOfferedRequest.reroll_count` is an integer field we had never sent. Rerolls are real --
-- the `Negotiator` boon's own text grants "5 additional rerolls" -- but we have never captured
-- the command that spends one, and inventing a command name is how `bash dwaeonic off` came to
-- be documented for a command that never existed (v4.7.265). So this counts the EVIDENCE
-- instead: a second offer screen, with no claim and no wave in between, IS a reroll.
--
-- THE NAME SET IS THE GUARD, and it is what makes the inference safe. A reroll produces a
-- DIFFERENT set of boons; a screen that merely re-prints -- a scrollback, a re-issued command,
-- a duplicated capture -- produces the identical set. Comparing against `run.lastOffered`, which
-- we already keep for resolving claim spellings, separates the two without knowing what caused
-- the reprint. An identical reprint therefore neither counts nor resets: it is not evidence
-- either way.
--
-- The chain is ended by a claim (M.onBoonClaim) and by GO! (M.onGo), never by the ripple number
-- -- see the note in onGo for why that number cannot be trusted between two screens of one chain.
function M._nameSet(list)
  local set, n = {}, 0
  for _, b in ipairs(list or {}) do
    local name = (type(b) == "table") and b.name or b
    if type(name) == "string" and name ~= "" and not set[name] then
      set[name] = true
      n = n + 1
    end
  end
  return set, n
end

function M._sameOffer(prevNames, list)
  local a, an = M._nameSet(prevNames)
  local b, bn = M._nameSet(list)
  if an == 0 or an ~= bn then return false end
  for name in pairs(a) do
    if not b[name] then return false end
  end
  return true
end

-- THE CHAIN LIVES ON `ataxiaTemp`, NOT ON `M.run` (deep review, v4.7.298).
--
-- `M.run` is a plain table hanging off `ataxia`, and `ataxia_saveSettings` does
-- `table.save(file, sanitizeForSave(ataxia))` -- a WHOLESALE serialization that strips only
-- functions, metatabled objects and GUI snapshots. Scalars like these two go straight to disk,
-- and `deepMerge` ends in an unconditional `dst[k] = v`, so the disk value wins on load. That is
-- exactly the trap CLAUDE.md documents from v4.7.192-194, and the reason `_relatchBoons` already
-- keeps its guard here rather than under `ataxia`.
--
-- Note for anyone reading `002_Reporter_API.lua`'s header: its claim that run state is
-- "in-memory only" is FALSE -- `run.active`, `ripple`, `publicId` and `lastOffered` all persist
-- today. Correcting that is out of scope here; what is in scope is not adding to it.
--
-- `ataxiaTemp` is never serialized (only `ataxia`, `ataxiaBasher`, `ataxiaBasherPaths`,
-- `ataxiaNDB`, `ataxiaExtraction` and `selfLimbDamage.config` are written to disk), so these
-- two are guaranteed to start clean on every load -- which for a per-screen counter is the only
-- correct starting state.
function M._rerollCount()
  ataxiaTemp = ataxiaTemp or {}
  return tonumber(ataxiaTemp.mnemRerolls) or 0
end

function M._rerollReset()
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.mnemRerolls = 0
  ataxiaTemp.mnemOfferChain = false
end

function M._rerollBump(list)
  ataxiaTemp = ataxiaTemp or {}
  -- A chain needs a PREVIOUS SCREEN to differ from. Requiring names as well as the flag is
  -- belt-and-braces: with no previous names there is nothing a reroll could have replaced, so
  -- the only honest answer is 0.
  local _, prevCount = M._nameSet(M.run.lastOffered)
  local continuing = (ataxiaTemp.mnemOfferChain == true) and prevCount > 0
  if continuing and not M._sameOffer(M.run.lastOffered, list) then
    ataxiaTemp.mnemRerolls = M._rerollCount() + 1
    M.decho("Offer replaced with no claim in between -- reroll #" .. tostring(ataxiaTemp.mnemRerolls))
  elseif not continuing then
    ataxiaTemp.mnemRerolls = 0
  end
  ataxiaTemp.mnemOfferChain = true
end

function M.onBoonsOffered()
  M._rerollsLeft = nil -- this screen's footer says it again (trigger 094)
  M._offerGoneAt, M._offerGoneWhy = nil, nil -- a new screen: its boons can be contemplated again
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
      -- Cleaned BEFORE anything reads it -- catalogue, history, reroll test and the post all see
      -- the same list (v4.7.322, see `_cleanOfferList`).
      local list = M._cleanOfferList(M._parseNamedBlock(lines))
      if #list == 0 then return end

      -- Local catalogue FIRST and unconditionally: the offer screen is the only place a boon's
      -- description is ever shown, so if we don't take it here it is gone the moment you claim.
      if M._learnBoon then
        for _, b in ipairs(list) do
          M._learnBoon(b.name, b.description, nil, nil, { comboBoon = b.combo_boon, category = b.category })
        end
        M._historySave()
      end

      -- Immunity annotation (v4.7.224). Above the telemetry gate on purpose: this is decision
      -- support shown while the offer screen is up, and it must not depend on `mnem` reporting
      -- being switched on. pcall'd because nothing about a display nicety justifies breaking
      -- the capture that feeds the catalogue and the API.
      if M._echoImmunities then pcall(M._echoImmunities, list) end
      if M._echoAttuneGated then pcall(M._echoAttuneGated, list) end
      if M._echoBoonCallouts then pcall(M._echoBoonCallouts, list) end -- v4.7.325/326: conflicts, combo, echo

      -- Everything below is telemetry.
      if not M._inRun() then return end
      -- BEFORE lastOffered is overwritten: the comparison against the previous screen's names is
      -- the entire reroll test, and this line is what would destroy it.
      --
      -- A RE-PRINT IS NOT A SECOND OFFER (deep review). The name-set guard inside `_rerollBump`
      -- stops an identical screen inflating the COUNT, but the count was never the only thing
      -- downstream: `_offerAfterRipple` below would re-send `wade status` and post a second,
      -- identical `/boons_offered`, giving the tracker two rows for one offer event. The
      -- comment on `_rerollBump` says a re-print "is not evidence either way" -- so it must not
      -- produce a report either.
      ataxiaTemp = ataxiaTemp or {}
      local reprint = (ataxiaTemp.mnemOfferChain == true) and M._sameOffer(M.run.lastOffered, list)
      M._rerollBump(list)
      -- Remember canonical names so a later BOON CLAIM can be reported
      -- with the exact spelling the game used.
      M.run.lastOffered = {}
      for _, b in ipairs(list) do
        table.insert(M.run.lastOffered, b.name)
        -- PROOF THE NAME EXISTS (v4.7.328): the game just printed it. If an old refusal
        -- blacklisted it (see `onContemplateUnknown`), clear that -- otherwise a boon wrongly
        -- marked once would never be contemplated again.
        if M.boonUnknownRetry then pcall(M.boonUnknownRetry, (M._baseBoonName and M._baseBoonName(b.name)) or b.name) end
      end
      if reprint then
        return M.decho("Identical offer re-printed -- not re-reporting.")
      end
      M._offerAfterRipple(list)
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
  -- A CLAIM ENDS THE CHAIN, which is what keeps Prospero's Fortune from being miscounted:
  -- Negotiator's every-fifth-claim second pick opens another offer screen, but a claim
  -- intervened, so the screen that follows starts a fresh chain rather than reading as a reroll.
  M._rerollReset()
  -- The other options are gone the moment we claim, so the contemplate chain must stop asking
  -- for them (v4.7.328): this is what keeps the refusal from happening at all.
  if M.offerScreenGone then M.offerScreenGone("claim") end
  if M._recordClaim then M._recordClaim(canonical) end -- local history (#6)
  if M.latchBoonFlag then M.latchBoonFlag(canonical) end -- generic flags (v4.7.241)
  -- The bonuses panel is derived from the claim history, so it is stale the instant a claim
  -- lands. pcall'd: a display refresh must never break the claim path it hangs off.
  if M.bonuses and M.bonuses.refresh then pcall(M.bonuses.refresh) end
  M.reportBoonsSelected(canonical)
  -- ...and arm the VERIFICATION. Everything above happens because we SENT the command
  -- (see the alias): the flag latches, the history records, the telemetry posts. Nothing
  -- yet knows whether the game accepted it. See M.onBoonClaimConfirmed below.
  M._armClaimVerify(canonical)
end

-- ---------------------------------------------------------------------------
-- THE CLAIM CONFIRMATION LINE (v4.7.278) -- `A fulgent eddy falls still.`
-- ---------------------------------------------------------------------------
--
-- From MediaRes' tracker, and it closes a real hole. Our boon flags latch at SEND time
-- (aliases/.../002_Boon_Claim.lua passes the command through, then calls onBoonClaim), so a
-- claim the game REFUSES -- wrong name, eddy already spent, screen gone -- still flips the
-- flag. We then run that boon's automation for the rest of the run on a boon we do not
-- hold: the Bard swaps to paean for a Warmarch we never got, the Knight swings arc at 3
-- denizens for an Indiscriminate that is not there.
--
-- This is the rule this codebase keeps re-learning stated once more: WHERE THE GAME SPEAKS
-- ABOUT ITS OWN STATE, OUR BOOKKEEPING IS THE FALLBACK (v4.7.266 distortion, v4.7.270
-- augment refusal, v4.7.271 augment cooldown).
--
-- IT WARNS, IT DOES NOT UN-LATCH. Deliberate, and the same call made for the Arc proof of
-- life (v4.7.245): this wording is captured from one source and we have never seen it
-- ourselves. If it turns out claims can succeed silently -- a different wording, a gag, a
-- line eaten by a spammy screen -- then auto-reverting would strip real boons, which is a
-- far worse failure than a warning that occasionally cries wolf. Promote it to an un-latch
-- only once the line is confirmed to fire on every successful claim.
M.CLAIM_CONFIRM_WINDOW = 4 -- seconds a claim may stay unconfirmed before we say so

function M._armClaimVerify(canonical)
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.mnemClaimPending = { name = canonical, at = (getEpoch and getEpoch()) or os.time() }
end

function M.onBoonClaimConfirmed()
  ataxiaTemp = ataxiaTemp or {}
  local p = ataxiaTemp.mnemClaimPending
  ataxiaTemp.mnemClaimPending = nil
  ataxiaTemp.mnemClaimConfirms = (tonumber(ataxiaTemp.mnemClaimConfirms) or 0) + 1
  -- A confirmation with nothing pending is not an error: the user can claim from the game's
  -- own menu without going through our alias, and that is a claim we never armed.
  if not p then return end
  M.decho("boon claim CONFIRMED: " .. tostring(p.name))
end

-- Polled rather than timered, so it is reload-safe (a tempTimer id must never be serialized,
-- v4.7.192) and so a claim armed before a SYSUPDATE cannot leave a warning permanently owed.
function M.checkClaimVerify()
  ataxiaTemp = ataxiaTemp or {}
  local p = ataxiaTemp.mnemClaimPending
  if not p then return nil end
  local now = (getEpoch and getEpoch()) or os.time()
  if (now - (tonumber(p.at) or now)) < (tonumber(M.CLAIM_CONFIRM_WINDOW) or 4) then return nil end
  ataxiaTemp.mnemClaimPending = nil
  -- Only worth warning if we have EVER seen the line. Until then we cannot distinguish "the
  -- claim failed" from "this game does not print that line to us", and warning on the latter
  -- every single claim would train the user to ignore it.
  if (tonumber(ataxiaTemp.mnemClaimConfirms) or 0) == 0 then
    M.decho("claim verify: no confirmation seen yet, and none ever seen -- staying quiet.")
    return nil
  end
  M.echo("<indian_red>BOON CLAIM UNCONFIRMED<reset> -- <white>" .. tostring(p.name)
    .. "<reset> was claimed but no <grey>'A fulgent eddy falls still.'<reset> followed."
    .. "\n  <a_darkmagenta>Its automation is armed anyway. Check <white>BOONS<a_darkmagenta> before trusting it.")
  return p.name
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
-- ---------------------------------------------------------------------------
-- THE OFFER HAS TO CARRY THE RIGHT RIPPLE (v4.7.279)
-- ---------------------------------------------------------------------------
--
-- Reported by the tracker's author, 2026-08-20:
--
--   "you're sending boons a ripple late so you're not sending the boons that are
--    initially offered ... you're also sending boon information that you have cached
--    and not sending what's actually offered"
--
-- `BoonsOfferedRequest` has NO ripple field -- token, offered, class, race, and that is
-- the whole schema (re-verified against the live openapi.json). So the server files an
-- offer under whatever ripple our LAST `/ripple_level` told it. Timing is the only lever
-- we have, and ours was wrong at both ends:
--
--   * We send `wade status` on GO! and nowhere else, so `/ripple_level` is only ever
--     updated at the START of a wave. An offer posted at the boon screen therefore lands
--     under the ripple we have just FINISHED.
--   * At the very FIRST offer -- the one before wave one -- we have never sent
--     `/ripple_level` at all, so the server has no ripple for it. That is exactly "not
--     sending the boons that are initially offered": the report goes out with no place to
--     put it.
--
-- The reference client (MediaRes' standalone tracker) sends `wade status` when the offer
-- block CLOSES and posts the offer after it. This does the same: ask, wait for the ripple
-- to be reported, then send the offer behind it. The HTTP queue is serial, so enqueueing
-- `/boons_offered` after `/ripple_level` is enough to guarantee the order on the wire.
--
-- BOUNDED, BECAUSE DEFERRING THIS IS EXACTLY WHAT BROKE IT BEFORE. v4.7.91 removed a
-- deferral (the per-boon CONTEMPLATE chain) that could stall and silently drop the entire
-- report. So this one cannot stall: whatever happens, the offer posts -- on the ripple line
-- if it arrives, on a timer if it does not. Never dropped, at worst filed where it is now.
M.OFFER_RIPPLE_WAIT = 3 -- seconds to wait for the ripple line before posting anyway

-- DROP a pending offer without posting it. Used at a run boundary: the offer belongs to a run
-- that is over, so flushing it would file it under the wrong run -- the one case where losing it
-- is better than sending it. Nothing cleared this slot before, which was survivable only while a
-- replaced offer was silently discarded; now that a replacement FLUSHES, a stale pending offer
-- would be posted into the next run.
function M._dropPendingOffer()
  M._pendingOffer = nil
  M._pendingRerolls = nil
  if M._offerTimer then pcall(killTimer, M._offerTimer); M._offerTimer = nil end
end

function M._offerAfterRipple(list)
  -- FLUSH THE PREVIOUS SCREEN, DO NOT DROP IT (deep review).
  --
  -- `_pendingOffer` is a single slot and this function used to overwrite it unconditionally.
  -- That was right when it was written (v4.7.279): a second screen arriving before the first had
  -- posted meant a duplicate capture, and keeping the newer one was the safe call. THE REROLL
  -- FEATURE MAKES TWO DISTINCT, MEANINGFUL SCREENS A NORMAL EVENT, and nothing reconciled the
  -- two -- so a rerolled-away screen was never posted and never recorded to local history, which
  -- is precisely the data `reroll_count` exists to make sense of.
  --
  -- Flushing here is ripple-safe: a reroll happens at the same boon screen, so the previous
  -- screen belongs to the same ripple the pending `wade status` was already asking about.
  -- The original test's intent -- "a second offer screen must not be posted with the first
  -- screen's list" -- is preserved exactly; only the discarding changes.
  if M._pendingOffer then M._flushPendingOffer("replaced") end
  M._pendingOffer = list
  -- THE COUNT IS SNAPSHOTTED WITH THE LIST, never re-read at send time. The POST is deferred
  -- (ripple line, or the timeout below), and `onBoonClaim`/`onGo` both zero the chain the moment
  -- they fire -- so a player claiming inside that window would otherwise make the LAST screen of
  -- a chain, the most informative row there is, report `reroll_count = 0`.
  M._pendingRerolls = M._rerollCount()
  -- A stale timer from a previous screen must not fire against this list.
  if M._offerTimer then pcall(killTimer, M._offerTimer); M._offerTimer = nil end
  -- Ask for the ripple. Gated exactly like the GO! send: `_auto()` rather than `_inRun()`,
  -- so an offer seen before the run-start line was noticed still bootstraps one.
  if M._auto() or (ataxiaBasher and ataxiaBasher.inMnemosyne) then
    send("wade status", false)
  end
  M._offerTimer = tempTimer(M.OFFER_RIPPLE_WAIT, function() M._flushPendingOffer("timeout") end)
end

-- Called from onRipple (the ripple has just been reported) and from the timeout. Whichever
-- gets here first wins; the second finds nothing pending and does nothing.
-- ONE GAP PER BOON SCREEN, and only once the offer is off our hands (v4.7.295).
--
-- User: "We should be constantly updating our Boon database." The catalogue cannot be rebuilt --
-- a description is shown once, on a screen that is gone a second later -- so anything that closes
-- holes without being asked is worth more than a command nobody remembers to type.
--
-- THE MOMENT IS THE WHOLE DESIGN. The boon screen is the only long quiet stretch in a run: the
-- explorer is paused, combat is over, and the user is reading. But it is ALSO when the offer
-- capture runs, and `_captureLines` holds ONE global slot whose second caller force-finishes the
-- first (v4.7.93) -- which is exactly the race v4.7.279 had to unpick when contemplate enrichment
-- silently dropped whole offer reports. So this fires only AFTER the offer has been flushed, waits
-- another `BOON_FILL_IDLE` seconds, and then still refuses if anything holds the slot.
--
-- ONE per screen, not a batch: a trickle cannot starve a capture, and over a twenty-ripple run it
-- closes twenty holes on its own.
M.BOON_FILL_IDLE = 4

function M._boonFillTrickle()
  if not (M.history and M.history.boonLibrary) then return false end
  if M._capturing then return false end            -- something else owns the slot
  local gaps = M.boonGaps()
  if #gaps == 0 then return false end
  M._boonFillNext({ gaps[1] }, 1, 0)
  return true
end

function M._flushPendingOffer(why)
  local list = M._pendingOffer
  local rerolls = M._pendingRerolls
  M._pendingOffer = nil
  M._pendingRerolls = nil
  if M._offerTimer then pcall(killTimer, M._offerTimer); M._offerTimer = nil end
  if type(list) ~= "table" or #list == 0 then return false end
  M.decho("posting /boons_offered (" .. tostring(why) .. ") at ripple "
    .. tostring(M.run and M.run.ripple))
  M._reportBoonsOfferedEnriched(list, rerolls)
  -- The offer is off our hands, so the capture slot is free and the boon screen is the quietest
  -- stretch of a run. After a pause, CONTEMPLATE EVERY OFFERED BOON (v4.7.324, user: "they
  -- constantly change these") plus one catalogue gap -- see `M._boonScreenContemplate`, which
  -- refuses if anything has taken the slot in the meantime and stops at GO!.
  if tempTimer and M.BOON_FILL_IDLE then
    tempTimer(M.BOON_FILL_IDLE, function()
      local ok, started = false, false
      if M._boonScreenContemplate then ok, started = pcall(M._boonScreenContemplate, list) end
      -- No chain means no chain END to print the summary at (v4.7.327): print it now.
      if not (ok and started) and M.offerSummary then pcall(M.offerSummary, list) end
    end)
  end
  return true
end

function M._reportBoonsOfferedEnriched(list, rerolls)
  -- Post the offer to the API IMMEDIATELY, with the name+description straight off the offer screen.
  -- The old design gated the report behind a slow (~2.5s/boon) BOON CONTEMPLATE enrichment chain,
  -- which (a) races the NEXT ripple's captures for the single `_capturing` slot -- when it loses, the
  -- chain STALLS and the ENTIRE /boons_offered is silently dropped (the reported bug: monsters posted,
  -- boons never did), and (b) even when it completes it can post AFTER the player has waded, landing
  -- the boons on the wrong ripple. Name+description is what the tracker shows; rarity/echoes are
  -- optional and are still learned locally from the BOONS list (trigger 013) + `mnem boonfill`.
  if M._recordOffers then M._recordOffers(list) end -- local history (#6)
  M.reportBoonsOffered(list, rerolls)
end

-- `_contemplateNext` / `_applyContemplate` -- the pre-v4.7.279 chain that CONTEMPLATEd each offered
-- boon before posting -- were removed in v4.7.322. Nothing had called them since v4.7.279, and
-- `_applyContemplate` copied a parse's `meta` table straight into the offer entry, so reviving the
-- chain would have put raw screen labels on the wire.

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
-- EVERY NAME WE KNOW OF, not just the ones we are holding (v4.7.295).
--
-- `boonFill` used to read `ataxiaTemp.boonsOwned` alone, so it could only ever describe boons we
-- had already been offered AND claimed. That is the smaller half of the problem: the catalogue's
-- holes are precisely the boons we have NEVER been offered -- 25 of them declared outright in
-- `M.BOON_UNDESCRIBED` after the 2026-09-01 rebalance named thirty-three new boons without saying
-- what any of them did, plus four we have working automation for and no text at all (Kai Unleashed,
-- Daemon Jaws, Necrotic Aura, Icy Heart).
--
-- `BOON CONTEMPLATE <name>` answers for any name, held or not, which is what makes the wider pool
-- reachable. Three sources, unioned:
--   * the SEED           -- includes every declared hole
--   * the LIBRARY        -- anything learned or imported, in case a row lost its description
--   * `boonsOwned`       -- what the last BOONS list showed, which may name something new
-- NAMES THE GAME DOES NOT RECOGNISE ARE NOT GAPS (v4.7.308). "You consider for a time, but no
-- information comes to you on such a boon." is the game's answer to a name it does not know --
-- and until this version nothing heard it, so the trickle asked the SAME first gap at every boon
-- screen of every run, forever, and learned nothing. The 25 name-only holes came from the
-- 2026-09-01 ANNOUNCEMENT, not from the game's own BOONS list, so a spelling the game does not
-- use is exactly what to expect. `M.history.boonUnknown[name]` (persisted) is set from the refusal
-- (trigger mnemosyne/089 -> M.onContemplateUnknown), skipped here, listed by `mnem boonfill
-- unknown`, and cleared by `mnem boonfill retry <name>` once the seed's spelling is corrected.
function M.boonUnknown(name)
  local u = M.history and M.history.boonUnknown
  return (u and name and u[name]) and true or false
end

function M.boonGaps()
  local gaps, seen = {}, {}
  local function consider(name)
    if type(name) ~= "string" or name == "" or seen[name] then return end
    seen[name] = true
    if M.boonUnknown(name) then return end
    local rec = M.boonInfo and M.boonInfo(name)
    if rec and rec.description and rec.description ~= "" then return end
    local sd = M.BOON_SEED and M.BOON_SEED[name]
    if sd and sd.description and sd.description ~= "" then return end
    gaps[#gaps + 1] = name
  end
  for name in pairs(M.BOON_SEED or {}) do consider(name) end
  for name in pairs((M.history and M.history.boonLibrary) or {}) do consider(name) end
  for name in pairs((ataxiaTemp and ataxiaTemp.boonsOwned) or {}) do consider(name) end
  table.sort(gaps)
  return gaps
end

-- CONTEMPLATE EVERY BOON, NO MATTER WHAT (v4.7.324, user-directed).
--
-- User, with an offer screen: "We should boon contemplate all boons no matter what as they
-- constantly change these to be different or add things to them." Until now a boon was contemplated
-- at most ONCE -- `boonGaps` only queued boons with no description, and v4.7.322's combo pass marked
-- each one `comboChecked` and never asked again -- so a boon the game later rewrote kept its old text
-- and its old quote, category and combo status for good.
--
-- So contemplation is now a CYCLE, and nothing leaves it:
--   * every boon on an offer screen is contemplated once that offer has posted (`_boonScreenContemplate`);
--   * `mnem boonfill` works through the WHOLE catalogue, never-contemplated first (seeded combo boons
--     first among those), then oldest `contemplatedAt` -- so a full cycle simply starts over;
--   * a complete, validated contemplate UPDATES the text as well as the rest, and says when it changed.
-- Echo rows ("(ECHO) Name") contemplate as their base boon; names the game refused are skipped.
local function baseName(name)
  if type(name) ~= "string" then return nil end
  local clean = name:gsub("^%(ECHO%)%s*", ""):gsub("^%s+", ""):gsub("%s+$", "")
  return clean ~= "" and clean or nil
end

-- When a boon was last contemplated: nil = never; a legacy v4.7.322 `comboChecked` counts as long ago.
local function contemplatedAt(rec)
  if type(rec) ~= "table" then return nil end
  if tonumber(rec.contemplatedAt) then return tonumber(rec.contemplatedAt) end
  if rec.comboChecked then return 0 end
  return nil
end

function M.boonMetaGaps()
  local never, seen = {}, {}
  for name, rec in pairs((M.history and M.history.boonLibrary) or {}) do
    if type(name) == "string" and type(rec) == "table"
       and type(rec.description) == "string" and rec.description ~= ""
       and not name:find("^%(ECHO%)") and not M.boonUnknown(name) then
      if contemplatedAt(rec) == nil then never[#never + 1] = name else seen[#seen + 1] = name end
    end
  end
  local lib = M.history.boonLibrary
  -- Never-contemplated first, the seeded combo boons first among them: seeing -- or not seeing --
  -- "Combo Boon?" on their contemplate is what settles which screen prints that line.
  table.sort(never, function(a, b)
    local ca, cb = lib[a].comboBoon == true, lib[b].comboBoon == true
    if ca ~= cb then return ca end
    return a < b
  end)
  -- Then the stalest.
  table.sort(seen, function(a, b)
    local ta, tb = contemplatedAt(lib[a]), contemplatedAt(lib[b])
    if ta ~= tb then return ta < tb end
    return a < b
  end)
  for _, name in ipairs(seen) do never[#never + 1] = name end
  return never
end

-- Start the cycle over (`mnem boonfill recheck`). The ANSWERS stay: nothing here can tell a stale
-- value from a current one, and the next contemplate overwrites what it shows.
function M.boonRecheck()
  local n = 0
  for _, rec in pairs((M.history and M.history.boonLibrary) or {}) do
    if type(rec) == "table" and (rec.comboChecked or rec.contemplatedAt) then
      rec.comboChecked, rec.contemplatedAt = nil, nil
      n = n + 1
    end
  end
  if n > 0 and M._historySaveSoon then M._historySaveSoon() end
  return n
end

-- BOUNDED BY DEFAULT. Each entry is one CONTEMPLATE and one captured block, and the capture slot
-- is shared with the offer and effects parsers -- so filling all of them in one burst is the same
-- race v4.7.279 had to unpick. `mnem boonfill` takes a handful; `mnem boonfill all` is the
-- deliberate opt-in for a quiet moment on the riverbank. Description gaps are queued first; the
-- rest of the batch goes to the contemplate cycle (v4.7.322, v4.7.324).
M.BOON_FILL_BATCH = 8

function M.boonFill(limit)
  if M._fillBusy() then
    return M.echo("A boon contemplation is already running -- <cyan>mnem boonfill<grey> again once it finishes.")
  end
  local gaps = M.boonGaps()
  local metaGaps = M.boonMetaGaps()
  if #gaps == 0 and #metaGaps == 0 then
    return M.echo("Boon catalogue is empty -- nothing to contemplate yet.")
  end
  local n = (limit == "all") and (#gaps + #metaGaps) or (tonumber(limit) or M.BOON_FILL_BATCH)
  local todo, meta, nMeta = {}, {}, 0
  for _, name in ipairs(gaps) do
    if #todo < n then todo[#todo + 1] = name end
  end
  local nDesc = #todo
  for _, name in ipairs(metaGaps) do
    if #todo < n then todo[#todo + 1] = name; meta[name] = true; nMeta = nMeta + 1 end
  end
  M.echo("Contemplating <cyan>" .. #todo .. "<grey> boon(s): <cyan>" .. nDesc .. "<grey> of <cyan>"
    .. #gaps .. "<grey> undescribed, <cyan>" .. nMeta .. "<grey> of <cyan>" .. #metaGaps
    .. "<grey> in the refresh cycle, stalest first (~" .. string.format("%.0f", #todo * 0.6) .. "s)...")
  M._boonFillNext(todo, 1, 0, M._fillCtx(meta))
end

-- ONE CHAIN AT A TIME (review, v4.7.326). Two chains -- the per-offer run and a `mnem boonfill`
-- typed while it goes -- would take turns at the capture slot and interleave their contemplates.
-- Every step stamps the lock and every exit clears it; a step that never comes back (an error in a
-- callback) cannot hold it past FILL_STALE, which is longer than any real step (a 2s capture, the
-- 0.5s spacing, and at most five 1s waits for the slot).
local FILL_STALE = 15
local function fillNow() return (getEpoch and getEpoch()) or os.time() end

function M._fillBusy()
  return M._fillBusyAt ~= nil and fillNow() - M._fillBusyAt < FILL_STALE
end

-- The bookkeeping one run of `_boonFillNext` carries. `gen` ties it to the wave it started in: GO!
-- bumps `M._fillGen`, and a run from an earlier wave stops rather than race that wave's captures.
function M._fillCtx(meta, auto)
  return { meta = meta or {}, checked = 0, lines = 0, noLine = {}, changed = {},
           gen = M._fillGen or 0, auto = auto and true or false, waits = 0 }
end

-- EVERY OFFERED BOON, EVERY SCREEN (v4.7.324). Runs once the offer has POSTED (`_flushPendingOffer`),
-- so the report never waits on it -- the exact reason v4.7.279 took contemplation off the offer
-- path, where it raced the next ripple's captures and dropped whole reports. What it contemplates
-- feeds the NEXT post of that boon. Plus one description gap, as the old one-per-screen trickle did.
-- Never starts while another capture holds the slot, and stops at GO!.
function M._boonScreenContemplate(list)
  if not (M.history and M.history.boonLibrary) then return false end
  if M._capturing or M._fillBusy() then return false end
  local todo, meta, queued = {}, {}, {}
  for _, b in ipairs(type(list) == "table" and list or {}) do
    local name = baseName(type(b) == "table" and b.name or b)
    if name and not queued[name] and not M.boonUnknown(name) then
      queued[name] = true
      todo[#todo + 1] = name
      local rec = M.boonInfo and M.boonInfo(name)
      if type(rec) == "table" and rec.description and rec.description ~= "" then meta[name] = true end
    end
  end
  for _, gap in ipairs(M.boonGaps()) do
    if not queued[gap] then queued[gap] = true; todo[#todo + 1] = gap; break end
  end
  -- ...and one COMBO component we have never contemplated (v4.7.328, user: "we need to boon
  -- contemplate those and add them to the database"). One per screen, like the gap above: a recipe
  -- fills itself in over a few offers without spending a command on it.
  for _, gap in ipairs((M.comboGaps and M.comboGaps()) or {}) do
    if not queued[gap] then queued[gap] = true; todo[#todo + 1] = gap; break end
  end
  if #todo == 0 then return false end
  local ctx = M._fillCtx(meta, true)
  ctx.offered = list -- the advisor's summary prints when this chain ends (v4.7.327)
  M._boonFillNext(todo, 1, 0, ctx)
  return true
end

local function sameText(a, b)
  local function norm(s) return (tostring(s or ""):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")) end
  return norm(a) == norm(b)
end

-- `ctx` is nil for the automatic trickle's single description gap; otherwise it carries a run's
-- bookkeeping (`M._fillCtx`): which names are already described (`meta`), what was checked, which
-- printed the combo line, which SEEDED combo boons came back without it, and which texts changed.
function M._boonFillNext(todo, i, learned, ctx)
  if ctx then
    ctx.checked, ctx.lines = ctx.checked or 0, ctx.lines or 0
    ctx.noLine, ctx.changed = ctx.noLine or {}, ctx.changed or {}
  end
  M._fillBusyAt = fillNow()
  if ctx and ctx.gen and ctx.gen ~= (M._fillGen or 0) then
    -- A wave started. Its captures own the slot now; what is left waits for the next boon screen.
    M._fillBusyAt = nil
    M._historySave()
    if not ctx.auto then
      M.echo("Boon contemplation paused at <cyan>" .. (i - 1) .. "/" .. #todo
        .. "<grey> -- the next wave started. <cyan>mnem boonfill<grey> resumes with the stalest.")
    end
    return
  end
  if i > #todo then
    M._fillBusyAt = nil
    M._historySave()
    -- THE OFFER'S SUMMARY (v4.7.327): everything the chain just learned, judged. After the
    -- catalogue line when there is one, and even when the chain itself had nothing to say.
    local function advise()
      if ctx and ctx.offered and M.offerSummary then pcall(M.offerSummary, ctx.offered) end
    end
    local quiet = ctx and ctx.auto and learned == 0 and #ctx.changed == 0
    if quiet then return advise() end
    local msg = "Boon catalogue updated: <cyan>" .. learned .. "<grey> learned."
    if ctx and ctx.checked > 0 then
      msg = msg .. " Contemplated <cyan>" .. ctx.checked .. "<grey>; <cyan>" .. #ctx.changed
        .. "<grey> changed; the 'Combo Boon?' line appeared on <cyan>" .. ctx.lines .. "<grey>."
      if #ctx.noLine > 0 then
        msg = msg .. " <yellow>No 'Combo Boon?' line on " .. table.concat(ctx.noLine, ", ")
          .. "<grey> (seeded as combo from the tracker's data) -- that line may be printed by the"
          .. " offer screen rather than CONTEMPLATE."
      end
    end
    M.echo(msg .. " Run <cyan>BOONS<grey> to see them.")
    return advise()
  end
  -- NEVER TAKE THE SLOT FROM ANOTHER CAPTURE (v4.7.324). `_captureLines` force-finishes whatever
  -- holds it, so a contemplate started mid-WADE-STATUS would cut that capture short. Wait for it;
  -- give up after a few tries rather than spin.
  if M._capturing then
    if ctx then
      ctx.waits = (ctx.waits or 0) + 1
      if ctx.waits <= 5 then
        tempTimer(1, function() M._boonFillNext(todo, i, learned, ctx) end)
        return
      end
    end
    M._fillBusyAt = nil
    M._historySave()
    return
  end
  local name = todo[i]
  -- The screen these came from has closed (v4.7.328): asking would only collect a refusal.
  if ctx and ctx.offered and M._offerGone and M._offerGone() and M._wasOffered(name) then
    return M._boonFillNext(todo, i + 1, learned, ctx)
  end
  local metaOnly = ctx and ctx.meta and ctx.meta[name] or false
  local before = M.boonInfo and M.boonInfo(name)
  local oldText = type(before) == "table" and before.description or nil
  local seededCombo = type(before) == "table" and before.comboBoon == true
  M._captureContemplate(function(info)
    -- A REAL, WHOLE CONTEMPLATE BLOCK (v4.7.322, v4.7.324). Every one we have seen prints `Rarity:`
    -- or `Can echo:` before the text, and ends on its closing divider. The capture is
    -- divider-bounded and shares one slot, so it can catch the wrong block (Deadly Finesse's
    -- "description" became two WADE STATUS lines) or be cut short by a timeout or another capture.
    -- Now that a contemplate may REWRITE a description, a block that is not provably whole is
    -- worth nothing: learn nothing from it, and do not mark the boon contemplated.
    local real = type(info) == "table" and info.complete ~= false
      and (info.rarity ~= nil or info.num_echoes_possible ~= nil)
    if real and M._learnBoon then
      -- A CONTEMPLATE IS A COMMAND SPENT AND A CAPTURE SLOT HELD, so take everything it printed
      -- (v4.7.298), and the conflicts list since v4.7.325.
      local extra = {
        quote = info.quote,
        category = info.category,
        unlockedBy = info.unlockedBy,
        unlocksFrom = info.unlocksFrom, -- v4.7.328: the combo recipe, as a list
        comboBoon = info.comboBoon, -- v4.7.322: a boolean, so `false` is passed too
        conflictsWith = info.conflictsWith,
        echoFloor = info.echoFloor, -- v4.7.326: the 1 is "can echo", not "echoes once"
      }
      local text = (info.description and info.description ~= "") and info.description or nil
      -- The game rewrites boons (user, v4.7.324), so a whole contemplate's text replaces ours --
      -- for a described boon too. `_learnBoon` still refuses a glued screen line.
      M._learnBoon(name, text, info.rarity, info.num_echoes_possible, extra)
      if text and not metaOnly then learned = learned + 1 end
      local rec = M.boonInfo and M.boonInfo(name)
      if type(rec) == "table" then
        rec.contemplatedAt = os.time()
        rec.comboChecked = nil -- superseded by the timestamp
      end
      if ctx then
        ctx.checked = ctx.checked + 1
        if info.comboBoon ~= nil then ctx.lines = ctx.lines + 1 end
        if seededCombo and info.comboBoon == nil then ctx.noLine[#ctx.noLine + 1] = name end
        local newText = type(rec) == "table" and rec.description or nil
        if oldText and newText and not sameText(oldText, newText) then
          ctx.changed[#ctx.changed + 1] = name
          M.echo("<yellow>" .. name .. " changed<grey>: " .. newText)
        end
      end
    end
    tempTimer(0.5, function() M._boonFillNext(todo, i + 1, learned, ctx) end)
  end)
  -- Say WHICH name goes out (v4.7.308): the send is silent, so a refusal in the log could not be
  -- tied to a name -- the user's first guess was the apostrophe, and the real cause was a
  -- spelling. `contemplating` is what the refusal handler reads back.
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.contemplating = name
  M.echo("contemplating <cyan>" .. name .. "<grey>...")
  send("boon contemplate " .. name, false)
end

-- The refusal (trigger mnemosyne/089). Marks the name in flight as unknown to the game -- so it
-- is never asked again until `mnem boonfill retry <name>` -- and finishes the capture at once so
-- a batch moves on instead of waiting out the 2s silence timeout.
-- Was this name on the boon screen we just had? The GAME printed it there, so its spelling is
-- right by construction -- which is the whole discriminator below.
function M._wasOffered(name)
  local base = (M._baseBoonName and M._baseBoonName(name)) or name
  for _, n in ipairs((M.run and M.run.lastOffered) or {}) do
    if ((M._baseBoonName and M._baseBoonName(n)) or n) == base then return true end
  end
  return false
end

-- The offer screen is gone (a claim, a reroll, a wave): its boons cannot be contemplated any
-- more. Remembered so the rest of the chain skips that screen's names instead of spending a
-- command on each and collecting a refusal.
function M.offerScreenGone(why)
  M._offerGoneAt = (getEpoch and getEpoch()) or os.time()
  M._offerGoneWhy = why
end
local OFFER_GONE_STALE = 120 -- a chain never runs this long; after it, treat a refusal as real

function M._offerGone()
  return M._offerGoneAt ~= nil
    and (((getEpoch and getEpoch()) or os.time()) - M._offerGoneAt) < OFFER_GONE_STALE
end

function M.onContemplateUnknown()
  ataxiaTemp = ataxiaTemp or {}
  local name = ataxiaTemp.contemplating
  ataxiaTemp.contemplating = nil
  if type(name) ~= "string" or name == "" then return false end
  -- NOT A BAD NAME -- A CLOSED SCREEN (user, 2026-09-19: "When I pick a boon before it gets
  -- contemplated, this pops up. It is wrong. It just means I picked it before the skill had time
  -- to look and the option isnt there anymore"). v4.7.308 read every refusal as "no such boon"
  -- and blacklisted the name FOREVER, so claiming quickly cost a real boon out of the catalogue.
  -- A name the game printed on the offer screen is spelt right, so the refusal means the screen
  -- closed under us: say so, skip the rest of that screen, and mark NOTHING unknown.
  if M._wasOffered(name) then
    M.offerScreenGone("refused")
    M.echo("<grey>'<cyan>" .. name .. "<grey>' is no longer on the screen -- the offer closed"
      .. " before it could be contemplated. Skipping the rest of that screen; nothing is marked"
      .. " unknown.")
    if M._capturing and M._captureForceFinish then pcall(M._captureForceFinish) end
    return true
  end
  M.history = M.history or {}
  M.history.boonUnknown = M.history.boonUnknown or {}
  M.history.boonUnknown[name] = (getEpoch and getEpoch()) or os.time()
  if M._historySaveSoon then M._historySaveSoon() end
  M.echo("<red>the game does not recognise the boon name<reset> '<cyan>" .. name
    .. "<reset>' -- skipping it from now on. <grey>mnem boonfill unknown<reset> lists these;"
    .. " fix the spelling in 010_Boon_Seed.lua, then <grey>mnem boonfill retry " .. name .. "<reset>.")
  if M._capturing and M._captureForceFinish then pcall(M._captureForceFinish) end
  return true
end

function M.boonUnknownRetry(name)
  local u = M.history and M.history.boonUnknown
  if not (u and type(name) == "string" and u[name]) then return false end
  u[name] = nil
  if M._historySaveSoon then M._historySaveSoon() end
  return true
end

-- Capture one BOON CONTEMPLATE block (skip the "<name>:" header + opening
-- divider; stop at the closing divider) and hand parsed detail to cb.
function M._captureContemplate(cb)
  -- `closed` (v4.7.324): did the block end on its CLOSING divider? A timeout or another capture
  -- force-finishing this one hands over a partial block, and now that a contemplate may rewrite a
  -- description, a partial block must never be read as the whole text.
  local seenDash, called, closed = false, false, false
  M._captureLines({
    timeout = 2,
    onLine = function(ln)
      if ln:find("BOON CLAIM", 1, true) then return "skip" end -- never capture the offered footer
      if isDivider(ln) then
        if seenDash then closed = true; return "stop" end
        seenDash = true
        return "skip"
      end
      if not seenDash then return "skip" end -- header line before the first divider
      return nil
    end,
    onDone = function(lines)
      if called then return end
      called = true
      local info = M._parseContemplate(lines)
      if type(info) == "table" then info.complete = closed end
      cb(info)
    end,
  })
end

-- Parse a captured CONTEMPLATE block into { rarity, num_echoes_possible,
-- description, quote, meta }. Layout: "Rarity: <r>", "Can echo: <Yes/No>", the
-- description paragraph, a blank line, then the quote in double quotes.
--
-- THE META BLOCK IS OPEN-ENDED (v4.7.288). The 2026-09-01 announcement adds a boon's CATEGORY to
-- this screen, plus -- for a boon unlocked by another -- a line naming the unlocking boon. The old
-- state machine recognised exactly three meta labels and treated ANY other non-blank line as the
-- start of the description, so both new lines would have flipped it early and been concatenated
-- into `info.description`. That is not cosmetic: a polluted description reaches `_learnBoon`,
-- which OVERWRITES, so it would have replaced good library text with "Category: Offensive Your
-- fire damage..." -- and the library outranks the seed in `_bonusDesc`, so the corruption lands
-- straight on the bonuses panel.
--
-- The fix is SHAPE, not names, since we have never seen the new wording: while still in the meta
-- section, a `Label: value` line is meta. A real description is prose and does not open that way.
-- Unrecognised labels are KEPT in `info.meta[label]` rather than dropped -- the announcement says
-- category is now available, and storing it under whatever the game calls it is how we find out
-- what to call it. Only a non-label line ends the meta section, exactly as before.
-- Is this a `Label: value` header rather than a sentence that happens to contain a colon?
-- WORD COUNT is the discriminator. Every label the screen has ever printed is one or two words
-- ("Rarity", "Can echo", "Maximum echoes", and now "Category" / "Unlocked by"); prose that opens
-- with a colon does not -- "Your options are simple: hit harder." is four. A shape rule with no
-- length bound swallowed exactly that line in testing, which is the whole reason the bound is
-- here: widening what a parser accepts obliges you to say what it must still refuse (v4.7.262).
--
-- A LABEL MAY END IN "?" (v4.7.322). The screen now prints `Combo Boon?:        Yes`, and the
-- character class above had no `?`, so that line was not a label: it flipped the parser into the
-- description and was glued onto the front of it -- "Combo Boon?:        Yes Gain 25% resistance
-- to cold damage." -- which `_learnBoon` then stored OVER the good text. That exact corruption is
-- sitting in the tracker's own catalogue for ten boons (GET /boons/export, 2026-09-18), which is
-- how we know the wording at all: no log of ours has captured it.
local META_LABEL_WORDS = 3
local META_KEY = "^(%u[%w'%- ]-%??):%s+"
local META_KEY_LABEL = META_KEY .. "%S"    -- built once, not per line (review, v4.7.322)
local META_KEY_VALUE = META_KEY .. "(.+)$"
-- Column-padded (2+ spaces after the colon): screen layout, never prose -- see `_splitGluedMeta`.
local META_KEY_PADDED = "^(%u[%w'%- ]-%??):%s%s+%S"
local function metaLabel(ln)
  local k = ln:match(META_KEY_LABEL)
  if not k then return nil end
  local words = 1
  for _ in k:gmatch(" ") do words = words + 1 end
  if words > META_LABEL_WORDS then return nil end
  return k
end

-- PROMOTE THE LABELS WE NOW KNOW THE NAME OF (v4.7.298).
--
-- v4.7.288 taught the meta block to KEEP an unrecognised `Label: value` instead of letting it
-- corrupt the description, and said that storing it "under whatever the game calls it is how we
-- find out what to call it". Three of those names are now known: the tracker's `BoonInfo` asks
-- for `category`, `unlocked_by` and `conflicts_with`, and the 2026-09-01 announcement put the
-- category and the unlocking boon on this very screen. So they graduate to typed fields.
--
-- `info.meta` IS LEFT WHOLE. It is the mechanism that learns the NEXT label, and emptying it as
-- labels graduate would remove that mechanism exactly when a new label appears. Promotion reads
-- from meta; it does not consume it.
--
-- SAFE-FAIL. A label we never see promotes nothing; the value simply stays in `meta`, which is
-- where the next reader will find it.
--
-- `Conflicts With` WAS ABSENT until v4.7.325 (deep review, v4.7.298): its value is a LIST of boon
-- names, the one shape that wraps, and a wrapped tail with no colon would have become the first
-- words of the description. The user then pasted a real block (2026-09-19): the label is
-- "Conflicts With", the list is joined with " and ", and the meta block ends in a BLANK LINE before
-- the description. So it is now promoted by its own path (below, and `_parseContemplate`), which
-- takes a following line as a wrapped tail only while the list still splits into KNOWN boon names.
--
-- The two in this table are promoted as STRINGS because a category is a single word, and
-- `unlocked by` was believed to be one name (the longest in the seed is ~30 characters, versus the
-- ~115-column wrap seen in the fixture). **v4.7.328 disproved the second half**: the user's
-- Lightning Soul prints `Unlocked By: Argent Scales, Electric Mastery, and Energetic` -- a LIST,
-- which can wrap and can exceed `META_VALUE_MAX`. The cap stays (it is what stops a wrapped value
-- being stored as though whole), and the recipe is read separately, as a list, below.
local META_PROMOTE = {
  ["category"] = "category",
  ["unlocked by"] = "unlockedBy",
  ["unlocks from"] = "unlockedBy",
}

-- Long enough that a wrap cannot be ruled out -> we do not trust the value. Comfortably above
-- the longest real value either promoted label can carry.
local META_VALUE_MAX = 60

-- A game rendering "no value" as a word must not become a value. `Unlocked by: None` would
-- otherwise be stored and shipped as though a boon called "None" unlocked this one -- and
-- fill-never-blank means it would then outrank the real answer when we finally saw it.
local META_PLACEHOLDER = {
  ["none"] = true, ["n/a"] = true, ["na"] = true, ["-"] = true,
  ["nothing"] = true, ["nil"] = true, ["unknown"] = true,
  -- The game's own word for a category it has not assigned (v4.7.322). The tracker's catalogue
  -- has it twice: Restoration's CATEGORY field is "Unset", and Curse of Time's DESCRIPTION opens
  -- with the glued line "Category:           Unset".
  ["unset"] = true,
}

-- YES/NO LABELS BECOME BOOLEANS (v4.7.322). `combo_boon` is a boolean on the tracker's BoonInfo,
-- so for this field "No" is information, not absence -- unlike a string, where an empty value
-- means we do not know. Anything but a clean yes/no stays in `meta` and promotes nothing.
-- Only the label we have actually SEEN: a guessed alias ("Combo Boon", no "?") sorts first, so it
-- would have outranked the real one had both ever appeared (review, v4.7.322).
local META_FLAG = {
  ["combo boon?"] = "comboBoon",
}
local FLAG_VALUE = { yes = true, no = false }

function M._promoteMeta(info)
  if type(info) ~= "table" or type(info.meta) ~= "table" then return info end
  -- SORTED, not `pairs()`. Two labels can map to one field ("unlocked by" / "unlocks from"), and
  -- with a first-wins guard an unspecified iteration order would make the winner arbitrary. The
  -- codebase sorts for exactly this reason elsewhere (`boonGaps`).
  local labels = {}
  for label in pairs(info.meta) do labels[#labels + 1] = label end
  table.sort(labels)
  for _, label in ipairs(labels) do
    local value = info.meta[label]
    local field = META_PROMOTE[tostring(label):lower()]
    if field and type(value) == "string" and value ~= "" and info[field] == nil then
      local trimmed = value:gsub("^%s+", ""):gsub("%s+$", "")
      local bare = trimmed:gsub("%s*%.%s*$", ""):lower()
      if #trimmed <= META_VALUE_MAX and not META_PLACEHOLDER[bare] then
        info[field] = trimmed
      end
    end
    -- UNLOCKED BY (v4.7.328): the COMBO recipe -- "Unlocked By: Argent Scales, Electric Mastery,
    -- and Energetic" on the reward's own contemplate (user's Lightning Soul, 2026-09-19). Read as a
    -- LIST like the conflicts line, and deliberately NOT through META_PROMOTE above, whose
    -- `META_VALUE_MAX` (60) a longer recipe runs past: the real 3-name Lightning Soul value is 46
    -- characters and fits, but a 4-name one is ~74 and the STRING form is dropped -- silently, and
    -- for exactly the biggest recipes. The list has no cap. The string is still promoted, and
    -- `_enrichOffer` falls back to this list so the tracker is not left with nothing.
    local lowLabel = tostring(label):lower()
    if (lowLabel == "unlocked by" or lowLabel == "unlocks from") and type(value) == "string"
      and info.unlocksFrom == nil then
      local bare = value:gsub("[%s%.]+$", ""):lower()
      if not META_PLACEHOLDER[bare] then
        local names = M._splitBoonList(value)
        if #names > 0 then info.unlocksFrom = names end
      end
    end
    -- CONFLICTS (v4.7.325): a LIST, split against the names we know (see `_splitBoonList`).
    if tostring(label):lower() == "conflicts with" and type(value) == "string" and info.conflictsWith == nil then
      local bare = value:gsub("[%s%.]+$", ""):lower()
      if not META_PLACEHOLDER[bare] then
        local names = M._splitBoonList(value)
        if #names > 0 then info.conflictsWith = names end
      end
    end
    local flag = META_FLAG[tostring(label):lower()]
    if flag and type(value) == "string" and info[flag] == nil then
      local word = value:gsub("^%s+", ""):gsub("[%s%.]+$", ""):lower()
      local b = FLAG_VALUE[word]
      if b ~= nil then info[flag] = b end
    end
  end
  return info
end

-- A SCREEN LINE GLUED ONTO A DESCRIPTION (v4.7.322). When a `Label:   value` line is mistaken for
-- the start of the description it ends up glued to the front of it: "Combo Boon?:        Yes Gain
-- 25% resistance to cold damage." (ten boons in the tracker's catalogue), "Category:           Unset
-- Your aeonics..." (one), and in OUR catalogue "Denizen levels increased by:  70 Denizen speed
-- increased by:   2" -- two WADE STATUS lines a contemplate capture swallowed as Deadly Finesse's
-- whole description.
--
-- The discriminator is TWO OR MORE SPACES after the colon. That is screen column padding, and
-- prose never has it: wrapped text is re-joined with single spaces. Scanned against every
-- description we hold (our catalogue, the seed and the tracker's export, ~1,100 strings), this
-- pattern matched exactly the corrupted ones and nothing else. Returns the remaining text and the
-- pairs it peeled off (nil when there were none). The value is ONE word: every glued value seen is.
local GLUED_META = "^(%u[%w'%- ]-%??):%s%s+(%S+)%s*(.*)$"
local GLUED_MAX = 8 -- no screen has this many meta lines; bounds the loop on hostile input

function M._splitGluedMeta(desc)
  if type(desc) ~= "string" then return desc, nil end
  local rest, meta = desc, nil
  for _ = 1, GLUED_MAX do
    local k, v, tail = rest:match(GLUED_META)
    if not k then break end
    meta = meta or {}
    if meta[k] == nil then meta[k] = v end
    rest = tail
  end
  return rest, meta
end

-- THE OFFER SCREEN GETS THE SAME PROTECTION (review, v4.7.322). The tracker's corruption could as
-- easily have come from the offer screen as from CONTEMPLATE, and `_parseNamedBlock` (whose rows
-- are `Name:  description`) would read a meta line two ways: on its OWN line it becomes a fake
-- boon named "Combo Boon?" -- learned into the catalogue, posted to the tracker, and counted in
-- the reroll comparison -- and ON THE SAME LINE as a boon it is glued onto that boon's text. Our
-- 13,998 recorded offers show neither, so this guards a line the game may add, not one it prints.
local OFFER_META_NAMES = {
  ["rarity"] = true, ["can echo"] = true, ["maximum echoes"] = true, ["category"] = true,
  ["combo boon?"] = true, ["unlocked by"] = true, ["unlocks from"] = true,
  ["conflicts with"] = true,
}

function M._cleanOfferList(list)
  local out = {}
  for _, b in ipairs(type(list) == "table" and list or {}) do
    local lname = (type(b) == "table" and type(b.name) == "string") and b.name:lower() or nil
    if lname and not OFFER_META_NAMES[lname] then
      local rest, glued = M._splitGluedMeta(b.description)
      if glued then
        b.description = (rest ~= "") and rest or nil
        local p = M._promoteMeta({ meta = glued })
        if b.combo_boon == nil and type(p.comboBoon) == "boolean" then b.combo_boon = p.comboBoon end
        if b.category == nil and type(p.category) == "string" then b.category = p.category end
      end
      out[#out + 1] = b
    end
  end
  return out
end

function M._parseContemplate(lines)
  local info = {}
  local descParts, quoteParts = {}, {}
  local section = "meta" -- meta -> desc -> quote
  local consumed = {} -- lines already taken as the tail of a wrapped conflicts list (v4.7.325)
  local sawYes, sawMax = false, false -- "Can echo: Yes" with no count is a floor (v4.7.326)
  for idx, ln in ipairs(lines) do
   if not consumed[idx] then
    local rar = ln:match("^Rarity:%s+(.+)$")
    local echo = ln:match("^Can echo:%s+(.+)$")
    local maxe = ln:match("^Maximum echoes:%s+(%d+)")
    if rar then
      info.rarity = rar:gsub("%s+$", "")
    elseif maxe then
      -- Authoritative echo count (printed only for echo-capable boons); overrides
      -- the "Can echo: Yes" floor of 1 regardless of which line arrives first.
      info.num_echoes_possible = tonumber(maxe)
      sawMax = true
    elseif echo then
      echo = echo:gsub("%s+$", ""):lower()
      if echo == "no" then
        info.num_echoes_possible = 0
      elseif echo == "yes" then
        -- Floor of 1; a "Maximum echoes: N" line, if present, refines this to N.
        info.num_echoes_possible = info.num_echoes_possible or 1
        sawYes = true
      else
        info.num_echoes_possible = tonumber(echo)
      end
    elseif ln:match("^%s*$") then
      if section == "desc" then section = "quote" end
    elseif metaLabel(ln) and (section == "meta" or ln:match(META_KEY_PADDED)) then
      -- (v4.7.322) Outside the meta block only a COLUMN-PADDED label counts: a meta line printed
      -- AFTER the text (unseen, but nothing rules it out) must not be glued onto its end, and a
      -- prose line with a single space after a colon still stays prose.
      -- An unrecognised `Label: value` while still in the meta block -- category, unlocked-by, or
      -- whatever is added next. Record it and do NOT let it start the description.
      local k, v = ln:match(META_KEY_VALUE)
      v = v:gsub("%s+$", "")
      -- A CONFLICTS LIST MAY WRAP (v4.7.325). It is the one label whose value is long, and a wrapped
      -- tail prints flush-left like the description does. Take the following lines as its tail
      -- only while the whole list still splits into KNOWN boon names -- a description line never
      -- does -- and never past the blank line that ends the meta block.
      if k:lower() == "conflicts with" or k:lower() == "unlocked by" or k:lower() == "unlocks from" then
        local j = idx + 1
        while lines[j] and not lines[j]:match("^%s*$") and not metaLabel(lines[j]) do
          local cand = v .. " " .. lines[j]:gsub("^%s+", ""):gsub("%s+$", "")
          -- TAKE THE TAIL WHEN THE LINE CANNOT STAND ALONE (v4.7.328 review). The all-known-names
          -- test below is the safe rule for a tail we could already name -- but a RECIPE's tail is
          -- exactly where an unknown boon appears (that is what `comboGaps` exists to fetch), and
          -- refusing it there was destructive: the list kept a phantom "and", the real component
          -- was lost, and the orphaned line became the boon's DESCRIPTION, overwriting the
          -- catalogue. A value ending in a comma or a bare "and" is unfinished by the game's own
          -- punctuation -- no list ends that way -- so the next line belongs to it whether or not
          -- we recognise the name.
          local dangling = v:match(",%s*$") ~= nil or v:match("%s+and%s*$") ~= nil or v:match(",%s*and%s*$") ~= nil
          if not (dangling or M._allKnownBoons(cand)) then break end
          v, consumed[j], j = cand, true, j + 1
        end
      end
      info.meta = info.meta or {}
      info.meta[k] = v
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
  end
  if #descParts > 0 then info.description = table.concat(descParts, " ") end
  if #quoteParts > 0 then
    info.quote = (table.concat(quoteParts, " "):gsub('^"', ""):gsub('"$', ""))
  end
  if sawYes and not sawMax then info.echoFloor = true end
  return M._promoteMeta(info)
end
