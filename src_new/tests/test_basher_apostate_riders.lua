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
-- The one exception is the pair of riders themselves: BELCH is also equilibrium, so only one of
-- the two can land in a round, and the room attack wins.

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
  local storm = ataxiaBasher_deathtempestStorm(sp, belch ~= "")
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

  it("but never both riders: one equilibrium, and the room attack takes it", function()
    reset()
    mnemDeadBreath, mnemDeathtempest = true, true
    local cmd = round()
    expect(cmd:find("belch", 1, true) ~= nil).toBeTrue()
    expect(cmd:find("soulstorm", 1, true)).toBeNil()
    expect(cmd:find("deadeyes 77001 bleed bleed", 1, true) ~= nil).toBeTrue()
    -- The belch keeps the equilibrium for as long as it can USE it -- after its cooldown it
    -- simply fires again, which is right: a room attack beats +10% on one mob every time.
    clock = clock + 10
    expect(round():find("belch", 1, true) ~= nil).toBeTrue()
    -- The storm gets the round when the belch cannot take it: here the room is still full of our
    -- own gas (the game refused the last one), which is the common case in a room we are clearing.
    ataxiaBasher_belchFouled()
    clock = clock + 10
    local later = round()
    expect(later:find("belch", 1, true)).toBeNil()
    expect(later:find("soulstorm 77001", 1, true) ~= nil).toBeTrue()
    expect(later:find("deadeyes 77001 bleed bleed", 1, true) ~= nil).toBeTrue()
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

-- Restore shared state for whoever runs after us (test files share one Lua state).
getEpoch = _epoch
mnemDeadBreath, mnemDeathtempest, target = nil, nil, nil
ataxiaTemp.profaned, ataxiaTemp.soulstormAt, ataxiaTemp.soulstormTarget = nil, nil, nil
ataxiaTemp.belchAt, ataxiaTemp.belchFouledRoom, ataxiaTemp.belchFouledAt = nil, nil, nil
