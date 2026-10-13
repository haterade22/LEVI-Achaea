--- test_battlerage_fallback.lua -- the shared battlerage path never idles (v4.7.421)
--
-- Live Serpent log (2026-10-12): Rage-Fuelled banked a free battlerage on every kill and rage
-- sat at 98-100, yet only thrash and culling ever fired. Three faults on the SHARED path (every
-- class without an owned rotation):
--   1. against one denizen the rotation stopped after small and large, so the special
--      (Serpent obliviate) never fired however long both sat on cooldown;
--   2. nothing on that path read the game's ~1s global battlerage cooldown, so the round right
--      after a battlerage kill queued another and the game refused it -- and the refused send
--      had already spent our record of the free charge;
--   3. the game's "You can use Thrash again." was ignored for every class but the Bard.
-- User: "We should be using all battle rage abilities if others (damage) are on cooldown for
-- every class".

require("mock_mudlet")

function ataxiaEcho(...) end
function get_Battlerage() end
function ataxia_saveSettings(...) end
function ataxiaBasher_canShield() return true end

ataxia = ataxia or {}
ataxia.settings = ataxia.settings or {}
ataxia.settings.separator = ";"
ataxia.vitals = ataxia.vitals or {}
ataxiaBasher = ataxiaBasher or {}
ataxiaTemp = ataxiaTemp or {}
battleRage_Timers = {}
stormhammerTargets = {}
target = 1
gmcp = gmcp or {}
gmcp.Room = { Info = { area = "" } }
gmcp.Char = gmcp.Char or {}
gmcp.Char.Status = { class = "Serpent", level = "99 " }
gmcp.IRE = { Target = { Info = {} } }

local B = "src_new/scripts/levi_ataxia/levi/ataxia/basher/"
assert(pcall(dofile, B .. "001_Bashing_Functions.lua"))
assert(pcall(dofile, B .. "011_Battlerage_Ready_Lines.lua"))

local savedValid, savedEpoch = ataxiaBasher_validTargets, getEpoch
local nowT = 1000
getEpoch = function() return nowT end
local targets = 1
ataxiaBasher_validTargets = function() return targets end

local function reset(class)
  gmcp.Char.Status.class = class or "Serpent"
  gmcp.Room.Info.area = ""
  battleRage_Timers = {}
  stormhammerTargets = {}
  targets = 1
  nowT = 1000
  ataxia.vitals.rage = 100
  ataxiaBasher.cullingBlade = false
  ataxiaBasher.rageraze = nil
  ataxiaBasher.rageFloor = nil
  ataxiaBasher.floorCulling = nil
  ataxiaBasher.rageConserveThreshold = nil
  ataxiaTemp.bladeCooldown = nil
  ataxiaTemp.brGlobalReadyAt = nil
  ataxiaTemp.brFreeCharge = nil
  ataxiaTemp.brFreeSpentAt = nil
  ataxiaBasher.battlerage = {
    Serpent = { small = "thrash 1", large = "throatrip 1", raze = "excoriate 1", special = "obliviate 1" },
    Infernal = { small = "smash 1", large = "crush 1", special = "oppress 1" },
    Shaman = { small = "curse 1 c", large = "invoke spirit 1", special = "invoke korkma 1" },
  }
end

describe("shared battlerage -- the special is the last resort against one denizen", function()
  it("damage first: thrash, then throatrip", function()
    reset()
    expect(ataxiaBasher_assembleBattlerage()).toBe("thrash 1;")
    reset(); battleRage_Timers.small = 1
    expect(ataxiaBasher_assembleBattlerage()).toBe("throatrip 1;")
  end)

  it("obliviate once thrash and throatrip are both on cooldown", function()
    reset(); battleRage_Timers.small = 1; battleRage_Timers.large = 1
    expect(ataxiaBasher_assembleBattlerage()).toBe("obliviate 1;")
  end)

  it("nothing when all three are on cooldown", function()
    reset(); battleRage_Timers.small = 1; battleRage_Timers.large = 1; battleRage_Timers.special = 1
    expect(ataxiaBasher_assembleBattlerage()).toBe("")
  end)

  it("every class on the standard path gets the fallback (Infernal)", function()
    reset("Infernal"); battleRage_Timers.small = 1; battleRage_Timers.large = 1
    expect(ataxiaBasher_assembleBattlerage()).toBe("oppress 1;")
  end)

  it("the rage floor still binds the fallback", function()
    reset(); battleRage_Timers.small = 1; battleRage_Timers.large = 1
    ataxiaBasher.rageFloor = 80 -- obliviate 28 + 80 > 100
    expect(ataxiaBasher_assembleBattlerage()).toBe("")
  end)

  it("a free Rage-Fuelled charge pays for it despite the floor, and is spent", function()
    reset(); battleRage_Timers.small = 1; battleRage_Timers.large = 1
    ataxiaBasher.rageFloor = 80; ataxiaTemp.brFreeCharge = true
    expect(ataxiaBasher_assembleBattlerage()).toBe("obliviate 1;")
    expect(ataxiaTemp.brFreeCharge).toBe(nil)
  end)

  it("2+ denizens: unchanged -- the special first, small/large only once it is on cooldown", function()
    reset(); targets = 2
    expect(ataxiaBasher_assembleBattlerage()).toBe("obliviate 1;")
    reset(); targets = 2; battleRage_Timers.special = 1
    expect(ataxiaBasher_assembleBattlerage()).toBe("thrash 1;")
  end)

  it("crowd-control classes below 3 targets fall back to their special (Shaman korkma)", function()
    reset("Shaman"); battleRage_Timers.small = 1; battleRage_Timers.large = 1
    expect(ataxiaBasher_assembleBattlerage()).toBe(" invoke korkma 1;")
  end)
end)

describe("shared battlerage -- the global cooldown", function()
  it("a confirmed fire line holds the next battlerage for 1s", function()
    reset()
    ataxiaBasher_brFired()
    expect(ataxiaBasher_assembleBattlerage()).toBe("")
    nowT = nowT + 1
    expect(ataxiaBasher_assembleBattlerage()).toBe("thrash 1;")
  end)

  it("the held round does not spend the free charge", function()
    reset(); ataxiaTemp.brFreeCharge = true
    ataxiaBasher_brFired()
    expect(ataxiaBasher_assembleBattlerage()).toBe("")
    expect(ataxiaTemp.brFreeCharge).toBeTrue()
  end)

  it("culling reap waits for it too", function()
    reset(); ataxiaBasher.cullingBlade = true
    ataxiaBasher_brFired()
    expect(ataxiaBasher_assembleBattlerage()).toBe("")
    nowT = nowT + 1
    expect(ataxiaBasher_assembleBattlerage()).toBe("reap 1;")
  end)
end)

describe("Rage-Fuelled -- a refused battlerage gives the charge back", function()
  it("refusal within the window restores the charge", function()
    reset(); ataxiaTemp.brFreeCharge = true
    expect(ataxiaBasher_assembleBattlerage()).toBe("thrash 1;")
    expect(ataxiaTemp.brFreeCharge).toBe(nil)
    nowT = nowT + 0.5
    ataxiaBasher_brRefused()
    expect(ataxiaTemp.brFreeCharge).toBeTrue()
  end)

  it("a stale spend is not refunded", function()
    reset(); ataxiaTemp.brFreeCharge = true
    ataxiaBasher_assembleBattlerage()
    nowT = nowT + 5
    ataxiaBasher_brRefused()
    expect(ataxiaTemp.brFreeCharge).toBe(nil)
  end)

  it("a refusal with no charge spent banks nothing", function()
    reset()
    ataxiaBasher_assembleBattlerage()
    ataxiaBasher_brRefused()
    expect(ataxiaTemp.brFreeCharge).toBe(nil)
  end)
end)

describe("ready lines -- every class's own verbs clear their slot", function()
  it("Thrash / Throatrip / Obliviate for a Serpent", function()
    reset(); battleRage_Timers = { small = 1, large = 2, special = 3 }
    expect(ataxiaBasher_brReady("Thrash")).toBe("small")
    expect(ataxiaBasher_brReady("Throatrip")).toBe("large")
    expect(ataxiaBasher_brReady("Obliviate")).toBe("special")
    expect(battleRage_Timers.small).toBe(nil)
    expect(battleRage_Timers.large).toBe(nil)
    expect(battleRage_Timers.special).toBe(nil)
  end)

  it("a multi-word command matches on its ability word (Korkma)", function()
    reset("Shaman"); battleRage_Timers = { special = 3 }
    expect(ataxiaBasher_brReady("Korkma")).toBe("special")
  end)

  it("an unknown verb changes nothing", function()
    reset(); battleRage_Timers = { small = 1 }
    expect(ataxiaBasher_brReady("Flagellate")).toBe(nil)
    expect(battleRage_Timers.small).toBe(1)
  end)
end)

describe("trigger 332 -- obliviate's fire line survives the server wrap", function()
  local TL = dofile("src_new/tests/trigger_lib.lua")
  local file = "src_new/triggers/levi_ataxia/for_levi/leviticus/332_Battlerage_Special.lua"
  local line = "You draw an extraordinarily bloated invar malagma's attention with the wavering tip of one"
    .. " finger, then quickly snap your fingers in front of his face, the sudden sound temporarily"
    .. " blanking his mind."
  for _, w in ipairs({ 100, 119, 124 }) do
    it("fires at width " .. w, function()
      local pats, hit = TL.patterns(file), false
      for _, row in ipairs(TL.wrap(line, w)) do
        if TL.anyMatches(pats, row) then hit = true end
      end
      expect(hit).toBeTrue()
    end)
  end
end)

ataxiaBasher_validTargets, getEpoch = savedValid, savedEpoch
