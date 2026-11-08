--- test_target_defence_lines.lua -- target-tracker lines that read the wrong person, or the wrong defence
--
-- From the deep review of the 2026-11-07 Serpent spar fixes (group C):
--   F1   our FLAY of the shield (serpent/003, 335) erased the target's REBOUNDING too; a shield flay
--        leaves rebounding up, so the next round dstabbed or impulsed into it (it does rip the
--        sileris coating, which 706 reads);
--   F3   640: anyone's flight marked our target gone, started TargetOutOfRoom and opened the chase
--        window, so combatQueue added the last departure's direction or "touch tentacle";
--   F16  443: anyone's parry erased our target's nausea (unanchored pattern, no name check);
--   F17  706: anyone's coating loss erased our target's fangbarrier and sileris;
--   F46  706: the rip's other form ("ripped away along with his protections") was not read;
--   F20  553: anyone's writhe out of an impale erased our target's impale;
--   F22  442: the sileris BERRY's shell line ("A supple purple shell ...") was not read;
--   F24  638: a ghost leaving (the line names no one) was read as our target leaving;
--   F48  638: "vanishes from sight to the ether" queued a move "ether".
--
-- The tests run the REAL trigger bodies over the REAL public API (016, 017) and the REAL V3 tracker
-- (007, 008); F3 also runs the real combatQueue (ataxia/003), and F1 the real Serpent offence
-- (serpent/002). Game lines are verbatim from kb/raw/logs (file:row given) unless marked
-- CONSTRUCTED. Every global that the loaded files create or change is restored at the end (one
-- shared Lua state for all test files).

local mock = require("mock_mudlet")
local before = {}
for k, v in pairs(_G) do before[k] = v end
local savedContains, savedStarts, savedClock = table.contains, string.starts, os.clock

-- The V3 files and the offence initialise these as `X = X or {...}`. Clear them, so the loads build
-- fresh tables; the restore at the end puts the old ones back.
for _, k in ipairs({ "afflictionStatesV3", "affConfigV3", "simpleAffsV3", "affCacheV3", "targetBurningLevelV3",
  "affLastConfirmedV3", "targetDefensesV3", "cureBalancesV3", "cureBalanceTimerIDsV3", "passiveCooldownsV3",
  "negativeConfirmTimersV3", "tAffsV2", "tAffStacksV2", "serpent", "Algedonic", "lastImpulsed",
  "lastReboundingFlay", "lastImpatienceAttempt", "serpOffenseMode", "serpStrategy", "attackMode",
  "ekaneliaReady", "affTimers", "hSuggRequest", "hSuggActive", "curingTable" }) do
  _G[k] = nil
end
ataxia = { settings = { separator = "::" }, playersHere = { "Agathon" }, afflictions = {} }
ataxiaTemp, tAffs, affTimers = {}, {}, {}
Algedonic = {}

-- table.contains and string.starts are Mudlet extensions (tarAffed and isTargeted use them).
table.contains = table.contains or function(t, v)
  for _, x in pairs(t) do if x == v then return true end end
  return false
end
string.starts = string.starts or function(s, p) return s:sub(1, #p) == p end

local OFFENSE = "src_new/scripts/levi_ataxia/levi/levi_scripts/serpent/002_Serpent_Offense.lua"
for _, f in ipairs({
  "src_new/scripts/levi_ataxia/levi/ataxia/016_Targeting_Functions.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/017_Affliction_Management.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/curing/002_Wide_Groups.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/007_Branching_State_Tracker.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/008_V3_Integration.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/ataxia/003_Queueing_Related.lua",
  OFFENSE,
}) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end
local realIsTargeted, realCombatQueue = isTargeted, combatQueue

local TL = dofile("src_new/tests/trigger_lib.lua")
local LEVI = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
local SHIELD_DOWN = LEVI .. "serpent/003_Shield_Down.lua"
local SECOND_HIT = LEVI .. "serpent/010_Flay_second_hit.lua"
local RAZED = LEVI .. "335_Mob_Razed.lua"
local FLY = LEVI .. "640_Fly_1.lua"
local PARRY = LEVI .. "443_Nausea_Lost_-_Parry.lua"
local FLAYED_SILERIS = LEVI .. "706_Flayed_Sileris.lua"
local SLICKNESS = LEVI .. "424_Got_slickness.lua"
local GOT_SILERIS = LEVI .. "442_Got_Sileris.lua"
local NO_IMPALE = LEVI .. "553_No_Impale.lua"
local WRITHED = LEVI .. "407_Writhed_Impale.lua"
local GHOST = LEVI .. "638_GHOST_LEFT.lua"
local OUT_OF_ROOM = "src_new/timers/levi_ataxia/for_levi/levi_062424/my_timers/003_TargetOutOfRoom.lua"

local function body(path)
  local fh = assert(io.open(path, "r"))
  local src = fh:read("*a"); fh:close()
  return assert((loadstring or load)(src:match("%]%]%-%-\r?\n(.*)$")))
end
local BODY = {}
for _, p in ipairs({ SHIELD_DOWN, SECOND_HIT, RAZED, FLY, PARRY, FLAYED_SILERIS, SLICKNESS, GOT_SILERIS,
  NO_IMPALE, WRITHED, GHOST, OUT_OF_ROOM }) do
  BODY[p] = body(p)
end

-- What Mudlet puts in matches[2]: the capture of the first pattern of the trigger that matches.
-- trigger_lib does not return captures, so the pattern's text before its "(\w+)" is turned into a
-- Lua pattern ("\w+" -> "%w+", an escaped character -> itself) and the word after it is read.
-- A matching pattern with no capture gives nil, as in Mudlet. No pattern matching raises.
local function luaPrefix(re)
  local out, i = {}, 1
  while i <= #re do
    local c = re:sub(i, i)
    if c == "\\" then
      local n = re:sub(i + 1, i + 1)
      if n == "w" then out[#out + 1] = "%w"
      elseif n:match("%p") then out[#out + 1] = "%" .. n
      else error("capture: unsupported escape \\" .. n .. " in " .. re) end
      i = i + 2
    elseif c == "+" then
      out[#out + 1] = "+"; i = i + 1
    elseif c:match("[%(%)%[%]%.%*%?%^%$|{}]") then
      error("capture: unsupported regex before the capture in " .. re)
    else
      out[#out + 1] = c:match("%p") and ("%" .. c) or c; i = i + 1
    end
  end
  return table.concat(out)
end
local function capture(path, l)
  for _, p in ipairs(TL.patterns(path)) do
    if TL.matches(p.pat, p.type, l) then
      local pre = p.pat:match("^%^(.-)%(\\w%+%)")
      if not pre then return nil end
      return (assert(l:match("^" .. luaPrefix(pre) .. "(%w+)"), "capture: no word after the prefix in " .. l))
    end
  end
  error("no pattern of " .. path .. " matches: " .. l)
end

-- Run a trigger body on a line, with matches as Mudlet would fill them.
local function fire(path, l, who)
  line = l
  matches = { l, who == nil and capture(path, l) or who }
  return BODY[path]()
end

-- The world the triggers run in. Only what the loaded files do not provide is stubbed.
local now, events, timersOn, sent = 1000, {}, {}, {}
local function world(name)
  now, events, timersOn, sent = 1000, {}, {}, {}
  mock.reset()
  getEpoch = function() return now end
  target = name
  isTargeted = realIsTargeted
  combatQueue = realCombatQueue
  raiseEvent = function(e, a) events[#events + 1] = { e, a } end
  checkTargetLocks = function() end
  ataxiaEcho, zgui = function() end, nil
  fg, bg = function() end, function() end
  cecho, ataxia_boxEcho = function() end, function() end
  enableTimer = function(n) timersOn[n] = true; return true end
  disableTimer = function(n) timersOn[n] = false; return true end
  send = function(c) sent[#sent + 1] = c end
  sendAll = function(...) for _, c in ipairs({ ... }) do send(c) end end
  confirmAffV2 = function() end
  gmcp = { Char = { Status = { class = "Serpent", name = "Leviticus" } } }
  ataxia_isClass = function(c) return gmcp.Char.Status.class:lower() == c:lower() end
  ataxia = { settings = { separator = ";" }, playersHere = { name }, afflictions = {} }
  ataxiaTemp = { tarAffTimers = {} }
  ataxiaBasher, ataxiaBasher_shieldDropped = { enabled = false }, nil
  tAffs, affTimers = {}, {}
  tBals = { tree = true, focus = true, plant = true, timers = {} }
  targetIshere = true
  chasing_Targets, jumping, tChaseTimer, dir_left, rtiwaz = nil, nil, nil, nil, nil
  envenomList, partyrelay, timpale = {}, nil, nil
  tdeliverance, havebomb, jestercheese, myaeon, preventriftlock, stoplatency = nil, nil, nil, nil, nil, nil
  serpent.state.geckoStripAttempted = true
  affConfigV3.enabled = true
  resetStatesV3()
  if resetCureBalancesV3 then resetCureBalancesV3() end
end

local P = function(a) return getAffProbabilityV3(a) end
local function cured()
  local out = {}
  for _, ev in ipairs(events) do
    if ev[1] == "target cured aff" then out[#out + 1] = ev[2] end
  end
  return out
end
local function sentAny(needle)
  for _, c in ipairs(sent) do
    if type(c) == "string" and c:find(needle, 1, true) then return true end
  end
  return false
end
-- Run the zero-delay timers (a deferred check runs once the packet is read).
local function flushNow()
  local due = {}
  for id, t in pairs(mock.active_timers) do
    if t.delay == 0 then due[#due + 1] = id end
  end
  for _, id in ipairs(due) do
    local t = mock.active_timers[id]
    mock.active_timers[id] = nil
    if type(t.callback) == "function" then t.callback()
    else assert((loadstring or load)(t.callback))() end
  end
end

local ok, err = pcall(function()

-- ---------------------------------------------------------------------------------------------
-- F1. Our own shield-flay lines are not in any log; these two are CONSTRUCTED from serpent/003's
-- patterns. The victim's seat shows what they mean: rebounding up at
-- kb/raw/logs/2026-11-01_claes_runewarden-vs-serpent_loss_azbErKcK.txt:2216, "Thato flays away your
-- shield defence." at 2235, and the rebounding flayed only at 2264.
-- ---------------------------------------------------------------------------------------------
describe("F1: our flay of the shield leaves the target's rebounding", function()
  local FLAYED = "You flay away Agathon's shield defence."
  local NONE = "You try to flay a non-existent shield from Agathon."
  -- kb/raw/logs/ours/2026-11-07_164635_Saibel.log:315
  local SECOND = "With your victim exposed, you crack Elentari's Scourge back for a second assault."

  local function shieldFlay(l, who)
    fire(SHIELD_DOWN, l, who)
    fire(RAZED, l, who)
  end

  it("both lines are what 003 and 335 match", function()
    for _, l in ipairs({ FLAYED, NONE }) do
      expect(TL.anyMatches(TL.patterns(SHIELD_DOWN), l)).toBeTrue()
      expect(TL.anyMatches(TL.patterns(RAZED), l)).toBeTrue()
    end
  end)

  it("the shield goes and the rebounding stays (003 and 335)", function()
    for _, l in ipairs({ FLAYED, NONE }) do
      world("Agathon")
      tarAffed("rebounding", "shield")
      shieldFlay(l, "Agathon")
      expect(haveAff("shield")).toBeFalse()
      expect(tAffs.shield).toBeFalse()
      expect(haveAff("rebounding")).toBeTrue()
      expect(tAffs.rebounding).toBeTrue()
    end
  end)

  -- A FLAY of the shield does rip the sileris coating (kb/sim/rules.md attack.flay.coating, 23 of 23:
  -- az 2235-2236 "Thato flays away your shield defence." then "The protective coating covering your
  -- skin is ripped away along with your protections."). 706 reads that from our flay line itself, so
  -- the coating goes even when the rip line is lost; only the rebounding stays.
  it("the flay line also takes the target's coating (706), and still not the rebounding", function()
    expect(TL.anyMatches(TL.patterns(FLAYED_SILERIS), FLAYED)).toBeTrue()
    expect(capture(FLAYED_SILERIS, FLAYED)).toBe("Agathon")
    world("Agathon")
    -- kb/raw/logs/ours/2026-10-27_112717_Tabethys.log:6442 has it for Akri; Agathon's name is CONSTRUCTED.
    fire(GOT_SILERIS, "A supple metallic shell of quicksilver has formed around Agathon.")
    tarAffed("rebounding", "shield")
    expect(haveAff("fangbarrier")).toBeTrue()
    expect(haveAff("sileris")).toBeTrue()
    shieldFlay(FLAYED, "Agathon")
    fire(FLAYED_SILERIS, FLAYED)
    expect(haveAff("shield")).toBeFalse()
    expect(haveAff("fangbarrier")).toBeFalse()
    expect(haveAff("sileris")).toBeFalse()
    expect(haveAff("rebounding")).toBeTrue()
  end)

  it("a flay of someone else's shield leaves the target's two defences", function()
    world("Agathon")
    tarAffed("rebounding", "shield")
    shieldFlay("You flay away Bob's shield defence.", "Bob")   -- CONSTRUCTED, as above
    expect(haveAff("shield")).toBeTrue()
    expect(haveAff("rebounding")).toBeTrue()
    expect(#cured()).toBe(0)
  end)

  it("the second-assault line (010) still takes both, when neither is left", function()
    world("Agathon")
    tarAffed("rebounding", "shield")
    shieldFlay(FLAYED, "Agathon")
    line = SECOND; matches = { SECOND }
    BODY[SECOND_HIT]()
    expect(haveAff("shield")).toBeFalse()
    expect(haveAff("rebounding")).toBeFalse()
  end)

  it("335's other lines still take both (a raze of a player's shield)", function()
    -- kb/raw/logs/ours/2026-10-27_135412_Tabethys.log:9391
    local raze = "You raze Belaziel's magical shield with Severance, a vorpal sanguine scimitar."
    expect(TL.anyMatches(TL.patterns(RAZED), raze)).toBeTrue()
    world("Belaziel")
    tarAffed("rebounding", "shield")
    fire(RAZED, raze, "Belaziel")
    expect(haveAff("shield")).toBeFalse()
    expect(haveAff("rebounding")).toBeFalse()
  end)
end)

-- The offence after the flay, in serpent/002's own world (the one test_serpent_spar_fixes.lua
-- builds): PRIORITY 1 flays the shield first, then must flay the rebounding, not dstab into it.
describe("F1: the next Serpent round flays the rebounding", function()
  local clock = 100
  local function spar()
    world("Agathon")
    clock = 100
    os.clock = function() return 0.25 end
    getEpoch = function() return clock end
    ataxia.settings.separator = "::"
    isTargeted = function(n) return n == target end
    combatQueue = function() return "g body::g gold::stand::" end
    rTabSize = function(t) local n = 0; for _ in pairs(t or {}) do n = n + 1 end; return n end
    ataxia_wantClumsiness = function() return false end
    getLockingAffliction = function() return "paralyse" end
    ataxiaNDB_getClass = function() return "Serpent" end
    Algedonic.Echo = function() end
    gmcp = { Char = { Vitals = { bal = "1" }, Status = { class = "Serpent" } } }
    Rebounding, Shielded, reboundHold, classDetect, tarClass = false, false, nil, nil, ""
    hypSeal2, snapped, canShrug, tpinshot = nil, nil, nil, nil
    ataxiaBasher_isMounted, omount, ataxiaBasher_CLASS_PETS = nil, nil, nil
    serpent.config.useExitBlock = false
    serpOffenseMode, serpStrategy = "lock", "lock"
    lastImpulsed, lastImpatienceAttempt, lastReboundingFlay = {}, 0, 0
    hSuggRequest, hSuggActive = "", ""
    serpent.hypnosis.mode = "fratricide"
    serpent.hypnosis.reset()
    serpent.cureTracking = { kelpCures = 0, ginsengCures = 0, bloodrootCures = 0, focusCures = 0,
      lastReset = 0, trackingWindow = 6 }
    local s = serpent.state
    s.attackInFlight, s.firstAttack, s.dispelSent = false, false, true
    s.impatienceDelivered, s.relapsePhase, s.stupidityImpulseSent, s.voyriaSent = false, false, false, false
    s.geckoStripAttempted, s.postGeckoLockdown, s.lastRebounding, s.shouldShrug = false, false, false, nil
    s.lockReinforceSent, s.camusDelivered, s.sigilDeployed, s.pinshotSentAt = false, false, false, 0
    s.reboundingSeen, s.snakesHere, s.adderNotedFor, s.roomListSeen = false, {}, nil, false
    s.lastWieldKw, s.lastWieldBefore = nil, nil
    s.lastBlockSentAt, s.blockedExits = 0, {}
  end
  local function round()
    sent = {}
    serpent.state.attackInFlight = false
    serp_ekanelia_offense()
    return table.concat(sent, "\n")
  end
  local function has(s, needle) return s:find(needle, 1, true) ~= nil end

  for _, l in ipairs({ "You flay away Agathon's shield defence.", "You try to flay a non-existent shield from Agathon." }) do
    it("after: " .. l, function()
      spar()
      -- The raise line (430) of a real rebounding: tarAffed raises "tar afflicted", which the
      -- offence reads as a rebounding a game line showed.
      tarAffed("rebounding")
      tarAffed("shield")
      serpent.onTargetAfflicted("rebounding")
      expect(has(round(), "flay Agathon shield")).toBeTrue()
      clock = 102
      fire(SHIELD_DOWN, l, "Agathon")
      fire(RAZED, l, "Agathon")
      local r = round()
      expect(has(r, "flay Agathon rebounding")).toBeTrue()
      expect(has(r, "dstab")).toBeFalse()
      expect(has(r, "impulse")).toBeFalse()
      expect(lastReboundingFlay).toBe(0)   -- no reapply pre-empt for a rebounding still up
    end)
  end
end)

-- ---------------------------------------------------------------------------------------------
-- F3. 640: only the target's flight. kb/raw/logs/ours/2026-11-03_081009_Froedine.log:3206 (Kaden)
-- and kb/raw/logs/2026-11-03_shikudo-group-alias.txt:5222 have the line for a bystander.
-- ---------------------------------------------------------------------------------------------
describe("F3: someone else's flight (640)", function()
  local KADEN = "Kaden is quickly carried up into the skies."
  local LAURYYN = "Lauryyn is quickly carried up into the skies."   -- CONSTRUCTED: the same line, her name

  local function fight()
    world("Lauryyn")
    ataxia.playersHere = { "Lauryyn", "Kaden" }
    dir_left = "north"                   -- an earlier departure's direction
    tarAffed("paralysis", "anorexia")
  end

  it("the line is what 640 matches, and the name is its capture", function()
    expect(capture(FLY, KADEN)).toBe("Kaden")
  end)

  it("leaves the target here: no chase window, no TargetOutOfRoom, no direction", function()
    fight()
    fire(FLY, KADEN)
    expect(targetIshere).toBeTrue()
    expect(timersOn.TargetOutOfRoom).toBeNil()
    expect(tChaseTimer).toBeNil()
    expect(dir_left).toBe("north")
    expect(#sent).toBe(0)
  end)

  it("the next round (combatQueue) walks nowhere", function()
    fight()
    fire(FLY, KADEN)
    expect(combatQueue()).toBe("g body;g gold;stand;")
  end)

  it("the target keeps her afflictions (a timer tick erases nothing)", function()
    fight()
    fire(FLY, KADEN)
    BODY[OUT_OF_ROOM]()
    expect(P("paralysis")).toBe(1)
    expect(P("anorexia")).toBe(1)
  end)

  it("the target's own flight is read as before", function()
    fight()
    fire(FLY, LAURYYN)
    expect(dir_left).toBe("fly")
    expect(targetIshere).toBeFalse()
    expect(timersOn.TargetOutOfRoom).toBeTrue()
    expect(tChaseTimer ~= nil).toBeTrue()
    expect(sentAny("queue addclear free touch tentacle Lauryyn")).toBeTrue()
    expect(P("paralysis")).toBe(0)
    expect(combatQueue()).toBe("g body;g gold;stand;touch tentacle Lauryyn;")
  end)
end)

-- ---------------------------------------------------------------------------------------------
-- F16. 443: kb/raw/logs/ours/2026-11-03_102138_Tabethys.log:339, Havyn parries while the target is
-- Grulk, and the tracker logged "-tar nausea" (338).
-- ---------------------------------------------------------------------------------------------
describe("F16: someone else's parry (443)", function()
  local HAVYN = "Havyn parries the attack with a deft manoeuvre."

  it("the pattern is anchored: a denizen's parry does not match", function()
    local pats = TL.patterns(PARRY)
    expect(TL.anyMatches(pats, HAVYN)).toBeTrue()
    expect(capture(PARRY, HAVYN)).toBe("Havyn")
    -- kb/raw/logs/ours/2026-11-03_102138_Tabethys.log:335 names the badger; this line is CONSTRUCTED.
    expect(TL.anyMatches(pats, "A grumpy badger parries the attack with a deft manoeuvre.")).toBeFalse()
  end)

  it("leaves the target's nausea", function()
    world("Grulk")
    tarAffed("nausea")
    fire(PARRY, HAVYN, "Havyn")
    expect(P("nausea")).toBe(1)
    expect(tAffs.nausea).toBeTrue()
    expect(#cured()).toBe(0)
  end)

  it("the target's own parry still takes it", function()
    world("Grulk")
    tarAffed("nausea")
    fire(PARRY, "Grulk parries the attack with a deft manoeuvre.", "Grulk")   -- CONSTRUCTED: his name
    expect(P("nausea")).toBe(0)
  end)
end)

-- ---------------------------------------------------------------------------------------------
-- F17 + F46. 706 (with 424 and 442, which read the same lines for the target).
-- ---------------------------------------------------------------------------------------------
describe("F17/F46: whose coating went (706)", function()
  -- kb/raw/logs/ours/2026-10-27_112717_Tabethys.log:6442 has it for Akri; Belaziel's name is CONSTRUCTED.
  local QUICKSILVER = "A supple metallic shell of quicksilver has formed around Belaziel."
  local function coated()
    world("Belaziel")
    fire(GOT_SILERIS, QUICKSILVER)
    expect(haveAff("fangbarrier")).toBeTrue()
    expect(haveAff("sileris")).toBeTrue()
  end
  local function both(path, l)
    if TL.anyMatches(TL.patterns(path), l) then fire(path, l) end
  end
  local function lose(l)
    both(FLAYED_SILERIS, l)
    both(SLICKNESS, l)
  end

  it("someone else's slough leaves the target's coating", function()
    coated()
    -- kb/raw/logs/ours/2026-10-27_135412_Tabethys.log:9526 (the target was Belaziel)
    lose("The protective coating covering the skin of Minkai sloughs off.")
    expect(haveAff("fangbarrier")).toBeTrue()
    expect(haveAff("sileris")).toBeTrue()
    expect(#cured()).toBe(0)
  end)

  it("someone else's rip leaves the target's coating", function()
    coated()
    -- kb/raw/logs/2026-11-03_shikudo-group-alias.txt:3880 (that client's target was Grulk)
    lose("The protective coating covering the skin of Xylarys is ripped away along with his protections.")
    expect(haveAff("fangbarrier")).toBeTrue()
    expect(haveAff("sileris")).toBeTrue()
  end)

  it("both rip forms are read, and name whose coating it was", function()
    local pats = TL.patterns(FLAYED_SILERIS)
    -- kb/raw/logs/ours/2026-11-03_080944_Lauryyn.log:74 and kb/raw/logs/ours/2026-11-07_164635_Saibel.log:308
    local along = "The protective coating covering the skin of Grulk is ripped away along with his protections."
    local ours = "The protective coating covering the skin of Saibel is ripped away with their protections."
    expect(TL.anyMatches(pats, along)).toBeTrue()
    expect(TL.anyMatches(pats, ours)).toBeTrue()
    expect(capture(FLAYED_SILERIS, along)).toBe("Grulk")
    expect(capture(FLAYED_SILERIS, ours)).toBe("Saibel")
    expect(capture(FLAYED_SILERIS, "The protective coating covering the skin of Minkai sloughs off.")).toBe("Minkai")
  end)

  it("the target's own loss still takes both, in every form", function()
    for _, l in ipairs({
      "The protective coating covering the skin of Belaziel sloughs off.",   -- CONSTRUCTED name (row 9526's line)
      "The protective coating covering the skin of Belaziel is ripped away along with his protections.",
      "The protective coating covering the skin of Belaziel is ripped away with their protections.",
      "You flay the metallic coating from Belaziel.",                           -- CONSTRUCTED (706's pattern)
    }) do
      coated()
      lose(l)
      expect(haveAff("fangbarrier")).toBeFalse()
      expect(haveAff("sileris")).toBeFalse()
    end
  end)

  it("the adder line is left alone: it did not take the coating", function()
    -- kb/raw/logs/2026-11-03_shikudo-group-alias.txt:3570; Gavai's flay ripped the coating at 3880.
    local adder = "A death adder lunges for the throat of Xylarys, fangs sinking into his fang barrier defence."
    expect(TL.anyMatches(TL.patterns(FLAYED_SILERIS), adder)).toBeFalse()
  end)
end)

-- ---------------------------------------------------------------------------------------------
-- F20. 553 (with 407, which reads the same writhe line for the target).
-- ---------------------------------------------------------------------------------------------
describe("F20: someone else's writhe out of an impale (553)", function()
  -- kb/raw/logs/ours/2026-11-03_081532_Tabethys.log:1668 (the target was Grulk)
  local TABETHYS = "With a look of agony on her face, Tabethys manages to writhe herself free of the weapon which impaled her."
  -- kb/raw/logs/2026-11-03_shikudo-group-alias.txt:9228, with Grulk's name (CONSTRUCTED name)
  local GRULK = "With a look of agony on his face, Grulk manages to writhe himself free of the weapon which impaled him."

  local function impaled()
    world("Grulk")
    tarAffed("impaled")
    timpale = true
  end
  -- 407's capture is ([\w'\-]+), which capture() does not read: its name is passed.
  local function writhe(l, who)
    fire(NO_IMPALE, l)
    fire(WRITHED, l, who)
  end

  it("the name is the capture", function()
    expect(capture(NO_IMPALE, TABETHYS)).toBe("Tabethys")
  end)

  it("leaves the target impaled", function()
    impaled()
    writhe(TABETHYS, "Tabethys")
    expect(haveAff("impaled")).toBeTrue()
    expect(tAffs.impaled).toBeTrue()
    expect(timpale).toBeTrue()
    expect(#cured()).toBe(0)
  end)

  it("the target's own writhe still frees her", function()
    impaled()
    writhe(GRULK, "Grulk")
    expect(haveAff("impaled")).toBeFalse()
    expect(timpale).toBeFalse()
  end)

  it("our disembowel of the target still ends it (553)", function()
    -- kb/raw/logs/2026-10-11_runewarden-snb-vs-shikudo_defender.txt:2193-2194, with Grulk's name
    local gut = "With a vicious snarl you carve a merciless swathe through the steaming guts of Grulk, who gurgles and chokes as you withdraw your dripping blade, glistening with gore."
    impaled()
    fire(NO_IMPALE, gut, "Grulk")
    expect(haveAff("impaled")).toBeFalse()
    expect(timpale).toBeFalse()
  end)
end)

-- ---------------------------------------------------------------------------------------------
-- F22. 442: the sileris berry's shell.
-- ---------------------------------------------------------------------------------------------
describe("F22: the berry's purple shell (442)", function()
  -- kb/raw/logs/ours/2026-10-27_135412_Tabethys.log:4320
  local BERRY = "A supple purple shell of sileris berry juice has formed around Jakiro."

  it("the line is matched, and the name is its capture", function()
    expect(TL.anyMatches(TL.patterns(GOT_SILERIS), BERRY)).toBeTrue()
    expect(capture(GOT_SILERIS, BERRY)).toBe("Jakiro")
  end)

  it("records the target's fangbarrier and sileris, and resets the gecko strip", function()
    world("Jakiro")
    fire(GOT_SILERIS, BERRY)
    expect(haveAff("fangbarrier")).toBeTrue()
    expect(haveAff("sileris")).toBeTrue()
    expect(serpent.state.geckoStripAttempted).toBeFalse()
  end)

  it("someone else's shell records nothing", function()
    world("Grulk")
    fire(GOT_SILERIS, BERRY)
    expect(haveAff("fangbarrier")).toBeFalse()
    expect(haveAff("sileris")).toBeFalse()
  end)

  it("the berry's application is not the shell (kb/raw/logs/ours/2026-11-03_102138_Tabethys.log:332)", function()
    expect(TL.anyMatches(TL.patterns(GOT_SILERIS), "Grulk applies a sileris berry to himself.")).toBeFalse()
  end)
end)

-- ---------------------------------------------------------------------------------------------
-- F24 + F48. 638: "A ghostly apparition vanishes from sight to the <dir>." names no one.
-- kb/raw/logs/2026-11-01_elmer_alchemist-vs-serpent_loss_Z5cyffxx.txt:2832 (northwest), 3425 (ether).
-- ---------------------------------------------------------------------------------------------
describe("F24/F48: a ghost leaves (638)", function()
  local function ghost(dir)
    local l = "A ghostly apparition vanishes from sight to the " .. dir .. "."
    line = l
    matches = { l, dir }
    BODY[GHOST]()
  end
  local function fight(chasing)
    world("Saibel")
    ataxia.playersHere = { "Saibel", "Kalys" }
    chasing_Targets = chasing
    dir_left = "north"
    tarAffed("paralysis", "anorexia", "asthma", "slickness")
  end
  local function gone()
    expect(sentAny("cq all")).toBeTrue()
    expect(targetIshere).toBeFalse()
    expect(timersOn.TargetOutOfRoom).toBeTrue()
    expect(P("paralysis")).toBe(0)
  end

  it("someone else's ghost (the target still listed) changes nothing", function()
    for _, chasing in ipairs({ false, true }) do
      fight(chasing)
      ghost("west")
      flushNow()
      expect(#sent).toBe(0)
      expect(targetIshere).toBeTrue()
      expect(timersOn.TargetOutOfRoom).toBeNil()
      expect(tChaseTimer).toBeNil()
      expect(dir_left).toBe("north")
      expect(P("paralysis")).toBe(1)
      BODY[OUT_OF_ROOM]()                -- a tick (had the timer started) erases nothing
      expect(P("anorexia")).toBe(1)
      expect(P("asthma")).toBe(1)
      expect(P("slickness")).toBe(1)
    end
  end)

  it("the target's ghost, GMCP removing her first: she left, and we follow", function()
    fight(true)
    ataxia.playersHere = { "Kalys" }
    ghost("west")
    gone()
    expect(sentAny("queue addclear free west")).toBeTrue()
    expect(dir_left).toBe("west")
    expect(tChaseTimer ~= nil).toBeTrue()
  end)

  it("the target's ghost, GMCP removing her after the line: read once the packet is read", function()
    fight(true)
    ghost("northwest")
    expect(#sent).toBe(0)
    ataxia.playersHere = { "Kalys" }     -- RemovePlayer, later in the same packet
    flushNow()
    gone()
    expect(sentAny("queue addclear free northwest")).toBeTrue()
    expect(dir_left).toBe("northwest")
  end)

  it("with no room list, the old reading: she left", function()
    fight(true)
    ataxia.playersHere = nil
    ghost("west")
    gone()
  end)

  it("chasing off: the cleanup, and no move", function()
    fight(false)
    ataxia.playersHere = { "Kalys" }
    ghost("west")
    gone()
    expect(sentAny("queue addclear free")).toBeFalse()
  end)

  it("to the ether: the cleanup, and no move to 'ether' (on foot or mounted)", function()
    for _, mounted in ipairs({ false, true }) do
      fight(true)
      jumping = mounted
      ataxia.playersHere = { "Kalys" }
      ghost("ether")
      gone()
      expect(sentAny("ether")).toBeFalse()
    end
  end)
end)

end)

mock.reset()
table.contains, string.starts, os.clock = savedContains, savedStarts, savedClock
-- Restore the shared Lua state: drop every global the loaded files created and put back every
-- one they replaced.
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
if not ok then error(err) end
