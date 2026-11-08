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
-- And the review of these fixes (2026-11-08), venom and impulse selection: the class gates read
-- our TARGET's class (tarClass was never assigned; attackerClass is whoever hit us); group mode
-- counts the first venom's slickness; the monkshood impulse always carries masochism; no impulse
-- on a reaction that gives nothing new; the relapse stupidity impulse waits for stupidity to go;
-- a lightwall in the room brings darkshade; the pet snake's bite records fratricide; the target's
-- kelp eats reach the adaptive count.
--
-- Loads the REAL offence (serpent/002), the REAL class gates (ataxia/007_Pariah_things) and the
-- REAL tracker (017's public API over V3, 007 + 008), and builds whole rounds through
-- serp_ekanelia_offense(). Every global the loaded files create or change is restored at the end
-- (one shared Lua state for all test files).

local mock = require("mock_mudlet")
local before = {}
for k, v in pairs(_G) do before[k] = v end
local savedClock, savedContains, savedStarts = os.clock, table.contains, string.starts

-- Initialised as `X = X or {...}` by the files below, so a table left by an earlier test file would
-- be reused. Cleared here, so the loads build fresh ones; the restore at the end puts the old back.
-- `pariah` too: the runner sets it to "" and 007_Pariah_things indexes it.
for _, k in ipairs({ "serpent", "Algedonic", "lastImpulsed", "lastReboundingFlay", "lastImpatienceAttempt",
  "serpOffenseMode", "serpStrategy", "attackMode", "ekaneliaReady", "affTimers", "hSuggRequest", "hSuggActive",
  "afflictionStatesV3", "affConfigV3", "simpleAffsV3", "affCacheV3", "targetBurningLevelV3", "affLastConfirmedV3",
  "targetDefensesV3", "cureBalancesV3", "cureBalanceTimerIDsV3", "passiveCooldownsV3", "negativeConfirmTimersV3",
  "curingTable", "pariah" }) do
  _G[k] = nil
end
ataxia = { settings = { separator = "::" }, playersHere = { "Agathon" }, afflictions = {} }
ataxiaTemp, tAffs, affTimers = {}, {}, {}
Algedonic = {}

table.contains = table.contains or function(t, v)
  for _, x in pairs(t) do if x == v then return true end end
  return false
end
-- string.starts is a Mudlet extension (the real isTargeted uses it); restored at the end.
string.starts = string.starts or function(s, p) return s:sub(1, #p) == p end

local OFFENSE = "src_new/scripts/levi_ataxia/levi/levi_scripts/serpent/002_Serpent_Offense.lua"
-- 007_Pariah_things holds the class gates the offence reads (ataxia_targetClass,
-- ataxia_wantClumsiness). Loaded, not stubbed: world() sets the target's CLASS instead.
for _, f in ipairs({
  "src_new/scripts/levi_ataxia/levi/ataxia/017_Affliction_Management.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/007_Branching_State_Tracker.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/008_V3_Integration.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/ataxia/007_Pariah_things.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/016_Targeting_Functions.lua",
  OFFENSE,
}) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end
-- The real name guard (016), for the F35 tests. world() puts in an exact-name isTargeted for the
-- rest, and nothing else here has an updateTarget.
local realIsTargeted, realUpdateTarget = isTargeted, updateTarget
updateTarget = nil

-- What 002 registered, taken now because world() resets the mock.
local REB_STRIPPED, REB_NONE, SUGGEST_GIVEN
for _, t in pairs(mock.active_triggers) do
  if t.pattern:find("You flay away", 1, true) then REB_STRIPPED = t end
  if t.pattern:find("non-existent aura of rebounding", 1, true) then REB_NONE = t end
  if t.pattern:find("You issue the suggestion", 1, true) then SUGGEST_GIVEN = t end
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
local VITALS = handlers("gmcp.Char.Vitals")        -- 002's balRecovery

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
-- The NDB's classes by name: what ataxiaNDB_getClass answers ("Unknown" for no entry, as 003's does).
local ndb = {}
-- getLockingAffliction's rows for the classes these tests use (scripts/_groups.yaml:324): "name"
-- asks for the affliction, any other argument for the game's word.
local LOCK_AFF = {
  Occultist = { "paralysis", "paralyse" }, Shaman = { "paralysis", "paralyse" },
  Jester = { "paralysis", "paralyse" }, Depthswalker = { "recklessness", "reckless" },
  Magi = { "haemophilia", "haemophilia" }, Serpent = { "weariness", "weariness" },
  Monk = { "weariness", "weariness" },
}
local function world()
  mock.reset()
  clock, sends, events, echoes, gmcpSent = 100, {}, {}, {}, {}
  ndb = {}
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
  -- By the target's class, as the real function reads it. This returned "paralyse" for every
  -- argument: no venom has that name, so the Occultist's "curare curare" could not show here. A
  -- class with no row gets the real function's no-NDB answer.
  getLockingAffliction = function(kind)
    local row = LOCK_AFF[ndb[target]]
    if not row then return "paralyse" end
    return kind == "name" and row[1] or row[2]
  end
  -- The target's class, through the real gates (007_Pariah_things). Agathon defaults to an
  -- Occultist: in the skip list of ataxia_wantClumsiness and with no class venom, which is the
  -- venom order these tests were written for (they stubbed the gate to false until 2026-11-08).
  ndb.Agathon = "Occultist"
  ataxiaNDB_getClass = function(n) return ndb[n] or "Unknown" end
  ataxiaNDB = nil                                  -- realClasses() below sets the real one up
  ataxiaEcho, zgui, cecho = function() end, nil, function() end
  Algedonic.Echo = function(s) echoes[#echoes + 1] = s end
  ataxiaTemp, tAffs, affTimers = { tarAffTimers = {} }, {}, {}
  tBals = { tree = true, focus = true, timers = {} }
  ataxia.afflictions = {}
  ataxia.lightwall = nil
  ataxia.playersHere = { "Agathon" }
  ataxia.settings.serpentattackfirst = nil
  ataxia.settings.user = nil
  gmcp = { Char = { Vitals = { bal = "1" } } }
  Rebounding, Shielded, reboundHold, classDetect, tarClass = false, false, nil, nil, nil
  hypSeal2, snapped, tpinshot = nil, nil, nil
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
  s.geckoStripAttempted, s.postGeckoLockdown, s.lastRebounding = false, false, false
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
    -- The target's class from the NDB, or from classDetect when the attacker it names is the
    -- target. (This read the global tarClass, which nothing in the package assigns.)
    for _, by in ipairs({ "ndb", "classDetect" }) do
      for _, mode in ipairs({ "lock", "group" }) do
        for _, b in ipairs(boards) do
          world()
          serpOffenseMode = mode
          if by == "ndb" then ndb.Agathon = "Depthswalker"
          else
            ndb.Agathon = nil
            classDetect = { state = { attackerClass = "Depthswalker", attackerName = "Agathon" } }
          end
          expect(ataxia_targetClass()).toBe("depthswalker")
          -- The whole board: `a and f() or g()` kept one value, so only b[1] was ever given.
          give((table.unpack or unpack)(b))
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
    world(); ndb.Agathon = "Depthswalker"
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
      world(); serpOffenseMode = mode; ndb.Agathon = "Depthswalker"
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
    world(); ndb.Agathon = "Depthswalker"
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

  -- The strip line itself starts the clock (2026-11-08 review, F30), so the round after it does not
  -- stamp it again.
  it("the strip line arms it, once", function()
    world(); Rebounding = true
    round()
    line(REB_STRIPPED, "You flay away Agathon's aura of rebounding defence.", "Agathon")
    expect(lastReboundingFlay).toBe(100)
    expect(serpent.state.reboundingSeen).toBeFalse()
    Rebounding = false
    clock = 101
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
          if #b > 0 then give((table.unpack or unpack)(b)) end
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
    stepThenAttack(round(), "seal Agathon 3")   -- 3 s, the wiki's minimum (F28)

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

-- =================================================================================================
-- The review of these fixes (2026-11-08): venom and impulse selection.
-- =================================================================================================

local ENGINE = "src_new/scripts/levi_ataxia/levi/levi_scripts/class_detect/001_Class_Detect_Engine.lua"
local NDB_API = "src_new/scripts/levi_ataxia/levi/ataxia/ataxia_ndb/003_ataxiaNDB_API.lua"
local SNAKE_BITE = "src_new/triggers/levi_ataxia/for_levi/leviticus/serpent/024_Snake_Bite_Fratricide.lua"
local KELP = "src_new/triggers/levi_ataxia/for_levi/leviticus/herbs/003_Kelp_(Unknown).lua"
local function body(path)
  return assert((loadstring or load)(read(path):match("%]%]%-%-\r?\n(.*)$")), path)
end

-- The target's class as the package keeps it: the REAL NDB API over `players`, and the REAL
-- class-detect engine (its "changed target" lookup and its class-line entry point).
local function realClasses(players)
  ataxiaNDB = { players = players }
  dofile(NDB_API)
  classDetect = nil
  dofile(ENGINE)
  classDetect.config.apiLookupEnabled = false   -- no download for a name the NDB lacks
end

local function dstabOf(r)
  local p = pieces(r)
  return p[#p]
end

describe("review: a press with no NDB to read (003's ataxiaNDB_Exists)", function()
  -- A load that throws leaves ataxiaNDB nil on purpose (001_Save_Load_Settings, test_settings.lua);
  -- an empty file gives a table with no players. The real API, and no class to read.
  for _, c in ipairs({ { "nil", nil }, { "with no players", {} } }) do
    it("ataxiaNDB " .. c[1] .. ": the round still goes out, clumsiness kept", function()
      world()
      dofile(NDB_API)                              -- the real ataxiaNDB_getClass, over world()'s stub
      ataxiaNDB = c[2]
      expect(ataxiaNDB_getClass("Agathon")).toBe("Unknown")
      expect(ataxia_targetClass()).toBe("")
      expect(has(round(), "dstab Agathon curare xentio")).toBeTrue()
    end)
  end

  it("ataxiaNDB with an empty players table reads the same (the control)", function()
    world()
    dofile(NDB_API)
    ataxiaNDB = { players = {} }
    expect(ataxia_targetClass()).toBe("")
    expect(has(round(), "dstab Agathon curare xentio")).toBeTrue()
  end)
end)

describe("review: the class gates read our TARGET's class", function()
  it("ataxia_wantClumsiness reads the target's class, in any case", function()
    world()
    ndb.Agathon = "Magi"
    expect(ataxia_targetClass()).toBe("magi")
    expect(ataxia_wantClumsiness()).toBeFalse()
    expect(ataxia_wantClumsiness("Sylvan")).toBeFalse()
    ndb.Agathon = "Serpent"
    expect(ataxia_wantClumsiness()).toBeTrue()
    ndb.Agathon = nil                              -- "Unknown": no entry keeps clumsiness
    expect(ataxia_targetClass()).toBe("")
    expect(ataxia_wantClumsiness()).toBeTrue()
  end)

  -- tarClass, the gate's only source until now, was never assigned, so a Magi got xentio first.
  it("a Magi target gets the asthma order, not xentio", function()
    world(); ndb.Agathon = "Magi"
    give("paralysis", "haemophilia")
    expect(dstabOf(round())).toBe("dstab Agathon kalmia vernalius")
    -- The same through classDetect, when the attacker it names is the target.
    world(); ndb.Agathon = nil
    classDetect = { state = { attackerClass = "Magi", attackerName = "Agathon" } }
    give("paralysis", "haemophilia")
    expect(dstabOf(round())).toBe("dstab Agathon kalmia vernalius")
  end)

  it("a class outside the list keeps xentio first", function()
    world(); ndb.Agathon = "Serpent"
    give("paralysis", "haemophilia")
    expect(dstabOf(round())).toBe("dstab Agathon xentio kalmia")
  end)

  it("a bystander's class line does not change our target's class venom", function()
    world()
    realClasses({ Agathon = { class = "Magi" } })
    classDetect.onTargetChanged()
    give("paralysis")
    expect(has(round(), "notechis")).toBeTrue()
    classDetect.setAttackerClass("Bystander", "Monk")   -- one class line from someone else
    expect(classDetect.state.attackerClass).toBe("Monk")
    local r = round()
    expect(has(r, "notechis")).toBeTrue()
    expect(has(r, "vernalius")).toBeFalse()
    -- The target hits us too: two attackers, so the engine holds no one's class, and the NDB (which
    -- each class line wrote) still gives the target's.
    classDetect.setAttackerClass("Agathon", "Magi")
    expect(classDetect.state.attackerClass).toBeNil()
    expect(has(round(), "notechis")).toBeTrue()
  end)

  it("a new target the NDB lacks does not inherit the last target's class venom", function()
    world()
    realClasses({ Agathon = { class = "Magi" } })
    classDetect.onTargetChanged()
    target, ataxia.playersHere = "Newguy", { "Newguy" }
    classDetect.onTargetChanged()                   -- not cached: attackerClass stays "Magi"
    expect(classDetect.state.attackerClass).toBe("Magi")
    give("paralysis")
    expect(has(round(), "notechis")).toBeFalse()
  end)
end)

describe("review: group mode counts the first venom's slickness", function()
  it("gecko then slike under impatience + asthma, not a second curare", function()
    world(); serpOffenseMode = "group"
    give("paralysis", "asthma", "weariness", "impatience")
    expect(dstabOf(round())).toBe("dstab Agathon gecko slike")
  end)

  it("with slickness already up: slike, then curare, as before", function()
    world(); serpOffenseMode = "group"
    give("paralysis", "asthma", "weariness", "impatience", "slickness")
    expect(dstabOf(round())).toBe("dstab Agathon slike curare")
  end)
end)

describe("review: the monkshood impulse always carries masochism", function()
  it("PRIORITY 4 with masochism believed up", function()
    world(); give("asthma", "weariness", "masochism", "slickness")
    expect(has(round(), "impulse Agathon masochism monkshood")).toBeTrue()
  end)

  it("the group pair with every condition met", function()
    world(); serpOffenseMode = "group"
    give("asthma", "masochism", "weariness", "paralysis")
    expect(has(round(), "impulse Agathon masochism monkshood")).toBeTrue()
  end)

  it("selectImpulsePair gives masochism with monkshood; another reaction keeps its filler", function()
    world(); give("asthma", "weariness", "masochism")
    local pair = selectImpulsePair()
    expect(pair.venom).toBe("monkshood")
    expect(pair.suggestion).toBe("masochism")
    world(); give("clumsiness", "weariness")
    pair = selectImpulsePair()
    expect(pair.venom).toBe("kalmia")
    expect(pair.suggestion).toBe("confusion")
  end)

  it("the rebounding pre-empt (PRIORITY 1.5) when its bite is the monkshood reaction", function()
    world(); give("asthma", "weariness", "masochism", "paralysis")
    lastReboundingFlay = clock - 9
    expect(has(round(), "impulse Agathon masochism monkshood")).toBeTrue()
    expect(lastReboundingFlay).toBe(0)
  end)

  it("the pre-empt with any other bite keeps its own suggestion", function()
    world(); give("paralysis", "asthma")
    lastReboundingFlay = clock - 9
    expect(has(round(), "impulse Agathon confusion vernalius")).toBeTrue()
  end)

  it("the keybind suggestion does not replace it", function()
    world(); hSuggRequest = "stupidity"
    give("asthma", "weariness", "masochism")
    local r = round()
    expect(has(r, "impulse Agathon masochism monkshood")).toBeTrue()
    expect(has(r, "impulse Agathon stupidity")).toBeFalse()
  end)
end)

describe("review: no impulse on a reaction that gives nothing new", function()
  it("group: no loki over nausea + paralysis already up; the DSTAB goes instead", function()
    world(); serpOffenseMode = "group"
    give("anorexia", "asthma", "slickness", "paralysis", "nausea", "confusion")
    local r = round()
    expect(has(r, "loki")).toBeFalse()
    expect(dstabOf(r)).toBe("dstab Agathon vernalius curare")
  end)

  it("group: no aconite over stupidity + paranoia already up", function()
    world(); serpOffenseMode = "group"
    give("dementia", "stupidity", "paranoia", "paralysis")
    local r = round()
    expect(has(r, "aconite")).toBeFalse()
    expect(dstabOf(r)).toBe("dstab Agathon kalmia vernalius")
  end)

  it("a reaction with something left to give still goes", function()
    world(); serpOffenseMode = "group"; give("dementia")
    expect(has(round(), "impulse Agathon deadening aconite")).toBeTrue()
    -- The loki pair of fix 1, on a locked target with paralysis and nausea still to give.
    world(); give("confusion", "anorexia", "asthma", "slickness")
    expect(selectImpulsePair().venom).toBe("loki")
  end)
end)

describe("review: the relapse stupidity impulse waits for stupidity to be gone", function()
  it("stupidity up: the relapse DSTAB, and the impulse stays unspent", function()
    world(); serpent.state.impatienceDelivered = true
    give("paralysis", "weariness", "stupidity")
    local r = round()
    expect(has(r, "impulse")).toBeFalse()
    expect(dstabOf(r)).toBe("dstab Agathon kalmia slike")
    expect(serpent.state.stupidityImpulseSent).toBeFalse()
    erAff("stupidity")
    clock = 102
    expect(has(round(), "impulse Agathon stupidity kalmia")).toBeTrue()
    expect(serpent.state.stupidityImpulseSent).toBeTrue()
  end)
end)

describe("review: a lightwall in the room brings darkshade", function()
  local function venoms()
    serpStrategy = "setup_lock"
    selectVenoms()
    return envenomList[1] .. " " .. envenomListTwo[1]
  end

  it("ataxia.lightwall, the room flag, is what the rule reads", function()
    world(); give("paralysis", "asthma", "weariness")
    expect(venoms()).toBe("gecko curare")
    ataxia.lightwall = true
    expect(venoms()).toBe("darkshade gecko")
    give("darkshade")
    expect(venoms()).toBe("gecko curare")
  end)
end)

-- canShrug and serpent.state.shouldShrug were read and never assigned, so the offence's own
-- shrug path could not run. It is gone; ataxia_lockBreak (can(x)/003) sends our SHRUGGING.
describe("review: the offence has no shrug of its own", function()
  it("a round never carries shrugging, even with the old flags up", function()
    world(); give("paralysis", "asthma", "weariness")
    ataxia.afflictions = { stupidity = true, confusion = true, dizziness = true }
    canShrug, serpent.state.shouldShrug = true, true
    local r = round()
    canShrug, serpent.state.shouldShrug = nil, nil
    expect(has(r, "shrugging")).toBeFalse()
  end)
end)

describe("review: the focus lock push counts pacified as a mental affliction", function()
  local function upToThreeMentals()
    world()
    give("fratricide", "impatience", "asthma", "weariness", "stupidity", "masochism", "vertigo")
    tBals.focus = false
  end

  it("three mentals are not enough for the push", function()
    upToThreeMentals()
    expect(has(round(), "monkshood")).toBeFalse()
  end)

  it("pacified, the tracker's name, is the fourth", function()
    upToThreeMentals(); give("pacified")
    expect(has(round(), "impulse Agathon confusion monkshood")).toBeTrue()
  end)
end)

describe("review: the pet snake's bite records fratricide", function()
  local ADDER = "A death adder sinks its fangs into the neck of Xylarys, injecting a potent dose of toxin."
  -- kb/raw/logs/2026-10-19_tabethys_magi-group_kalys_o6UKnyyy.txt:218-219, one line since
  -- CONFIG SCREENWIDTH 0.
  local RATTLER = "A small grey-brown rattlesnake sinks its fangs into the neck of Valkael, "
    .. "injecting a potent dose of toxin."
  local function line(text, who)
    assert(TL.anyMatches(TL.patterns(SNAKE_BITE), text), "024's pattern does not take: " .. text)
    matches = { text, who }
    body(SNAKE_BITE)()
  end
  local function aimAt(who)
    target, ataxia.playersHere = who, { who }
  end

  it("the death adder's line (Froedine.log:2009) on our target", function()
    world(); aimAt("Xylarys")
    expect(haveAff("fratricide")).toBeFalse()
    line(ADDER, "Xylarys")
    expect(haveAff("fratricide")).toBeTrue()
  end)

  it("another snake's name takes too", function()
    world(); aimAt("Valkael")
    line(RATTLER, "Valkael")
    expect(haveAff("fratricide")).toBeTrue()
  end)

  it("a bite on someone else records nothing", function()
    world(); aimAt("Xylarys")
    line("A death adder sinks its fangs into the neck of Grulk, injecting a potent dose of toxin.", "Grulk")
    expect(haveAff("fratricide")).toBeFalse()
  end)

  it("the fang-barrier refusal and the victim's own line are not the bite", function()
    local pats = TL.patterns(SNAKE_BITE)
    -- kb/raw/logs/ours/2026-11-03_081009_Froedine.log:897
    expect(TL.anyMatches(pats, "A death adder lunges for the throat of Xylarys, fangs sinking into his fang"
      .. " barrier defence.")).toBeFalse()
    -- kb/raw/logs/2026-11-01_nikita_depthswalker-vs-serpent_win_X8pRorzR.txt:235-236
    expect(TL.anyMatches(pats, "A small grey-brown rattlesnake sinks its fangs into your neck and injects a"
      .. " potent dose of toxin.")).toBeFalse()
  end)

  it("the offence reads it: the focus-lock push goes after the bite", function()
    world(); aimAt("Xylarys")
    give("impatience", "asthma", "weariness", "stupidity", "masochism", "recklessness", "vertigo")
    tBals.focus = false
    expect(has(round(), "impulse")).toBeFalse()
    line(ADDER, "Xylarys")
    clock = 102
    expect(has(round(), "impulse Xylarys confusion monkshood")).toBeTrue()
  end)
end)

describe("review: the target's kelp eats reach the adaptive count", function()
  it("each kelp or aurum eat by the target counts once; someone else's does not", function()
    world()
    local savedFg = fg
    fg = function() end
    local fine, e = pcall(function()
      -- Saibel's eat at kb/raw/logs/ours/2026-11-07_164635_Saibel.log:1373, on our target's name.
      for i = 1, 5 do
        clock = 100 + 0.4 * i
        matches = { "Agathon eats an aurum flake.", "Agathon", "an aurum flake" }
        body(KELP)()
      end
      matches = { "Grulk eats a piece of kelp.", "Grulk", "a piece of kelp" }
      body(KELP)()
    end)
    fg = savedFg
    if not fine then error(e, 0) end
    expect(serpent.cureTracking.kelpCures).toBe(5)
    local out = {}
    cecho = function(s) out[#out + 1] = s end
    serp_status()
    expect(has(table.concat(out), "Kelp Cures: <yellow>5")).toBeTrue()
  end)
end)

-- =============================================================================
-- The second review of the offence (2026-11-08, round A2): F0, F8, F10, F29-F37, X6.
-- =============================================================================

local DSTAB = "src_new/triggers/levi_ataxia/for_levi/leviticus/serpent/001_Doublestab.lua"
local PINSHOT = "src_new/triggers/levi_ataxia/for_levi/leviticus/serpent/002_Pinshot.lua"
local SN = "src_new/aliases/levi_ataxia/for_levi/levi_062424/serpent/001_Darkshade.lua"
local GRAB = "src_new/triggers/levi_ataxia/for_levi/leviticus/determine_class/002_Serpent_Class_Grab.lua"

local function vitals(bal)
  gmcp.Char.Vitals.bal = bal
  for _, h in ipairs(VITALS) do h("gmcp.Char.Vitals") end
end

describe("F0: a round the game refused does not stop the offence", function()
  it("002 registers one balance handler", function()
    expect(#VITALS).toBe(1)
  end)

  -- "You are paralysed and cannot do that." with the balance flag still up
  -- (kb/raw/logs/ours/2026-10-27_135412_Tabethys.log:4920-4924): no 0 -> 1 edge ever came, and every
  -- later press returned at the attackInFlight guard.
  it("a round that spent no balance is sent again after 1.5 s", function()
    world(); serpent.state.lastBalState = "1"
    serp_ekanelia_offense()
    expect(#sends).toBe(1)
    vitals("1")                                  -- the prompt after the refusal: still on balance
    clock = clock + 2
    sends = {}
    serp_ekanelia_offense()
    expect(#sends).toBe(1)
    local said = false
    for _, e in ipairs(echoes) do if has(e, "spent no balance") then said = true end end
    expect(said).toBeTrue()
  end)

  it("a second press inside the window still sends nothing", function()
    world(); serpent.state.lastBalState = "1"
    serp_ekanelia_offense()
    clock = clock + 0.3
    sends = {}
    serp_ekanelia_offense()
    expect(#sends).toBe(0)
  end)

  it("a round that spent balance waits for the recovery, as before", function()
    world(); serpent.state.lastBalState = "1"
    serp_ekanelia_offense()
    vitals("0")
    expect(serpent.state.balSpentSinceSend).toBeTrue()
    gmcp.Char.Vitals.bal = "1"                   -- read before the recovery's own event ran
    clock = clock + 2
    sends = {}
    serp_ekanelia_offense()
    expect(#sends).toBe(0)
    vitals("1")
    expect(serpent.state.attackInFlight).toBeFalse()
    serp_ekanelia_offense()
    expect(#sends).toBe(1)
    expect(serpent.state.balSpentSinceSend).toBeFalse()
  end)

  -- Slowed, a command waits with balance up and a new send replaces it and restarts its delay
  -- (kb/mechanics/balance-and-queueing.md, "Retardation"), so the release waits for the slow to end.
  it("while slowed the guard holds, and the press after the slow sends", function()
    world(); serpent.state.lastBalState = "1"
    serp_ekanelia_offense()
    expect(#sends).toBe(1)
    ataxia.afflictions.aeon = true
    vitals("1")
    clock = clock + 2
    sends = {}
    serp_ekanelia_offense()
    expect(#sends).toBe(0)
    ataxia.afflictions.aeon = nil
    serp_ekanelia_offense()
    expect(#sends).toBe(1)
  end)
end)

describe("F8/X5: below truelock lock_reinforce sends the curare DSTAB, not the voyria impulse", function()
  -- Hardlock in the relapse phase: the second monkshood landed, paralysis is not up.
  local function hardlock()
    world()
    serpent.state.impatienceDelivered = true
    give("asthma", "slickness", "anorexia", "impatience", "weariness", "clumsiness", "masochism")
  end

  it("no paralysis: a DSTAB with curare, and no impulse", function()
    hardlock()
    local r = round()
    expect(serpStrategy).toBe("lock_reinforce")
    expect(has(r, "impulse")).toBeFalse()
    expect(has(r, "dstab Agathon curare voyria")).toBeTrue()
  end)

  -- A paralysis at 0.75 (a quarter of the branches lost it, an unseen cure for example): haveAff's
  -- 0.30 reads it up, truelock's 0.90 does not. The voyria impulse went every round here.
  it("a doubtful paralysis (under 0.90) gets curare again, not the impulse", function()
    hardlock(); give("paralysis")
    local keep = afflictionStatesV3[1]
    local lost = { affs = {}, prob = keep.prob / 4 }
    for k, v in pairs(keep.affs) do lost.affs[k] = v end
    lost.affs.paralysis = nil
    keep.prob = keep.prob * 3 / 4
    afflictionStatesV3[#afflictionStatesV3 + 1] = lost
    rebuildCacheV3()
    syncToOldSystemV3()
    expect(getAffProbabilityV3("paralysis")).toBe(0.75)
    expect(haveAff("paralysis")).toBeTrue()
    local r = round()
    expect(serpStrategy).toBe("lock_reinforce")
    expect(has(r, "impulse")).toBeFalse()
    expect(has(r, "dstab Agathon curare voyria")).toBeTrue()
  end)

  it("at truelock the voyria impulse goes once, then the finish", function()
    hardlock(); give("paralysis")
    expect(has(round(), "impulse Agathon vertigo voyria")).toBeTrue()
    expect(serpent.state.voyriaSent).toBeTrue()
    clock = 102
    local r = round()
    expect(serpStrategy).toBe("finish")
    expect(has(r, "execute")).toBeFalse()        -- standing: no finisher (F10)
  end)
end)

describe("F10: execute only a prone target, with the whip", function()
  local function truelocked()
    world()
    serpent.state.voyriaSent = true
    give("anorexia", "asthma", "slickness", "impatience", "paralysis")
  end

  it("a standing truelocked target gets no execute and no behead", function()
    truelocked()
    local r = round()
    expect(has(r, "execute")).toBeFalse()
    expect(has(r, "behead")).toBeFalse()
  end)

  it("prone: the whip, then execute", function()
    for _, first in ipairs({ false, true }) do
      truelocked(); give("prone")
      ataxia.settings.serpentattackfirst = first
      hands({ ["111"] = SHIELD, ["555"] = "a curved dirk" })
      local r = round()
      expect(has(r, "behead")).toBeFalse()
      local p = pieces(r)
      local at
      for i, x in ipairs(p) do if x == "execute Agathon" then at = i end end
      expect(at ~= nil).toBeTrue()
      expect((p[at - 1]:gsub("^queue addclear freestand ", ""))).toBe("wield shield whip")
    end
  end)

  it("prone but under truelock: no execute", function()
    world(); serpent.state.voyriaSent = true
    give("anorexia", "asthma", "slickness", "impatience", "prone")
    expect(has(round(), "execute")).toBeFalse()
  end)
end)

describe("F29: the suggestion success line records what our round suggested", function()
  local LINE = "You issue the suggestion, concealing it deep within Agathon's mind."
  local function given()
    assert(SUGGEST_GIVEN, "002's suggest trigger was not captured at load")
    assert(TL.matches(SUGGEST_GIVEN.pattern, 1, LINE), "002's pattern no longer takes: " .. LINE)
    matches = { LINE, "Agathon" }
    assert((loadstring or load)(SUGGEST_GIVEN.callback))()
  end

  -- In the default order the round's queued piece is purge (or dispel, Saibel.log:225), so the
  -- suggest goes raw and queue_Scan never sets ataxiaTemp.suggestAff.
  it("the fratricide suggest is recorded, and not sent again", function()
    world()
    serpent.hypnosis.onHypnotised()
    expect(has(round(), "suggest Agathon fratricide")).toBeTrue()
    ataxiaTemp.suggestAff = nil
    given()
    expect(serpent.hypnosis.fratricideApplied).toBeTrue()
    expect(serpent.hypnosis.suggestions[1]).toBe("fratricide")
    clock = 102
    expect(has(round(), "suggest")).toBeFalse()
  end)

  it("a stale queued suggestion does not stand in for the lock chain's", function()
    world()
    serpent.hypnosis.mode = "lock"
    serpent.hypnosis.targetSuggestions = { "hypochondria", "disrupt" }
    serpent.hypnosis.onHypnotised()
    expect(has(round(), "suggest Agathon hypochondria")).toBeTrue()
    ataxiaTemp.suggestAff = "fratricide"
    given()
    expect(serpent.hypnosis.fratricideApplied).toBeFalse()
    expect(serpent.hypnosis.suggestions[1]).toBe("hypochondria")
    serpent.hypnosis.mode = "fratricide"
  end)

  -- The last chain's suggest never got its success line; a hand-typed suggest in the next chain
  -- must not be recorded as that word (fratricideApplied would end the chain's own suggest).
  it("a new chain starts with no word left over from the last one", function()
    world()
    serpent.hypnosis.pendingSuggestion = "fratricide"
    serpent.hypnosis.start("Agathon")
    expect(serpent.hypnosis.pendingSuggestion).toBeNil()
    given()
    expect(serpent.hypnosis.fratricideApplied).toBeFalse()
  end)
end)

describe("F30: the strip line starts the rebounding reapply clock", function()
  -- Saibel.log: the flay's rebounding line at 16:47:22.414 (:305), the next round at 23.986 (:333).
  it("the pre-empt fires 8.15 s after the strip, not after the next round", function()
    world(); Rebounding = true
    clock = 98.8
    round()
    clock = 100.18
    matches = { "You flay away Agathon's aura of rebounding defence.", "Agathon" }
    assert((loadstring or load)(REB_STRIPPED.callback))()
    Rebounding = false
    clock = 101.71
    round()
    expect(lastReboundingFlay).toBe(100.18)
    clock = 108.40
    expect(has(round(), "impulse Agathon")).toBeTrue()
  end)
end)

describe("F31: the flay's venom while the kalmia reaction waits adds an affliction", function()
  it("shield, clumsiness + weariness + paralysis: slike, not vernalius", function()
    for _, mode in ipairs({ "lock", "group" }) do
      world(); serpOffenseMode = mode; Shielded = true
      give("clumsiness", "weariness", "paralysis")
      local r = round()
      expect(has(r, "flay Agathon shield slike")).toBeTrue()
      expect(has(r, "vernalius")).toBeFalse()
    end
  end)

  it("rebounding: the same", function()
    world(); Rebounding = true
    give("clumsiness", "weariness", "paralysis")
    expect(has(round(), "flay Agathon rebounding slike")).toBeTrue()
  end)

  it("never asthma, and the next missing one when anorexia is up", function()
    world(); Shielded = true
    give("clumsiness", "weariness", "paralysis", "anorexia")
    local r = round()
    expect(has(r, "flay Agathon shield euphorbia")).toBeTrue()
    expect(has(r, "kalmia")).toBeFalse()
  end)

  it("no paralysis: curare, as before", function()
    world(); Shielded = true
    give("clumsiness", "weariness")
    expect(has(round(), "flay Agathon shield curare")).toBeTrue()
  end)
end)

describe("F32: the rebounding pre-empt waits for a hypnosis step", function()
  it("hypnotised: the suggest goes, no impulse, and the clock stays armed", function()
    world()
    serpent.hypnosis.mode, serpent.hypnosis.phase = "fratricide", "hypnotised"
    lastReboundingFlay = clock - 9
    local r = round()
    expect(has(r, "suggest Agathon fratricide")).toBeTrue()
    expect(has(r, "impulse")).toBeFalse()
    expect(lastReboundingFlay).toBe(91)
  end)

  it("sealed: the snap goes, no impulse", function()
    world()
    serpent.hypnosis.mode, serpent.hypnosis.phase = "lock", "suggesting"
    serpent.hypnosis.targetSuggestions, serpent.hypnosis.suggestions = { "stupidity" }, { "stupidity" }
    serpent.hypnosis.sealed = true
    lastReboundingFlay = clock - 9
    local r = round()
    expect(has(r, "snap Agathon")).toBeTrue()
    expect(has(r, "impulse")).toBeFalse()
    serpent.hypnosis.mode = "fratricide"
  end)

  it("with no step due it still fires", function()
    world()
    lastReboundingFlay = clock - 9
    expect(has(round(), "impulse Agathon")).toBeTrue()
    expect(lastReboundingFlay).toBe(0)
  end)
end)

describe("F33: the pinshot is in one person", function()
  local function pinned(who)
    local line = "Your arrow slams into the foot of " .. who .. "."
    assert(TL.anyMatches(TL.patterns(PINSHOT), line), "the pinshot pattern no longer takes: " .. line)
    matches = { line, who }
    local savedBox = ataxia_boxEcho
    ataxia_boxEcho = function() end
    local fine, e = pcall(body(PINSHOT))
    ataxia_boxEcho = savedBox
    if not fine then error(e, 0) end
  end
  local function pinTimers()
    local n = 0
    for _, t in pairs(mock.active_timers) do
      if t.delay == 21 and type(t.callback) == "string" and has(t.callback, "tpinshot") then n = n + 1 end
    end
    return n
  end

  it("a new target within 21 s gets its own pinshot", function()
    world(); tpinshotTimer = nil
    serpent.state.firstAttack, serpent.state.dispelSent = true, false
    pinned("Agathon")
    expect(tpinshot).toBe("Agathon")
    retarget("Claes")
    expect(has(round(), "pinshot Claes foot")).toBeTrue()
  end)

  it("the pinned target is not pinned again within its 21 s", function()
    world(); tpinshotTimer = nil
    serpent.state.firstAttack, serpent.state.dispelSent = true, false
    pinned("Agathon")
    expect(has(round(), "pinshot")).toBeFalse()
  end)

  it("two pins leave one clear timer", function()
    world(); tpinshotTimer = nil
    pinned("Agathon")
    pinned("Claes")
    expect(pinTimers()).toBe(1)
    expect(tpinshot).toBe("Claes")
    tpinshotTimer = nil
  end)
end)

describe("F34: sn runs the darkshade offence", function()
  it("the alias calls functions that exist", function()
    world(); serpOffenseMode = "lock"
    local savedOffense, ran = serp_ekanelia_offense, 0
    serp_ekanelia_offense = function() ran = ran + 1 end
    local fine, e = pcall(body(SN))
    serp_ekanelia_offense = savedOffense
    if not fine then error(e, 0) end
    expect(serpOffenseMode).toBe("darkshade")
    expect(ran).toBe(1)
  end)
end)

describe("F35: a part name is completed before the round", function()
  -- A round with 016's real isTargeted and updateTarget in place.
  local function round016()
    local savedIs, savedUpdate = isTargeted, updateTarget
    isTargeted, updateTarget = realIsTargeted, realUpdateTarget
    local fine, r = pcall(round)
    isTargeted, updateTarget = savedIs, savedUpdate
    if not fine then error(r, 0) end
    return r
  end
  local function refused()
    for _, e in ipairs(echoes) do if has(e, "Target not in room!") then return true end end
    return false
  end

  it("without 016: the one listed name that starts with it becomes the target", function()
    world()
    target, ataxia.playersHere = "Sai", { "Saibel" }
    local savedIs, savedUpdate = isTargeted, updateTarget
    isTargeted, updateTarget = nil, nil          -- 016 not loaded: the plain assignment
    local fine, r = pcall(round)
    isTargeted, updateTarget = savedIs, savedUpdate
    if not fine then error(r, 0) end
    expect(target).toBe("Saibel")
    expect(has(r, "dstab Saibel")).toBeTrue()
  end)

  it("016's isTargeted completes a part name, and the round names her in full", function()
    world()
    target, ataxia.playersHere = "sai", { "Saibel" }
    local r = round016()
    expect(target).toBe("Saibel")
    expect(has(r, "dstab Saibel")).toBeTrue()
  end)

  it("a full name a line has named, gone from the room, is not renamed to a longer one", function()
    world()
    target, ataxia.playersHere = "Kai", { "Kai" }
    expect(realIsTargeted("Kai")).toBeTrue()     -- a line about her: 016 now holds "kai" as full
    ataxia.playersHere = { "Kaiden" }
    expect(round016()).toBe("")
    expect(target).toBe("Kai")
    expect(refused()).toBeTrue()
  end)

  it("the same name in another case is respelt, and then counts as a full name", function()
    world()
    target, ataxia.playersHere = "saibel", { "Saibel" }
    expect(has(round016(), "dstab Saibel")).toBeTrue()
    expect(target).toBe("Saibel")
    ataxia.playersHere = { "Saibeline" }         -- she leaves; a longer name is someone else
    expect(round016()).toBe("")
    expect(target).toBe("Saibel")
  end)

  it("two names that start with it: nothing is sent", function()
    world()
    target, ataxia.playersHere = "Sai", { "Saibel", "Saidra" }
    expect(round()).toBe("")
    expect(target).toBe("Sai")
  end)
end)

describe("F36: a reflection on prick 1 still credits prick 2", function()
  local PRICK = "You quickly prick Agathon with your dirk."
  local BLINK = "A reflection of Agathon blinks out of existence."
  local SECOND = "Striking like a snake, you prick Agathon a second time with your dirk."
  local VTA = { curare = "paralysis", xentio = "clumsiness", kalmia = "asthma" }
  local queued

  local function stab(next1)
    queued = {}
    local saved = { tempLineTrigger, venom_to_aff }
    tempLineTrigger = function(_, _, f) queued[#queued + 1] = f; return #queued end
    venom_to_aff = function(v) return VTA[v] end
    envenomList, envenomListTwo = { "curare" }, { "xentio" }
    assert(TL.matches(TL.patterns(DSTAB)[1].pat, 1, PRICK), "the prick pattern no longer takes")
    multimatches = { { PRICK, "Agathon" }, { "" }, { next1 } }
    local fine, e = pcall(body(DSTAB))
    tempLineTrigger, venom_to_aff = saved[1], saved[2]
    if not fine then error(e, 0) end
  end
  local function nextLine(text)
    line = text
    local f = table.remove(queued, 1)
    local savedTLT = tempLineTrigger
    tempLineTrigger = function(_, _, g) queued[#queued + 1] = g; return #queued end
    local fine, e = pcall(f)
    tempLineTrigger = savedTLT
    if not fine then error(e, 0) end
  end

  it("prick 2 lands the top venom (xentio here, the second named)", function()
    world()
    stab(BLINK)
    expect(haveAff("clumsiness")).toBeFalse()   -- not before prick 2's own line
    nextLine(SECOND)
    nextLine("Balance used: 1.8s.")             -- Saibel.log:458, the line after prick 2's
    expect(haveAff("clumsiness")).toBeTrue()
    expect(haveAff("paralysis")).toBeFalse()
    expect(#envenomList).toBe(0)
  end)

  it("prick 2 rebounding records the rebounding, not the venom", function()
    world()
    stab(BLINK)
    nextLine(SECOND)
    nextLine("The attack rebounds back onto you!")
    expect(haveAff("clumsiness")).toBeFalse()
    expect(haveAff("rebounding")).toBeTrue()
  end)

  it("a second reflection takes prick 2: nothing", function()
    world()
    stab(BLINK)
    nextLine(SECOND)
    nextLine(BLINK)
    expect(haveAff("clumsiness")).toBeFalse()
  end)

  it("no second prick line: nothing", function()
    world()
    stab(BLINK)
    nextLine("Agathon takes a drink from a vial.")
    expect(#queued).toBe(0)
    expect(haveAff("clumsiness")).toBeFalse()
  end)
end)

describe("F37: the Serpent class lines are the game's", function()
  local pats = TL.patterns(GRAB)
  it("the real lines take", function()
    for _, l in ipairs({
      "Thato sinks her fangs into your body and you wince in pain.",   -- azbErKcK.txt:1242
      "Thato fixes her gaze to yours and hisses a sharp command.",      -- azbErKcK.txt:1238
      "Kalys flays away your shield defence.",                         -- g-lD00-h.txt:37
      "Thato flays away your aura of rebounding defence.",              -- azbErKcK.txt:89
      "Thato snaps her fingers in front of you.",                       -- azbErKcK.txt:275
      "Archaeon quickly pricks you with his dirk.",                     -- X8pRorzR.txt:49
    }) do
      expect(TL.anyMatches(pats, l)).toBeTrue()
    end
  end)

  it("a Pariah's gaze and a pet snake's bite do not", function()
    expect(TL.anyMatches(pats,
      "Talo fixes his gaze to yours, raising his right hand, before sharply snapping his fingers.")).toBeFalse()
    expect(TL.anyMatches(pats,
      "An emerald tree snake sinks its fangs into your neck and injects a potent dose of toxin.")).toBeFalse()
  end)

  it("the body names the Serpent", function()
    local savedCD, got = classDetect, nil
    classDetect = { setAttackerClass = function(n, c) got = n .. ":" .. c end }
    matches = { "Kalys flays away your shield defence.", "Kalys" }
    local fine, e = pcall(body(GRAB))
    classDetect = savedCD
    if not fine then error(e, 0) end
    expect(got).toBe("Kalys:Serpent")
  end)
end)

-- Integration round 1 of the deep review (2026-11-08).
describe("a lock piece a branched cure left at 0.667 is sent again, at the lock's own bar", function()
  local function P(a) return getAffProbabilityV3(a) end
  local function near(got, want, what)
    if math.abs(got - want) > 1e-9 then
      error(string.format("%s: expected %.6f but got %.6f", what, want, got), 2)
    end
  end
  -- A lock short only of anorexia, on which an eat branches.
  local function board(mode, delivered, ...)
    world()
    serpOffenseMode = mode
    serpent.state.impatienceDelivered = delivered
    give("paralysis", "asthma", "slickness", "weariness", "masochism", "impatience", ...)
  end
  local LANDS = { curare = "paralysis", kalmia = "asthma", gecko = "slickness", slike = "anorexia",
    vernalius = "weariness", voyria = "voyria" }
  -- n rounds whose venoms land, and whose monkshood bite reacts.
  local function rounds(n)
    local seen = {}
    for i = 1, n do
      clock = clock + 2.4
      local r = round()
      seen[i] = r
      local a, b = r:match("dstab Agathon (%S+) (%S+)")
      if a then
        if LANDS[a] then give(LANDS[a]) end
        if LANDS[b] then give(LANDS[b]) end
      end
      local sug, venom = r:match("impulse Agathon (%S+) (%S+)")
      if sug then
        give(sug)
        if LANDS[venom] then give(LANDS[venom]) end
        if venom == "monkshood" then give("impatience") end
      end
    end
    return seen
  end
  local function anyHas(seen, needle)
    for _, r in ipairs(seen) do if has(r, needle) then return true end end
    return false
  end

  -- "Saibel eats an aurum flake." kb/raw/logs/ours/2026-11-07_164635_Saibel.log:2054
  it("kelp over weariness + asthma: kalmia goes again and the lock closes", function()
    board("lock", true)
    onHerbCureV3("kelp")
    near(P("asthma"), 2 / 3, "asthma after the eat")
    local seen = rounds(3)
    expect(has(seen[1], "kalmia")).toBeTrue()
    expect(anyHas(seen, "curare vernalius")).toBeFalse()
    expect(truelock).toBeTrue()
  end)

  -- "Saibel eats a magnesium chip." kb/raw/logs/ours/2026-11-07_164635_Saibel.log:1241
  it("bloodroot over paralysis + slickness: gecko goes again and the lock closes", function()
    board("lock", true)
    onHerbCureV3("bloodroot")
    near(P("slickness"), 2 / 3, "slickness after the eat")
    local seen = rounds(3)
    expect(anyHas(seen, "gecko")).toBeTrue()
    expect(truelock).toBeTrue()
  end)

  -- A real monkshood reaction leaves disloyalty up (Saibel.log:1272), which made the reaction read
  -- as spent even with impatience read at the lock's bar.
  for _, c in ipairs({ { "lock", true }, { "lock", false }, { "group", false } }) do
    it("goldenseal over stupidity + impatience (" .. c[1] .. ", delivered " .. tostring(c[2])
      .. "): monkshood goes again", function()
      board(c[1], c[2], "stupidity", "disloyalty")
      onHerbCureV3("goldenseal")
      near(P("impatience"), 2 / 3, "impatience after the eat")
      local seen = rounds(3)
      expect(anyHas(seen, "impulse Agathon masochism monkshood")).toBeTrue()
      expect(truelock).toBeTrue()
    end)
  end

  -- A third of the branches lost the piece, with no cure of ours to name (a focus, say).
  local function doubt(aff)
    local keep = afflictionStatesV3[1]
    local lost = { affs = {}, prob = keep.prob / 3 }
    for k, v in pairs(keep.affs) do lost.affs[k] = v end
    lost.affs[aff] = nil
    keep.prob = keep.prob * 2 / 3
    afflictionStatesV3[#afflictionStatesV3 + 1] = lost
    rebuildCacheV3()
    syncToOldSystemV3()
  end

  -- Each venom picker's own read of each piece, one round each. The stall was "curare vernalius"
  -- (lock, relapse) or "curare kalmia" (group). stupidityImpulseSent keeps the relapse's one
  -- stupidity impulse out of the way, so the round is its DSTAB.
  for _, c in ipairs({
    { "pickVenomRelapse asthma", "lock", true, "kelp", "dstab Agathon kalmia slike" },
    { "pickVenomRelapse slickness", "lock", true, "bloodroot", "dstab Agathon gecko slike" },
    { "pickVenomRelapse anorexia", "lock", true, "doubt", "dstab Agathon slike curare", "anorexia" },
    { "pickVenom asthma", "lock", false, "kelp", "dstab Agathon kalmia curare", "anorexia" },
    { "pickVenom slickness", "lock", false, "bloodroot", "dstab Agathon gecko curare", "anorexia" },
    { "slikeGateMet anorexia", "lock", false, "doubt", "dstab Agathon slike curare", "anorexia" },
    { "pickVenomGroup anorexia", "group", false, "doubt", "dstab Agathon slike curare", "anorexia" },
  }) do
    it(c[1] .. " at 0.667: " .. c[5], function()
      if c[6] then board(c[2], c[3], c[6]) else board(c[2], c[3]) end
      serpent.state.stupidityImpulseSent = true
      if c[4] == "doubt" then doubt("anorexia") else onHerbCureV3(c[4]) end
      expect(has(rounds(1)[1], c[5])).toBeTrue()
    end)
  end

  it("pickVenomGroup: an asthma at 0.667 goes before the slickness that builds on it", function()
    world()
    serpOffenseMode = "group"
    give("paralysis", "asthma", "weariness", "impatience")
    onHerbCureV3("kelp")
    expect(has(round(), "dstab Agathon kalmia gecko")).toBeTrue()
  end)

  it("group mode sends the piece again too", function()
    board("group", false)
    onHerbCureV3("kelp")
    expect(has(rounds(1)[1], "kalmia")).toBeTrue()
  end)

  it("with sileris up the gecko strip goes for an impatience at 0.667 too", function()
    board("lock", false, "stupidity")
    onHerbCureV3("goldenseal")
    tAffs.sileris = true
    expect(has(round(), "dstab Agathon gecko")).toBeTrue()
    expect(serpent.state.geckoStripAttempted).toBeTrue()
  end)

  it("a read of a piece to build on stays at 0.30: gecko rides on an asthma at 0.667", function()
    world()
    give("paralysis", "asthma", "weariness", "impatience")
    onHerbCureV3("kelp")
    near(P("asthma"), 2 / 3, "asthma after the eat")
    expect(has(round(), "dstab Agathon kalmia gecko")).toBeTrue()
  end)

  it("a piece at 0.667 is not a lock: no recklessness until it is back", function()
    world(); ndb.Agathon = "Depthswalker"
    give("anorexia", "asthma", "slickness", "paralysis", "weariness")
    onHerbCureV3("kelp")
    expect(serpent.recklessnessAllowed()).toBeFalse()
    expect(has(round(), "eurypteria")).toBeFalse()
    give("asthma")
    expect(serpent.recklessnessAllowed()).toBeTrue()
  end)
end)

describe("lock_reinforce never sends curare twice", function()
  local function hardlock(class, ...)
    world()
    ndb.Agathon = class
    serpent.state.impatienceDelivered = true
    give("asthma", "slickness", "anorexia", "impatience", "weariness", "clumsiness", "masochism", ...)
  end

  it("a paralysis-lock class gets voyria, not its own curare again", function()
    for _, class in ipairs({ "Occultist", "Shaman", "Jester" }) do
      hardlock(class)
      local r = round()
      expect(serpStrategy).toBe("lock_reinforce")
      expect(has(r, "dstab Agathon curare voyria")).toBeTrue()
    end
  end)

  it("with voyria up the second venom is another one", function()
    for _, class in ipairs({ "Occultist", "Monk", "Serpent" }) do
      hardlock(class, "voyria")
      local r = round()
      expect(serpStrategy).toBe("lock_reinforce")
      expect(has(r, "dstab Agathon curare ")).toBeTrue()
      expect(has(r, "curare curare")).toBeFalse()
    end
  end)

  it("a class whose lock venom is missing still gets it", function()
    world()
    ndb.Agathon = "Magi"
    serpent.state.impatienceDelivered = true
    give("asthma", "slickness", "anorexia", "impatience", "weariness", "clumsiness", "masochism")
    expect(has(round(), "dstab Agathon curare notechis")).toBeTrue()
  end)
end)

describe("group mode reaches the finish", function()
  local function truelocked()
    world()
    serpOffenseMode = "group"
    give("anorexia", "asthma", "slickness", "impatience", "paralysis", "weariness")
  end

  it("at truelock the voyria impulse goes once, then the finish", function()
    truelocked()
    local r = round()
    expect(serpStrategy).toBe("lock_reinforce")
    expect(has(r, "impulse Agathon vertigo voyria")).toBeTrue()
    expect(serpent.state.voyriaSent).toBeTrue()
    clock = clock + 2.4
    serp_setmode_group()                         -- `sr` runs this on every press: no mode change
    expect(serpent.state.voyriaSent).toBeTrue()
    r = round()
    expect(serpStrategy).toBe("finish")
    expect(has(r, "dstab Agathon voyria ")).toBeTrue()
    expect(has(r, "impulse")).toBeFalse()
  end)

  it("below truelock it stays the group strategy", function()
    truelocked()
    erAff("paralysis")
    round()
    expect(serpStrategy).toBe("group")
  end)
end)

describe("X6: the unused focus clock is gone", function()
  it("serpent.getFocusCooldownRemaining is not defined", function()
    expect(serpent.getFocusCooldownRemaining).toBeNil()
  end)
end)

end)

-- Restore the shared Lua state.
os.clock, table.contains, string.starts = savedClock, savedContains, savedStarts
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
if not ok then error(err) end
