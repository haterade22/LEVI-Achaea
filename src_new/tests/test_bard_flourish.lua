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
  bardtempostance = bardtempostance, mnemShadowTempo = mnemShadowTempo,
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
  ataxia.bardStuff = { bashPunctuate = false, footworkFlourish = false }
  ataxia.mnemosyne = { _denizenCount = function() return opts.denizens or 2 end }
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

-- FOOTWORK FLOURISH (v4.7.311): the boon-free policy from the tempo analysis. Front -> back at
-- every return to front, on the tempos where the maths says the lost balance pays, read from the
-- GAME's tempo line so an unlearned Tempo (no line, stance "none") keeps it off.
describe("footwork flourish -- flourish at every return to front, boon or no boon", function()
  local savedStance = bardtempostance
  local function fw(opts)
    reset({ boon = false, tempo = (opts.pos == nil) and "front" or opts.pos })
    ataxia.bardStuff.footworkFlourish = (opts.on ~= false)
    bardtempostance = opts.stance
    mnemShadowTempo = opts.shadow or false
  end

  it("fires on Vivace from the front with no boon at all, and again at the next front", function()
    fw({ stance = "Vivace" })
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
    clock = clock + 5 -- replay hold over; the boon's 15s would still be running
    bardtempo = "back"                                  -- landed at the back
    expect(has(ataxiaBasher_bardBashing(), "blade flourish")).toBeFalse()
    clock = clock + 11                                  -- 16s: five back hits later...
    bardtempo = "front"                                 -- ...the dance carried us to front
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
  end)

  -- THE LIVE LOG (2026-09-16): position tracking could not read a multi-word denizen, so
  -- "front" never changed and the policy flourished on every balance. The trigger is fixed; this
  -- pins the latch that makes such a fault cost ONE balance instead of every balance.
  it("flourishes ONCE per visit to the front, even if the position never appears to change", function()
    fw({ stance = "Vivace" })
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
    clock = clock + 5 -- replay over; bardtempo still reads "front"
    expect(has(ataxiaBasher_bardBashing(), "blade flourish")).toBeFalse()
    clock = clock + 5
    expect(has(ataxiaBasher_bardBashing(), "blade flourish")).toBeFalse()
    bardtempo = "back"; ataxiaBasher_bardBashing() -- seen to leave the front...
    clock = clock + 5
    bardtempo = "front"                            -- ...and come back: a fresh visit
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
  end)

  it("has no 15s clock of its own -- the dance is the clock", function()
    fw({ stance = "Vivace" })
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
    clock = clock + 5
    bardtempo = "back"; ataxiaBasher_bardBashing() -- left the front (a real visit ends)...
    bardtempo = "front"                            -- ...and back again inside the boon's 15s
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
  end)

  it("only from the front -- at the side or the back it is the boon's business", function()
    fw({ stance = "Vivace", pos = "side" })
    expect(has(ataxiaBasher_bardBashing(), "blade flourish")).toBeFalse()
    fw({ stance = "Vivace", pos = "back" })
    expect(has(ataxiaBasher_bardBashing(), "blade flourish")).toBeFalse()
    fw({ stance = "Vivace", pos = false }) -- position unreadable: the policy needs the front
    expect(has(ataxiaBasher_bardBashing(), "blade flourish")).toBeFalse()
  end)

  it("Adagio and Moderato pay only with Shadow Tempo; Allegro and no tempo never", function()
    fw({ stance = "Moderato" })
    expect(has(ataxiaBasher_bardBashing(), "blade flourish")).toBeFalse()
    fw({ stance = "Moderato", shadow = true })
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
    fw({ stance = "Adagio", shadow = true })
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
    fw({ stance = "Allegro", shadow = true })
    expect(has(ataxiaBasher_bardBashing(), "blade flourish")).toBeFalse()
    fw({ stance = "none", shadow = true })
    expect(has(ataxiaBasher_bardBashing(), "blade flourish")).toBeFalse()
  end)

  it("reads the GAME's tempo line, never config -- an unlearned Tempo keeps it off", function()
    fw({ stance = nil })
    ataxia.bardStuff.bashTempo = "vivace" -- what we ASKED for; the game never confirmed it
    expect(has(ataxiaBasher_bardBashing(), "blade flourish")).toBeFalse()
  end)

  it("is switchable off, and off means off", function()
    fw({ stance = "Vivace", on = false })
    expect(has(ataxiaBasher_bardBashing(), "blade flourish")).toBeFalse()
    expect(ataxiaBasher_bardFootworkFlourishPays()).toBeFalse()
    ataxia.bardStuff.footworkFlourish = true
    expect(ataxiaBasher_bardFootworkFlourishPays()).toBeTrue()
  end)

  -- "We should flourish from the front to get to the back" (user, v4.7.312): `always` drops the
  -- tempo rule -- every return to front, whatever the tempo, even one the game never confirmed.
  it("ALWAYS fires from the front on any tempo, including none", function()
    fw({ stance = "Allegro" }); ataxia.bardStuff.footworkFlourish = "always"
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
    fw({ stance = nil }); ataxia.bardStuff.footworkFlourish = "always"
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
    fw({ stance = nil, pos = "side" }); ataxia.bardStuff.footworkFlourish = "always"
    expect(has(ataxiaBasher_bardBashing(), "blade flourish")).toBeFalse() -- still front only
  end)

  it("leaves the boon path exactly as it was when the policy is off", function()
    fw({ stance = "Vivace", on = false })
    mnemDeadlyFlourish = true
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
    clock = clock + 6
    bardtempo = "front"
    expect(has(ataxiaBasher_bardBashing(), "blade flourish")).toBeFalse() -- the boon's 15s holds
  end)

  bardtempostance = savedStance
  mnemShadowTempo = false
end)

-- The landed line (highlighting/062) restarts the 15s from the moment the flourish actually
-- executed -- a balance after the pick's send stamp -- and releases the in-flight replay.
describe("Deadly Flourish -- the landed line restarts the clock and releases the replay", function()
  it("re-stamps the 15s from the landed moment", function()
    reset()
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue() -- send stamp at 500000
    clock = clock + 3
    ataxiaBasher_bardFlourishConfirm()                                     -- landed at 500003
    expect(ataxiaTemp.bardFlourishAt).toBe(500003)
    expect(ataxiaTemp.bardFlourishPendingAt).toBeNil()                    -- replay released
    clock = clock + 13 -- 16s after the SEND, 13s after the landing: still held
    expect(has(ataxiaBasher_bardBashing(), "blade flourish")).toBeFalse()
    clock = clock + 3  -- 16s after the landing
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
  end)

  it("a released replay stops re-sending inside what would have been the hold", function()
    reset()
    ataxiaBasher_bardBashing()
    clock = clock + 1
    ataxiaBasher_bardFlourishConfirm()
    clock = clock + 1 -- 2s after the send: the 4s replay hold would still be open
    local cmd = ataxiaBasher_bardBashing()
    expect(has(cmd, "blade flourish")).toBeFalse()
    expect(has(cmd, "blade flick 7 nomos")).toBeTrue()
  end)

  it("does not latch the boon flag -- the base ability prints the same line", function()
    reset({ boon = false })
    ataxiaBasher_bardFlourishConfirm()
    expect(mnemDeadlyFlourish).toBeFalse()
    expect(has(ataxiaBasher_bardBashing(), "blade flourish")).toBeFalse()
  end)
end)

-- "Regardless of the denizens in the room, 1 or 50" (user, 2026-09-14). The count is never read.
-- "only use flourish with multiple denizens and the boon" (user, 2026-09-16, v4.7.313 -- the
-- later instruction, reversing v4.7.302's "1 or 50").
describe("Deadly Flourish -- the boon path needs a crowd", function()
  it("holds alone with one denizen", function()
    reset({ denizens = 1 })
    local cmd = ataxiaBasher_bardBashing()
    expect(has(cmd, "blade flourish")).toBeFalse()
    expect(has(cmd, "blade flick 7 nomos")).toBeTrue()
    expect(ataxiaTemp.bardFlourishAt).toBeNil()
  end)

  it("fires at two, and in a crowd of fifty", function()
    reset({ denizens = 2 })
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
    reset({ denizens = 50 })
    expect(has(ataxiaBasher_bardBashing(), "blade flourish 7")).toBeTrue()
  end)

  it("a lagging count of zero, or no Mnemosyne module at all, holds", function()
    reset({ denizens = 0 })
    expect(has(ataxiaBasher_bardBashing(), "blade flourish")).toBeFalse()
    reset({ denizens = 2 }); ataxia.mnemosyne = nil
    expect(has(ataxiaBasher_bardBashing(), "blade flourish")).toBeFalse()
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
bardtempostance, mnemShadowTempo = saved.bardtempostance, saved.mnemShadowTempo
mnemSongstep = saved.mnemSongstep
bardWarmarch = saved.bardWarmarch
getEpoch = saved.getEpoch
ataxiaEcho = saved.ataxiaEcho
ataxiaBasher_assembleBattlerage = saved.ataxiaBasher_assembleBattlerage
