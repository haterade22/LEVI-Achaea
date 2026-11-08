--- test_serpent_notes.lua -- Serpent fixes from the relayed notes and their cross-check
--
-- The notes (kb/raw/players/serpent-2026-10-12.txt) were checked against the code, and these are
-- the faults that held:
--   S1  the three monkshood impatience sends skipped the sileris/fangbarrier gate the other
--       impulses use, so a blocked impulse went out every round and the gecko strip never ran
--       (scytherus mode's impulse skipped it too: B1 below);
--   S2  an Ekanelia reaction's result was never recorded, so our own impatience (and curare's
--       hypochondria, kalmia's slickness, loki's nausea + paralysis) never reached the tracker,
--       and the 2.5 s impatience cooldown had no caller;
--   S3  monkshood was still sent for impatience the target already had;
--   S4  fratricide was written to tAffs only, so haveAff("fratricide") was always false;
--   S5  the fratricide relapse window was 3.0 s; the notes say 2.25 s;
--   S6  the defence against a Serpent never prioritised hypochondria, or fratricide with scytherus.
-- And two the review of those found:
--   once S4 put fratricide on the tracker, a target's lobelia eat over masochism + fratricide left
--   masochism believed (fratricide stands near the front of both lobelia lists but is cured last),
--   so the next monkshood impulse dropped the masochism its reaction needs;
--   the offense's timers read os.clock(), CPU time on Linux and macOS, and S2 made the 2.5 s
--   impatience cooldown live.
-- And two follow-ups (v4.7.420):
--   B1  scytherus mode's impulse was the one impulse still without the sileris/fangbarrier gate;
--   B2  a target change reset the hypnosis chain's MODE with the chain, so after one in hypnolock
--       (ekhl) the next chain suggested fratricide and snapped with no seal. Its review found the
--       lock chain never ended: the snap left `sealed` set, which is canSnap() in lock mode, so
--       every later round sent SNAP and held off the impulses that need the eq slot.
--
-- Loads the REAL offense (serpent/002), the REAL trigger body (serpent/016), the REAL defence
-- handlers (algedonic_defense_1.0/001) and the REAL tracker (017's public API over V3, 007 + 008),
-- and builds whole rounds through serp_ekanelia_offense(). B2 also loads the REAL target switch
-- (016_Targeting_Functions) and the class check it reads (misc_scripts/002). Every global the
-- loaded files create or change is restored at the end (one shared Lua state for all test files),
-- and so are os.clock (held still here: the offense must not read it) and table.contains.

local mock = require("mock_mudlet")
local before = {}
for k, v in pairs(_G) do before[k] = v end
local savedClock, savedContains = os.clock, table.contains

-- These are initialised as `X = X or {...}` by the files below, so a table left by an earlier test
-- file (test_serpent_helpers loads 002 too) would be reused and mutated. Clearing them first makes
-- the loads build fresh ones, which the restore at the end drops (putting the old ones back).
for _, k in ipairs({ "serpent", "Algedonic", "lastImpulsed", "lastReboundingFlay", "lastImpatienceAttempt",
  "serpOffenseMode", "serpStrategy", "attackMode", "ekaneliaReady", "affTimers", "hSuggRequest", "hSuggActive",
  "afflictionStatesV3", "affConfigV3", "simpleAffsV3", "affCacheV3", "targetBurningLevelV3", "affLastConfirmedV3",
  "targetDefensesV3", "cureBalancesV3", "cureBalanceTimerIDsV3", "passiveCooldownsV3", "negativeConfirmTimersV3",
  "curingTable" }) do
  _G[k] = nil
end
ataxia = { settings = { separator = "::" }, playersHere = { "Agathon" }, afflictions = {} }
ataxiaTemp, tAffs, affTimers = {}, {}, {}
Algedonic = {}

-- table.contains is a Mudlet extension (tarAffed and serp_sendAttack use it); restored at the end.
table.contains = table.contains or function(t, v)
  for _, x in pairs(t) do if x == v then return true end end
  return false
end

local OFFENSE = "src_new/scripts/levi_ataxia/levi/levi_scripts/serpent/002_Serpent_Offense.lua"
local DEFENCE = "src_new/scripts/levi_ataxia/levi/levi_scripts/algedonic_defense_1.0/001_Anti_Priorities.lua"
for _, f in ipairs({
  "src_new/scripts/levi_ataxia/levi/ataxia/017_Affliction_Management.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/007_Branching_State_Tracker.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/008_V3_Integration.lua",
  OFFENSE,
  DEFENCE,
}) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end

-- The cure line's temp trigger, as 002 registered it (the mock keeps it until mock.reset()).
local FRAT_CURED, REB_STRIPPED
for _, t in pairs(mock.active_triggers) do
  if t.pattern:find("look of madness", 1, true) then FRAT_CURED = t.callback end
  if t.pattern:find("You flay away", 1, true) then REB_STRIPPED = t.callback end
end

-- For B2, taken here for the same reason (world() resets the mock): the trigger 002 registered for
-- "has noticed your attempt at hypnosis", and the "changed target" handlers 007 and 002 registered,
-- in order, which Mudlet runs when 016's switchTarget raises the event. The seal and snap lines'
-- triggers are kept whole (pattern and code), so a test can check its line against the pattern.
local HYPNO_NOTICED, HYPNO_SEALED, HYPNO_SNAPPED
for _, t in pairs(mock.active_triggers) do
  if t.pattern:find("has noticed your attempt at hypnosis", 1, true) then HYPNO_NOTICED = t.callback end
  if t.pattern:find("your suggestions indelibly printed", 1, true) then HYPNO_SEALED = t end
  if t.pattern:find("You snap your fingers in front of", 1, true) then HYPNO_SNAPPED = t end
end
local CHANGED_TARGET = {}
for _, h in ipairs(mock.named_handlers["changed target"] or {}) do CHANGED_TARGET[#CHANGED_TARGET + 1] = h end

local TL = dofile("src_new/tests/trigger_lib.lua")
local EK_TRIGGER = "src_new/triggers/levi_ataxia/for_levi/leviticus/serpent/016_Ekanelia_Success.lua"
local function body(path)
  local fh = assert(io.open(path, "r"))
  local src = fh:read("*a"); fh:close()
  return assert((loadstring or load)(src:match("%]%]%-%-\r?\n(.*)$")))
end
local EK_BODY = body(EK_TRIGGER)

-- The world the code runs in. Only what the loaded files do not provide is stubbed.
local clock, sends, events = 100, {}, {}
local function world()
  mock.reset()                          -- no timer from an earlier test may fire into this one
  clock, sends, events = 100, {}, {}
  -- os.clock() is CPU time in Lua 5.1 (wall time only under Windows' C runtime): on Linux or
  -- macOS it barely moves while the client waits on the game. Held still, so a timer that reads
  -- it instead of getEpoch never runs out, and the tests that move `clock` catch it.
  os.clock = function() return 0.25 end
  getEpoch = function() return clock end
  send = function(c) sends[#sends + 1] = c end
  -- Recorded, not dispatched: 017 registers "tar afflicted" by NAME, which the mock cannot call.
  raiseEvent = function(e, a) events[#events + 1] = { e, a } end
  target = "Agathon"
  isTargeted = function(n) return n == "Agathon" end
  checkTargetLocks = function() end     -- curing/003, not loaded
  combatQueue = function() return "" end
  rTabSize = function(t) local n = 0; for _ in pairs(t or {}) do n = n + 1 end; return n end
  ataxia_wantClumsiness = function() return false end
  getLockingAffliction = function() return "paralyse" end
  ataxiaNDB_getClass = function() return "Serpent" end
  ataxiaEcho, zgui, cecho = function() end, nil, function() end
  ataxiaTemp, tAffs, affTimers = { tarAffTimers = {} }, {}, {}
  tBals = { tree = true, focus = true, timers = {} }
  ataxia.afflictions = {}
  gmcp = { Char = { Vitals = { bal = "1" } } }
  Rebounding, Shielded, reboundHold, classDetect, tarClass = false, false, nil, nil, ""
  hypSeal2, snapped, canShrug = nil, nil, nil
  resetStatesV3()

  serpOffenseMode, serpStrategy = "lock", "lock"
  lastImpulsed, lastImpatienceAttempt, lastReboundingFlay = {}, 0, 0
  hSuggRequest, hSuggActive = "", ""
  serpent.hypnosis.reset()
  serpent.cureTracking = { kelpCures = 0, ginsengCures = 0, bloodrootCures = 0, focusCures = 0,
    lastReset = 0, trackingWindow = 6 }
  local s = serpent.state
  s.attackInFlight, s.firstAttack, s.dispelSent = false, false, true   -- no opener, no dispel
  s.impatienceDelivered, s.relapsePhase, s.stupidityImpulseSent, s.voyriaSent = false, false, false, false
  s.geckoStripAttempted, s.postGeckoLockdown, s.lastRebounding, s.shouldShrug = false, false, false, nil
end

local function give(...) tarAffed(...) end

-- One whole round, as the offense would queue it.
local function round()
  sends = {}
  serpent.state.attackInFlight = false
  serp_ekanelia_offense()
  return table.concat(sends, "\n")
end

local function has(s, needle) return s:find(needle, 1, true) ~= nil end

local function ekanelia(who, venom)
  local line = "You sense the weakness in " .. who .. " as your " .. venom .. " takes hold."
  assert(TL.anyMatches(TL.patterns(EK_TRIGGER), line), "016's pattern no longer matches: " .. line)
  matches = { line, who, venom }
  EK_BODY()
end

local function sentAny(needle)
  for _, c in ipairs(sends) do if has(c, needle) then return true end end
  return false
end

local function curedEvents(aff)
  local n = 0
  for _, e in ipairs(events) do if e[1] == "target cured aff" and e[2] == aff then n = n + 1 end end
  return n
end

local ok, err = pcall(function()

describe("S1: the monkshood impatience sends respect sileris/fangbarrier", function()
  local MONK = "impulse Agathon masochism monkshood"

  it("PRIORITY 4: no impulse into fangbarrier; the round reaches the gecko strip instead", function()
    world(); give("asthma", "weariness", "slickness")
    expect(has(round(), MONK)).toBeTrue()          -- the impatience conditions are met

    world(); give("asthma", "weariness", "slickness", "fangbarrier")
    local r = round()
    expect(has(r, "impulse")).toBeFalse()
    expect(has(r, "dstab Agathon gecko")).toBeTrue()
  end)

  it("PRIORITY 4: sileris blocks it the same way", function()
    world(); give("asthma", "weariness", "slickness", "sileris")
    expect(has(round(), "impulse")).toBeFalse()
  end)

  -- The flay round chained this impulse until the 2026-11-07 spar showed that an impulse spends
  -- balance too ("Balance used: 1.7s." on 13 of 13), so the game refuses it after the flay. The
  -- flay now goes alone, and the impulse goes the next round (test_serpent_spar_fixes, fix 5).
  it("a shielded target gets the flay alone; the monkshood impulse goes the next round", function()
    world(); Shielded = true; give("asthma", "weariness", "slickness")
    local r = round()
    expect(has(r, "flay Agathon shield")).toBeTrue()
    expect(has(r, "impulse")).toBeFalse()

    Shielded = false; erAff("shield")
    expect(has(round(), MONK)).toBeTrue()

    world(); Shielded = true; give("asthma", "weariness", "slickness", "fangbarrier")
    r = round()
    expect(has(r, "flay Agathon shield")).toBeTrue()
    expect(has(r, "impulse")).toBeFalse()
  end)

  it("PRIORITY 5 (focus lock push): no impulse into fangbarrier either", function()
    local function lockedUp()
      world()
      give("fratricide", "impatience", "asthma", "weariness", "stupidity", "masochism", "recklessness", "vertigo")
      tBals.focus = false
    end
    lockedUp()
    expect(has(round(), "impulse Agathon confusion monkshood")).toBeTrue()

    lockedUp(); give("fangbarrier")
    expect(has(round(), "impulse")).toBeFalse()
  end)
end)

describe("S2: the Ekanelia success line records the reaction's result", function()
  it("the line still matches 016's own pattern", function()
    expect(TL.anyMatches(TL.patterns(EK_TRIGGER), "You sense the weakness in Agathon as your monkshood takes hold.")).toBeTrue()
  end)

  it("monkshood: impatience on the tracker, and not the venom's own disloyalty (009 records that)", function()
    world()
    ekanelia("Agathon", "monkshood")
    expect(haveAff("impatience")).toBeTrue()
    expect(haveAff("disloyalty")).toBeFalse()
    expect(serpent.state.impatienceDelivered).toBeTrue()
  end)

  it("monkshood: stamps the impatience cooldown, which holds the next send for 2.5 s", function()
    -- PRIORITY 4 reads canAttemptImpatience(). After the reaction, lock mode moves to relapse_lock
    -- (impatienceDelivered), whose PRIORITY 7 sends the stupidity impulse once and then dstabs, so
    -- no other branch sends monkshood inside the cooldown. (This test used the flay round's
    -- shield-break impulse until that impulse left the flay round, 2026-11-07.)
    world(); give("asthma", "weariness", "slickness")
    expect(has(round(), "impulse Agathon masochism monkshood")).toBeTrue()
    clock = 100.5
    ekanelia("Agathon", "monkshood")
    expect(lastImpatienceAttempt).toBe(100.5)
    erAff("impatience")                            -- the target cures it at once
    expect(has(round(), "monkshood")).toBeFalse()  -- canAttemptImpatience() is false right after
    clock = 102.9
    expect(has(round(), "monkshood")).toBeFalse()
    clock = 103.1
    expect(has(round(), "impulse Agathon masochism monkshood")).toBeTrue()
  end)

  it("once our reaction has landed, the next round stops sending monkshood", function()
    -- Auto mode: lock mode moves to relapse_lock on impatienceDelivered and would hide this.
    -- PRIORITY 4 is held by the cooldown here, and PRIORITY 7 (which never reads the cooldown)
    -- stops only because impatience is now on the tracker.
    world(); serpOffenseMode = "auto"; give("asthma", "weariness", "slickness")
    expect(has(round(), "impulse Agathon masochism monkshood")).toBeTrue()
    ekanelia("Agathon", "monkshood")
    expect(has(round(), "monkshood")).toBeFalse()
  end)

  it("curare -> hypochondria, kalmia -> slickness, loki -> nausea and paralysis", function()
    world(); ekanelia("Agathon", "curare")
    expect(haveAff("hypochondria")).toBeTrue()
    expect(haveAff("paralysis")).toBeFalse()     -- curare's own paralysis is 009's, not this line's

    world(); ekanelia("Agathon", "kalmia")
    expect(haveAff("slickness")).toBeTrue()
    expect(haveAff("asthma")).toBeFalse()

    world(); ekanelia("Agathon", "loki")
    expect(haveAff("nausea")).toBeTrue()
    expect(haveAff("paralysis")).toBeTrue()
  end)

  it("scytherus gives damage, not an affliction: nothing recorded", function()
    world(); ekanelia("Agathon", "scytherus")
    expect(serpent.state.camusDelivered).toBeTrue()
    for _, e in ipairs(events) do expect(e[1] == "tar afflicted").toBeFalse() end
  end)

  it("another person's name records nothing and stamps nothing", function()
    world(); ekanelia("Someoneelse", "monkshood")
    expect(haveAff("impatience")).toBeFalse()
    expect(lastImpatienceAttempt).toBe(0)
  end)

  it("is guarded on serpent.EKANELIA_RESULTS existing", function()
    world()
    local saved = serpent.EKANELIA_RESULTS
    serpent.EKANELIA_RESULTS = nil
    local fine = pcall(ekanelia, "Agathon", "curare")
    serpent.EKANELIA_RESULTS = saved
    expect(fine).toBeTrue()
    expect(haveAff("hypochondria")).toBeFalse()
  end)
end)

describe("S3: monkshood is never sent for impatience the target already has", function()
  it("selectBiteVenom does not pick monkshood onto impatience", function()
    world(); give("asthma", "masochism", "weariness")
    expect(selectBiteVenom().venom).toBe("monkshood")
    give("impatience")
    expect(selectBiteVenom().venom).toBe("curare")
  end)

  it("a bitepayload round bites something else", function()
    world(); serpOffenseMode = "bitepayload"
    give("asthma", "masochism", "weariness", "impatience")
    local r = round()
    expect(has(r, "bite Agathon curare")).toBeTrue()
    expect(has(r, "monkshood")).toBeFalse()
  end)

  it("the relapse re-lock does not pick the monkshood pair onto impatience", function()
    world(); give("slickness", "anorexia", "asthma", "weariness", "masochism")
    expect(selectRelapseImpulse().venom).toBe("monkshood")
    give("impatience")
    local pair = selectRelapseImpulse()
    expect(pair == nil or pair.venom ~= "monkshood").toBeTrue()
  end)

  it("a lock round with impatience up sends no monkshood", function()
    world(); give("asthma", "weariness", "masochism", "impatience")
    expect(has(round(), "monkshood")).toBeFalse()
  end)

  it("the keybind suggestion does not replace the masochism the reaction needs", function()
    world(); hSuggRequest = "stupidity"
    give("asthma", "weariness")                  -- no third condition: PRIORITY 7's pair
    local r = round()
    expect(has(r, "impulse Agathon masochism monkshood")).toBeTrue()
    expect(has(r, "impulse Agathon stupidity")).toBeFalse()
  end)

  -- Monkshood's masochism goes in its impulse even when it is up (a held one can be focused away
  -- before the bite: kb/raw/logs/ours/2026-11-07_164635_Saibel.log:1344-1370), so the keybind does
  -- not replace it there either (test_serpent_spar_fixes, review).
  it("...not even when masochism is up", function()
    world(); hSuggRequest = "stupidity"
    give("asthma", "weariness", "masochism")
    local r = round()
    expect(has(r, "impulse Agathon masochism monkshood")).toBeTrue()
    expect(has(r, "impulse Agathon stupidity")).toBeFalse()
  end)

  it("...but still replaces a filler suggestion", function()
    world(); hSuggRequest = "paranoia"
    give("confusion", "recklessness")            -- loki: the reaction needs nothing from the impulse
    expect(has(round(), "impulse Agathon paranoia loki")).toBeTrue()
  end)
end)

describe("S4: fratricide lives in the tracker", function()
  local function snap()
    serpent.hypnosis.fratricideApplied = true
    serpent.hypnosis.onSnapped()
  end

  it("a snap after the fratricide suggestion makes haveAff('fratricide') true", function()
    world(); snap()
    expect(haveAff("fratricide")).toBeTrue()
    expect(serpent.hypnosis.fratricideActive).toBeTrue()
  end)

  it("the cure line takes it off, and reports the cure once", function()
    world(); snap()
    expect(FRAT_CURED ~= nil).toBeTrue()
    matches = { "The look of madness fades from Agathon's eyes", "Agathon" }
    assert((loadstring or load)(FRAT_CURED))()
    expect(haveAff("fratricide")).toBeFalse()
    expect(serpent.hypnosis.fratricideActive).toBeFalse()
    expect(curedEvents("fratricide")).toBe(1)
  end)

  it("onFratricideCured takes it off the tracker", function()
    world(); snap()
    serpent.hypnosis.onFratricideCured()
    expect(haveAff("fratricide")).toBeFalse()
  end)

  it("the target's lobelia eat can now cure it", function()
    world(); snap()
    expect(haveAff("fratricide")).toBeTrue()
    onHerbCureV3("lobelia")
    expect(haveAff("fratricide")).toBeFalse()
  end)

  it("cureGroupsV3.herb_lobelia counts it", function()
    expect(cureGroupsV3.herb_lobelia).toContain("fratricide")
  end)

  -- ...but only when nothing else lobelia cures is there. Fratricide stands near the FRONT of both
  -- lobelia lists, and a list's order is V3's weight, while our priority for it is 25, the bottom
  -- (ataxia/001_Default_Curing_Prios.lua:280; the live normal set agrees). By position, one eat
  -- over masochism + fratricide left masochism believed at 0.67 (0.33 even with fratricide last,
  -- still over haveAff's 0.3), and the next monkshood impulse dropped the masochism its reaction
  -- needs. 007's onHerbCureV3 now takes fratricide only when it is alone.
  local WIDE_GROUPS = "src_new/scripts/levi_ataxia/levi/ataxia/curing/002_Wide_Groups.lua"
  local function productionCuringTable()
    -- The file V3 reads first. In a sandbox: only its table is wanted, not its functions in _G.
    local chunk = assert(loadfile(WIDE_GROUPS))
    setfenv(chunk, setmetatable({ ataxiaTemp = {} }, { __index = _G }))
    chunk()
    return getfenv(chunk).curingTable
  end

  -- masochism + fratricide, then one lobelia eat read through `cureTable` (nil: V3's own
  -- curingTableV3, where fratricide is FIRST).
  local function lobeliaOverMasochism(cureTable)
    world(); give("masochism"); snap()
    curingTable = cureTable
    local fine, e = pcall(onHerbCureV3, "lobelia")
    curingTable = nil
    if not fine then error(e) end
    return getAffProbabilityV3("masochism"), getAffProbabilityV3("fratricide")
  end

  it("a lobelia eat over masochism + fratricide takes the masochism (V3's own table)", function()
    local masochism, fratricide = lobeliaOverMasochism(nil)
    expect(masochism).toBe(0)
    expect(fratricide).toBe(1)
  end)

  it("...and through the production table, curing/002_Wide_Groups.lua", function()
    local prod = productionCuringTable()
    expect(prod.lobelia).toContain("fratricide")
    expect(prod.lobelia).toContain("masochism")
    local masochism, fratricide = lobeliaOverMasochism(prod)
    expect(masochism).toBe(0)
    expect(fratricide).toBe(1)
  end)

  it("so the next round's monkshood impulse still carries the masochism", function()
    world(); give("asthma", "weariness", "masochism"); snap()
    onHerbCureV3("lobelia")                      -- the target cures the masochism
    expect(has(round(), "impulse Agathon masochism monkshood")).toBeTrue()
  end)

  it("two other lobelia afflictions branch exactly as they would without fratricide", function()
    world(); give("masochism", "vertigo"); onHerbCureV3("lobelia")
    local masochism, vertigo = getAffProbabilityV3("masochism"), getAffProbabilityV3("vertigo")
    world(); give("masochism", "vertigo"); snap(); onHerbCureV3("lobelia")
    expect(math.abs(getAffProbabilityV3("masochism") - masochism)).toBeLessThan(1e-9)
    expect(math.abs(getAffProbabilityV3("vertigo") - vertigo)).toBeLessThan(1e-9)
    expect(getAffProbabilityV3("fratricide")).toBeGreaterThan(0.99)
  end)
end)

describe("S5: fratricide's relapse window is 2.25 s", function()
  it("an affliction impulsed 2.3 s ago passes; one impulsed 2.0 s ago does not", function()
    world(); serpent.hypnosis.fratricideActive = true
    lastImpulsed.confusion = clock - 2.3
    expect(selectFallbackSuggestion()).toBe("confusion")
    lastImpulsed.confusion = clock - 2.0
    expect(selectFallbackSuggestion()).toBe("stupidity")
  end)

  it("without fratricide there is no window", function()
    world(); lastImpulsed.confusion = clock - 0.5
    expect(selectFallbackSuggestion()).toBe("confusion")
  end)
end)

describe("the offense's timers run on getEpoch, not os.clock", function()
  -- world() holds os.clock still (CPU time). The S2 cooldown and S5 window tests read the same
  -- clock; this is the third timer on it, the 8.15 s rebounding pre-empt.
  it("the rebounding pre-empt fires 8.15 s of getEpoch after the drop, once", function()
    world(); Rebounding = true
    expect(has(round(), "flay Agathon rebounding")).toBeTrue()
    -- Since 2026-11-07 only a rebounding a game line showed arms the pre-empt: here the flay's
    -- real strip line, through the trigger 002 registered (test_serpent_spar_fixes, fix 4).
    expect(REB_STRIPPED ~= nil).toBeTrue()
    matches = { "You flay away Agathon's aura of rebounding defence.", "Agathon" }
    assert((loadstring or load)(REB_STRIPPED))()
    Rebounding = false
    round()                                      -- the drop is stamped
    expect(lastReboundingFlay).toBe(100)
    clock = 108.1
    round()
    expect(lastReboundingFlay).toBe(100)         -- not yet
    clock = 108.2
    round()
    expect(lastReboundingFlay).toBe(0)           -- fired, and disarmed
  end)
end)

describe("S6: the defence against a Serpent", function()
  local function defend(affs)
    world()
    ataxia.afflictions = affs
    Algedonic.Prioritize()                       -- dispatches to AntiSerpent (ataxiaNDB says Serpent)
  end
  local function prioaffs()
    local out = {}
    for _, c in ipairs(sends) do
      local a = c:match("^curing prioaff (%S+)$")
      if a then out[#out + 1] = a end
    end
    return out
  end

  it("hypochondria without paralysis: prioaff hypochondria", function()
    defend({ hypochondria = true })
    expect(sentAny("curing prioaff hypochondria")).toBeTrue()
  end)

  it("hypochondria with paralysis: no", function()
    defend({ hypochondria = true, paralysis = true })
    expect(sentAny("curing prioaff hypochondria")).toBeFalse()
  end)

  it("fratricide with scytherus: prioaff fratricide", function()
    defend({ fratricide = true, scytherus = true })
    expect(sentAny("curing prioaff fratricide")).toBeTrue()
  end)

  it("fratricide alone, or with paralysis: no", function()
    defend({ fratricide = true })
    expect(sentAny("curing prioaff fratricide")).toBeFalse()
    defend({ fratricide = true, scytherus = true, paralysis = true })
    expect(sentAny("curing prioaff fratricide")).toBeFalse()
  end)

  it("one prioaff per call: impatience first, then hypochondria", function()
    defend({ hypochondria = true, fratricide = true, scytherus = true })
    local p = prioaffs()
    expect(#p).toBe(1)
    expect(p[1]).toBe("hypochondria")
    defend({ impatience = true, hypochondria = true })
    p = prioaffs()
    expect(#p).toBe(1)
    expect(p[1]).toBe("impatience")
  end)

  it("writes no stored curing priority", function()
    for _, affs in ipairs({ { hypochondria = true }, { fratricide = true, scytherus = true },
      { hypochondria = true, fratricide = true, scytherus = true } }) do
      defend(affs)
      for _, c in ipairs(sends) do expect(has(c, "curing priority")).toBeFalse() end
    end
  end)

  -- The tree branch needs OUR tree. tBals.tree is the TARGET's (trigger 389).
  local CURING_BALS = "src_new/triggers/levi_ataxia/for_levi/leviticus/curing_bals/"
  local TREE_TOUCHED = body(CURING_BALS .. "003_Tree_Touched.lua")
  local TREE_READY = body(CURING_BALS .. "004_Got_Tree_Bal.lua")

  local function approachingLock(setup)
    world()
    ataxia.afflictions = { asthma = true, slickness = true, anorexia = true }
    setup()
    Algedonic.Prioritize()
  end

  it("his tree down, ours up: it trees", function()
    approachingLock(function() tBals.tree = false end)
    expect(sentAny("touch tree")).toBeTrue()
  end)

  it("his tree up, ours down: no tree", function()
    approachingLock(function() tBals.tree = true; ataxiaTemp.usedTree = true end)
    expect(sentAny("touch tree")).toBeFalse()
  end)

  it("our own lines drive it: the touch line holds the tree, the ready line frees it", function()
    approachingLock(TREE_TOUCHED)
    expect(sentAny("touch tree")).toBeFalse()
    local savedMnem = ataxia.mnemosyne
    ataxia.mnemosyne = nil                       -- 004 also calls Mnemosyne's hook; not this test's
    TREE_READY()
    ataxia.mnemosyne = savedMnem
    Algedonic.Prioritize()
    expect(sentAny("touch tree")).toBeTrue()
  end)

  -- The touch line is ours on every touch. It hung under trigger 002 (`[Curing]: TOUCH TREE`), so
  -- it could run only on the line after that one. Our own `touch tree` is not curing's report.
  it("the touch line stands alone, under no chain parent", function()
    local fh = assert(io.open(CURING_BALS .. "003_Tree_Touched.lua", "r"))
    local src = fh:read("*a"):gsub("\r", "")
    fh:close()
    local hierarchy = assert(src:match("hierarchy:\n(.-)attributes:"))
    expect(hierarchy:find("Tree Touch", 1, true)).toBeNil()
    expect(hierarchy:match("%- ([^\n]+)\n$")).toBe("Curing Bals")
  end)

  -- A dropped link can miss the ready line, and ataxiaTemp outlives the login.
  it("a login frees our tree: nil is the safe side, as the game refuses a touch at no real cost", function()
    local fh = assert(io.open("src_new/scripts/levi_ataxia/levi/ataxia/login/001_Login_Function.lua", "r"))
    local src = fh:read("*a")
    fh:close()
    local block = assert(src:match('\n(ataxia_resetTargetBals%(%).-)\nexpandAlias%("t Penwize"%)'))
    local savedReset = ataxia_resetTargetBals
    ataxia_resetTargetBals = function() end
    approachingLock(function()
      ataxiaTemp.usedTree = true
      assert((loadstring or load)(block))()
    end)
    ataxia_resetTargetBals = savedReset
    expect(sentAny("touch tree")).toBeTrue()
  end)

  -- `cq all` clears our own queue, and this function runs on every affliction gain and loss.
  local function shields()
    local n = 0
    for _, c in ipairs(sends) do if c == "cq all;touch shield" then n = n + 1 end end
    return n
  end

  it("impatience: one shield per 4 s, however often the afflictions change", function()
    defend({ impatience = true })
    expect(shields()).toBe(1)
    Algedonic.Prioritize()
    Algedonic.Prioritize()
    expect(shields()).toBe(1)
    expect(#prioaffs()).toBe(3)                  -- the free prioaff still goes out each time
    local delay
    for _, t in pairs(mock.active_timers) do delay = t.delay end
    expect(delay).toBe(4)
    mock.fire_timers()                           -- the 4 s are up
    Algedonic.Prioritize()
    expect(shields()).toBe(2)
  end)

  it("the warning goes with the shield, not with each throttled call", function()
    local warned = 0
    defend({ impatience = true })
    cecho = function(s) if has(s, "TOUCH SHIELD") then warned = warned + 1 end end
    Algedonic.Prioritize()
    expect(warned).toBe(0)
    mock.fire_timers()
    Algedonic.Prioritize()
    expect(warned).toBe(1)
  end)

  it("the throttle changes no decision: paralysis still blocks it, the tree still comes first", function()
    defend({ impatience = true, paralysis = true })
    expect(shields()).toBe(0)
    defend({ impatience = true, asthma = true, slickness = true })
    expect(sentAny("touch tree")).toBeTrue()
    expect(shields()).toBe(0)
  end)

  it("approaching lock with our tree down falls through to the impatience branch", function()
    world()
    ataxia.afflictions = { impatience = true, asthma = true, slickness = true }
    ataxiaTemp.usedTree = true
    Algedonic.Prioritize()
    expect(sentAny("touch tree")).toBeFalse()
    expect(shields()).toBe(1)
  end)
end)

describe("B1: scytherus mode's impulse respects sileris/fangbarrier too", function()
  -- Scytherus mode with addiction + nausea up and no scytherus yet: PRIORITY 7 impulses the
  -- scytherus (its Ekanelia gives camus), riding a bite that the barrier stops.
  local function scytherusRound(...)
    world(); serpOffenseMode = "scytherus"; give("addiction", "nausea", ...)
    return round()
  end

  it("no barrier: the scytherus impulse goes out", function()
    expect(has(scytherusRound(), "impulse Agathon confusion scytherus")).toBeTrue()
  end)

  it("fangbarrier up: no impulse, and the round still dstabs", function()
    local r = scytherusRound("fangbarrier")
    expect(has(r, "impulse")).toBeFalse()
    expect(has(r, "dstab Agathon curare kalmia")).toBeTrue()
  end)

  it("sileris blocks it the same way", function()
    local r = scytherusRound("sileris")
    expect(has(r, "impulse")).toBeFalse()
    expect(has(r, "dstab Agathon")).toBeTrue()
  end)

  it("with asthma up, that dstab is the gecko that strips the barrier", function()
    -- scytherus_attack's first venom is gecko when asthma is up and slickness is not
    -- (selectVenoms); the blocked impulse used to replace the dstab, so it never went out.
    local r = scytherusRound("asthma", "fangbarrier")
    expect(has(r, "impulse")).toBeFalse()
    expect(has(r, "dstab Agathon gecko")).toBeTrue()
  end)
end)

describe("B2: hypnolock keeps its mode across a target change", function()
  for _, f in ipairs({
    "src_new/scripts/levi_ataxia/levi/ataxia/016_Targeting_Functions.lua",
    "src_new/scripts/levi_ataxia/levi/ataxia/misc_scripts/002_System_Class_Functions.lua",
  }) do
    local fine, e = pcall(dofile, f)
    if not fine then error("Failed to load " .. f .. ": " .. tostring(e)) end
  end

  -- Our target becomes `who` the way the `t` alias does it: 016's switchTarget, outside bashing,
  -- with "changed target" run through the handlers 007 and 002 registered. What switchTarget
  -- reaches outside the loaded files is stubbed for the call and put back after it.
  local STUBBED = { "matches", "pariah", "ataxiaBasher", "raiseEvent", "setafflictionstackslevi",
    "twohanded_resetFractures" }
  local function retarget(who)
    local saved = {}
    for i, k in ipairs(STUBBED) do saved[i] = _G[k] end
    matches = { "t " .. who:lower(), who:lower() }
    pariah, ataxiaBasher = nil, nil              -- 016 indexes pariah when set (the runner's is "")
    local record = raiseEvent
    raiseEvent = function(e, ...)
      record(e, ...)
      if e == "changed target" then
        for _, h in ipairs(CHANGED_TARGET) do h(e, ...) end
      end
    end
    setafflictionstackslevi = function() end     -- 015 (over 004's stack list), not loaded
    twohanded_resetFractures = function() end    -- ataxia/006, not loaded
    gmcp.Char.Status = { class = "Serpent" }
    ataxiaTemp.class = "Serpent"
    ataxia.playersHere = { "Agathon", who }
    local fine, e = pcall(switchTarget, who)
    for i, k in ipairs(STUBBED) do _G[k] = saved[i] end
    if not fine then error(e, 0) end
  end

  -- A test that leaves world() a mode it does not reset any more (reset() keeps it, which is the
  -- point), so each one puts back the defaults whether it passes or not.
  local function cleanly(fn)
    local fine, e = pcall(fn)
    serpent.hypnosis.mode = "fratricide"
    serpent.hypnosis.targetSuggestions = {}
    ataxia.playersHere = { "Agathon" }
    if not fine then error(e, 0) end
  end

  it("after a target change the next chain suggests the lock afflictions, then seals", function()
    cleanly(function()
      world()
      serp_setmode_hypnolock()                   -- ekhl: the chain starts on Agathon...
      expect(serpent.hypnosis.mode).toBe("lock")
      serpent.hypnosis.onHypnotised()
      serpent.hypnosis.onSuggested("hypochondria") -- ...and gets one suggestion in
      retarget("Claes")
      expect(target).toBe("Claes")
      expect(serpent.state.firstAttack).toBeTrue() -- 002's "changed target" handler ran as well
      expect(serpent.hypnosis.mode).toBe("lock")
      expect(#serpent.hypnosis.suggestions).toBe(0) -- Agathon's chain is gone

      expect(has(round(), "hypnotise Claes")).toBeTrue()
      serpent.hypnosis.onHypnotised()
      local r = round()
      expect(has(r, "suggest Claes hypochondria")).toBeTrue()
      expect(has(r, "fratricide")).toBeFalse()
      for _, sug in ipairs({ "hypochondria", "disrupt" }) do serpent.hypnosis.onSuggested(sug) end
      expect(has(round(), "suggest Claes generosity")).toBeTrue()
      serpent.hypnosis.onSuggested("generosity")
      r = round()
      expect(has(r, "seal Claes 3")).toBeTrue()
      expect(has(r, "snap")).toBeFalse()
    end)
  end)

  it("the lock suggestions are picked again for the new target", function()
    cleanly(function()
      world(); give("hypochondria")              -- Agathon has hypochondria already
      serp_setmode_hypnolock()
      expect(table.concat(serpent.hypnosis.targetSuggestions, ",")).toBe("disrupt,generosity")
      retarget("Claes")                          -- Claes does not
      expect(table.concat(serpent.hypnosis.targetSuggestions, ",")).toBe("hypochondria,disrupt,generosity")
    end)
  end)

  it("a hypnosis attempt the target noticed restarts the lock chain, not a fratricide one", function()
    cleanly(function()
      world()
      serp_setmode_hypnolock()
      serpent.hypnosis.onHypnotised()
      expect(HYPNO_NOTICED ~= nil).toBeTrue()
      matches = { "Agathon has noticed your attempt at hypnosis!", "Agathon" }
      assert((loadstring or load)(HYPNO_NOTICED))()
      expect(serpent.hypnosis.phase).toBe("idle")
      expect(serpent.hypnosis.mode).toBe("lock")
      expect(has(round(), "hypnotise Agathon")).toBeTrue()
      serpent.hypnosis.onHypnotised()
      expect(has(round(), "suggest Agathon hypochondria")).toBeTrue()
    end)
  end)

  it("ekhyp after ekhl runs the fratricide chain: the alias sets its own mode", function()
    cleanly(function()
      world()
      serp_setmode_hypnolock()
      serp_setmode_hypnosis()
      expect(serpent.hypnosis.mode).toBe("fratricide")
      expect(#serpent.hypnosis.targetSuggestions).toBe(0)
      serpent.hypnosis.onHypnotised()
      expect(has(round(), "suggest Agathon fratricide")).toBeTrue()
    end)
  end)

  -- One of the hypnosis lines whose trigger was captured at load: the line must still match the
  -- trigger's pattern, then the trigger's code runs.
  local function hypnoLine(trig, line, who)
    assert(trig, "002's trigger for this line was not captured at load")
    assert(TL.matches(trig.pattern, 1, line), "002's pattern no longer takes: " .. line)
    matches = { line, who }
    assert((loadstring or load)(trig.callback))()
  end

  -- Fires, earliest first, the timers due within dt seconds of being armed. Each one here was
  -- armed at the snap, so this is the client dt seconds after it.
  local function elapse(dt)
    local due = {}
    for id, t in pairs(mock.active_timers) do
      if t.delay <= dt then due[#due + 1] = { id = id, t = t } end
    end
    table.sort(due, function(a, b) return a.t.delay < b.t.delay end)
    for _, d in ipairs(due) do
      mock.active_timers[d.id] = nil
      if type(d.t.callback) == "function" then d.t.callback() else assert((loadstring or load)(d.t.callback))() end
    end
  end

  -- The chain B2's path now runs, followed past its snap. onSnapped left `sealed` true, and in
  -- lock mode canSnap() IS `sealed`, so every round after the chain sent SNAP as its eq action,
  -- and an eq action shuts out every impulse that needs the eq slot free (PRIORITY 3, 4, 5 and 7),
  -- the monkshood impatience among them. Before B2 a target change turned the chain into the
  -- fratricide one, whose canSnap() is phase == "ready_snap" and so ends at its snap.
  it("the chain ends at its snap: no later round snaps again, and the impulses come back", function()
    cleanly(function()
      world()
      serp_setmode_hypnolock()
      serpent.hypnosis.onHypnotised()
      retarget("Claes")
      expect(has(round(), "hypnotise Claes")).toBeTrue()
      serpent.hypnosis.onHypnotised()
      for _, sug in ipairs({ "hypochondria", "disrupt", "generosity" }) do serpent.hypnosis.onSuggested(sug) end
      expect(has(round(), "seal Claes 3")).toBeTrue()
      hypnoLine(HYPNO_SEALED,
        "You draw Claes out of his hypnotic daze, your suggestions indelibly printed on his mind.", "Claes")
      expect(has(round(), "snap Claes")).toBeTrue()
      hypnoLine(HYPNO_SNAPPED, "You snap your fingers in front of Claes.", "Claes")

      elapse(0.5)                                -- onSnapped's switch to lock mode
      expect(serpOffenseMode).toBe("lock")
      expect(has(round(), "snap")).toBeFalse()
      elapse(COOLDOWN_TIME)                      -- the chain's cooldown, and the trigger's 3 s
      expect(serpent.hypnosis.phase).toBe("idle")
      expect(has(round(), "snap")).toBeFalse()

      -- A new target is believed to have rebounding, sileris and fangbarrier up (016's
      -- targetresetafflictionslevi); they come down as the flay and the gecko strip would take them.
      for _, def in ipairs({ "rebounding", "sileris", "fangbarrier" }) do erAff(def) end
      give("asthma", "weariness", "slickness")  -- the impatience conditions, on Claes
      local r = round()
      expect(has(r, "impulse Claes masochism monkshood")).toBeTrue()
      expect(has(r, "snap")).toBeFalse()
    end)
  end)

  -- 2026-11-08 review, F9: the 4 s snap timer moved the phase to "ready_snap" in lock mode too. One
  -- suggestion goes per round, so the third was due after the 4 s mark, and from then on the lock
  -- chain's getCommand found no step: no third suggestion, no seal, no snap.
  it("the snap timer does not end a lock chain that still has suggestions to give", function()
    cleanly(function()
      world()
      serp_setmode_hypnolock()
      serpent.hypnosis.onHypnotised()
      for _, sug in ipairs({ "hypochondria", "disrupt" }) do serpent.hypnosis.onSuggested(sug) end
      elapse(SNAP_DELAY)
      expect(serpent.hypnosis.snapTimerFired).toBeTrue()
      expect(serpent.hypnosis.phase).toBe("suggesting")
      expect(has(round(), "suggest Agathon generosity")).toBeTrue()
      serpent.hypnosis.onSuggested("generosity")
      expect(has(round(), "seal Agathon 3")).toBeTrue()
      hypnoLine(HYPNO_SEALED,
        "You draw Agathon out of his hypnotic daze, your suggestions indelibly printed on his mind.", "Agathon")
      expect(has(round(), "snap Agathon")).toBeTrue()
    end)
  end)

  it("the fratricide chain's snap timer still marks the snap ready", function()
    cleanly(function()
      world()
      serp_setmode_hypnosis()
      serpent.hypnosis.onHypnotised()
      serpent.hypnosis.onSuggested("fratricide")
      elapse(SNAP_DELAY)
      expect(serpent.hypnosis.phase).toBe("ready_snap")
      expect(has(round(), "snap Agathon")).toBeTrue()
    end)
  end)

  -- 2026-11-08 review, F28: SEAL takes a delay in seconds, three and upwards
  -- (kb/raw/wiki/Hypnosis.wiki:24, :28). It sent the number of suggestions, so a chain of one or two
  -- sent "seal X 1" or "seal X 2", which the game does not take.
  it("the seal names 3 seconds whatever the number of suggestions", function()
    cleanly(function()
      world(); give("hypochondria", "disrupt")      -- only generosity is left to suggest
      serp_setmode_hypnolock()
      expect(table.concat(serpent.hypnosis.targetSuggestions, ",")).toBe("generosity")
      serpent.hypnosis.onHypnotised()
      serpent.hypnosis.onSuggested("generosity")
      local r = round()
      expect(has(r, "seal Agathon 3")).toBeTrue()
      expect(has(r, "seal Agathon 1")).toBeFalse()
    end)
  end)
end)

end)

-- Restore the shared Lua state.
os.clock, table.contains = savedClock, savedContains
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
if not ok then error(err) end
