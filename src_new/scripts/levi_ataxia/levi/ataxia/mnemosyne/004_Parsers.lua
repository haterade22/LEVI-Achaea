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
-- possession." -- the run has ended (Mnemosyne is an endless climb with no
-- victory; it ends on true death or WADE LEAVE, and this reward line marks the
-- conclusion). A normal life-loss death (the /death trigger) keeps the run going.
function M.onRunEnd()
  if M._inRun() then M.endRun() end
end

-- "You wade N ripples deep into the tides of memory:" (WADE STATUS output).
-- Seeing this proves we're in a run, so (re)assert active, set the ripple
-- first, then flush any buffered monsters so /ripple_level precedes /monsters.
function M.onRipple(n)
  if not M._auto() then return end
  M.run.active = true
  M.setRipple(n)
  M._flushMonsters()
end

-- Given the lines immediately preceding GO! (nearest first), pick the mob spawn
-- line. The wave always prints "<0>\n<mob spawn line>\n<GO!>", so the mob line
-- is the first non-empty, non-countdown-number line above GO!.
function M._pickMobLine(prior)
  for _, ln in ipairs(prior) do
    if type(ln) == "string" then
      local t = ln:gsub("^%s+", ""):gsub("%s+$", "")
      if t == "GO!" or t == "" then
        -- skip
      elseif t:match("^%d+$") then
        return nil -- reached the countdown without a mob line
      else
        return t
      end
    end
  end
  return nil
end

-- Mob spawn phrasing is "<flavour> a/an <quantifier> of <mob> <verb>...". These
-- sets anchor the "a <quantifier> of <mob>" extraction.
local MOB_QUANTIFIERS = {
  host = true, group = true, pack = true, swarm = true, horde = true,
  legion = true, band = true, throng = true, mob = true, cluster = true,
  flock = true, pride = true, colony = true, gaggle = true, troop = true,
  army = true, gathering = true, crowd = true, mass = true, multitude = true,
  drove = true, cloud = true, school = true, brood = true, litter = true,
  nest = true, coven = true, company = true, squad = true, warband = true,
}
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
}

-- Extract the "a/an <quantifier> of <mob>" phrase from a full spawn line, or nil
-- if the structure isn't present. Mob words are collected after "of" until a
-- verb, a comma, or sentence-ending punctuation (capped at 4 words for safety).
function M._extractMob(str)
  if type(str) ~= "string" then return nil end
  local words = {}
  for w in str:gmatch("%S+") do words[#words + 1] = w end
  local function clean(w) return (w:lower():gsub("%p+", "")) end
  for i = 1, #words - 2 do
    local a = clean(words[i])
    if (a == "a" or a == "an") and MOB_QUANTIFIERS[clean(words[i + 1])] and clean(words[i + 2]) == "of" then
      local mob = {}
      for j = i + 3, #words do
        local w = words[j]
        if MOB_VERBS[w:lower():gsub("%p+$", "")] then break end
        table.insert(mob, (w:gsub("%p+$", "")))
        if w:match("[%.,;:!?]$") or #mob >= 4 then break end
      end
      if #mob > 0 then
        return words[i] .. " " .. words[i + 1] .. " " .. words[i + 2] .. " " .. table.concat(mob, " ")
      end
    end
  end
  return nil
end

-- "GO!" -- a new wave has begun. The mob spawn line is the line directly above
-- GO! (between the countdown "0" and "GO!"); capture it by position rather than
-- by wording, since each mob has different flavour text. Then auto-send WADE
-- STATUS so its output drives the ripple-level and effects reporting.
-- Gated on _auto() (not _inRun) so it can bootstrap the run if the run-start
-- line was missed; a stray GO! outside a run just sends a harmless status.
function M.onGo()
  if not M._auto() then return end
  if M._inRun() then
    local n = getLineNumber()
    local prior = {}
    for i = 1, 3 do
      local ok, lns = pcall(getLines, n - i, n - i)
      prior[i] = (ok and lns and lns[1]) or ""
    end
    local mob = M._pickMobLine(prior)
    if mob then M.onMonsters(M._extractMob(mob) or mob) end
  end
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
      if #list > 0 then M.reportEffects(list) end
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
  local canonical
  for _, off in ipairs(M.run.lastOffered or {}) do
    if off:lower() == name:lower() then
      canonical = off
      break
    end
  end
  if not canonical then
    return M.decho("BOON CLAIM '" .. name .. "' not in last offered set; not reporting.")
  end
  M.reportBoonsSelected(canonical)
end

-- Enrichment: when `contemplate` is enabled, BOON CONTEMPLATE each offered boon
-- to fill rarity/quote/num_echoes_possible before reporting; otherwise send the
-- name + description straight through.
function M._reportBoonsOfferedEnriched(list)
  if not M._cfg().contemplate then
    return M.reportBoonsOffered(list)
  end
  M._contemplateNext(list, 1)
end

-- Sequentially BOON CONTEMPLATE each boon, merge the parsed detail into the
-- entry, then send the fully-populated /boons_offered.
function M._contemplateNext(list, i)
  if i > #list then
    return M.reportBoonsOffered(list)
  end
  local boon = list[i]
  M._captureContemplate(function(info)
    if info then
      if info.rarity then boon.rarity = info.rarity end
      if info.quote then boon.quote = info.quote end
      if info.num_echoes_possible ~= nil then boon.num_echoes_possible = info.num_echoes_possible end
      if info.description and info.description ~= "" then boon.description = info.description end
    end
    tempTimer(0.5, function() M._contemplateNext(list, i + 1) end)
  end)
  send("boon contemplate " .. boon.name, false)
end

-- Capture one BOON CONTEMPLATE block (skip the "<name>:" header + opening
-- divider; stop at the closing divider) and hand parsed detail to cb.
function M._captureContemplate(cb)
  local seenDash, called = false, false
  M._captureLines({
    timeout = 2,
    onLine = function(ln)
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
    if rar then
      info.rarity = rar:gsub("%s+$", "")
    elseif echo then
      echo = echo:gsub("%s+$", ""):lower()
      if echo == "no" then
        info.num_echoes_possible = 0
      elseif echo == "yes" then
        info.num_echoes_possible = 1
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
