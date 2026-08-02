--- test_rage_fuelled.lua -- the Rage-Fuelled Mnemosyne boon (v4.7.179)
--
-- "When slaying a denizen, your next battlerage attack will cost no resource."
--
-- A kill banks ONE free battlerage. The charge is a STATE, not a timer: it sits until a
-- battlerage actually goes out. The whole payoff routes through ataxiaBasher_rageAfford --
-- the single gate all 37 rotation call sites already use -- so one bypass reaches every
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

-- THE SHARED CULLING BRANCH (v4.7.193, Codex adversarial review). v4.7.179 put
-- `or ataxiaBasher_brFree()` on the seven OWNED culling gates, because culling
-- deliberately bypasses rageAfford to stay floor-exempt. It missed the EIGHTH -- the
-- shared branch inside assembleBattlerage, which is the one every class that does NOT own
-- a rotation actually runs (Infernal, Paladin, Serpent, Apostate, Pariah, Alchemist,
-- Priest, Sentinel, the Elemental Lords...). So for most of the roster the free charge
-- was banked and then declined for the single best thing to spend it on: a free AoE
-- execute. Nothing leaked -- the charge stayed banked and went on a cheaper battlerage
-- further down the same function -- which is exactly why no existing test caught it.
describe("the free charge reaches the SHARED culling branch too", function()
  -- Mirrors the gate at basher/001 inside ataxiaBasher_assembleBattlerage.
  local function sharedCullGate(rage, bigRage)
    return (rage >= bigRage) or ataxiaBasher_brFree()
  end

  it("still requires bigRage with no charge banked", function()
    reset()
    expect(sharedCullGate(35, 36)).toBeFalse()
    expect(sharedCullGate(36, 36)).toBeTrue()
  end)

  it("reaps at ZERO rage while a charge is banked", function()
    reset()
    ataxiaTemp.brFreeCharge = true
    expect(sharedCullGate(0, 36)).toBeTrue()
    expect(sharedCullGate(0, 54)).toBeTrue() -- bigRage is 54 under rageraze
  end)

  it("goes back to normal economics once the charge is spent", function()
    reset()
    ataxiaTemp.brFreeCharge = true
    expect(sharedCullGate(0, 36)).toBeTrue()
    ataxiaBasher_brSent()
    expect(sharedCullGate(0, 36)).toBeFalse()
  end)

  it("is NOT floored -- culling stays floor-exempt with or without a charge", function()
    reset()
    ataxiaBasher.rageFloor = 46
    expect(sharedCullGate(36, 36)).toBeTrue() -- raw compare, floor never consulted
  end)
end)

-- SHIELD DOWN -> RE-ASSEMBLE (v4.7.197). User report: "we tend to waste razing a lot when
-- their shield is down... the problem is an already queued raze". Clearing
-- ataxiaBasher.shielded only decides what the NEXT rebuild looks like; the raze we already
-- sent is in the SERVER-SIDE queue waiting on balance and will execute into a shield that is
-- gone. Only another `queue addclearfull` can replace it, so trigger 335 now re-sends the
-- round immediately rather than waiting for the prompt-driven rebuild.
describe("ataxiaBasher_shieldDropped -- pull back the stale raze", function()
  local calls, realAttack
  local function arm()
    reset()
    calls = 0
    realAttack = ataxiaBasher_attack
    ataxiaBasher_attack = function() calls = calls + 1 end
    ataxiaBasher.enabled, ataxiaBasher.paused = true, nil
    target = 7
    removeShield = nil
  end
  local function disarm() ataxiaBasher_attack = realAttack end

  it("re-sends the round when a denizen's shield comes down", function()
    arm()
    ataxiaBasher_shieldDropped()
    expect(calls).toBe(1)
    disarm()
  end)

  it("throttles to one re-send per second (335 carries ~25 patterns)", function()
    arm()
    ataxiaBasher_shieldDropped()
    ataxiaBasher_shieldDropped() -- our raze line AND the fade line in the same round
    ataxiaBasher_shieldDropped()
    expect(calls).toBe(1)
    clock = clock + 1             -- next second: allowed again
    ataxiaBasher_shieldDropped()
    expect(calls).toBe(2)
    disarm()
  end)

  it("is inert in PvP -- a player's shield is not ours to re-attack through", function()
    arm(); target = "someplayer"
    ataxiaBasher_shieldDropped()
    expect(calls).toBe(0)
    disarm()
  end)

  it("is inert while the basher is off or paused", function()
    arm(); ataxiaBasher.enabled = false
    ataxiaBasher_shieldDropped()
    expect(calls).toBe(0)
    arm(); ataxiaBasher.paused = true
    ataxiaBasher_shieldDropped()
    expect(calls).toBe(0)
    disarm()
  end)

  -- The swarm pull queues "<attack>;<backdir>" as ONE entry; any addclearfull wipes it
  -- before balance. That is the whole reason ataxiaTemp.swarmHold exists.
  it("respects the swarm hold -- never wipes a queued pull chain", function()
    arm(); ataxiaTemp.swarmHold = true
    ataxiaBasher_shieldDropped()
    expect(calls).toBe(0)
    disarm()
  end)

  it("kills 336's pending expiry timer so it cannot outlive this shield", function()
    arm()
    local killed
    local realKill = killTimer
    killTimer = function(id) killed = id end
    removeShield = 4242
    ataxiaBasher_shieldDropped()
    expect(killed).toBe(4242)
    expect(removeShield).toBe(nil)
    killTimer = realKill
    disarm()
  end)

  it("still clears that timer even when the re-attack is gated off", function()
    arm(); ataxiaBasher.enabled = false
    removeShield = 99
    ataxiaBasher_shieldDropped()
    expect(removeShield).toBe(nil) -- the stale-timer hazard is independent of attacking
    expect(calls).toBe(0)
    disarm()
  end)
end)

-- CONTROL-FIRST DENIZENS (v4.7.198). User: "a manifested nightmare -- when facing this
-- denizen we need to use as many battlerages that slow their attacks down as possible."
-- Against a listed mob, the battlerages that spend ITS balance outrank the ones that spend
-- its health. This only REORDERS abilities each class already owns.
describe("ataxiaBasher_controlFirst -- which denizens get the slow treatment", function()
  local function arm(name)
    reset()
    ataxiaBasher.controlMobs = { "manifested nightmare" }
    target, secondTarget = 7, name
  end

  it("matches the seeded denizen by substring, as the game names it", function()
    arm("a manifested nightmare")
    expect(ataxiaBasher_controlFirst()).toBeTrue()
  end)

  it("is case-insensitive", function()
    arm("A Manifested Nightmare")
    expect(ataxiaBasher_controlFirst()).toBeTrue()
  end)

  it("leaves every other denizen on the normal damage-first rotation", function()
    arm("a ghostly deckhand")
    expect(ataxiaBasher_controlFirst()).toBeFalse()
  end)

  it("is inert in PvP -- a player target is never control-first", function()
    arm("a manifested nightmare")
    target = "someplayer"
    expect(ataxiaBasher_controlFirst()).toBeFalse()
  end)

  it("tolerates a missing or empty mob name", function()
    arm(nil)
    expect(ataxiaBasher_controlFirst()).toBeFalse()
    arm("")
    expect(ataxiaBasher_controlFirst()).toBeFalse()
  end)

  it("is off entirely when the list is empty", function()
    arm("a manifested nightmare")
    ataxiaBasher.controlMobs = {}
    expect(ataxiaBasher_controlFirst()).toBeFalse()
  end)

  it("add/remove round-trips, and removal actually sticks", function()
    reset()
    ataxiaBasher.controlMobs = {}
    target, secondTarget = 7, "a howling revenant"
    ataxiaBasher_addControlMob("howling revenant")
    expect(ataxiaBasher_controlFirst()).toBeTrue()
    ataxiaBasher_addControlMob("howling revenant") -- idempotent, no duplicate
    expect(#ataxiaBasher.controlMobs).toBe(1)
    ataxiaBasher_removeControlMob("howling revenant")
    expect(ataxiaBasher_controlFirst()).toBeFalse()
  end)
end)

-- Restore shared state for whoever runs after us (files share one Lua state).
mnemRageFuelled = false
getEpoch = _epoch
target = nil
ataxiaTemp = {}
