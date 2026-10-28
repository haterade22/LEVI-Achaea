--[[mudlet
type: script
name: Runeblade Empower
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Gear System
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- Runeblade empower job (alias `remweap`, v4.7.465)
--
-- A Runewarden runeblade is LAGUL + LAGUA + LAGUZ sketched on a knight weapon, then EMPOWER
-- (2000 mana, about 10 s, the system paused). The job:
--   1. WEAPONLIST (ataxia.weaponDetect.list) -> the knight weapons, by full ID.
--   2. PROBE each one. "This weapon has N months of runic empowerment left." = already a
--      runeblade. The WEAPONLIST Months column is item DECAY, not empowerment -- never read it.
--   3. For each weapon that is not empowered: the three sketches, EMPOWER, and a probe to verify.
--   4. gebo/gebu on armour and shield (the old remweap did this too).
--
-- One step at a time, and every step moves on from a GAME LINE, never a fixed timer (the old
-- remweap sent sketches on 6 s timers and never knew whether one had landed). Every step has a
-- timeout, and a timeout stops the whole job: the no-ink refusal has never been captured.
-- Commands name the full ID: a type word hits the same item twice with two flails.
--
-- Captured lines (2026-10-28):
--   probe end:  "<desc> has no venoms or magical effects on it."
--               "<desc> has the following venoms or magical effects on it:" (then "Empowered")
--   sketch:     "You begin sketching a lagul rune on a Logosian battleaxe."
--               "With a flourish, you finish sketching a lagul rune."
--               "There is no need to duplicate runes."  (already there -- harmless, go on)
--   empower:    "Using <desc>, you lightly inscribe a circle upon the ground around where you stand..."
--               "When you feel that your concentration is perfect and complete, ..."

ataxia.runeblade = ataxia.runeblade or {}
local R = ataxia.runeblade

-- The knight weapon types that become runeblades, in the order the job works through them.
R.TYPES = { "flail", "morningstar", "scimitar", "longsword", "battleaxe", "warhammer", "bastard" }
R.RUNES = { "lagul", "lagua", "laguz" }
R.ARMOUR_SKETCHES = {
  { rune = "gebo", on = "armour" }, { rune = "gebu", on = "armour" },
  { rune = "gebu", on = "shield" }, { rune = "gebo", on = "shield" },
}

R.config = R.config or {}
R.config.mana = R.config.mana or 2000           -- EMPOWER's cost
R.config.probeTimeout = R.config.probeTimeout or 5
R.config.sketchTimeout = R.config.sketchTimeout or 10
R.config.empowerTimeout = R.config.empowerTimeout or 25
R.config.readyWait = R.config.readyWait or 120   -- longest wait for balance/eq/mana
R.config.poll = R.config.poll or 0.5

R.state = R.state or { running = false }

function R.echo(text)
  cecho("\n<dark_orchid>[<light_slate_blue>Runeblade<dark_orchid>]<lavender>: <plum>" .. text)
end

-- Keep the knight weapons from WEAPONLIST rows, ordered by R.TYPES and then by ID number.
function R.filterWeapons(rows)
  local rank = {}
  for i, t in ipairs(R.TYPES) do rank[t] = i end
  local out = {}
  for _, row in ipairs(rows or {}) do
    if rank[row.type] then out[#out + 1] = row.id end
  end
  table.sort(out, function(a, b)
    local ta, tb = a:match("^(%a+)"), b:match("^(%a+)")
    if ta ~= tb then return rank[ta] < rank[tb] end
    return tonumber(a:match("%d+$")) < tonumber(b:match("%d+$"))
  end)
  return out
end

--------------------------------------------------------------------------------
-- Timers and triggers. A generation number makes a stale timer harmless.
--------------------------------------------------------------------------------

local function killStepTimers()
  local s = R.state
  if s.timer then killTimer(s.timer); s.timer = nil end
  if s.poll then killTimer(s.poll); s.poll = nil end
end

local function armTimeout(seconds, what)
  local s = R.state
  local gen = s.gen
  s.timer = tempTimer(seconds, function()
    if R.state.running and R.state.gen == gen then
      R.finish("no answer to " .. what .. " after " .. seconds .. " s")
    end
  end)
end

local TRIGGERS = {
  { "^This weapon has (\\d+) months? of runic empowerment left\\.", function() R.onMonths(tonumber(matches[2])) end },
  { "^.+ has no venoms or magical effects on it\\.$", function() R.onProbeEnd() end },
  { "^.+ has the following venoms or magical effects on it:$", function() R.onProbeEnd() end },
  { "^With a flourish, you finish sketching an? \\w+ rune\\.", function() R.onSketchDone() end },
  { "^There is no need to duplicate runes\\.", function() R.onSketchDone() end },
  { "^Using .+, you lightly inscribe a circle upon the ground", function() R.onEmpowerStart() end },
  { "^When you feel that your concentration is perfect and complete", function() R.onEmpowerDone() end },
}

local function armTriggers()
  R.state.triggers = {}
  for _, t in ipairs(TRIGGERS) do
    R.state.triggers[#R.state.triggers + 1] = tempRegexTrigger(t[1], t[2])
  end
end

local function killTriggers()
  for _, id in ipairs(R.state.triggers or {}) do killTrigger(id) end
  R.state.triggers = {}
end

--------------------------------------------------------------------------------
-- Readiness: balance, equilibrium and (for EMPOWER) mana, read from GMCP.
--------------------------------------------------------------------------------

local function vitals()
  return (gmcp and gmcp.Char and gmcp.Char.Vitals) or {}
end

-- nil when ready, else the reason we are waiting.
function R.notReady(needMana)
  local v = vitals()
  if v.bal ~= "1" then return "balance" end
  if v.eq ~= "1" then return "equilibrium" end
  if needMana and (tonumber(v.mp) or 0) < R.config.mana then return "mana" end
  return nil
end

-- Run fn once we have balance and equilibrium (and mana, if asked). Gives up after readyWait.
local function whenReady(needMana, fn)
  local s = R.state
  local gen = s.gen
  local waited, told = 0, false
  local function try()
    if not R.state.running or R.state.gen ~= gen then return end
    R.state.poll = nil
    local why = R.notReady(needMana)
    if not why then return fn() end
    if why == "mana" and not told then
      told = true
      R.echo("Waiting for " .. R.config.mana .. " mana to empower...")
    end
    waited = waited + R.config.poll
    if waited > R.config.readyWait then
      return R.finish("still no " .. why .. " after " .. R.config.readyWait .. " s")
    end
    R.state.poll = tempTimer(R.config.poll, try)
  end
  try()
end

--------------------------------------------------------------------------------
-- The step queue
--------------------------------------------------------------------------------

local function current()
  return R.state.steps[R.state.idx]
end

function R.runStep()
  local s = R.state
  local step = current()
  if not step then
    if not s.planned then return R.plan() end
    return R.finish("done")
  end
  s.gen = s.gen + 1
  killStepTimers()
  step.months = nil
  if step.kind == "probe" then
    send("probe " .. step.id)
    armTimeout(R.config.probeTimeout, "probe " .. step.id)
  elseif step.kind == "sketch" then
    whenReady(false, function()
      send("sketch " .. step.rune .. " on " .. step.on)
      armTimeout(R.config.sketchTimeout, "sketch " .. step.rune .. " on " .. step.on)
    end)
  elseif step.kind == "empower" then
    whenReady(true, function()
      send("empower " .. step.id)
      armTimeout(R.config.empowerTimeout, "empower " .. step.id)
    end)
  end
end

local function advance()
  killStepTimers()
  R.state.idx = R.state.idx + 1
  R.runStep()
end

function R.onMonths(n)
  local step = R.state.running and current()
  if step and step.kind == "probe" then step.months = n end
end

function R.onProbeEnd()
  local step = R.state.running and current()
  if not step or step.kind ~= "probe" then return end
  local w = R.state.weapons[step.id]
  if step.months then
    if step.verify then w.status = "empowered (" .. step.months .. " months)"
    else w.status = "already (" .. step.months .. " months)"; w.done = true end
  else
    if step.verify then w.status = "FAILED (no empowerment after EMPOWER)"
    else w.status = "needs runes + empower" end
  end
  advance()
end

function R.onSketchDone()
  local step = R.state.running and current()
  if step and step.kind == "sketch" then advance() end
end

function R.onEmpowerStart()
  local step = R.state.running and current()
  if step and step.kind == "empower" then step.started = true end
end

function R.onEmpowerDone()
  local step = R.state.running and current()
  if step and step.kind == "empower" then advance() end
end

-- All weapons probed: queue the work (run mode) or report (list mode).
function R.plan()
  local s = R.state
  s.planned = true
  if s.mode == "list" then return R.finish("listed") end

  local todo = {}
  for _, id in ipairs(s.order) do
    if not s.weapons[id].done then todo[#todo + 1] = id end
  end
  for _, id in ipairs(todo) do
    for _, rune in ipairs(R.RUNES) do
      s.steps[#s.steps + 1] = { kind = "sketch", rune = rune, on = id }
    end
    s.steps[#s.steps + 1] = { kind = "empower", id = id }
    s.steps[#s.steps + 1] = { kind = "probe", id = id, verify = true }
  end
  for _, a in ipairs(R.ARMOUR_SKETCHES) do
    s.steps[#s.steps + 1] = { kind = "sketch", rune = a.rune, on = a.on }
  end

  R.echo(#todo .. " of " .. #s.order .. " weapons to empower: " .. (#todo * #R.RUNES)
    .. " purple inks, " .. (#todo * R.config.mana) .. " mana. Then gebo/gebu on armour and shield.")
  -- Pause the system for the work, and only unpause later if we were the ones who paused it.
  if not ataxia.settings.paused then
    s.pausedByUs = true
    ataxiaToggle("off")
  end
  R.runStep()
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

local function begin(mode)
  if R.state.running then
    return R.echo("A runeblade job is already running. <white>remweap stop<plum> ends it.")
  end
  if mode == "run" and ataxiaBasher and ataxiaBasher.enabled then
    return R.echo("Turn the basher off first. EMPOWER takes about 10 s and must not be interrupted.")
  end
  R.state = { running = true, mode = mode, steps = {}, idx = 1, gen = 0,
              weapons = {}, order = {}, planned = false, triggers = {} }
  R.echo("Reading WEAPONLIST...")
  ataxia.weaponDetect.list(function(rows)
    if not R.state.running then return end
    if not rows then return R.finish("WEAPONLIST did not answer") end
    local s = R.state
    s.order = R.filterWeapons(rows)
    if #s.order == 0 then return R.finish("no flail, morningstar, scimitar, longsword, battleaxe, warhammer or bastard found") end
    for _, id in ipairs(s.order) do
      s.weapons[id] = { status = "not reached" }
      s.steps[#s.steps + 1] = { kind = "probe", id = id }
    end
    armTriggers()
    R.runStep()
  end)
end

function R.start() begin("run") end
function R.list() begin("list") end

function R.stop()
  if not R.state.running then return R.echo("No runeblade job is running.") end
  R.finish("stopped by you")
end

function R.finish(reason)
  local s = R.state
  if not s.running then return end
  s.running = false
  s.gen = (s.gen or 0) + 1
  killStepTimers()
  killTriggers()
  if s.pausedByUs then
    s.pausedByUs = false
    ataxiaToggle("on")
  end
  R.echo("Finished: " .. reason .. ".")
  for _, id in ipairs(s.order or {}) do
    cecho("\n    <lavender>" .. string.format("%-20s", id) .. " <plum>" .. s.weapons[id].status)
  end
  cecho("\n")
end
