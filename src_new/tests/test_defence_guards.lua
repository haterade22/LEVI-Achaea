--- test_defence_guards.lua -- defence writes and actions that repeated for nothing (2026-11-08)
--
-- 1. ApplySwaps' WATER, paraAst, astWear and fratLock had no `ataxia_getPrio(x) ~= N` test, so
--    every affliction gain re-sent a priority the server already held (once a second per
--    affliction), spending the four writes a second the throttle allows.
-- 2. AntiSerpent sent `cq all;touch shield` on impatience with our shield already up.
-- 3. The Runewarden DWB round re-sent `touch shield` on every balance while impatience lasted
--    against a Serpent, even with our shield up. The hold stays (an attack drops our own shield,
--    kb/raw/logs/2026-11-01_elmer_alchemist-vs-serpent_loss_Z5cyffxx.txt:78); only the redundant
--    touch goes.
-- 4. The Depthswalker lock-breaker sent `chrono accelerate boost` while prone and paralysed; the
--    wiki says prone makes the boost impossible (kb/raw/wiki/Aeonics.wiki:106).
--
-- The REAL scripts run here: 002_Prio_Management (setAffPrio/getPrio and the throttle),
-- 001_Anti_Priorities, dwb_runie/001 and can(x)/003. Every global they create or change is
-- restored at the end (one shared Lua state for all test files).

local mock = require("mock_mudlet")
local before = {}
for k, v in pairs(_G) do before[k] = v end
local savedContains = table.contains
local savedAtaxia = ataxia
local savedTables = {}
for _, k in ipairs({ "afflictions", "curingprio", "settings", "prioritySwaps", "defences", "vitals",
  "prioThrottle", "playersHere" }) do
  savedTables[k] = ataxia and ataxia[k]
end

table.contains = function(t, v)
  if type(t) ~= "table" then return false end
  for _, x in pairs(t) do if x == v then return true end end
  return false
end

ataxia = ataxia or {}
ataxia.afflictions, ataxia.curingprio, ataxia.settings = {}, {}, {}
ataxia.prioThrottle = nil
Algedonic = Algedonic or {}
ataxiaTemp = {}
dwbRunie = nil                                   -- dwb_runie/001 builds its tables only when absent

local ROOT = "src_new/scripts/levi_ataxia/levi/"
for _, f in ipairs({
  ROOT .. "ataxia/ataxia/002_Prio_Management.lua",
  ROOT .. "levi_scripts/algedonic_defense_1.0/001_Anti_Priorities.lua",
  ROOT .. "levi_scripts/dwb_runie/001_DWB_Runie_Logic.lua",
  ROOT .. "ataxia/can(x)/003_Lock_breakers.lua",
}) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end

local now = 1000
local tc = "Serpent"
local function reset(affs)
  mock.reset()
  now = 1000
  getEpoch = function() return now end
  ataxia.afflictions = affs or {}
  ataxia.curingprio = {}
  ataxia.defences = {}
  ataxia.vitals = { bal = true, eq = true }
  ataxia.settings = {}
  ataxia.prioThrottle.commands = {}
  ataxia.prioThrottle.sentThisSecond = 0
  ataxia.prioThrottle.windowStart = 0
  ataxia_bashProfileActive = nil
  prioWaitfor, prioWaitrestore = {}, {}
  ataxiaTemp = {}
  target = "Agathon"
  affed = function(a) return ataxia.afflictions[a] end
  ataxiaNDB_Exists = function() return true end
  ataxiaNDB_getClass = function() return tc end
  cecho, ataxiaEcho = function() end, function() end
end

local function sent(cmd) return mock.was_sent(cmd) end
local function count(cmd)
  local n = 0
  for _, c in ipairs(mock.sent_commands) do if c == cmd then n = n + 1 end end
  return n
end

local ok, err = pcall(function()

describe("ApplySwaps: a stored priority the server already holds is not written again", function()
  local function swaps(names)
    ataxia.prioritySwaps = {}
    for _, n in ipairs(names) do ataxia.prioritySwaps[n] = { active = true } end
  end

  it("paraAst: writes paralysis 1 once, and not while trigger 719 has confirmed it", function()
    reset({ asthma = true, paralysis = true, slickness = true })
    swaps({ "paraAst" })
    ataxia.curingprio.paralysis = 3
    Algedonic.ApplySwaps("slickness")
    expect(sent("curing priority paralysis 1")).toBeTrue()

    reset({ asthma = true, paralysis = true, slickness = true })
    swaps({ "paraAst" })
    ataxia.curingprio.paralysis = 1
    Algedonic.ApplySwaps("slickness")
    expect(#mock.sent_commands).toBe(0)
  end)

  it("astWear: asthma 3 against a Serpent, not again once held", function()
    tc = "Serpent"
    reset({ asthma = true, weariness = true })
    swaps({ "astWear" })
    ataxia.curingprio.asthma = 7
    Algedonic.ApplySwaps("weariness")
    expect(sent("curing priority asthma 3")).toBeTrue()

    reset({ asthma = true, weariness = true })
    swaps({ "astWear" })
    ataxia.curingprio.asthma = 3
    Algedonic.ApplySwaps("weariness")
    expect(#mock.sent_commands).toBe(0)
  end)

  it("fratLock: fratricide 4, not again once held", function()
    reset({ fratricide = true, asthma = true, slickness = true })
    swaps({ "fratLock" })
    ataxia.curingprio.fratricide = 25
    Algedonic.ApplySwaps("slickness")
    expect(sent("curing priority fratricide 4")).toBeTrue()

    reset({ fratricide = true, asthma = true, slickness = true })
    swaps({ "fratLock" })
    ataxia.curingprio.fratricide = 4
    Algedonic.ApplySwaps("slickness")
    expect(#mock.sent_commands).toBe(0)
  end)

  it("WATER: nausea 1 against a Blademaster, not again once held", function()
    tc = "Blademaster"
    reset({ nausea = true, asthma = true })
    swaps({ "WATER" })
    ataxia.curingprio.nausea = 9
    Algedonic.ApplySwaps("asthma")
    expect(sent("curing priority nausea 1")).toBeTrue()

    reset({ nausea = true, asthma = true })
    swaps({ "WATER" })
    ataxia.curingprio.nausea = 1
    Algedonic.ApplySwaps("asthma")
    expect(#mock.sent_commands).toBe(0)
    tc = "Serpent"
  end)

  it("five gains a second apart send paralysis 1 once, not five times", function()
    reset({ asthma = true, paralysis = true, slickness = true })
    swaps({ "paraAst" })
    ataxia.curingprio.paralysis = 3
    for i = 1, 5 do
      Algedonic.ApplySwaps("slickness")
      -- The server confirms the first write (trigger 719), and prioWaitfor's 1 s clock runs out.
      if i == 1 then ataxia.curingprio.paralysis = 1 end
      mock.fire_timers()
      now = now + 1
    end
    expect(count("curing priority paralysis 1")).toBe(1)
  end)
end)

describe("AntiSerpent: impatience with our shield already up", function()
  it("sends the prioaff and no `cq all;touch shield`", function()
    tc = "Serpent"
    reset({ impatience = true })
    ataxia.defences.shield = true
    Algedonic.AntiSerpent()
    expect(sent("curing prioaff impatience")).toBeTrue()
    expect(sent("cq all;touch shield")).toBeFalse()
    expect(ataxiaTemp.serpentShieldThrottle).toBeNil()
  end)

  it("with the shield down it still shields, once per 4 s", function()
    reset({ impatience = true })
    Algedonic.AntiSerpent()
    Algedonic.AntiSerpent()
    expect(count("touch shield")).toBe(1)
  end)
end)

describe("Runewarden DWB: impatience against a Serpent", function()
  local function dwbWorld(shield)
    reset({ impatience = true, anorexia = true, slickness = true, asthma = true })
    ataxia.defences.shield = shield
    ataxia.playersHere = { "Agathon" }
    gmcp = { Char = { Vitals = { bal = "1" } } }
    lb, tAffs, affConfigV3 = {}, {}, nil
    reboundHold, myinstantcath, engaged = nil, nil, true
    getLockingAffliction, checkTargetLocks = function() end, function() end
    combatQueue = function() return "" end
    dwbRunie.state = { mode = "torso" }
    dwbRunie.diagnosticEcho = function() end
    dwbRunie.buildTorsoAttack = function() return "ATTACK" end
  end
  local function lastRound()
    for i = #mock.sent_commands, 1, -1 do
      local c = mock.sent_commands[i]
      if c:find("^queue addclearfull free") then return c end
    end
  end

  it("with our shield up the round holds: the prioaff, no attack and no second touch", function()
    dwbWorld(true)
    dwbRunie.dispatch()
    expect(sent("curing prioaff impatience")).toBeTrue()
    expect(lastRound()).toBeNil()
  end)

  it("with the shield down the round is the shield, as before", function()
    dwbWorld(nil)
    dwbRunie.dispatch()
    expect(sent("curing prioaff impatience")).toBeTrue()
    expect(lastRound()).toBe("queue addclearfull free touch shield")
  end)
end)

describe("Depthswalker lock-breaker while prone", function()
  local function breakWith(affs)
    reset(affs)
    ataxiaTemp.class = "Depthswalker"
    ataxia_breakLock()
  end

  it("prone and paralysed: plain `chrono accelerate`, no stand", function()
    breakWith({ prone = true, paralysis = true, asthma = true, slickness = true, anorexia = true })
    expect(sent("chrono accelerate")).toBeTrue()
    expect(sent("chrono accelerate boost")).toBeFalse()
    expect(sent("stand")).toBeFalse()
  end)

  it("prone but free to stand: stand, then the boost", function()
    breakWith({ prone = true, asthma = true, slickness = true, anorexia = true })
    expect(sent("stand;chrono accelerate boost")).toBeTrue()
  end)

  it("standing: the boost", function()
    breakWith({ paralysis = true, asthma = true, slickness = true, anorexia = true })
    expect(sent("chrono accelerate boost")).toBeTrue()
  end)
end)

end)

mock.reset()
table.contains = savedContains
-- Restore the shared Lua state: drop every global the loaded files created and put back every
-- one they replaced. `ataxia` is shared with every other file, so its fields go back one by one.
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
ataxia = savedAtaxia
if ataxia then
  for k, v in pairs(savedTables) do ataxia[k] = v end
end
if not ok then error(err) end
