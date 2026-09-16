--- test_searing_light.lua -- Searing Light: CONJURE LIGHTWALL first, at 2+ denizens (Serpent)
--
-- Boon (captured 2026-09-16): "Conjuring a lightwall now deals fire damage to all denizens in
-- your location." User: "the first thing we need to do is conjure lightwall in any direction" --
-- and, v4.7.309, "regardless of denizen as it does fire damage one time". AB Lightwall: 4.00s of
-- EQUILIBRIUM, 45 mana -- so it rides beside the balance garrote, first in the chain, behind a mana
-- floor; once per room on the first free planar exit, and a refused direction rotates to the next.
--
-- Loads the real basher/002_Class_Bashing.lua. Files share ONE Lua state: every global touched
-- here is saved at the top and restored at the bottom.

require("mock_mudlet")

local saved = {
  target = target, ataxia = ataxia, ataxiaBasher = ataxiaBasher, ataxiaTemp = ataxiaTemp,
  gmcp = gmcp, getEpoch = getEpoch, mnemSearingLight = mnemSearingLight, ataxiaEcho = ataxiaEcho,
  ataxiaBasher_assembleBattlerage = ataxiaBasher_assembleBattlerage,
}

target = 7
ataxia = { settings = { separator = ";" }, vitals = { rage = 0, mp = 3000 }, defences = {} }
ataxiaBasher = { shielded = false, rageraze = false, inMnemosyne = true, battlerage = {} }
ataxiaTemp = {}
gmcp = { Char = { Status = { class = "Serpent" } }, Room = { Info = { num = 50 } } }
function ataxiaEcho() end
function ataxiaBasher_assembleBattlerage() return "BRAGE;" end

local ok, err = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/basher/002_Class_Bashing.lua")
if not ok then error("Failed to load class-bashing file: " .. tostring(err)) end
function ataxiaBasher_assembleBattlerage() return "BRAGE;" end

local clock = 800000
getEpoch = function() return clock end

local function has(cmd, needle) return cmd:find(needle, 1, true) ~= nil end

local OFFSETS = { north = {0,1}, south = {0,-1}, east = {1,0}, west = {-1,0},
                  northeast = {1,1}, northwest = {-1,1}, southeast = {1,-1}, southwest = {-1,-1} }
local SHORT = { north = "n", south = "s", east = "e", west = "w", northeast = "ne",
                northwest = "nw", southeast = "se", southwest = "sw", up = "u", down = "d" }
local NORM = { n = "north", s = "south", e = "east", w = "west", ne = "northeast", nw = "northwest",
               se = "southeast", sw = "southwest", u = "up", d = "down" }
for k in pairs(SHORT) do NORM[k] = k end

local function reset(opts)
  opts = opts or {}
  clock = 800000
  target = 7
  ataxiaTemp = {}
  ataxia.vitals.mp = opts.mp or 3000
  ataxiaBasher.shielded = false
  ataxiaBasher.inMnemosyne = true
  mnemSearingLight = (opts.boon ~= false)
  local exits = opts.exits or { west = 0, north = 0, down = 0 }
  ataxia.mnemosyne = {
    _denizenCount = function() return opts.denizens or 2 end,
    map = {
      _ripple = opts.ripple or 3,
      current = opts.room or 50,
      rooms = { [opts.room or 50] = { exits = exits } },
      OFFSETS = OFFSETS,
      normDir = function(d) return NORM[d] end,
      shortDir = function(d) return SHORT[NORM[d] or d] or d end,
    },
  }
end

describe("Searing Light -- CONJURE LIGHTWALL first, whatever the room holds", function()
  it("is inert without the boon", function()
    reset({ boon = false })
    local cmd = ataxiaBasher_serpentBashing()
    expect(has(cmd, "conjure lightwall")).toBeFalse()
    expect(has(cmd, "garrote 7")).toBeTrue()
  end)

  it("prepends the conjure FIRST, on the first planar exit sorted, and the garrote still swings", function()
    reset({ exits = { west = 0, north = 0, down = 0 } })
    local cmd = ataxiaBasher_serpentBashing()
    expect(cmd:sub(1, #"conjure lightwall n;")).toBe("conjure lightwall n;")  -- north sorts before west; down is not planar
    expect(has(cmd, "garrote 7")).toBeTrue()
    expect(has(cmd, "BRAGE;")).toBeTrue()
  end)

  -- "regardless of denizen as it does fire damage one time" (user, v4.7.309): the count is
  -- never read -- one mob, fifty, or a lagging zero.
  it("fires alone, in a crowd, and on a lagging count of zero", function()
    reset({ denizens = 1 })
    expect(has(ataxiaBasher_serpentBashing(), "conjure lightwall n;")).toBeTrue()
    reset({ denizens = 50 })
    expect(has(ataxiaBasher_serpentBashing(), "conjure lightwall n;")).toBeTrue()
    reset({ denizens = 0 })
    expect(has(ataxiaBasher_serpentBashing(), "conjure lightwall n;")).toBeTrue()
  end)

  it("needs a denizen target, the tower, and a mana pool worth spending", function()
    reset(); target = "Grulk"
    expect(has(ataxiaBasher_serpentBashing(), "conjure lightwall")).toBeFalse()
    reset(); ataxiaBasher.inMnemosyne = false
    expect(has(ataxiaBasher_serpentBashing(), "conjure lightwall")).toBeFalse()
    reset({ mp = 200 })
    expect(has(ataxiaBasher_serpentBashing(), "conjure lightwall")).toBeFalse()
    expect(ataxiaTemp.lightwallAt).toBeNil() -- a refused gate stamps nothing
  end)

  it("replays verbatim across the re-queue loop, then is done with the room", function()
    reset()
    expect(has(ataxiaBasher_serpentBashing(), "conjure lightwall n;")).toBeTrue()
    clock = clock + 2
    expect(has(ataxiaBasher_serpentBashing(), "conjure lightwall n;")).toBeTrue()
    clock = clock + 5 -- past the hold
    local cmd = ataxiaBasher_serpentBashing()
    expect(has(cmd, "conjure lightwall")).toBeFalse()
    expect(has(cmd, "garrote 7")).toBeTrue()
    expect(ataxiaTemp.lightwallRooms[50]).toBeTrue()
  end)

  -- "only do the lightwall attack one time per room" (user, v4.7.310): no re-arm, however long
  -- we stay, and no second wall on walking back into the room later in the ripple.
  it("never conjures a second wall in the same room, however long we stay", function()
    reset()
    ataxiaBasher_serpentBashing()
    clock = clock + 600
    expect(has(ataxiaBasher_serpentBashing(), "conjure lightwall")).toBeFalse()
  end)

  it("a new room is a new wall, and coming BACK to the first room is not", function()
    reset()
    ataxiaBasher_serpentBashing()
    clock = clock + 10
    ataxia.mnemosyne.map.current = 51
    ataxia.mnemosyne.map.rooms[51] = { exits = { east = 0 } }
    expect(has(ataxiaBasher_serpentBashing(), "conjure lightwall e;")).toBeTrue()
    clock = clock + 10
    ataxia.mnemosyne.map.current = 50 -- patrolled back into the first room
    expect(has(ataxiaBasher_serpentBashing(), "conjure lightwall")).toBeFalse()
  end)

  it("a new ripple forgets the rooms (keyed on the MAP's ripple, telemetry-independent)", function()
    reset()
    ataxiaBasher_serpentBashing()
    clock = clock + 10
    expect(has(ataxiaBasher_serpentBashing(), "conjure lightwall")).toBeFalse()
    ataxia.mnemosyne.map._ripple = 4
    expect(has(ataxiaBasher_serpentBashing(), "conjure lightwall n;")).toBeTrue()
  end)

  -- "There is already a lightwall in that direction." -- that exit is spent, try the next one.
  it("a refused direction rotates to the next exit, and a room with none left conjures nothing", function()
    reset({ exits = { west = 0, north = 0 } })
    expect(has(ataxiaBasher_serpentBashing(), "conjure lightwall n;")).toBeTrue()
    ataxiaBasher_lightwallRefused()
    expect(ataxiaTemp.lightwallRooms[50]).toBeNil() -- a refused conjure did not do the room
    expect(has(ataxiaBasher_serpentBashing(), "conjure lightwall w;")).toBeTrue()
    ataxiaBasher_lightwallRefused()
    local cmd = ataxiaBasher_serpentBashing()
    expect(has(cmd, "conjure lightwall")).toBeFalse()
    expect(has(cmd, "garrote 7")).toBeTrue()
  end)

  it("conjures nothing when the room's exits are unknown", function()
    reset({ exits = {} })
    expect(has(ataxiaBasher_serpentBashing(), "conjure lightwall")).toBeFalse()
  end)

  it("still fires on a shielded round -- the wall is room-wide, not a strike on the shield -- and STILL first", function()
    reset(); ataxiaBasher.shielded = true
    local cmd = ataxiaBasher_serpentBashing()
    expect(cmd:sub(1, #"conjure lightwall n;")).toBe("conjure lightwall n;") -- ahead of the flay, per the user
    expect(has(cmd, "flay 7 shield")).toBeTrue()
  end)
end)

-- Both lines captured live: the conjure releases the replay and restamps the room from the
-- landed moment; the detonation is the boon's own and re-latches the flag.
describe("Searing Light -- the landed lines", function()
  it("the conjure line releases the replay; the room stays done", function()
    reset()
    expect(has(ataxiaBasher_serpentBashing(), "conjure lightwall n;")).toBeTrue()
    clock = clock + 2
    ataxiaBasher_searingLightConfirm(false)
    expect(ataxiaTemp.lightwallPendingAt).toBeNil()
    expect(has(ataxiaBasher_serpentBashing(), "conjure lightwall")).toBeFalse() -- no longer replaying
    expect(ataxiaTemp.lightwallRooms[50]).toBeTrue()
  end)

  it("the detonation line is self-proving and re-latches the flag; the plain conjure is not", function()
    reset({ boon = false })
    ataxiaBasher_searingLightConfirm(false)
    expect(mnemSearingLight).toBeFalse()
    ataxiaBasher_searingLightConfirm(true)
    expect(mnemSearingLight).toBeTrue()
  end)

  it("a landing with nothing in flight marks nothing (a wall we did not conjure)", function()
    reset()
    ataxiaBasher_searingLightConfirm(false)
    expect(next(ataxiaTemp.lightwallRooms or {})).toBeNil()
  end)
end)

-- Restore shared state for whoever runs after us.
target, ataxia, ataxiaBasher, ataxiaTemp, gmcp = saved.target, saved.ataxia, saved.ataxiaBasher, saved.ataxiaTemp, saved.gmcp
getEpoch, mnemSearingLight, ataxiaEcho = saved.getEpoch, saved.mnemSearingLight, saved.ataxiaEcho
ataxiaBasher_assembleBattlerage = saved.ataxiaBasher_assembleBattlerage
