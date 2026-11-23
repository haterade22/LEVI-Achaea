--- test_affix_registry.lua -- the Mnemosyne affix registry (mnemosyne/017, v4.7.511)
--
-- The user, 2026-11-21, with Ricketts, Splinterbark and Suffering of Abbadon on the wade status:
-- "What happened to us planning for the ongoing effects (affixes?) of the wading?"
--
-- Lines: the WADE STATUS rows are from kb/raw/live/2026-11-21_wade-status_ricketts-splinterbark-abbadon.txt;
-- the other affix sentences are from kb/raw/live/2026-11-23_mnemosyne-affix-library.txt.
-- Loads the real mnemosyne 001-005, 007, 017 and the real class cure (can(x)/003). Every global
-- this file sets is put back at the end, because all test files share one Lua state.

local mock = require("mock_mudlet")

local SAVED = {}
local function setGlobal(name, value)
  if SAVED[name] == nil then SAVED[name] = { v = _G[name] } end
  _G[name] = value
end

local clock = 5000
setGlobal("getEpoch", function() return clock end)
setGlobal("yajl", { to_string = function() return "JSON" end, to_value = function() return nil end })
setGlobal("postHTTP", function() end)
setGlobal("getHTTP", function() end)
setGlobal("ataxia", { settings = { separator = ";" }, vitals = {}, afflictions = {}, defences = {} })
setGlobal("ataxiaBasher", { enabled = true })
setGlobal("ataxiaTemp", {})
setGlobal("ataxiaTables", {})
setGlobal("gmcp", { Room = { Info = { area = "" } }, Char = { Status = { class = "Monk" } } })

for _, f in ipairs({
  "src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/001_HTTP_Client.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/002_Reporter_API.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/003_Commands.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/004_Parsers.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/005_Ripple_Map.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/007_History.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/017_Affix_Registry.lua",
}) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end

local M = ataxia.mnemosyne

-- Verbatim rows (kb/raw/live/2026-11-21_wade-status_ricketts-splinterbark-abbadon.txt).
local ROWS = {
  "--------------------------------------------------------------------------------",
  "Suffering of Abbadon:    Slaying a denizen has a chance to evoke a memory of the Suffering God and spawn either a thornwall or gravehands in your location.",
  "Splinterbark:            Your tree tattoo is tainted with fell magic, causing you to bleed and suffer a random malady when touching it.",
  "Ricketts:                Attacking a denizen causes some of your limbs to break.",
}
-- kb/raw/live/2026-11-23_mnemosyne-affix-library.txt
local TENDERISED = "You suffer permanent tenderskin and permanent sensitivity."
local OUTCAST = "You suffer from permanent disloyalty."
local IMPASSE = "All denizens will block your movements."
local DEATHMARKED = "Defeating a denizen has a high chance to summon an elite Quisalis assassin to slay you."

local function reset()
  mock.reset()
  clock = clock + 100
  ataxia.settings = { separator = ";", reporting = { enabled = false, quiet = false } }
  ataxia.vitals = { hpp = 100 }
  ataxia.afflictions = {}
  ataxiaTemp = {}
  ataxiaBasher.inMnemosyne = true
  M.history = M.history or {}
  M.history.run = 900
  M.history.claims = {}
  M.history.affixes = {}
  M.history.library = M.history.library or {}
  M.history.boonLibrary = M.history.boonLibrary or {}
  M._boonLibGen = (M._boonLibGen or 0) + 1
  M.affixReset()
end

local function echoes(find)
  local n = 0
  for _, line in ipairs(mock.echoed_lines) do
    if line:find(find, 1, true) then n = n + 1 end
  end
  return n
end

-- Run the real "Ongoing effects:" handler over `lines`, with the capture stubbed to hand them over.
local function effectsBlock(lines)
  local savedCap, savedReport = M._captureLines, M.reportEffects
  local posted = 0
  M._captureLines = function(opts) opts.onDone(lines) end
  M.reportEffects = function() posted = posted + 1 end
  local ok, err = pcall(M.onEffectsHeader)
  M._captureLines, M.reportEffects = savedCap, savedReport
  assert(ok, err)
  return posted
end

describe("the run's affixes are read with telemetry OFF", function()
  it("the WADE STATUS rows land in the run set, and nothing is posted", function()
    reset()
    local posted = effectsBlock(ROWS)
    expect(M.runHasAffix("Ricketts")).toBeTrue()
    expect(M.runHasAffix("splinterbark")).toBeTrue()
    expect(M.runHasAffix("Suffering of Abbadon")).toBeTrue()
    expect(M.runHasAffix("Prey")).toBeFalse()
    expect(M.hasAffix("abbadon")).toBeTrue() -- the substring reader sees it too
    expect(posted).toBe(0)
  end)

  it("outside the tower, with telemetry off, the block is not read", function()
    reset()
    ataxiaBasher.inMnemosyne = false
    effectsBlock(ROWS)
    expect(M.runHasAffix("Ricketts")).toBeFalse()
  end)

  it("a run reset forgets them", function()
    reset()
    effectsBlock(ROWS)
    M.affixReset()
    expect(M.runHasAffix("Ricketts")).toBeFalse()
  end)
end)

describe("each new affix is announced once, with our response or none", function()
  it("a handled affix names what we do; an unhandled one says so with the game's sentence", function()
    reset()
    M.onAffixesSeen({ { name = "Splinterbark", description = "x" }, { name = "Impasse", description = IMPASSE } })
    expect(echoes("Splinterbark<reset>: curing tree off")).toBe(1)
    expect(echoes("Impasse<reset>: <red>no response in our code<reset> -- " .. IMPASSE)).toBe(1)
    M.onAffixesSeen({ { name = "Splinterbark", description = "x" }, { name = "Impasse", description = IMPASSE } })
    expect(echoes("Splinterbark<reset>:")).toBe(1)
    expect(echoes("Impasse<reset>:")).toBe(1)
  end)

  it("says nothing under mnem quiet", function()
    reset()
    ataxia.settings.reporting.quiet = true
    M.onAffixesSeen({ { name = "Impasse", description = IMPASSE } })
    expect(echoes("Impasse")).toBe(0)
  end)
end)

describe("an affix's permanent affliction is not a reason to cure", function()
  it("reads both afflictions of 'permanent X and permanent Y'", function()
    expect(table.concat(M._permanentAffsFrom(TENDERISED), ",")).toBe("tenderskin,sensitivity")
    expect(table.concat(M._permanentAffsFrom(OUTCAST), ",")).toBe("disloyalty")
  end)

  it("ataxia_permanentAff names the affix in the tower, and nil outside", function()
    reset()
    M.onAffixesSeen({ { name = "Tenderised Flesh", description = TENDERISED }, { name = "Outcast", description = OUTCAST } })
    expect(ataxia_permanentAff("tenderskin")).toBe("Tenderised Flesh")
    expect(ataxia_permanentAff("sensitivity")).toBe("Tenderised Flesh")
    expect(ataxia_permanentAff("disloyalty")).toBe("Outcast")
    expect(ataxia_permanentAff("paralysis")).toBeNil()
    ataxiaBasher.inMnemosyne = false
    expect(ataxia_permanentAff("tenderskin")).toBeNil()
  end)

  it("an affix seen after the first read still counts (the cache follows the run set)", function()
    reset()
    expect(ataxia_permanentAff("disloyalty")).toBeNil()
    M.onAffixesSeen({ { name = "Outcast", description = OUTCAST } })
    expect(ataxia_permanentAff("disloyalty")).toBe("Outcast")
  end)
end)

describe("the spawn-on-kill hold", function()
  it("holds below 90% with Deathmarked, and names it", function()
    reset()
    M.onAffixesSeen({ { name = "Deathmarked", description = DEATHMARKED } })
    ataxia.vitals.hpp = 60
    local hold, name = M._spawnHold()
    expect(hold).toBeTrue()
    expect(name).toBe("Deathmarked")
    ataxia.vitals.hpp = 90
    expect((M._spawnHold())).toBeFalse()
  end)

  it("Suffering of Abbadon is a spawn affix too", function()
    reset()
    effectsBlock(ROWS)
    ataxia.vitals.hpp = 50
    local hold, name = M._spawnHold()
    expect(hold).toBeTrue()
    expect(name).toBe("Suffering of Abbadon")
  end)

  it("does not hold with no spawn affix, or outside the tower", function()
    reset()
    M.onAffixesSeen({ { name = "Impasse", description = IMPASSE } })
    ataxia.vitals.hpp = 10
    expect((M._spawnHold())).toBeFalse()
    M.onAffixesSeen({ { name = "Deathmarked", description = DEATHMARKED } })
    ataxiaBasher.inMnemosyne = false
    expect((M._spawnHold())).toBeFalse()
  end)
end)

-- ─── put the shared state back ──────────────────────────────────────────────

for name, rec in pairs(SAVED) do _G[name] = rec.v end
