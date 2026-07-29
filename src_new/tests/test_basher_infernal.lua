--- test_basher_infernal.lua -- Infernal PvE bashing (v4.7.148)
-- Covers the Dual Wield Cutting swing + hyena maul, the Army of the Dead room nuke
-- (boon-gated, crowd-gated, cooldown-stamped), and the Daemon Jaws maul-cooldown scaling.
-- The pet-safety fixes (hyena on the own-denizen list, "she hurls herself at you" ordering
-- her passive) live in triggers/config and are covered by test_basher_owndenizens.lua.

require("mock_mudlet")

target = 42
ataxia = { settings = { separator = ";" }, vitals = { rage = 0, knight = "Dual Cutting" }, defences = {} }
ataxiaBasher = {
  shielded = false, rageraze = false,
  battlerage = { Infernal = { small = "ravage 42", large = "spike 42", raze = "shiver 42" } },
}
ataxiaTemp = {}
gmcp = {
  Room = { Info = { area = "" } },
  Char = { Status = { class = "Infernal", level = "80 " }, Vitals = { ep = 100, maxep = 100 } },
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
  ataxiaBasher.infGravehandsCd, ataxiaBasher.infTyrannyCd = nil, nil
  ataxiaBasher.infEssenceFloor, ataxiaBasher.infQuash = nil, nil
  ataxia.vitals.essence = nil
  ataxia.vitals.rage, ataxia.vitals.knight = 0, "Dual Cutting"
  ataxiaTemp = {}
  infArmyOfDead, infDaemonJaws, infIndiscriminate = false, false, false
  infNecroticAura, infFuryOfAges = false, false
  gmcp.Char.Vitals = { ep = 100, maxep = 100 }
  ataxia.defences = {}
  ataxiaBasher.infArcAt = nil
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

-- v4.7.152: the maul is a PET order (no balance, no eq of ours), so its only limit is
-- its own cooldown. It used to live INSIDE each spec's swing string, so every round that
-- replaced the swing silently dropped it.
describe("hyena maul rides EVERY round (it costs us nothing)", function()
  it("rides a Tyranny round", function()
    reset(); infArmyOfDead = true; denizens = 3
    local cmd = ataxiaBasher_infernalBashing()
    expect(has(cmd, "tyranny")).toBeTrue()
    expect(has(cmd, "hyena maul 42")).toBeTrue()
  end)

  it("rides an Arc round", function()
    reset(); infIndiscriminate = true; denizens = 3
    local cmd = ataxiaBasher_infernalBashing()
    expect(has(cmd, "arc")).toBeTrue()
    expect(has(cmd, "hyena maul 42")).toBeTrue()
  end)

  it("rides Dual Blunt, which never had it at all", function()
    reset(); ataxia.vitals.knight = "Dual Blunt"
    local cmd = ataxiaBasher_infernalBashing()
    expect(has(cmd, "doublewhirl 42")).toBeTrue()
    expect(has(cmd, "hyena maul 42")).toBeTrue()
  end)

  it("rides Sword and Board and Two Handed", function()
    reset(); ataxia.vitals.knight = "Sword and Board"
    expect(has(ataxiaBasher_infernalBashing(), "hyena maul 42")).toBeTrue()
    reset(); ataxia.vitals.knight = "Two Handed"
    expect(has(ataxiaBasher_infernalBashing(), "hyena maul 42")).toBeTrue()
  end)

  it("HOLDS on a shielded denizen -- a mauled shield burns the whole cooldown", function()
    reset(); ataxiaBasher.shielded = true
    expect(has(ataxiaBasher_infernalBashing(), "hyena maul")).toBeFalse()
  end)
end)

describe("Army of the Dead -- TYRANNY, a one-time summon", function()
  it("does nothing without the boon", function()
    reset(); denizens = 3
    expect(ataxiaBasher_infGravehands(";")).toBe("")
  end)

  it("needs a crowd: solo denizens are not worth 3% essence", function()
    reset(); infArmyOfDead = true; denizens = 1
    expect(ataxiaBasher_infGravehands(";")).toBe("")
  end)

  it("casts TYRANNY for Infernal -- not the Apostate wording", function()
    reset(); infArmyOfDead = true; denizens = 2
    expect(ataxiaBasher_infGravehands(";")).toBe("tyranny;")
  end)

  it("uses the Apostate command when the class is Apostate", function()
    reset(); infArmyOfDead = true; denizens = 2
    gmcp.Char.Status.class = "Apostate"
    expect(ataxiaBasher_infGravehands(";")).toBe("summon hands of the grave;")
    gmcp.Char.Status.class = "Infernal"
  end)

  it("is ONE-TIME -- the hands persist, so it does not re-cast on a rotation cd", function()
    reset(); infArmyOfDead = true; denizens = 2
    expect(ataxiaBasher_infGravehands(";")).toBe("tyranny;")
    expect(ataxiaBasher_infGravehands(";")).toBe("")
    clock = clock + 120 -- two minutes later: still summoned, still silent
    expect(ataxiaBasher_infGravehands(";")).toBe("")
    clock = clock + 500 -- past the long backstop re-arm
    expect(ataxiaBasher_infGravehands(";")).toBe("tyranny;")
  end)

  it("respects the life-essence floor (3% a cast)", function()
    reset(); infArmyOfDead = true; denizens = 2
    ataxia.vitals.essence = 19 -- below the default floor of 20
    expect(ataxiaBasher_infGravehands(";")).toBe("")
    ataxia.vitals.essence = 20
    expect(ataxiaBasher_infGravehands(";")).toBe("tyranny;")
    ataxia.vitals.essence = nil
  end)

  it("REPLACES the swing -- tyranny costs 3s of balance, so it IS the round", function()
    reset(); infArmyOfDead = true; denizens = 3
    local cmd = ataxiaBasher_infernalBashing()
    expect(has(cmd, "tyranny")).toBeTrue()
    expect(has(cmd, "dsl 42")).toBeFalse() -- both would fight over the same balance
    expect(cmd:sub(-1)).toBe("y")          -- no dangling separator
  end)

  it("goes back to the normal swing once it is summoned", function()
    reset(); infArmyOfDead = true; denizens = 3
    ataxiaBasher_infernalBashing() -- summons
    clock = clock + 5
    local cmd = ataxiaBasher_infernalBashing()
    expect(has(cmd, "tyranny")).toBeFalse()
    expect(has(cmd, "dsl 42")).toBeTrue()
  end)

  it("never spends a shield-break round on it", function()
    reset(); infArmyOfDead = true; denizens = 3
    ataxiaBasher.shielded = true
    expect(has(ataxiaBasher_infernalBashing(), "tyranny")).toBeFalse()
  end)
end)

describe("Fury of Ages -- hold FURY while endurance allows", function()
  local function ep(pct)
    gmcp.Char.Vitals = { ep = pct, maxep = 100 }
  end

  it("does nothing without the boon", function()
    reset(); ep(100)
    expect(ataxiaBasher_infFury(";")).toBe("")
  end)

  it("turns fury ON once endurance is healthy", function()
    reset(); infFuryOfAges = true; ep(80)
    expect(ataxiaBasher_infFury(";")).toBe("fury on;")
    expect(ataxiaTemp.infFuryOn).toBeTrue()
  end)

  it("will not turn on at low endurance -- the cost is quadrupled", function()
    reset(); infFuryOfAges = true; ep(40) -- below the 60% on-threshold
    expect(ataxiaBasher_infFury(";")).toBe("")
    expect(ataxiaTemp.infFuryOn).toBe(nil)
  end)

  it("drops fury before endurance strands us", function()
    reset(); infFuryOfAges = true; ep(80)
    expect(ataxiaBasher_infFury(";")).toBe("fury on;")
    clock = clock + 31
    ep(24) -- under the 25% off-threshold
    expect(ataxiaBasher_infFury(";")).toBe("fury off;")
    expect(ataxiaTemp.infFuryOn).toBe(nil)
  end)

  it("holds in the hysteresis band -- no flapping (each activation may cost 500 wp)", function()
    reset(); infFuryOfAges = true; ep(80)
    expect(ataxiaBasher_infFury(";")).toBe("fury on;")
    clock = clock + 31
    ep(40) -- between off(25) and on(60): stays ON, no toggle
    expect(ataxiaBasher_infFury(";")).toBe("")
    expect(ataxiaTemp.infFuryOn).toBeTrue()
  end)

  it("enforces a 30s minimum between toggles", function()
    reset(); infFuryOfAges = true; ep(80)
    expect(ataxiaBasher_infFury(";")).toBe("fury on;")
    ep(10)
    expect(ataxiaBasher_infFury(";")).toBe("") -- too soon to toggle back off
    clock = clock + 31
    expect(ataxiaBasher_infFury(";")).toBe("fury off;")
  end)

  it("rides the round alongside the swing", function()
    reset(); infFuryOfAges = true; ep(80)
    expect(has(ataxiaBasher_infernalBashing(), "fury on")).toBeTrue()
  end)
end)

describe("Necrotic Aura -- keep the deathaura defence up", function()
  it("does nothing without the boon", function()
    reset()
    expect(ataxiaBasher_infDeathaura(";")).toBe("")
  end)

  it("raises deathaura when the boon is up and the defence is down", function()
    reset(); infNecroticAura = true
    expect(ataxiaBasher_infDeathaura(";")).toBe("deathaura;")
  end)

  it("leaves it alone while the defence is standing", function()
    reset(); infNecroticAura = true
    ataxia.defences = { deathaura = true }
    expect(ataxiaBasher_infDeathaura(";")).toBe("")
    ataxia.defences = {}
  end)

  it("holds off re-sending while the defence line lands", function()
    reset(); infNecroticAura = true
    expect(ataxiaBasher_infDeathaura(";")).toBe("deathaura;")
    expect(ataxiaBasher_infDeathaura(";")).toBe("")
    clock = clock + 11
    expect(ataxiaBasher_infDeathaura(";")).toBe("deathaura;")
  end)

  it("prefixes every round, shielded included", function()
    reset(); infNecroticAura = true
    expect(has(ataxiaBasher_infernalBashing(), "deathaura")).toBeTrue()
    reset(); infNecroticAura = true; ataxiaBasher.shielded = true
    expect(has(ataxiaBasher_infernalBashing(), "deathaura")).toBeTrue()
  end)
end)

describe("Indiscriminate -- ARC as a denizen AoE", function()
  it("does nothing without the boon", function()
    reset(); denizens = 4
    expect(ataxiaBasher_infArc(";")).toBe("")
  end)

  it("needs 2+ denizens -- a 4.75s arc costs more than two normal swings", function()
    reset(); infIndiscriminate = true; denizens = 1
    expect(ataxiaBasher_infArc(";")).toBe("")
    reset(); infIndiscriminate = true; denizens = 2
    expect(ataxiaBasher_infArc(";")).toBe("arc")
  end)

  it("swings the UNTARGETED room form, not the single-target one", function()
    reset(); infIndiscriminate = true; denizens = 3
    expect(ataxiaBasher_infArc(";")).toBe("arc") -- naming a target would hit only them
  end)

  it("REPLACES the single-target swing in the assembled command", function()
    reset(); infIndiscriminate = true; denizens = 3
    local cmd = ataxiaBasher_infernalBashing()
    expect(has(cmd, "arc")).toBeTrue()
    expect(has(cmd, "dsl 42")).toBeFalse() -- both spend the same balance
  end)

  it("yields to a shielded round -- break the shield first", function()
    reset(); infIndiscriminate = true; denizens = 3
    ataxiaBasher.shielded = true
    expect(ataxiaBasher_infArc(";")).toBe("")
  end)

  it("honours a custom threshold", function()
    reset(); infIndiscriminate = true; denizens = 2
    ataxiaBasher.infArcAt = 3
    expect(ataxiaBasher_infArc(";")).toBe("")
    denizens = 3
    expect(ataxiaBasher_infArc(";")).toBe("arc")
    ataxiaBasher.infArcAt = nil
  end)
end)

describe("QUASH -- the eq-based shield strip (works on denizens)", function()
  it("only fires while a shield is up", function()
    reset()
    expect(ataxiaBasher_infQuash(";")).toBe("")
    reset(); ataxiaBasher.shielded = true
    expect(ataxiaBasher_infQuash(";")).toBe("quash 42;")
  end)

  it("holds briefly -- it costs 4s of equilibrium, one per round at most", function()
    reset(); ataxiaBasher.shielded = true
    expect(ataxiaBasher_infQuash(";")).toBe("quash 42;")
    expect(ataxiaBasher_infQuash(";")).toBe("")
    clock = clock + 5
    expect(ataxiaBasher_infQuash(";")).toBe("quash 42;")
  end)

  it("rides the shielded round WITHOUT displacing the balance razer or spending rage", function()
    reset(); ataxiaBasher.shielded = true
    local cmd = ataxiaBasher_infernalBashing()
    expect(has(cmd, "quash 42")).toBeTrue()
    expect(has(cmd, "razeslash 42")).toBeTrue() -- the weapon raze still swings
    expect(has(cmd, "shiver")).toBeFalse()  -- ...and no battlerage razer (rageraze off)
  end)

  it("can be switched off", function()
    reset(); ataxiaBasher.shielded = true
    ataxiaBasher.infQuash = false
    expect(ataxiaBasher_infQuash(";")).toBe("")
    ataxiaBasher.infQuash = nil
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
infArmyOfDead, infDaemonJaws, infIndiscriminate = false, false, false
infNecroticAura, infFuryOfAges = false, false
target = nil
