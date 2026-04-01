--- test_afflictions.lua
-- Tests for affliction tracking helpers in 004_Aff_gains_losses.lua.
-- Exercises: affed(), setStackAff(), gotAff(), lostAff()

-- table.contains is a Mudlet extension not in stock Lua 5.1
table.contains = table.contains or function(t, val)
  for _, v in pairs(t) do
    if v == val then return true end
  end
  return false
end

-- Stub all external dependencies that 004_Aff_gains_losses.lua calls
Algedonic = {
  ApplySwaps     = function() end,
  RestoreSwaps   = function() end,
  Prioritize     = function() end,
  Stack_My_Affs  = function() end,
  Count_My_Affs  = function() return 0 end,
  AffCount       = 0,
}
ataxiaNDB_getClass   = function() return "" end
ataxia_lockBreak     = function() end
ataxia_boxEcho       = function() end
ataxia_isClass       = function() return false end
ataxia_tryVultureTalon = function() end
retardationOn        = function() end
retardationOff       = function() end
getdirectionn        = function() end
expandAlias          = function() end
random_direction     = "north"
zgui                 = nil  -- intentionally absent so showAffs() branches are skipped
myaeon               = false
partyrelay           = true
stoplatency          = false
stopscourge          = false
preventriftlock      = false
sent_diagnose        = nil

-- Reset namespace state
ataxia = {
  afflictions    = {},
  vitals         = { hp = 5000, maxhp = 5000, mp = 4000, maxmp = 4000 },
  retardation    = false,
  darkshadeTracker = { timerId = nil, threshold = 17, prioritized = false },
}
ataxiaBasher = { enabled = false, treeblackout = false }
gmcp = {
  Char = {
    Afflictions = { Add = { name = "" }, Remove = { "" }, List = {} },
  },
}

dofile("src_new/scripts/levi_ataxia/levi/ataxia/004_Aff_gains_losses.lua")

-- ─── affed() ────────────────────────────────────────────────────────────────

describe("affed()", function()
  it("returns true when affliction is present", function()
    ataxia.afflictions.paralysis = true
    expect(affed("paralysis")).toBeTrue()
  end)

  it("returns false when affliction is absent", function()
    ataxia.afflictions = {}
    expect(affed("paralysis")).toBeFalse()
  end)

  it("is case-insensitive", function()
    ataxia.afflictions.asthma = true
    expect(affed("ASTHMA")).toBeTrue()
    expect(affed("Asthma")).toBeTrue()
  end)

  it("returns false for a nil-valued entry", function()
    ataxia.afflictions.asthma = nil
    expect(affed("asthma")).toBeFalse()
  end)
end)

-- ─── setStackAff() ──────────────────────────────────────────────────────────

describe("setStackAff()", function()
  it("sets a numeric stack aff to its encoded value", function()
    ataxia.afflictions = {}
    setStackAff("burning12")  -- second-to-last char is "1" → value 1
    expect(ataxia.afflictions.burning).toBe(1)
  end)

  it("resets a stack aff to 0 when num=true", function()
    ataxia.afflictions.burning = 5
    setStackAff("burning12", true)
    expect(ataxia.afflictions.burning).toBe(0)
  end)

  it("defaults to 1 when suffix digit is not parseable as a number", function()
    -- aff name where second-to-last char is non-numeric
    ataxia.afflictions = {}
    setStackAff("pressure")  -- no numeric suffix → falls to else branch → 1
    expect(ataxia.afflictions.pressure).toBe(1)
  end)

  it("recognises every stack-aff name", function()
    -- These names must all resolve to a known key in the internal affs list
    local stackNames = {
      "horror", "pyre", "unweavingspirit", "unweavingmind", "unweavingbody",
      "temperedsanguine", "temperedcholeric", "temperedmelancholic", "temperedphlegmatic",
      "pressure", "crackedribs", "torntendons", "skullfractures", "wristfractures",
      "burning", "crescendo",
    }
    for _, name in ipairs(stackNames) do
      ataxia.afflictions = {}
      setStackAff(name)
      -- After setStackAff the key should exist and be a number
      local v = ataxia.afflictions[name]
      expect(type(v)).toBe("number")
    end
  end)
end)

-- ─── gotAff() ───────────────────────────────────────────────────────────────

describe("gotAff() — basic state tracking", function()
  it("sets a plain affliction in ataxia.afflictions", function()
    ataxia.afflictions = {}
    gmcp.Char.Afflictions.Add = { name = "asthma" }
    gotAff()
    expect(ataxia.afflictions.asthma).toBeTrue()
  end)

  it("ignores blindness", function()
    ataxia.afflictions = {}
    gmcp.Char.Afflictions.Add = { name = "blindness" }
    gotAff()
    expect(affed("blindness")).toBeFalse()
  end)

  it("ignores deafness", function()
    ataxia.afflictions = {}
    gmcp.Char.Afflictions.Add = { name = "deafness" }
    gotAff()
    expect(affed("deafness")).toBeFalse()
  end)

  it("ignores insomnia", function()
    ataxia.afflictions = {}
    gmcp.Char.Afflictions.Add = { name = "insomnia" }
    gotAff()
    expect(affed("insomnia")).toBeFalse()
  end)

  it("stores a numeric stack aff as a number", function()
    ataxia.afflictions = {}
    gmcp.Char.Afflictions.Add = { name = "burning12" }
    gotAff()
    expect(type(ataxia.afflictions.burning)).toBe("number")
  end)

  it("raises the 'aff gained' event", function()
    mock.raised_events = {}
    gmcp.Char.Afflictions.Add = { name = "slickness" }
    gotAff()
    local found = false
    for _, e in ipairs(mock.raised_events) do
      if e == "aff gained" then found = true end
    end
    expect(found).toBeTrue()
  end)
end)

-- ─── lostAff() ──────────────────────────────────────────────────────────────

describe("lostAff() — affliction removal", function()
  it("clears a boolean affliction to nil", function()
    ataxia.afflictions = { asthma = true }
    gmcp.Char.Afflictions.Remove = { "asthma" }
    lostAff()
    expect(ataxia.afflictions.asthma).toBeNil()
  end)

  it("ignores blindness in the ignore list without erroring", function()
    gmcp.Char.Afflictions.Remove = { "blindness" }
    lostAff()
    expect(true).toBeTrue()
  end)

  it("resets unweavingmind to 0 (not nil) on cure", function()
    ataxia.afflictions.unweavingmind = 4
    gmcp.Char.Afflictions.Remove = { "unweavingmind" }
    lostAff()
    expect(ataxia.afflictions.unweavingmind).toBe(0)
  end)

  it("resets unweavingbody to 0 on cure", function()
    ataxia.afflictions.unweavingbody = 2
    gmcp.Char.Afflictions.Remove = { "unweavingbody" }
    lostAff()
    expect(ataxia.afflictions.unweavingbody).toBe(0)
  end)

  it("resets crescendo to 0 on cure", function()
    ataxia.afflictions.crescendo = 3
    gmcp.Char.Afflictions.Remove = { "crescendo" }
    lostAff()
    expect(ataxia.afflictions.crescendo).toBe(0)
  end)

  it("raises the 'aff cured' event", function()
    mock.raised_events = {}
    ataxia.afflictions = { kelp = true }
    gmcp.Char.Afflictions.Remove = { "kelp" }
    lostAff()
    local found = false
    for _, e in ipairs(mock.raised_events) do
      if e == "aff cured" then found = true end
    end
    expect(found).toBeTrue()
  end)
end)
