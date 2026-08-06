--- test_bashing_parry.lua — "bashing" parry mode + basher auto-switch (self_limb_tracking/003)
-- Covers ataxia_bashingParry()'s selection ladder (pattern prediction -> fresh focus-follow ->
-- head default), the ataxia_parrySuccess feed, and the ataxia_bashingParryOn/Off mode swap
-- semantics.

require("mock_mudlet")

-- Controllable clock: 003's freshness check and ataxia_parrySuccess read getEpoch() at call
-- time. Restored at the end of the file (shared test state -- a frozen clock leaking into
-- later suites is the same defect class as the test_swarm_tactics send leak).
local realGetEpoch = getEpoch
local now = 100000
function getEpoch() return now end

-- Globals 003 reads at load/call time.
ataxia = { parrying = { limb = "none", shouldparry = "right leg" }, parry = "stand" }
selfLimbDamage = {
  config = { enabled = true, autoParry = true, parryMode = "bashing" },
  lasthit = "none",
}
brokenLimbs = {}
function ataxia_selfLimbBroken(limb) return brokenLimbs[limb] or false end
function ataxia_selfHitsToBreak() return 10 end
function ataxia_selfLimbPrepped() return false end

-- Predictor stub (005 is exercised by test_denizen_parry); nil = no pattern in play.
predictedLimb = nil
function ataxia_denizenParryPredict() return predictedLimb end

local file = "src_new/scripts/levi_ataxia/levi/ataxia/self_limb_tracking/003_Parrying.lua"
local ok, err = pcall(dofile, file)
if not ok then error("Failed to load parrying file: " .. tostring(err)) end

describe("ataxia_bashingParry — PvE selection ladder", function()
  it("uses the denizen-pattern prediction when one is in play", function()
    predictedLimb = "torso"
    selfLimbDamage.lasthit = "left arm"
    ataxia_bashingParry()
    expect(ataxia.parrying.shouldparry).toBe("torso")
  end)

  it("follows the mob's focus (last hit limb) when no pattern applies", function()
    predictedLimb = nil
    selfLimbDamage.lasthit = "left arm"
    selfLimbDamage.lasthitAt = now
    selfLimbDamage["left arm"] = { damage = 30 }
    ataxia_bashingParry()
    expect(ataxia.parrying.shouldparry).toBe("left arm")
  end)

  -- REQUIREMENT REVERSED, v4.7.221 (Duke Semiro log, 2026-08-06). This used to assert that a
  -- broken focus limb is SKIPPED. That is precisely backwards in PvE: a broken limb that keeps
  -- being hit is how rl1 becomes Rl2 and how BOTH legs end up broken -- the state that refuses
  -- our own attacks outright. In that log the right leg was both the most-attacked parryable
  -- limb and broken most of the time, so the filter excluded exactly the limb worth covering.
  -- The predictive `fixed` path (005) has always parked on a broken limb deliberately; this
  -- brings focus-follow in line with it. Deliberate behaviour change, not a test bent to pass.
  it("DOES follow a broken focus limb -- re-hits are what escalate a break", function()
    predictedLimb = nil
    selfLimbDamage.lasthit = "left arm"
    selfLimbDamage.lasthitAt = now
    selfLimbDamage["left arm"] = { damage = 30 }
    brokenLimbs = { ["left arm"] = true }
    ataxia_bashingParry()
    expect(ataxia.parrying.shouldparry).toBe("left arm")
    brokenLimbs = {}
  end)

  it("ignores a STALE focus limb -- falls to the head default", function()
    predictedLimb = nil
    selfLimbDamage.lasthit = "left arm"
    selfLimbDamage.lasthitAt = now - 13 -- past LASTHIT_STALE_AFTER
    ataxia_bashingParry()
    expect(ataxia.parrying.shouldparry).toBe("head")
  end)

  it("still follows a focus limb exactly at the freshness boundary (<= 12s)", function()
    predictedLimb = nil
    selfLimbDamage.lasthit = "left arm"
    selfLimbDamage.lasthitAt = now - 12
    ataxia_bashingParry()
    expect(ataxia.parrying.shouldparry).toBe("left arm")
  end)

  it("ignores a timestamp-less lasthit (the old group-init seed shape)", function()
    -- Regression: _groups.yaml used to seed lasthit = "left leg" with no timestamp,
    -- pinning the parry there forever. Un-stamped lasthit must never be followed.
    predictedLimb = nil
    selfLimbDamage.lasthit = "left leg"
    selfLimbDamage.lasthitAt = nil
    selfLimbDamage["left leg"] = { damage = 0 }
    ataxia_bashingParry()
    expect(ataxia.parrying.shouldparry).toBe("head")
  end)

  it("defaults to head before anything is observed", function()
    predictedLimb = nil
    selfLimbDamage.lasthit = "none"
    selfLimbDamage.lasthitAt = nil
    ataxia_bashingParry()
    expect(ataxia.parrying.shouldparry).toBe("head")
  end)

  it("skips broken limbs in the default ladder (head -> right leg -> left leg -> torso)", function()
    predictedLimb = nil
    selfLimbDamage.lasthit = "none"
    selfLimbDamage.lasthitAt = nil
    brokenLimbs = { ["head"] = true }
    ataxia_bashingParry()
    expect(ataxia.parrying.shouldparry).toBe("right leg")
    brokenLimbs = { ["head"] = true, ["right leg"] = true }
    ataxia_bashingParry()
    expect(ataxia.parrying.shouldparry).toBe("left leg")
    brokenLimbs = { ["head"] = true, ["right leg"] = true, ["left leg"] = true }
    ataxia_bashingParry()
    expect(ataxia.parrying.shouldparry).toBe("torso")
    brokenLimbs = {}
  end)
end)

describe("ataxia_parrySuccess — confirmed-parry feed", function()
  it("refreshes focus-follow and syncs the confirmed parry limb", function()
    selfLimbDamage["torso"] = { damage = 0 }
    ataxia.parrying.limb = "none"
    ataxia_parrySuccess("torso")
    expect(selfLimbDamage.lasthit).toBe("torso")
    expect(selfLimbDamage.lasthitAt).toBe(now)
    expect(ataxia.parrying.limb).toBe("torso")
  end)

  it("feeds the denizen-pattern observer", function()
    local observed = nil
    function ataxia_denizenParryObserve(limb) observed = limb end
    selfLimbDamage["torso"] = { damage = 0 }
    ataxia_parrySuccess("torso")
    expect(observed).toBe("torso")
    ataxia_denizenParryObserve = nil
  end)

  it("ignores unknown limb text (defensive against wording drift)", function()
    selfLimbDamage.lasthit = "none"
    ataxia_parrySuccess("left hand")
    expect(selfLimbDamage.lasthit).toBe("none")
  end)

  it("no-ops when SLC is disabled", function()
    selfLimbDamage.config.enabled = false
    selfLimbDamage.lasthit = "none"
    selfLimbDamage["torso"] = { damage = 0 }
    ataxia_parrySuccess("torso")
    expect(selfLimbDamage.lasthit).toBe("none")
    selfLimbDamage.config.enabled = true
  end)

  it("a parried swing steers the next bashing-parry pick (integration)", function()
    predictedLimb = nil
    selfLimbDamage["left arm"] = { damage = 0 }
    brokenLimbs = {}
    ataxia_parrySuccess("left arm")
    ataxia_bashingParry()
    expect(ataxia.parrying.shouldparry).toBe("left arm")
  end)
end)

-- FREQUENCY OVER LAST-HIT (v4.7.221). Driven by the Duke Semiro log, 2026-08-06: over ~20
-- swings he interleaved right leg x5, torso x4 and left leg x1, and exactly TWO parries landed.
-- Following the most recent hit is the worst possible rule against a mob that spreads -- it
-- parks the cover on the limb he has just finished with, permanently one swing behind.
describe("ataxia_bashingParryFocus — most-hit wins, recency breaks ties", function()
  local function hist(...)
    selfLimbDamage.hitHistory = { ... }
  end

  it("picks the most-hit limb, not the most recent one", function()
    -- Semiro's actual ratio, oldest -> newest. The LAST hit is the torso -- which is what the
    -- old rule would have covered -- but the right leg is the majority and the limb to cover.
    hist("right leg", "torso", "right leg", "right leg", "right leg", "torso")
    expect(ataxia_bashingParryFocus()).toBe("right leg")
  end)

  it("breaks a tie toward the more recent limb, so a real focus-switch is followed", function()
    hist("torso", "torso", "right leg", "right leg")
    expect(ataxia_bashingParryFocus()).toBe("right leg")
  end)

  it("degrades to the last hit when there is no history yet", function()
    selfLimbDamage.hitHistory = {}
    selfLimbDamage.lasthit = "left arm"
    expect(ataxia_bashingParryFocus()).toBe("left arm")
    -- ...and to nothing at all when there is not even that: the caller falls to the ladder.
    selfLimbDamage.lasthit = "none"
    expect(ataxia_bashingParryFocus()).toBe(nil)
  end)

  it("ignores junk entries rather than counting them", function()
    hist("none", "", "torso")
    expect(ataxia_bashingParryFocus()).toBe("torso")
  end)

  it("drives the full selection when the focus is fresh", function()
    predictedLimb = nil
    hist("right leg", "torso", "right leg", "torso", "right leg")
    selfLimbDamage.lasthit = "torso"
    selfLimbDamage.lasthitAt = now
    selfLimbDamage["right leg"] = { damage = 30 }
    ataxia_bashingParry()
    expect(ataxia.parrying.shouldparry).toBe("right leg")
  end)

  it("still ignores the whole history once it is stale", function()
    predictedLimb = nil
    hist("right leg", "right leg", "right leg")
    selfLimbDamage.lasthit = "right leg"
    selfLimbDamage.lasthitAt = now - 13 -- past LASTHIT_STALE_AFTER
    ataxia_bashingParry()
    expect(ataxia.parrying.shouldparry).toBe("head")
  end)

  -- A parried swing emits NO "dealt N% damage" perceive line, so it never reaches
  -- ataxia_raiseLimbDamage. If the history counted only unparried hits it would under-count
  -- exactly the limb the parry is succeeding on, and the frequency pick would drift off it the
  -- moment it started working -- the parry would sabotage itself.
  it("counts parried swings too, so a working parry does not un-elect its own limb", function()
    selfLimbDamage.hitHistory = {}
    selfLimbDamage["right leg"] = { damage = 0 }
    ataxia_recordSelfHit = ataxia_recordSelfHit or function(l)
      selfLimbDamage.hitHistory[#selfLimbDamage.hitHistory + 1] = l
    end
    ataxia_parrySuccess("right leg")
    ataxia_parrySuccess("right leg")
    expect(#selfLimbDamage.hitHistory).toBe(2)
    expect(ataxia_bashingParryFocus()).toBe("right leg")
  end)
end)

describe("ataxia_bashingParryOn/Off — basher auto-switch", function()
  local cfg = selfLimbDamage.config

  it("switches to bashing on basher-enable and remembers the prior mode", function()
    cfg.parryMode = "stand"
    cfg.parryModeSaved = nil
    ataxia_bashingParryOn()
    expect(cfg.parryMode).toBe("bashing")
    expect(cfg.parryModeSaved).toBe("stand")
    expect(ataxia.parry).toBe("bashing")
  end)

  it("restores the remembered mode on basher-disable", function()
    ataxia_bashingParryOff()
    expect(cfg.parryMode).toBe("stand")
    expect(cfg.parryModeSaved).toBe(nil)
    expect(ataxia.parry).toBe("stand")
  end)

  it("never hijacks manual mode", function()
    cfg.parryMode = "manual"
    ataxia_bashingParryOn()
    expect(cfg.parryMode).toBe("manual")
    cfg.parryMode = "stand"
  end)

  it("is idempotent: a second enable does not clobber the saved mode", function()
    cfg.parryMode = "auto"
    ataxia_bashingParryOn()
    ataxia_bashingParryOn()
    expect(cfg.parryModeSaved).toBe("auto")
    ataxia_bashingParryOff()
    expect(cfg.parryMode).toBe("auto")
  end)

  it("disable is a no-op when the mode was changed away mid-bash", function()
    cfg.parryMode = "defend" -- user picked a mode manually while bashing
    cfg.parryModeSaved = "stand"
    ataxia_bashingParryOff()
    expect(cfg.parryMode).toBe("defend") -- their choice sticks
    cfg.parryModeSaved = nil
  end)

  it("respects the bashingParryAuto opt-out (nil counts as ON)", function()
    cfg.parryMode = "stand"
    cfg.bashingParryAuto = false
    ataxia_bashingParryOn()
    expect(cfg.parryMode).toBe("stand")
    cfg.bashingParryAuto = nil
    ataxia_bashingParryOn()
    expect(cfg.parryMode).toBe("bashing")
    ataxia_bashingParryOff()
  end)
end)

-- Hand the shared test state a live clock back (frozen-clock leaks fail later suites the
-- same way the unrestored send override did in test_swarm_tactics).
getEpoch = realGetEpoch or os.time
