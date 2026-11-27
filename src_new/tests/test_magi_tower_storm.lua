-- test_magi_tower_storm.lua -- Magi casts stormhammer at 3+ non-own denizens in the Mnemosyne tower
-- (basher/002 ataxiaBasher_magiTowerStormhammer; tower = ataxiaBasher.inMnemosyne). Targets come from
-- ataxia.denizensHere, not from the saved target list, and the `abshuse` toggle is not needed there.
-- One shared Lua state: every global is restored at the end.

require("mock_mudlet")

local before = {}
for k, v in pairs(_G) do before[k] = v end

local clock = 1000000
getEpoch = function() return clock end
target = 101
ataxia = { settings = { separator = ";", sipping = { manause = 30 } },
           vitals = { mp = 10000, maxmp = 10000 }, defences = {}, denizensHere = {} }
ataxiaBasher = { shielded = false, inMnemosyne = true, ownDenizens = { "ashbeast" } }
ataxiaTemp = {}
ataxia.mnemosyne = { _denizenCount = function() local n = 0 for _ in pairs(ataxia.denizensHere) do n = n + 1 end return n end }
function ataxiaBasher_assembleBattlerage() return "BRAGE" end
function ataxiaBasher_isOwnDenizen(name)
  for _, kw in pairs(ataxiaBasher.ownDenizens or {}) do
    if name:lower():find(kw, 1, true) then return true end
  end
  return false
end

local loadErr
local okLoad, errLoad = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/basher/002_Class_Bashing.lua")
if not okLoad then loadErr = tostring(errLoad) end
ataxiaBasher_stormhammer = function() end
ataxiaBasher_magiStormPrep = function() end
ataxiaBasher_magiShouldBloodboil = function() return false end
ataxiaBasher_validTargets = function() return 0 end

local function has(s, part) return s:find(part, 1, true) ~= nil end
local function world(n, tower)
  clock = 1000000
  mnemEvocationFire, mnemEvocationEarth, mnemMasterOfFour = false, false, false
  mnemWintersHeart, magiKkractle = false, false
  ataxiaBasher = { shielded = false, inMnemosyne = tower ~= false, ownDenizens = { "ashbeast" } }
  ataxiaTemp = {}
  ataxia.vitals.mp, ataxia.vitals.maxmp = 10000, 10000
  ataxia.denizensHere = {}
  for i = 1, n do ataxia.denizensHere[tostring(100 + i)] = "a guard " .. i end
  target = 101
  stormhammerTargets = {}
end

local ok, err = pcall(function()
if loadErr then error(loadErr, 0) end

describe("tower stormhammer", function()
  it("2 denizens -> none; 3 -> three ids, target first", function()
    world(2)
    expect(ataxiaBasher_magiTowerStormhammer(";")).toBe("")
    world(3); target = 103
    expect(ataxiaBasher_magiTowerStormhammer(";")).toBe("cast stormhammer at 103 and 101 and 102;")
    expect(ataxiaBasher_magiBashing()).toBe("BRAGE;cast stormhammer at 103 and 101 and 102")
  end)
  it("4 denizens -> exactly 3 ids", function()
    world(4); target = 999
    expect(ataxiaBasher_magiTowerStormhammer(";")).toBe("cast stormhammer at 101 and 102 and 103;")
  end)
  it("own denizens are neither counted nor targeted", function()
    world(2)
    ataxia.denizensHere["200"] = "a blazing ashbeast"
    expect(ataxiaBasher_magiTowerStormhammer(";")).toBe("")
    ataxia.denizensHere["103"] = "a guard 3"
    local r = ataxiaBasher_magiTowerStormhammer(";")
    expect(has(r, "200")).toBe(false)
    expect(has(r, "103")).toBe(true)
  end)
  it("outside the tower the helper is silent and the old toggle branch is unchanged", function()
    world(3, false)
    expect(ataxiaBasher_magiTowerStormhammer(";")).toBe("")
    expect(has(ataxiaBasher_magiBashing(), "stormhammer")).toBe(false)
    ataxiaBasher.stormhammer = true
    ataxiaBasher_validTargets = function() return 3 end
    stormhammerTargets = { "1", "2", "3" }
    expect(ataxiaBasher_magiBashing()).toBe("BRAGE;cast stormhammer at 1 and 2 and 3")
    ataxiaBasher_validTargets = function() return 0 end
  end)
  it("toggle off in the tower: it still casts", function()
    world(3)
    ataxiaBasher.stormhammer = false
    expect(has(ataxiaBasher_magiBashing(), "cast stormhammer at")).toBe(true)
  end)
  it("mana floor: 1200 may not take us below manause", function()
    world(3)
    ataxia.vitals.mp = 4199
    expect(ataxiaBasher_magiTowerStormhammer(";")).toBe("")
    ataxia.vitals.mp = 4200
    expect(has(ataxiaBasher_magiTowerStormhammer(";"), "cast stormhammer")).toBe(true)
  end)
  it("shielded: erode wins", function()
    world(3); ataxiaBasher.shielded = true
    expect(has(ataxiaBasher_magiBashing(), "cast erode")).toBe(true)
  end)
  it("a ready Hellfumes proc outranks it; afterwards stormhammer", function()
    world(3); mnemEvocationFire = true
    expect(has(ataxiaBasher_magiBashing(), "hellfumes")).toBe(true)
    ataxiaTemp.evocationFireAt = clock
    expect(has(ataxiaBasher_magiBashing(), "cast stormhammer at")).toBe(true)
  end)
  it("with magiKkractle or deepfreeze held, stormhammer still wins at 3+", function()
    world(3); magiKkractle, mnemWintersHeart = true, true
    expect(has(ataxiaBasher_magiBashing(), "cast stormhammer at")).toBe(true)
    world(2); magiKkractle = true
    expect(ataxiaBasher_magiBashing()).toBe("BRAGE;elemental surge")
  end)
end)

end)

for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
if not ok then error(err) end
