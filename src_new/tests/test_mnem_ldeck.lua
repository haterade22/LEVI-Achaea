--- test_mnem_ldeck.lua -- Mnemosyne legend deck auto-draw (basher/010, v4.7.165)
-- The rules under test (user spec): Maran at 20% hp, Seasone (FOR ELIXIR) at 35%,
-- Morimbuul while bound, Matic at 3+ denizens, and Covenant/Xylthus only when we can
-- afford the battlerage that cashes in the affliction they plant.
--
-- The economics matter as much as the conditions: these cards hold 2-3 charges and
-- regenerate one per HOUR, so the charge gate, the per-card interval, the one-card-
-- per-round cap and the in-flight replay (which stops the 0.3s addclearfull rebuild
-- loop from stamping a draw away unsent) are all first-class assertions here.

require("mock_mudlet")

target = 7
secondTarget = "a lean dirangi"
ataxia = {
  settings = { separator = ";" },
  vitals = { rage = 0, hpp = 100 },
  afflictions = {},
  mnemosyne = { run = {} },
}
ataxiaBasher = { inMnemosyne = true }
ataxiaTemp = {}
gmcp = {
  Room = { Info = { area = "", num = 5 } },
  Char = { Status = { class = "Runewarden" } },
}
function ataxiaEcho() end
function ataxiaBasher_rageAfford(rage, cost)
  return (tonumber(rage) or 0) >= (cost + (tonumber(ataxiaBasher.rageFloor) or 0))
end
local denizenAffs = {}
function ataxiaBasher_dsHasAff(_, aff) return denizenAffs[aff] == true end
local setAffs = {}
function ataxiaBasher_dsSetAff(_, aff) setAffs[aff] = true end
function ataxiaBasher_dsAlert() end

local denizens = 0
ataxia.mnemosyne._denizenCount = function() return denizens end

-- A minimal ldm stand-in. `deck` is the source of truth (the rejection path zeroes
-- it, exactly as the real "lacks the power" trigger does).
ldm = {
  deck = {},
  getCharges = function(key) return (ldm.deck[key] and ldm.deck[key].charges) or 0 end,
  save = function() end,
}
local function setCharges(t)
  ldm.deck = {}
  for k, v in pairs(t) do ldm.deck[k] = { charges = v, max_charges = v } end
end

local _epoch = getEpoch
local clock = 900000
getEpoch = function() return clock end

local ok = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/basher/010_Mnemosyne_Legend_Deck.lua")
if not ok then error("Failed to load the Mnemosyne legend deck file") end

local function reset()
  ataxiaBasher.inMnemosyne = true
  ataxiaBasher.rageFloor = nil
  ataxiaBasher.mnemLdeck.enabled = true
  ataxiaBasher.mnemLdeck.maranAt, ataxiaBasher.mnemLdeck.seasoneAt = 20, 35
  ataxiaBasher.mnemLdeck.maticAt = 3
  ataxia.vitals.rage, ataxia.vitals.hpp = 0, 100
  ataxia.afflictions = {}
  ataxia.mnemosyne.run = {}
  gmcp.Char.Status.class = "Runewarden"
  gmcp.Room.Info.num = 5
  target, secondTarget = 7, "a lean dirangi"
  denizens = 0
  denizenAffs = {}
  setAffs = {}
  ataxiaTemp = {}
  setCharges({ Maran = 2, Seasone = 3, Morimbuul = 3, Matic = 3, Covenant = 3, Xylthus = 3 })
  clock = clock + 1000 -- well past every interval
end

local function pick()
  local key = ataxiaBasher_mnemLdeckPick()
  return key
end

describe("threshold cards -- maran / seasone / morimbuul", function()
  it("draws nothing at full health in an empty room", function()
    reset()
    expect(pick()).toBe(nil)
  end)

  it("SEASONE at 35% and MARAN at 20% -- maran outranks it when both apply", function()
    reset(); ataxia.vitals.hpp = 36
    expect(pick()).toBe(nil)
    reset(); ataxia.vitals.hpp = 35
    expect(pick()).toBe("Seasone")
    reset(); ataxia.vitals.hpp = 20
    expect(pick()).toBe("Maran") -- the barrier is the more urgent of the two
  end)

  it("draws the ELIXIR half of Seasone, not the room-poison half", function()
    reset(); ataxia.vitals.hpp = 30
    local _, cmd = ataxiaBasher_mnemLdeckPick()
    expect(cmd).toBe("ldeck draw seasone for elixir")
  end)

  it("treats an hpp of 0 as blackout/unknown, never as an emergency", function()
    reset(); ataxia.vitals.hpp = 0
    expect(pick()).toBe(nil)
  end)

  it("MORIMBUUL while bound, and it outranks even the barrier", function()
    reset(); ataxia.afflictions.webbed = true
    expect(pick()).toBe("Morimbuul")
    reset(); ataxia.afflictions.entangled = true; ataxia.vitals.hpp = 15
    expect(pick()).toBe("Morimbuul")
  end)
end)

describe("MATIC -- the guaranteed crit, on a crowd", function()
  it("needs the configured denizen count", function()
    reset(); denizens = 2
    expect(pick()).toBe(nil)
    denizens = 3
    expect(pick()).toBe("Matic")
  end)

  it("is once per ROOM even after its interval lapses", function()
    reset(); denizens = 3
    expect(pick()).toBe("Matic")
    expect(ataxiaBasher_mnemLdeck(";")).toBe("ldeck draw matic;")
    ataxiaBasher_mnemLdeckConfirm("Matic")
    clock = clock + 600
    expect(pick()).toBe(nil)     -- same room
    gmcp.Room.Info.num = 6
    expect(pick()).toBe("Matic") -- new room
  end)
end)

describe("COVENANT / XYLTHUS -- only with the rage to cash them in", function()
  it("XYLTHUS needs Etch's 25 rage as Runewarden (it plants stun)", function()
    reset(); ataxia.vitals.rage = 24
    expect(pick()).toBe(nil)
    ataxia.vitals.rage = 25
    expect(pick()).toBe("Xylthus")
  end)

  it("skips when the denizen ALREADY carries the affliction", function()
    reset(); ataxia.vitals.rage = 60; denizenAffs.stun = true
    expect(pick()).toBe(nil)
  end)

  it("respects the rage floor -- the surplus, not the raw rage, must cover it", function()
    reset(); ataxia.vitals.rage = 30; ataxiaBasher.rageFloor = 40
    expect(pick()).toBe(nil)
    ataxia.vitals.rage = 65
    expect(pick()).toBe("Xylthus")
  end)

  it("never spends Xylthus on a boss -- the card cannot bind one", function()
    reset(); ataxia.vitals.rage = 60
    ataxia.mnemosyne.run.boss = "Seasone the Industrious"
    secondTarget = "Seasone, the Industrious"
    expect(pick()).toBe(nil)
    secondTarget = "a lean dirangi" -- an ordinary mob on a boss ripple is fair game
    expect(pick()).toBe("Xylthus")
  end)

  it("card -> CONFIRMED -> battlerage: the stun lands on confirmation, not on send", function()
    reset(); ataxia.vitals.rage = 60
    expect(ataxiaBasher_mnemLdeck(";")).toBe("ldeck draw xylthus 7;")
    expect(setAffs.stun).toBe(nil)   -- Etch must NOT cash a phantom this round
    ataxiaBasher_mnemLdeckConfirm("Xylthus")
    expect(setAffs.stun).toBeTrue()  -- the draw landed: now it is real
  end)

  it("a REJECTED draw stamps nothing, zeroes the charges and drops the replay", function()
    reset(); ataxia.vitals.rage = 60
    ataxiaBasher_mnemLdeck(";")
    ataxiaBasher_mnemLdeckRejected("Xylthus")
    expect(setAffs.stun).toBe(nil)
    expect(ataxiaTemp.mnemLdeckPending).toBe(nil) -- no re-send into the same wall
    expect(ataxiaBasher_mnemLdeck(";")).toBe("")  -- charge gate now holds
  end)

  it("skips the card while its payoff battlerage is still on cooldown", function()
    reset(); ataxia.vitals.rage = 60
    ataxiaTemp.rwBrAt = { etch = clock }        -- Etch just fired, 23s to go
    expect(pick()).toBe(nil)
    ataxiaTemp.rwBrAt = { etch = clock - 25 }
    expect(pick()).toBe("Xylthus")
  end)

  it("COVENANT is drawn by a class that can spend recklessness, and not otherwise", function()
    reset(); ataxia.vitals.rage = 60; gmcp.Char.Status.class = "Blademaster"
    expect(pick()).toBe("Covenant") -- Headstrike, 25 rage
    reset(); ataxia.vitals.rage = 60; gmcp.Char.Status.class = "Magi"
    expect(pick()).toBe("Covenant") -- Firefall, 25 rage
    reset(); ataxia.vitals.rage = 100; gmcp.Char.Status.class = "Psion"
    expect(pick()).toBe(nil)        -- nothing in the Psion rotation reads it
  end)

  it("needs a numeric denizen target -- inert in PvP", function()
    reset(); ataxia.vitals.rage = 60; target = "Somebody"
    expect(pick()).toBe(nil)
  end)
end)

describe("economics -- charges, intervals, one card per round", function()
  it("never draws a card with no charges left", function()
    reset(); ataxia.vitals.hpp = 15; ldm.deck.Maran.charges = 0
    expect(pick()).toBe("Seasone") -- falls through to the next applicable card
    ldm.deck.Seasone.charges = 0
    expect(pick()).toBe(nil)
  end)

  it("honours the per-card interval once a draw is confirmed", function()
    reset(); ataxia.vitals.hpp = 15
    expect(ataxiaBasher_mnemLdeck(";")).toBe("ldeck draw maran;")
    ataxiaBasher_mnemLdeckConfirm("Maran")
    clock = clock + 10
    expect(pick()).toBe("Seasone") -- maran held; the 35% card is still live
    clock = clock + 60             -- 70s > the 65s barrier interval
    expect(pick()).toBe("Maran")
  end)

  it("draws at most ONE card per round", function()
    reset(); ataxia.vitals.hpp = 15; denizens = 4; ataxia.vitals.rage = 60
    local cmd = ataxiaBasher_mnemLdeck(";")
    expect(cmd).toBe("ldeck draw maran;")
    expect(select(2, cmd:gsub("ldeck draw", ""))).toBe(1)
  end)

  it("REPLAYS the pending pick across the addclearfull rebuild loop", function()
    reset(); ataxia.vitals.hpp = 15
    local first = ataxiaBasher_mnemLdeck(";")
    clock = clock + 1
    expect(ataxiaBasher_mnemLdeck(";")).toBe(first) -- verbatim, not stamped away
    expect(ataxiaTemp.mnemLdeckAt.Maran).toBe(nil)  -- nothing stamped until confirmed
  end)

  it("stops replaying once the window lapses, and stamps so it cannot loop", function()
    reset(); ataxia.vitals.hpp = 15; ldm.deck.Seasone.charges = 0
    expect(ataxiaBasher_mnemLdeck(";")).toBe("ldeck draw maran;")
    clock = clock + 5 -- past the 4s pending window, no confirmation ever came
    expect(ataxiaBasher_mnemLdeck(";")).toBe("")
    expect(ataxiaTemp.mnemLdeckAt.Maran).toBe(clock)
  end)

  it("hands the gated-round free-queue command out exactly ONCE per pick", function()
    reset(); ataxia.afflictions.webbed = true
    ataxiaBasher_mnemLdeck(";")
    expect(ataxiaBasher_mnemLdeckFree()).toBe("ldeck draw morimbuul")
    expect(ataxiaBasher_mnemLdeckFree()).toBe(nil) -- `queue add free` accumulates
  end)
end)

describe("gates", function()
  it("is inert outside Mnemosyne -- the tower is what this layer is for", function()
    reset(); ataxia.vitals.hpp = 10; ataxiaBasher.inMnemosyne = false
    expect(pick()).toBe(nil)
    expect(ataxiaBasher_mnemLdeck(";")).toBe("")
  end)

  it("is inert when switched off", function()
    reset(); ataxia.vitals.hpp = 10; ataxiaBasher.mnemLdeck.enabled = false
    expect(pick()).toBe(nil)
  end)

  it("reset() forgets the per-room and in-flight state but keeps the intervals", function()
    reset(); ataxia.vitals.hpp = 15
    ataxiaBasher_mnemLdeck(";")
    ataxiaBasher_mnemLdeckConfirm("Maran")
    ataxiaBasher_mnemLdeckReset()
    expect(ataxiaTemp.mnemLdeckPending).toBe(nil)
    expect(ataxiaTemp.mnemLdeckAt.Maran).toBe(clock) -- charges are global, not per ripple
  end)
end)

-- Restore shared state for whoever runs after us (files share one Lua state).
getEpoch = _epoch
target, secondTarget = nil, nil
ldm = nil
