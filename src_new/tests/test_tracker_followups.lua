--- test_tracker_followups.lua -- cross-file tracker follow-ups, 2026-11-08 deep review
--
-- tprio.switchTo (mage/006) does its own target switch, and it left the old target's chase running:
--   the 1.4 s TargetOutOfRoom ticks erased what we landed on the new target. It now stops the chase
--   and sets targetIshere from GMCP's room list, as switchTarget (016) does.
-- apostate.mentalReady (apostate/015) compared a summed V3 probability with >= 1.0, which a
--   renormalised split leaves a few ulps under 1.
--
-- The tests run the REAL functions on the REAL V3 tracker (007, 008). Every global the loaded files
-- create or change is restored at the end (one shared Lua state for all test files).

local mock = require("mock_mudlet")
local before = {}
for k, v in pairs(_G) do before[k] = v end
local savedContains = table.contains
local savedStarts = string.starts

-- The V3 files initialise these as `X = X or {...}`. Clear them, so the loads build fresh tables.
for _, k in ipairs({ "afflictionStatesV3", "affConfigV3", "simpleAffsV3", "affCacheV3", "targetBurningLevelV3",
  "affLastConfirmedV3", "targetDefensesV3", "cureBalancesV3", "cureBalanceTimerIDsV3", "passiveCooldownsV3",
  "negativeConfirmTimersV3", "tAffsV2", "tAffStacksV2" }) do
  _G[k] = nil
end
ataxiaTemp, tAffs, affTimers = {}, {}, {}
tprio, apostate = nil, nil

for _, f in ipairs({
  "src_new/scripts/levi_ataxia/levi/ataxia/016_Targeting_Functions.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/017_Affliction_Management.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/curing/002_Wide_Groups.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/007_Branching_State_Tracker.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/008_V3_Integration.lua",
  "src_new/scripts/levi_ataxia/levi/levi_scripts/mage/006_Target_Priority.lua",
  "src_new/scripts/levi_ataxia/levi/levi_scripts/apostate/015_CC_Apostate.lua",
}) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end

table.contains = table.contains or function(t, v)
  for _, x in pairs(t) do if x == v then return true end end
  return false
end
string.starts = string.starts or function(s, p) return s:sub(1, #p) == p end

local timersOn, sent
local function world()
  mock.reset()
  timersOn, sent = { TargetOutOfRoom = true }, {}
  disableTimer = function(n) timersOn[n] = false; return true end
  enableTimer = function(n) timersOn[n] = true; return true end
  send = function(c) sent[#sent + 1] = c end
  getEpoch = function() return 1000 end
  raiseEvent, ataxiaEcho, zgui = function() end, function() end, nil
  checkTargetLocks = function() end
  gmcp = { Char = { Status = { class = "Serpent", name = "Leviticus" } } }
  ataxia = { settings = { separator = ";" }, playersHere = {} }
  ataxiaTemp = { tarAffTimers = {} }
  tAffs, affTimers = {}, {}
  tBals = { tree = true, focus = true, plant = true, timers = {} }
  target = "Oldtarget"
  targetIshere = false
  lb, magi, setafflictionstackslevi, targetresetafflictionslevi = nil, nil, nil, nil
  tprio.list, tprio.current, tprio.playersInRoom = {}, 0, {}
  affConfigV3.enabled = true
  resetStatesV3()
end

local ok, err = pcall(function()

describe("tprio.switchTo: the new target's presence (mage/006)", function()
  it("a listed new target: here, and the old target's chase stops", function()
    world()
    ataxia.playersHere = { "Bystander", "Saibel" }
    tprio.switchTo("saibel")
    expect(target).toBe("Saibel")
    expect(targetIshere).toBeTrue()
    expect(timersOn.TargetOutOfRoom).toBeFalse()
  end)

  it("an absent new target: not here, and the old target's chase still stops", function()
    world()
    targetIshere = true                 -- what the old target left behind
    ataxia.playersHere = { "Bystander" }
    tprio.switchTo("Saibel")
    expect(target).toBe("Saibel")
    expect(targetIshere).toBeFalse()
    expect(timersOn.TargetOutOfRoom).toBeFalse()
  end)

  it("no room list yet: not here, and it does not throw", function()
    world()
    ataxia.playersHere = nil
    tprio.switchTo("Saibel")
    expect(targetIshere).toBeFalse()
  end)

  it("a part name counts when a listed name starts with it", function()
    world()
    ataxia.playersHere = { "Saibel" }
    tprio.switchTo("sai")
    expect(target).toBe("Sai")
    expect(targetIshere).toBeTrue()
  end)

  it("never the reverse: Kaiden is not here because Kai is", function()
    world()
    ataxia.playersHere = { "Kai" }
    tprio.switchTo("Kaiden")
    expect(targetIshere).toBeFalse()
  end)

  it("the switch itself still happens (the settarget line goes out)", function()
    world()
    ataxia.playersHere = { "Saibel" }
    tprio.switchTo("Saibel")
    local found = false
    for _, c in ipairs(sent) do if c == "settarget Saibel" then found = true end end
    expect(found).toBeTrue()
  end)
end)

describe("apostate.mentalReady: impatience is confirmed when every branch holds it", function()
  local function branches(list)
    afflictionStatesV3 = list
    rebuildCacheV3()
  end

  it("branches that sum a few ulps under 1 are still confirmed", function()
    world()
    branches({
      { affs = { impatience = true, stupidity = true, dizziness = true, asthma = true }, prob = 0.7 },
      { affs = { impatience = true, stupidity = true, dizziness = true, slickness = true }, prob = 0.2 },
      { affs = { impatience = true, stupidity = true, dizziness = true }, prob = 0.1 },
    })
    expect(getAffProbabilityV3("impatience") < 1).toBeTrue()   -- the old >= 1.0 test failed here
    expect(apostate.mentalReady()).toBeTrue()
  end)

  it("a split impatience is not confirmed", function()
    world()
    branches({
      { affs = { impatience = true, stupidity = true, dizziness = true }, prob = 0.6 },
      { affs = { stupidity = true, dizziness = true }, prob = 0.4 },
    })
    expect(apostate.mentalReady()).toBeFalse()
  end)

  it("certain impatience with only one other mental piece is not ready", function()
    world()
    tarAffed("impatience", "stupidity")
    expect(apostate.mentalReady()).toBeFalse()
  end)

  it("certain impatience with two other mental pieces is ready", function()
    world()
    tarAffed("impatience", "stupidity", "vertigo")
    expect(apostate.mentalReady()).toBeTrue()
  end)
end)

end)

mock.reset()
table.contains = savedContains
string.starts = savedStarts
-- Restore the shared Lua state: drop every global the loaded files created and put back every
-- one they replaced.
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
if not ok then error(err) end
