--- test_basher_depthswalker.lua -- Depthswalker PvE bashing (v4.7.142 overhaul)
-- Verifies ataxiaBasher_dwBattlerage + ataxiaBasher_dwKeeper + the rewritten
-- ataxiaBasher_depthswalkerBashing: the owned timer-free rotation over the SIX
-- denizen-legal battlerage abilities, Erasure's affliction gate, Curse's aeon skip +
-- rage banking, Boinad's opt-in/crowd/word-balance gates, the shield fix (nakail is no
-- longer hidden behind the off-by-default rageraze toggle), the Terminus buff keepers,
-- and the separator hygiene the old two-line function got wrong.

require("mock_mudlet")

target = 7
ataxia = {
  settings = { separator = ";" },
  vitals = { rage = 0 },
  defences = {},
}
ataxiaBasher = { shielded = false, rageraze = false, battlerage = {} }
ataxiaTemp = {}
ataxiaTables = { depthswalker = { wordBal = true, age = 0, abilities = nil } }
stormhammerTargets = {}
gmcp = {
  Room = { Info = { area = "" } },
  Char = { Status = { class = "Depthswalker", level = "80 " } },
  IRE = { Target = { Info = {} } },
}
function ataxiaEcho() end
function ataxiaBasher_rageAfford(rage, cost)
  return (tonumber(rage) or 0) >= (cost + (tonumber(ataxiaBasher.rageFloor) or 0))
end
local validTargets = 1
function ataxiaBasher_validTargets() return validTargets end
local denizenAffs = {}
function ataxiaBasher_dsHasAff(id, aff) return denizenAffs[aff] == true end

local _epoch = getEpoch
local clock = 900000
getEpoch = function() return clock end

local file = "src_new/scripts/levi_ataxia/levi/ataxia/basher/002_Class_Bashing.lua"
local ok, err = pcall(dofile, file)
if not ok then error("Failed to load class-bashing file: " .. tostring(err)) end

local function has(cmd, needle) return cmd:find(needle, 1, true) ~= nil end

-- Danger level drives the keeper gate (a standing buff is not worth a round while we
-- are losing the fight); default to the healthy state for every other test.
local dangerLevel = "attack"
function ataxiaBasher_dangerLevel() return dangerLevel end

local function reset()
  ataxiaBasher.shielded, ataxiaBasher.rageraze = false, false
  ataxiaBasher.cullingBlade, ataxiaBasher.rageConserveThreshold = nil, nil
  ataxiaBasher.rageFloor, ataxiaBasher.dwBoinad, ataxiaBasher.dwCull = nil, false, false
  ataxiaBasher.dwKeepers = false -- keepers tested in their own block
  ataxiaBasher.enabled = true
  ataxia.vitals.rage = 0
  ataxia.defences = {}
  ataxiaTemp = {}
  ataxiaTables.depthswalker = { wordBal = true, age = 0, abilities = nil }
  denizenAffs = {}
  dwFlashforward = false
  ataxiaBasher.dwAgeCap = 400
  dangerLevel = "attack"
  validTargets = 1
  stormhammerTargets = {}
  gmcp.IRE.Target.Info = {}
  gmcp.Room.Info.area = ""
  clock = clock + 100 -- past every cooldown and the global BR gate
end

describe("ataxiaBasher_dwBattlerage -- owned rotation", function()
  it("fires Curse > Lash > Drain by priority (one pick per balance round)", function()
    reset(); ataxia.vitals.rage = 100
    -- Control first: Curse (denizen AEON) outranks raw damage, the same rule the user
    -- set for Golden Dragon's Deaden.
    expect(has(ataxiaBasher_dwBattlerage(";"), "chrono curse 7")).toBeTrue()
    clock = clock + 4
    expect(has(ataxiaBasher_dwBattlerage(";"), "shadow lash 7")).toBeTrue()
    clock = clock + 4
    expect(has(ataxiaBasher_dwBattlerage(";"), "shadow drain 7")).toBeTrue()
    clock = clock + 4
    expect(ataxiaBasher_dwBattlerage(";")).toBe("") -- all stamped, still on cooldown
  end)

  it("respects the real AB rage costs (drain 14, lash 36)", function()
    reset(); ataxia.vitals.rage = 13; denizenAffs.aeon = true
    expect(ataxiaBasher_dwBattlerage(";")).toBe("")
    reset(); ataxia.vitals.rage = 14; denizenAffs.aeon = true
    expect(has(ataxiaBasher_dwBattlerage(";"), "shadow drain")).toBeTrue()
    -- Aeon already up skips Curse, isolating the two damage abilities.
    reset(); ataxia.vitals.rage = 35; denizenAffs.aeon = true
    expect(has(ataxiaBasher_dwBattlerage(";"), "shadow drain")).toBeTrue() -- lash unaffordable
    reset(); ataxia.vitals.rage = 36; denizenAffs.aeon = true
    expect(has(ataxiaBasher_dwBattlerage(";"), "shadow lash")).toBeTrue()
  end)

  it("owns culling: reap outranks the rotation and ignores the rage floor", function()
    reset(); ataxia.vitals.rage = 36; ataxiaBasher.cullingBlade = true
    ataxiaBasher.rageFloor = 40 -- reap must stay exempt
    expect(has(ataxiaBasher_dwBattlerage(";"), "reap 7")).toBeTrue()
    reset(); ataxia.vitals.rage = 100; denizenAffs.aeon = true
    ataxiaBasher.cullingBlade = true; ataxiaTemp.bladeCooldown = true
    expect(has(ataxiaBasher_dwBattlerage(";"), "shadow lash")).toBeTrue()
  end)

  it("Erasure only fires when the mob actually carries weakness or amnesia", function()
    reset(); ataxia.vitals.rage = 100
    expect(has(ataxiaBasher_dwBattlerage(";"), "chrono erasure")).toBeFalse() -- solo: never
    reset(); ataxia.vitals.rage = 100; denizenAffs.weakness = true
    expect(has(ataxiaBasher_dwBattlerage(";"), "chrono erasure 7")).toBeTrue()
    reset(); ataxia.vitals.rage = 100; denizenAffs.amnesia = true
    expect(has(ataxiaBasher_dwBattlerage(";"), "chrono erasure 7")).toBeTrue()
  end)

  it("Curse applies denizen AEON, skips a mob that already has it, and BANKS rage", function()
    reset(); ataxia.vitals.rage = 30 -- curse (24) affordable, lash (36) not
    expect(has(ataxiaBasher_dwBattlerage(";"), "chrono curse 7")).toBeTrue()
    reset(); ataxia.vitals.rage = 30; denizenAffs.aeon = true
    expect(has(ataxiaBasher_dwBattlerage(";"), "shadow drain")).toBeTrue() -- aeon up: skip
    -- v4.7.145 (MEASURED: aeon lasted ~5.6s against curse's 35s cd, ~16% uptime):
    -- curse no longer BANKS. At 20 rage it is unaffordable, so the cheap filler fires
    -- rather than the round being wasted holding rage for a 5-second window.
    reset(); ataxia.vitals.rage = 20
    expect(has(ataxiaBasher_dwBattlerage(";"), "shadow drain")).toBeTrue()
  end)

  it("Boinad is opt-in, needs a second denizen, and yields the word balance", function()
    reset(); ataxia.vitals.rage = 100; validTargets = 2
    expect(has(ataxiaBasher_dwBattlerage(";"), "intone boinad")).toBeFalse() -- opt-in off
    reset(); ataxia.vitals.rage = 100; ataxiaBasher.dwBoinad = true; denizenAffs.aeon = true
    expect(has(ataxiaBasher_dwBattlerage(";"), "intone boinad")).toBeFalse() -- solo
    reset(); ataxia.vitals.rage = 100; ataxiaBasher.dwBoinad = true; denizenAffs.aeon = true
    validTargets = 2; stormhammerTargets = { 7, 9 }
    local cmd = ataxiaBasher_dwBattlerage(";")
    expect(has(cmd, "intone boinad 9")).toBeTrue() -- charms the mob we're NOT killing
    expect(ataxiaTemp.brCharmTgt).toBe(9)          -- so the charm is attributed correctly
    -- No word balance -> yields to nothing else that needs it.
    reset(); ataxia.vitals.rage = 100; ataxiaBasher.dwBoinad = true; denizenAffs.aeon = true
    validTargets = 2; stormhammerTargets = { 7, 9 }
    ataxiaTables.depthswalker.wordBal = false
    expect(has(ataxiaBasher_dwBattlerage(";"), "intone boinad")).toBeFalse()
  end)

  it("replays the same pick across the 0.3s re-queue loop", function()
    reset(); ataxia.vitals.rage = 100
    local first = ataxiaBasher_dwBattlerage(";")
    expect(has(first, "chrono curse")).toBeTrue()
    clock = clock + 1
    expect(ataxiaBasher_dwBattlerage(";")).toBe(first) -- byte-identical, no re-stamp
    expect(ataxiaTemp.dwBrAt.lash).toBe(nil)          -- the rotation did NOT advance
  end)

  it("conserves rage on nearly-dead mobs and clears the pending pick", function()
    reset(); ataxia.vitals.rage = 100
    ataxiaBasher.rageConserveThreshold = 15
    gmcp.IRE.Target.Info.hpperc = "10%"
    expect(ataxiaBasher_dwBattlerage(";")).toBe("")
    expect(ataxiaTemp.dwBrPending).toBe(nil)
  end)

  it("fire-line confirmation restamps the cooldown and frees the hold", function()
    reset(); ataxia.vitals.rage = 30
    expect(has(ataxiaBasher_dwBattlerage(";"), "chrono curse")).toBeTrue()
    clock = clock + 2
    ataxiaBasher_dwConfirm("curse")
    expect(ataxiaTemp.dwBrPending).toBe(nil)
    expect(ataxiaTemp.dwBrAt.curse).toBe(clock)
  end)
end)

describe("ataxiaBasher_depthswalkerBashing -- assembly and the shield fix", function()
  it("swings shadow reap with the battlerage, and never doubles separators", function()
    reset(); ataxia.vitals.rage = 100
    local cmd = ataxiaBasher_depthswalkerBashing()
    expect(has(cmd, "shadow reap 7")).toBeTrue()
    expect(has(cmd, "chrono curse 7")).toBeTrue()
    expect(has(cmd, ";;")).toBeFalse()      -- the old function produced "drain 7;;reap 7"
    expect(cmd:sub(1, 1) == ";").toBeFalse() -- ...and a leading ";" with no battlerage
  end)

  it("NEVER spends rage on a shield by default -- just keeps swinging (v4.7.143)", function()
    reset(); ataxiaBasher.shielded = true; ataxia.vitals.rage = 100
    local cmd = ataxiaBasher_depthswalkerBashing()
    expect(cmd).toBe("shadow reap 7")            -- no nakail: rage is for damage
    expect(has(cmd, "chrono curse")).toBeFalse() -- no battlerage on a shield round
    expect(ataxiaTemp.dwBrAt).toBe(nil)          -- ...so no cooldown stamp is burned
  end)

  it("razes with NAKAIL only when rageraze is explicitly opted in", function()
    reset(); ataxiaBasher.shielded = true; ataxiaBasher.rageraze = true
    ataxia.vitals.rage = 40
    expect(ataxiaBasher_depthswalkerBashing()).toBe("intone nakail 7;shadow reap 7")
    -- ...and even then only when it is affordable and the word balance is free.
    reset(); ataxiaBasher.shielded = true; ataxiaBasher.rageraze = true
    ataxia.vitals.rage = 16
    expect(ataxiaBasher_depthswalkerBashing()).toBe("shadow reap 7")
    reset(); ataxiaBasher.shielded = true; ataxiaBasher.rageraze = true
    ataxia.vitals.rage = 40; ataxiaTables.depthswalker.wordBal = false
    expect(ataxiaBasher_depthswalkerBashing()).toBe("shadow reap 7")
  end)

  it("swaps the primary swing to shadow cull on request", function()
    reset(); ataxiaBasher.dwCull = true
    expect(has(ataxiaBasher_depthswalkerBashing(), "shadow cull 7")).toBeTrue()
  end)
end)

describe("ataxiaBasher_dwKeeper -- Terminus buffs on the word balance", function()
  it("intones a buff whose defence is down, one per round", function()
    reset(); ataxiaBasher.dwKeepers = true
    expect(ataxiaBasher_dwKeeper(";")).toBe("intone trusad;") -- crit chance vs denizens
    expect(ataxiaBasher_dwKeeper(";")).toBe("intone tsuura;") -- next one down
  end)

  it("goes quiet once every tracked defence is up (one-time buffs, not a timer)", function()
    reset(); ataxiaBasher.dwKeepers = true
    ataxia.defences = { precision = true, durability = true, bodyaugment = true }
    -- Terminus words persist once intoned, so with all three standing there is nothing
    -- to re-assert -- the keeper must NOT spam the weapon augments on a timer.
    expect(ataxiaBasher_dwKeeper(";")).toBe("")
  end)

  it("re-ups only the defence that actually dropped", function()
    reset(); ataxiaBasher.dwKeepers = true
    ataxia.defences = { precision = true, bodyaugment = true } -- durability fell
    expect(ataxiaBasher_dwKeeper(";")).toBe("intone tsuura;")
  end)

  it("never spends the word balance while a shield is standing (nakail outranks it)", function()
    reset(); ataxiaBasher.dwKeepers = true; ataxiaBasher.shielded = true
    expect(ataxiaBasher_dwKeeper(";")).toBe("")
  end)

  it("waits for the word balance and honours the known-ability list", function()
    reset(); ataxiaBasher.dwKeepers = true
    ataxiaTables.depthswalker.wordBal = false
    expect(ataxiaBasher_dwKeeper(";")).toBe("")
    -- A scraped AB TERMINUS list that lacks a word must skip it (user's live list has
    -- trusad/tsuura/mainaas/mainaad/balateth but NOT laiad).
    reset(); ataxiaBasher.dwKeepers = true
    ataxiaTables.depthswalker.abilities = { tsuura = true } -- trusad not researched
    expect(ataxiaBasher_dwKeeper(";")).toBe("intone tsuura;")
  end)

  it("does not spend a round on buffs while we are in danger (v4.7.145)", function()
    reset(); ataxiaBasher.dwKeepers = true
    dangerLevel = "shield"
    expect(ataxiaBasher_dwKeeper(";")).toBe("")
    dangerLevel = "flee"
    expect(ataxiaBasher_dwKeeper(";")).toBe("")
    dangerLevel = "attack"
    expect(ataxiaBasher_dwKeeper(";")).toBe("intone trusad;")
  end)

  it("is off entirely when disabled", function()
    reset(); ataxiaBasher.dwKeepers = false
    expect(ataxiaBasher_dwKeeper(";")).toBe("")
  end)
end)

describe("Flashforward boon -- keep chrono blur up", function()
  it("does nothing without the boon", function()
    reset()
    expect(ataxiaBasher_dwFlashforward(";")).toBe("")
  end)

  it("re-ups chrono blur while the boon is up and blur is down", function()
    reset(); dwFlashforward = true
    expect(ataxiaBasher_dwFlashforward(";")).toBe("chrono blur;")
  end)

  it("leaves it alone when the blur defence is already standing", function()
    reset(); dwFlashforward = true
    ataxia.defences.blur = true
    expect(ataxiaBasher_dwFlashforward(";")).toBe("")
  end)

  it("holds off re-sending while the defence line lands", function()
    reset(); dwFlashforward = true
    expect(ataxiaBasher_dwFlashforward(";")).toBe("chrono blur;")
    expect(ataxiaBasher_dwFlashforward(";")).toBe("") -- 8s attempt-hold
    clock = clock + 9
    expect(ataxiaBasher_dwFlashforward(";")).toBe("chrono blur;")
  end)

  it("respects the age cap -- bashing must not price out the chrono kit", function()
    reset(); dwFlashforward = true
    ataxiaTables.depthswalker.age = 401
    expect(ataxiaBasher_dwFlashforward(";")).toBe("")
    ataxiaTables.depthswalker.age = 400
    expect(ataxiaBasher_dwFlashforward(";")).toBe("chrono blur;")
  end)

  it("rides every round -- including shielded ones (the buff is on US)", function()
    reset(); dwFlashforward = true; ataxia.vitals.rage = 100
    expect(has(ataxiaBasher_depthswalkerBashing(), "chrono blur;")).toBeTrue()
    reset(); dwFlashforward = true; ataxiaBasher.shielded = true
    local cmd = ataxiaBasher_depthswalkerBashing()
    expect(cmd).toBe("chrono blur;shadow reap 7")
  end)
end)

-- ONE WORD BALANCE PER CHAIN (v4.7.193, Codex adversarial review). The keeper and Boinad
-- both spend the single word balance, and each checked `ataxiaTables.depthswalker.wordBal`
-- -- the balance we hold RIGHT NOW, which is still true while the keeper is merely a
-- string in the buffer. The whole `;`-chain is ONE queue entry, so both intones ran back
-- to back the instant it fired: the keeper took the balance and Boinad was rejected,
-- having already stamped a 38s cooldown, armed the pending replay, armed the global
-- battlerage cooldown and possibly spent a Rage-Fuelled charge. A current-state gate
-- cannot see what the same round has already claimed -- the caller has to say so.
describe("keeper and Boinad never share the word balance in one chain", function()
  local function armBoth()
    reset()
    ataxiaBasher.dwKeepers = true      -- trusad is down, so the keeper wants the word
    ataxiaBasher.dwBoinad = true       -- boinad is opt-in
    ataxia.vitals.rage = 100
    validTargets = 2                   -- boinad is a crowd ability
    stormhammerTargets = { 7, 9 }
    denizenAffs.aeon = true            -- so `curse` (skipIfAff aeon) yields to boinad
  end

  it("boinad stands down when the keeper already claimed the word", function()
    armBoth()
    expect(ataxiaBasher_dwBattlerage(";", true)).toBe("shadow lash 7;") -- next non-word pick
  end)

  it("boinad still fires when no keeper word went out", function()
    armBoth()
    expect(ataxiaBasher_dwBattlerage(";", false)).toBe("intone boinad 9;")
  end)

  it("stamps NOTHING for boinad on the round it stood down", function()
    armBoth()
    ataxiaBasher_dwBattlerage(";", true)
    expect((ataxiaTemp.dwBrAt or {}).boinad).toBe(nil)
  end)

  it("the assembled round carries at most ONE intone", function()
    armBoth()
    local cmd = ataxiaBasher_depthswalkerBashing()
    local n = 0
    for _ in cmd:gmatch("intone") do n = n + 1 end
    expect(n <= 1).toBeTrue()
    expect(cmd:find("intone trusad", 1, true) ~= nil).toBeTrue() -- keeper wins the tie
  end)

  it("boinad gets the word back once the keeper has nothing left to raise", function()
    armBoth()
    -- The keeper outranks boinad for as long as ANY of its three Terminus defences is
    -- down -- it walks trusad -> tsuura -> mainaas, one per round. That is the intended
    -- ordering (a dropped defence is rarer and more valuable than a charm), and it is
    -- self-limiting: the words persist once intoned, so the keeper goes quiet and hands
    -- the word balance back rather than holding it forever.
    ataxia.defences = { precision = true, durability = true, bodyaugment = true }
    expect(ataxiaBasher_dwKeeper(";")).toBe("") -- nothing to re-assert
    local cmd = ataxiaBasher_depthswalkerBashing()
    expect(cmd:find("intone boinad", 1, true) ~= nil).toBeTrue()
    expect(cmd:find("intone trusad", 1, true)).toBe(nil)
  end)
end)

-- CONTROL-FIRST ORDERING (v4.7.198). Against a denizen on ataxiaBasher.controlMobs, the
-- abilities flagged `slows` float to the front of the pick order. Chrono Curse applies AEON
-- -- the mob acts once per lengthy balance -- so it is Depthswalker's contribution.
--
-- `slows`, NOT `control`: in this rotation `control` already means "BANK rage until
-- affordable", which v4.7.145 measured as a LOSS for curse (aeon ~5.6s against a 35s
-- cooldown). Overloading the key silently restored that banking, and the existing curse test
-- caught it -- hence the separate flag.
describe("control-first denizens put the AEON ability ahead of damage", function()
  local realControlFirst
  local function arm(on)
    reset()
    ataxia.vitals.rage = 100 -- everything affordable, so ORDER is the only variable
    realControlFirst = ataxiaBasher_controlFirst
    ataxiaBasher_controlFirst = function() return on end
  end
  local function disarm() ataxiaBasher_controlFirst = realControlFirst end

  -- Curse sits second in DW_BR, so at plain full rage it fires anyway; the ordering only
  -- becomes observable where something else reorders the table. That something is the
  -- Rage-Fuelled free charge, which sorts DESCENDING BY COST to spend the charge on the
  -- dearest ability -- putting Shadow Lash (36) ahead of Curse (24). Control-first has to
  -- compose with that, not fight it: float the slowing ability back to the front while
  -- keeping the dearest-first rule among the rest.
  it("with a free charge banked, cost-first normally wins and takes Shadow Lash", function()
    arm(false)
    ataxiaTemp.brFreeCharge = true
    expect(has(ataxiaBasher_dwBattlerage(";"), "shadow lash")).toBeTrue()
    disarm()
  end)

  it("control-first overrides that and takes Chrono Curse (AEON) instead", function()
    arm(true)
    ataxiaTemp.brFreeCharge = true
    expect(has(ataxiaBasher_dwBattlerage(";"), "chrono curse 7")).toBeTrue()
    disarm()
  end)

  it("and takes Curse at plain full rage too", function()
    arm(true)
    expect(has(ataxiaBasher_dwBattlerage(";"), "chrono curse 7")).toBeTrue()
    disarm()
  end)

  it("still respects the aeon skip -- no point re-applying what is already up", function()
    arm(true); denizenAffs.aeon = true
    expect(has(ataxiaBasher_dwBattlerage(";"), "chrono curse")).toBeFalse()
    disarm()
  end)

  it("does NOT re-enable rage banking (the v4.7.145 measurement stands)", function()
    arm(true); ataxia.vitals.rage = 20 -- curse (24) unaffordable
    -- Banking would return "" and waste the round holding rage for a ~5.6s aeon window.
    expect(has(ataxiaBasher_dwBattlerage(";"), "shadow drain")).toBeTrue()
    disarm()
  end)
end)

-- Restore shared state for whoever runs after us (files share one Lua state).
dwFlashforward = false
getEpoch = _epoch
target = nil
stormhammerTargets = {}
