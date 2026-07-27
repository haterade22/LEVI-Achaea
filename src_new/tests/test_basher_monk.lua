--- test_basher_monk.lua — Monk (Shikudo / Tekura) bashing assembly
-- Verifies ataxiaBasher_monkBashing2(): Monk NEVER spends rage on a denizen shield
-- (always the free `shatter` / `rhk` breaker, never the 17-rage `spk` battlerage raze),
-- battlerage is skipped while shielded, and the Shikudo form rotation rides Willow and
-- leaves Rain/Oak as soon as a transition is legal. Loads the real basher/002_Class_Bashing.lua.

require("mock_mudlet")

-- Globals the Monk bashing path reads at call time.
target = "manticore"
ataxia = {
  settings = {
    separator = ";", crushbash = false,
    sipping = { transmuteat = 50, transmuteto = 70, manause = 30 },
  },
  -- sipbal nil + hp == maxhp keeps the transmute preamble out of the assembled command.
  vitals = { form = "Willow", kata = 0, stance = false, rage = 100, sipbal = nil,
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
  ataxia.vitals.sipbal = nil
  ataxia.vitals.hp, ataxia.vitals.maxhp = 5000, 5000
  ataxia.vitals.mp, ataxia.vitals.maxmp = 5000, 5000
  ataxia.settings.crushbash = false
  ataxia.settings.sipping = { transmuteat = 50, transmuteto = 70, manause = 30 }
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

-- Transmute is a gap-filler for the window server-side sipping cannot cover: sip balance
-- DOWN and actually low. Firing it every balance to top up just burns the mana Regeneration
-- converts back into health.
describe("ataxiaBasher_monkBashing2 — transmute is a gap-filler", function()
  it("does not transmute while sip balance is UP, even at low health", function()
    reset(); ataxia.vitals.sipbal = true; ataxia.vitals.hp = 1000 -- 20%
    expect(has(ataxiaBasher_monkBashing2(), "transmute")).toBeFalse()
  end)

  -- ataxia.vitals = {} on login and only the sip triggers set sipbal, so it is nil until the
  -- first sip. nil must NOT read as "off balance" (`== false`, not `not sipbal`).
  it("does not transmute when sipbal is nil (no sip yet this session)", function()
    reset(); ataxia.vitals.sipbal = nil; ataxia.vitals.hp = 1000
    expect(has(ataxiaBasher_monkBashing2(), "transmute")).toBeFalse()
  end)

  it("does not transmute off sip balance while above transmuteat", function()
    reset(); ataxia.vitals.sipbal = false; ataxia.vitals.hp = 3000 -- 60% > 50%
    expect(has(ataxiaBasher_monkBashing2(), "transmute")).toBeFalse()
  end)

  it("transmutes off sip balance at/below transmuteat, topping up to transmuteto", function()
    reset(); ataxia.vitals.sipbal = false; ataxia.vitals.hp = 2000 -- 40% <= 50%
    -- target ceil(5000*0.70)=3500; deficit 1500; spendable 5000-1500=3500 -> min = 1500
    expect(has(ataxiaBasher_monkBashing2(), "transmute 1500;")).toBeTrue()
  end)

  it("never spends mana past the manause floor", function()
    reset(); ataxia.vitals.sipbal = false; ataxia.vitals.hp = 2000
    ataxia.vitals.mp = 1800 -- spendable 1800-1500=300, less than the 1500 deficit
    expect(has(ataxiaBasher_monkBashing2(), "transmute 300;")).toBeTrue()
  end)

  it("emits an integer amount (the mana floor can be fractional)", function()
    reset(); ataxia.vitals.sipbal = false; ataxia.vitals.hp = 2000
    ataxia.vitals.maxmp, ataxia.vitals.mp = 5001, 1800 -- floor 1500.3 -> spendable 299.7
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "transmute 299;")).toBeTrue()
    expect(cmd:find("transmute %d+%.")).toBeNil() -- never a fractional command
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

-- Kai Unleashed boon (Mnemosyne): RAIN-form KAI CHOKE takes the round over the combo
-- at 2+ denizens, off the boon's 30s AoE-burst cooldown. Gates: boon flag, Rain form,
-- no shield to break, kai in hand (vitals.class), denizen count, cooldown stamp in
-- ataxiaTemp (survives a SYSUPDATE reload).
describe("ataxiaBasher_monkBashing2 -- Kai Unleashed AoE choke", function()
  local mobs = 2
  local clock = 100000
  local _epoch = getEpoch
  getEpoch = function() return clock end -- restored at the end of this describe

  local function kaiReset(n)
    reset()
    ataxia.vitals.form = "Rain"
    ataxia.vitals.class = 80 -- kai% (Kai/Shin land in vitals.class)
    ataxia.mnemosyne = { _denizenCount = function() return mobs end }
    ataxiaTemp = { kaiUnleashedAt = nil }
    mnemKaiUnleashed = true
    mobs = n or 2
    clock = 100000
  end

  it("fires kai choke instead of the combo in Rain with 2+ denizens", function()
    kaiReset(3)
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "kai choke " .. target)).toBeTrue()
    expect(has(cmd, "combo")).toBeFalse() -- the choke replaces the round's combo
    expect(ataxiaTemp.kaiUnleashedAt).toBe(100000) -- cooldown stamped at send
  end)

  it("respects the 30s cooldown, then fires again", function()
    kaiReset(2)
    ataxiaBasher_monkBashing2() -- stamps the cooldown
    clock = clock + 10
    expect(has(ataxiaBasher_monkBashing2(), "kai choke")).toBeFalse()
    clock = clock + 25 -- 35s since the stamp
    expect(has(ataxiaBasher_monkBashing2(), "kai choke")).toBeTrue()
  end)

  it("only fires in Rain form (the rotation re-visits Rain every cycle)", function()
    kaiReset(3); ataxia.vitals.form = "Willow"
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "kai choke")).toBeFalse()
    expect(has(cmd, "combo")).toBeTrue()
  end)

  it("needs 2+ denizens, the boon flag, and kai in hand", function()
    kaiReset(1)
    expect(has(ataxiaBasher_monkBashing2(), "kai choke")).toBeFalse()
    kaiReset(2); mnemKaiUnleashed = false
    expect(has(ataxiaBasher_monkBashing2(), "kai choke")).toBeFalse()
    kaiReset(2); ataxia.vitals.class = 10 -- kai-dry: fall back to the combo, save the window
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "kai choke")).toBeFalse()
    expect(has(cmd, "combo")).toBeTrue()
    expect(ataxiaTemp.kaiUnleashedAt).toBe(nil) -- cooldown NOT spent on a refused gate
  end)

  it("breaks a shield first -- shatter wins over the choke", function()
    kaiReset(3); ataxiaBasher.shielded = true
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "shatter")).toBeTrue()
    expect(has(cmd, "kai choke")).toBeFalse()
  end)

  -- Restore shared state for whoever runs after us (files share one Lua state).
  mnemKaiUnleashed = false
  ataxia.mnemosyne = nil
  getEpoch = _epoch
end)
