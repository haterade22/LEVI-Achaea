--- test_bash_stats.lua -- the reworked DPS figures and incoming-damage-by-type (v4.7.207)
--
-- Both DPS numbers were misleading, each in a different way:
--
--   "Avg" was totalDamage / WALL CLOCK since the stats were reset. Every second spent not
--   fighting -- walking, resting, hovering to heal, sitting on the boon screen -- divided it
--   down, so it measured how long the client had been open rather than how hard we hit.
--
--   "Now" was a SINGLE balance's damage over that balance's duration. One crit spiked it, one
--   miss zeroed it; it flickered too hard to read mid-fight.
--
-- Now: Avg divides by ACTIVE combat seconds, and Now is a rolling 10s window (the same shape
-- the incoming-damage watchdog already used).

require("mock_mudlet")

ataxia = { settings = {}, vitals = {} }
function ataxiaEcho() end
gmcp = { Char = { Status = { gold = 0 } } }

local clock = 100000
local _epoch = getEpoch
getEpoch = function() return clock end

dofile("src_new/scripts/levi_ataxia/levi/ataxia/basher/003_Bash_Stats_Functions.lua")

local function reset()
  clock = 100000
  resetBashingStats(true)
end

describe("bashStats_recordDamage -- the active-combat clock", function()
  it("the first hit starts the clock but measures no time", function()
    reset()
    bashStats_recordDamage(500)
    expect(bashStats.combatTime).toBe(0) -- we know when we connected, not when we started
    expect(bashStats.totalDamage or 0).toBe(0) -- trigger 350 owns totalDamage, not us
  end)

  it("accumulates the gaps between hits", function()
    reset()
    bashStats_recordDamage(500)
    clock = clock + 3; bashStats_recordDamage(500)
    clock = clock + 2; bashStats_recordDamage(500)
    expect(bashStats.combatTime).toBe(5)
  end)

  it("does NOT count a gap longer than the combat threshold", function()
    reset()
    bashStats_recordDamage(500)
    clock = clock + 3; bashStats_recordDamage(500)   -- +3, still fighting
    clock = clock + 600; bashStats_recordDamage(500) -- ten minutes away: not combat
    expect(bashStats.combatTime).toBe(3)
  end)

  it("ignores zero and negative amounts", function()
    reset()
    bashStats_recordDamage(0)
    bashStats_recordDamage(-50)
    expect(#bashStats.dmgSamples).toBe(0)
  end)

  it("trims samples that fall out of the rolling window", function()
    reset()
    bashStats_recordDamage(500)
    clock = clock + 30
    bashStats_recordDamage(500)
    expect(#bashStats.dmgSamples).toBe(1) -- the 30s-old sample is gone
  end)
end)

describe("bashStats_getDPS -- Avg is per FIGHTING second", function()
  it("is 0 with no damage at all", function()
    reset()
    local s, b = bashStats_getDPS()
    expect(s).toBe("0")
    expect(b).toBe("0.0")
  end)

  -- The headline fix: idle time must not dilute the average.
  it("an hour idle does NOT drag the session average down", function()
    reset()
    bashStats.totalDamage = 10000
    bashStats_recordDamage(5000)
    clock = clock + 5; bashStats_recordDamage(5000)   -- 5 seconds of actual fighting
    clock = clock + 3600                              -- then an hour of doing nothing
    local s = bashStats_getDPS()
    expect(s).toBe("2000.0")                          -- 10000 / 5s fighting
    -- The old wall-clock figure would have been 10000/3605 = "2.8".
  end)

  it("falls back to wall clock before there is any combat time to measure", function()
    reset()
    bashStats.totalDamage = 1000
    clock = clock + 10
    local s = bashStats_getDPS()
    expect(s).toBe("100.0") -- rather than a confident, wrong 0
  end)
end)

describe("bashStats_getDPS -- Now is a rolling window", function()
  it("averages the window rather than one balance", function()
    reset()
    bashStats_recordDamage(1000)
    bashStats_recordDamage(1000)
    local _, b = bashStats_getDPS()
    expect(b).toBe("200.0") -- 2000 over the 10s window
  end)

  it("decays to 0 once we stop hitting, instead of showing the last burst", function()
    reset()
    bashStats_recordDamage(5000)
    clock = clock + 30
    local _, b = bashStats_getDPS()
    expect(b).toBe("0.0")
  end)

  it("one crit no longer spikes the reading the way a single sample did", function()
    reset()
    bashStats_recordDamage(200)
    bashStats_recordDamage(200)
    bashStats_recordDamage(9000) -- a crit
    local _, b = bashStats_getDPS()
    expect(b).toBe("940.0")      -- 9400/10, not 9000-per-balance
  end)
end)

-- "Health lost: 1488 (physical cutting)."
describe("incoming damage by type", function()
  it("tallies amount, total and hit count", function()
    reset()
    bashStats_recordIncoming(1488, "physical cutting")
    bashStats_recordIncoming(512, "physical cutting")
    expect(bashStats.incomingByType["physical cutting"]).toBe(2000)
    expect(bashStats.incomingTotal).toBe(2000)
    expect(bashStats.incomingHits).toBe(2)
  end)

  it("normalises case and stray whitespace so one type stays one bucket", function()
    reset()
    bashStats_recordIncoming(100, "Physical Cutting")
    bashStats_recordIncoming(100, "  physical cutting ")
    expect(bashStats.incomingByType["physical cutting"]).toBe(200)
  end)

  it("keeps the FULL type -- category and subtype are different answers", function()
    reset()
    bashStats_recordIncoming(100, "physical cutting")
    bashStats_recordIncoming(100, "physical blunt")
    expect(bashStats.incomingByType["physical cutting"]).toBe(100)
    expect(bashStats.incomingByType["physical blunt"]).toBe(100)
  end)

  it("is kept separate from our OUTGOING damageByType", function()
    reset()
    bashStats.damageByType["magic"] = 99999
    bashStats_recordIncoming(100, "magic")
    expect(bashStats.incomingByType["magic"]).toBe(100) -- not 100099
  end)

  it("ignores nonsense amounts", function()
    reset()
    bashStats_recordIncoming(0, "magic")
    bashStats_recordIncoming(nil, "magic")
    expect(bashStats.incomingTotal).toBe(0)
  end)
end)

describe("bashStats_topIncoming -- what is actually hurting us", function()
  it("is nil before anything has hit us", function()
    reset()
    expect(bashStats_topIncoming()).toBe(nil)
  end)

  it("returns the biggest type, its total and its share", function()
    reset()
    bashStats_recordIncoming(7000, "physical cutting")
    bashStats_recordIncoming(3000, "magic")
    local dtype, amt, share = bashStats_topIncoming()
    expect(dtype).toBe("physical cutting")
    expect(amt).toBe(7000)
    expect(math.floor(share + 0.5)).toBe(70)
  end)

  it("ranks every type, biggest first", function()
    reset()
    bashStats_recordIncoming(100, "cold")
    bashStats_recordIncoming(900, "physical cutting")
    bashStats_recordIncoming(500, "magic")
    local ranked = bashStats_incomingRanked()
    expect(ranked[1][1]).toBe("physical cutting")
    expect(ranked[2][1]).toBe("magic")
    expect(ranked[3][1]).toBe("cold")
  end)

  it("breaks ties stably rather than at random", function()
    reset()
    bashStats_recordIncoming(500, "zeta")
    bashStats_recordIncoming(500, "alpha")
    expect(bashStats_incomingRanked()[1][1]).toBe("alpha")
  end)
end)

-- Restore shared state for whoever runs after us (files share one Lua state).
getEpoch = _epoch
