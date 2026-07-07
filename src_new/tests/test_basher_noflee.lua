--- test_basher_noflee.lua — Unit tests for no-flee area handling (Mnemosyne / World Tree)
-- Loads the real basher functions file and exercises ataxiaBasher_isNoFleeArea()
-- and ataxiaBasher_dangerLevel() to confirm no-flee areas shield instead of flee,
-- while normal areas still flee (regression).

local mock = require("mock_mudlet")

-- ----------------------------------------------------------------------------
-- Stub project globals the basher functions file expects
-- ----------------------------------------------------------------------------
function ataxiaEcho(...) end
function get_Battlerage() end
function ataxiaBasher_canShield() return true end
function table.contains(t, v)
  if type(t) ~= "table" then return false end
  for _, x in pairs(t) do if x == v then return true end end
  return false
end

ataxia = ataxia or {}
ataxia.settings = ataxia.settings or { separator = "::" }
ataxia.vitals = { hpp = 100, maxhp = 5000, rage = 0 }
ataxia.afflictions = {}
ataxia.defences = {}

ataxiaBasher = ataxiaBasher or {}
ataxiaTemp = ataxiaTemp or {}
gmcp = { Room = { Info = { area = "" } } }

local function setArea(a) gmcp.Room.Info.area = a end

-- Load the real basher functions (defines the functions under test)
local basher_file = "src_new/scripts/levi_ataxia/levi/ataxia/basher/001_Bashing_Functions.lua"
local ok, err = pcall(dofile, basher_file)
if not ok then error("Failed to load basher functions file: " .. tostring(err)) end

-- Reset per-test state to a calm baseline
local function baseline()
  ataxia.vitals = { hpp = 100, maxhp = 5000, rage = 0 }
  ataxia.afflictions = {}
  ataxia.defences = {}
  ataxiaTemp.bashFlee = false
  ataxiaBasher.inMnemosyne = false
  ataxiaBasher.fleeThresholdPct = 25
  ataxiaBasher.shieldThresholdPct = 40
  ataxiaBasher_dmgSamples = {}
  setArea("Test Bashing Area")
end

local function spikeDamage()
  -- Two samples well above the 60%-of-maxhp threshold (3000 for maxhp 5000)
  ataxiaBasher_dmgSamples = { { getEpoch(), 2000 }, { getEpoch(), 2000 } }
end

-- ----------------------------------------------------------------------------
describe("ataxiaBasher_isNoFleeArea", function()

  it("returns true for the World Tree", function()
    baseline()
    expect(ataxiaBasher_isNoFleeArea("the Fathomless Expanse of the World Tree")).toBeTrue()
  end)

  it("returns true when the Mnemosyne flag is set (empty area)", function()
    baseline()
    ataxiaBasher.inMnemosyne = true
    expect(ataxiaBasher_isNoFleeArea("")).toBeTrue()
  end)

  it("returns false for a normal area with the flag off", function()
    baseline()
    expect(ataxiaBasher_isNoFleeArea("Test Bashing Area")).toBeFalse()
  end)

end)

describe("ataxiaBasher_dangerLevel — no-flee behavior", function()

  it("normal area: low HP flees (regression)", function()
    baseline()
    ataxia.vitals.hpp = 20
    expect(ataxiaBasher_dangerLevel()).toBe("flee")
  end)

  it("normal area: extreme damage flees (regression)", function()
    baseline()
    ataxia.vitals.hpp = 80
    spikeDamage()
    expect(ataxiaBasher_dangerLevel()).toBe("flee")
  end)

  it("Mnemosyne: low HP shields instead of fleeing", function()
    baseline()
    ataxiaBasher.inMnemosyne = true
    setArea("")
    ataxia.vitals.hpp = 20
    expect(ataxiaBasher_dangerLevel()).toBe("shield")
  end)

  it("Mnemosyne: extreme damage shields instead of fleeing", function()
    baseline()
    ataxiaBasher.inMnemosyne = true
    setArea("")
    ataxia.vitals.hpp = 80
    spikeDamage()
    expect(ataxiaBasher_dangerLevel()).toBe("shield")
  end)

  it("Mnemosyne: healthy with no spike still attacks", function()
    baseline()
    ataxiaBasher.inMnemosyne = true
    setArea("")
    ataxia.vitals.hpp = 90
    expect(ataxiaBasher_dangerLevel()).toBe("attack")
  end)

end)
