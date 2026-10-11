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
  mnemAssassinsBlade = mnemAssassinsBlade,
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

-- v4.7.381, user: "we should use venom instead of garrote with these boons" -- "secrete camus;bite
-- target". Serpent's Maw (unblockable +50% venom damage on denizens) and Toxicologist (venoms relapse).
describe("Serpent venom boons: bite with camus instead of garrote", function()
  local function bash(opts)
    reset({ boon = false })
    mnemSerpentsMaw, mnemToxicologist = opts.maw, opts.tox
    ataxiaBasher.shielded = opts.shielded or false
    local cmd = ataxiaBasher_serpentBashing()
    mnemSerpentsMaw, mnemToxicologist = nil, nil
    return cmd
  end

  it("without either boon: garrote, as before", function()
    local cmd = bash({})
    expect(has(cmd, "garrote 7")).toBeTrue()
    expect(has(cmd, "bite")).toBeFalse()
  end)

  -- v4.7.383, user: "It should be purge;secrete camus;bite target"
  it("with Serpent's Maw: purge, secrete camus, then bite", function()
    local cmd = bash({ maw = true })
    expect(has(cmd, "purge;secrete camus;bite 7")).toBeTrue()
    expect(has(cmd, "garrote")).toBeFalse()
  end)

  it("with Toxicologist: the same", function()
    expect(has(bash({ tox = true }), "purge;secrete camus;bite 7")).toBeTrue()
  end)

  it("a shielded round still flays the shield, and bites nothing", function()
    local cmd = bash({ maw = true, shielded = true })
    expect(has(cmd, "flay 7 shield")).toBeTrue()
    expect(has(cmd, "bite")).toBeFalse()
    expect(has(cmd, "purge")).toBeFalse()
  end)

  it("the boons are wired: flags, claim alias, catalogue", function()
    local function slurp(p) local f = io.open(p); local s = f:read("*a"); f:close(); return s end
    local parsers = slurp("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/004_Parsers.lua")
    expect(parsers:find('["Serpent\'s Maw"]        = "mnemSerpentsMaw"', 1, true) ~= nil).toBeTrue()
    expect(parsers:find('["Toxicologist"]         = "mnemToxicologist"', 1, true) ~= nil).toBeTrue()
    local claim = slurp("src_new/aliases/levi_ataxia/for_levi/levi_062424/mnemosyne/002_Boon_Claim.lua")
    expect(claim:find('find("serpent\'s maw", 1, true) then mnemSerpentsMaw = true', 1, true) ~= nil).toBeTrue()
    expect(slurp("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/010_Boon_Seed.lua")
      :find("Your venoms now deal unblockable damage against denizens", 1, true) ~= nil).toBeTrue()
  end)
end)

-- v4.7.384, user: "Highlight this attack as our attack (orange or something bright)"
describe("our venom bite is highlighted", function()
  local TL = dofile("src_new/tests/trigger_lib.lua")
  local P = TL.patterns("src_new/triggers/levi_ataxia/for_levi/leviticus/highlighting/068_Camus_Bite_Highlight.lua")
  local LINE = "You sink your fangs into a greater earth elemental, injecting just the proper amount of camus."

  it("the line as pasted, and every row of it however the server wraps", function()
    expect(TL.anyMatches(P, LINE)).toBeTrue()
    for w = 119, 124 do                      -- the server wraps at 119-124
      for _, row in ipairs(TL.wrap(LINE, w)) do expect(TL.anyMatches(P, row)).toBeTrue() end
    end
    local long = "You sink your fangs into an enormous, ancient and terribly well-armoured guardian of the deep wastes, injecting just the proper amount of camus."
    for w = 119, 124 do
      for _, row in ipairs(TL.wrap(long, w)) do expect(TL.anyMatches(P, row)).toBeTrue() end
    end
  end)

  it("not someone else's line", function()
    expect(TL.anyMatches(P, "A death adder sinks its fangs into you.")).toBeFalse()
    expect(TL.anyMatches(P, "You sink into the mud.")).toBeFalse()
  end)

  it("bright, bold, and not the reserved orange family", function()
    local f = io.open("src_new/triggers/levi_ataxia/for_levi/leviticus/highlighting/068_Camus_Bite_Highlight.lua")
    local s = f:read("*a"); f:close()
    expect(s:find('fg("chartreuse")', 1, true) ~= nil).toBeTrue()
    expect(s:find("setBold(true)", 1, true) ~= nil).toBeTrue()
  end)
end)

-- v4.7.384, user: "Also this, is the relapse ... from that toxic boon"
describe("Toxicologist's relapse line", function()
  local TL = dofile("src_new/tests/trigger_lib.lua")
  local F = "src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/108_Toxicologist_Relapse.lua"
  local P = TL.patterns(F)
  local LINE = "An enormous two-headed ettin screams out in agony, struck by the effects of a vicious venom."

  it("matches as pasted, and every row however a long name wraps it", function()
    expect(TL.anyMatches(P, LINE)).toBeTrue()
    local long = "An immense, ancient and thoroughly bad-tempered two-headed ettin of the eastern wastes screams out in agony, struck by the effects of a vicious venom."
    for w = 119, 124 do
      for _, row in ipairs(TL.wrap(long, w)) do expect(TL.anyMatches(P, row)).toBeTrue() end
    end
  end)

  it("re-latches Toxicologist -- in the tower only", function()
    local stubs = { selectString = selectString, fg = fg, setBold = setBold, deselect = deselect,
                    resetFormat = resetFormat }
    selectString, fg, setBold, deselect, resetFormat = function() return 1 end, function() end,
      function() end, function() end, function() end
    line = LINE
    local ok, err = pcall(function()
      mnemToxicologist = nil
      ataxiaBasher.inMnemosyne = false
      dofile(F)
      expect(mnemToxicologist).toBeNil()
      ataxiaBasher.inMnemosyne = true
      dofile(F)
      expect(mnemToxicologist).toBeTrue()
    end)
    selectString, fg, setBold, deselect, resetFormat = stubs.selectString, stubs.fg, stubs.setBold,
      stubs.deselect, stubs.resetFormat
    mnemToxicologist, line = nil, nil
    if not ok then error(err, 0) end
  end)
end)

-- v4.7.392, user: "You scream out in agony as a vicious venom tears through your body." --
-- "We need to purge in this instance"
describe("a venom tearing through us sends PURGE", function()
  local TL = dofile("src_new/tests/trigger_lib.lua")
  local F = "src_new/triggers/levi_ataxia/for_levi/leviticus/serpent/019_Venom_Agony_Purge.lua"
  local P = TL.patterns(F)
  local LINE = "You scream out in agony as a vicious venom tears through your body."

  local function fire()
    local sent = {}
    local realSend = send
    send = function(c) sent[#sent + 1] = c end
    local ok, err = pcall(dofile, F)
    send = realSend
    if not ok then error(err, 0) end
    return sent
  end

  it("matches the line, with or without its full stop, and not a denizen's", function()
    expect(TL.anyMatches(P, LINE)).toBeTrue()
    expect(TL.anyMatches(P, LINE:sub(1, -2))).toBeTrue()
    expect(TL.anyMatches(P, "An enormous two-headed ettin screams out in agony, struck by the effects of a vicious venom.")).toBeFalse()
  end)

  it("purges, once per burst", function()
    ataxiaTemp = {}
    clock = 800000
    local first = fire()
    expect(#first).toBe(1)
    expect(first[1]).toBe("purge")
    clock = clock + 1
    expect(#fire()).toBe(0) -- the next tick of the same venom
    clock = clock + 1
    expect(fire()[1]).toBe("purge") -- 2s later it purges again
  end)
end)

-- v4.7.393, user: Assassin's Blade ("When hidden from sight, your backstab will resolve instantly")
-- with Darkwalker ("Defeating a denizen will render you hidden") -- "it should always open with backstab".
describe("Assassin's Blade: open with BACKSTAB while hidden", function()
  local function bash(opts)
    reset({ boon = opts.lightwall or false })
    mnemAssassinsBlade = (opts.blade ~= false)
    mnemSerpentsMaw = opts.maw
    ataxia.defences = { hiding = (opts.hidden ~= false) or nil }
    ataxiaBasher.shielded = opts.shielded or false
    local cmd = ataxiaBasher_serpentBashing()
    mnemAssassinsBlade, mnemSerpentsMaw = nil, nil
    ataxia.defences = {}
    return cmd
  end

  it("hidden: backstab FIRST, the battlerage after it, no garrote", function()
    local cmd = bash({})
    expect(cmd).toBe("wield shield dirk;backstab 7;BRAGE")
  end)

  it("hidden with Searing Light: backstab first, then the lightwall", function()
    local cmd = bash({ lightwall = true })
    expect(cmd:sub(1, #"wield shield dirk;backstab 7;conjure lightwall")).toBe("wield shield dirk;backstab 7;conjure lightwall")
  end)

  it("no bare trailing separator when nothing follows the backstab", function()
    local real = ataxiaBasher_assembleBattlerage
    ataxiaBasher_assembleBattlerage = function() return "" end
    local cmd = bash({})
    ataxiaBasher_assembleBattlerage = real
    expect(cmd).toBe("wield shield dirk;backstab 7")
  end)

  it("hidden beats the venom bite too", function()
    local cmd = bash({ maw = true })
    expect(has(cmd, "backstab 7")).toBeTrue()
    expect(has(cmd, "bite")).toBeFalse()
  end)

  it("not hidden: the normal swing", function()
    local cmd = bash({ hidden = false })
    expect(has(cmd, "backstab")).toBeFalse()
    expect(has(cmd, "garrote 7")).toBeTrue()
  end)

  it("without the boon a backstab channels, so it is not used", function()
    local cmd = bash({ blade = false })
    expect(has(cmd, "backstab")).toBeFalse()
    expect(has(cmd, "garrote 7")).toBeTrue()
  end)

  it("a shielded target is flayed first", function()
    local cmd = bash({ shielded = true })
    expect(has(cmd, "backstab")).toBeFalse()
    expect(has(cmd, "flay 7 shield")).toBeTrue()
  end)

  -- v4.7.408, user: "You swiftly return to concealment in the wake of your triumph." -- "this rehides us also".
  it("Darkwalker's line counts as hidden before GMCP says so", function()
    reset({})
    ataxiaBasher_serpentConcealed()
    mnemAssassinsBlade = true
    ataxia.defences = {}
    local cmd = ataxiaBasher_serpentBashing()
    expect(cmd:sub(1, #"wield shield dirk;backstab 7")).toBe("wield shield dirk;backstab 7")
    clock = clock + 4 -- the window has passed with no GMCP hiding: back to the normal swing
    expect(has(ataxiaBasher_serpentBashing(), "backstab")).toBeFalse()
    mnemAssassinsBlade = nil
  end)

  it("trigger serpent/020 matches the rehide line and the already-hidden refusal", function()
    local f = io.open("src_new/triggers/levi_ataxia/for_levi/leviticus/serpent/020_Darkwalker_Concealed.lua")
    local src = f:read("*a"); f:close()
    expect(src:find("pattern: You swiftly return to concealment in the wake of your triumph", 1, true) ~= nil).toBeTrue()
    expect(src:find("pattern: You are already hidden", 1, true) ~= nil).toBeTrue()
    expect(src:find("pattern: You conceal yourself using all the guile you possess", 1, true) ~= nil).toBeTrue()
  end)

  it("a GMCP Remove of hiding cancels the concealment at once", function()
    reset({})
    ataxiaBasher_serpentConcealed()
    expect(ataxiaBasher_serpentHidden()).toBeTrue()
    gmcp.Char = gmcp.Char or {}
    gmcp.Char.Defences = { Remove = { "hiding" } }
    local ok, err = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/deffing/001_Defence_API.lua")
    expect(ok).toBeTrue()
    ataxiaBasher.enabled = true -- quiet the echo
    lostDef()
    ataxiaBasher.enabled = nil
    expect(ataxiaBasher_serpentHidden()).toBeFalse()
  end)

  it("the boon is wired: flag, claim alias, run start", function()
    local function slurp(p) local f = io.open(p); local s = f:read("*a"); f:close(); return s end
    expect(slurp("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/004_Parsers.lua")
      :find([==[["Assassin's Blade"]     = "mnemAssassinsBlade"]==], 1, true) ~= nil).toBeTrue()
    expect(slurp("src_new/aliases/levi_ataxia/for_levi/levi_062424/mnemosyne/002_Boon_Claim.lua")
      :find([[find("assassin's blade", 1, true) then mnemAssassinsBlade = true]], 1, true) ~= nil).toBeTrue()
    expect(slurp("src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/001_Run_Start.lua")
      :find("mnemAssassinsBlade = false", 1, true) ~= nil).toBeTrue()
  end)
end)

-- Restore shared state for whoever runs after us.
target, ataxia, ataxiaBasher, ataxiaTemp, gmcp = saved.target, saved.ataxia, saved.ataxiaBasher, saved.ataxiaTemp, saved.gmcp
getEpoch, mnemSearingLight, ataxiaEcho = saved.getEpoch, saved.mnemSearingLight, saved.ataxiaEcho
mnemAssassinsBlade = saved.mnemAssassinsBlade
ataxiaBasher_assembleBattlerage = saved.ataxiaBasher_assembleBattlerage
