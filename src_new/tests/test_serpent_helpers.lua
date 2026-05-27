--- test_serpent_helpers.lua — Unit tests for serpent offense helpers
-- Tests selectBiteVenom() and selectOpportunisticEkanelia() in isolation.
-- These tests stub the minimal dependencies needed and load the serpent
-- offense file via dofile. They do NOT cover dispatch integration.

local mock = require("mock_mudlet")

-- ----------------------------------------------------------------------------
-- Stub dependencies that the serpent offense file expects to find
-- ----------------------------------------------------------------------------

-- Mock affliction state (set per-test via setAff)
local _tAffs = {}
function haveAff(aff) return _tAffs[aff] == true end
tAffs = setmetatable({}, {
  __index = function(_, k) return _tAffs[k] end,
  __newindex = function(_, k, v) _tAffs[k] = v end,
})

local function setAff(aff, val)
  _tAffs[aff] = (val ~= false)
end
local function clearAffs()
  _tAffs = {}
end

-- Ataxia / GUI stubs
ataxia = ataxia or {}
ataxia.settings = ataxia.settings or { separator = "::" }
ataxia.playersHere = {}

Algedonic = Algedonic or {}
Algedonic.Echo = function() end

tBals = tBals or { focus = true }
tarClass = ""
target = "dummy"
Rebounding = false
Shielded = false
reboundHold = nil
ataxiaTemp = ataxiaTemp or {}

function combatQueue() return "" end
function table.contains(t, v)
  for _, x in ipairs(t) do if x == v then return true end end
  return false
end
function ataxia_wantClumsiness() return true end
function getEpoch() return os.time() end

-- erAffWrapper/erAff/tarAffed stubs for the trigger registration block
function erAffWrapper() end
function erAff() end
function tarAffed() end

-- ----------------------------------------------------------------------------
-- Load the serpent offense file (registers globals: selectBiteVenom, etc.)
-- ----------------------------------------------------------------------------
local serpent_file = "src_new/scripts/levi_ataxia/levi/levi_scripts/serpent/002_Serpent_Offense.lua"
local ok, err = pcall(dofile, serpent_file)
if not ok then
  error("Failed to load serpent offense file: " .. tostring(err))
end

-- ----------------------------------------------------------------------------
-- Tests
-- ----------------------------------------------------------------------------

describe("selectBiteVenom — bite payload helper", function()

  it("returns scytherus when scytherus aff is stuck (camus loop)", function()
    clearAffs()
    setAff("scytherus", true)
    local pick = selectBiteVenom()
    expect(pick).toBe(pick)  -- not nil
    expect(pick.venom).toBe("scytherus")
    expect(pick.label).toContain("camus")
  end)

  it("returns scytherus when addiction+nausea ekanelia conditions met", function()
    clearAffs()
    setAff("addiction", true)
    setAff("nausea", true)
    local pick = selectBiteVenom()
    expect(pick.venom).toBe("scytherus")
  end)

  it("returns monkshood when asthma+masochism+weariness present (impatience ekanelia)", function()
    clearAffs()
    setAff("asthma", true)
    setAff("masochism", true)
    setAff("weariness", true)
    local pick = selectBiteVenom()
    expect(pick.venom).toBe("monkshood")
    expect(pick.label).toContain("impatience")
  end)

  it("returns kalmia when clumsiness+weariness present and asthma missing", function()
    clearAffs()
    setAff("clumsiness", true)
    setAff("weariness", true)
    local pick = selectBiteVenom()
    expect(pick.venom).toBe("kalmia")
  end)

  it("returns loki when confusion+recklessness present and paralysis missing", function()
    clearAffs()
    setAff("confusion", true)
    setAff("recklessness", true)
    local pick = selectBiteVenom()
    expect(pick.venom).toBe("loki")
  end)

  it("returns aconite when deadening+dementia present and stupidity missing", function()
    clearAffs()
    setAff("deadening", true)
    setAff("dementia", true)
    local pick = selectBiteVenom()
    expect(pick.venom).toBe("aconite")
  end)

  it("falls back to curare when paralysis missing and no ekanelia conditions met", function()
    clearAffs()
    local pick = selectBiteVenom()
    expect(pick.venom).toBe("curare")
  end)

  it("returns nil when target has nothing missing and no ekanelia ready", function()
    clearAffs()
    setAff("paralysis", true)
    setAff("asthma", true)
    setAff("weariness", true)
    local pick = selectBiteVenom()
    expect(pick).toBeNil()
  end)

end)

describe("selectOpportunisticEkanelia — Track 5 underused transforms", function()

  it("picks loki when confusion+recklessness present, paralysis missing", function()
    clearAffs()
    setAff("confusion", true)
    setAff("recklessness", true)
    local pair = selectOpportunisticEkanelia()
    expect(pair.venom).toBe("loki")
    expect(pair.label).toContain("nausea + paralysis")
  end)

  it("picks aconite when deadening+dementia present, stupidity missing", function()
    clearAffs()
    setAff("deadening", true)
    setAff("dementia", true)
    local pair = selectOpportunisticEkanelia()
    expect(pair.venom).toBe("aconite")
  end)

  it("picks curare-ek when hypersomnia+masochism present, paralysis missing", function()
    clearAffs()
    setAff("hypersomnia", true)
    setAff("masochism", true)
    local pair = selectOpportunisticEkanelia()
    expect(pair.venom).toBe("curare")
    expect(pair.label).toContain("hypochondria")
  end)

  it("returns nil when no ekanelia conditions are met", function()
    clearAffs()
    setAff("paralysis", true)  -- blocks curare-ek and loki
    local pair = selectOpportunisticEkanelia()
    expect(pair).toBeNil()
  end)

  it("prioritizes loki over aconite when both available", function()
    clearAffs()
    setAff("confusion", true)
    setAff("recklessness", true)
    setAff("deadening", true)
    setAff("dementia", true)
    local pair = selectOpportunisticEkanelia()
    expect(pair.venom).toBe("loki")  -- loki is priority 1
  end)

end)
