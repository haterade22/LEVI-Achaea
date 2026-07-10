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
  if M._capturing then
    M.decho("capture already in progress; ignoring new block")
    return function() end
  end
  M._capturing = true

  local lines, tid, timer = {}, nil, nil
  local done = false

  local function finish()
    if done then return end
    done = true
    M._capturing = false
    if tid then pcall(killTrigger, tid) end
    if timer then pcall(killTimer, timer) end
    local ok, err = pcall(opts.onDone, lines)
    if not ok then M.echo("Parse error: " .. tostring(err)) end
  end

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

-- "You begin to wade out into the depths of the Mnemosyne..."
function M.onRunStart()
  if M._auto() then M.startRun() end
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
  if M._inRun() then M.endRun() end
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

-- The wave prints "<countdown 0>\n<mob spawn line>\n<GO!>". On the "0", arm a
-- one-shot capture of the next (mob) line into M._mobCandidate; onGo commits it
-- when GO! follows. Deterministic -- unlike reading back with getLines.
function M.onCountdownZero()
  if not M._inRun() then return end
  M._mobCandidate = nil
  if M._mobTrig then pcall(killTrigger, M._mobTrig); M._mobTrig = nil end
  M._mobTrig = tempRegexTrigger([[^.*$]], function()
    local ln = (line or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if ln == "" then return end -- skip blanks, keep waiting for the mob line
    if M._mobTrig then pcall(killTrigger, M._mobTrig); M._mobTrig = nil end
    if ln == "GO!" or ln:match("^%d+$") then return end -- no mob line this wave
    M._mobCandidate = ln
  end)
end

-- "GO!" -- a new wave has begun. Commit the mob line captured after the "0"
-- (trimmed to the mob phrase), then auto-send WADE STATUS so its output drives
-- ripple-level/effects reporting. Gated on _auto() (not _inRun) for the wade
-- status so it can bootstrap a run whose start line was missed.
function M.onGo()
  -- Fire for telemetry OR just for the ripple map (so WADE STATUS -> the ripple
  -- line drives the per-ripple map reset even with reporting off).
  local mnem = ataxiaBasher and ataxiaBasher.inMnemosyne
  if not (M._auto() or mnem) then return end
  if M._mobTrig then pcall(killTrigger, M._mobTrig); M._mobTrig = nil end
  if M._inRun() and M._mobCandidate then
    M.onMonsters(M._extractMob(M._mobCandidate) or M._mobCandidate)
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
function M.onBoonsOffered()
  if not M._inRun() then return end
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
      if #list > 0 then
        -- Remember canonical names so a later BOON CLAIM can be reported
        -- with the exact spelling the game used.
        M.run.lastOffered = {}
        for _, b in ipairs(list) do table.insert(M.run.lastOffered, b.name) end
        M._reportBoonsOfferedEnriched(list)
      end
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
  if not M._cfg().contemplate then
    if M._recordOffers then M._recordOffers(list) end -- local history (#6)
    return M.reportBoonsOffered(list)
  end
  M._contemplateNext(list, 1)
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
