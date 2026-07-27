--- test_basher_psion.lua -- Psion bashing assembly (Panoply boon verb swap)
-- Verifies ataxiaBasher_psionBashing(): weave deathblow is the default bash; the
-- Mnemosyne Panoply boon (WEAVE FLURRY scales 60-200% with strikes landed) swaps
-- the damage weave to flurry while psionPanoply is up -- cleave keeps the
-- shield-break role, psi shatter keeps its transcendence slot. Loads the real
-- basher/002_Class_Bashing.lua.

require("mock_mudlet")

-- Globals the Psion bashing path reads at call time.
target = "manticore"
ataxia = { settings = { separator = ";" }, vitals = { rage = 100 }, defences = {} }
ataxiaBasher = {
  shielded = false, rageraze = false,
  battlerage = { Psion = { raze = "RAZERAGE" } },
}
ataxiaTemp = {}
function ataxiaBasher_assembleBattlerage() return "BRAGE" end
function ataxiaEcho() end

local file = "src_new/scripts/levi_ataxia/levi/ataxia/basher/002_Class_Bashing.lua"
local ok, err = pcall(dofile, file)
if not ok then error("Failed to load class-bashing file: " .. tostring(err)) end

local function has(cmd, needle) return cmd:find(needle, 1, true) ~= nil end

local function reset()
  ataxiaBasher.shielded, ataxiaBasher.rageraze = false, false
  ataxia.vitals.rage = 100
  ataxiaTemp = {}
  psionPanoply = false
end

describe("ataxiaBasher_psionBashing -- Panoply flurry swap", function()
  it("bashes with weave deathblow by default", function()
    reset()
    local cmd = ataxiaBasher_psionBashing()
    expect(has(cmd, "weave deathblow " .. target)).toBeTrue()
    expect(has(cmd, "weave flurry")).toBeFalse()
    expect(has(cmd, "BRAGE")).toBeTrue()
  end)

  it("swaps to weave flurry while Panoply is up", function()
    reset(); psionPanoply = true
    local cmd = ataxiaBasher_psionBashing()
    expect(has(cmd, "weave flurry " .. target)).toBeTrue()
    expect(has(cmd, "weave deathblow")).toBeFalse()
  end)

  it("keeps psi shatter's transcendence slot, flurry replacing only the weave", function()
    reset(); psionPanoply = true
    ataxiaTemp.transcendence = 100
    local cmd = ataxiaBasher_psionBashing()
    expect(has(cmd, "psi shatter " .. target .. ";weave flurry " .. target)).toBeTrue()
  end)

  it("cleave keeps the shield-break role even with the boon up", function()
    reset(); psionPanoply = true
    ataxiaBasher.shielded, ataxiaBasher.rageraze = true, true
    local cmd = ataxiaBasher_psionBashing()
    expect(has(cmd, "weave cleave " .. target)).toBeTrue()
    expect(has(cmd, "weave flurry")).toBeFalse()
  end)
end)

-- Restore shared state for whoever runs after us (files share one Lua state).
psionPanoply = false
