--- test_basher_infernal.lua -- Infernal PvE bashing (v4.7.148)
-- Covers the Dual Wield Cutting swing + hyena maul, the Army of the Dead room nuke
-- (boon-gated, crowd-gated, cooldown-stamped), and the Daemon Jaws maul-cooldown scaling.
-- The pet-safety fixes (hyena on the own-denizen list, "she hurls herself at you" ordering
-- her passive) live in triggers/config and are covered by test_basher_owndenizens.lua.

require("mock_mudlet")

target = 42
ataxia = { settings = { separator = ";" }, vitals = { rage = 0, knight = "Dual Cutting" } }
ataxiaBasher = {
  shielded = false, rageraze = false,
  battlerage = { Infernal = { small = "ravage 42", large = "spike 42", raze = "shiver 42" } },
}
ataxiaTemp = {}
gmcp = {
  Room = { Info = { area = "" } },
  Char = { Status = { class = "Infernal", level = "80 " } },
  IRE = { Target = { Info = {} } },
}
function ataxiaEcho() end
function ataxiaBasher_assembleBattlerage() return "" end

local denizens = 0
ataxia.mnemosyne = { _denizenCount = function() return denizens end }

local _epoch = getEpoch
local clock = 1000000
getEpoch = function() return clock end

local file = "src_new/scripts/levi_ataxia/levi/ataxia/basher/002_Class_Bashing.lua"
local ok, err = pcall(dofile, file)
if not ok then error("Failed to load class-bashing file: " .. tostring(err)) end

local function has(cmd, needle) return cmd:find(needle, 1, true) ~= nil end

local function reset()
  ataxiaBasher.shielded, ataxiaBasher.rageraze = false, false
  ataxiaBasher.hyenaMaulReady = true
  ataxiaBasher.infGravehandsCd = nil
  ataxia.vitals.rage, ataxia.vitals.knight = 0, "Dual Cutting"
  ataxiaTemp = {}
  infArmyOfDead, infDaemonJaws = false, false
  denizens = 0
  clock = clock + 100
end

describe("ataxiaBasher_infernalBashing -- Dual Wield Cutting", function()
  it("swings DSL, with the hyena maul while it is off cooldown", function()
    reset()
    local cmd = ataxiaBasher_infernalBashing()
    expect(has(cmd, "hyena maul 42")).toBeTrue()
    expect(has(cmd, "dsl 42")).toBeTrue()
  end)

  it("drops the maul while it is on cooldown, keeping the swing", function()
    reset(); ataxiaBasher.hyenaMaulReady = false
    local cmd = ataxiaBasher_infernalBashing()
    expect(has(cmd, "hyena maul")).toBeFalse()
    expect(has(cmd, "dsl 42")).toBeTrue()
  end)
end)

describe("Army of the Dead -- gravehands room nuke", function()
  it("does nothing without the boon", function()
    reset(); denizens = 3
    expect(ataxiaBasher_infGravehands(";")).toBe("")
  end)

  it("needs a crowd: solo denizens are not worth the summon", function()
    reset(); infArmyOfDead = true; denizens = 1
    expect(ataxiaBasher_infGravehands(";")).toBe("")
  end)

  it("summons at 2+ denizens, then holds its cooldown", function()
    reset(); infArmyOfDead = true; denizens = 2
    expect(ataxiaBasher_infGravehands(";")).toBe("summon hands of the grave;")
    expect(ataxiaBasher_infGravehands(";")).toBe("") -- stamped
    clock = clock + 21
    expect(ataxiaBasher_infGravehands(";")).toBe("summon hands of the grave;")
  end)

  it("rides ahead of the swing in the assembled command", function()
    reset(); infArmyOfDead = true; denizens = 3
    local cmd = ataxiaBasher_infernalBashing()
    expect(has(cmd, "summon hands of the grave")).toBeTrue()
    expect(has(cmd, "dsl 42")).toBeTrue()
  end)

  it("never spends a shield-break round on it", function()
    reset(); infArmyOfDead = true; denizens = 3
    ataxiaBasher.shielded = true
    expect(has(ataxiaBasher_infernalBashing(), "summon hands of the grave")).toBeFalse()
  end)
end)

describe("Daemon Jaws -- hyena maul cooldown", function()
  local cdFile = "src_new/scripts/levi_ataxia/levi/ataxia/basher/005_Falcon_Cooldowns.lua"
  local okc = pcall(dofile, cdFile)

  it("loads the cooldown module", function()
    expect(okc).toBeTrue()
  end)

  it("arms a 30s safety timer normally, ~10s under the boon", function()
    if not okc then return end
    reset()
    local seen
    local realTempTimer = tempTimer
    tempTimer = function(secs, _) seen = secs; return 1 end

    infDaemonJaws = false
    ataxiaBasher_hyenaMaulCooldown()
    expect(seen).toBe(30)

    infDaemonJaws = true
    ataxiaBasher_hyenaMaulCooldown()
    expect(math.floor(seen * 10 + 0.5) / 10).toBe(10.2) -- 30 * 0.34, -66%

    tempTimer = realTempTimer
    infDaemonJaws = false
  end)
end)

-- Restore shared state for whoever runs after us (files share one Lua state).
getEpoch = _epoch
infArmyOfDead, infDaemonJaws = false, false
target = nil
