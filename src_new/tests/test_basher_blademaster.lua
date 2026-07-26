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

describe("ataxiaBasher_blademasterBashing — Bladed Reflexes (shin augment) boon", function()
  local function reset(shin)
    bmShatteredStar = false
    bmBladedReflexes = true
    ataxiaBasher.shielded = false
    ataxiaBasher.rageraze = false
    ataxiaTemp = {}
    ataxia.defences = {}
    ataxia.vitals.class = shin -- shin count (blademaster.getShin fallback source)
  end

  it("prepends the configurable augment spend with the boon on and enough shin", function()
    reset(3)
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "shin augment 3")).toBeTrue() -- default spend: 1 shin dissipates instantly (live log)
    expect(cmd:find("shin augment 3", 1, true)).toBe(1) -- augment leads the chain
    expect(has(cmd, "drawslash " .. target .. " sternum")).toBeTrue() -- attack intact
    reset(5)
    ataxiaBasher.bmAugmentAmount = 5
    local cmd2 = ataxiaBasher_blademasterBashing()
    expect(has(cmd2, "shin augment 5")).toBeTrue()
    ataxiaBasher.bmAugmentAmount = nil
  end)

  it("does NOT augment below the spend amount (augment needs the shin)", function()
    reset(2) -- below the default spend of 3
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "shin augment")).toBeFalse()
  end)

  it("does NOT augment while the bodyaugment defence is already up", function()
    reset(3)
    ataxia.defences.bodyaugment = true
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "shin augment")).toBeFalse()
  end)

  it("does NOT re-send during the attempt-hold (channel wind-up)", function()
    reset(3)
    ataxiaTemp.bmAugmentAttempted = true
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "shin augment")).toBeFalse()
  end)

  it("arms the attempt-hold when it sends, so the NEXT swing skips the augment", function()
    reset(4)
    local first = ataxiaBasher_blademasterBashing()
    expect(has(first, "shin augment 3")).toBeTrue()
    local second = ataxiaBasher_blademasterBashing()
    expect(has(second, "shin augment")).toBeFalse()
  end)

  it("does NOT augment when the boon is off", function()
    reset(3)
    bmBladedReflexes = false
    local cmd = ataxiaBasher_blademasterBashing()
    expect(has(cmd, "shin augment")).toBeFalse()
  end)
end)
