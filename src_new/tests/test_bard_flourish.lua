--- test_bard_flourish.lua -- Deadly Flourish: BLADE FLOURISH every 15s as the Bard's balance swing
--
-- Boon (captured 2026-09-14): "Your bladedance flourish ability now deals additional cutting
-- damage to all denizens in your location when used on a denizen. This can only occur once every
-- 15 seconds." User: "if we have this boon, we should use flourish every 15 seconds."
--
-- AB Flourish: `BLADE FLOURISH <target>`, 2.10s of BALANCE, adventurers-only, no damage, and it
-- ADVANCES TWO DANCE POSITIONS (front->back, side->front, back->side). Balance means it REPLACES
-- the flick; adventurers-only means the boon is the denizen permit; two positions means the
-- moment matters for footwork -- side->front is the one bad case, and it is refused while the
-- position is readable, bounded so a stale flag cannot lock the boon out.
--
-- Loads the real basher/002_Class_Bashing.lua. Files share ONE Lua state: every global touched
-- here is saved at the top and restored at the bottom, never blanked.

require("mock_mudlet")

local saved = {
  target = target, ataxia = ataxia, ataxiaBasher = ataxiaBasher, ataxiaTemp = ataxiaTemp,
  gmcp = gmcp, bardtempo = bardtempo, mnemDeadlyFlourish = mnemDeadlyFlourish,
  mnemSongstep = mnemSongstep, bardWarmarch = bardWarmarch, getEpoch = getEpoch,
  ataxiaEcho = ataxiaEcho, ataxiaBasher_assembleBattlerage = ataxiaBasher_assembleBattlerage,
}

target = 7
ataxia = { settings = { separator = ";" }, vitals = { rage = 0 }, defences = {},
           bardStuff = { bashPunctuate = false } }
ataxiaBasher = { shielded = false, rageraze = false, battlerage = {} }
ataxiaTemp = {}
gmcp = { Char = { Status = { class = "Bard" } } }
function ataxiaEcho() end
-- The Bard round runs the shared battlerage assembler; stub it to a sentinel so we can assert
-- that the rage rider still rides a flourish round (the same shape test_bm_infuse.lua uses).
function ataxiaBasher_assembleBattlerage() return "BRAGE;" end

local ok, err = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/basher/002_Class_Bashing.lua")
if not ok then error("Failed to load class-bashing file: " .. tostring(err)) end
function ataxiaBasher_assembleBattlerage() return "BRAGE;" end -- re-assert after the load

local clock = 500000
getEpoch = function() return clock end

local function has(cmd, needle) return cmd:find(needle, 1, true) ~= nil end

local function reset(opts)
  opts = opts or {}
  clock = 500000
  target = 7
  ataxiaTemp = {}
  ataxia.defences = {}
  ataxia.bardStuff = { bashPunctuate = false }
  ataxia.mnemosyne = { _denizenCount = function() return opts.denizens or 1 end }
  ataxiaBasher.shielded = false
  bardtempo = opts.tempo -- nil = position unreadable
  bardWarmarch = false
  mnemSongstep = false
  mnemDeadlyFlourish = (opts.boon ~= false)
end

describe("Deadly Flourish -- BLADE FLOURISH as the Bard's balance swing", function()
  it("is completely inert without the boon", function()
    reset({ boon = false })
    local cmd = ataxiaBasher_bardBashing()
    expect(has(cmd, "blade flourish")).toBeFalse()
    expect(has(cmd, "blade flick 7 nomos")).toBeTrue()
    expect(ataxiaTemp.bardFlourishAt).toBeNil() -- no stamp burned on a refused gate
  end)

  it("REPLACES the flick with blade flourish <target> when the boon is held and the clock is up", function()
    reset()
    local cmd = ataxiaBasher_bardBashing()
    expect(has(cmd, "wield right rapier;wield left shield;blade flourish 7")).toBeTrue()
    expect(has(cmd, "blade flick")).toBeFalse()   -- balance: one swing per round, and this is it
    expect(has(cmd, "BRAGE;")).toBeTrue()         -- the rage rider still rides
    expect(ataxiaTemp.bardFlourishAt).toBe(500000)
  end)

  -- Every 0.3s the basher rebuilds the round with queue addclearfull, and only the LAST line
  -- queued before balance executes. A pick that stamped on every rebuild would see its own
  -- cooldown on the next one and flip the queued line back to a flick before the flourish ever
  -- went out (the phantom-stamp trap the owned rotations solved with an in-flight hold).
  it("replays the same flourish verbatim across the re-queue loop without restamping", function()
    reset()
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
    clock = clock + 1
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
    clock = clock + 2
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
    expect(ataxiaTemp.bardFlourishAt).toBe(500000) -- one stamp, not three
  end)

  it("holds for the boon's 15s after the in-flight window, then fires again", function()
    reset()
    ataxiaBasher_bardBashing()
    clock = clock + 6  -- past the replay hold, inside the 15s
    local cmd = ataxiaBasher_bardBashing()
    expect(has(cmd, "blade flourish")).toBeFalse()
    expect(has(cmd, "blade flick 7 nomos")).toBeTrue()
    clock = clock + 8  -- 14s: still held
    expect(has(ataxiaBasher_bardBashing(), "blade flourish")).toBeFalse()
    clock = clock + 2  -- 16s
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
  end)

  -- AB Flourish "Works against: Adventurers" -- the BOON is what permits a denizen. Against a
  -- player it is a harmless repositioning move that costs a balance, and the basher has no
  -- business spending one.
  it("is PvE only -- never fires at a named player target", function()
    reset(); target = "Grulk"
    local cmd = ataxiaBasher_bardBashing()
    expect(has(cmd, "blade flourish")).toBeFalse()
    expect(ataxiaTemp.bardFlourishAt).toBeNil()
  end)

  it("skips a shielded round so the punctuate breaks the shield first", function()
    reset(); ataxiaBasher.shielded = true
    local cmd = ataxiaBasher_bardBashing()
    expect(has(cmd, "blade punctuate 7 paean")).toBeTrue()
    expect(has(cmd, "blade flourish")).toBeFalse()
    expect(ataxiaTemp.bardFlourishAt).toBeNil()
  end)

  -- Both are BALANCE, so only one can happen in a round. The dance is the rarer window and a
  -- state we then hold for a whole fight; it wins, and the flourish helper is not even CALLED
  -- for that round, so it cannot stamp a cooldown for a round it did not get.
  it("yields the round to a Songstep dance switch without burning its stamp", function()
    reset({ denizens = 2 })
    mnemSongstep = true -- 2 denizens -> hawkstep wanted, and it is not up
    local cmd = ataxiaBasher_bardBashing()
    expect(has(cmd, "dance hawkstep")).toBeTrue()
    expect(has(cmd, "blade flourish")).toBeFalse()
    expect(ataxiaTemp.bardFlourishAt).toBeNil()
    ataxia.defences.hawkstep = true -- already dancing it: the swing is ours again
    clock = clock + 1
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
  end)
end)

-- Flourish advances TWO positions: front->back (the whole point of the footwork game), back->side
-- (lands two hits from back again), side->front (two hits from back becomes five). The only loss
-- is from SIDE, so that is the only position the pick refuses -- and only while it is readable.
describe("Deadly Flourish -- footwork: never from the side position while readable", function()
  it("fires from the front (straight to the back-position bonus)", function()
    reset({ tempo = "front" })
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
  end)

  it("fires from the back", function()
    reset({ tempo = "back" })
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
  end)

  it("holds at the side, then fires the moment the dance carries us on", function()
    reset({ tempo = "side" })
    local cmd = ataxiaBasher_bardBashing()
    expect(has(cmd, "blade flourish")).toBeFalse()
    expect(has(cmd, "blade flick 7 nomos")).toBeTrue() -- the round still swings
    expect(ataxiaTemp.bardFlourishAt).toBeNil()          -- a hold is not a spend
    clock = clock + 2
    bardtempo = "back" -- "carries you with lethal promise to the blindspot"
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
    expect(ataxiaTemp.bardFlourishSideSince).toBeNil()   -- the hold is released on firing
  end)

  -- A hold released only by a game line becomes a livelock the moment that line stops arriving
  -- (a flourish's own two-step jump may not print the position line we track). The dance leaves
  -- side within four hits at most, so a "side" that lasts longer than the cap is a stale flag.
  it("the side hold is bounded -- a stale position cannot lock the boon out", function()
    reset({ tempo = "side" })
    expect(has(ataxiaBasher_bardBashing(), "blade flourish")).toBeFalse()
    clock = clock + 9
    expect(has(ataxiaBasher_bardBashing(), "blade flourish")).toBeFalse() -- still inside the cap
    clock = clock + 2 -- 11s at "side": past FLOURISH_SIDE_HOLD_MAX
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
  end)

  it("fires when the position is unreadable -- the user's rule is every 15 seconds", function()
    reset({ tempo = nil })
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
    reset({ tempo = false }) -- login sets bardtempo = false
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
  end)
end)

-- "Regardless of the denizens in the room, 1 or 50" (user, 2026-09-14). The count is never read.
describe("Deadly Flourish -- the denizen count is irrelevant", function()
  it("fires alone with one denizen", function()
    reset({ denizens = 1 })
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
  end)

  it("fires in a crowd of fifty", function()
    reset({ denizens = 50 })
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
  end)

  it("fires on a lagging count of zero -- the count is not consulted at all", function()
    reset({ denizens = 0 })
    ataxia.mnemosyne = nil -- not even a Mnemosyne module to ask
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
  end)

  it("has no floor knob to consult (v4.7.301's hedge is gone)", function()
    reset({ denizens = 1 })
    ataxiaBasher.bardFlourishAt = 50 -- a stale config value from v4.7.301 must change nothing
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
    ataxiaBasher.bardFlourishAt = nil
  end)
end)

-- Restore shared state for whoever runs after us (files share one Lua state).
target = saved.target
ataxia = saved.ataxia
ataxiaBasher = saved.ataxiaBasher
ataxiaTemp = saved.ataxiaTemp
gmcp = saved.gmcp
bardtempo = saved.bardtempo
mnemDeadlyFlourish = saved.mnemDeadlyFlourish
mnemSongstep = saved.mnemSongstep
bardWarmarch = saved.bardWarmarch
getEpoch = saved.getEpoch
ataxiaEcho = saved.ataxiaEcho
ataxiaBasher_assembleBattlerage = saved.ataxiaBasher_assembleBattlerage
