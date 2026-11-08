--- test_serpent_spar_fixes.lua -- the Serpent offence fixes from the 2026-11-07 spar against Saibel
--
-- The user attacks with `zz` (serp_setmode_lock + serp_ekanelia_offense) and, in a group, with `sr`
-- (serp_setmode_group + the same call), so every fix here is in serpent/002 and reaches both.
--   1  recklessness only on a locked target (user: "We shouldnt be doing recklessness unless we
--      have locked them. Else that is a wasted attack"): no eurypteria, no recklessness
--      suggestion, and no loki pair that brings recklessness until anorexia + asthma + slickness;
--   2  "order adder kill" only when our death adder is in the room or we ride it (39 of 39 orders
--      were refused in the spar), with one note per target when it is not;
--   3  the opener puts the round's wield and attack straight after the pinshot, and leaves out
--      combatQueue's three idle commands (the game held six commands and refused the flay);
--   4  the rebounding pre-empt arms only on a rebounding a game line showed, not on the assumed
--      one a new target starts with (it fired at FL 566 for "a non-existent aura");
--   5  one balance action per round: an impulse spends balance too, so no impulse after a flay,
--      and the exit block goes after the attack, not in front of it;
--   6  `aconfig serpent attackfirst`: the attack goes before purge, the adder order and
--      combatQueue's commands. Only a wield (when GMCP shows the weapon is not in hand), a stand
--      (when prone) and the offence's own pre-attack equilibrium step (suggest, seal, hypnotise,
--      which must go on balance) go before it.
--
-- Loads the REAL offence (serpent/002) and the REAL tracker (017's public API over V3, 007 + 008),
-- and builds whole rounds through serp_ekanelia_offense(). Every global the loaded files create or
-- change is restored at the end (one shared Lua state for all test files).

local mock = require("mock_mudlet")
local before = {}
for k, v in pairs(_G) do before[k] = v end
local savedClock, savedContains = os.clock, table.contains

-- Initialised as `X = X or {...}` by the files below, so a table left by an earlier test file would
-- be reused. Cleared here, so the loads build fresh ones; the restore at the end puts the old back.
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

table.contains = table.contains or function(t, v)
  for _, x in pairs(t) do if x == v then return true end end
  return false
end

local OFFENSE = "src_new/scripts/levi_ataxia/levi/levi_scripts/serpent/002_Serpent_Offense.lua"
for _, f in ipairs({
  "src_new/scripts/levi_ataxia/levi/ataxia/017_Affliction_Management.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/007_Branching_State_Tracker.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/008_V3_Integration.lua",
  OFFENSE,
}) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end

-- What 002 registered, taken now because world() resets the mock.
local REB_STRIPPED, REB_NONE
for _, t in pairs(mock.active_triggers) do
  if t.pattern:find("You flay away", 1, true) then REB_STRIPPED = t end
  if t.pattern:find("non-existent aura of rebounding", 1, true) then REB_NONE = t end
end
local function handlers(event)
  local out = {}
  for _, h in pairs(mock.named_handlers[event] or {}) do
    if type(h) == "function" then out[#out + 1] = h end
  end
  return out
end
local TAR_AFFLICTED = handlers("tar afflicted")
local ROOM_HANDLERS = {
  List = handlers("gmcp.Char.Items.List"),
  Add = handlers("gmcp.Char.Items.Add"),
  Remove = handlers("gmcp.Char.Items.Remove"),
}
local CHANGED_TARGET = handlers("changed target")

local TL = dofile("src_new/tests/trigger_lib.lua")
local T400 = "src_new/triggers/levi_ataxia/for_levi/leviticus/400_Rebounding_Strip.lua"
local ALIAS = "src_new/aliases/levi_ataxia/for_levi/levi_062424/configs/034_Serpent_Attack_First.lua"
local CHECK = "src_new/scripts/levi_ataxia/levi/ataxia/002_Check_For_Any_Missing_Variables.lua"
local WIZARD = "src_new/scripts/levi_ataxia/levi/ataxia/misc_scripts/020_Setup_Wizard.lua"

local function read(path)
  local f = assert(io.open(path)); local s = f:read("*a"); f:close(); return s
end

local SHIELD, DIRK, WHIP = "a Shield of Absorption", "Thoth's fang", "Elentari's Scourge"

local clock, sends, events, echoes, gmcpSent = 100, {}, {}, {}, {}
local function world()
  mock.reset()
  clock, sends, events, echoes, gmcpSent = 100, {}, {}, {}, {}
  os.clock = function() return 0.25 end
  getEpoch = function() return clock end
  send = function(c) sends[#sends + 1] = c end
  sendGMCP = function(m) gmcpSent[#gmcpSent + 1] = m end
  raiseEvent = function(e, a) events[#events + 1] = { e, a } end
  target = "Agathon"
  isTargeted = function(n) return n == target end
  checkTargetLocks = function() end
  -- ataxia/003's combatQueue with nothing to parry or chase.
  combatQueue = function() return "g body::g gold::stand::" end
  rTabSize = function(t) local n = 0; for _ in pairs(t or {}) do n = n + 1 end; return n end
  ataxia_wantClumsiness = function() return false end
  getLockingAffliction = function() return "paralyse" end
  ataxiaNDB_getClass = function() return "Serpent" end
  ataxiaEcho, zgui, cecho = function() end, nil, function() end
  Algedonic.Echo = function(s) echoes[#echoes + 1] = s end
  ataxiaTemp, tAffs, affTimers = { tarAffTimers = {} }, {}, {}
  tBals = { tree = true, focus = true, timers = {} }
  ataxia.afflictions = {}
  ataxia.playersHere = { "Agathon" }
  ataxia.settings.serpentattackfirst = nil
  ataxia.settings.user = nil
  gmcp = { Char = { Vitals = { bal = "1" } } }
  Rebounding, Shielded, reboundHold, classDetect, tarClass = false, false, nil, nil, ""
  hypSeal2, snapped, canShrug, tpinshot = nil, nil, nil, nil
  ataxiaBasher_isMounted, omount, ataxiaBasher, ataxiaBasher_CLASS_PETS = nil, nil, nil, nil
  serpent.config.useExitBlock = false
  resetStatesV3()

  serpOffenseMode, serpStrategy = "lock", "lock"
  lastImpulsed, lastImpatienceAttempt, lastReboundingFlay = {}, 0, 0
  hSuggRequest, hSuggActive = "", ""
  serpent.hypnosis.mode = "fratricide"
  serpent.hypnosis.reset()
  serpent.cureTracking = { kelpCures = 0, ginsengCures = 0, bloodrootCures = 0, focusCures = 0,
    lastReset = 0, trackingWindow = 6 }
  local s = serpent.state
  s.attackInFlight, s.firstAttack, s.dispelSent = false, false, true   -- no opener, no dispel
  s.impatienceDelivered, s.relapsePhase, s.stupidityImpulseSent, s.voyriaSent = false, false, false, false
  s.geckoStripAttempted, s.postGeckoLockdown, s.lastRebounding, s.shouldShrug = false, false, false, nil
  s.lockReinforceSent, s.camusDelivered, s.sigilDeployed, s.pinshotSentAt = false, false, false, 0
  s.reboundingSeen, s.snakesHere, s.adderNotedFor, s.roomListSeen = false, {}, nil, false
  s.lastWieldKw, s.lastWieldBefore = nil, nil
  s.lastBlockSentAt, s.blockedExits = 0, {}
end

local function give(...) tarAffed(...) end

local function round()
  sends = {}
  serpent.state.attackInFlight = false
  serp_ekanelia_offense()
  return table.concat(sends, "\n")
end

local function has(s, needle) return s:find(needle, 1, true) ~= nil end

-- The commands the game gets: Mudlet splits the line on the separator.
local function pieces(line)
  local out, start = {}, 1
  while true do
    local i, j = line:find("::", start, true)
    local p = line:sub(start, i and (i - 1) or #line)
    if p ~= "" then out[#out + 1] = p end
    if not i then break end
    start = j + 1
  end
  return out
end

-- The pieces that spend our balance.
local BALANCE = { dstab = true, doublestab = true, flay = true, impulse = true, bite = true,
  behead = true, execute = true, pinshot = true }
local function balanceActions(line)
  local n = 0
  for _, p in ipairs(pieces(line)) do
    local w = p:gsub("^queue addclear freestand ", ""):match("^(%S+)")
    if w and BALANCE[w:lower()] then n = n + 1 end
  end
  return n
end

local function adderEchoes()
  local n = 0
  for _, e in ipairs(echoes) do if has(e, "ADDER") then n = n + 1 end end
  return n
end

-- GMCP room contents, through the handlers 002 registered.
local function roomEvent(key, payload)
  gmcp.Char.Items = gmcp.Char.Items or {}
  gmcp.Char.Items[key] = payload
  for _, h in ipairs(ROOM_HANDLERS[key]) do h("gmcp.Char.Items." .. key) end
end
local function adderInRoom()
  roomEvent("List", { location = "room", items = {
    { id = "5501", name = "a death adder", attrib = "m" },
    { id = "77", name = "a rat", attrib = "m" },
  } })
end

local function hands(t) ataxiaTemp.wieldedItems = t end

local function retarget(name)
  target = name
  ataxia.playersHere = { name }
  for _, h in ipairs(CHANGED_TARGET) do h("changed target") end
end

local ok, err = pcall(function()

describe("fix 1: recklessness only on a locked target", function()
  local function noReck(r)
    expect(has(r, "eurypteria")).toBeFalse()
    expect(has(r, " recklessness ")).toBeFalse()
  end

  it("an unlocked Depthswalker never gets eurypteria or a recklessness suggestion", function()
    local boards = {
      { "paralysis" },
      { "paralysis", "asthma" },
      { "paralysis", "asthma", "weariness" },
      { "paralysis", "anorexia", "asthma" },
      { "paralysis", "asthma", "slickness" },
      { "paralysis", "asthma", "slickness", "bloodfire" },   -- the offence's 3-of-4 softlock
      { "paralysis", "confusion" },
      { "paralysis", "confusion", "stupidity", "masochism" },
    }
    for _, by in ipairs({ "tarClass", "classDetect" }) do
      for _, mode in ipairs({ "lock", "group" }) do
        for _, b in ipairs(boards) do
          world()
          serpOffenseMode = mode
          if by == "tarClass" then tarClass = "Depthswalker"
          else classDetect = { state = { attackerClass = "depthswalker" } } end
          give(table.unpack and table.unpack(b) or unpack(b))
          expect(serpent.recklessnessAllowed()).toBeFalse()
          for _ = 1, 3 do
            noReck(round())
            clock = clock + 2
          end
        end
      end
    end
  end)

  it("a locked Depthswalker gets eurypteria", function()
    world(); tarClass = "Depthswalker"
    give("anorexia", "asthma", "slickness", "paralysis")
    expect(serpent.recklessnessAllowed()).toBeTrue()
    expect(has(round(), "eurypteria")).toBeTrue()
  end)

  it("the recklessness suggestion waits for the lock", function()
    world(); give("confusion", "stupidity", "masochism")
    expect(selectFallbackSuggestion()).toBe("vertigo")
    world(); give("confusion", "stupidity", "masochism", "anorexia", "asthma", "slickness")
    expect(selectFallbackSuggestion()).toBe("recklessness")
  end)

  it("the loki pair does not bring recklessness to an unlocked target", function()
    world(); give("confusion")
    expect(selectImpulsePair()).toBeNil()
    world(); give("confusion", "anorexia", "asthma", "slickness")
    local pair = selectImpulsePair()
    expect(pair.suggestion).toBe("recklessness")
    expect(pair.venom).toBe("loki")
  end)

  it("a group round over asthma and confusion sends no recklessness impulse", function()
    world(); serpOffenseMode = "group"; give("asthma", "confusion")
    noReck(round())
  end)

  it("a piece that is gone opens no lock", function()
    world(); give("anorexia", "asthma", "slickness")
    expect(serpent.recklessnessAllowed()).toBeTrue()
    erAff("slickness")
    expect(serpent.recklessnessAllowed()).toBeFalse()
  end)

  -- The threshold itself. The target's tree on the bare lock cures one of the three pieces, and
  -- the tracker cannot see which, so each piece sits at 2/3: above haveAff's 0.30, below 0.70.
  it("each piece of the lock must read at 0.70, not at haveAff's 0.30", function()
    for _, mode in ipairs({ "lock", "group" }) do
      world(); serpOffenseMode = mode; tarClass = "Depthswalker"
      give("anorexia", "asthma", "slickness")
      onTargetTreeV3()
      for _, piece in ipairs({ "anorexia", "asthma", "slickness" }) do
        local p = getAffProbabilityV3(piece)
        expect(p > 0.30 and p < 0.70).toBeTrue()
        expect(haveAff(piece)).toBeTrue()
      end
      expect(serpent.recklessnessAllowed()).toBeFalse()
      expect(selectFallbackSuggestion() ~= "recklessness").toBeTrue()
      for _ = 1, 3 do
        noReck(round())
        clock = clock + 2
      end
    end
  end)

  it("one piece below 0.70 holds the lock, the other two at 1.0", function()
    world(); tarClass = "Depthswalker"
    give("anorexia", "asthma", "slickness", "paralysis")
    -- Half the branches lost the slickness (an unseen cure, for example).
    local keep = afflictionStatesV3[1]
    local lost = { affs = {}, prob = keep.prob / 2 }
    for k, v in pairs(keep.affs) do lost.affs[k] = v end
    lost.affs.slickness = nil
    keep.prob = keep.prob / 2
    afflictionStatesV3[#afflictionStatesV3 + 1] = lost
    rebuildCacheV3()
    syncToOldSystemV3()
    expect(getAffProbabilityV3("slickness")).toBe(0.5)
    expect(haveAff("slickness")).toBeTrue()
    expect(serpent.recklessnessAllowed()).toBeFalse()
    noReck(round())
  end)
end)

describe("fix 2: the adder order only with the adder here", function()
  it("no adder: no order, and one note per target", function()
    world()
    local r = round()
    expect(has(r, "order adder")).toBeFalse()
    expect(adderEchoes()).toBe(1)
    clock = 102
    expect(has(round(), "order adder")).toBeFalse()
    expect(adderEchoes()).toBe(1)
    retarget("Claes")
    expect(has(round(), "order adder")).toBeFalse()
    expect(adderEchoes()).toBe(2)
  end)

  it("an adder in the room gets the order; it stops when the adder leaves, and comes back with it", function()
    world(); adderInRoom()
    expect(serpent.adderHere()).toBeTrue()
    expect(has(round(), "order adder kill Agathon")).toBeTrue()
    expect(adderEchoes()).toBe(0)

    roomEvent("Remove", { location = "room", item = { id = "5501", name = "a death adder" } })
    expect(has(round(), "order adder")).toBeFalse()
    expect(adderEchoes()).toBe(1)

    roomEvent("Add", { location = "room", item = { id = "5501", name = "a death adder", attrib = "m" } })
    expect(has(round(), "order adder kill Agathon")).toBeTrue()
    -- Seeing the adder again clears the note, so the next loss is said again.
    roomEvent("Remove", { location = "room", item = { id = "5501", name = "a death adder" } })
    round()
    expect(adderEchoes()).toBe(2)
  end)

  it("with no room list since the load, the room is asked for once", function()
    world()
    round()
    clock = 102
    round()
    local asked = 0
    for _, m in ipairs(gmcpSent) do if m == "Char.Items.Room" then asked = asked + 1 end end
    expect(asked).toBe(1)

    world(); adderInRoom()                      -- a room list: nothing to ask
    roomEvent("Remove", { location = "room", item = { id = "5501", name = "a death adder" } })
    round()
    expect(#gmcpSent).toBe(0)
  end)

  it("a new room's list replaces the picture", function()
    world(); adderInRoom()
    roomEvent("List", { location = "room", items = { { id = "77", name = "a rat", attrib = "m" } } })
    expect(serpent.adderHere()).toBeFalse()
  end)

  it("a dead adder, an adder corpse, or an adder in our inventory is not our adder here", function()
    world()
    roomEvent("List", { location = "room", items = {
      { id = "1", name = "a death adder", attrib = "md" },
      { id = "2", name = "the corpse of a death adder", attrib = "t" },
    } })
    expect(serpent.adderHere()).toBeFalse()
    roomEvent("List", { location = "inv", items = { { id = "3", name = "a death adder", attrib = "m" } } })
    expect(serpent.adderHere()).toBeFalse()
    roomEvent("Add", { location = "inv", item = { id = "3", name = "a death adder", attrib = "m" } })
    expect(serpent.adderHere()).toBeFalse()
  end)

  it("an item that is not a living monster is not our adder", function()
    world()
    roomEvent("List", { location = "room", items = {
      { id = "4", name = "a death adder fang", attrib = "t" },
      { id = "5", name = "a statue of a death adder" },
      { id = "6", name = "a death adder skin", attrib = "tw" },
    } })
    expect(serpent.adderHere()).toBeFalse()
    expect(has(round(), "order adder")).toBeFalse()
    roomEvent("Add", { location = "room", item = { id = "7", name = "a death adder fang", attrib = "t" } })
    roomEvent("Add", { location = "room", item = { id = "8", name = "a carved death adder" } })
    expect(serpent.adderHere()).toBeFalse()
  end)

  it("our adder counts with the do-not-attack flag too", function()
    world()
    roomEvent("List", { location = "room", items = { { id = "9", name = "a death adder", attrib = "mx" } } })
    expect(serpent.adderHere()).toBeTrue()
    world()
    roomEvent("Add", { location = "room", item = { id = "9", name = "a death adder", attrib = "mx" } })
    expect(has(round(), "order adder kill Agathon")).toBeTrue()
  end)

  it("riding the adder counts, by the mount's name or its id", function()
    world()
    ataxiaBasher_isMounted = function() return true end
    omount = "a death adder"
    expect(has(round(), "order adder kill Agathon")).toBeTrue()

    world()
    ataxiaBasher_isMounted = function() return true end
    ataxia.settings.user = { mount = "5501" }
    ataxiaBasher = { mountIds = { [5501] = "a death adder" } }
    expect(has(round(), "order adder kill Agathon")).toBeTrue()

    world()
    ataxiaBasher_isMounted = function() return true end
    omount = "a black stallion"
    expect(has(round(), "order adder")).toBeFalse()

    world()
    ataxiaBasher_isMounted = function() return false end
    omount = "a death adder"                     -- the last mount, but we are not on it now
    expect(has(round(), "order adder")).toBeFalse()
  end)
end)

describe("fix 3: the opener", function()
  local function opening()
    world()
    serpent.state.firstAttack, serpent.state.dispelSent = true, false
  end

  it("the wield and the flay go straight after the pinshot, and the idle commands are left out", function()
    opening(); Rebounding = true
    expect(round()).toBe("queue addclear freestand dispel Agathon::purge::remove bow::wield bow"
      .. "::pinshot Agathon foot::wield shield whip::flay Agathon rebounding curare")
  end)

  it("the adder order goes after the attack", function()
    opening(); Rebounding = true; adderInRoom()
    expect(round()).toBe("queue addclear freestand dispel Agathon::purge::remove bow::wield bow"
      .. "::pinshot Agathon foot::wield shield whip::flay Agathon rebounding curare::order adder kill Agathon")
  end)

  it("a dstab opener wields the dirk once", function()
    opening()
    local r = round()
    local p = pieces(r)
    expect(p[5]).toBe("pinshot Agathon foot")
    expect(p[6]).toBe("wield shield dirk")
    expect(p[7]:match("^dstab Agathon ") ~= nil).toBeTrue()
    expect(#p).toBe(7)
  end)

  it("prone, the stand goes before the bow", function()
    opening(); Rebounding = true; ataxia.afflictions.prone = true
    local p = pieces(round())
    expect(p[2]).toBe("purge")
    expect(p[3]).toBe("stand")
    expect(p[4]).toBe("remove bow")
  end)

  it("the opener is the same with attackfirst on", function()
    opening(); Rebounding = true; ataxia.settings.serpentattackfirst = true
    hands({ ["111"] = SHIELD, ["444"] = WHIP })
    expect(round()).toBe("queue addclear freestand dispel Agathon::purge::remove bow::wield bow"
      .. "::pinshot Agathon foot::wield shield whip::flay Agathon rebounding curare")
  end)

  it("the opener runs once per target", function()
    opening(); Rebounding = true
    round()
    clock = 102
    local r = round()
    expect(has(r, "pinshot")).toBeFalse()
    expect(has(r, "dispel")).toBeFalse()
  end)
end)

describe("fix 4: the rebounding pre-empt arms only on a rebounding a line showed", function()
  local function line(trig, text, who)
    matches = { text, who }
    assert((loadstring or load)(trig.callback))()
  end

  it("002's two flay lines match the game's lines, as trigger 400's do", function()
    local stripped = "You flay away Agathon's aura of rebounding defence."
    local none = "You try to flay a non-existent aura of rebounding from Agathon."
    expect(TL.matches(REB_STRIPPED.pattern, 1, stripped)).toBeTrue()
    expect(TL.matches(REB_NONE.pattern, 1, none)).toBeTrue()
    expect(TL.matches(REB_STRIPPED.pattern, 1, none)).toBeFalse()
    local p400 = TL.patterns(T400)
    expect(TL.anyMatches(p400, stripped)).toBeTrue()
    expect(TL.anyMatches(p400, none)).toBeTrue()
  end)

  it("the assumed rebounding of a new target does not arm it", function()
    world(); Rebounding = true
    expect(has(round(), "flay Agathon rebounding")).toBeTrue()
    Rebounding = false
    round()
    expect(lastReboundingFlay).toBe(0)
  end)

  it("a flay that finds no rebounding does not arm it (FL 305, FL 566)", function()
    world(); Rebounding = true
    round()
    line(REB_NONE, "You try to flay a non-existent aura of rebounding from Agathon.", "Agathon")
    Rebounding = false
    round()
    expect(lastReboundingFlay).toBe(0)
    clock = 110
    expect(has(round(), "impulse")).toBeFalse()
  end)

  it("the strip line arms it, once", function()
    world(); Rebounding = true
    round()
    line(REB_STRIPPED, "You flay away Agathon's aura of rebounding defence.", "Agathon")
    expect(serpent.state.reboundingSeen).toBeTrue()
    Rebounding = false
    round()
    expect(lastReboundingFlay).toBe(100)
    expect(serpent.state.reboundingSeen).toBeFalse()
    clock = 108.2
    expect(has(round(), "impulse Agathon")).toBeTrue()
    expect(lastReboundingFlay).toBe(0)
  end)

  it("a strip line about someone else does not arm it", function()
    world(); Rebounding = true
    round()
    line(REB_STRIPPED, "You flay away Claes's aura of rebounding defence.", "Claes")
    Rebounding = false
    round()
    expect(lastReboundingFlay).toBe(0)
  end)

  it("a raise line (tar afflicted with rebounding) arms it", function()
    expect(#TAR_AFFLICTED).toBe(1)
    world(); Rebounding = true
    round()
    TAR_AFFLICTED[1]("tar afflicted", { "rebounding" })
    Rebounding = false
    round()
    expect(lastReboundingFlay).toBe(100)

    world(); Rebounding = true
    round()
    TAR_AFFLICTED[1]("tar afflicted", { "asthma" })
    Rebounding = false
    round()
    expect(lastReboundingFlay).toBe(0)
  end)

  it("a target change forgets what was seen", function()
    world()
    serpent.onTargetAfflicted("rebounding")
    expect(serpent.state.reboundingSeen).toBeTrue()
    retarget("Claes")
    expect(serpent.state.reboundingSeen).toBeFalse()
  end)
end)

describe("fix 5: one balance action per round", function()
  it("the kalmia reaction does not ride the flay", function()
    world(); Shielded = true; give("clumsiness", "weariness")
    local r = round()
    expect(has(r, "flay Agathon shield")).toBeTrue()
    expect(has(r, "impulse")).toBeFalse()
    expect(balanceActions(r)).toBe(1)
  end)

  it("no round sends two balance actions, in any mode or board", function()
    local boards = {
      {},
      { "paralysis" },
      { "clumsiness", "weariness" },
      { "asthma", "weariness", "slickness" },
      { "asthma", "weariness", "masochism" },
      { "anorexia", "asthma", "slickness", "paralysis", "impatience" },
      { "confusion", "recklessness" },
      { "addiction", "nausea" },
      { "fratricide", "impatience", "asthma", "weariness", "stupidity", "masochism", "recklessness", "vertigo" },
    }
    local defences = { "none", "shield", "rebounding" }
    local checked = 0
    for _, mode in ipairs({ "lock", "group", "darkshade", "scytherus", "bitepayload" }) do
      for _, d in ipairs(defences) do
        for _, b in ipairs(boards) do
          world()
          serpOffenseMode = mode
          Shielded, Rebounding = (d == "shield"), (d == "rebounding")
          if #b > 0 then give(table.unpack and table.unpack(b) or unpack(b)) end
          local r = round()
          if r ~= "" then
            checked = checked + 1
            if balanceActions(r) > 1 then error("two balance actions (" .. mode .. ", " .. d .. "): " .. r) end
          end
        end
      end
    end
    expect(checked > 100).toBeTrue()
  end)

  -- No log shows what BLOCK costs. It went out raw in front of the round, so a balance-spending
  -- BLOCK made the attack wait a whole balance. Now it goes last, after the attack.
  it("the exit block goes after the attack, in the same send, in every order", function()
    local function blockRound(setup)
      world(); setup()
      serpent.config.useExitBlock = true
      gmcp.Room = { Info = { exits = { east = 1234 } } }
      local r = round()
      serpent.config.useExitBlock = false
      expect(#sends).toBe(1)
      local p = pieces(r)
      expect(p[#p]).toBe("block east")
      local attackAt
      for i, piece in ipairs(p) do
        local w = piece:gsub("^queue addclear freestand ", ""):match("^(%S+)")
        if w == "dstab" or w == "flay" then attackAt = attackAt or i end
      end
      expect(attackAt ~= nil and attackAt < #p).toBeTrue()
      expect(p[1] ~= "block east").toBeTrue()
      return p
    end
    blockRound(function() end)
    blockRound(function()
      ataxia.settings.serpentattackfirst = true
      hands({ ["111"] = SHIELD, ["555"] = "a curved dirk" })
    end)
    blockRound(function() serpent.state.firstAttack, serpent.state.dispelSent = true, false; Shielded = true end)
  end)

  it("the exit block keeps its 5 s throttle", function()
    world()
    serpent.config.useExitBlock = true
    gmcp.Room = { Info = { exits = { east = 1234 } } }
    expect(has(round(), "block east")).toBeTrue()
    clock = 102
    expect(has(round(), "block")).toBeFalse()
    clock = 105
    expect(has(round(), "block east")).toBeTrue()
    serpent.config.useExitBlock = false
  end)

  it("the opener's pinshot and attack are the one exception", function()
    world(); serpent.state.firstAttack, serpent.state.dispelSent = true, false; Shielded = true
    expect(balanceActions(round())).toBe(2)
  end)
end)

describe("fix 6: aconfig serpent attackfirst", function()
  local DSTAB

  -- The dstab an empty board gets, read from a plain round.
  local function dstab()
    if not DSTAB then
      world()
      local p = pieces(round())
      DSTAB = p[#p]
      assert(DSTAB:match("^dstab Agathon %S+ %S+$"), "not a dstab: " .. tostring(DSTAB))
    end
    return DSTAB
  end

  it("off (the default): purge, the idle commands, the wield, then the attack", function()
    local d = dstab()
    world()
    expect(round()).toBe("queue addclear freestand purge::g body::g gold::stand::wield shield dirk::" .. d)
    world(); adderInRoom()
    expect(round()).toBe("queue addclear freestand purge::order adder kill Agathon::g body::g gold::stand"
      .. "::wield shield dirk::" .. d)
  end)

  it("on, weapon in hand: the attack is the first command", function()
    local d = dstab()
    world(); ataxia.settings.serpentattackfirst = true
    hands({ ["111"] = SHIELD, ["555"] = "a curved dirk" })
    expect(round()).toBe("queue addclear freestand " .. d .. "::purge::g body::g gold::stand")
    world(); ataxia.settings.serpentattackfirst = true; adderInRoom()
    hands({ ["111"] = SHIELD, ["555"] = "a curved dirk" })
    expect(round()).toBe("queue addclear freestand " .. d .. "::purge::order adder kill Agathon"
      .. "::g body::g gold::stand")
  end)

  it("on, the wrong weapon in hand: the wield goes first, then the attack", function()
    local d = dstab()
    world(); ataxia.settings.serpentattackfirst = true
    hands({ ["111"] = SHIELD, ["444"] = "a leather whip" })
    expect(round()).toBe("queue addclear freestand wield shield dirk::" .. d .. "::purge::g body::g gold::stand")
  end)

  it("on, prone: a raw stand goes in front of the queue command, and only once", function()
    local d = dstab()
    world(); ataxia.settings.serpentattackfirst = true; ataxia.afflictions.prone = true
    hands({ ["111"] = SHIELD, ["555"] = "a curved dirk" })
    expect(round()).toBe("stand::queue addclear freestand " .. d .. "::purge::g body::g gold")
    world(); ataxia.settings.serpentattackfirst = true; ataxia.afflictions.prone = true
    hands({ ["111"] = SHIELD, ["444"] = "a leather whip" })
    expect(round()).toBe("stand::queue addclear freestand wield shield dirk::" .. d .. "::purge::g body::g gold")
  end)

  it("on, hands not known: the wield goes first, and the inventory is asked for once", function()
    local d = dstab()
    world(); ataxia.settings.serpentattackfirst = true
    expect(round()).toBe("queue addclear freestand wield shield dirk::" .. d .. "::purge::g body::g gold::stand")
    clock = 102
    round()
    local inv = 0
    for _, m in ipairs(gmcpSent) do if m == "Char.Items.Inv" then inv = inv + 1 end end
    expect(inv).toBe(1)
  end)

  it("on, the artefact weapons are learned by their ids", function()
    local d = dstab()
    world(); ataxia.settings.serpentattackfirst = true
    hands({ ["111"] = SHIELD, ["444"] = WHIP })
    expect(pieces(round())[1]).toBe("queue addclear freestand wield shield dirk")
    hands({ ["111"] = SHIELD, ["555"] = DIRK })             -- GMCP shows the wield
    clock = 102
    expect(pieces(round())[1]).toBe("queue addclear freestand " .. d)
    expect(ataxiaTemp.serpentWeaponIds.dirk).toBe("555")

    Shielded = true
    clock = 104
    expect(pieces(round())[1]).toBe("queue addclear freestand wield shield whip")
    hands({ ["111"] = SHIELD, ["444"] = WHIP })
    clock = 106
    local p = pieces(round())
    expect(p[1]:match("^queue addclear freestand flay Agathon shield ") ~= nil).toBeTrue()
    expect(ataxiaTemp.serpentWeaponIds.whip).toBe("444")

    Shielded = false
    clock = 108
    expect(pieces(round())[1]).toBe("queue addclear freestand wield shield dirk")   -- 555 not in hand
  end)

  it("on, a wield that changed nothing teaches nothing", function()
    world(); ataxia.settings.serpentattackfirst = true
    hands({ ["111"] = SHIELD, ["444"] = WHIP })
    round()
    clock = 102                                            -- still the whip: the wield failed
    expect(pieces(round())[1]).toBe("queue addclear freestand wield shield dirk")
    expect(ataxiaTemp.serpentWeaponIds.dirk).toBeNil()
  end)

  -- Since 2026-10-23 a SUGGEST off balance takes a fixed equilibrium, and a SEAL off balance an
  -- unmodified one (kb/changes/2026-10-23_classleads.md). The offence puts them before the attack,
  -- so attack-first must too.
  it("on, an equilibrium step the offence puts before the attack stays before it", function()
    world(); ataxia.settings.serpentattackfirst = true
    hands({ ["111"] = SHIELD, ["555"] = "a curved dirk" })
    serp_sendAttack("wield shield dirk::hypnotise Agathon::dstab Agathon curare kalmia",
      "g body::g gold::stand::parry left leg::")
    expect(sends[#sends]).toBe("queue addclear freestand hypnotise Agathon::dstab Agathon curare kalmia"
      .. "::purge::g body::g gold::stand::parry left leg")
    serp_sendAttack("wield shield dirk::suggest Agathon fratricide::dstab Agathon curare kalmia", "")
    expect(sends[#sends]).toBe("queue addclear freestand suggest Agathon fratricide::dstab Agathon curare kalmia"
      .. "::purge")
    -- The wrong weapon in hand: the wield, then the step, then the attack (the offence's own order).
    hands({ ["111"] = SHIELD, ["444"] = "a leather whip" })
    serp_sendAttack("wield shield dirk::seal Agathon 2::bite Agathon scytherus", "")
    expect(sends[#sends]).toBe("queue addclear freestand wield shield dirk::seal Agathon 2"
      .. "::bite Agathon scytherus::purge")
  end)

  it("on, a step the offence puts after the attack stays after it", function()
    world(); ataxia.settings.serpentattackfirst = true
    hands({ ["111"] = SHIELD, ["555"] = "a curved dirk" })
    serp_sendAttack("wield shield dirk::dstab Agathon curare kalmia::snap Agathon", "")
    expect(sends[#sends]).toBe("queue addclear freestand dstab Agathon curare kalmia::snap Agathon::purge")
    serp_sendAttack("wield shield dirk::dstab Agathon curare kalmia::shrugging", "g body::")
    expect(sends[#sends]).toBe("queue addclear freestand dstab Agathon curare kalmia::shrugging::purge::g body")
  end)

  it("on, the offence's own suggest and seal rounds keep the step on balance", function()
    local function stepThenAttack(r, step)
      local p = pieces(r)
      expect(p[1]).toBe("queue addclear freestand " .. step)
      expect(p[2]:match("^dstab Agathon %S+ %S+$") ~= nil).toBeTrue()
      expect(p[3]).toBe("purge")
    end
    -- Fratricide mode, target hypnotised: the suggest goes on balance, then the dstab.
    world(); ataxia.settings.serpentattackfirst = true
    hands({ ["111"] = SHIELD, ["555"] = "a curved dirk" })
    serpent.hypnosis.mode, serpent.hypnosis.phase = "fratricide", "hypnotised"
    stepThenAttack(round(), "suggest Agathon fratricide")

    -- Lock mode, every suggestion given: the seal goes on balance, then the dstab.
    world(); ataxia.settings.serpentattackfirst = true
    hands({ ["111"] = SHIELD, ["555"] = "a curved dirk" })
    serpent.hypnosis.mode, serpent.hypnosis.phase = "lock", "suggesting"
    serpent.hypnosis.targetSuggestions = { "stupidity", "paranoia" }
    serpent.hypnosis.suggestions = { "stupidity", "paranoia" }
    serpent.hypnosis.sealed = false
    stepThenAttack(round(), "seal Agathon 2")

    -- Sealed: the snap goes after the dstab.
    serpent.hypnosis.sealed = true
    clock = 102
    local p = pieces(round())
    expect(p[1]:match("^queue addclear freestand dstab Agathon %S+ %S+$") ~= nil).toBeTrue()
    expect(p[2]).toBe("snap Agathon")
    serpent.hypnosis.mode = "fratricide"
  end)

  it("on, a command with no attack keeps the old order", function()
    world(); ataxia.settings.serpentattackfirst = true
    serp_sendAttack("hypnotise Agathon", "g body::")
    expect(sends[#sends]).toBe("queue addclear freestand purge::g body::hypnotise Agathon")
  end)

  it("the status shows the setting, the adder and the recklessness gate", function()
    world()
    local out = {}
    cecho = function(s) out[#out + 1] = s end
    serp_status()
    local all = table.concat(out)
    expect(has(all, "Attack First")).toBeTrue()
    expect(has(all, "Death Adder")).toBeTrue()
    expect(has(all, "Recklessness")).toBeTrue()
  end)
end)

describe("aconfig serpent attackfirst: the alias, the default and the wizard", function()
  local savedSave, savedEcho = ataxia_saveSettings, ataxiaEcho
  local saves, said

  local function run(arg, settings)
    local savedSettings = ataxia.settings
    ataxia.settings = settings
    saves, said = 0, nil
    ataxia_saveSettings = function() saves = saves + 1 end
    ataxiaEcho = function(s) said = s end
    matches = { "aconfig serpent attackfirst" .. (arg and (" " .. arg) or ""), arg }
    local okRun, e = pcall(dofile, ALIAS)
    ataxia_saveSettings, ataxiaEcho = savedSave, savedEcho
    local result = ataxia.settings.serpentattackfirst
    ataxia.settings = savedSettings
    if not okRun then error(e, 0) end
    return result
  end

  it("on saves it", function()
    expect(run("on", {})).toBeTrue()
    expect(saves).toBe(1)
    expect(has(said, "on")).toBeTrue()
  end)

  it("off stores false, not nil", function()
    expect(run("off", { serpentattackfirst = true })).toBe(false)
    expect(saves).toBe(1)
  end)

  it("with no argument it only shows the setting", function()
    expect(run(nil, { serpentattackfirst = true })).toBeTrue()
    expect(saves).toBe(0)
    expect(has(said, "on")).toBeTrue()
  end)

  it("the alias takes on, off or nothing", function()
    expect(has(read(ALIAS), "regex: ^aconfig serpent attackfirst(?: (on|off))?$")).toBeTrue()
  end)

  it("defaults to off", function()
    expect(has(read(CHECK), "ataxia.settings.serpentattackfirst = false")).toBeTrue()
    expect(has(read(CHECK), "ataxia.settings.serpentattackfirst = true")).toBeFalse()
  end)

  it("the setup wizard shows it and names the command", function()
    local src = read(WIZARD)
    expect(has(src, "ataxia.settings.serpentattackfirst")).toBeTrue()
    expect(has(src, "aconfig serpent attackfirst <on|off>")).toBeTrue()
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
