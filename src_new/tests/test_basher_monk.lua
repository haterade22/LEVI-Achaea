--- test_basher_monk.lua — Monk (Shikudo / Tekura) bashing assembly
-- Verifies ataxiaBasher_monkBashing2(): Monk NEVER spends rage on a denizen shield
-- (always the free `shatter` / `rhk` breaker, never the 17-rage `spk` battlerage raze),
-- battlerage is skipped while shielded, and the Shikudo form rotation rides Willow and
-- leaves Rain/Oak as soon as a transition is legal. Loads the real basher/002_Class_Bashing.lua.

require("mock_mudlet")

-- Globals the Monk bashing path reads at call time.
target = "manticore"
ataxia = {
  settings = { separator = ";", crushbash = false },
  -- hp == maxhp so the transmute preamble stays out of the assembled command.
  vitals = { form = "Willow", kata = 0, stance = false, rage = 100,
             hp = 5000, maxhp = 5000, mp = 5000, maxmp = 5000 },
}
ataxiaBasher = {
  shielded = false,
  rageraze = false,
  battlerage = { Monk = { small = "sbp " .. target, large = "tnk " .. target,
                          raze = "spk " .. target, special = "mind scramble " .. target } },
}
-- Battlerage assembly is covered elsewhere; stub it to a sentinel so we can assert on
-- whether it was folded into the command at all.
function ataxiaBasher_assembleBattlerage() return "BRAGE" end
function ataxiaEcho() end

local file = "src_new/scripts/levi_ataxia/levi/ataxia/basher/002_Class_Bashing.lua"
local ok, err = pcall(dofile, file)
if not ok then error("Failed to load class-bashing file: " .. tostring(err)) end

local function has(cmd, needle) return cmd:find(needle, 1, true) ~= nil end

local function reset()
  ataxia.vitals.form, ataxia.vitals.kata, ataxia.vitals.stance = "Willow", 0, false
  ataxia.vitals.rage = 100
  ataxia.settings.crushbash = false
  ataxiaBasher.shielded, ataxiaBasher.rageraze = false, false
end

describe("ataxiaBasher_monkBashing2 — never spends rage on denizen shields", function()
  it("breaks a shield with the free shatter, not the spk battlerage raze", function()
    reset(); ataxiaBasher.shielded = true
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "shatter")).toBeTrue()
    expect(has(cmd, "spk")).toBeFalse()
  end)

  it("STILL uses shatter with rageraze on and rage to spare (the regression guard)", function()
    reset(); ataxiaBasher.shielded = true; ataxiaBasher.rageraze = true; ataxia.vitals.rage = 100
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "shatter")).toBeTrue()
    expect(has(cmd, "spk")).toBeFalse() -- rageraze is deliberately ignored for Monk
  end)

  it("Tekura uses its own free rhk breaker when shielded, never spk", function()
    reset(); ataxia.vitals.stance = true; ataxiaBasher.shielded = true; ataxiaBasher.rageraze = true
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "rhk")).toBeTrue()
    expect(has(cmd, "spk")).toBeFalse()
  end)

  it("uses the plain combo (no shatter) when unshielded", function()
    reset()
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "hiru hiraku flashheel left")).toBeTrue()
    expect(has(cmd, "shatter")).toBeFalse()
  end)

  it("skips battlerage while shielded, folds it in otherwise", function()
    reset(); ataxiaBasher.shielded = true
    expect(has(ataxiaBasher_monkBashing2(), "BRAGE")).toBeFalse()
    reset()
    expect(has(ataxiaBasher_monkBashing2(), "BRAGE")).toBeTrue()
  end)
end)

describe("ataxiaBasher_monkBashing2 — Shikudo form rotation", function()
  it("rides Willow, then transitions to Rain at its leaveAt", function()
    reset(); ataxia.vitals.kata = 0
    expect(has(ataxiaBasher_monkBashing2(), "transition")).toBeFalse()
    reset(); ataxia.vitals.kata = 9
    expect(has(ataxiaBasher_monkBashing2(), "transition rain")).toBeTrue()
  end)

  -- Per AB SHIKUDO COMBO the transition is an inline suffix of COMBO itself, not a separate
  -- command -- a separate one races the three attacks that build the chain it needs.
  it("emits the transition inline in the combo, not as a separate command", function()
    reset(); ataxia.vitals.kata = 9
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "combo " .. target .. " hiru hiraku flashheel left transition rain")).toBeTrue()
    expect(has(cmd, "transition to the")).toBeFalse()
  end)

  -- The game rejects a TRANSITION below a chain of 5 and the rejection RESETS the chain, so
  -- transitioning early is not merely wasted -- it livelocks the rotation (chain 0 -> 3 ->
  -- rejected -> 0 -> ...), which is exactly what was seen in game. Never gate below 5.
  it("never transitions below a kata of 5 (a rejected transition resets the chain)", function()
    for _, form in ipairs({"Rain", "Oak", "Tykonos", "Gaital", "Maelstrom"}) do
      for _, k in ipairs({0, 2, 3, 4}) do
        reset(); ataxia.vitals.form, ataxia.vitals.kata = form, k
        expect(has(ataxiaBasher_monkBashing2(), "transition")).toBeFalse()
      end
    end
  end)

  it("leaves Rain and Oak once the chain is legal (Willow -> Rain -> Oak -> Willow)", function()
    reset(); ataxia.vitals.form, ataxia.vitals.kata = "Rain", 6
    expect(has(ataxiaBasher_monkBashing2(), "transition oak")).toBeTrue()
    reset(); ataxia.vitals.form, ataxia.vitals.kata = "Oak", 6
    expect(has(ataxiaBasher_monkBashing2(), "transition willow")).toBeTrue()
  end)

  it("tolerates a nil kata (absent from charstats until a chain starts)", function()
    reset(); ataxia.vitals.kata = nil
    expect(ataxiaBasher_monkBashing2() ~= "").toBeTrue()
  end)

  it("crushbash mode swaps the staff combo for mind crush", function()
    reset(); ataxia.settings.crushbash = true
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "mind crush")).toBeTrue()
    expect(has(cmd, "combo")).toBeFalse()
  end)
end)
