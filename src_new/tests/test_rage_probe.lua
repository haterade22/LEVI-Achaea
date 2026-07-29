--- test_rage_probe.lua -- rage-threshold damage probe (v4.7.141)
-- Verifies the pure analysis functions behind `bash probe`: bucket classification
-- (including the ambiguity band around the threshold), FIFO-capped sample recording,
-- the per-mob hi/lo means + ratio (a real "+23% above 40 rage" must show as ~1.23),
-- the rage-band view that locates the REAL breakpoint, and mob/class filtering.

require("mock_mudlet")

ataxiaBasher = ataxiaBasher or {}

local file = "src_new/scripts/levi_ataxia/levi/ataxia/basher/009_Rage_Probe.lua"
local ok, err = pcall(dofile, file)
if not ok then error("Failed to load rage probe: " .. tostring(err)) end

local function newState(at)
  return { on = true, at = at or 40, crits = 0, samples = {} }
end

local function add(st, rage, dmg, mob, class)
  ataxiaBasher_rageProbeRecord(st, { r = rage, d = dmg, m = mob or "a mob", c = class or "Blademaster" })
end

describe("ataxiaBasher_rageProbeBucket -- classification", function()
  it("splits hi/lo around the threshold", function()
    expect(ataxiaBasher_rageProbeBucket(90, 40)).toBe("hi")
    expect(ataxiaBasher_rageProbeBucket(44, 40)).toBe("hi")
    expect(ataxiaBasher_rageProbeBucket(10, 40)).toBe("lo")
    expect(ataxiaBasher_rageProbeBucket(35, 40)).toBe("lo")
  end)

  it("discards the ambiguity band -- vitals.rage is last-prompt (pre-attack) data", function()
    expect(ataxiaBasher_rageProbeBucket(40, 40)).toBe(nil)
    expect(ataxiaBasher_rageProbeBucket(36, 40)).toBe(nil)
    expect(ataxiaBasher_rageProbeBucket(43, 40)).toBe(nil)
  end)

  it("follows a moved threshold and ignores junk", function()
    expect(ataxiaBasher_rageProbeBucket(60, 70)).toBe("lo")
    expect(ataxiaBasher_rageProbeBucket(80, 70)).toBe("hi")
    expect(ataxiaBasher_rageProbeBucket(nil, 40)).toBe(nil)
  end)
end)

describe("ataxiaBasher_rageProbeRecord -- sample store", function()
  it("appends samples in order", function()
    local st = newState()
    add(st, 50, 100); add(st, 10, 80)
    expect(#st.samples).toBe(2)
    expect(st.samples[1].r).toBe(50)
    expect(st.samples[2].d).toBe(80)
  end)

  it("FIFO-caps so the saved table can't grow unbounded", function()
    local st = newState()
    for i = 1, 1600 do add(st, 50, i) end
    expect(#st.samples).toBe(1500)
    expect(st.samples[1].d).toBe(101)    -- oldest 100 dropped
    expect(st.samples[1500].d).toBe(1600) -- newest kept
  end)
end)

describe("ataxiaBasher_rageProbeRows -- per-mob means and ratio", function()
  it("measures a +23% bonus as a ~1.23 ratio", function()
    local st = newState()
    for _ = 1, 20 do add(st, 60, 1230) end -- above the floor: buffed
    for _ = 1, 20 do add(st, 20, 1000) end -- below: unbuffed
    local rows, tot = ataxiaBasher_rageProbeRows(st)
    expect(#rows).toBe(1)
    expect(rows[1].hiN).toBe(20)
    expect(rows[1].loN).toBe(20)
    expect(math.floor(rows[1].ratio * 100 + 0.5)).toBe(123)
    expect(math.floor(tot.ratio * 100 + 0.5)).toBe(123)
  end)

  it("keeps mobs separate (different armour must not blur the means)", function()
    local st = newState()
    add(st, 60, 1000, "a troll"); add(st, 20, 1000, "a troll")
    add(st, 60, 500, "a rat");    add(st, 20, 250, "a rat")
    local rows = ataxiaBasher_rageProbeRows(st)
    expect(#rows).toBe(2)
    local byMob = {}
    for _, r in ipairs(rows) do byMob[r.mob] = r end
    expect(byMob["a troll"].ratio).toBe(1)
    expect(byMob["a rat"].ratio).toBe(2)
  end)

  it("excludes ambiguity-band samples from the means entirely", function()
    local st = newState()
    add(st, 40, 99999) -- inside the band: must not pollute either bucket
    add(st, 60, 100); add(st, 20, 100)
    local _, tot = ataxiaBasher_rageProbeRows(st)
    expect(tot.hiN).toBe(1)
    expect(tot.loN).toBe(1)
    expect(tot.hiMean).toBe(100)
  end)

  it("filters by mob or class substring", function()
    local st = newState()
    add(st, 60, 100, "a troll", "Blademaster")
    add(st, 60, 200, "a rat", "Psion")
    local rows = ataxiaBasher_rageProbeRows(st, "troll")
    expect(#rows).toBe(1)
    expect(rows[1].mob).toBe("a troll")
    local psionRows = ataxiaBasher_rageProbeRows(st, "psion")
    expect(#psionRows).toBe(1)
    expect(psionRows[1].mob).toBe("a rat")
  end)

  it("reports no ratio when a bucket is empty (never divides by zero)", function()
    local st = newState()
    add(st, 60, 100)
    local rows, tot = ataxiaBasher_rageProbeRows(st)
    expect(rows[1].ratio).toBe(nil)
    expect(tot.ratio).toBe(nil)
    expect(tot.loN).toBe(0)
  end)
end)

describe("ataxiaBasher_rageProbeBands -- locating the real breakpoint", function()
  it("buckets by 10 rage, ascending, omitting empty bands", function()
    local st = newState()
    add(st, 5, 100); add(st, 8, 100)   -- band 0-9
    add(st, 55, 200)                    -- band 50-59
    local bands = ataxiaBasher_rageProbeBands(st)
    expect(#bands).toBe(2)
    expect(bands[1].lo).toBe(0)
    expect(bands[1].hi).toBe(9)
    expect(bands[1].n).toBe(2)
    expect(bands[1].mean).toBe(100)
    expect(bands[2].lo).toBe(50)
    expect(bands[2].mean).toBe(200)
  end)

  it("shows the step where the bonus actually starts", function()
    local st = newState()
    for r = 5, 35, 10 do add(st, r, 1000) end   -- below 40: flat
    for r = 45, 75, 10 do add(st, r, 1230) end  -- at/above 40: buffed
    local bands = ataxiaBasher_rageProbeBands(st)
    local means = {}
    for _, b in ipairs(bands) do means[b.lo] = b.mean end
    expect(means[30]).toBe(1000)
    expect(means[40]).toBe(1230) -- the step lands here
  end)
end)

describe("ataxiaBasher_rageProbeHit -- live capture gating", function()
  local saved = ataxiaBasher.rageProbe
  local function fixture()
    ataxiaBasher.rageProbe = newState()
    ataxia = ataxia or {}
    ataxia.vitals = { rage = 60 }
    ataxia.denizensHere = { [123] = "a sturdy troll woman" }
    target = 123
    gmcp = gmcp or {}
    gmcp.Char = { Status = { class = "Blademaster" } }
    return ataxiaBasher.rageProbe
  end

  it("records a non-crit hit with the rage and mob name", function()
    local st = fixture()
    ataxiaBasher_rageProbeHit(1500, "cutting", false)
    expect(#st.samples).toBe(1)
    expect(st.samples[1].r).toBe(60)
    expect(st.samples[1].d).toBe(1500)
    expect(st.samples[1].m).toBe("a sturdy troll woman")
    expect(st.samples[1].c).toBe("Blademaster")
  end)

  it("counts crits but keeps them OUT of the samples (heavy tail)", function()
    local st = fixture()
    ataxiaBasher_rageProbeHit(9000, "cutting", true)
    expect(#st.samples).toBe(0)
    expect(st.crits).toBe(1)
  end)

  it("records nothing while the probe is off", function()
    local st = fixture()
    st.on = false
    ataxiaBasher_rageProbeHit(1500, "cutting", false)
    expect(#st.samples).toBe(0)
  end)

  ataxiaBasher.rageProbe = saved
end)

-- Restore shared state for whoever runs after us (files share one Lua state).
target = nil
