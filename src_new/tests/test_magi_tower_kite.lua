-- test_magi_tower_kite.lua -- the Magi kite in the Mnemosyne tower (v4.7.530, mnemosyne/018).
-- User, 2026-11-27: "Cooldown Abilities via Boons > Stormhammer if not in danger (health) > Run if in
-- danger (health) > hit and run with stormhammer". Hit and run = "Cast, step out, return". Danger =
-- the swarm's escape line (escapeAt). And: "stormhammer only for denizens 3 plus, not 1 or 2.
-- Staffcast is better usage there."
--
-- The REAL code runs: basher/001 (danger level, the attack hold), basher/002 (the round), ataxia/003
-- (the one-entry move), mnemosyne/009 (the swarm) and 018 (the kite), and the cast lines go through
-- the REAL trigger patterns (magi_offense_tracking/022 and 023). One shared Lua state: every global
-- is restored at the end.

local mock = require("mock_mudlet")

local before = {}
for k, v in pairs(_G) do before[k] = v end

local TL = dofile("src_new/tests/trigger_lib.lua")
local LEV = "src_new/triggers/levi_ataxia/for_levi/leviticus/magi_offense_tracking/"
local STORM_FILE, STAFF_FILE = LEV .. "022_Stormhammer_Cast.lua", LEV .. "023_Staffcast_Horripilation_Cast.lua"
-- The first wrapped row of each line (stormhammer: Tabethys's own log; staffcast: the third-person
-- line from kb/raw/logs/ours/2026-10-28_073547_Tabethys.log:761, put in the first person).
local STORM_LINE = "The sky above grows dark as you call upon powerful magics. Raising your hands balefully, you cause "
local STAFF_LINE = "You point an exquisite Mhaldorian staff of sterling silver at a carnivorous lycopod, and he screams in pain as his skin begins to freeze and crack."

local clock = 50000
getEpoch = function() return clock end

local echoes = {}
function ataxiaEcho(m) echoes[#echoes + 1] = tostring(m) end
function get_Battlerage() end
function table.contains(t, v)
  if type(t) ~= "table" then return false end
  for _, x in pairs(t) do if x == v then return true end end
  return false
end

local sent = {}
send = function(c) sent[#sent + 1] = tostring(c) end

gmcp = { Room = { Info = { area = "", num = 7200, details = {} } },
         Char = { Status = { class = "Magi" }, Vitals = { hp = 3000, maxhp = 10000, bal = "1", eq = "1" } } }
ataxia = { settings = { separator = ";", sipping = { manause = 30 } },
           vitals = { hpp = 30, hp = 3000, maxhp = 10000, mp = 10000, maxmp = 10000, rage = 0 },
           afflictions = {}, defences = {}, denizensHere = {} }
ataxiaBasher = { enabled = true, manual = true, inMnemosyne = true, ownDenizens = { "ashbeast" },
                 fleeThresholdPct = 25, shieldThresholdPct = 40 }
ataxiaTemp = {}
target = 101

-- The mnemosyne surface 009 and 018 touch (the parts of 004/005/008 that are not loaded here).
local cfg = { swarm = { enabled = true, threshold = 3 } }
local MAP = {
  current = 200, rooms = {},
  OFFSETS = { north = {0,1}, south = {0,-1}, east = {1,0}, west = {-1,0} },
  OPPOSITE = { north = "south", south = "north", east = "west", west = "east", up = "down", down = "up" },
}
local LONG = { n = "north", s = "south", e = "east", w = "west", u = "up", d = "down" }
local SHORT = {}
for s, l in pairs(LONG) do SHORT[l] = s end
function MAP.normDir(d) return LONG[d] or (SHORT[d] and d) or nil end
function MAP.shortDir(d) return SHORT[d] or d end
local armed = {}
local function count() local n = 0 for _ in pairs(ataxia.denizensHere) do n = n + 1 end return n end
local prey = false
ataxia.mnemosyne = {
  map = MAP, run = { ripple = 1 },
  explore = { on = true, fromRoom = 100, fromDir = "n" },
  _navRefusal = function() return nil end,
  _cfg = function() return cfg end,
  _roomHasDenizens = function() return count() > 0 end,
  _denizenCount = count,
  _scheduleTick = function() end,
  _tacticalArm = function(dir, timeout) armed[#armed + 1] = { dir = dir, timeout = timeout } end,
  _disarmMove = function() end,
  _exploreEcho = function(m) echoes[#echoes + 1] = tostring(m) end,
  echo = function(m) echoes[#echoes + 1] = tostring(m) end,
  runHasAffix = function(n) return prey and n == "Prey" end,
}

local function load(path)
  local okL, errL = pcall(dofile, path)
  if not okL then error("failed to load " .. path .. ": " .. tostring(errL), 0) end
end
local SCR = "src_new/scripts/levi_ataxia/levi/ataxia/"
load(SCR .. "ataxia/003_Queueing_Related.lua")
load(SCR .. "basher/001_Bashing_Functions.lua")
load(SCR .. "basher/002_Class_Bashing.lua")
load(SCR .. "mnemosyne/009_Swarm_Tactics.lua")
load(SCR .. "mnemosyne/018_Magi_Kite.lua")
local M = ataxia.mnemosyne
local S, K = M.swarm, M.magiKite
function ataxiaBasher_assembleBattlerage() return "BRAGE" end
ataxiaBasher_stormhammer = function() end
ataxiaBasher_magiStormPrep = function() end
ataxiaBasher_magiShouldBloodboil = function() return false end
ataxiaBasher_validTargets = function() return 0 end
local assembled = 0
ataxiaBasher_assembleAttack = function() assembled = assembled + 1 end

local function body(file)
  local fh = assert(io.open(file, "r"))
  local src = fh:read("*a"); fh:close()
  return assert((loadstring or load)(assert(src:match("%]%]%-%-\r?\n(.*)$"), "no header: " .. file), file))
end
-- Deliver a line the way it reaches Mudlet: wrapped, each row on its own, through the real patterns.
local function deliver(file, line)
  local hit = false
  for _, row in ipairs(TL.wrap(line, 119)) do
    if TL.anyMatches(TL.patterns(file), row) then body(file)(); hit = true end
  end
  return hit
end
local function has(s, part) return tostring(s):find(part, 1, true) ~= nil end
local function sentHas(part)
  for _, c in ipairs(sent) do if has(c, part) then return true end end
  return false
end
local function echoed(part)
  for _, e in ipairs(echoes) do if has(e, part) then return true end end
  return false
end
local function setHp(pct)
  ataxia.vitals.hpp = pct
  ataxia.vitals.hp, ataxia.vitals.maxhp = pct * 200, 20000 -- above the 3000 panic floor at 30%
  gmcp.Char.Vitals.hp, gmcp.Char.Vitals.maxhp = pct * 200, 20000
end
local function mobs(n, base)
  ataxia.denizensHere = {}
  for i = 1, n do ataxia.denizensHere[tostring((base or 100) + i)] = "a guard " .. i end
end

-- Room 100 (cleared) is south of the fight room 200; we walked north into 200.
local function world(n, hp)
  clock = 50000
  if K.active() then K.stop("fixture") end
  S.onRipple()
  sent, echoes, armed, assembled = {}, {}, {}, 0
  ataxiaTemp = {}
  ataxiaBasher_dmgSamples, ataxiaBasher_incSamples = {}, {} -- the damage watchdog's feeds (shared state)
  S._lastEmergencyAt, S._lastDisengageAt = nil, nil
  S.state = "idle"
  if S._stopMoveWatch then S._stopMoveWatch("fixture") end
  cfg.swarm = { enabled = true, threshold = 3 }
  MAP.current = 200
  MAP.rooms = {
    [100] = { visited = true, exits = { north = 200 } },
    [200] = { visited = true, exits = { south = 100 } },
  }
  M.explore.on, M.explore.fromRoom, M.explore.fromDir = true, 100, "n"
  gmcp.Room.Info.num, gmcp.Room.Info.area, gmcp.Room.Info.details = 7200, "", { "indoors" }
  gmcp.Char.Status.class = "Magi"
  gmcp.Char.Vitals.bal, gmcp.Char.Vitals.eq = "1", "1"
  ataxiaBasher = { enabled = true, manual = true, inMnemosyne = true, ownDenizens = { "ashbeast" },
                   fleeThresholdPct = 25, shieldThresholdPct = 40, shielded = false }
  ataxia.afflictions, ataxia.defences = {}, {}
  ataxia.vitals.mp, ataxia.vitals.maxmp = 10000, 10000
  mnemEvocationFire, mnemEvocationEarth, mnemMasterOfFour = false, false, false
  mnemWintersHeart, magiKkractle, mnemRollHide, mnemTerrorSkies = false, false, false, false
  prey = false
  target = 101
  gmcp.Room.Info.name = nil
  S.grounded, S.flying, S.flightConfirmed, S.flightUpAt, S.flightDownAt = nil, nil, nil, nil, nil
  mnemDeluge = nil
  mobs(n or 3)
  setHp(hp or 30)
end

-- Outdoors (v4.7.531): no "indoors" in the room details, a named room.
local GROUND = "A windswept plain"
local function outdoors()
  gmcp.Room.Info.details = {}
  gmcp.Room.Info.name = GROUND
end
-- Up: gmcp renames the room, and Char.Items lists the sky (empty).
local function goUp() gmcp.Room.Info.name = "Flying above " .. GROUND; mobs(0) end
-- Down: the ground's name and its denizens.
local function goDown(n) gmcp.Room.Info.name = GROUND; mobs(n or 3) end
local function sentExact(cmd)
  for _, c in ipairs(sent) do if c == cmd then return true end end
  return false
end
local SIP_FILE = "src_new/triggers/levi_ataxia/for_levi/leviticus/balances/002_Sip_Used.lua"
local function sip()
  local t = target
  target = nil -- the trigger's basher echo is not what is tested here
  line = "The elixir heals and soothes you." -- Mudlet's global for the matched line
  local hit = deliver(SIP_FILE, line)
  target, line = t, nil
  return hit
end

-- Land in a room: the map moves, the next room's denizens are `n`.
local function land(room, n, base)
  MAP.current = room
  gmcp.Room.Info.num = 7000 + room
  mobs(n or 0, base)
end

local ok, err = pcall(function()

describe("the kite starts below the escape line, Magi in the tower only", function()
  it("30% (line 35): a kite in its cast phase, and no move sent", function()
    world(3, 30)
    S.onVitals()
    expect(K.active()).toBe(true)
    expect(ataxiaTemp.magiKite.phase).toBe("cast")
    expect(sentHas("lvmove")).toBe(false)
    expect(S.state).toBe("idle")
  end)
  it("40%: no kite", function()
    world(3, 40)
    S.onVitals()
    expect(K.active()).toBe(false)
  end)
  it("another class at 30% gets the ladder's retreat, as before", function()
    world(3, 30)
    gmcp.Char.Status.class = "Runewarden"
    S.onVitals()
    expect(K.active()).toBe(false)
    expect(S.state).toBe("pulling")
    expect(sentHas("setalias lvmove stand/leap s")).toBe(true)
  end)
  it("outside the tower a Magi gets no kite, and the danger level still flees", function()
    world(3, 20)
    ataxiaBasher.inMnemosyne = false
    gmcp.Room.Info.area = "Test Bashing Area"
    expect(K.tryStart(20)).toBe(false)
    expect(ataxiaBasher_dangerLevel()).toBe("flee")
    expect(K.active()).toBe(false)
  end)
  it("the danger level answers 'attack' while the kite owns the room (no disengage)", function()
    world(3, 20)
    expect(ataxiaBasher_dangerLevel()).toBe("attack")
    expect(K.active()).toBe(true)
    expect(sentHas("lvmove")).toBe(false)
  end)
end)

describe("the kite's hit: stormhammer at 3+, the staffcast at 1-2", function()
  it("3 denizens -> stormhammer at three", function()
    world(3, 30); S.onVitals()
    expect(ataxiaBasher_magiBashing()).toBe("BRAGE;cast stormhammer at 101 and 102 and 103")
  end)
  it("2 denizens -> staff cast horripilation, not stormhammer", function()
    world(2, 30); S.onVitals()
    expect(ataxiaBasher_magiBashing()).toBe("BRAGE;staff cast horripilation at 101")
  end)
  it("3 denizens but no mana for stormhammer -> the staffcast", function()
    world(3, 30); S.onVitals()
    ataxia.vitals.mp = 4000
    expect(ataxiaBasher_magiBashing()).toBe("BRAGE;staff cast horripilation at 101")
  end)
  it("a ready 30 s proc still comes first; the fillers come after the kite's hit", function()
    world(3, 30); S.onVitals()
    mnemEvocationEarth, magiKkractle, mnemWintersHeart = true, true, true
    expect(ataxiaBasher_magiBashing()).toBe("BRAGE;cast quake")
    mnemEvocationEarth = false
    expect(ataxiaBasher_magiBashing()).toBe("BRAGE;cast stormhammer at 101 and 102 and 103")
  end)
end)

describe("the cycle: the step out goes on the cast line", function()
  it("building the round and later prompts send no move; the cast line does", function()
    world(3, 30); S.onVitals()
    ataxiaBasher_magiBashing()
    clock = clock + 2; S.onVitals(); K.step()
    expect(sentHas("lvmove")).toBe(false)
    expect(deliver(STORM_FILE, STORM_LINE)).toBe(true)
    expect(ataxiaTemp.magiKite.phase).toBe("out")
    expect(sentHas("cq all")).toBe(true)
    expect(sentHas("setalias lvmove stand/leap s")).toBe(true)
    expect(sentHas("queue addclear free lvmove")).toBe(true)
    expect(armed[#armed].timeout).toBe(12)
    -- the dispatcher is held, so no `queue addclearfull` round can delete the step
    ataxiaBasher_attack()
    expect(assembled).toBe(0)
  end)
  it("the staffcast line steps out too (2 denizens)", function()
    world(2, 30); S.onVitals()
    expect(deliver(STAFF_FILE, STAFF_LINE)).toBe(true)
    expect(ataxiaTemp.magiKite.phase).toBe("out")
  end)
  it("a cast line outside the kite's cast phase moves nothing", function()
    world(3, 50)
    expect(deliver(STORM_FILE, STORM_LINE)).toBe(true)
    expect(K.active()).toBe(false)
    expect(sentHas("lvmove")).toBe(false)
  end)
  it("landed: wait for the room to settle and for equilibrium, then back in; then cast again", function()
    world(3, 30); S.onVitals()
    deliver(STORM_FILE, STORM_LINE)
    sent = {}
    land(100, 0)
    S.onVitals()
    expect(ataxiaTemp.magiKite.phase).toBe("away")
    expect(ataxiaTemp.magiKiteHold ~= nil).toBe(true)
    clock = clock + 1.6
    gmcp.Char.Vitals.eq = "0"
    K.step()
    expect(sentHas("lvmove")).toBe(false) -- equilibrium is not back
    gmcp.Char.Vitals.eq = "1"
    K.step()
    expect(ataxiaTemp.magiKite.phase).toBe("back")
    expect(sentHas("setalias lvmove stand/leap n")).toBe(true)
    land(200, 3)
    K.step()
    expect(ataxiaTemp.magiKite.phase).toBe("cast")
    expect(ataxiaTemp.magiKiteHold).toBeNil()
    expect(ataxiaBasher_magiBashing()).toBe("BRAGE;cast stormhammer at 101 and 102 and 103")
  end)
  it("health 60%: still kiting; 90% and cured: the kite ends and we fight", function()
    world(3, 30); S.onVitals()
    setHp(60); K.step()
    expect(K.active()).toBe(true)
    setHp(90); K.step()
    expect(K.active()).toBe(false)
    expect(echoed("health is back")).toBe(true)
    expect(ataxiaBasher_magiBashing()).toBe("BRAGE;cast stormhammer at 101 and 102 and 103") -- the tower round
  end)
  it("90% but still afflicted: kiting goes on (the U-turn bar is 85% AND cured)", function()
    world(3, 30); S.onVitals()
    ataxia.afflictions = { brokenleftarm = true }
    setHp(90); K.step()
    expect(K.active()).toBe(true)
  end)
end)

describe("the stops, each with its reason", function()
  it("no cleared room next door: no kite, the reason is said", function()
    world(3, 30)
    MAP.rooms[100].visited = false
    S.onVitals()
    expect(K.active()).toBe(false)
    expect(echoed("no cleared room next door")).toBe(true)
  end)
  it("no exit at the cast line: the kite stops and the ladder has the room", function()
    world(3, 30); S.onVitals()
    MAP.rooms[200].exits = {}
    deliver(STORM_FILE, STORM_LINE)
    expect(K.active()).toBe(false)
    expect(echoed("MAGI KITE ends")).toBe(true)
    expect(K.tryStart(30)).toBe(false) -- cooling down
  end)
  it("Prey: no kite", function()
    world(3, 30); prey = true
    expect(K.tryStart(30)).toBe(false)
    expect(echoed("Prey")).toBe(true)
  end)
  it("a lethal hit here: no kite (the ladder leaves without a cast)", function()
    world(3, 30)
    ataxiaTemp.attackHits = { { room = 7200, sum = 9000, last = clock } }
    expect(K.tryStart(30)).toBe(false)
    expect(echoed("LETHAL")).toBe(true)
  end)
  it("a step that never happens: the kite stops, takes the step back and releases the hold", function()
    world(3, 30); S.onVitals()
    deliver(STORM_FILE, STORM_LINE)
    sent = {}
    clock = clock + 13
    K.step()
    expect(K.active()).toBe(false)
    expect(echoed("never happened")).toBe(true)
    expect(ataxiaTemp.magiKiteHold).toBeNil()
    expect(sentHas("cq all")).toBe(true)
  end)
  it("they follow every step: hit them there once, then stop and fight", function()
    world(3, 30); S.onVitals()
    deliver(STORM_FILE, STORM_LINE)
    land(100, 3, 200)
    K.step()
    clock = clock + 1.6; K.step()
    expect(ataxiaTemp.magiKite.phase).toBe("cast")
    expect(ataxiaTemp.magiKite.fight).toBe(100)
    MAP.rooms[100].exits = { north = 200 }
    MAP.rooms[200].visited = true
    M.explore.fromRoom, M.explore.fromDir = 200, "s"
    deliver(STORM_FILE, STORM_LINE)
    expect(ataxiaTemp.magiKite.phase).toBe("out")
    land(200, 3, 300)
    K.step(); clock = clock + 1.6; K.step()
    expect(K.active()).toBe(false)
    expect(echoed("followed 2 steps")).toBe(true)
    expect(S._pursued()).toBe(true)
  end)
  it("going back is one hit from death: stop, and heal here", function()
    world(3, 30); S.onVitals()
    deliver(STORM_FILE, STORM_LINE)
    land(100, 0)
    K.step()
    ataxiaTemp.attackHits = { { room = 7200, sum = 9000, last = clock } }
    clock = clock + 1.6; K.step()
    expect(K.active()).toBe(false)
    expect(echoed("not safe")).toBe(true)
    expect(S.state).toBe("recovering")
  end)
  it("the cast line never comes: two unexplained equilibrium spends stop the kite", function()
    world(3, 30); S.onVitals()
    for _ = 1, 2 do
      gmcp.Char.Vitals.eq = "1"; K.step()
      gmcp.Char.Vitals.eq = "0"; K.step()
      clock = clock + 1.2; K.step()
    end
    expect(K.active()).toBe(false)
    expect(echoed("UNCONFIRMED")).toBe(true)
    expect(sentHas("lvmove")).toBe(false) -- a lapse never moves us
  end)
  it("the fight room clear at low health: heal here", function()
    world(3, 30); S.onVitals()
    mobs(0); K.step()
    expect(K.active()).toBe(false)
    expect(S.state).toBe("recovering")
  end)
  it("a swarm reset (a new ripple) ends it", function()
    world(3, 30); S.onVitals()
    S.onRipple()
    expect(K.active()).toBe(false)
  end)
  it("off by setting: no kite", function()
    world(3, 30); cfg.swarm.magiKite = false
    S.onVitals()
    expect(K.active()).toBe(false)
    expect(S.state).toBe("pulling") -- the ladder, as for any class
  end)
end)

describe("outdoors the out is a fly: cast, fly, sip, land, cast (v4.7.531)", function()
  it("the whole cycle, each phase on the game's evidence", function()
    world(3, 30); outdoors()
    S.onVitals()
    expect(K.active()).toBe(true)
    expect(echoed("cast, fly, heal, land")).toBe(true)
    sent = {}
    expect(deliver(STORM_FILE, STORM_LINE)).toBe(true)
    expect(ataxiaTemp.magiKite.phase).toBe("up")
    expect(sentHas("cq all")).toBe(true)
    expect(sentHas("setalias lvmove stand/fly")).toBe(true)
    expect(sentHas("leap")).toBe(false)
    ataxiaBasher_attack()
    expect(assembled).toBe(0) -- held: no round can delete the queued fly
    -- the key press is not the takeoff: still on the ground, still "up"
    K.step()
    expect(ataxiaTemp.magiKite.phase).toBe("up")
    goUp(); K.step()
    expect(ataxiaTemp.magiKite.phase).toBe("air")
    -- up, equilibrium not back: no land
    sent = {}
    clock = clock + 2; gmcp.Char.Vitals.eq = "0"; K.step()
    expect(sentExact("land")).toBe(false)
    -- equilibrium back, but no sip yet and under one sip clock: still up
    gmcp.Char.Vitals.eq = "1"; K.step()
    expect(sentExact("land")).toBe(false)
    expect(ataxiaTemp.magiKite.phase).toBe("air")
    -- SSC's health sip (the real trigger): land
    expect(sip()).toBe(true)
    K.step()
    expect(sentExact("land")).toBe(true)
    expect(ataxiaTemp.magiKite.phase).toBe("down")
    ataxiaBasher_attack()
    expect(assembled).toBe(0)
    goDown(3); K.step()
    expect(ataxiaTemp.magiKite.phase).toBe("cast")
    expect(ataxiaTemp.magiKiteHold).toBeNil()
    expect(ataxiaBasher_magiBashing()).toBe("BRAGE;cast stormhammer at 101 and 102 and 103")
    deliver(STORM_FILE, STORM_LINE)
    expect(ataxiaTemp.magiKite.phase).toBe("up")
    expect(ataxiaTemp.magiKite.cycles).toBe(2)
  end)
  it("the ring's line counts as up; the land line counts as down", function()
    world(3, 30); outdoors(); S.onVitals()
    deliver(STORM_FILE, STORM_LINE)
    clock = clock + 5
    S.onFlightUp(); mobs(0); K.step()
    expect(ataxiaTemp.magiKite.phase).toBe("air")
    clock = clock + 5; K.step() -- one sip clock up with no sip: land
    expect(ataxiaTemp.magiKite.phase).toBe("down")
    clock = clock + 0.5
    gmcp.Room.Info.name = nil -- gmcp names no room: only the line can say we are down
    K.step()
    expect(ataxiaTemp.magiKite.phase).toBe("down")
    S.onFlightDown(); K.step()
    expect(ataxiaTemp.magiKite.phase).toBe("cast")
  end)
  it("no sip at all: land after one sip clock, not at full health", function()
    world(3, 30); outdoors(); S.onVitals()
    deliver(STORM_FILE, STORM_LINE)
    goUp(); K.step()
    sent = {}
    clock = clock + 4; K.step()
    expect(sentExact("land")).toBe(false)
    clock = clock + 0.5; K.step()
    expect(sentExact("land")).toBe(true)
  end)
  it("a land that does not take is sent again", function()
    world(3, 30); outdoors(); S.onVitals()
    deliver(STORM_FILE, STORM_LINE)
    goUp(); K.step()
    clock = clock + 5; K.step()
    sent = {}
    clock = clock + 1.6; K.step()
    expect(sentExact("land")).toBe(true)
    expect(ataxiaTemp.magiKite.phase).toBe("down")
  end)
end)

describe("the fly refused, and the stops while flying", function()
  it("no airborne evidence in 10 s: the fly is taken back and the kite steps out instead", function()
    world(3, 30); outdoors(); S.onVitals()
    deliver(STORM_FILE, STORM_LINE)
    sent = {}
    clock = clock + 11; K.step()
    expect(sentHas("cq all")).toBe(true)
    expect(ataxiaTemp.magiKite.phase).toBe("out")
    expect(sentHas("setalias lvmove stand/leap s")).toBe(true)
    expect(echoed("the fly never took")).toBe(true)
    -- the next cycle does not try the sky again
    land(100, 0); K.step(); clock = clock + 1.6; K.step()
    land(200, 3); K.step()
    expect(ataxiaTemp.magiKite.phase).toBe("cast")
    deliver(STORM_FILE, STORM_LINE)
    expect(ataxiaTemp.magiKite.phase).toBe("out")
  end)
  it("webbed while the fly waits: the step out at once", function()
    world(3, 30); outdoors(); S.onVitals()
    deliver(STORM_FILE, STORM_LINE)
    ataxia.afflictions.webbed = true
    K.step()
    expect(ataxiaTemp.magiKite.phase).toBe("out")
    expect(echoed("bound")).toBe(true)
  end)
  it("refused with no cleared room next door: the kite stops and says why", function()
    world(3, 30); outdoors()
    MAP.rooms[100].visited = false
    S.onVitals()
    expect(K.active()).toBe(true) -- the sky needs no exit
    deliver(STORM_FILE, STORM_LINE)
    clock = clock + 11; K.step()
    expect(K.active()).toBe(false)
    expect(echoed("MAGI KITE ends")).toBe(true)
    expect(echoed("no cleared room next door")).toBe(true)
  end)
  it("Deluge outdoors: the step out, and the echo says why not the sky", function()
    world(3, 30); outdoors(); mnemDeluge = true
    S.onVitals()
    expect(echoed("cast, step out, come back")).toBe(true)
    deliver(STORM_FILE, STORM_LINE)
    expect(ataxiaTemp.magiKite.phase).toBe("out")
    expect(echoed("no fly: Deluge")).toBe(true)
    mnemDeluge = nil
  end)
  it("a swarm reset while up lands us", function()
    world(3, 30); outdoors(); S.onVitals()
    deliver(STORM_FILE, STORM_LINE)
    goUp(); K.step()
    sent = {}
    S.onRipple()
    expect(K.active()).toBe(false)
    expect(sentExact("land")).toBe(true)
    expect(echoed("MAGI KITE ends")).toBe(true)
  end)
  it("leaving the tower while up lands us", function()
    world(3, 30); outdoors(); S.onVitals()
    deliver(STORM_FILE, STORM_LINE)
    goUp(); K.step()
    sent = {}
    ataxiaBasher.inMnemosyne = false
    K.step()
    expect(K.active()).toBe(false)
    expect(sentExact("land")).toBe(true)
  end)
  it("a stop with the fly still queued takes it back and sends no land", function()
    world(3, 30); outdoors(); S.onVitals()
    deliver(STORM_FILE, STORM_LINE)
    sent = {}
    S.onRipple()
    expect(K.active()).toBe(false)
    expect(sentHas("cq all")).toBe(true)
    expect(sentExact("land")).toBe(false)
  end)
  it("landing into a lethal hit: we stay up, and the recovery hover takes the flight", function()
    world(3, 30); outdoors(); S.onVitals()
    deliver(STORM_FILE, STORM_LINE)
    goUp(); K.step()
    ataxiaTemp.attackHits = { { room = 7200, sum = 9000, last = clock } }
    sent = {}
    clock = clock + 5; K.step()
    expect(K.active()).toBe(false)
    expect(sentExact("land")).toBe(false)
    expect(S.state).toBe("recovering")
    expect(S.flying).toBe(true)
    expect(echoed("the hover holds the air")).toBe(true)
  end)
  it("company in the sky: land, and no flying for the rest of the ripple", function()
    world(3, 30); outdoors(); S.onVitals()
    deliver(STORM_FILE, STORM_LINE)
    goUp(); K.step()
    sent = {}
    clock = clock + 1.6; mobs(1, 500); K.step()
    expect(sentExact("land")).toBe(true)
    expect(S.grounded).toBe(true)
    goDown(3); K.step()
    expect(ataxiaTemp.magiKite.phase).toBe("cast")
    deliver(STORM_FILE, STORM_LINE)
    expect(ataxiaTemp.magiKite.phase).toBe("out")
  end)
  it("knocked out of the sky: the cast phase on foot, no flying this ripple", function()
    world(3, 30); outdoors(); S.onVitals()
    deliver(STORM_FILE, STORM_LINE)
    goUp(); K.step()
    clock = clock + 1.6; goDown(3); K.step()
    expect(ataxiaTemp.magiKite.phase).toBe("cast")
    expect(ataxiaTemp.magiKiteHold).toBeNil()
    expect(S.grounded).toBe(true)
  end)
end)

describe("the fly out touches nobody else", function()
  it("another class outdoors at 30% gets the swarm's hover, not the kite", function()
    world(3, 30); outdoors()
    gmcp.Char.Status.class = "Runewarden"
    S.onVitals()
    expect(K.active()).toBe(false)
    expect(S.state).toBe("recovering")
    expect(S.flying).toBe(true)
  end)
  it("a Magi outdoors above the line: no kite, no fly", function()
    world(3, 50); outdoors()
    S.onVitals()
    expect(K.active()).toBe(false)
    expect(sentHas("fly")).toBe(false)
  end)
end)

end)

if K and K.active and K.active() then pcall(K.stop, "test end") end
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
if not ok then error(err) end
