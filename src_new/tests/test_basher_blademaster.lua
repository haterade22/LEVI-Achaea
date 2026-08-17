--- test_basher_blademaster.lua — Blademaster bashing attack assembly
-- Verifies ataxiaBasher_blademasterBashing() swaps drawslash -> multislash while the
-- White Heaven's Shattered Star boon (bmShatteredStar) is active, and falls back to
-- drawslash otherwise. Loads the real basher/002_Class_Bashing.lua (function defs only).

require("mock_mudlet")

-- Globals the class-bashing file reads at call time.
target = "manticore"
ataxia = { settings = { separator = ";" }, vitals = { rage = 0 } }
ataxiaBasher = {
  shielded = false,
  rageraze = false,
  battlerage = { Blademaster = { raze = "raze " .. target } },
}
-- Battlerage assembly is exercised in test_basher_battlerage; stub to empty so we test
-- only the melee verb selection here.
function ataxiaBasher_assembleBattlerage() return "" end

local file = "src_new/scripts/levi_ataxia/levi/ataxia/basher/002_Class_Bashing.lua"
local ok, err = pcall(dofile, file)
if not ok then error("Failed to load class-bashing file: " .. tostring(err)) end

local function has(cmd, needle) return cmd:find(needle, 1, true) ~= nil end

describe("ataxiaBasher_blademasterBashing — Shattered Star (multislash) boon", function()
  it("uses drawslash <t> sternum when the boon is OFF", function()
    bmShatteredStar = false
    ataxiaBasher.shielded = false
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "drawslash " .. target .. " sternum")).toBeTrue()
    expect(has(cmd, "multislash")).toBeFalse()
  end)

  it("swaps to multislash <t> sternum (same body part) when the boon is ON", function()
    bmShatteredStar = true
    ataxiaBasher.shielded = false
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "multislash " .. target .. " sternum")).toBeTrue()
    expect(has(cmd, "drawslash")).toBeFalse()
  end)

  it("keeps the infuse in the chain with multislash", function()
    bmShatteredStar = true
    ataxiaBasher.shielded = false
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "infuse lightning")).toBeTrue() -- lightning leads as of v4.7.269
  end)

  it("still swaps to multislash on the rageraze+shielded path", function()
    bmShatteredStar = true
    ataxiaBasher.shielded = true
    ataxiaBasher.rageraze = true
    ataxia.vitals.rage = 20 -- >= 17 so the rageraze branch is taken
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "multislash " .. target .. " sternum")).toBeTrue()
    expect(has(cmd, "drawslash")).toBeFalse()
  end)

  it("uses drawslash on the rageraze+shielded path when the boon is OFF", function()
    bmShatteredStar = false
    ataxiaBasher.shielded = true
    ataxiaBasher.rageraze = true
    ataxia.vitals.rage = 20
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "drawslash " .. target .. " sternum")).toBeTrue()
    expect(has(cmd, "multislash")).toBeFalse()
  end)

  it("does not inject a melee verb on the plain shielded raze path", function()
    bmShatteredStar = true
    ataxiaBasher.shielded = true
    ataxiaBasher.rageraze = false -- this branch is "raze <t> ; <battlerage>" only
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "multislash")).toBeFalse()
    expect(has(cmd, "drawslash")).toBeFalse()
  end)
end)

describe("ataxiaBasher_blademasterBashing — Bladed Reflexes (shin augment) boon", function()
  local function reset(shin)
    bmShatteredStar = false
    bmBladedReflexes = true
    ataxiaBasher.shielded = false
    ataxiaBasher.rageraze = false
    ataxiaTemp = {}
    ataxia.defences = {}
    -- Inject through the REAL accessor (the test_bm_infuse idiom). This used to set
    -- ataxia.vitals.class, which reached shin via a fallback branch PRODUCTION NEVER RAN --
    -- getShin returns 0 not nil, and 0 is truthy, so the `or` never fired. These tests were the
    -- only consumer of that dead branch (v4.7.269).
    blademaster = { getShin = function() return shin end }
  end

  it("prepends the configurable augment spend with the boon on and enough shin", function()
    reset(20)
    local cmd = ataxiaBasher_blademasterBashing()
    -- Default spend is 20, not 3: ONE SHIN IS ONE SECOND of the augment (user-confirmed), so the
    -- old default bought three seconds of a 20% damage reduction.
    expect(has(cmd, "shin augment 20")).toBeTrue()
    expect(cmd:find("shin augment 20", 1, true)).toBe(1) -- augment leads the chain
    expect(has(cmd, "drawslash " .. target .. " sternum")).toBeTrue() -- attack intact
    reset(5)
    ataxiaBasher.bmAugmentAmount = 5
    local cmd2 = ataxiaBasher_blademasterBashing()
    expect(has(cmd2, "shin augment 5")).toBeTrue()
    ataxiaBasher.bmAugmentAmount = nil
  end)

  it("does NOT augment below the spend amount (augment needs the shin)", function()
    reset(2) -- below the default spend of 3
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "shin augment")).toBeFalse()
  end)

  it("does NOT augment while the bodyaugment defence is already up", function()
    reset(3)
    ataxia.defences.bodyaugment = true
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "shin augment")).toBeFalse()
  end)

  it("does NOT re-send during the attempt-hold (channel wind-up)", function()
    reset(3)
    ataxiaTemp.bmAugmentAttempted = true
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "shin augment")).toBeFalse()
  end)

  it("arms the attempt-hold when it sends, so the NEXT swing skips the augment", function()
    reset(20) -- must clear the DEFAULT spend, which is 20 as of v4.7.269 (1 shin = 1 second)
    local first = ataxiaBasher_blademasterBashing()
    expect(has(first, "shin augment 20")).toBeTrue()
    local second = ataxiaBasher_blademasterBashing()
    expect(has(second, "shin augment")).toBeFalse()
  end)

  it("does NOT augment when the boon is off", function()
    reset(3)
    bmBladedReflexes = false
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "shin augment")).toBeFalse()
  end)
end)

-- ONE SHIN/EQUILIBRIUM SPENDER PER ROUND (v4.7.193, Codex adversarial review).
-- The `;`-chain is ONE queue entry, so every command in it executes back to back the
-- instant it fires. SHIN AUGMENT and SHIN THUNDERSTORM both want the equilibrium and both
-- draw on the same shin pool, so a round carrying both gets the second one REJECTED --
-- after ataxiaBasher_bmThunderstorm already stamped a 4s cooldown on send. The fix skips
-- the thunderstorm CALL (not just its result) whenever the augment claimed the round,
-- because the stamp lives inside the helper.
describe("ataxiaBasher_blademasterBashing -- augment and thunderstorm never share a round", function()
  local function reset(shin, denizens)
    bmShatteredStar, bmBladedReflexes, mnemDivineThunder = false, false, true
    ataxiaBasher.shielded, ataxiaBasher.rageraze = false, false
    ataxiaTemp = {}
    ataxia.defences = {}
    blademaster = { getShin = function() return shin end }
    ataxia.mnemosyne = { _denizenCount = function() return denizens or 4 end }
  end

  it("sends the storm alone when no augment is due", function()
    reset(40); bmBladedReflexes = false
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "shin thunderstorm")).toBeTrue()
    expect(has(cmd, "shin augment")).toBeFalse()
  end)

  it("sends the augment alone and SUPPRESSES the storm when both would fire", function()
    reset(40); bmBladedReflexes = true -- 40 shin clears augment (3) AND storm (30) alone
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "shin augment 20")).toBeTrue()
    expect(has(cmd, "shin thunderstorm")).toBeFalse()
  end)

  it("does not burn the storm's 4s cooldown on the round it was suppressed", function()
    reset(40); bmBladedReflexes = true
    ataxiaBasher_blademasterBashing()
    -- The whole point: the stamp is inside the helper, so a suppressed round must not
    -- have called it at all. If bmShinStormAt were set here, the storm would be
    -- locked out for 4s having never gone out.
    expect(ataxiaTemp.bmShinStormAt).toBe(nil)
  end)

  it("lets the storm through on the NEXT round, once the augment attempt-hold is up", function()
    reset(40); bmBladedReflexes = true
    expect(has(ataxiaBasher_blademasterBashing(), "shin augment 20")).toBeTrue()
    -- The augment arms bmAugmentAttempted for 5s; with it held, the round is free again.
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "shin augment")).toBeFalse()
    expect(has(cmd, "shin thunderstorm")).toBeTrue()
  end)

  it("is inert without the Divine Thunder boon (no storm to collide with)", function()
    reset(40); bmBladedReflexes = true; mnemDivineThunder = false
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "shin augment 20")).toBeTrue()
    expect(has(cmd, "shin thunderstorm")).toBeFalse()
  end)
end)

-- MIDNIGHT SNOW'S ICY HEART (v4.7.195). SHIN BLIZZARD is the exact twin of SHIN
-- THUNDERSTORM -- AB 315 vs AB 314, both "Works on/against: Room", both 4.00s of
-- EQUILIBRIUM, both 30 Shin energy. Only the damage type differs (cold vs electric). So
-- they are ONE slot with a choice of type, not two riders: casting both would be 60 shin
-- and two equilibrium spends in one queued line, and the second would be rejected.
describe("shin storms -- one slot, two damage types", function()
  local nulled
  local function reset(shin, denizens)
    bmShatteredStar, bmBladedReflexes = false, false
    mnemDivineThunder, mnemIcyHeart = false, false
    ataxiaBasher.shielded, ataxiaBasher.rageraze = false, false
    ataxiaBasher.bmStormPrefs, ataxiaBasher.blizzardAt = nil, nil
    ataxiaTemp = {}
    ataxia.defences = {}
    blademaster = { getShin = function() return shin or 40 end }
    nulled = {}
    ataxia.mnemosyne = {
      _denizenCount = function() return denizens or 4 end,
      damageNulled = function(t) return nulled[t] == true end,
    }
  end

  it("casts nothing without either boon", function()
    reset()
    expect(ataxiaBasher_bmShinStorm(";")).toBe("")
  end)

  it("casts the thunderstorm when only Divine Thunder is held", function()
    reset(); mnemDivineThunder = true
    expect(ataxiaBasher_bmShinStorm(";")).toBe("shin thunderstorm;")
  end)

  it("casts the blizzard when only Icy Heart is held", function()
    reset(); mnemIcyHeart = true
    expect(ataxiaBasher_bmShinStorm(";")).toBe("shin blizzard;")
  end)

  it("casts exactly ONE of them when both are held", function()
    reset(); mnemDivineThunder, mnemIcyHeart = true, true
    local cmd = ataxiaBasher_bmShinStorm(";")
    expect(cmd == "shin thunderstorm;" or cmd == "shin blizzard;").toBeTrue()
    -- the shared equilibrium slot is now stamped, so the round is spent
    expect(ataxiaBasher_bmShinStorm(";")).toBe("")
  end)

  it("prefers the thunderstorm by default, so Divine-Thunder-only users are unaffected", function()
    reset(); mnemDivineThunder, mnemIcyHeart = true, true
    expect(ataxiaBasher_bmShinStorm(";")).toBe("shin thunderstorm;")
  end)

  -- The payoff for owning both: the affix nulls a damage TYPE, and we have two.
  it("steps around ICEPROOF -- cold nulled, so it thunderstorms", function()
    reset(); mnemDivineThunder, mnemIcyHeart = true, true
    nulled.cold = true
    expect(ataxiaBasher_bmShinStorm(";")).toBe("shin thunderstorm;")
  end)

  it("steps around an ELECTRIC-nulling ripple -- so it blizzards", function()
    reset(); mnemDivineThunder, mnemIcyHeart = true, true
    nulled.electricity = true
    expect(ataxiaBasher_bmShinStorm(";")).toBe("shin blizzard;")
  end)

  it("still casts when BOTH types are nulled -- a 33% cut beats no AoE", function()
    reset(); mnemDivineThunder, mnemIcyHeart = true, true
    nulled.cold, nulled.electricity = true, true
    expect(ataxiaBasher_bmShinStorm(";")).toBe("shin thunderstorm;")
  end)

  it("falls through to the other type when the preferred boon is not held", function()
    reset(); mnemIcyHeart = true      -- no Divine Thunder
    nulled.electricity = true          -- and lightning is nulled anyway
    expect(ataxiaBasher_bmShinStorm(";")).toBe("shin blizzard;")
  end)

  it("honours an explicit preference order", function()
    reset(); mnemDivineThunder, mnemIcyHeart = true, true
    ataxiaBasher.bmStormPrefs = { "ice", "lightning" }
    expect(ataxiaBasher_bmShinStorm(";")).toBe("shin blizzard;")
  end)

  it("respects the crowd gate and the shin floor, like its twin", function()
    reset(40, 2); mnemIcyHeart = true            -- only 2 denizens, gate is 3
    expect(ataxiaBasher_bmShinStorm(";")).toBe("")
    reset(29, 4); mnemIcyHeart = true            -- 29 shin, blizzard needs 30
    expect(ataxiaBasher_bmShinStorm(";")).toBe("")
  end)

  it("takes a separate blizzardAt when one is configured", function()
    reset(40, 2); mnemIcyHeart = true
    ataxiaBasher.blizzardAt = 2
    expect(ataxiaBasher_bmShinStorm(";")).toBe("shin blizzard;")
  end)

  it("breaks the shield first -- neither storm fires on a shielded round", function()
    reset(); mnemDivineThunder, mnemIcyHeart = true, true
    ataxiaBasher.shielded = true
    expect(ataxiaBasher_bmShinStorm(";")).toBe("")
    expect(ataxiaTemp.bmShinStormAt).toBe(nil) -- and stamps nothing
  end)

  it("still yields the round to SHIN AUGMENT (the v4.7.193 rule)", function()
    reset(); mnemIcyHeart = true; bmBladedReflexes = true
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "shin augment 20")).toBeTrue()
    expect(has(cmd, "shin blizzard")).toBeFalse()
    expect(ataxiaTemp.bmShinStormAt).toBe(nil)
  end)

  it("rides the assembled round when nothing else claimed the shin", function()
    reset(); mnemIcyHeart = true
    expect(has(ataxiaBasher_blademasterBashing(), "shin blizzard")).toBeTrue()
  end)
end)

-- Restore shared state for whoever runs after us (files share one Lua state).
bmShatteredStar, bmBladedReflexes, mnemDivineThunder = false, false, false
mnemIcyHeart = false
ataxia.mnemosyne = nil
ataxiaTemp = {}

-- ---------------------------------------------------------------------------
-- The shin budget and SHIN PHOENIX (v4.7.269)
-- ---------------------------------------------------------------------------
describe("shin budget -- infuse yields to Phoenix", function()
  local function setup(shin, inTower)
    bmShatteredStar, bmBladedReflexes, mnemDivineThunder, mnemIcyHeart = false, false, false, false
    ataxiaBasher.shielded, ataxiaBasher.rageraze = false, false
    ataxiaBasher.inMnemosyne = inTower and true or false
    ataxiaBasher.bmInfuseAt, ataxiaBasher.phoenixAt = nil, nil
    ataxiaTemp = {}
    ataxia.defences = {}
    ataxia.vitals = ataxia.vitals or {}
    ataxia.vitals.hpp = 100
    ataxia.vitals.rage = 0
    blademaster = { getShin = function() return shin end }
  end

  -- The whole point: infuse was the ONE shin spender with no arithmetic behind it, and it fired
  -- every single round.
  it("holds the infuse in the tower below 90 shin", function()
    setup(85, true)
    expect(has(ataxiaBasher_blademasterBashing(), "infuse")).toBeFalse()
  end)

  -- 90 is derived: Phoenix needs 80, so infusing only above 90 leaves >80 afterwards.
  it("infuses in the tower above 90 shin", function()
    setup(95, true)
    expect(has(ataxiaBasher_blademasterBashing(), "infuse lightning")).toBeTrue()
  end)

  it("is unrestricted OUTSIDE the tower -- nothing is being saved for", function()
    setup(5, false)
    expect(has(ataxiaBasher_blademasterBashing(), "infuse lightning")).toBeTrue()
  end)

  it("also holds it on the shielded rage-raze round", function()
    setup(85, true)
    ataxiaBasher.shielded, ataxiaBasher.rageraze = true, true
    ataxia.vitals.rage = 50
    expect(has(ataxiaBasher_blademasterBashing(), "infuse")).toBeFalse()
    setup(95, true)
    ataxiaBasher.shielded, ataxiaBasher.rageraze = true, true
    ataxia.vitals.rage = 50
    expect(has(ataxiaBasher_blademasterBashing(), "infuse lightning")).toBeTrue()
  end)
end)

describe("SHIN PHOENIX", function()
  local function setup(shin, hpp)
    bmShatteredStar, bmBladedReflexes, mnemDivineThunder, mnemIcyHeart = false, false, false, false
    ataxiaBasher.shielded, ataxiaBasher.rageraze = false, false
    ataxiaBasher.inMnemosyne = true
    ataxiaBasher.bmInfuseAt, ataxiaBasher.phoenixAt = nil, nil
    ataxiaTemp = {}
    ataxia.defences = {}
    ataxia.vitals = ataxia.vitals or {}
    ataxia.vitals.hpp = hpp
    ataxia.vitals.rage = 0
    blademaster = { getShin = function() return shin end }
  end

  it("fires at 10% HP with 80 shin", function()
    setup(80, 10)
    expect(has(ataxiaBasher_blademasterBashing(), "shin phoenix")).toBeTrue()
  end)

  it("does not fire above the threshold or below 80 shin", function()
    setup(80, 35)
    expect(has(ataxiaBasher_blademasterBashing(), "shin phoenix")).toBeFalse()
    setup(79, 10)
    expect(has(ataxiaBasher_blademasterBashing(), "shin phoenix")).toBeFalse()
  end)

  -- hpp == 0 is BLACKOUT, not 10% -- the idiom ataxiaBasher_dangerLevel already uses. A bare
  -- `hpp <= 10` empties the whole shin pool every time we lose sight of our own health.
  it("does NOT fire on a zero HP reading (blackout, not nearly dead)", function()
    setup(100, 0)
    expect(has(ataxiaBasher_blademasterBashing(), "shin phoenix")).toBeFalse()
  end)

  -- It consumes the whole pool, so it cannot share a round: augment must yield.
  it("outranks the augment and suppresses it for that round", function()
    setup(100, 10)
    bmBladedReflexes = true
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "shin phoenix")).toBeTrue()
    expect(has(cmd, "shin augment")).toBeFalse()
  end)

  it("lets the augment through once HP recovers", function()
    setup(100, 100)
    bmBladedReflexes = true
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "shin phoenix")).toBeFalse()
    expect(has(cmd, "shin augment 20")).toBeTrue()
  end)

  -- Leave the globals as we found them. A boon flag or a low hpp left set here rewrites what every
  -- later test FILE measures -- three separate leaks of exactly this kind were found in v4.7.268.
  it("leaves no state behind for the next suite", function()
    bmBladedReflexes = false
    ataxiaBasher.inMnemosyne = false
    ataxia.vitals.hpp = 100
    expect(bmBladedReflexes).toBeFalse()
  end)
end)
