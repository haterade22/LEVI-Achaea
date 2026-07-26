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
  bmShatteredStar = false -- boons gone on a confirmed run-end
  magiKkractle = false -- boons gone on a confirmed run-end
  magiHotSprings = false -- boons gone on a confirmed run-end
  mnemHammerAnvil = false -- boons gone on a confirmed run-end
  bmBladedReflexes = false -- boons gone on a confirmed run-end
  mnemSleuth = false -- boons gone on a confirmed run-end
  mnemRollHide = false -- boons gone on a confirmed run-end
  mnemReaper = false -- boons gone on a confirmed run-end
  if ataxiaTemp then ataxiaTemp.reaperKills = nil end -- the +1%/kill tally dies with the run
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
    ataxiaBasher.inMnemosyne = false
    if ataxiaBasher_mnemStillHere then ataxiaBasher_mnemStillHere() end -- drop any pending ask
    ataxiaEcho("Mnemosyne wade ended — no-flee mode OFF.")
  end
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
    M.echo("<red>Splinterbark<reset> active — <red>curing tree off<reset> (tree touch bleeds/afflicts)")
  end
end

-- Restore game tree curing iff Splinterbark had forced it off. Called from onRunEnd (run over ->
-- untainted). No-op unless we turned it off, so it never spuriously re-enables curing.
function M.restoreTreeCuring()
  if not M._treeCuringOff then return end
  M._treeCuringOff = nil
  send("curing tree on")
  if not M._quiet() then M.echo("Splinterbark cleared — <green>curing tree on<reset>") end
end

-- "You wade N ripples deep into the tides of memory:" (WADE STATUS output).
-- Seeing this proves we're in a run, so (re)assert active, set the ripple
-- first, then flush any buffered monsters so /ripple_level precedes /monsters.
function M.onRipple(n)
  -- Reset the ripple map on level change (independent of telemetry reporting).
  if ataxia.mnemosyne.map and ataxia.mnemosyne.map.onRipple then ataxia.mnemosyne.map.onRipple(n) end
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
  if not M._inRun() then return end
  if type(text) ~= "string" then return end
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  local target = text:match("^defeat (.+)$")
  if not target then return end
  if target:match("^%d+ waves? of enemies") then return end -- normal wave, not a boss
  M.reportBoss(target)
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
