--- test_denizen_parry.lua — Denizen pattern parry predictor (self_limb_tracking/005)
-- Pure-logic tests for ataxia_denizenParryObserve / ataxia_denizenParryPredict against the
-- axe-wielding revenant cycle (right leg x2 -> left leg x2 -> torso x2, two perceive lines
-- per swing).

require("mock_mudlet")

-- Controllable clock: the module reads getEpoch() when available.
local now = 1000
function getEpoch() return now end

ataxiaBasher = { enabled = true }
secondTarget = "an axe-wielding revenant"
selfLimbDamage = {}

local file = "src_new/scripts/levi_ataxia/levi/ataxia/self_limb_tracking/005_Denizen_Parry_Patterns.lua"
local ok, err = pcall(dofile, file)
if not ok then error("Failed to load denizen-parry file: " .. tostring(err)) end

-- One swing = two perceive lines close together, then time advances to the next round.
local function swing(limb)
  ataxia_denizenParryObserve(limb)
  now = now + 0.1
  ataxia_denizenParryObserve(limb)
  now = now + 2.5
end

local function freshMob()
  -- Simulate a brand-new engagement: pattern state goes stale, then a new fight starts.
  now = now + 100
  secondTarget = "an axe-wielding revenant"
end

describe("ataxia_denizenParryPredict — axe-wielding revenant cycle", function()
  it("predicts the cycle opener (right leg) before any swing lands", function()
    freshMob()
    expect(ataxia_denizenParryPredict()).toBe("right leg")
  end)

  it("predicts right leg again after the first right-leg swing (pairs)", function()
    freshMob()
    swing("right leg")
    expect(ataxia_denizenParryPredict()).toBe("right leg")
  end)

  it("does not double-count the two perceive lines of one swing", function()
    freshMob()
    ataxia_denizenParryObserve("right leg")
    now = now + 0.1
    ataxia_denizenParryObserve("right leg") -- same swing, 0.1s later
    expect(ataxia_denizenParryPredict()).toBe("right leg") -- count 1 -> repeat, not advance
    now = now + 2.5
  end)

  it("advances to left leg after the right-leg pair completes", function()
    freshMob()
    swing("right leg")
    swing("right leg")
    expect(ataxia_denizenParryPredict()).toBe("left leg")
  end)

  it("walks the full cycle and wraps torso -> right leg", function()
    freshMob()
    swing("right leg") swing("right leg")
    swing("left leg")
    expect(ataxia_denizenParryPredict()).toBe("left leg")
    swing("left leg")
    expect(ataxia_denizenParryPredict()).toBe("torso")
    swing("torso")
    expect(ataxia_denizenParryPredict()).toBe("torso")
    swing("torso")
    expect(ataxia_denizenParryPredict()).toBe("right leg") -- wrap
  end)

  it("still predicts the NEXT limb when a limb gets an extra third swing", function()
    freshMob()
    swing("left leg") swing("left leg") swing("left leg") -- drift seen in live logs
    expect(ataxia_denizenParryPredict()).toBe("torso")
  end)

  it("returns the opener again once the pattern goes stale", function()
    freshMob()
    swing("torso")
    now = now + 60 -- mob died / we left; well past STALE_AFTER
    expect(ataxia_denizenParryPredict()).toBe("right leg")
  end)

  it("returns nil for a mob with no pattern", function()
    freshMob()
    secondTarget = "a lean dirangi"
    expect(ataxia_denizenParryPredict()).toBe(nil)
  end)

  it("returns nil when the basher is disabled (PvP never touched)", function()
    freshMob()
    ataxiaBasher.enabled = false
    expect(ataxia_denizenParryPredict()).toBe(nil)
    ataxiaBasher.enabled = true
  end)

  it("resyncs when the observed limb jumps off-pattern-position", function()
    freshMob()
    swing("right leg")
    swing("torso") -- unexpected jump: resync onto torso
    expect(ataxia_denizenParryPredict()).toBe("torso") -- first of the torso pair
    swing("torso")
    expect(ataxia_denizenParryPredict()).toBe("right leg")
  end)
end)

describe("fixed-parry entries — one parryable attack, park the cover there", function()
  it("always predicts the fixed limb, no observation needed", function()
    freshMob()
    secondTarget = "a steel-encased Death Knight"
    expect(ataxia_denizenParryPredict()).toBe("left leg")
    secondTarget = "a ravager of the Infernal Legion"
    expect(ataxia_denizenParryPredict()).toBe("torso")
  end)

  it("keeps predicting the fixed limb regardless of observed hits or staleness", function()
    freshMob()
    secondTarget = "a steel-encased Death Knight"
    ataxia_denizenParryObserve("right arm") -- no-op for fixed entries
    expect(ataxia_denizenParryPredict()).toBe("left leg")
    now = now + 60 -- staleness never applies to a fixed entry
    expect(ataxia_denizenParryPredict()).toBe("left leg")
  end)

  it("observing a fixed-entry mob does not disturb a cycle mob's streak", function()
    freshMob()
    swing("right leg") -- revenant: 1 swing observed -> next prediction repeats right leg
    secondTarget = "a steel-encased Death Knight"
    ataxia_denizenParryObserve("torso") -- ignored: fixed entry
    secondTarget = "an axe-wielding revenant"
    expect(ataxia_denizenParryPredict()).toBe("right leg")
  end)

  it("returns nil (never errors) for a malformed entry with neither fixed nor cycle", function()
    freshMob()
    selfLimbDamage.denizenPatterns["a malformed entry"] = {}
    secondTarget = "a malformed entry"
    expect(ataxia_denizenParryPredict()).toBe(nil)
    selfLimbDamage.denizenPatterns["a malformed entry"] = nil
    secondTarget = "an axe-wielding revenant"
  end)

  it("returns nil for fixed entries too when the basher is disabled", function()
    freshMob()
    secondTarget = "a steel-encased Death Knight"
    ataxiaBasher.enabled = false
    expect(ataxia_denizenParryPredict()).toBe(nil)
    ataxiaBasher.enabled = true
    secondTarget = "an axe-wielding revenant"
  end)
end)
