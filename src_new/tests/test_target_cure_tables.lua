--- test_target_cure_tables.lua -- target cure inference matches the game's WHATCURES
-- v4.7.371: the outside DW audit captured WHATCURES for the whole affliction
-- catalogue. getCurableAffs reads the global curingTable (curing/002) FIRST and
-- only falls back to curingTableV3 for a herb curingTable does not list, so a
-- gap in curingTable is a gap in tracking whatever V3 says. These tests load the
-- real tables and the real V3 cure handlers. Every global the loaded files
-- create or change is restored at the end (one shared Lua state).

local before = {}
for k, v in pairs(_G) do before[k] = v end

local files = {
  "src_new/scripts/levi_ataxia/levi/ataxia/curing/002_Wide_Groups.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/007_Branching_State_Tracker.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/008_V3_Integration.lua",
}
for _, f in ipairs(files) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end

-- The game's WHATCURES, per herb/mineral pair. insomnia is deliberately absent
-- from goldenseal: the tracker models it as a target DEFENCE.
local WHATCURES = {
  ash = { "confusion", "crescendo", "dementia", "hallucinations", "hypersomnia", "paranoia" },
  bellwort = { "diminished", "generosity", "indifference", "justice", "lovers", "pacified", "peace",
    "pyre", "retribution", "stridulating", "timeloop" },
  bloodroot = { "paralysis", "pyramides", "slickness" },
  ginseng = { "addiction", "darkshade", "flushings", "haemophilia", "lethargy", "nausea", "scytherus",
    "unweavingbody" },
  goldenseal = { "depression", "dissonance", "dizziness", "epilepsy", "fulminated", "impatience",
    "mycalium", "sandfever", "shadowmadness", "shyness", "stupidity", "unweavingmind" },
  kelp = { "asthma", "clumsiness", "healthleech", "parasite", "rebbies", "sensitivity", "weariness" },
  lobelia = { "agoraphobia", "claustrophobia", "fratricide", "guilt", "horror", "hypochondria",
    "loneliness", "masochism", "recklessness", "spiritburn", "tenderskin", "vertigo", "whisperingmadness" },
}
local SMOKE = { "aeon", "dazed", "deadening", "earworm", "tension", "unweavingspirit",
  "disloyalty", "hellsight", "manaleech", "slickness" }
local FOCUS = { "agoraphobia", "anorexia", "claustrophobia", "confusion", "dementia", "dizziness",
  "epilepsy", "hallucinations", "loneliness", "lovers", "masochism", "pacified", "paranoia", "peace",
  "recklessness", "shyness", "stupidity", "stuttering", "vertigo" }

local function set(list)
  local s = {}
  for _, v in ipairs(list or {}) do s[v] = true end
  return s
end
-- The list getCurableAffs would actually use for this herb.
local function effective(herb)
  return (curingTable and curingTable[herb]) or curingTableV3[herb]
end

describe("Target cure tables -- WHATCURES (v4.7.371)", function()

  it("every herb's effective list holds exactly the game's set", function()
    for herb, affs in pairs(WHATCURES) do
      local have = set(effective(herb))
      for _, aff in ipairs(affs) do
        if not have[aff] then error(herb .. " is missing " .. aff) end
      end
      local want = set(affs)
      for aff in pairs(have) do
        if not want[aff] then error(herb .. " lists " .. aff .. ", which WHATCURES does not") end
      end
    end
  end)

  it("curingTableV3 matches too, so neither table can mask the other", function()
    for herb, affs in pairs(WHATCURES) do
      local have = set(curingTableV3[herb])
      for _, aff in ipairs(affs) do
        if not have[aff] then error("curingTableV3." .. herb .. " is missing " .. aff) end
      end
    end
  end)

  it("the V3 smoke table covers both pipes (elm and valerian)", function()
    local have = set(smokeCureTableV3)
    for _, aff in ipairs(SMOKE) do
      if not have[aff] then error("smoke is missing " .. aff) end
    end
  end)

  it("focus cures exactly the game's list -- no impatience, addiction or hypersomnia", function()
    local have, want = set(focusCurableAffsV3), set(FOCUS)
    for _, aff in ipairs(FOCUS) do
      if not have[aff] then error("focus is missing " .. aff) end
    end
    for aff in pairs(have) do
      if not want[aff] then error("focus lists " .. aff .. ", which WHATCURES does not") end
    end
  end)

  it("a goldenseal eat cures shadowmadness (it used to be masked)", function()
    resetStatesV3()
    if resetCureBalancesV3 then resetCureBalancesV3() end
    applyAffV3("shadowmadness")
    expect(getAffProbabilityV3("shadowmadness")).toBe(1)
    onHerbCureV3("goldenseal")
    expect(getAffProbabilityV3("shadowmadness")).toBe(0)
  end)

  it("a bellwort eat cures retribution", function()
    resetStatesV3()
    if resetCureBalancesV3 then resetCureBalancesV3() end
    applyAffV3("retribution")
    onHerbCureV3("bellwort")
    expect(getAffProbabilityV3("retribution")).toBe(0)
  end)

  it("a focus proves impatience absent instead of sharing the cure with it", function()
    resetStatesV3()
    if resetCureBalancesV3 then resetCureBalancesV3() end
    applyAffV3("stupidity")
    -- A 50% impatience branch (one of two equally likely worlds).
    afflictionStatesV3 = {
      { affs = { stupidity = true, impatience = true }, prob = 0.5 },
      { affs = { stupidity = true }, prob = 0.5 },
    }
    onTargetFocusV3()
    expect(getAffProbabilityV3("impatience")).toBe(0)
    expect(getAffProbabilityV3("stupidity")).toBe(0)   -- the only focus-curable aff
  end)
end)

describe("the tree's random-cure pool (v4.7.416)", function()
  it("holds what the tree was seen to cure, and not the NoRandomCure damaged limbs", function()
    local pool = {}
    for _, a in ipairs(treeCurableAffsV3) do pool[a] = true end
    -- Mystor's logs: the tree cured healthleech and a level-1 broken limb; a Runewarden's: blackout.
    -- The game's AFFLICTION SHOW marks none of these NoRandomCure.
    for _, a in ipairs({ "healthleech", "brokenleftleg", "brokenrightleg", "brokenleftarm", "brokenrightarm", "blackout" }) do
      expect(pool[a]).toBeTrue()
    end
    -- damaged (level-2) limbs ARE NoRandomCure
    expect(pool.damagedleftleg).toBeNil()
    expect(pool.damagedrightarm).toBeNil()
  end)
end)

-- The 2026-11-07 Serpent spar: Saibel's tree at 26.296 most likely took recklessness (INFERRED, CONFLICTS #65), her only affliction then,
-- and the tracker kept it for 5 more rounds because the pool had no recklessness. The pool is now
-- built from the game's AFFLICTION SHOW records (kb/raw/live/affliction_show/<aff>.txt).
describe("the tree's pool is the game's random-curable set (2026-11-07 spar)", function()
  -- The game's NoRandomCure value for one affliction ("Yes" or "No"), or nil with no record.
  local function noRandomCure(aff)
    local fh = io.open("kb/raw/live/affliction_show/" .. aff .. ".txt", "r")
    if not fh then return nil end
    local txt = fh:read("*a"); fh:close()
    return txt:match("NoRandomCure:%s+(%a+)")
  end
  local function poolSet()
    local pool = {}
    for _, a in ipairs(treeCurableAffsV3) do pool[a] = true end
    return pool
  end

  it("every pool entry has a record, and the record says NoRandomCure: No", function()
    for _, a in ipairs(treeCurableAffsV3) do
      local flag = noRandomCure(a)
      if flag ~= "No" then error(a .. " is in the tree pool, but its NoRandomCure is " .. tostring(flag)) end
    end
  end)

  it("holds the spar's afflictions: recklessness, masochism, disloyalty, hypochondria, vertigo, fratricide", function()
    local pool = poolSet()
    for _, a in ipairs({ "recklessness", "masochism", "disloyalty", "hypochondria", "vertigo", "fratricide" }) do
      if not pool[a] then error("the tree pool has no " .. a) end
    end
  end)

  it("holds every random-curable affliction the tracker can cure, except burning", function()
    -- Burning comes in levels, and V3 holds it as one affliction (see the note above the pool).
    local OUT = { burning = true }
    local tracked = {}
    local function add(list) for _, a in ipairs(list or {}) do tracked[a] = true end end
    for _, list in pairs(curingTableV3) do add(list) end
    for _, list in pairs(salveCureTableV3) do add(list) end
    add(smokeCureTableV3); add(focusCurableAffsV3); add(passiveCurableAffsV3)
    local pool, missing = poolSet(), {}
    for a in pairs(tracked) do
      if noRandomCure(a) == "No" and not OUT[a] and not pool[a] then missing[#missing + 1] = a end
    end
    table.sort(missing)
    if #missing > 0 then error("random-curable but not in the tree pool: " .. table.concat(missing, ", ")) end
  end)

  it("a tree with only recklessness on takes it", function()
    resetStatesV3()
    if resetCureBalancesV3 then resetCureBalancesV3() end
    applyAffV3("recklessness")
    onTargetTreeV3()
    expect(getAffProbabilityV3("recklessness")).toBe(0)
  end)

  it("a tree splits evenly between recklessness and clumsiness", function()
    resetStatesV3()
    if resetCureBalancesV3 then resetCureBalancesV3() end
    applyAffV3("recklessness")
    applyAffV3("clumsiness")
    onTargetTreeV3()
    expect(math.abs(getAffProbabilityV3("recklessness") - 0.5) < 1e-9).toBeTrue()
    expect(math.abs(getAffProbabilityV3("clumsiness") - 0.5) < 1e-9).toBeTrue()
  end)
end)

-- Restore the shared Lua state: drop every global the loaded files created and
-- put back every one they replaced.
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
