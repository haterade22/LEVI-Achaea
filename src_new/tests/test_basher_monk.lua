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

-- Kai Unleashed boon (Mnemosyne): RAIN-form KAI CHOKE rides ALONGSIDE the combo at
-- 2+ denizens, off the boon's 30s AoE-burst cooldown. Per AB Kaichoke (ID 896): the
-- choke spends 4s of EQUILIBRIUM (idle during balance combos, so both land) and
-- against a DENIZEN consumes NO kai -- only 50 mana, hence a small mana floor
-- instead of a kai gate. Cooldown stamp in ataxiaTemp (survives a SYSUPDATE reload).
describe("ataxiaBasher_monkBashing2 -- Kai Unleashed AoE choke", function()
  local mobs = 2
  local clock = 100000
  local _epoch = getEpoch
  getEpoch = function() return clock end -- restored at the end of this describe

  local function kaiReset(n)
    reset()
    ataxia.vitals.form = "Rain"
    ataxia.mnemosyne = { _denizenCount = function() return mobs end }
    ataxiaTemp = { kaiUnleashedAt = nil }
    mnemKaiUnleashed = true
    mobs = n or 2
    clock = 100000
  end

  it("prepends kai choke to the combo in Rain with 2+ denizens (eq rides balance)", function()
    kaiReset(3)
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "kai choke " .. target)).toBeTrue()
    expect(has(cmd, "combo")).toBeTrue() -- the combo still swings this round
    expect(cmd:find("kai choke", 1, true) < cmd:find("combo", 1, true)).toBeTrue()
    expect(ataxiaTemp.kaiChokePendingAt).toBe(100000) -- pending, NOT the 30s stamp
    expect(ataxiaTemp.kaiUnleashedAt).toBe(nil) -- the burst line starts the real cooldown
  end)

  it("retries an UNCONFIRMED choke after the retry window (eaten/wiped send)", function()
    kaiReset(2)
    ataxiaBasher_monkBashing2() -- sends; no burst line ever comes
    clock = clock + 3
    expect(has(ataxiaBasher_monkBashing2(), "kai choke")).toBeFalse() -- inside retry guard
    clock = clock + 5 -- 8s since the send
    expect(has(ataxiaBasher_monkBashing2(), "kai choke")).toBeTrue() -- retried
  end)

  it("starts the 30s cooldown only when the burst line CONFIRMS", function()
    kaiReset(2)
    ataxiaBasher_monkBashing2()
    clock = clock + 2
    ataxiaBasher_kaiUnleashedBurst() -- the live-captured surge line fired
    expect(ataxiaTemp.kaiUnleashedAt).toBe(100002)
    expect(ataxiaTemp.kaiChokePendingAt).toBe(nil)
    clock = clock + 20 -- 22s after the burst: still cooling down
    expect(has(ataxiaBasher_monkBashing2(), "kai choke")).toBeFalse()
    clock = clock + 15 -- 37s after the burst
    expect(has(ataxiaBasher_monkBashing2(), "kai choke")).toBeTrue()
  end)

  it("only fires in Rain form (the rotation re-visits Rain every cycle)", function()
    kaiReset(3); ataxia.vitals.form = "Willow"
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "kai choke")).toBeFalse()
    expect(has(cmd, "combo")).toBeTrue()
  end)

  it("needs 2+ denizens, the boon flag, and a non-dry mana pool", function()
    kaiReset(1)
    expect(has(ataxiaBasher_monkBashing2(), "kai choke")).toBeFalse()
    kaiReset(2); mnemKaiUnleashed = false
    expect(has(ataxiaBasher_monkBashing2(), "kai choke")).toBeFalse()
    kaiReset(2); ataxia.vitals.mp = 100 -- scraping bottom: skip the 50-mana choke
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

-- Senseless Flurry boon: keep the NUMB defence up in Rain form (balance recovers
-- 30% faster while numb). NUMB is self-only, 3s of eq -- the same idle channel as
-- Kai Choke, which OUTRANKS it for a round's eq. Gated on the GMCP-tracked
-- numbness defence + the bmAugment-style 5s attempt-hold.
describe("ataxiaBasher_monkBashing2 -- Senseless Flurry numb keeper", function()
  local function numbReset()
    reset()
    ataxia.vitals.form = "Rain"
    ataxia.defences = nil
    ataxia.mnemosyne = { _denizenCount = function() return 1 end }
    ataxiaTemp = {}
    mnemSenselessFlurry = true
    mnemKaiUnleashed = false
  end

  it("prepends numb to the combo in Rain when the defence is down", function()
    numbReset()
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "numb; ")).toBeTrue()
    expect(has(cmd, "combo")).toBeTrue() -- eq rider: the combo still swings
  end)

  it("skips numb while the defence is up, outside Rain, or without the boon", function()
    numbReset(); ataxia.defences = { numbness = true }
    expect(has(ataxiaBasher_monkBashing2(), "numb")).toBeFalse()
    numbReset(); ataxia.vitals.form = "Willow"
    expect(has(ataxiaBasher_monkBashing2(), "numb")).toBeFalse()
    numbReset(); mnemSenselessFlurry = false
    expect(has(ataxiaBasher_monkBashing2(), "numb")).toBeFalse()
  end)

  it("attempt-hold stops respam while the numb channel is in flight", function()
    numbReset()
    expect(has(ataxiaBasher_monkBashing2(), "numb")).toBeTrue()
    expect(has(ataxiaBasher_monkBashing2(), "numb")).toBeFalse() -- held
  end)

  it("Kai Choke outranks the numb refresh for the round's eq", function()
    numbReset()
    mnemKaiUnleashed = true
    ataxia.mnemosyne = { _denizenCount = function() return 3 end }
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "kai choke")).toBeTrue()
    expect(has(cmd, "numb")).toBeFalse() -- one eq spender per round
  end)

  it("still numbs on a shielded round (numb is self-targeted)", function()
    numbReset(); ataxiaBasher.shielded = true
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "shatter")).toBeTrue()
    expect(has(cmd, "numb; ")).toBeTrue()
  end)

  -- Review HIGH: numbness DEFERS damage, pinning HP -- the rate watchdog, danger
  -- levels, and the HP-gated escape ladder all go blind, then the lump lands as one
  -- blow that can exceed max HP in a crowd. Never numb in swarm-threshold rooms or
  -- mid-tactic: live HP data outranks 30% balance there.
  it("never numbs in a swarm-threshold crowd (HP-safety gates must stay live)", function()
    numbReset()
    ataxia.mnemosyne = { _denizenCount = function() return 3 end } -- no choke boon: crowd gate alone
    expect(has(ataxiaBasher_monkBashing2(), "numb")).toBeFalse()
  end)

  it("never numbs while a swarm tactic is running", function()
    numbReset()
    ataxia.mnemosyne = {
      _denizenCount = function() return 1 end,
      swarm = { state = "funnel", threshold = function() return 3 end },
    }
    expect(has(ataxiaBasher_monkBashing2(), "numb")).toBeFalse()
  end)

  -- Restore shared state for whoever runs after us.
  mnemSenselessFlurry = false
  ataxia.mnemosyne = nil
  ataxia.defences = nil
end)

-- ─── SPIRIT REND (Mnemosyne boon) ───────────────────────────────────────────
--
-- KAI ENFEEBLE halves a denizen's CURRENT health, so it is worth twice as much at 80% as at 40%
-- and illegal below the floor entirely. That makes it the one eq rider whose opportunity EXPIRES,
-- which is why it sorts ahead of the Kai Choke burst rather than behind it.

describe("Spirit Rend -- KAI ENFEEBLE as an eq rider", function()
  local function rendReset()
    reset()
    target = 12345                       -- numeric = denizen; the boon is the denizen permit
    ataxia.vitals.form = "Rain"
    mnemSpiritRend, mnemKaiUnleashed, mnemSenselessFlurry = true, false, false
    ataxiaTemp = {}
    ataxia.mnemosyne = { _denizenCount = function() return 1 end,
                         swarm = { state = "idle", threshold = function() return 3 end } }
    gmcp = { IRE = { Target = { Info = { hpperc = "80" } } } }
  end

  it("fires in Rain form on a denizen above the health floor", function()
    rendReset()
    expect(has(ataxiaBasher_monkBashing2(), "kai enfeeble 12345")).toBeTrue()
  end)

  -- The floor is the user's rule and the reason is arithmetic: halving 40% removes a fifth of the
  -- mob, halving 90% removes nearly half. Below the floor the cooldown is better saved.
  it("holds below the health floor", function()
    rendReset(); gmcp.IRE.Target.Info.hpperc = "50"
    expect(has(ataxiaBasher_monkBashing2(), "kai enfeeble")).toBeFalse()
    gmcp.IRE.Target.Info.hpperc = "51"
    expect(has(ataxiaBasher_monkBashing2(), "kai enfeeble")).toBeTrue()
  end)

  it("respects a raised floor from config", function()
    rendReset(); ataxiaBasher.spiritRendAt = 90
    expect(has(ataxiaBasher_monkBashing2(), "kai enfeeble")).toBeFalse()
    ataxiaBasher.spiritRendAt = nil
  end)

  it("is Rain-form only, like the choke and the numb refresh", function()
    rendReset(); ataxia.vitals.form = "Willow"
    expect(has(ataxiaBasher_monkBashing2(), "kai enfeeble")).toBeFalse()
  end)

  -- The AB says "Works on/against: Adventurers"; the BOON is what permits a denizen. Against a
  -- player this is an ordinary 61-kai ability and the basher has no business spending it.
  it("is PvE only -- never fires at a named player target", function()
    rendReset(); target = "Grulk"
    expect(has(ataxiaBasher_monkBashing2(), "kai enfeeble")).toBeFalse()
    target = 12345
  end)

  it("does nothing without the boon", function()
    rendReset(); mnemSpiritRend = false
    expect(has(ataxiaBasher_monkBashing2(), "kai enfeeble")).toBeFalse()
  end)

  it("skips a shielded round so the shield breaks first", function()
    rendReset(); ataxiaBasher.shielded = true
    expect(has(ataxiaBasher_monkBashing2(), "kai enfeeble")).toBeFalse()
  end)

  -- The 60s clock starts at the CONFIRMED line, never at send: a command the server ate has not
  -- spent the cooldown, and stamping on send would lock the ability out for a minute over a round
  -- that never happened.
  it("holds for 60s after a CONFIRMED enfeeble, not after a send", function()
    rendReset()
    expect(has(ataxiaBasher_monkBashing2(), "kai enfeeble")).toBeTrue()
    ataxiaBasher_spiritRendConfirm()
    expect(has(ataxiaBasher_monkBashing2(), "kai enfeeble")).toBeFalse()
    ataxiaTemp.spiritRendAt = ((getEpoch and getEpoch()) or os.time()) - 61
    ataxiaTemp.spiritRendPendingAt = nil
    expect(has(ataxiaBasher_monkBashing2(), "kai enfeeble")).toBeTrue()
  end)

  it("re-latches the flag from the confirm line (self-proving)", function()
    rendReset(); mnemSpiritRend = false
    ataxiaBasher_spiritRendConfirm()
    expect(mnemSpiritRend).toBeTrue()
  end)

  -- An UNCONFIRMED send holds only briefly, so an eaten command retries instead of locking out.
  it("retries an unconfirmed send rather than waiting the full cooldown", function()
    rendReset()
    expect(has(ataxiaBasher_monkBashing2(), "kai enfeeble")).toBeTrue()
    expect(has(ataxiaBasher_monkBashing2(), "kai enfeeble")).toBeFalse() -- inside the retry hold
    ataxiaTemp.spiritRendPendingAt = ((getEpoch and getEpoch()) or os.time()) - 7
    expect(has(ataxiaBasher_monkBashing2(), "kai enfeeble")).toBeTrue()  -- not 60s later
  end)

  -- A threshold we cannot evaluate is not a threshold we may assume. But refusing SILENTLY is
  -- this package's commonest failure, and here it would be invisible -- the ability costs no
  -- balance, so nothing else would look wrong.
  it("holds when the target's health cannot be read, and says so once", function()
    rendReset()
    gmcp = {}
    local said = 0
    local realEcho = ataxiaEcho
    ataxiaEcho = function() said = said + 1 end
    expect(has(ataxiaBasher_monkBashing2(), "kai enfeeble")).toBeFalse()
    ataxiaBasher_monkBashing2()
    ataxiaEcho = realEcho
    expect(said).toBe(1)   -- once, not once per round
  end)

  -- ORDER IS THE DECISION. Rend's window closes as the target drops; the choke is just as good
  -- next round. So rend goes first when both are eligible -- and the choke helper must not even
  -- be CALLED, or it would stamp its own retry guard for a round it did not win.
  it("outranks the Kai Choke burst when both are eligible", function()
    rendReset()
    mnemKaiUnleashed = true
    ataxia.mnemosyne._denizenCount = function() return 3 end
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "kai enfeeble")).toBeTrue()
    expect(has(cmd, "kai choke")).toBeFalse()
    expect(ataxiaTemp.kaiChokePendingAt).toBeNil()  -- the loser stamped nothing
  end)

  it("lets the choke through once rend is on cooldown", function()
    rendReset()
    mnemKaiUnleashed = true
    ataxia.mnemosyne._denizenCount = function() return 3 end
    ataxiaBasher_spiritRendConfirm()          -- rend now held for 60s
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "kai enfeeble")).toBeFalse()
    expect(has(cmd, "kai choke")).toBeTrue()
  end)

  -- Restore shared state for whoever runs after us.
  mnemSpiritRend, mnemKaiUnleashed = false, false
  target = "manticore"
  gmcp = nil
  ataxia.mnemosyne = nil
  ataxiaTemp = {}
end)

-- ─── TEKURA GETS THE SAME KAIDO RIDERS (v4.7.297, user-directed) ───────────────────────────
--
-- "The monk boons should also be coded to be used when I am in tekura. In tekura I am only in
-- one stance. SO the stance criteria for tekura needs to be removed."
--
-- Kai Choke, Kai Enfeeble (Spirit Rend), and Numbness are all Kaido abilities, and Kaido is the
-- skill Tekura and Shikudo SHARE (CLAUDE.md: "Monk: Tekura/Shikudo, Kaido, Telepathy") -- so
-- "Rain form" was always user doctrine for WHICH Shikudo form to use them in, never a
-- restriction to Shikudo itself. Before this fix `ataxia.vitals.form` is nil for a Tekura Monk,
-- so a bare `form ~= "Rain"` gate silently blocked all three every time, AND the `elseif tekura`
-- branch of ataxiaBasher_monkBashing2 never even CALLED the three rider helpers -- both halves
-- had to change. No stance-NAME filtering: `ataxia.vitals.stance` truthy already means Tekura
-- (the discriminator the dispatcher itself uses), and a Tekura Monk sits in exactly one stance
-- during ordinary bashing.
describe("ataxiaBasher_monkBashing2 -- Tekura gets the Kaido eq riders too", function()
  local function tekuraReset()
    reset()
    ataxia.vitals.form = nil
    ataxia.vitals.stance = "Horse" -- any truthy stance; the NAME is deliberately not checked
    ataxia.mnemosyne = { _denizenCount = function() return 3 end,
                         swarm = { state = "idle", threshold = function() return 3 end } }
    ataxiaTemp = {}
    mnemKaiUnleashed, mnemSenselessFlurry, mnemSpiritRend = false, false, false
  end

  it("still swings the unarmed combo with no boon at all", function()
    tekuraReset()
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "unwield all")).toBeTrue()
    expect(has(cmd, "combo " .. target .. " sdk ucp ucp")).toBeTrue()
  end)

  it("prepends kai choke to the Tekura combo (eq rides the balance swing)", function()
    tekuraReset()
    mnemKaiUnleashed = true
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "kai choke " .. target)).toBeTrue()
    expect(has(cmd, "combo " .. target .. " sdk ucp ucp")).toBeTrue()
    expect(cmd:find("kai choke", 1, true) < cmd:find("combo", 1, true)).toBeTrue()
  end)

  it("prepends the numb refresh to the Tekura combo", function()
    tekuraReset()
    ataxia.mnemosyne._denizenCount = function() return 1 end -- under the numb crowd gate
    mnemSenselessFlurry = true
    ataxia.defences = nil
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "numb; ")).toBeTrue()
    expect(has(cmd, "combo")).toBeTrue()
    ataxia.defences = nil
  end)

  it("prepends kai enfeeble to the Tekura combo against a denizen above the floor", function()
    tekuraReset()
    target = 12345
    mnemSpiritRend = true
    gmcp = { IRE = { Target = { Info = { hpperc = "80" } } } }
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "kai enfeeble 12345")).toBeTrue()
    expect(has(cmd, "combo 12345 sdk ucp ucp")).toBeTrue()
    target = "manticore"; gmcp = nil
  end)

  -- Same eq slot, same order as Shikudo: rend's window closes, so it wins; the choke's helper
  -- must not even be called for a round rend takes, or it would stamp its own retry guard.
  it("keeps the rend-before-choke-before-numb order in Tekura too", function()
    tekuraReset()
    target = 12345
    mnemSpiritRend, mnemKaiUnleashed = true, true
    gmcp = { IRE = { Target = { Info = { hpperc = "80" } } } }
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "kai enfeeble")).toBeTrue()
    expect(has(cmd, "kai choke")).toBeFalse()
    expect(ataxiaTemp.kaiChokePendingAt).toBeNil()
    target = "manticore"; gmcp = nil
  end)

  it("still breaks a shield with rhk first -- shielded rounds skip rend and choke", function()
    tekuraReset()
    ataxiaBasher.shielded = true
    mnemKaiUnleashed, mnemSpiritRend = true, true
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "combo " .. target .. " rhk ucp ucp")).toBeTrue()
    expect(has(cmd, "kai choke")).toBeFalse()
    expect(has(cmd, "kai enfeeble")).toBeFalse()
  end)

  -- Numb is self-targeted, so unlike rend/choke it still rides a shielded round -- matching the
  -- Shikudo behaviour exactly.
  it("still numbs on a shielded Tekura round", function()
    tekuraReset()
    ataxia.mnemosyne._denizenCount = function() return 1 end -- under the numb crowd gate
    ataxiaBasher.shielded = true
    mnemSenselessFlurry = true
    local cmd = ataxiaBasher_monkBashing2()
    expect(has(cmd, "combo " .. target .. " rhk ucp ucp")).toBeTrue()
    expect(has(cmd, "numb; ")).toBeTrue()
  end)

  -- No stance-NAME filtering: the user's own words -- "In tekura I am only in one stance" --
  -- mean the boons must not care WHICH stance string charstats reports.
  it("does not care which stance name is reported", function()
    for _, name in ipairs({ "Horse", "Bear", "Dragon", "Scorpion" }) do
      tekuraReset()
      ataxia.vitals.stance = name
      mnemKaiUnleashed = true
      expect(has(ataxiaBasher_monkBashing2(), "kai choke")).toBeTrue()
    end
  end)

  -- Restore shared state for whoever runs after us.
  mnemKaiUnleashed, mnemSenselessFlurry, mnemSpiritRend = false, false, false
  target = "manticore"
  gmcp = nil
  ataxia.mnemosyne = nil
  ataxia.defences = nil
  ataxiaTemp = {}
end)

