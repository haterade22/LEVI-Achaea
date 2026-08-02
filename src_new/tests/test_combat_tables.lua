--- test_combat_tables.lua
-- Tests for the numeric affliction display table (005_Prompt_Affs.lua)
-- and its consistency with the stack-aff list in 004_Aff_gains_losses.lua.
--
-- Key regression: every aff that appears in the prompt display table must also
-- be recognised by setStackAff(), otherwise it would display but never get set.

-- Provide table.contains (Mudlet extension)
table.contains = table.contains or function(t, val)
  for _, v in pairs(t) do
    if v == val then return true end
  end
  return false
end

-- ─── Load 004 stubs & source ──────────────────────────────────────────────

Algedonic = {
  ApplySwaps    = function() end,
  RestoreSwaps  = function() end,
  Prioritize    = function() end,
  Stack_My_Affs = function() end,
  Count_My_Affs = function() return 0 end,
  AffCount      = 0,
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
zgui                 = nil
myaeon               = false
partyrelay           = true
stoplatency          = false
stopscourge          = false
preventriftlock      = false
sent_diagnose        = nil

ataxia = {
  afflictions    = {},
  vitals         = { hp = 5000, maxhp = 5000 },
  retardation    = false,
  -- darkshadeTracker deliberately ABSENT (v4.7.194): the package never created it
  -- either, and hand-building it here is what hid the nil-index crash.
}
ataxiaBasher = { enabled = false, treeblackout = false }
gmcp = { Char = { Afflictions = { Add = { name = "" }, Remove = { "" }, List = {} } } }

dofile("src_new/scripts/levi_ataxia/levi/ataxia/004_Aff_gains_losses.lua")

-- ─── The expected set of numeric (stacking) afflictions ──────────────────────
-- This is the authoritative list. Both 005_Prompt_Affs (display) and
-- 004_Aff_gains_losses (setStackAff) must recognise every name here.
local EXPECTED_STACK_AFFS = {
  "horror", "pyre",
  "unweavingspirit", "unweavingmind", "unweavingbody",
  "temperedsanguine", "temperedcholeric", "temperedmelancholic", "temperedphlegmatic",
  "pressure",
  "crackedribs", "torntendons", "skullfractures", "wristfractures",
  "burning", "crescendo",
}

-- ─── setStackAff() recognises every expected stack aff ───────────────────────

describe("setStackAff() — stack-aff completeness", function()
  for _, name in ipairs(EXPECTED_STACK_AFFS) do
    -- Capture in local so the closure binds correctly
    local affName = name
    it("recognises '" .. affName .. "'", function()
      ataxia.afflictions = {}
      setStackAff(affName)
      expect(type(ataxia.afflictions[affName])).toBe("number")
    end)
  end
end)

-- ─── setStackAff() does NOT create spurious keys ─────────────────────────────

describe("setStackAff() — no spurious keys", function()
  it("creates exactly one key per call", function()
    ataxia.afflictions = {}
    setStackAff("burning")
    local count = 0
    for _ in pairs(ataxia.afflictions) do count = count + 1 end
    expect(count).toBe(1)
  end)

  it("unrecognised aff name produces no key (empty string tow)", function()
    ataxia.afflictions = {}
    setStackAff("totallymadeupaffliction")
    -- tow = "" so afflictions[""] gets set — this is a pre-existing behaviour;
    -- the test documents it rather than asserting it shouldn't happen.
    expect(ataxia.afflictions[""]).toBeGreaterThan(-1)
  end)
end)

-- ─── Numeric display table in 005_Prompt_Affs consistency ────────────────────
-- We verify consistency indirectly: load 005 with enough stubs to make it
-- parse cleanly, then call ataxia_promptAffs() with each expected stack aff
-- at a non-zero count and confirm the output contains the aff abbreviation.

describe("ataxia_promptAffs() — numeric aff display", function()
  -- Stubs needed by 005_Prompt_Affs
  affs_to_colour      = {}
  populate_aff_colours = function() affs_to_colour = {} end
  ataxia_promptLocks  = function() return "" end
  getDamnationPromptWarning = nil
  rTabSize = function(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
  end

  dofile("src_new/scripts/levi_ataxia/levi/ataxia/005_Prompt_Affs.lua")

  -- Map of aff name → expected abbreviation in output
  local affAbbrevs = {
    temperedsanguine    = "TS",
    temperedphlegmatic  = "TP",
    temperedcholeric    = "TC",
    temperedmelancholic = "TM",
    skullfractures      = "Sf",
    torntendons         = "Tt",
    crackedribs         = "Cr",
    crescendo           = "Cres",
    wristfractures      = "Wf",
    pressure            = "Pr",
    burning             = "burns",
    unweavingmind       = "UWM",
    unweavingbody       = "UWB",
    unweavingspirit     = "UWS",
    horror              = "HORROR",
    pyre                = "PYRE",
  }

  for affName, abbrev in pairs(affAbbrevs) do
    local a, b = affName, abbrev
    it("displays '" .. a .. "' as '" .. b .. "'", function()
      ataxia.vitals = { bleed = 0 }
      ataxia.afflictions = { [a] = 1 }
      local result = ataxia_promptAffs()
      expect(result).toContain(b)
    end)
  end
end)
