--- test_cc_depthswalker.lua -- Depthswalker PvP offense (015_CC_Depthswalker)
-- Pins the v4.7.365 fixes: capstones are PER INSTILL (never a global count of
-- DW afflictions), LOCK takes the shadow phase, and "impatience" is never an
-- instill. Every global replaced here is restored at the end of the file.

local mock = require("mock_mudlet")

local saved = {
  haveAff = haveAff, getEpoch = getEpoch, ataxiaEcho = ataxiaEcho,
  target = target, php = php, pm = pm, haveshadow = haveshadow,
  depthswalkerQueue = depthswalkerQueue, getAffProbabilityV3 = getAffProbabilityV3,
  affConfigV3 = affConfigV3, haveWord = haveWord,
}

local _affs = {}
function haveAff(aff) return _affs[aff] == true end
local function affs(list)
  _affs = {}
  for _, a in ipairs(list or {}) do _affs[a] = true end
end

local now = 1000
function getEpoch() return now end
local echoes = {}
function ataxiaEcho(msg) echoes[#echoes + 1] = msg end
function depthswalkerQueue() return "" end
getAffProbabilityV3 = function(aff) return _affs[aff] and 1 or 0 end
affConfigV3 = nil
haveWord = nil

ataxia = ataxia or {}
ataxia.settings = ataxia.settings or {}
ataxia.settings.separator = ataxia.settings.separator or "::"
target = "Victim"

local ok, err = pcall(dofile, "src_new/scripts/levi_ataxia/levi/levi_scripts/depthswalker/015_CC_Depthswalker.lua")
if not ok then error("Failed to load 015_CC_Depthswalker: " .. tostring(err)) end

local dw = depthswalker

local function fresh(mode)
  dw.state.mode = mode or "lock"
  dw.state.haveShadow = false
  dw.state.bellwortComplete = false
  dw.state.canClaimShadow = false
  dw.state.claimReadyAt = nil
  dw.state.madCapAt = nil
  dw.selections.instill = nil
  dw.selections.phase = "init"
end

describe("CC_Depthswalker -- per-Instill capstone ladders", function()

  it("stages count rungs up to the first missing one", function()
    affs({})
    expect(dw.instillStage("depression")).toBe(0)
    affs({ "depression" })
    expect(dw.instillStage("depression")).toBe(1)
    affs({ "depression", "nausea" })
    expect(dw.instillStage("depression")).toBe(2)
    -- A later rung without an earlier one does not count (the rung triggers
    -- would apply the missing earlier rung next).
    affs({ "nausea", "hypochondria" })
    expect(dw.instillStage("depression")).toBe(0)
  end)

  it("the capstone is ready only once that Instill's own ladder is complete", function()
    affs({ "depression", "nausea" })
    expect(dw.capstoneReady("depression")).toBeFalse()
    expect(dw.hitsToCapstone("depression")).toBe(2)
    affs({ "depression", "nausea", "hypochondria" })
    expect(dw.capstoneReady("depression")).toBeTrue()
    expect(dw.hitsToCapstone("depression")).toBe(1)
  end)

  it("five unrelated DW afflictions do NOT make depression's capstone ready", function()
    -- The reported bug: the old global rule read this as capstone-ready.
    affs({ "depression", "parasite", "healthleech", "justice", "timeloop" })
    expect(dw.countDWAffsInt()).toBe(5)
    expect(dw.capstoneReady("depression")).toBeFalse()
    expect(dw.capstoneReady("leach")).toBeFalse()
  end)

  it("a full ladder is ready even when the global DW count is under five", function()
    affs({ "shadowmadness", "vertigo", "hallucinations" })
    expect(dw.countDWAffsInt() < 5).toBeTrue()
    expect(dw.capstoneReady("madness")).toBeTrue()
  end)

  it("retribution's ladder is two rungs", function()
    affs({ "justice", "retribution" })
    expect(dw.capstoneReady("retribution")).toBeTrue()
  end)

  it("capstoneReady refuses an invalid instill and requires an argument", function()
    affs({ "impatience" })
    expect(dw.capstoneReady("impatience")).toBeFalse()
    expect(dw.capstoneReady()).toBeFalse()
    expect(dw.validInstill("impatience")).toBeFalse()
    expect(dw.validInstill("leach")).toBeTrue()
  end)
end)

describe("CC_Depthswalker -- route selectors", function()

  it("LOCK takes the shadow phase once clumsiness is stuck", function()
    fresh("lock")
    affs({ "clumsiness" })
    expect(dw.selectInstill()).toBe("leach")
    expect(dw.selections.phase).toBe("shadow")
  end)

  it("LOCK fires the leach capstone on a full leach ladder", function()
    fresh("lock")
    affs({ "clumsiness", "parasite", "healthleech", "manaleech" })
    expect(dw.selectInstill()).toBe("leach")
    expect(dw.capstoneReady("leach")).toBeTrue()
  end)

  it("LOCK never selects impatience, even with asthma stuck", function()
    fresh("lock")
    dw.state.haveShadow = true
    affs({ "clumsiness", "asthma", "justice", "retribution", "timeloop" })
    expect(dw.selectInstill()).toBe("depression")
  end)

  it("no route ever returns an invalid instill", function()
    local pool = { "clumsiness", "weariness", "paralysis", "asthma", "anorexia",
      "depression", "nausea", "hypochondria", "shadowmadness", "vertigo",
      "hallucinations", "parasite", "healthleech", "manaleech", "justice",
      "retribution", "timeloop", "impatience", "slickness" }
    local modes = { "lock", "damage", "dictate", "madpression", "group" }
    -- Deterministic sweep over subsets of the pool.
    for seed = 0, 400 do
      local picked = {}
      for i, a in ipairs(pool) do
        if math.floor(seed * 7919 / (i * 3 + 1)) % 2 == 1 then picked[#picked + 1] = a end
      end
      for _, mode in ipairs(modes) do
        for _, shadow in ipairs({ false, true }) do
          fresh(mode)
          dw.state.haveShadow = shadow
          affs(picked)
          local inst = dw.selectInstill()
          if not dw.validInstill(inst) then
            error("mode " .. mode .. " returned invalid instill " .. tostring(inst))
          end
        end
      end
    end
  end)

  it("LOCK fires the depression capstone after its three rungs", function()
    fresh("lock")
    dw.state.haveShadow = true
    affs({ "clumsiness", "timeloop", "depression", "nausea", "hypochondria" })
    expect(dw.selectInstill()).toBe("depression")
    expect(dw.capstoneReady("depression")).toBeTrue()
  end)

  it("LOCK climbs degeneration toward paralysis once anorexia is stuck", function()
    fresh("lock")
    dw.state.haveShadow = true
    affs({ "clumsiness", "timeloop", "anorexia" })
    expect(dw.selectInstill()).toBe("degeneration")
  end)

  it("MADPRESSION opens with madness when both ladders are armed", function()
    fresh("madpression")
    dw.state.haveShadow = true
    affs({ "clumsiness", "timeloop", "depression", "nausea", "hypochondria",
      "shadowmadness", "vertigo", "hallucinations" })
    expect(dw.selectInstill()).toBe("madness")
  end)

  it("MADPRESSION cashes depression inside the madness stun window", function()
    fresh("madpression")
    dw.state.haveShadow = true
    affs({ "clumsiness", "timeloop", "depression", "nausea", "hypochondria",
      "shadowmadness", "vertigo", "hallucinations" })
    now = 1000
    dw.onMadnessCapstone()
    now = 1001
    expect(dw.selectInstill()).toBe("depression")
    now = 1000 + dw.config.madStunWindow + 1
    expect(dw.selectInstill()).toBe("madness")
    now = 1000
  end)

  it("DICTATE fires retribution on its complete ladder", function()
    fresh("dictate")
    dw.state.haveShadow = true
    affs({ "clumsiness", "timeloop", "justice", "retribution" })
    expect(dw.selectInstill()).toBe("retribution")
  end)
end)

describe("CC_Depthswalker -- timeloop and shadow claim", function()

  it("never loops a capstone hit", function()
    fresh("lock")
    dw.state.haveShadow = true
    affs({ "depression", "nausea", "hypochondria" })
    dw.selections.instill = "depression"
    dw.selections.phase = "lock"
    local oldCan = dw.canTimeloop
    dw.canTimeloop = function() return true end
    local okT, errT = pcall(function()
      expect(dw.shouldTimeloop()).toBeFalse()
      affs({})
      expect(dw.shouldTimeloop()).toBeTrue()   -- three rungs to go: double it
      affs({ "depression", "nausea" })
      expect(dw.shouldTimeloop()).toBeFalse()  -- one rung then the capstone
    end)
    dw.canTimeloop = oldCan
    if not okT then error(errT) end
  end)

  it("a leach capstone opens a bounded claim window that the claim closes", function()
    fresh("damage")
    now = 1000
    expect(dw.needClaimShadow()).toBeFalse()
    dw.onLeachCapstone()
    expect(dw.needClaimShadow()).toBeTrue()
    dw.onShadowClaimed()
    expect(dw.needClaimShadow()).toBeFalse()
    dw.onLeachCapstone()
    now = 1000 + dw.config.claimWindow + 1
    expect(dw.needClaimShadow()).toBeFalse()
    now = 1000
  end)

  it("buildAttack never sends an invalid instill", function()
    fresh("lock")
    php, pm = 100, 100
    affs({})
    dw.selections.instill = "impatience"
    dw.selections.venom = "curare"
    dw.selections.useTimeloop = false
    echoes = {}
    local atk = dw.buildAttack()
    expect(atk:find("with impatience", 1, true) == nil).toBeTrue()
    expect(atk).toContain("shadow instill scythe with degeneration")
    expect(#echoes).toBe(1)
  end)
end)

-- Restore every global this file replaced (one shared Lua state).
for k, v in pairs(saved) do _G[k] = v end
