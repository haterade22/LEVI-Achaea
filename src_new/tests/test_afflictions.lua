--- test_afflictions.lua
-- Tests for affliction tracking helpers in 004_Aff_gains_losses.lua.
-- Exercises: affed(), setStackAff(), gotAff(), lostAff()

local mock = require("mock_mudlet")

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
  -- darkshadeTracker deliberately ABSENT: the package never created it either, and
  -- hand-building it here is what hid the nil-index crash until v4.7.194.
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
      if e.name == "aff gained" then found = true end
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
      if e.name == "aff cured" then found = true end
    end
    expect(found).toBeTrue()
  end)
end)

-- DARKSHADE TRACKER (v4.7.194). `ataxia.darkshadeTracker` was referenced by both the gain
-- and the cure path but CREATED NOWHERE in the package -- the only definitions were these
-- test fixtures, which hand-built it. On a real profile the first darkshade threw a
-- nil-index, and because an error aborts the handler, everything after the branch was
-- skipped too: `ataxia_lockBreak()` + `raiseEvent("aff gained")` on the way in, and
-- `raiseEvent("aff cured")` + `Algedonic.RestoreSwaps` on the way out. Against a Serpent,
-- darkshade staying up for 26s IS the kill route.
describe("darkshade tracking survives an uninitialised namespace", function()
  local function fresh()
    ataxia.darkshadeTracker = nil   -- exactly what a real profile starts with
    ataxiaTemp = {}
    ataxia.afflictions = {}
  end

  it("does not throw when darkshade is gained on a virgin profile", function()
    fresh()
    gmcp.Char.Afflictions.Add = { name = "darkshade" }
    expect(pcall(gotAff)).toBeTrue()
  end)

  it("still raises 'aff gained' -- the crash used to swallow it", function()
    fresh()
    mock.raised_events = {}
    gmcp.Char.Afflictions.Add = { name = "darkshade" }
    gotAff()
    local found = false
    for _, e in ipairs(mock.raised_events) do
      if e.name == "aff gained" then found = true end
    end
    expect(found).toBeTrue()
  end)

  it("does not throw when darkshade is cured on a virgin profile", function()
    fresh()
    ataxia.afflictions = { darkshade = true }
    gmcp.Char.Afflictions.Remove = { "darkshade" }
    expect(pcall(lostAff)).toBeTrue()
  end)

  it("still raises 'aff cured' on the way out", function()
    fresh()
    mock.raised_events = {}
    ataxia.afflictions = { darkshade = true }
    gmcp.Char.Afflictions.Remove = { "darkshade" }
    lostAff()
    local found = false
    for _, e in ipairs(mock.raised_events) do
      if e.name == "aff cured" then found = true end
    end
    expect(found).toBeTrue()
  end)

  it("keeps the timer id and the one-shot latch OFF the serialized namespace", function()
    fresh()
    gmcp.Char.Afflictions.Add = { name = "darkshade" }
    gotAff()
    -- `ataxia` is saved wholesale and deepMerged back with an unconditional dst[k] = v,
    -- so a persisted `prioritized = true` would reload with no timer alive to reset it.
    expect(ataxia.darkshadeTracker.timerId).toBe(nil)
    expect(ataxia.darkshadeTracker.prioritized).toBe(nil)
    expect(ataxiaTemp.darkshadeTimer ~= nil).toBeTrue()
  end)

  it("clears the transient state again when the affliction is cured", function()
    fresh()
    gmcp.Char.Afflictions.Add = { name = "darkshade" }
    gotAff()
    ataxia.afflictions = { darkshade = true }
    gmcp.Char.Afflictions.Remove = { "darkshade" }
    lostAff()
    expect(ataxiaTemp.darkshadeTimer).toBe(nil)
    expect(ataxiaTemp.darkshadePrioritized).toBe(nil)
  end)

  it("honours a user-configured threshold if one was saved", function()
    fresh()
    ataxia.darkshadeTracker = { threshold = 9 }
    gmcp.Char.Afflictions.Add = { name = "darkshade" }
    gotAff()
    expect(ataxia.darkshadeTracker.threshold).toBe(9) -- config survives, state does not
  end)
end)

-- ============================================================================
-- v4.7.257 -- Truthseeker: there are no hidden afflictions to count
-- ============================================================================
--
-- User: "When we have this boon, the ? in our prompt isnt true." The cosmetic half is the
-- least of it -- `ataxia.afflictions.unknown` is a counter that only goes UP in
-- gotUnknownAff, and S._afflicted() reads it as a real affliction, so a phantom count wedges
-- the Mnemosyne recovery gate shut for the rest of the run.
describe("Truthseeker suppresses the unknown-affliction counter", function()
  local realSend, sent

  -- gotUnknownAff's NON-boon path arms a tempLineTrigger, which the mock does not provide.
  -- Without this stub a deliberate break errors out mid-test, `restore()` never runs, and the
  -- overridden `send` leaks into every file that runs after us -- which is exactly what
  -- happened the first time these were broken back (15 unrelated failures).
  -- Counting stub: gotUnknownAff does not increment directly, it ARMS a line trigger that
  -- calls confirmedUnknownAff on the next line. So "did it record anything" has to be asked as
  -- "did it arm the trigger" -- asserting on the counter alone passes whether or not the guard
  -- exists, because the increment has not happened yet either way.
  local armed = 0
  local realTLT = tempLineTrigger

  local function fresh(boon)
    -- Restore defensively at the START too: an errored test never reaches its restore().
    if realSend then send = realSend end
    armed = 0
    tempLineTrigger = function() armed = armed + 1; return 0 end
    ataxia = ataxia or {}
    ataxia.afflictions = {}
    ataxia.vitals = { hp = 100, maxhp = 200, mp = 100, maxmp = 200 }
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.lokiCheck = nil
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.enabled = false
    sent_diagnose = nil
    mnemTruthseeker = boon and true or false
    realSend, sent = send, {}
    send = function(c) table.insert(sent, c) end
  end
  local function restore()
    send = realSend
    mnemTruthseeker = false
    -- Never leave our counting stub for the next file. The mock has no tempLineTrigger, so
    -- restore a plain no-op rather than nil -- reinstating nil is what made the first attempt
    -- error on its own second test.
    tempLineTrigger = realTLT or function() return 0 end
  end

  it("counts hidden afflictions normally without the boon", function()
    fresh(false)
    line = "You are confused as to the effects of the venom."
    confirmedUnknownAff()
    expect(ataxia.afflictions.unknown).toBe(1)
    restore()
  end)

  it("does not even arm the capture while the boon is held", function()
    fresh(false)
    gotUnknownAff()
    expect(armed).toBe(1)              -- normally it arms the next-line capture...
    fresh(true)
    gotUnknownAff()
    expect(armed).toBe(0)              -- ...and under the boon it does not
    expect(ataxia.afflictions.unknown).toBe(nil)
    restore()
  end)

  -- Claimed mid-run, or re-latched from the BOONS list after a reload: phantoms have already
  -- banked, and the flag alone would only stop NEW ones.
  it("clears phantoms banked before the boon latched", function()
    fresh(false)
    ataxia.afflictions.unknown = 20   -- roughly what the screenshot showed
    mnemTruthseeker = true
    gotUnknownAff()
    expect(ataxia.afflictions.unknown).toBe(nil)
    restore()
  end)

  -- The `>= 2` branch fires a queued diagnose; under the boon there is nothing to diagnose.
  it("does not spam diagnose for afflictions that were never hidden", function()
    fresh(true)
    ataxiaBasher.enabled = true
    for _ = 1, 5 do gotUnknownAff() end
    local diag = false
    for _, c in ipairs(sent) do if c:find("diagnose", 1, true) then diag = true end end
    expect(diag).toBeFalse()
    restore()
  end)

  it("still diagnoses without the boon", function()
    fresh(false)
    ataxiaBasher.enabled = true
    line = "You are confused as to the effects of the venom."
    confirmedUnknownAff()
    confirmedUnknownAff()
    local diag = false
    for _, c in ipairs(sent) do if c:find("diagnose", 1, true) then diag = true end end
    expect(diag).toBeTrue()
    restore()
  end)
end)
