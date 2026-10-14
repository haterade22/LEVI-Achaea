-- test_basher_alchemist.lua -- the Alchemist bash rotation holds a shield (v4.7.422)
--
-- User: "educe iron is the go to attack for Alchemist" and "Alchie should be wielding a shield
-- when bashing". Loads the real basher/002_Class_Bashing.lua. Files share ONE Lua state: every
-- global touched here is saved at the top and restored at the bottom.

require("mock_mudlet")

local saved = {
  target = target, ataxia = ataxia, ataxiaBasher = ataxiaBasher, ataxiaTemp = ataxiaTemp,
  ataxiaBasher_assembleBattlerage = ataxiaBasher_assembleBattlerage,
}

target = 7
ataxia = { settings = { separator = ";" }, vitals = { hp = 1000, maxhp = 1000, rage = 0, mp = 3000 },
           defences = {} }
ataxiaBasher = { shielded = false, enabled = true, manual = false, rageraze = true,
                 battlerage = { Alchemist = { raze = "RAZE" } } }
ataxiaTemp = {}

local ok, err = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/basher/002_Class_Bashing.lua")
if not ok then error("Failed to load class-bashing file: " .. tostring(err)) end
local brage = "BR"
function ataxiaBasher_assembleBattlerage() return brage end

describe("alchemist bashing", function()
  it("wields the shield, then educe iron", function()
    ataxiaBasher.shielded = false
    expect(ataxiaBasher_alchemistBashing()).toBe("wield shield;BR;educe iron 7")
  end)

  it("a shielded target: shield first, educe copper", function()
    ataxiaBasher.shielded, ataxia.vitals.rage = true, 0
    expect(ataxiaBasher_alchemistBashing()).toBe("wield shield;educe copper 7;BR")
  end)

  it("a shielded target at 17+ rage: shield first, raze, educe iron", function()
    ataxiaBasher.shielded, ataxia.vitals.rage = true, 20
    expect(ataxiaBasher_alchemistBashing()).toBe("wield shield;RAZE;educe iron 7")
  end)
end)

target, ataxia, ataxiaBasher, ataxiaTemp = saved.target, saved.ataxia, saved.ataxiaBasher, saved.ataxiaTemp
ataxiaBasher_assembleBattlerage = saved.ataxiaBasher_assembleBattlerage
