-- test_basher_alchemist.lua -- the Alchemist bash rotation holds a shield (v4.7.422)
--
-- User: "educe iron is the go to attack for Alchemist" and "Alchie should be wielding a shield
-- when bashing". Loads the real basher/002_Class_Bashing.lua. Files share ONE Lua state: every
-- global touched here is saved at the top and restored at the bottom.

require("mock_mudlet")

local saved = {
  target = target, ataxia = ataxia, ataxiaBasher = ataxiaBasher, ataxiaTemp = ataxiaTemp,
  ataxiaBasher_assembleBattlerage = ataxiaBasher_assembleBattlerage,
  pav = mnemPavonian, salt = mnemPurifyingSalt, rust = mnemRust,
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

-- v4.7.424. User: "We need to account for these boons" (Pavonian, Purifying Salt, Rust).
describe("alchemist bashing: Mnemosyne boons", function()
  local crowd = 1
  local function reset()
    ataxiaBasher.shielded, ataxia.vitals.rage = false, 0
    ataxiaBasher.alchemistWrackAff, ataxiaBasher.alchemistSaltAt = nil, nil
    ataxia.afflictions = {}
    ataxia.mnemosyne = { _denizenCount = function() return crowd end }
    mnemPavonian, mnemPurifyingSalt, mnemRust = false, false, false
    crowd = 1
  end

  it("no boons: the plain rotation", function()
    reset(); crowd = 4
    expect(ataxiaBasher_alchemistBashing()).toBe("wield shield;BR;educe iron 7")
  end)

  it("Pavonian: a wrack on balance rides beside educe iron on equilibrium", function()
    reset(); mnemPavonian = true
    expect(ataxiaBasher_alchemistBashing()).toBe("wield shield;BR;educe iron 7;wrack 7 paralysis")
    ataxiaBasher.alchemistWrackAff = "weariness"
    expect(ataxiaBasher_alchemistBashing()).toBe("wield shield;BR;educe iron 7;wrack 7 weariness")
  end)

  it("Pavonian: no wrack into a shield", function()
    reset(); mnemPavonian = true; ataxiaBasher.shielded = true
    expect(ataxiaBasher_alchemistBashing()).toBe("wield shield;educe copper 7;BR")
  end)

  it("Purifying Salt: educe salt in a crowd, educe iron alone", function()
    reset(); mnemPurifyingSalt = true; crowd = 2
    expect(ataxiaBasher_alchemistBashing()).toBe("wield shield;BR;educe salt")
    crowd = 1
    expect(ataxiaBasher_alchemistBashing()).toBe("wield shield;BR;educe iron 7")
    crowd = 2; ataxiaBasher.alchemistSaltAt = 3
    expect(ataxiaBasher_alchemistBashing()).toBe("wield shield;BR;educe iron 7")
  end)

  it("Purifying Salt: stupidity blocks salt, so the round stays on iron", function()
    reset(); mnemPurifyingSalt = true; crowd = 3; ataxia.afflictions.stupidity = true
    expect(ataxiaBasher_alchemistBashing()).toBe("wield shield;BR;educe iron 7")
  end)

  it("both boons in a crowd: salt plus the wrack", function()
    reset(); mnemPurifyingSalt, mnemPavonian = true, true; crowd = 3
    expect(ataxiaBasher_alchemistBashing()).toBe("wield shield;BR;educe salt;wrack 7 paralysis")
  end)

  it("Rust changes nothing in the rotation", function()
    reset(); mnemRust = true
    expect(ataxiaBasher_alchemistBashing()).toBe("wield shield;BR;educe iron 7")
  end)

  it("all three are latched from the boon registry", function()
    local f = assert(io.open("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/004_Parsers.lua"))
    local src = f:read("*a"); f:close()
    expect(src:find('%["Pavonian"%]%s*=%s*"mnemPavonian"') ~= nil).toBeTrue()
    expect(src:find('%["Purifying Salt"%]%s*=%s*"mnemPurifyingSalt"') ~= nil).toBeTrue()
    expect(src:find('%["Rust"%]%s*=%s*"mnemRust"') ~= nil).toBeTrue()
  end)
end)

mnemPavonian, mnemPurifyingSalt, mnemRust = saved.pav, saved.salt, saved.rust
target, ataxia, ataxiaBasher, ataxiaTemp = saved.target, saved.ataxia, saved.ataxiaBasher, saved.ataxiaTemp
ataxiaBasher_assembleBattlerage = saved.ataxiaBasher_assembleBattlerage
