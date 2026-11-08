--- test_monk_class_grab.lua -- trigger 006 must not turn a known Shikudo into a Monk
--
-- The user, 2026-11-08: "Tekura Monk, Sylvan, Magi, Blademaster, and Elemental Lords are all immune
-- to clumsiness." Shikudo is not on that list. With two attackers the engine clears attackerName,
-- so a Shikudo's kick used to rewrite his NDB class to Monk and drop clumsiness for that round.
-- The real trigger, engine, NDB API and class gate run here. Every global this file changes is
-- restored at the end.

local mock = require("mock_mudlet")

local before = {}
for k, v in pairs(_G) do before[k] = v end
local tableSave, tableLoad, ioExists = table.save, table.load, io.exists

local LEVI = "src_new/scripts/levi_ataxia/levi/"
local TRIGGER = "src_new/triggers/levi_ataxia/for_levi/leviticus/determine_class/006_Monk_Class_Grab.lua"
local STAFF = "whips a staff at the side of your neck."
local KICK = "lashes out with a high kick at your left leg."

local function fresh()
  mock.reset()
  ataxia = { settings = {}, playersHere = { "Agathon" }, afflictions = {} }
  ataxiaTemp = {}
  classDetect = nil
  pariah = {}
  ataxiaNDB = { players = {} }
  cecho, ataxiaEcho = function() end, function() end
  getEpoch = function() return 1000 end
  raiseEvent, send = function() end, function() end
  registerAnonymousEventHandler = function() return 1 end
  killAnonymousEventHandler = function() end
  table.save, table.load = function() end, function() end
  io.exists = function() return false end
  dofile(LEVI .. "ataxia/ataxia_ndb/003_ataxiaNDB_API.lua")
  dofile(LEVI .. "ataxia/ataxia/007_Pariah_things.lua")
  dofile(LEVI .. "levi_scripts/class_detect/001_Class_Detect_Engine.lua")
  ataxia_switchCuringsetSend = function() end
  ataxia_sendCuringPriority = function() end
  ataxia_bashProfileActive = function() return false end
  isDefenceForCurrentClass = function() return true end
  target = "Kalys"
end

local function hit(who, text)
  line = who .. " " .. text
  matches = { line, who }
  dofile(TRIGGER)
end

local function attackers()
  local n = 0
  for _ in pairs(classDetect.state.attackers) do n = n + 1 end
  return n
end

describe("one attacker", function()
  it("a kick after a staff line stays Shikudo", function()
    fresh()
    hit("Kalys", STAFF)
    hit("Kalys", KICK)
    expect(ataxiaNDB_getClass("Kalys")).toBe("Shikudo")
    expect(ataxia_wantClumsiness()).toBeTrue()
  end)

  it("an unknown monk's kick reads Monk", function()
    fresh()
    hit("Kalys", KICK)
    expect(ataxiaNDB_getClass("Kalys")).toBe("Monk")
    expect(ataxia_wantClumsiness()).toBeFalse()
  end)
end)

describe("two attackers", function()
  local function twoAttackers()
    fresh()
    classDetect.setAttackerClass("Tabethys", "Bard")
  end

  it("staff, kick, staff, kick all stay Shikudo", function()
    twoAttackers()
    for _, text in ipairs({ STAFF, KICK, STAFF, KICK }) do
      hit("Kalys", text)
      expect(ataxiaNDB_getClass("Kalys")).toBe("Shikudo")
      expect(ataxia_wantClumsiness()).toBeTrue()
    end
  end)

  it("a saved Shikudo who only kicks in this fight reads Monk", function()
    twoAttackers()
    ataxiaNDB.players.Kalys = { class = "Shikudo" }
    hit("Kalys", KICK)
    expect(ataxiaNDB_getClass("Kalys")).toBe("Monk")
    expect(ataxia_wantClumsiness()).toBeFalse()
    expect(attackers()).toBe(2)
  end)

  it("a first kick still enters the attackers table", function()
    twoAttackers()
    hit("Kalys", KICK)
    expect(classDetect.state.attackers.kalys).toBeTrue()
  end)

  it("a kick that matches the guard refreshes the combat timeout", function()
    twoAttackers()
    hit("Kalys", STAFF)
    local refreshed = 0
    local real = classDetect.resetCombatTimeout
    classDetect.resetCombatTimeout = function() refreshed = refreshed + 1; real() end
    hit("Kalys", KICK)
    expect(refreshed).toBe(1)
  end)
end)

for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
table.save, table.load, io.exists = tableSave, tableLoad, ioExists
mock.reset()
