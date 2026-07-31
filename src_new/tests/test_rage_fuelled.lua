--- test_rage_fuelled.lua -- the Rage-Fuelled Mnemosyne boon (v4.7.179)
--
-- "When slaying a denizen, your next battlerage attack will cost no resource."
--
-- A kill banks ONE free battlerage. The charge is a STATE, not a timer: it sits until a
-- battlerage actually goes out. The whole payoff routes through ataxiaBasher_rageAfford --
-- the single gate all 40 rotation call sites already use -- so one bypass reaches every
-- class. Culling reap is the exception that needs explicit handling, because it
-- deliberately sidesteps rageAfford to stay floor-exempt.

require("mock_mudlet")

target = 7
ataxia = {
  settings = { separator = ";" },
  vitals = { rage = 0, knight = "Sword and Board" },
  defences = {},
  afflictions = {},
}
ataxiaBasher = { enabled = true, battlerage = {} }
ataxiaTemp = {}
gmcp = {
  Room = { Info = { area = "", num = 5 } },
  Char = { Status = { class = "Runewarden" }, Vitals = {} },
  IRE = { Target = { Info = {} } },
}
function ataxiaEcho() end
function bashConsoleEcho() end

local _epoch = getEpoch
local clock = 500000
getEpoch = function() return clock end

local ok = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/basher/001_Bashing_Functions.lua")
if not ok then error("Failed to load bashing functions") end

local function reset()
  ataxiaTemp = {}
  ataxiaBasher.rageFloor = nil
  mnemRageFuelled = false
  clock = clock + 100
end

describe("ataxiaBasher_brFree -- the banked charge", function()
  it("is empty until something banks it", function()
    reset()
    expect(ataxiaBasher_brFree()).toBeFalse()
  end)

  it("reads the charge, and tolerates a missing ataxiaTemp", function()
    reset()
    ataxiaTemp.brFreeCharge = true
    expect(ataxiaBasher_brFree()).toBeTrue()
    ataxiaTemp.brFreeCharge = nil
    expect(ataxiaBasher_brFree()).toBeFalse()
  end)
end)

describe("ataxiaBasher_rageAfford -- the single gate the boon rides", function()
  it("behaves exactly as before with no charge banked", function()
    reset()
    expect(ataxiaBasher_rageAfford(35, 36)).toBeFalse()
    expect(ataxiaBasher_rageAfford(36, 36)).toBeTrue()
  end)

  it("still honours the rage floor with no charge banked", function()
    reset()
    ataxiaBasher.rageFloor = 40
    expect(ataxiaBasher_rageAfford(50, 36)).toBeFalse() -- 36 + 40 floor = 76
    expect(ataxiaBasher_rageAfford(76, 36)).toBeTrue()
  end)

  it("makes ANY cost affordable while a charge is banked -- even at zero rage", function()
    reset()
    ataxiaTemp.brFreeCharge = true
    expect(ataxiaBasher_rageAfford(0, 36)).toBeTrue()
    expect(ataxiaBasher_rageAfford(0, 999)).toBeTrue()
  end)

  it("short-circuits the FLOOR too -- a free ability has no surplus to preserve", function()
    reset()
    ataxiaBasher.rageFloor = 46
    ataxiaTemp.brFreeCharge = true
    expect(ataxiaBasher_rageAfford(0, 36)).toBeTrue()
  end)
end)

describe("ataxiaBasher_brSent -- the commit point", function()
  it("arms the ~1s global cooldown AND spends the charge, in lockstep", function()
    reset()
    ataxiaTemp.brFreeCharge = true
    ataxiaBasher_brSent()
    expect(ataxiaTemp.brGlobalReadyAt).toBe(clock + 1)
    expect(ataxiaTemp.brFreeCharge).toBe(nil)
    expect(ataxiaBasher_brFree()).toBeFalse()
  end)

  it("is harmless when no charge was banked", function()
    reset()
    ataxiaBasher_brSent()
    expect(ataxiaTemp.brGlobalReadyAt).toBe(clock + 1)
    expect(ataxiaTemp.brFreeCharge).toBe(nil)
  end)

  it("spends only ONE charge -- the second battlerage pays full price", function()
    reset()
    ataxiaTemp.brFreeCharge = true
    expect(ataxiaBasher_rageAfford(0, 36)).toBeTrue()
    ataxiaBasher_brSent()
    expect(ataxiaBasher_rageAfford(0, 36)).toBeFalse() -- back to normal economics
  end)
end)

describe("the kill only banks a charge while the BOON is up", function()
  -- Mirrors the guarded arm in trigger 340_Slain.
  local function onSlain()
    if mnemRageFuelled then ataxiaTemp.brFreeCharge = true end
  end

  it("banks nothing without the boon", function()
    reset()
    onSlain()
    expect(ataxiaBasher_brFree()).toBeFalse()
  end)

  it("banks a charge with the boon, and a second kill does not stack it", function()
    reset()
    mnemRageFuelled = true
    onSlain()
    expect(ataxiaBasher_brFree()).toBeTrue()
    onSlain() -- the game banks ONE; re-arming is idempotent, not cumulative
    expect(ataxiaBasher_brFree()).toBeTrue()
    ataxiaBasher_brSent()
    expect(ataxiaBasher_brFree()).toBeFalse()
  end)

  it("re-banks on the NEXT kill after the charge is spent", function()
    reset()
    mnemRageFuelled = true
    onSlain(); ataxiaBasher_brSent()
    expect(ataxiaBasher_brFree()).toBeFalse()
    onSlain()
    expect(ataxiaBasher_brFree()).toBeTrue()
  end)
end)

-- Restore shared state for whoever runs after us (files share one Lua state).
mnemRageFuelled = false
getEpoch = _epoch
target = nil
ataxiaTemp = {}
