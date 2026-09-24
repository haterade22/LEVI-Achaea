--- test_basher_deadbreath.lua -- BELCH as an AoE under the Dead Breath boon (v4.7.336)
--
-- The boon: "Your belch will now cause significant damage to all denizens in the location, but
-- drains 10% of your mana in the process."  The ability (ABADMIN 136): BELCH, works on the ROOM,
-- 4.00 seconds of EQUILIBRIUM, 200 mana.
--
-- The user's live log is what sets the bar -- one belch, three kills:
--   Damage dealt: 2121 (asphyxiation).  ... 15372 ... 18000
-- and their rule: "we can use belch on denizens 2 or more".

local mock = require("mock_mudlet")

ataxia = ataxia or {}
ataxia.settings = ataxia.settings or {}
ataxia.settings.separator = ";"
ataxia.vitals = ataxia.vitals or {}
ataxiaBasher = ataxiaBasher or {}
ataxiaTemp = ataxiaTemp or {}

local NOW = 5000
local realEpoch = getEpoch
getEpoch = function() return NOW end

local denizens = 2
ataxia.mnemosyne = ataxia.mnemosyne or {}
local realCount = ataxia.mnemosyne._denizenCount
ataxia.mnemosyne._denizenCount = function() return denizens end

local ok, err = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/basher/014_Dead_Breath.lua")
if not ok then error("failed to load the dead breath module: " .. tostring(err)) end

local function reset()
  NOW = 5000
  denizens = 2
  mnemDeadBreath = true
  ataxiaBasher.enabled, ataxiaBasher.shielded = true, false
  ataxiaBasher.deadBreathManaFloor = nil
  ataxia.vitals.mp = 5000
  gmcp = { Char = { Vitals = { maxmp = 6000 } }, Room = { Info = { num = 1234 } } }
  ataxiaTemp.belchAt, ataxiaTemp.belchFouledRoom, ataxiaTemp.belchFouledAt = nil, nil, nil
end

describe("BELCH rides the round only when it pays", function()
  it("fires in a crowd, with the separator the round uses", function()
    reset()
    expect(ataxiaBasher_deadBreathBelch(";")).toBe("belch;")
  end)

  it("holds on a single denizen -- a ROOM attack earns its mana in a crowd", function()
    reset()
    denizens = 1
    expect(ataxiaBasher_deadBreathBelch(";")).toBe("")
    denizens = 2                                   -- the user's rule: two or more
    expect(ataxiaBasher_deadBreathBelch(";")).toBe("belch;")
  end)

  it("does nothing without the boon: a bare belch is not worth the equilibrium", function()
    reset()
    mnemDeadBreath = false
    expect(ataxiaBasher_deadBreathBelch(";")).toBe("")
  end)

  it("breaks the shield first, like every other rider", function()
    reset()
    ataxiaBasher.shielded = true
    expect(ataxiaBasher_deadBreathBelch(";")).toBe("")
  end)

  it("keeps a curing pool: 200 flat plus a tenth of maximum, and a floor under that", function()
    reset()
    ataxia.vitals.mp = 700           -- 200 + 600 drain = 800 > 700
    expect(ataxiaBasher_deadBreathBelch(";")).toBe("")
    ataxia.vitals.mp = 5000
    expect(ataxiaBasher_deadBreathBelch(";")).toBe("belch;")
    reset()
    ataxia.vitals.mp = 3600          -- affordable, but would land at 46% of the pool
    expect(ataxiaBasher_deadBreathBelch(";")).toBe("")
    ataxiaBasher.deadBreathManaFloor = 0             -- ...unless the floor is switched off
    expect(ataxiaBasher_deadBreathBelch(";")).toBe("belch;")
  end)

  it("waits out the ability's own cooldown", function()
    reset()
    expect(ataxiaBasher_deadBreathBelch(";")).toBe("belch;")
    expect(ataxiaBasher_deadBreathBelch(";")).toBe("")   -- 4s of equilibrium
    NOW = NOW + 6
    expect(ataxiaBasher_deadBreathBelch(";")).toBe("belch;")
  end)
end)

describe("the room's own air decides, not a timer", function()
  it("a fouled room refuses, and moving clears it", function()
    reset()
    ataxiaBasher_belchFouled()
    NOW = NOW + 6                                     -- past the ability cooldown...
    expect(ataxiaBasher_deadBreathBelch(";")).toBe("") -- ...but this room is still foul
    gmcp.Room.Info.num = 5678                          -- a new room: clean air
    expect(ataxiaBasher_deadBreathBelch(";")).toBe("belch;")
  end)

  it("the gas thins eventually, even standing still", function()
    reset()
    ataxiaBasher_belchFouled()
    NOW = NOW + 20
    expect(ataxiaBasher_deadBreathBelch(";")).toBe("belch;")
  end)

  it("a landed belch clears the foul mark -- the cloud is ours again", function()
    reset()
    ataxiaBasher_belchFouled()
    ataxiaBasher_belchLanded(false)
    expect(ataxiaTemp.belchFouledRoom).toBeNil()
  end)
end)

describe("the boon's own line proves the boon", function()
  it("the damage line latches the flag; the plain belch line does not", function()
    reset()
    mnemDeadBreath = false
    ataxiaBasher_belchLanded(false)
    expect(mnemDeadBreath).toBeFalse()
    ataxiaBasher_belchLanded(true)
    expect(mnemDeadBreath).toBeTrue()
  end)

  it("the triggers carry the live lines and route them", function()
    local f = io.open("src_new/triggers/levi_ataxia/for_levi/leviticus/778_Belch_Landed.lua")
    local landed = f:read("*a"); f:close()
    expect(landed:find("You belch a cloud of stinking gas out of your lungs", 1, true) ~= nil).toBeTrue()
    expect(landed:find("Your rotten breath befouls the air", 1, true) ~= nil).toBeTrue()
    expect(landed:find("ataxiaBasher_belchLanded(", 1, true) ~= nil).toBeTrue()
    f = io.open("src_new/triggers/levi_ataxia/for_levi/leviticus/779_Belch_Fouled.lua")
    local fouled = f:read("*a"); f:close()
    expect(fouled:find("cough and sputter as you inhale the noxious air", 1, true) ~= nil).toBeTrue()
    expect(fouled:find("ataxiaBasher_belchFouled()", 1, true) ~= nil).toBeTrue()
  end)

  it("the round really asks for it", function()
    local f = io.open("src_new/scripts/levi_ataxia/levi/ataxia/basher/001_Bashing_Functions.lua")
    local src = f:read("*a"); f:close()
    expect(src:find("ataxiaBasher_deadBreathBelch", 1, true) ~= nil).toBeTrue()
    expect(src:find("stareCmd..belchCmd", 1, true) ~= nil).toBeTrue()
  end)
end)

-- Restore shared state for whoever runs after us.
getEpoch = realEpoch
ataxia.mnemosyne._denizenCount = realCount
mnemDeadBreath = nil
ataxiaTemp.belchAt, ataxiaTemp.belchFouledRoom, ataxiaTemp.belchFouledAt = nil, nil, nil
