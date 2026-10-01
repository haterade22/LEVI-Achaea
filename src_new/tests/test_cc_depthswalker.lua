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

  it("LOCK climbs degeneration toward paralysis while hypochondria waits on impatience", function()
    fresh("lock")
    dw.state.haveShadow = true
    affs({ "clumsiness", "timeloop", "anorexia", "hypochondria" })
    expect(dw.selectInstill()).toBe("degeneration")
  end)

  it("LOCK rebuilds hypochondria when it is cured before impatience lands (v4.7.371)", function()
    -- Impatience is a delayed HYPOCHONDRIA symptom; lose hypochondria and the
    -- route's only impatience source is gone.
    fresh("lock")
    dw.state.haveShadow = true
    affs({ "clumsiness", "timeloop", "anorexia" })
    expect(dw.selectInstill()).toBe("depression")
  end)

  it("LOCK stops guarding hypochondria once impatience has landed", function()
    fresh("lock")
    dw.state.haveShadow = true
    affs({ "clumsiness", "timeloop", "anorexia", "impatience" })
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

  it("DICTATE fires retribution once its four amplifiers are up", function()
    fresh("dictate")
    dw.state.haveShadow = true
    affs({ "clumsiness", "timeloop", "justice", "retribution",
      "depression", "shadowmadness", "parasite" })
    expect(dw.selectInstill()).toBe("retribution")
    expect(dw.capstoneReady("retribution")).toBeTrue()
  end)

  it("DICTATE rebuilds a fallen amplifier before cashing retribution (v4.7.371)", function()
    fresh("dictate")
    dw.state.haveShadow = true
    local base = { "clumsiness", "timeloop", "justice", "retribution" }
    local function with(extra)
      local l = {}
      for _, a in ipairs(base) do l[#l + 1] = a end
      for _, a in ipairs(extra) do l[#l + 1] = a end
      return l
    end
    affs(with({ "shadowmadness", "parasite" }))
    expect(dw.selectInstill()).toBe("depression")
    affs(with({ "depression", "parasite" }))
    expect(dw.selectInstill()).toBe("madness")
    affs(with({ "depression", "shadowmadness" }))
    expect(dw.selectInstill()).toBe("leach")
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

  it("no packet ever contains SHADOW CLAIM; the leach capstone stays selected", function()
    -- SHADOW CLAIM is not a command: the leach capstone strike claims the
    -- shadow. v4.7.365 briefly wired a synthetic claim packet.
    expect(dw.needClaimShadow).toBeNil()
    for _, mode in ipairs({ "lock", "damage", "dictate", "madpression", "group" }) do
      fresh(mode)
      php, pm = 100, 100
      affs({ "clumsiness", "parasite", "healthleech", "manaleech" })
      dw.selections.instill = dw.selectInstill()
      expect(dw.selections.instill).toBe("leach")
      dw.selections.venom = dw.selectVenom()
      dw.selections.useTimeloop = false
      expect(dw.buildAttack():find("shadow claim", 1, true) == nil).toBeTrue()
    end
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

describe("CC_Depthswalker -- Dictate, the opening latch, Assess (v4.7.366)", function()

  it("Dictate's threshold counts only depression, madness, retribution, parasite", function()
    affs({ "healthleech", "manaleech", "justice", "timeloop", "clumsiness" })
    expect(dw.getDictateThreshold()).toBe(40)
    affs({ "depression", "shadowmadness", "retribution", "parasite",
      "healthleech", "manaleech", "justice", "timeloop" })
    expect(dw.getDictateThreshold()).toBe(60)
  end)

  it("a low-confidence affliction does not raise the Dictate threshold", function()
    affs({ "depression" })
    local oldP = getAffProbabilityV3
    getAffProbabilityV3 = function(aff) return aff == "depression" and 0.4 or 0 end
    local okT, errT = pcall(function()
      expect(dw.getDictateThreshold()).toBe(40)
    end)
    getAffProbabilityV3 = oldP
    if not okT then error(errT) end
  end)

  it("the opening latch drops when the foundation is cured down", function()
    fresh("lock")
    dw.state.haveShadow = true
    affs({ "clumsiness", "justice", "retribution", "timeloop" })
    expect(dw.selectInstillOpening()).toBeNil()
    expect(dw.state.bellwortComplete).toBeTrue()
    -- They cure three of the four: rebuild rather than keep finishing.
    affs({ "timeloop" })
    expect(dw.selectInstillOpening()).toBe("degeneration")
    expect(dw.state.bellwortComplete).toBeFalse()
  end)

  it("the latch holds while two of the foundation remain", function()
    fresh("lock")
    dw.state.haveShadow = true
    dw.state.bellwortComplete = true
    affs({ "clumsiness", "justice" })
    expect(dw.selectInstillOpening()).toBeNil()
    expect(dw.state.bellwortComplete).toBeTrue()
  end)

  it("assess is appended only when configured", function()
    fresh("lock")
    php, pm = 100, 100
    affs({})
    dw.selections.instill = "degeneration"
    dw.selections.venom = "curare"
    dw.selections.useTimeloop = false
    local was = dw.config.assess
    local okT, errT = pcall(function()
      dw.config.assess = true
      expect(dw.buildAttack()).toContain("assess Victim")
      dw.config.assess = false
      local atk = dw.buildAttack()
      expect(atk:find("assess", 1, true) == nil).toBeTrue()
      expect(atk).toContain("contemplate Victim")
      expect(dw.handleShield():find("assess", 1, true) == nil).toBeTrue()
    end)
    dw.config.assess = was
    if not okT then error(errT) end
  end)
end)

describe("CC_Depthswalker -- audit v1.1 (v4.7.371)", function()

  it("the boosted leach conversion needs high confidence in healthleech", function()
    fresh("lock")
    affs({ "clumsiness", "parasite", "healthleech" })
    dw.selections.instill = "leach"
    dw.selections.phase = "shadow"
    local oldCan, oldP = dw.canTimeloop, getAffProbabilityV3
    dw.canTimeloop = function() return true end
    local okT, errT = pcall(function()
      expect(dw.shouldTimeloop()).toBeTrue()
      -- Healthleech only a 40% branch: do not spend the venom slot on it.
      getAffProbabilityV3 = function(aff)
        if aff == "healthleech" then return 0.4 end
        return _affs[aff] and 1 or 0
      end
      expect(dw.shouldTimeloop()).toBeFalse()
    end)
    dw.canTimeloop, getAffProbabilityV3 = oldCan, oldP
    if not okT then error(errT) end
  end)

  it("the boredom line (414) records impatience only -- no back-filled hypochondria chain", function()
    local fh = assert(io.open("src_new/triggers/levi_ataxia/for_levi/leviticus/414_Impatience_1.lua", "r"))
    local src = fh:read("*a")
    fh:close()
    local body = src:match("%]%]%-%-\r?\n(.*)$")
    local chunk = assert((loadstring or load)(body))
    local added = {}
    local stubs = {
      matches = { "Victim shuffles his feet in boredom.", "Victim" },
      isTargeted = function() return true end,
      tarAffed = function(...) for _, a in ipairs({ ... }) do added[#added + 1] = a end end,
      onTargetImpatienceV3 = function() end,
      selectString = function() end, fg = function() end, resetFormat = function() end,
      ataxia_isClass = function(c) return c == "depthswalker" end,   -- the old branch's gate
      line = "Victim shuffles his feet in boredom.",
    }
    local saved = {}
    for k, v in pairs(stubs) do saved[k] = _G[k]; _G[k] = v end
    local okT, errT = pcall(chunk)
    for k in pairs(stubs) do _G[k] = saved[k] end
    if not okT then error(errT) end
    expect(#added).toBe(1)
    expect(added[1]).toBe("impatience")
  end)

  it("with dwattune off, attune is sent once and committed only when the reap lands", function()
    fresh("lock")
    php, pm = 100, 100
    affs({})
    dw.selections.instill = "degeneration"
    dw.selections.venom = "curare"
    dw.selections.useTimeloop = false
    dw.selections.attune = "degeneration"
    dw.state.attunedTo, dw.state.attunedAt, dw.state.attunePending = nil, nil, nil
    local was = dw.config.attuneEvery
    local okT, errT = pcall(function()
      dw.config.attuneEvery = false
      now = 1000
      expect(dw.buildAttack()).toContain("shadow attune Victim to degeneration")
      -- A rebuild before the packet fired must STILL carry the attune.
      expect(dw.buildAttack()).toContain("shadow attune Victim to degeneration")
      dw.onReapLanded()
      expect(dw.buildAttack():find("shadow attune", 1, true) == nil).toBeTrue()
      -- A different directive re-attunes.
      dw.selections.attune = "madness"
      expect(dw.buildAttack()).toContain("shadow attune Victim to madness")
      dw.onReapLanded()
      -- The refresh backstop re-attunes after attuneRefresh seconds.
      now = 1000 + dw.config.attuneRefresh + 1
      expect(dw.buildAttack()).toContain("shadow attune Victim to madness")
      -- And the default re-sends every time.
      dw.config.attuneEvery = true
      now = 1000
      dw.onReapLanded()
      expect(dw.buildAttack()).toContain("shadow attune Victim to madness")
    end)
    dw.config.attuneEvery = was
    dw.selections.attune = "degeneration"
    now = 1000
    if not okT then error(errT) end
  end)
end)

-- Run a trigger file's Lua body with the given globals stubbed (restored after).
local TRG = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
local function runTrigger(path, stubs)
  local fh = assert(io.open(path, "r"))
  local src = fh:read("*a")
  fh:close()
  local body = src:match("%]%]%-%-\r?\n(.*)$")
  local chunk = assert((loadstring or load)(body))
  local saved = {}
  for k, v in pairs(stubs) do saved[k] = _G[k]; _G[k] = v end
  local okT, errT = pcall(chunk)
  for k in pairs(stubs) do _G[k] = saved[k] end
  if not okT then error(errT) end
end
local function noop() end

describe("CC_Depthswalker -- deep review fixes (v4.7.372)", function()

  it("no timeloop in the kelp or shadow phase, so the opening latch cannot fire early", function()
    -- The regression: round 1 looped degeneration, timeloop + clumsiness then
    -- read as a standing foundation and LOCK skipped the shadow entirely.
    local oldCan = dw.canTimeloop
    dw.canTimeloop = function() return true end
    local okT, errT = pcall(function()
      for _, mode in ipairs({ "lock", "dictate", "madpression" }) do
        fresh(mode)
        affs({})
        dw.selections.instill = dw.selectInstill()
        expect(dw.selections.phase).toBe("kelp")
        expect(dw.shouldTimeloop()).toBeFalse()
        affs({ "clumsiness" })
        dw.selections.instill = dw.selectInstill()
        expect(dw.selections.phase).toBe("shadow")
        expect(dw.shouldTimeloop()).toBeFalse()
      end
    end)
    dw.canTimeloop = oldCan
    if not okT then error(errT) end
  end)

  it("clumsiness + timeloop with no shadow still goes to the shadow phase", function()
    fresh("lock")
    affs({ "clumsiness", "timeloop" })
    expect(dw.selectInstill()).toBe("leach")
    expect(dw.state.bellwortComplete).toBeFalse()
  end)

  it("a latched opening re-opens when the shadow is gone", function()
    fresh("lock")
    dw.state.bellwortComplete = true
    dw.state.haveShadow = false
    affs({ "clumsiness", "justice", "retribution", "timeloop" })
    expect(dw.selectInstill()).toBe("leach")
    expect(dw.state.bellwortComplete).toBeFalse()
  end)

  it("LOCK cycles depression, not degeneration capstones, once paralysis is up", function()
    fresh("lock")
    dw.state.haveShadow = true
    affs({ "clumsiness", "weariness", "paralysis", "timeloop", "anorexia", "impatience" })
    expect(dw.capstoneReady("degeneration")).toBeTrue()
    expect(dw.selectInstill()).toBe("depression")
  end)

  it("Dictate maintenance uses the rung triggers' 30% test, not 0.7", function()
    -- At 0.5, the trigger would record the NEXT rung on a re-sent depression.
    fresh("dictate")
    dw.state.haveShadow = true
    affs({ "clumsiness", "timeloop", "justice", "retribution", "depression", "shadowmadness", "parasite" })
    local oldP = getAffProbabilityV3
    getAffProbabilityV3 = function(aff)
      if aff == "depression" then return 0.5 end
      return _affs[aff] and 1 or 0
    end
    local okT, errT = pcall(function()
      expect(dw.selectInstill()).toBe("retribution")
      expect(dw.getDictateThreshold()).toBe(55)   -- the threshold still counts at 0.7
    end)
    getAffProbabilityV3 = oldP
    if not okT then error(errT) end
  end)

  it("boosted chrono only in the shadow phase", function()
    affs({ "parasite", "healthleech" })
    dw.selections.useTimeloop = true
    local oldU = dw.canUnboostedLoop
    dw.canUnboostedLoop = function() return true end
    local okT, errT = pcall(function()
      dw.selections.phase = "shadow"
      expect(dw.getChronoCommand()).toBe("chrono loop boost")
      dw.selections.phase = "bellwort"
      expect(dw.getChronoCommand()).toBe("chrono loop")
    end)
    dw.canUnboostedLoop = oldU
    dw.selections.useTimeloop = false
    if not okT then error(errT) end
  end)

  it("cull and mutilate record the curare they actually send", function()
    fresh("lock")
    affs({})
    dw.selections.instill = "degeneration"
    dw.selections.venom = "kalmia"
    envenomList = { "kalmia" }
    php, pm = 30, 100
    expect(dw.buildAttack()).toContain("shadow cull Victim curare")
    expect(envenomList[1]).toBe("curare")
    -- Mutilate needs pm <= 30, but Dictate (checked first) fires at <= 40, so
    -- in play mutilate is unreachable (pre-existing ordering, reported); stub
    -- Dictate off to exercise the mutilate packet itself.
    dw.state.haveShadow = true
    envenomList = { "kalmia" }
    php, pm = 35, 25
    local oldD = dw.needDictate
    dw.needDictate = function() return false end
    local okT, errT = pcall(function()
      expect(dw.buildAttack()).toContain("shadow mutilate Victim curare")
      expect(envenomList[1]).toBe("curare")
    end)
    dw.needDictate = oldD
    php, pm = 100, 100
    if not okT then error(errT) end
  end)

  it("a target change clears the shadow and the stale mana/health readings", function()
    local oldSend, oldQ, oldHold = send, depthswalkerQueue, reboundHold
    send = noop
    reboundHold = nil
    local okT, errT = pcall(function()
      fresh("lock")
      affs({})
      dw.state.lastTarget = "Previous"
      haveshadow = true
      php, pm = 20, 20
      dw.dispatch()
      expect(haveshadow).toBeFalse()
      expect(dw.state.haveShadow).toBeFalse()
      expect(pm).toBe(100)
    end)
    send, depthswalkerQueue, reboundHold = oldSend, oldQ, oldHold
    if not okT then error(errT) end
  end)

  it("trigger 476 (depression capstone) does not re-add hypochondria or nausea", function()
    local added = {}
    runTrigger(TRG .. "476_Depression_Fully_Stacked!.lua", {
      matches = { "A look of total despair crosses the face of Victim.", "Victim" },
      isTargeted = function() return true end,
      tarAffed = function(...) for _, a in ipairs({ ... }) do added[a] = true end end,
      selectString = noop, fg = noop, bg = noop, setBold = noop, resetFormat = noop,
    })
    expect(added.anorexia).toBeTrue()
    expect(added.masochism).toBeTrue()
    expect(added.hypochondria).toBeNil()
    expect(added.nausea).toBeNil()
  end)

  it("trigger 478 sets haveshadow only for our target, and echoes once", function()
    local echoes, prev = 0, haveshadow
    local stubs = {
      matches = { "You claim the shadow of Other, storing it within your phylactery.", "Other" },
      isTargeted = function(n) return n == "Victim" end,
      tarAffed = noop, selectString = noop, fg = noop, bg = noop, setBold = noop, resetFormat = noop,
      ataxia_boxEcho = function() echoes = echoes + 1 end,
    }
    haveshadow = false
    runTrigger(TRG .. "478_Shadow_Stolen.lua", stubs)
    expect(haveshadow).toBeFalse()
    stubs.matches = { "You claim the shadow of Victim, storing it within your phylactery.", "Victim" }
    runTrigger(TRG .. "478_Shadow_Stolen.lua", stubs)
    expect(haveshadow).toBeTrue()
    expect(echoes).toBe(1)
    haveshadow = prev
  end)

  it("trigger 390 (smoke) leaves the cure to V3 -- no second legacy removal", function()
    local erased = {}
    runTrigger(TRG .. "390_Smoked.lua", {
      matches = { "Victim takes a long drag off his pipe.", "Victim" },
      isTargeted = function() return true end,
      onSmokeCureV3 = noop, onTargetSmokeV2 = false,
      erAff = function(a) erased[#erased + 1] = a end,
      haveAff = function() return false end,
      tAffs = { aeon = true, slickness = true },
      tempTimer = noop, ataxiaEcho = noop, ataxiaTemp = {},
    })
    -- Only the asthma proof; aeon/slickness are V3's to branch over.
    expect(#erased).toBe(1)
    expect(erased[1]).toBe("asthma")
  end)

  it("trigger 398 (focus) leaves the cure to V3 -- no erAff/tFocused on top", function()
    local erased, v3 = {}, 0
    runTrigger(TRG .. "398_Focus_(UNK).lua", {
      matches = { "A look of extreme focus crosses the face of Victim.", "Victim" },
      isTargeted = function() return true end,
      tBals = { focus = true, timers = {} },
      onTargetFocusV3 = function() v3 = v3 + 1 end,
      erAff = function(a) erased[#erased + 1] = a end,
      tFocused = function() erased[#erased + 1] = "tFocused" end,
      haveAff = function() return false end,
      tempTimer = noop, killTimer = noop,
    })
    expect(v3).toBe(1)
    expect(#erased).toBe(0)
  end)

  it("trigger 491 (full retribution) survives an empty venom list and ignores other targets", function()
    local added, sent = 0, 0
    local stubs = {
      matches = { "line", "Victim" },
      isTargeted = function(n) return n == "Victim" end,
      tarAffed = function() added = added + 1 end,
      send = function() sent = sent + 1 end,
      envenomList = {}, partyrelay = true, tloop = false, tloop2 = false,
    }
    runTrigger(TRG .. "491_Full_Retribution.lua", stubs)
    expect(added).toBe(2)
    expect(sent).toBe(1)
    stubs.matches = { "line", "Other" }
    runTrigger(TRG .. "491_Full_Retribution.lua", stubs)
    expect(added).toBe(2)
  end)

  it("trigger 486 (cull) honours dwassess", function()
    local sent = {}
    local stubs = {
      matches = { "line", "Victim" },
      isTargeted = function() return true end,
      envenomList = {}, tarAffed = noop, disableTimer = noop,
      haveAff = function() return false end,
      send = function(c) sent[#sent + 1] = c end,
    }
    local was = dw.config.assess
    local okT, errT = pcall(function()
      dw.config.assess = false
      runTrigger(TRG .. "486_Cull.lua", stubs)
      expect(sent[1]).toBe("contemplate Victim")
      dw.config.assess = true
      runTrigger(TRG .. "486_Cull.lua", stubs)
      expect(sent[2]).toContain("assess Victim")
    end)
    dw.config.assess = was
    if not okT then error(errT) end
  end)
end)

-- Restore every global this file replaced (one shared Lua state).
for k, v in pairs(saved) do _G[k] = v end
