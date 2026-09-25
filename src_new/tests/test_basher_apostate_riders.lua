--- test_basher_apostate_riders.lua -- the equilibrium riders and the balance attack share a round
--
-- User (2026-09-24): "It seems like you can soulstorm target and then deadeyes bleed bleed on the
-- same balance" -- "Soulstorm takes eq and deadeyes take balance".
--
-- That is exactly why the necromancy boon abilities were built as RIDERS rather than as rounds of
-- their own: SOULSTORM and BELCH spend EQUILIBRIUM, which the Apostate's `deadeyes <t> bleed bleed`
-- leaves idle while it spends balance. This file pins the pairing the way the assembler builds it,
-- so a later change that makes a rider replace the swing -- or the swing drop a rider -- fails
-- here rather than in a swarm.
--
-- The two riders do NOT compete with each other either (v4.7.343, user: "belch doesnt matter,
-- shouldnt be a criteria. They are two seperate attacks") -- against a denizen the storm's
-- equilibrium cost is "greatly reduced", so a round can carry the belch, the storm and the swing.

require("mock_mudlet")

target = 77001
ataxia = { settings = { separator = ";" }, vitals = { rage = 0, mp = 5000 }, defences = {} }
ataxiaBasher = {
  enabled = true, shielded = false, rageraze = false,
  battlerage = { Apostate = { small = "", large = "", raze = "shiver 77001" } },
}
ataxiaTemp = {}
gmcp = {
  Room = { Info = { area = "", num = 1234 } },
  Char = { Status = { class = "Apostate", level = "80 " }, Vitals = { maxmp = 6000 } },
  IRE = { Target = { Info = {} } },
}
function ataxiaEcho() end
function ataxiaBasher_assembleBattlerage() return "" end

local denizens = 3
ataxia.mnemosyne = { _denizenCount = function() return denizens end }

local _epoch = getEpoch
local clock = 1000000
getEpoch = function() return clock end

for _, f in ipairs({ "002_Class_Bashing", "014_Dead_Breath" }) do
  local ok, err = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/basher/" .. f .. ".lua")
  if not ok then error("failed to load " .. f .. ": " .. tostring(err)) end
end

-- How `ataxiaBasher_assembleAttack` composes the round: riders first, then the class attack.
local function round()
  local sp = ataxia.settings.separator
  local belch = ataxiaBasher_deadBreathBelch(sp)
  local storm = ataxiaBasher_deathtempestStorm(sp)
  return belch .. storm .. ataxiaBasher_apostateBashing()
end

local function reset()
  clock = clock + 100
  mnemDeadBreath, mnemDeathtempest = false, false
  denizens = 3
  ataxiaBasher.shielded = false
  ataxia.vitals.mp = 5000
  ataxiaTemp.belchAt, ataxiaTemp.belchFouledRoom, ataxiaTemp.belchFouledAt = nil, nil, nil
  ataxiaTemp.profaned, ataxiaTemp.soulstormAt, ataxiaTemp.soulstormTarget = {}, nil, nil
  infArmyOfDead, mnemResourceful, mnemGraveborn = false, false, false
  infNecroticAura = false
  ataxia.defences = {}
  ataxiaTemp.infDeathauraAt = nil
  ataxiaBasher.gravehandsManaFloor, ataxiaBasher.infEssenceFloor = nil, nil
  ataxiaBasher.infTyrannyAt = nil
  ataxiaTemp.infTyrannyRoom = nil
  ataxiaTemp.gravehandsAt, ataxiaTemp.gravehandsSeen, ataxiaTemp.gravehandsRetried = nil, nil, nil
  ataxia.vitals.essence = 80
  gmcp.Room.Info.num = 1234
end

describe("one round, two resources", function()
  it("soulstorm (eq) and deadeyes (balance) go out together", function()
    reset()
    mnemDeathtempest = true
    local cmd = round()
    expect(cmd:find("soulstorm 77001", 1, true) ~= nil).toBeTrue()
    expect(cmd:find("deadeyes 77001 bleed bleed", 1, true) ~= nil).toBeTrue()
    -- ...and in that order: the rider is prepended, so the swing is never delayed behind it
    expect(cmd:find("soulstorm", 1, true) < cmd:find("deadeyes", 1, true)).toBeTrue()
  end)

  it("the swing still goes out on its own when no boon is held", function()
    reset()
    local cmd = round()
    expect(cmd:find("deadeyes 77001 bleed bleed", 1, true) ~= nil).toBeTrue()
    expect(cmd:find("soulstorm", 1, true)).toBeNil()
    expect(cmd:find("belch", 1, true)).toBeNil()
  end)

  it("belch (eq) and deadeyes (balance) go out together too", function()
    reset()
    mnemDeadBreath = true
    local cmd = round()
    expect(cmd:find("belch", 1, true) ~= nil).toBeTrue()
    expect(cmd:find("deadeyes 77001 bleed bleed", 1, true) ~= nil).toBeTrue()
  end)

  it("all three together: belch, soulstorm and the swing", function()
    reset()
    mnemDeadBreath, mnemDeathtempest = true, true
    local cmd = round()
    expect(cmd:find("belch", 1, true) ~= nil).toBeTrue()
    expect(cmd:find("soulstorm 77001", 1, true) ~= nil).toBeTrue()
    expect(cmd:find("deadeyes 77001 bleed bleed", 1, true) ~= nil).toBeTrue()
    -- ...and the storm is still once per soul: the next round carries the belch, not a second one
    ataxiaBasher_soulstormLanded()
    clock = clock + 10
    local later = round()
    expect(later:find("belch", 1, true) ~= nil).toBeTrue()
    expect(later:find("soulstorm", 1, true)).toBeNil()
  end)

  it("a shielded target still swings -- the riders stand down, the raze does not", function()
    reset()
    mnemDeadBreath, mnemDeathtempest = true, true
    ataxiaBasher.shielded = true
    ataxiaBasher.rageraze, ataxia.vitals.rage = true, 20
    local cmd = round()
    expect(cmd:find("belch", 1, true)).toBeNil()
    expect(cmd:find("soulstorm", 1, true)).toBeNil()
    expect(cmd:find("shiver 77001", 1, true) ~= nil).toBeTrue()          -- the raze
    expect(cmd:find("deadeyes 77001 bleed bleed", 1, true) ~= nil).toBeTrue()
  end)
end)


-- =====================================================================================
-- ARMY OF THE DEAD on the APOSTATE (v4.7.347, user: "For Apostate")
--
--   Army of the Dead  1  rare
--     When summoning the hands of the grave, you will deal damage to all denizens in the location.
--
--   Gravehands (Necromancy)  ABADMIN ID: 144
--   Syntax:    SUMMON HANDS OF THE GRAVE
--   Cooldown:  3.00 seconds of EQUILIBRIUM
--   Resource:  1.50% life essence and 350 mana
--
-- The helper has carried the Apostate command since v4.7.149 and nothing ever called it from
-- this class's round, so the boon did nothing at all here. These pin the two things that make
-- the Apostate's copy different from the Infernal's: it RIDES the swing (equilibrium against
-- deadeyes' balance) rather than taking the round, and it costs MANA.
describe("Army of the Dead rides the Apostate round", function()
  local function graves(cmd) return cmd:find("summon hands of the grave", 1, true) end

  it("goes out WITH the swing, not instead of it", function()
    reset()
    infArmyOfDead = true
    local cmd = round()
    expect(graves(cmd) ~= nil).toBeTrue()
    expect(cmd:find("deadeyes 77001 bleed bleed", 1, true) ~= nil).toBeTrue()
    -- ...and ahead of it: the eq cast never delays the balance swing
    expect(graves(cmd) < cmd:find("deadeyes", 1, true)).toBeTrue()
  end)

  it("does nothing without the boon", function()
    reset()
    expect(graves(round())).toBeNil()
  end)

  it("needs a crowd -- one denizen is not worth the essence", function()
    reset()
    infArmyOfDead = true; denizens = 1
    expect(graves(round())).toBeNil()
  end)

  it("is a ONE-TIME summon: the hands persist, so the room gets one", function()
    reset()
    infArmyOfDead = true
    expect(graves(round()) ~= nil).toBeTrue()
    ataxiaBasher_gravehandsUp()          -- the game confirms them
    clock = clock + 30
    expect(graves(round())).toBeNil()
    -- ...but the swing still goes every round
    expect(round():find("deadeyes 77001 bleed bleed", 1, true) ~= nil).toBeTrue()
  end)

  it("a new room gets its own", function()
    reset()
    infArmyOfDead = true
    expect(graves(round()) ~= nil).toBeTrue()
    ataxiaBasher_gravehandsUp()
    gmcp.Room.Info.num = 1235
    expect(graves(round()) ~= nil).toBeTrue()
  end)

  it("stands down shielded -- break the shield first, every rider's rule", function()
    reset()
    infArmyOfDead = true
    ataxiaBasher.shielded = true
    ataxiaBasher.rageraze, ataxia.vitals.rage = true, 20
    local cmd = round()
    expect(graves(cmd)).toBeNil()
    expect(cmd:find("shiver 77001", 1, true) ~= nil).toBeTrue()          -- the raze
    expect(cmd:find("deadeyes 77001 bleed bleed", 1, true) ~= nil).toBeTrue()
    -- and the room was NOT burned by the refusal: unshielded, it still fires
    ataxiaBasher.shielded = false
    expect(graves(round()) ~= nil).toBeTrue()
  end)

  it("all four in one round: gravehands, belch, soulstorm and the swing", function()
    reset()
    infArmyOfDead, mnemDeadBreath, mnemDeathtempest = true, true, true
    local cmd = round()
    expect(graves(cmd) ~= nil).toBeTrue()
    expect(cmd:find("belch", 1, true) ~= nil).toBeTrue()
    expect(cmd:find("soulstorm 77001", 1, true) ~= nil).toBeTrue()
    expect(cmd:find("deadeyes 77001 bleed bleed", 1, true) ~= nil).toBeTrue()
  end)
end)

-- 350 MANA is the cost the Infernal's TYRANNY never had to think about, and mana is the curing
-- pool as well as the ammunition.
describe("the gravehands mana floor", function()
  local function graves(cmd) return cmd:find("summon hands of the grave", 1, true) end

  it("refuses outright below the flat cost", function()
    reset()
    infArmyOfDead = true
    ataxia.vitals.mp = 300
    expect(graves(round())).toBeNil()
  end)

  it("refuses when paying it would drop us under the floor", function()
    reset()
    infArmyOfDead = true
    ataxia.vitals.mp = 2500 -- 41.7% of 6000; paying 350 lands under the 40% floor
    expect(graves(round())).toBeNil()
    ataxia.vitals.mp = 5000
    expect(graves(round()) ~= nil).toBeTrue()
  end)

  -- The flat check is not redundant with the floor: the floor is CONFIGURABLE (and silently
  -- inert when the client has told us no maxmp), and 350 mana we do not have is a refusal
  -- whatever the percentage says.
  it("refuses below the flat cost even with the floor turned off", function()
    reset()
    infArmyOfDead = true
    ataxia.vitals.mp = 300
    ataxiaBasher.gravehandsManaFloor = 0
    expect(graves(round())).toBeNil()
    ataxiaBasher.gravehandsManaFloor = nil
  end)

  it("refuses below the flat cost when maxmp is unknown", function()
    reset()
    infArmyOfDead = true
    ataxia.vitals.mp = 300
    gmcp.Char.Vitals.maxmp = nil          -- the floor cannot be computed at all
    expect(graves(round())).toBeNil()
    ataxia.vitals.mp = 5000
    expect(graves(round()) ~= nil).toBeTrue()  -- ...and plenty still fires
    gmcp.Char.Vitals.maxmp = 6000
  end)

  it("takes the floor from config when it is set", function()
    reset()
    infArmyOfDead = true
    ataxia.vitals.mp = 2500
    ataxiaBasher.gravehandsManaFloor = 5 -- the user wants it spent
    expect(graves(round()) ~= nil).toBeTrue()
    ataxiaBasher.gravehandsManaFloor = nil
  end)
end)

-- The stamp is written when we SEND. Without a confirmation the room is burned for the visit --
-- and this round already carries two other equilibrium riders that could have taken the beat.
describe("a summon that was never confirmed retries ONCE", function()
  local function graves(cmd) return cmd:find("summon hands of the grave", 1, true) end

  it("holds while the confirmation could still arrive", function()
    reset()
    infArmyOfDead = true
    expect(graves(round()) ~= nil).toBeTrue()
    clock = clock + 2 -- inside the window
    expect(graves(round())).toBeNil()
  end)

  it("retries once the window passes with no line", function()
    reset()
    infArmyOfDead = true
    expect(graves(round()) ~= nil).toBeTrue()
    clock = clock + 10
    expect(graves(round()) ~= nil).toBeTrue()
  end)

  it("...but only once -- a room that never answers is not a loop", function()
    reset()
    infArmyOfDead = true
    round()
    clock = clock + 10
    expect(graves(round()) ~= nil).toBeTrue()
    clock = clock + 10
    expect(graves(round())).toBeNil()
    clock = clock + 100
    expect(graves(round())).toBeNil()
  end)

  it("never retries once the game has shown us the hands", function()
    reset()
    infArmyOfDead = true
    round()
    ataxiaBasher_gravehandsUp()
    clock = clock + 60
    expect(graves(round())).toBeNil()
  end)

  it("the retry budget is per ROOM, not per session", function()
    reset()
    infArmyOfDead = true
    round(); clock = clock + 10; round()      -- summon + its one retry, both unconfirmed
    clock = clock + 10
    expect(graves(round())).toBeNil()
    gmcp.Room.Info.num = 1240                  -- somewhere new
    expect(graves(round()) ~= nil).toBeTrue()
    clock = clock + 10
    expect(graves(round()) ~= nil).toBeTrue()  -- and its own retry
  end)

  -- The Infernal is deliberately excluded: TYRANNY's confirmation line has never been captured,
  -- so "unconfirmed" would be its permanent state and this would re-cast every few seconds --
  -- the v4.7.148 bug that burned 3% life essence a go.
  it("does NOT apply to the Infernal's TYRANNY", function()
    reset()
    infArmyOfDead = true
    gmcp.Char.Status.class = "Infernal"
    expect(ataxiaBasher_infGravehands(";")).toBe("tyranny;")
    clock = clock + 600
    expect(ataxiaBasher_infGravehands(";")).toBe("")
    gmcp.Char.Status.class = "Apostate"
  end)

  -- 350 mana is the GRAVEHANDS cost (ABADMIN 144). TYRANNY is a different ability and its cost
  -- is not this one, so the mana gate must not follow the boon across the class line.
  it("and the Apostate's 350-mana cost does not follow it either", function()
    reset()
    infArmyOfDead = true
    gmcp.Char.Status.class = "Infernal"
    ataxia.vitals.mp = 10                       -- nowhere near 350
    expect(ataxiaBasher_infGravehands(";")).toBe("tyranny;")
    gmcp.Char.Status.class = "Apostate"
  end)
end)

describe("the gravehands lines", function()
  local function slurp(p) local f = io.open(p); local s = f:read("*a"); f:close(); return s end

  it("the summon line confirms the hands, and does NOT latch the boon", function()
    local t = slurp("src_new/triggers/levi_ataxia/for_levi/leviticus/782_Gravehands_Up.lua")
    expect(t:find("hands of rotting flesh and white bone push out of the ground", 1, true) ~= nil).toBeTrue()
    expect(t:find("if ataxiaBasher_gravehandsUp then", 1, true) ~= nil).toBeTrue()
    -- the base ability prints it with or without the boon; a wrong latch is paid for every room
    expect(t:find("infArmyOfDead = true", 1, true)).toBeNil()
  end)

  it("both lines are highlighted, in a colour neither sibling rider uses", function()
    local t = slurp("src_new/triggers/levi_ataxia/for_levi/leviticus/highlighting/066_Gravehands_Highlight.lua")
    expect(t:find("hands of rotting flesh and white bone push out of the ground", 1, true) ~= nil).toBeTrue()
    expect(t:find("the chill of the grave striking out amidst a rasping chorus of death", 1, true) ~= nil).toBeTrue()
    -- Read the COLOURS the file chooses, not the words it contains: the comment explains why
    -- the orange family is off-limits, and a bare text search for "orange" matches that prose.
    -- Same trap as v4.7.346's trigger-wiring assertion, which matched a name in a comment.
    local chosen = {}
    for c in t:gmatch('fg%("([%w_]+)"%)') do chosen[#chosen + 1] = c end
    expect(#chosen > 0).toBeTrue()
    for _, c in ipairs(chosen) do
      expect(c).toBe("cadet_blue")         -- never the belch's goldenrod or the storm's orchid
      expect(c:find("orange", 1, true)).toBeNil()  -- reserved family
    end
    expect(t:find("selectString(line, 1)", 1, true) ~= nil).toBeTrue()
    expect(t:find("resetFormat()", 1, true) ~= nil).toBeTrue()
  end)
end)


-- =====================================================================================
-- GRAVEBORN -- the combo that turns the hands into an engine (v4.7.348)
--
--   Graveborn:  rare / Offence / Can echo: No
--   Unlocked By: Army of the Dead, Maliceborn, and Necrotic Aura
--   "While standing in gravehands, your attacks will command them to ravage your enemies,
--    damaging all denizens in your location. This can only trigger every 15 seconds."
--
-- User: "We need to ensure we gravehands every room to maximize this."
--
-- The crowd gate existed because the summon was ONE AoE hit, and one denizen did not repay the
-- cast. Graveborn changes what is being bought: the hands fire every 15 seconds for as long as
-- we stand in them and keep swinging, so a room we skip is an engine we never built. These pin
-- the three gates that decide whether "every room" is true -- the crowd, the essence and the
-- mana -- because any one of them silently skipping a room defeats the boon.
describe("Graveborn: gravehands in EVERY room", function()
  local function graves(cmd) return cmd:find("summon hands of the grave", 1, true) end

  it("one denizen is enough", function()
    reset()
    infArmyOfDead, mnemGraveborn = true, true
    denizens = 1
    expect(graves(round()) ~= nil).toBeTrue()
  end)

  it("...where without it, one denizen is not", function()
    reset()
    infArmyOfDead = true
    denizens = 1
    expect(graves(round())).toBeNil()
  end)

  it("does nothing on its own -- the summon still needs Army of the Dead", function()
    reset()
    mnemGraveborn = true
    denizens = 3
    expect(graves(round())).toBeNil()
  end)

  -- Graveborn is UNLOCKED BY Maliceborn ("Slaying a denizen will now restore 5% of your life
  -- essence"), so holding it means holding the refund -- a kill pays back more than three casts.
  it("drops the essence floor, because the combo contains the refund", function()
    reset()
    infArmyOfDead = true
    ataxia.vitals.essence = 12          -- under the standing 20% floor
    expect(graves(round())).toBeNil()
    reset()
    infArmyOfDead, mnemGraveborn = true, true
    ataxia.vitals.essence = 12          -- ...but above the 10% one Graveborn allows
    expect(graves(round()) ~= nil).toBeTrue()
  end)

  it("drops the mana floor -- skipping a room now costs every proc it would have fired", function()
    reset()
    infArmyOfDead = true
    ataxia.vitals.mp = 2500             -- 41.7%; paying 350 lands under the standing 40% floor
    expect(graves(round())).toBeNil()
    reset()
    infArmyOfDead, mnemGraveborn = true, true
    ataxia.vitals.mp = 2500             -- ...but clear of the 25% one Graveborn allows
    expect(graves(round()) ~= nil).toBeTrue()
  end)

  it("never waives the floors, only lowers them", function()
    reset()
    infArmyOfDead, mnemGraveborn = true, true
    ataxia.vitals.mp = 1000             -- 16.7%: under even the Graveborn floor
    expect(graves(round())).toBeNil()
    reset()
    infArmyOfDead, mnemGraveborn = true, true
    ataxia.vitals.essence = 4
    expect(graves(round())).toBeNil()
  end)

  it("an explicit setting still beats the boon, both ways", function()
    reset()
    infArmyOfDead, mnemGraveborn = true, true
    ataxiaBasher.infTyrannyAt = 3       -- the user wants a real crowd regardless
    denizens = 1
    expect(graves(round())).toBeNil()
    reset()
    infArmyOfDead = true                -- ...and without the boon, they can ask for every room
    ataxiaBasher.infTyrannyAt = 1
    denizens = 1
    expect(graves(round()) ~= nil).toBeTrue()
  end)
end)

-- NECROTIC AURA was inert on this class for the same reason Army of the Dead was: the helper is
-- class-agnostic (DEATHAURA is a Necromancy defence) and only the Infernal round ever called it.
-- It is one of the three boons GRAVEBORN is unlocked by, so an Apostate on the combo path holds
-- it by definition.
describe("Necrotic Aura keeps the deathaura up on the Apostate", function()
  it("raises it when the boon is held and the defence is down", function()
    reset()
    infNecroticAura = true
    expect(round():find("deathaura", 1, true) ~= nil).toBeTrue()
  end)

  it("does nothing without the boon", function()
    reset()
    expect(round():find("deathaura", 1, true)).toBeNil()
  end)

  it("does nothing while the defence is already up", function()
    reset()
    infNecroticAura = true
    ataxia.defences.deathaura = true
    expect(round():find("deathaura", 1, true)).toBeNil()
  end)

  it("rides the shielded branch too -- raising a defence is not an attack", function()
    reset()
    infNecroticAura = true
    ataxiaBasher.shielded = true
    ataxiaBasher.rageraze, ataxia.vitals.rage = true, 20
    local cmd = round()
    expect(cmd:find("deathaura", 1, true) ~= nil).toBeTrue()
    expect(cmd:find("shiver 77001", 1, true) ~= nil).toBeTrue()
    expect(cmd:find("deadeyes 77001 bleed bleed", 1, true) ~= nil).toBeTrue()
  end)

  it("and on the shielded branch WITHOUT rageraze, which has no raze to hide behind", function()
    reset()
    infNecroticAura = true
    ataxiaBasher.shielded = true
    ataxiaBasher.rageraze = false
    local cmd = round()
    expect(cmd:find("deathaura", 1, true) ~= nil).toBeTrue()
    expect(cmd:find("deadeyes 77001 bleed bleed", 1, true) ~= nil).toBeTrue()
  end)

  it("re-raises no more than once every ten seconds", function()
    reset()
    infNecroticAura = true
    expect(round():find("deathaura", 1, true) ~= nil).toBeTrue()
    clock = clock + 2
    expect(round():find("deathaura", 1, true)).toBeNil()
    clock = clock + 20
    expect(round():find("deathaura", 1, true) ~= nil).toBeTrue()
  end)
end)

describe("the Graveborn boon flag is wired everywhere a boon flag must be", function()
  local function slurp(p) local f = io.open(p); local s = f:read("*a"); f:close(); return s end
  local S = "src_new/scripts/levi_ataxia/levi/ataxia/"

  it("the catalogue, so a claim or a contemplate latches it", function()
    local t = slurp(S .. "mnemosyne/004_Parsers.lua")
    expect(t:find('["Graveborn"]            = "mnemGraveborn"', 1, true) ~= nil).toBeTrue()
  end)

  it("both resets -- a boon that outlives its run is a boon that lies", function()
    expect(slurp(S .. "mnemosyne/004_Parsers.lua"):find("mnemGraveborn = false", 1, true) ~= nil).toBeTrue()
    expect(slurp("src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/001_Run_Start.lua")
      :find("mnemGraveborn = false", 1, true) ~= nil).toBeTrue()
  end)

  it("the claim line and the BOONS row", function()
    expect(slurp("src_new/aliases/levi_ataxia/for_levi/levi_062424/mnemosyne/002_Boon_Claim.lua")
      :find('find("graveborn")', 1, true) ~= nil).toBeTrue()
    local row = slurp("src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/098_Graveborn.lua")
    expect(row:find("^Graveborn", 1, true) ~= nil).toBeTrue()
    expect(row:find("mnemGraveborn = true", 1, true) ~= nil).toBeTrue()
  end)

  it("the combo recipe, with all three components the game named", function()
    local t = slurp(S .. "mnemosyne/010_Boon_Seed.lua")
    local rec = t:match('%["Graveborn"%] = %b{}')
    expect(rec ~= nil).toBeTrue()
    expect(rec:find("Army of the Dead", 1, true) ~= nil).toBeTrue()
    expect(rec:find("Maliceborn", 1, true) ~= nil).toBeTrue()
    expect(rec:find("Necrotic Aura", 1, true) ~= nil).toBeTrue()
    expect(rec:find('rarity = "rare"', 1, true) ~= nil).toBeTrue()
    expect(rec:find('category = "Offence"', 1, true) ~= nil).toBeTrue()
    expect(rec:find("maxEchoes = 0", 1, true) ~= nil).toBeTrue()   -- "Can echo: No"
  end)
end)

-- Restore shared state for whoever runs after us (test files share one Lua state).
getEpoch = _epoch
mnemDeadBreath, mnemDeathtempest, target = nil, nil, nil
infArmyOfDead, mnemResourceful, mnemGraveborn = nil, nil, nil
infNecroticAura = nil
ataxiaTemp.infDeathauraAt = nil
ataxiaTemp.infTyrannyRoom = nil
ataxiaTemp.gravehandsAt, ataxiaTemp.gravehandsSeen, ataxiaTemp.gravehandsRetried = nil, nil, nil
ataxiaTemp.profaned, ataxiaTemp.soulstormAt, ataxiaTemp.soulstormTarget = nil, nil, nil
ataxiaTemp.belchAt, ataxiaTemp.belchFouledRoom, ataxiaTemp.belchFouledAt = nil, nil, nil
