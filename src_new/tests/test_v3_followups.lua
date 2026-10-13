--- test_v3_followups.lua -- follow-ups to "one target tree, one charge" (v4.7.420)
--
-- A1. syncToOldSystemV3 (007) only visited afflictions still in some branch, so a cure V3 resolved
--     to its only candidate left tAffs true while haveAff read 0, for every cure, not just the tree.
--     The sync now clears what V3 held at its last sync and holds nowhere now: V3's own keys only,
--     once, and a reset forgets them rather than clearing them. It also clears, once, what drops
--     under haveAff's 30%: three cures over four afflictions leave each at 1/4.
-- A2. erAff("haemophilia") (017) reset the bleed counters and never tAffs.haemophilia.
-- A3. Trigger 318 erased a passive's random cure (tSingleRandom / tMultipleRandom) after the passive
--     trigger had already charged it in V3 (onClassCureV3 -> onPassiveCureV3): one cure, two charges.
--     With V3 on it no longer erases, so onPassiveCureV3 (008) does the erase's other two jobs: it
--     takes a level-1 broken limb (simple-tracked, in no branch) when no branch can pay for the cure,
--     and it reports what it made certain through the public API.
-- A smoke that disproved a certain asthma (collapseAffAbsentV3, 007) emptied every branch, and
-- through the sync tAffs too; it now removes asthma alone.
--
-- The REAL tracker (007, 008), public API (017) and tSingleRandom / tMultipleRandom (curing/002) run
-- here, driven by the REAL bodies of the kelp, smoke, Syphon and Dragonheal triggers, the prompt
-- trigger 318 and the raffs alias. Lines are verbatim: LcJC = kb/raw/logs/2026-10-11_mystor_shikudo-
-- vs-apostate_win_LcJC-rJ5.txt, iJVmpL = kb/raw/logs/2026-10-11_mystor_shikudo-vs-infernal-dwc_win_
-- c.iJVmpL.txt, guide = kb/raw/guides/active-and-passive-cures-with-fire-lines.txt. Every global the
-- loaded files create or replace is restored at the end (one shared Lua state for all test files).

local mock = require("mock_mudlet")
local before = {}
for k, v in pairs(_G) do before[k] = v end
local savedContains = table.contains

-- The V3 files initialise these as `X = X or {...}`, so a table left by an earlier test file would
-- be reused and mutated here. Cleared first, the loads build fresh ones, which the restore drops.
for _, k in ipairs({ "afflictionStatesV3", "affConfigV3", "simpleAffsV3", "affCacheV3", "targetBurningLevelV3",
  "affLastConfirmedV3", "targetDefensesV3", "cureBalancesV3", "cureBalanceTimerIDsV3", "passiveCooldownsV3",
  "negativeConfirmTimersV3", "tAffsV2", "tAffStacksV2" }) do
  _G[k] = nil
end
ataxiaTemp, tAffs, affTimers = {}, {}, {}

for _, f in ipairs({
  "src_new/scripts/levi_ataxia/levi/ataxia/017_Affliction_Management.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/curing/002_Wide_Groups.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/007_Branching_State_Tracker.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/008_V3_Integration.lua",
}) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end

-- table.contains is a Mudlet extension (tarAffed uses it); restored at the end.
table.contains = table.contains or function(t, v)
  for _, x in pairs(t) do if x == v then return true end end
  return false
end

local TL = dofile("src_new/tests/trigger_lib.lua")
local TRIG = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
local KELP = TRIG .. "herbs/003_Kelp_(Unknown).lua"
local SMOKE = TRIG .. "390_Smoked.lua"
local SYPHON = TRIG .. "passive_active/026_Syphon_(Apostate).lua"
local DRAGONHEAL = TRIG .. "passive_active/005_Dragonheal.lua"
local RAFFS = "src_new/aliases/levi_ataxia/for_levi/levi_062424/combat_aliases/011_Reset_Afflictions_on_Target.lua"

local AURUM = "Agathon eats an aurum flake."                        -- LcJC:235
local DRAG = "Agathon takes a long drag off his pipe."              -- iJVmpL:1177
local GLOW = "A demonic crimson glow emanates from Agathon."        -- LcJC:627 (Apostate Syphon)
local KEENING = "Lii lets out a great keening, casting the impurities from her form." -- guide:30 (Dragonheal)

local function body(path)
  local fh = assert(io.open(path, "r"))
  local src = fh:read("*a"); fh:close()
  return assert((loadstring or load)(src:match("%]%]%-%-\r?\n(.*)$"), "=" .. path))
end
local KELP_BODY, SMOKE_BODY = body(KELP), body(SMOKE)
local SYPHON_BODY, DRAGONHEAL_BODY = body(SYPHON), body(DRAGONHEAL)
local PROMPT_BODY, RAFFS_BODY = body(TRIG .. "318_Prompt_Trigger.lua"), body(RAFFS)

-- The world the bodies run in. Only what the loaded files do not provide is stubbed, and 318's whole
-- body runs at every prompt, so what it reads is set to take its quiet branches: no basher, no class
-- with a rebounding rule, no limb counts, no room, no Shikudo strike in flight.
local CLASS = { Agathon = "Apostate", Lii = "Red Dragon" }
local now, echoed, events = 1000, {}, {}
local function world(who)
  now, echoed, events = 1000, {}, {}
  mock.reset()                          -- no timer from an earlier test may fire into this one
  getEpoch = function() return now end
  target = who or "Agathon"
  isTargeted = function(n) return n == target end
  -- Recorded, not dispatched: 017 registers "tar afflicted" by NAME, which the mock cannot call.
  raiseEvent = function(e, a) events[#events + 1] = { e, a } end
  checkTargetLocks = function() end     -- curing/003, not loaded
  ataxiaEcho, ataxia_Echo, zgui = function() end, function() end, nil
  cecho = function(s) echoed[#echoed + 1] = s end
  fg = function() end
  ataxiaTemp = { tarAffTimers = {} }
  tAffs, affTimers = {}, {}
  tBals = { tree = true, focus = true, plant = true, timers = {} }
  passiveFailsafe, anorexiaFailsafe, lastFocus, pariah, myrebounding = nil, nil, nil, nil, nil
  -- 390's legacy kelp backtrack and its V2 hook (001_Core, not loaded) stay out of the way.
  lastKelp, lastKelpAffs, kelpDisambiguateTimer, onTargetSmokeV2 = nil, nil, nil, nil
  ataxiaNDB_getClass = function(n) return CLASS[n] end
  ataxia_promptCommands, lpreapply = function() end, function() end
  haveDef = function() return false end
  gmcp, ataxiaTables, lb, shikudoLedger = {}, {}, {}, nil
  ataxiaBasher = { enabled = false }
  affConfigV3.enabled = true
  resetStatesV3()
end

-- A trigger body on its line, as Mudlet runs it.
local function fire(fn, text, name)
  line = text
  matches = { text, name }
  fn()
end
local function prompt()
  line = ""                             -- 318's pattern is the prompt itself (type 7)
  PROMPT_BODY()
end

local P = function(a) return getAffProbabilityV3(a) end
local function sum(affs)
  local s = 0
  for _, a in ipairs(affs) do s = s + P(a) end
  return s
end
-- Branch weights are sixths and quarters, so compare with a tolerance and say what came out.
local function near(got, want, what)
  if math.abs(got - want) > 1e-9 then
    error(string.format("%s: expected %.4f but got %.4f", what, want, got), 2)
  end
end
-- V3 and tAffs agree that it is gone; the error names the affliction and the test's line.
local function gone(a)
  if P(a) ~= 0 or tAffs[a] ~= false then
    error(string.format("%s should be gone: P=%s, tAffs=%s", a, tostring(P(a)), tostring(tAffs[a])), 2)
  end
end
local function erased()                 -- tSingleRandom's "<red> -<aff>" echo: an erase happened
  for _, s in ipairs(echoed) do
    if s:find("<red> -", 1, true) then return true end
  end
  return false
end
local function cured()                  -- what erAff reported, in order ("target cured aff")
  local out = {}
  for _, e in ipairs(events) do
    if e[1] == "target cured aff" then out[#out + 1] = e[2] end
  end
  return out
end

-- Mystor's tracker on Agathon at LcJC:626, the prompt before the Syphon line.
local SIX = { "confusion", "dizziness", "weariness", "clumsiness", "healthleech", "lethargy" }
local FOUR = { "confusion", "dizziness", "weariness", "lethargy" }

local ok, err = pcall(function()
describe("A1: what V3 stops holding leaves tAffs too (syncToOldSystemV3, 007)", function()
  it("a lone kelp candidate eaten off: gone from tAffs as well as V3", function()
    -- LcJC:232-238: weariness was Agathon's only affliction besides prone; he ate an aurum flake
    -- (235) and it was gone. Asthma is the case group H reproduced with targetAteWrapper.
    for _, aff in ipairs({ "weariness", "asthma" }) do
      world()
      tarAffed(aff)
      fire(KELP_BODY, AURUM, "Agathon")
      gone(aff)
    end
  end)

  it("every other cure V3 resolves to one candidate: smoke, salve, focus", function()
    for _, c in ipairs({
      { "aeon", function() onSmokeCureV3() end },
      { "itching", function() onSalveCureV3("body") end },
      { "stupidity", function() onTargetFocusV3() end },
    }) do
      world()
      tarAffed(c[1])
      c[2]()
      gone(c[1])
    end
  end)

  it("only V3's own keys: what triggers write straight into tAffs survives the sync", function()
    world()
    tAffs.shield, tAffs.bleed, tAffs.horror = true, 300, 2
    tarAffed("asthma")
    fire(KELP_BODY, AURUM, "Agathon")
    gone("asthma")
    expect(tAffs.shield).toBe(true)
    expect(tAffs.bleed).toBe(300)
    expect(tAffs.horror).toBe(2)
  end)

  it("a reset forgets what V3 held: the raffs alias keeps its own defaults", function()
    -- raffs writes `tAffs = {blindness = true, deafness = true, ..., rebounding = true}` and then
    -- resets V3. V3 held rebounding and deafness; clearing them would undo the alias.
    world()
    tarAffed("rebounding", "deafness", "asthma")
    RAFFS_BODY()
    expect(P("rebounding")).toBe(0)
    expect(tAffs.rebounding).toBe(true)
    expect(tAffs.deafness).toBe(true)
    expect(tAffs.blindness).toBe(true)
    tarAffed("clumsiness")              -- a later sync does not clear them either
    expect(tAffs.rebounding).toBe(true)
    expect(tAffs.deafness).toBe(true)
  end)

  it("a reload mid-fight still knows what tAffs was told (the V3 tables survive it)", function()
    -- A focus syncs once, after it branches; a kelp or smoke syncs first (the anorexia/asthma proof),
    -- which would hide a forgotten set. Only 007 is reloaded: it is the file that holds the set.
    world()
    tarAffed("stupidity")
    dofile("src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/007_Branching_State_Tracker.lua")
    onTargetFocusV3()
    gone("stupidity")
    -- ... and at what probability: the drop under 30% compares against it. Dragonheal's passive
    -- branches before its one sync, as the focus does.
    world("Lii")
    tarAffed(unpack(FOUR))
    dofile("src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/007_Branching_State_Tracker.lua")
    fire(DRAGONHEAL_BODY, KEENING, "Lii")
    for _, a in ipairs(FOUR) do expect(tAffs[a]).toBe(false) end
  end)

  it("cleared once, on the drop: a later write by a trigger is not undone", function()
    -- tSingleRandom's erase (318 and 389 with V3 off) picks slickness (asthma + slickness puts
    -- asthma last) and arms the failsafe; a cure line inside 0.5 s writes it back into tAffs
    -- (restorePassiveCure, curing/002). V3 let go of slickness at the erase, so no later sync
    -- touches that write.
    world()
    tarAffed("asthma", "slickness")
    expect(tSingleRandom()).toBe("slickness")
    gone("slickness")
    restorePassiveCure()
    expect(tAffs.slickness).toBe(true)
    tarAffed("clumsiness")              -- any later sync
    expect(tAffs.slickness).toBe(true)
  end)

  it("a drop under haveAff's 30% leaves tAffs too: two kelp eats over four kelp afflictions", function()
    -- Not only passives: weariness, the first of the four on the kelp list (curing/002), is left at
    -- 3/14 after two eats. The sync left everything between 1% and 30% as it was, so haveAff said
    -- no and tAffs said yes.
    world()
    local K = { "asthma", "clumsiness", "weariness", "sensitivity" }
    tarAffed(unpack(K))
    fire(KELP_BODY, AURUM, "Agathon")
    now = now + 2                       -- past the target's herb balance (1.3 s)
    fire(KELP_BODY, AURUM, "Agathon")
    near(P("weariness"), 3 / 14, "weariness")
    expect(haveAff("weariness")).toBeFalse()
    expect(tAffs.weariness).toBe(false)
    for _, a in ipairs({ "asthma", "clumsiness", "sensitivity" }) do   -- 0.39, 0.64, 0.75: still there
      expect(haveAff(a)).toBeTrue()
      expect(tAffs[a]).toBe(true)
    end
  end)

  it("a drop under haveAff's 30% clears tAffs, once: a value written there afterwards stays", function()
    -- Dragonheal's three cures over four afflictions leave each at 1/4 (A3 below). The sync left
    -- everything between 1% and 30% as it was, so tAffs kept all four while haveAff read none.
    -- 390's kelp backtrack writes straight into tAffs (tAffs[lastKelp] = true); a later sync must
    -- not undo that, as V3 still holds the affliction under 30%.
    world("Lii")
    tarAffed(unpack(FOUR))
    fire(DRAGONHEAL_BODY, KEENING, "Lii")
    prompt()
    expect(tAffs.dizziness).toBe(false)
    tAffs.dizziness = true
    tarAffed("asthma")                  -- any later sync
    near(P("dizziness"), 0.25, "dizziness")
    expect(tAffs.dizziness).toBe(true)
  end)
end)

describe("A2: erAff('haemophilia') clears the affliction, not only the bleed (017)", function()
  it("given through tarAffed: gone from tAffs and V3, the bleed counters reset", function()
    world()
    tarAffed("haemophilia")
    tAffs.bleed, tAffs.bleeding = 300, 300
    erAff("haemophilia")
    gone("haemophilia")
    expect(tAffs.bleed).toBe(0)
    expect(tAffs.bleeding).toBe(0)
  end)

  it("a tAffs entry V3 never held (written before V3 loads, or straight into tAffs) is cleared too", function()
    world()
    tAffs.haemophilia = true
    erAff("haemophilia")
    expect(tAffs.haemophilia).toBe(false)
  end)
end)

describe("A3: a passive's random cure is charged once (318 after the passive line)", function()
  it("Syphon over six afflictions: the sum drops by one, no erase", function()
    -- Mystor's client charged this very line as one cure spread over the six: its readings summed to
    -- 330% at LcJC:626 and 229% at LcJC:629.
    world()
    tarAffed(unpack(SIX))
    fire(SYPHON_BODY, GLOW, "Agathon")
    prompt()
    near(sum(SIX), 5, "sum")
    for _, a in ipairs(SIX) do near(P(a), 5 / 6, a) end
    expect(erased()).toBeFalse()
    expect(ataxiaTemp.randomCure).toBeNil()
  end)

  it("asthma and slickness: no lock piece erased, nothing armed for a cure line to put back", function()
    world()
    tarAffed("asthma", "slickness")
    fire(SYPHON_BODY, GLOW, "Agathon")
    prompt()
    near(sum({ "asthma", "slickness" }), 1, "sum")
    near(P("slickness"), 0.5, "slickness")
    expect(passiveFailsafe).toBeNil()
  end)

  it("a lone candidate: gone from tAffs as well as V3 (the sync, A1)", function()
    world()
    tarAffed("lethargy")
    fire(SYPHON_BODY, GLOW, "Agathon")
    prompt()
    gone("lethargy")
  end)

  it("Dragonheal's three cures over six afflictions leave three: tMultipleRandom is not called", function()
    -- Six, so each is left at 1/2 and still in tAffs, where tMultipleRandom would find and erase
    -- three more (over four, each drops under 30% and leaves tAffs first: see the next test).
    world("Lii")
    tarAffed(unpack(SIX))
    fire(DRAGONHEAL_BODY, KEENING, "Lii")
    prompt()
    near(sum(SIX), 3, "sum")
    expect(ataxiaTemp.randomCure).toBeNil()
  end)

  it("Dragonheal's three cures over four leave one, and tAffs agrees with haveAff (each 1/4)", function()
    -- tMultipleRandom's erase used to take three of the four out of tAffs. Without it the sync
    -- must, or every tAffs reader keeps a lock that three of its pieces have left.
    world("Lii")
    tarAffed(unpack(FOUR))
    fire(DRAGONHEAL_BODY, KEENING, "Lii")
    prompt()
    near(sum(FOUR), 1, "sum")
    for _, a in ipairs(FOUR) do
      near(P(a), 0.25, a)
      expect(haveAff(a)).toBeFalse()
      expect(tAffs[a]).toBe(false)
    end
  end)

  it("a lone level-1 broken limb: the passive takes it, and says so", function()
    -- The four limbs are on the passive list but simple-tracked, so no branch holds them. 318's
    -- erase used to take them (the last four on tSingleRandom's list); with V3 on it no longer
    -- erases, so onPassiveCureV3 must. Prone is not on the passive list and stays.
    world()
    tarAffed("brokenleftleg", "prone")
    fire(SYPHON_BODY, GLOW, "Agathon")
    prompt()
    gone("brokenleftleg")
    expect(P("prone")).toBe(1)
    expect(#cured()).toBe(1)
    expect(cured()[1]).toBe("brokenleftleg")
  end)

  it("Dragonheal: one cure for the branch candidate, then a limb per cure, in the erase's order", function()
    -- Round one takes confusion; rounds two and three find no branch candidate and take limbs in
    -- the order 318's erase took them (left leg, right leg, left arm, right arm).
    world("Lii")
    tarAffed("confusion", "brokenrightarm", "brokenleftarm", "brokenrightleg")
    fire(DRAGONHEAL_BODY, KEENING, "Lii")
    prompt()
    gone("confusion")
    gone("brokenrightleg")
    gone("brokenleftarm")
    expect(P("brokenrightarm")).toBe(1)
    expect(tAffs.brokenrightarm).toBe(true)
  end)

  it("a limb beside a branch candidate stays, as on the tree (ataxia_targetTreeV3)", function()
    -- V3 cannot branch a simple-tracked affliction, so the cure goes to the branch candidate.
    world()
    tarAffed("confusion", "brokenleftleg")
    fire(SYPHON_BODY, GLOW, "Agathon")
    prompt()
    gone("confusion")
    expect(P("brokenleftleg")).toBe(1)
    expect(tAffs.brokenleftleg).toBe(true)
  end)

  it("with V3 off the limb is 318's to erase: two broken legs lose one, not two", function()
    local okInner, errInner = pcall(function()
      world()
      affConfigV3.enabled = false
      tarAffed("brokenleftleg", "brokenrightleg")
      fire(SYPHON_BODY, GLOW, "Agathon")
      prompt()
      gone("brokenleftleg")             -- tSingleRandom's pick: its list ends with the limbs
      expect(P("brokenrightleg")).toBe(1)
    end)
    affConfigV3.enabled = true
    if not okInner then error(errInner, 0) end
  end)

  it("a cure the passive made certain is reported ('target cured aff'); a guess is not", function()
    -- That event is the fight log's feed of target cures (misc_scripts/026). The old erase
    -- reported its guess, whichever affliction it was.
    world()
    tarAffed("lethargy")
    fire(SYPHON_BODY, GLOW, "Agathon")
    prompt()
    expect(#cured()).toBe(1)
    expect(cured()[1]).toBe("lethargy")

    world()
    tarAffed(unpack(SIX))
    fire(SYPHON_BODY, GLOW, "Agathon")
    prompt()
    expect(#cured()).toBe(0)
  end)

  it("with V3 disabled 318 still erases (tSingleRandom, tMultipleRandom)", function()
    local okInner, errInner = pcall(function()
      world()
      affConfigV3.enabled = false
      tarAffed(unpack(SIX))
      fire(SYPHON_BODY, GLOW, "Agathon")
      prompt()
      expect(P("lethargy")).toBe(0)     -- tSingleRandom's first pick on its own list
      expect(echoed[#echoed]).toBe("<red> -lethargy")

      -- Six, not four: three cures over four leave each at 1/4, which the sync now clears from
      -- tAffs (A1), so tMultipleRandom would find nothing to erase. Over six each is left at 1/2.
      world("Lii")
      affConfigV3.enabled = false
      tarAffed(unpack(SIX))
      fire(DRAGONHEAL_BODY, KEENING, "Lii")
      prompt()
      for _, a in ipairs({ "lethargy", "confusion", "healthleech" }) do  -- tMultipleRandom's first three
        expect(P(a)).toBe(0)
      end
    end)
    affConfigV3.enabled = true
    if not okInner then error(errInner, 0) end
  end)

  it("the triggers' own patterns match the logged lines", function()
    expect(TL.anyMatches(TL.patterns(KELP), AURUM)).toBeTrue()
    -- trigger_lib judges only ^-anchored regexes, so 390's first (gurgling) pattern is left out.
    local smoke = {}
    for _, p in ipairs(TL.patterns(SMOKE)) do
      if p.pat:sub(1, 1) == "^" then smoke[#smoke + 1] = p end
    end
    expect(TL.anyMatches(smoke, DRAG)).toBeTrue()
    expect(TL.anyMatches(TL.patterns(SYPHON), GLOW)).toBeTrue()
    expect(TL.anyMatches(TL.patterns(DRAGONHEAL), KEENING)).toBeTrue()
  end)
end)

describe("a smoke that disproves a certain asthma removes only asthma (collapseAffAbsentV3, 007)", function()
  it("the rest of the target stays, in V3 and in tAffs; the smoke still takes slickness", function()
    -- iJVmpL:1175-1179: Mystor's tracker read PAR SLCK clum hlch leth (1175) before Agathon smoked
    -- (1177) and PAR clum hlch leth after (1179). It had seen the fitness that took asthma (1173);
    -- here asthma is still certain, as if that line had been missed, so the smoke contradicts it.
    -- That emptied every branch, and the sync then cleared all five from tAffs as well.
    world()
    tarAffed("asthma", "paralysis", "slickness", "clumsiness", "healthleech", "lethargy")
    fire(SMOKE_BODY, DRAG, "Agathon")
    gone("asthma")
    gone("slickness")                   -- the only smoke cure among them (valerian)
    for _, a in ipairs({ "paralysis", "clumsiness", "healthleech", "lethargy" }) do
      expect(P(a)).toBe(1)
      expect(tAffs[a]).toBe(true)
    end
  end)
end)
end)

-- Restore the shared Lua state: drop every global the loaded files created and put back every
-- one they replaced. No timer armed here (cure balances, 390's tempTimer(0)) may fire into a later
-- file, so the mock is reset first.
mock.reset()
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
table.contains = savedContains
if not ok then error(err) end
