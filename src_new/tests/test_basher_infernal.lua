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
  -- Arc is WEAPONMASTERY, so v4.7.244 exercises all four knight entry points from here.
  -- Each reads ataxiaBasher.battlerage[<class>].raze, so every one needs a table.
  battlerage = {
    Infernal   = { small = "ravage 42", large = "spike 42", raze = "shiver 42" },
    Paladin    = { small = "smite 42",  large = "rebuke 42", raze = "disrupt 42" },
    Runewarden = { small = "collide 42", large = "onslaught 42", raze = "sunder 42" },
    Unnamable  = { small = "rend 42",   large = "maul 42",   raze = "shatter 42" },
  },
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
  gmcp.Room.Info.num = 1
  ataxiaBasher.infEssenceFloor, ataxiaBasher.infQuash = nil, nil
  ataxia.vitals.essence = nil
  ataxia.vitals.rage, ataxia.vitals.knight = 0, "Dual Cutting"
  ataxiaTemp = {}
  infArmyOfDead, infDaemonJaws, infIndiscriminate = false, false, false
  infNecroticAura, infFuryOfAges = false, false
  mnemWintersHeart, mnemResourceful = false, false
  ataxiaBasher.deepfreezeAt, ataxiaBasher.infTyrannyAt = nil, nil
  gmcp.Char.Vitals = { ep = 100, maxep = 100 }
  ataxia.defences = {}
  ataxiaBasher.arcAt, ataxiaBasher.infArcAt = nil, nil
  ataxiaBasher.falconRakeReady, ataxiaBasher.sowuluAt = false, nil
  mnemThunderclap, mnemHammerAndNail = false, false
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

  -- v4.7.162: Resourceful refunds 10% of the class resource (life essence for Infernal)
  -- per kill, against Tyranny's 3% -- so the crowd gate that existed to protect essence
  -- stops applying and every room with a denizen gets gravehands.
  it("with Resourceful, a SINGLE denizen is enough (kills refund the essence)", function()
    reset(); infArmyOfDead = true; mnemResourceful = true; denizens = 1
    expect(ataxiaBasher_infGravehands(";")).toBe("tyranny;")
  end)

  it("Resourceful alone does nothing without Army of the Dead", function()
    reset(); mnemResourceful = true; denizens = 3
    expect(ataxiaBasher_infGravehands(";")).toBe("")
  end)

  it("Resourceful lowers the essence floor too", function()
    reset(); infArmyOfDead = true; denizens = 2
    ataxia.vitals.essence = 12       -- under the normal 20% floor
    expect(ataxiaBasher_infGravehands(";")).toBe("")
    reset(); infArmyOfDead = true; mnemResourceful = true; denizens = 2
    ataxia.vitals.essence = 12       -- ...but above the Resourceful floor of 10
    expect(ataxiaBasher_infGravehands(";")).toBe("tyranny;")
    ataxia.vitals.essence = nil
  end)

  it("an explicit infTyrannyAt still wins over both", function()
    reset(); infArmyOfDead = true; mnemResourceful = true; denizens = 1
    ataxiaBasher.infTyrannyAt = 3
    expect(ataxiaBasher_infGravehands(";")).toBe("")
    denizens = 3
    expect(ataxiaBasher_infGravehands(";")).toBe("tyranny;")
    ataxiaBasher.infTyrannyAt = nil
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

  it("is ONCE PER ROOM -- every new room can have its own gravehands", function()
    reset(); infArmyOfDead = true; denizens = 2
    gmcp.Room.Info.num = 100
    expect(ataxiaBasher_infGravehands(";")).toBe("tyranny;")
    expect(ataxiaBasher_infGravehands(";")).toBe("") -- same room: already summoned
    clock = clock + 600                              -- ...and time does NOT re-arm it
    expect(ataxiaBasher_infGravehands(";")).toBe("")
    gmcp.Room.Info.num = 101                         -- walked next door
    expect(ataxiaBasher_infGravehands(";")).toBe("tyranny;")
    gmcp.Room.Info.num = 100                         -- back again: that room has its own
    expect(ataxiaBasher_infGravehands(";")).toBe("tyranny;")
  end)

  it("collapses to one slot while gmcp is blind (no room number)", function()
    reset(); infArmyOfDead = true; denizens = 2
    gmcp.Room.Info.num = nil
    expect(ataxiaBasher_infGravehands(";")).toBe("tyranny;")
    expect(ataxiaBasher_infGravehands(";")).toBe("") -- not once per round while blind
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

  it("goes back to the normal swing once this room is summoned", function()
    reset(); infArmyOfDead = true; denizens = 3
    ataxiaBasher_infernalBashing() -- summons in this room
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

describe("Winter's Heart -- DEEPFREEZE as a room-wide cold AoE", function()
  it("does nothing without the boon", function()
    reset(); denizens = 4
    expect(ataxiaBasher_winterDeepfreeze(";")).toBe("")
  end)

  it("needs 2+ denizens -- a spread nuke beats one attack only on a crowd", function()
    reset(); mnemWintersHeart = true; denizens = 1
    expect(ataxiaBasher_winterDeepfreeze(";")).toBe("")
    reset(); mnemWintersHeart = true; denizens = 2
    expect(ataxiaBasher_winterDeepfreeze(";")).toBe("cast deepfreeze;")
  end)

  it("rides the round WITHOUT replacing the swing (it is an eq cast)", function()
    reset(); mnemWintersHeart = true; denizens = 3
    local cmd = ataxiaBasher_infernalBashing()
    expect(has(cmd, "cast deepfreeze")).toBeTrue()
    expect(has(cmd, "dsl 42")).toBeTrue() -- balance swing still happens
  end)

  it("yields on a shielded round", function()
    reset(); mnemWintersHeart = true; denizens = 3
    ataxiaBasher.shielded = true
    expect(ataxiaBasher_winterDeepfreeze(";")).toBe("")
  end)

  it("honours a custom threshold", function()
    reset(); mnemWintersHeart = true; denizens = 2
    ataxiaBasher.deepfreezeAt = 4
    expect(ataxiaBasher_winterDeepfreeze(";")).toBe("")
    denizens = 4
    expect(ataxiaBasher_winterDeepfreeze(";")).toBe("cast deepfreeze;")
    ataxiaBasher.deepfreezeAt = nil
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
    expect(ataxiaBasher_knightArc()).toBe("")
  end)

  -- THE THRESHOLD IS 3 (v4.7.244, user: "if denizens is more than 2"). Arc spends 4.75s of
  -- balance against a ~2s dsl -- 2.375 normal swings -- so at TWO denizens it lands 2 hits
  -- where focused swinging lands ~2.4. It only starts paying at three.
  it("needs 3+ denizens -- a 4.75s arc costs more than two normal swings", function()
    reset(); infIndiscriminate = true; denizens = 1
    expect(ataxiaBasher_knightArc()).toBe("")
    reset(); infIndiscriminate = true; denizens = 2
    expect(ataxiaBasher_knightArc()).toBe("") -- the old default fired here, one mob early
    reset(); infIndiscriminate = true; denizens = 3
    expect(ataxiaBasher_knightArc()).toBe("arc")
  end)

  it("swings the UNTARGETED room form, not the single-target one", function()
    reset(); infIndiscriminate = true; denizens = 3
    expect(ataxiaBasher_knightArc()).toBe("arc") -- naming a target would hit only them
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
    expect(ataxiaBasher_knightArc()).toBe("")
  end)

  it("honours a custom threshold", function()
    reset(); infIndiscriminate = true; denizens = 3
    ataxiaBasher.arcAt = 4
    expect(ataxiaBasher_knightArc()).toBe("")
    denizens = 4
    expect(ataxiaBasher_knightArc()).toBe("arc")
    ataxiaBasher.arcAt = nil
  end)

  -- A hand-tuned value under the OLD key must not be silently discarded by the rename.
  it("still honours the legacy infArcAt key", function()
    reset(); infIndiscriminate = true; denizens = 2
    ataxiaBasher.infArcAt = 2
    expect(ataxiaBasher_knightArc()).toBe("arc")
    ataxiaBasher.infArcAt = nil
  end)

  it("the new key wins over the legacy one", function()
    reset(); infIndiscriminate = true; denizens = 2
    ataxiaBasher.infArcAt = 2
    ataxiaBasher.arcAt = 5
    expect(ataxiaBasher_knightArc()).toBe("")
    ataxiaBasher.infArcAt, ataxiaBasher.arcAt = nil, nil
  end)
end)

-- ARC IS WEAPONMASTERY, NOT AN INFERNAL ABILITY (v4.7.244). It shipped Infernal-only
-- because that was the class in the tower when the boon was captured, which left the other
-- three knights holding a boon that did nothing at all.
describe("Indiscriminate reaches every knight", function()
  local function crowd()
    reset(); infIndiscriminate = true; denizens = 3
    ataxiaTemp.class = "Unnamable"
  end

  it("Paladin swings arc instead of its spec attack", function()
    crowd()
    local cmd = ataxiaBasher_paladinBashing()
    expect(has(cmd, "arc")).toBeTrue()
    expect(has(cmd, "dsl 42")).toBeFalse()
  end)

  it("the generic knight path (Unnamable) swings arc", function()
    crowd()
    local cmd = ataxiaBasher_knightBashing()
    expect(has(cmd, "arc")).toBeTrue()
    expect(has(cmd, "dsl 42")).toBeFalse()
  end)

  it("Runewarden swings arc when it has no bisect", function()
    crowd()
    mnemThunderclap = false
    local cmd = ataxiaBasher_runewardenBashing()
    expect(has(cmd, "arc")).toBeTrue()
    expect(has(cmd, "dsl 42")).toBeFalse()
  end)

  -- Both spend BALANCE, so at most one can land. Bisect buys the same room-wide reach for
  -- the price of an ordinary swing; arc costs 4.75s. Taking the cheap one is free money.
  it("Runewarden prefers BISECT over arc when both are available", function()
    crowd()
    mnemThunderclap = true
    local cmd = ataxiaBasher_runewardenBashing()
    expect(has(cmd, "bisect")).toBeTrue()
    expect(has(cmd, "arc")).toBeFalse()
    mnemThunderclap = false
  end)

  it("no knight swings arc below the threshold", function()
    reset(); infIndiscriminate = true; denizens = 2
    ataxiaTemp.class = "Unnamable"
    expect(has(ataxiaBasher_paladinBashing(), "arc")).toBeFalse()
    expect(has(ataxiaBasher_knightBashing(), "arc")).toBeFalse()
    expect(has(ataxiaBasher_runewardenBashing(), "arc")).toBeFalse()
  end)

  it("and none of them swing it without the boon", function()
    reset(); denizens = 5
    ataxiaTemp.class = "Unnamable"
    expect(has(ataxiaBasher_paladinBashing(), "arc")).toBeFalse()
    expect(has(ataxiaBasher_knightBashing(), "arc")).toBeFalse()
    expect(has(ataxiaBasher_runewardenBashing(), "arc")).toBeFalse()
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

-- SHIELDED SELF-GUARD (v4.7.193, Codex adversarial review). infernalBashing calls
-- infGravehands EAGERLY and then discards the result on its shielded branch -- but the
-- helper had already stamped ataxiaTemp.infTyrannyRoom. That latch is only ever
-- overwritten by a DIFFERENT room number and is never reset, so one shielded first
-- contact meant Tyranny never fired in that room again for the rest of the session.
describe("Army of the Dead -- the room latch must not burn on a discarded round", function()
  it("refuses outright while the denizen is shielded", function()
    reset(); infArmyOfDead = true; denizens = 3
    ataxiaBasher.shielded = true
    expect(ataxiaBasher_infGravehands(";")).toBe("")
  end)

  it("leaves the room UNSTAMPED when it refuses, so the room is still armed", function()
    reset(); infArmyOfDead = true; denizens = 3
    ataxiaBasher.shielded = true
    ataxiaBasher_infGravehands(";")
    expect((ataxiaTemp.infTyrannyRoom)).toBe(nil)
  end)

  it("fires in that same room the moment the shield drops", function()
    reset(); infArmyOfDead = true; denizens = 3
    ataxiaBasher.shielded = true
    expect(ataxiaBasher_infGravehands(";")).toBe("") -- shielded contact
    ataxiaBasher.shielded = false
    expect(ataxiaBasher_infGravehands(";")).toBe("tyranny;") -- the regression: was ""
  end)

  it("full round: the shielded branch emits no tyranny, the next unshielded one does", function()
    reset(); infArmyOfDead = true; denizens = 3
    ataxiaBasher.shielded = true
    expect(has(ataxiaBasher_infernalBashing(), "tyranny")).toBeFalse()
    ataxiaBasher.shielded = false
    expect(has(ataxiaBasher_infernalBashing(), "tyranny")).toBeTrue()
  end)

  it("still latches once per room on the normal unshielded path", function()
    reset(); infArmyOfDead = true; denizens = 3
    expect(ataxiaBasher_infGravehands(";")).toBe("tyranny;")
    expect(ataxiaBasher_infGravehands(";")).toBe("") -- same room, already summoned
    gmcp.Room.Info.num = 2
    expect(ataxiaBasher_infGravehands(";")).toBe("tyranny;") -- new room re-arms
  end)
end)

-- Restore shared state for whoever runs after us (files share one Lua state).
getEpoch = _epoch
infArmyOfDead, infDaemonJaws, infIndiscriminate = false, false, false
infNecroticAura, infFuryOfAges = false, false
mnemWintersHeart, mnemResourceful = false, false
target = nil
