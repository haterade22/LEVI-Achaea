--- test_bashing_parry.lua — "bashing" parry mode + basher auto-switch (self_limb_tracking/003)
-- Covers ataxia_bashingParry()'s selection ladder (pattern prediction -> focus-follow ->
-- leg default) and the ataxia_bashingParryOn/Off mode swap semantics.

require("mock_mudlet")

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
    selfLimbDamage["left arm"] = { damage = 30 }
    ataxia_bashingParry()
    expect(ataxia.parrying.shouldparry).toBe("left arm")
  end)

  it("does not follow a BROKEN focus limb -- falls to an unbroken leg", function()
    predictedLimb = nil
    selfLimbDamage.lasthit = "left arm"
    brokenLimbs = { ["left arm"] = true }
    ataxia_bashingParry()
    expect(ataxia.parrying.shouldparry).toBe("right leg")
    brokenLimbs = {}
  end)

  it("defaults to right leg before anything is observed", function()
    predictedLimb = nil
    selfLimbDamage.lasthit = "none"
    ataxia_bashingParry()
    expect(ataxia.parrying.shouldparry).toBe("right leg")
  end)

  it("skips broken legs in the default ladder (right -> left -> torso)", function()
    predictedLimb = nil
    selfLimbDamage.lasthit = "none"
    brokenLimbs = { ["right leg"] = true }
    ataxia_bashingParry()
    expect(ataxia.parrying.shouldparry).toBe("left leg")
    brokenLimbs = { ["right leg"] = true, ["left leg"] = true }
    ataxia_bashingParry()
    expect(ataxia.parrying.shouldparry).toBe("torso")
    brokenLimbs = {}
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
