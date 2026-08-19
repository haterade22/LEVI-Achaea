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
    -- Was pinned at 1: the old decoder read the SECOND-TO-LAST character, so this
    -- returned the tens digit. The suffix is the count, however many digits it has.
    ataxia.afflictions = {}
    setStackAff("burning12")
    expect(ataxia.afflictions.burning).toBe(12)
  end)

  it("decodes a SINGLE-digit suffix -- the form Achaea actually sends", function()
    -- The regression that mattered: "burning3" tests "g" under sub(-2,-2), so the whole
    -- stack path was skipped and a boolean was stored under the suffixed key instead.
    ataxia.afflictions = {}
    setStackAff("burning3")
    expect(ataxia.afflictions.burning).toBe(3)
    expect(ataxia.afflictions.burning3).toBeNil()
  end)

  it("resets a stack aff to 0 when num=true", function()
    ataxia.afflictions.burning = 5
    setStackAff("burning12", true)
    expect(ataxia.afflictions.burning).toBe(0)
  end)

  it("treats a BARE stack name as one stack", function()
    ataxia.afflictions = {}
    setStackAff("pressure")
    expect(ataxia.afflictions.pressure).toBe(1)
  end)

  it("writes nothing for a name we do not model as stacking", function()
    -- The old substring scan left tow = "" and wrote ataxia.afflictions[""], a key
    -- rTabSize counts -- so the prompt's affliction bracket printed forever.
    ataxia.afflictions = {}
    setStackAff("totallymadeupaffliction")
    local count = 0
    for _ in pairs(ataxia.afflictions) do count = count + 1 end
    expect(count).toBe(0)
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

  it("stores a SINGLE-digit stack aff under the bare name, not the suffixed one", function()
    -- checkDamnationThreat reads ataxia.afflictions.burning as a level; before this it
    -- was permanently 0 because the count lived under a suffixed boolean key.
    ataxia.afflictions = {}
    gmcp.Char.Afflictions.Add = { name = "burning4" }
    gotAff()
    expect(ataxia.afflictions.burning).toBe(4)
    expect(ataxia.afflictions.burning4).toBeNil()
  end)

  it("raises 'aff gained' with the BARE name for a stack aff", function()
    -- ApplySwaps tests `aff == "burning"` and Stack_My_Affs looks the name up in the herb
    -- tables, which list bare names only -- both were dead while we passed "burning4".
    mock.raised_events = {}
    ataxia.afflictions = {}
    gmcp.Char.Afflictions.Add = { name = "burning4" }
    gotAff()
    local found = false
    for _, e in ipairs(mock.raised_events) do
      if e.name == "aff gained" and e.args and e.args[1] == "burning" then found = true end
    end
    expect(found).toBeTrue()
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

-- ─── affed() and the cured-stack contract ───────────────────────────────────

describe("affed() -- a cured stack is not an affliction", function()
  it("is FALSE for a stacking aff at zero", function()
    -- 0 is TRUTHY in Lua. lostAff zeroes rather than nils (the prompt renderer and
    -- checkDamnationThreat both want a number), and setafflictionstackslevi plants sixteen
    -- zeroes on reset -- so a bare truthiness test reported a burn we had just put out.
    ataxia.afflictions = { burning = 0 }
    expect(affed("burning")).toBeFalse()
  end)

  it("is TRUE for a stacking aff with stacks", function()
    ataxia.afflictions = { burning = 3 }
    expect(affed("burning")).toBeTrue()
  end)

  it("still handles ordinary boolean afflictions", function()
    ataxia.afflictions = { asthma = true }
    expect(affed("asthma")).toBeTrue()
    expect(affed("paralysis")).toBeFalse()
  end)

  it("survives an explicit false", function()
    ataxia.afflictions = { unweavingmind = false }
    expect(affed("unweavingmind")).toBeFalse()
  end)
end)

-- ─── ataxia_stackAff() ──────────────────────────────────────────────────────

describe("ataxia_stackAff() — the base/count decoder", function()
  it("splits a suffixed name into base and count", function()
    local base, n = ataxia_stackAff("burning5")
    expect(base).toBe("burning")
    expect(n).toBe(5)
  end)

  it("handles a multi-digit count", function()
    local base, n = ataxia_stackAff("burning12")
    expect(base).toBe("burning")
    expect(n).toBe(12)
  end)

  it("reads a bare stack name as one stack", function()
    local base, n = ataxia_stackAff("horror")
    expect(base).toBe("horror")
    expect(n).toBe(1)
  end)

  it("is case-insensitive", function()
    expect(ataxia_stackAff("UnweavingMind3")).toBe("unweavingmind")
  end)

  it("returns nil for an affliction that does not stack", function()
    expect(ataxia_stackAff("paralysis")).toBeNil()
    expect(ataxia_stackAff("asthma4")).toBeNil()
  end)

  it("matches the base by EQUALITY, not substring", function()
    -- The old loop used aff:find(x) and kept the LAST match, so any future affliction
    -- whose name merely CONTAINED a stack name decoded as that stack aff.
    expect(ataxia_stackAff("burningaura")).toBeNil()
    expect(ataxia_stackAff("prepressure2")).toBeNil()
  end)

  it("survives a non-string", function()
    expect(ataxia_stackAff(nil)).toBeNil()
    expect(ataxia_stackAff(5)).toBeNil()
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

  it("zeroes a suffixed stack remove that names the level we hold", function()
    ataxia.afflictions = { burning = 3 }
    gmcp.Char.Afflictions.Remove = { "burning3" }
    lostAff()
    expect(ataxia.afflictions.burning).toBe(0)
  end)

  it("IGNORES a suffixed stack remove for a level we have already moved past", function()
    -- A stack CHANGE is Remove(old) + Add(new) and the order is not guaranteed. If the
    -- Add lands first, zeroing on the trailing Remove kills a live stack.
    ataxia.afflictions = { burning = 4 }
    gmcp.Char.Afflictions.Remove = { "burning3" }
    lostAff()
    expect(ataxia.afflictions.burning).toBe(4)
  end)

  it("zeroes on a BARE stack remove regardless of the level held", function()
    ataxia.afflictions = { burning = 5 }
    gmcp.Char.Afflictions.Remove = { "burning" }
    lostAff()
    expect(ataxia.afflictions.burning).toBe(0)
  end)

  it("resets unweavingmind to 0 via a suffixed remove", function()
    ataxia.afflictions = { unweavingmind = 5 }
    gmcp.Char.Afflictions.Remove = { "unweavingmind5" }
    lostAff()
    expect(ataxia.afflictions.unweavingmind).toBe(0)
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
