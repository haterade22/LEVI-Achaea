--- test_basher_blademaster.lua — Blademaster bashing attack assembly
-- Verifies ataxiaBasher_blademasterBashing() swaps drawslash -> multislash while the
-- White Heaven's Shattered Star boon (bmShatteredStar) is active, and falls back to
-- drawslash otherwise. Loads the real basher/002_Class_Bashing.lua (function defs only).

require("mock_mudlet")

-- Globals the class-bashing file reads at call time.
target = "manticore"
ataxia = { settings = { separator = ";" }, vitals = { rage = 0 } }
ataxiaBasher = {
  shielded = false,
  rageraze = false,
  battlerage = { Blademaster = { raze = "raze " .. target } },
}
-- Battlerage assembly is exercised in test_basher_battlerage; stub to empty so we test
-- only the melee verb selection here.
function ataxiaBasher_assembleBattlerage() return "" end

local file = "src_new/scripts/levi_ataxia/levi/ataxia/basher/002_Class_Bashing.lua"
local ok, err = pcall(dofile, file)
if not ok then error("Failed to load class-bashing file: " .. tostring(err)) end

local function has(cmd, needle) return cmd:find(needle, 1, true) ~= nil end

describe("ataxiaBasher_blademasterBashing — Shattered Star (multislash) boon", function()
  it("uses drawslash <t> sternum when the boon is OFF", function()
    bmShatteredStar = false
    ataxiaBasher.shielded = false
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "drawslash " .. target .. " sternum")).toBeTrue()
    expect(has(cmd, "multislash")).toBeFalse()
  end)

  it("swaps to multislash <t> sternum (same body part) when the boon is ON", function()
    bmShatteredStar = true
    ataxiaBasher.shielded = false
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "multislash " .. target .. " sternum")).toBeTrue()
    expect(has(cmd, "drawslash")).toBeFalse()
  end)

  it("keeps infuse fire in the chain with multislash", function()
    bmShatteredStar = true
    ataxiaBasher.shielded = false
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "infuse fire")).toBeTrue()
  end)

  it("still swaps to multislash on the rageraze+shielded path", function()
    bmShatteredStar = true
    ataxiaBasher.shielded = true
    ataxiaBasher.rageraze = true
    ataxia.vitals.rage = 20 -- >= 17 so the rageraze branch is taken
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "multislash " .. target .. " sternum")).toBeTrue()
    expect(has(cmd, "drawslash")).toBeFalse()
  end)

  it("uses drawslash on the rageraze+shielded path when the boon is OFF", function()
    bmShatteredStar = false
    ataxiaBasher.shielded = true
    ataxiaBasher.rageraze = true
    ataxia.vitals.rage = 20
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "drawslash " .. target .. " sternum")).toBeTrue()
    expect(has(cmd, "multislash")).toBeFalse()
  end)

  it("does not inject a melee verb on the plain shielded raze path", function()
    bmShatteredStar = true
    ataxiaBasher.shielded = true
    ataxiaBasher.rageraze = false -- this branch is "raze <t> ; <battlerage>" only
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "multislash")).toBeFalse()
    expect(has(cmd, "drawslash")).toBeFalse()
  end)
end)
