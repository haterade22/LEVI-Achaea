--- test_swarm_tactics.lua — Mnemosyne swarm tactics (mnemosyne/009)
-- Pure-logic tests: threshold resolution, back-direction validation, the
-- assess -> pull -> funnel -> reenter state machine, decorator consumption,
-- hold hygiene, and resets. Timer-fired paths (fallback/hold timeouts) are
-- validated in-game; everything here is deterministic.

require("mock_mudlet")

-- Controllable clock (009 prefers getEpoch when present).
local clock = 10000
function getEpoch() return clock end

-- Recording stubs. The mock's own `send` (with its capture buffer that test_example
-- asserts on) is restored at the END of this file -- test files share one Lua state and
-- discovery order differs between Windows (dir) and CI (find), so a leaked override
-- breaks whoever runs after us.
local _mockSend = send
local sent = {}
function send(cmd) table.insert(sent, cmd) end
local armed = {}
local scheduled = {}

-- GMCP + vitals mocks (indoors flag, panic HP)
gmcp = { Room = { Info = { details = {} } } }

-- Mock mnemosyne core (008/005/004 surface that 009 touches).
local cfg = { swarm = { enabled = true, threshold = 3 } }
local MAP = {
  current = nil,
  rooms = {},
  OFFSETS = { north = {0,1}, south = {0,-1}, east = {1,0}, west = {-1,0},
              northeast = {1,1}, northwest = {-1,1}, southeast = {1,-1}, southwest = {-1,-1} },
  OPPOSITE = { north = "south", south = "north", east = "west", west = "east",
               northeast = "southwest", southwest = "northeast",
               northwest = "southeast", southeast = "northwest",
               up = "down", down = "up" },
}
local LONG = { n = "north", s = "south", e = "east", w = "west", d = "down", u = "up",
               ne = "northeast", nw = "northwest", se = "southeast", sw = "southwest" }
local SHORT = {}
for s, l in pairs(LONG) do SHORT[l] = s end
function MAP.normDir(d) return LONG[d] or (SHORT[d] and d) or nil end
function MAP.shortDir(d) return SHORT[d] or d end

local mobs = 0
local disarmed = 0
ataxia = { settings = { separator = ";" }, vitals = { hpp = 100 } }
ataxia.mnemosyne = {
  map = MAP,
  run = { ripple = 1 },
  explore = { on = true, fromRoom = nil, fromDir = nil, lavaRooms = {}, lavaEdges = {} },
  -- Faithful minimal stand-ins for the predicates that live in 008 (not loaded here). The
  -- swarm's escape routes consult these, so without them the lava guards are simply absent
  -- and the tests would pass while the guard did nothing.
  roomIsLava = function(k)
    return k ~= nil and ataxia.mnemosyne.explore.lavaRooms[k] == true
  end,
  edgeIsLava = function(num, dir)
    local nd = MAP.normDir(dir)
    if num == nil or not nd then return false end
    local e = ataxia.mnemosyne.explore.lavaEdges[num]
    if e and e[nd] then return true end
    local r = MAP.rooms[num]
    local dest = r and r.exits and r.exits[nd]
    if type(dest) == "number" and dest > 0 then
      return ataxia.mnemosyne.explore.lavaRooms[dest] == true
    end
    return false
  end,
  _cfg = function() return cfg end,
  _roomHasDenizens = function() return mobs > 0 end,
  _denizenCount = function() return mobs end,
  _scheduleTick = function(d) table.insert(scheduled, d or 0.5) end,
  _tacticalArm = function(dir) table.insert(armed, dir) end,
  _disarmMove = function() disarmed = disarmed + 1 end,
  _exploreEcho = function() end,
  echo = function() end,
  _captureLines = function(opts) opts.onDone({ "line one", "line two" }) end,
}
ataxiaBasher = { enabled = true }
ataxiaTemp = {}
found_target = false

-- S._afflicted consults the PvE curing profile to tell a PARKED affliction (one we have
-- decided not to cure, so it must not hold the recovery hover) from a real one. Loaded
-- explicitly rather than relying on test_bash_curing_profile.lua having run first --
-- the runner sorts filenames, so that ordering is incidental, not a contract.
if not ataxia_bashCuringPrios then
  local okp = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/ataxia/008_Bash_Curing_Profile.lua")
  if not okp then error("Failed to load bash curing profile") end
end

local file = "src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/009_Swarm_Tactics.lua"
local ok, err = pcall(dofile, file)
if not ok then error("Failed to load swarm tactics file: " .. tostring(err)) end
local S = ataxia.mnemosyne.swarm
local M = ataxia.mnemosyne

-- Grid fixture: room 100 (funnel, cleared) north of us -> we walked north INTO
-- room 200 (the swarm room). fromDir = "n", so back = south, forward = north.
local function fixture(count)
  S.onRipple()
  sent, armed, scheduled = {}, {}, {}
  ataxiaTemp = {}
  clock = 10000
  disarmed = 0
  S._lastEmergencyAt = nil
  gmcp.Char = nil
  target = nil            -- basher's current-target global (progress check)
  ataxiaBasher_dsGet = nil
  -- onRipple deliberately preserves wall memory within a ripple, so tests must
  -- clear it explicitly for isolation.
  S.wallRaised = {}
  M.explore.lavaRooms, M.explore.lavaEdges = {}, {}
  S._wallsRipple = nil
  S.tumbleResolvedAt, S._recoverTumbles = nil, nil -- fixture rewinds the clock; these must go with it
  S._meltRoom, S._meltTries = nil, nil
  mobs = count or 3
  MAP.current = 200
  MAP.rooms = {
    [100] = { visited = true, exits = { north = 200 } },
    [200] = { visited = true, exits = { south = 100 } },
  }
  M.explore.on = true
  M.explore.fromRoom = 100
  M.explore.fromDir = "n"
  M.run.ripple = 1
  cfg.swarm = { enabled = true, threshold = 3 }
  ataxiaBasher.enabled = true
  ataxiaBasher.manual = true
  gmcp.Room.Info.details = {}
  ataxia.vitals = { hpp = 100 }
  ataxia.afflictions = {}
  mnemRollHide = false
end

describe("swarm threshold resolution", function()
  it("uses the flat threshold by default", function()
    fixture()
    expect(S.threshold()).toBe(3)
  end)
  it("switches to the deep threshold at/past deepAt", function()
    fixture()
    cfg.swarm.deepAt, cfg.swarm.deepThreshold = 10, 4
    M.run.ripple = 9
    expect(S.threshold()).toBe(3)
    M.run.ripple = 10
    expect(S.threshold()).toBe(4)
  end)
end)

describe("swarm _backDir validation", function()
  it("returns short back, long back and short forward for a valid walked edge", function()
    fixture()
    local sb, lb, sf = S._backDir()
    expect(sb).toBe("s")
    expect(lb).toBe("south")
    expect(sf).toBe("n")
  end)
  it("rejects a non-planar entry (holding room's down)", function()
    fixture()
    M.explore.fromDir = "d"
    expect(S._backDir()).toBe(nil)
  end)
  it("rejects when adjacency does not match (stale fromDir)", function()
    fixture()
    MAP.rooms[200].exits.south = 150 -- reported exit leads elsewhere
    expect(S._backDir()).toBe(nil)
  end)
  it("rejects when we never left the from-room", function()
    fixture()
    MAP.current = 100
    M.explore.fromRoom = 100
    expect(S._backDir()).toBe(nil)
  end)
end)

describe("swarm assess -> pull", function()
  it("starts a pull at threshold with a valid route", function()
    fixture(3)
    expect(S.onTick()).toBeTrue()
    expect(S.state).toBe("pulling")
    expect(ataxiaTemp.swarmPullDir).toBe("s")
    expect(S.pulls[200]).toBe(1)
  end)
  it("does not engage below threshold", function()
    fixture(2)
    expect(S.onTick()).toBeFalse()
    expect(S.state).toBe("idle")
  end)
  it("fights in place when there is no valid pull route", function()
    fixture(4)
    M.explore.fromDir = "d" -- entered via the holding room's down
    expect(S.onTick()).toBeFalse()
    expect(S.noTactics[200]).toBeTrue()
    expect(S.state).toBe("idle")
  end)
  it("gives up after MAX_PULLS and marks the room no-tactics", function()
    fixture(3)
    S.pulls[200] = 3 -- budget already spent
    expect(S.onTick()).toBeFalse()
    expect(S.noTactics[200]).toBeTrue()
  end)
  it("does nothing when the swarm config is off", function()
    fixture(5)
    cfg.swarm.enabled = false
    expect(S.onTick()).toBeFalse()
    expect(S.state).toBe("idle")
  end)
end)

describe("swarm decorate (pull consumption)", function()
  it("appends the back-dir once, arms the hold, and clears stale targeting", function()
    fixture(3)
    S.onTick() -- arms the pull
    found_target = true
    local cmd = S.decorate("infuse fire; drawslash t sternum", ";")
    expect(cmd).toBe("infuse fire; drawslash t sternum;s")
    expect(ataxiaTemp.swarmPullDir).toBe(nil) -- one-shot consumed
    expect(ataxiaTemp.swarmHold).toBeTrue()
    expect(found_target).toBeFalse()
    expect(armed[1]).toBe("s") -- explorer in-flight machinery armed
    local again = S.decorate("attack", ";")
    expect(again).toBe("attack") -- no double decoration
  end)
  it("passes commands through untouched when idle", function()
    fixture(0)
    expect(S.decorate("attack", ";")).toBe("attack")
  end)
end)

describe("swarm funnel phase", function()
  local function pullAndArrive()
    fixture(3)
    S.onTick()
    S.decorate("attack", ";")
    MAP.current = 100 -- arrived in the funnel room
    mobs = 0
    S.onTick() -- pulling -> funnel
  end

  it("enters funnel on arrival, clears the hold, and quicklooks", function()
    pullAndArrive()
    expect(S.state).toBe("funnel")
    expect(ataxiaTemp.swarmHold).toBe(nil)
    expect(sent[#sent]).toBe("ql")
  end)
  it("holds navigation while followers are being fought", function()
    pullAndArrive()
    mobs = 2
    expect(S.onTick()).toBeTrue()
    expect(S.peakFollowers).toBe(2)
    expect(S.state).toBe("funnel")
  end)
  it("holds navigation through the empty follow window", function()
    pullAndArrive()
    mobs = 0
    expect(S.onTick()).toBeTrue()
    expect(S.state).toBe("funnel")
    expect(#scheduled > 0).toBeTrue() -- re-check scheduled for the window end
  end)
  it("re-enters the swarm room once the window expires", function()
    pullAndArrive()
    mobs = 0
    clock = clock + 10 -- well past FOLLOW_WINDOW
    expect(S.onTick()).toBeTrue()
    expect(S.state).toBe("reenter")
    expect(armed[#armed]).toBe("n") -- forward = original entry direction
    expect(sent[#sent]).toBe("queue addclear free stand;leap n") -- tactical moves always LEAP (wall-safe)
  end)
  it("resets if we somehow end up in a third room", function()
    pullAndArrive()
    MAP.current = 300
    expect(S.onTick()).toBeFalse()
    expect(S.state).toBe("idle")
  end)
end)

describe("swarm reenter -> re-assess", function()
  it("re-assesses the swarm room and pulls again while still crowded", function()
    fixture(3)
    S.onTick(); S.decorate("attack", ";")
    MAP.current = 100; mobs = 0; S.onTick() -- funnel
    clock = clock + 10; S.onTick()          -- reenter
    MAP.current = 200; mobs = 3             -- back in, still 3 mobs
    expect(S.onTick()).toBeTrue()           -- pull #2 begins
    expect(S.state).toBe("pulling")
    expect(S.pulls[200]).toBe(2)
  end)
  it("hands back to the normal fight when the room thinned out", function()
    fixture(3)
    S.onTick(); S.decorate("attack", ";")
    MAP.current = 100; mobs = 0; S.onTick()
    clock = clock + 10; S.onTick()
    MAP.current = 200; mobs = 2
    expect(S.onTick()).toBeFalse() -- below threshold: normal explorer flow fights here
    expect(S.state).toBe("idle")
  end)
end)

describe("swarm stage 2 — icewall (indoors)", function()
  it("routes to wall mode indoors and decorates with point+leap in one entry", function()
    fixture(3)
    gmcp.Room.Info.details = { "indoors" }
    expect(S.onTick()).toBeTrue()
    expect(S.state).toBe("pulling")
    expect(S.mode).toBe("wall")
    local cmd = S.decorate("attack", ";")
    expect(cmd).toBe("attack;point bracers417868 south;leap s")
  end)

  it("holds through the longer wall window", function()
    fixture(3)
    gmcp.Room.Info.details = { "indoors" }
    S.onTick(); S.decorate("attack", ";")
    MAP.current = 100; mobs = 0; S.onTick() -- funnel behind the wall
    clock = clock + 5 -- past FOLLOW_WINDOW, inside WALL_WINDOW
    expect(S.onTick()).toBeTrue()
    expect(S.state).toBe("funnel")
  end)

  it("re-enters by LEAPING our own wall -- the icewall stays up", function()
    fixture(3)
    gmcp.Room.Info.details = { "indoors" }
    S.onTick(); S.decorate("attack", ";")
    MAP.current = 100; mobs = 0; S.onTick()
    clock = clock + 20 -- past WALL_WINDOW
    S.onTick()
    expect(S.state).toBe("reenter")
    expect(sent[#sent]).toBe("queue addclear free stand;leap n")
    expect(S.wallRaised[200]).toBe("south") -- wall memory (the walled edge) survives the cycle
  end)

  it("goes leap-only on the next escape while our wall still stands", function()
    fixture(3)
    gmcp.Room.Info.details = { "indoors" }
    S.onTick()
    expect(S.decorate("attack", ";")).toBe("attack;point bracers417868 south;leap s")
    MAP.current = 100; mobs = 0; S.onTick()  -- funnel
    clock = clock + 20; S.onTick()           -- reenter (leap back in)
    MAP.current = 200; mobs = 3
    S.onTick()                                -- re-assess: pull #2, wall still up
    expect(S.decorate("attack", ";")).toBe("attack;leap s") -- no point: eq-only escape
  end)

  it("melts the wall once the room is done: hold armed, cleared only on CONFIRMATION", function()
    fixture(3)
    gmcp.Room.Info.details = { "indoors" }
    S.onTick(); S.decorate("attack", ";")
    MAP.current = 100; mobs = 0; S.onTick()
    clock = clock + 20; S.onTick()           -- reenter
    MAP.current = 200; mobs = 0              -- back in, everything is dead
    expect(S.onTick()).toBeTrue()            -- consumed: the melt must not be wiped by a nav move
    expect(sent[#sent]).toBe("queue addclear free point bracers151113 at icewall")
    expect(ataxiaTemp.swarmHold).toBeTrue()  -- a roamer's addclearfull must not wipe the queued melt
    expect(S.wallRaised[200]).toBe("south")  -- NOT cleared optimistically (review HIGH)
    S.onWallMelted()                          -- "You send a lash of fire..." landed
    expect(S.wallRaised[200]).toBe(nil)
    expect(ataxiaTemp.swarmHold).toBe(nil)
    expect(S.onTick()).toBeFalse()           -- next tick hands navigation back
  end)

  it("re-sends a wiped/whiffed melt, then gives up after bounded retries", function()
    fixture(0)
    S.wallRaised[200] = "south"
    MAP.current = 200
    local melts = 0
    for _ = 1, 4 do
      expect(S.onTick()).toBeTrue()          -- each attempt consumes the tick + re-sends
    end
    for _, c in ipairs(sent) do
      if c == "queue addclear free point bracers151113 at icewall" then melts = melts + 1 end
    end
    expect(melts).toBe(4)
    expect(S.onTick()).toBeFalse()           -- budget spent: leave it to the wall-leap reflex
    expect(S.wallRaised[200]).toBe(nil)
  end)

  it("never melts from a DIFFERENT room (memory retained)", function()
    fixture(0)
    S.wallRaised[200] = "south"
    MAP.current = 100
    expect(S.onTick()).toBeFalse()
    expect(S.wallRaised[200]).toBe("south")
    local sawMelt = false
    for _, c in ipairs(sent) do if c:find("bracers151113", 1, true) then sawMelt = true end end
    expect(sawMelt).toBeFalse()
  end)

  it("reset PRESERVES wall memory (the wall is physical)", function()
    fixture(3)
    S.wallRaised[200] = "south"
    S.state = "funnel"
    S.reset("test")
    expect(S.wallRaised[200]).toBe("south")
  end)

  it("keeps wall memory on a same-ripple restart, wipes on a genuine new ripple", function()
    fixture(3)
    S.wallRaised[200] = "south"
    S._wallsRipple = 1                        -- raised during ripple 1
    S.onRipple()                              -- mnem explore off/on mid-ripple (still ripple 1)
    expect(S.wallRaised[200]).toBe("south")
    M.run.ripple = 2
    S.onRipple()                              -- genuine boundary: fresh layout
    expect(S.wallRaised[200]).toBe(nil)
  end)

  it("panic tumble avoids the walled edge in a fight-in-place room", function()
    fixture(4)
    S.noTactics[200] = true                   -- pulls exhausted; wall on the south edge
    S.wallRaised[200] = "south"
    MAP.rooms[200].exits.east = 60
    mnemRollHide = true
    S._lastPanicAt = nil
    ataxia.vitals = { hpp = 30 }
    expect(S.onTick()).toBeTrue()
    local sawEast, sawSouth = false, false
    for _, c in ipairs(sent) do
      if c:find("tumble e", 1, true) then sawEast = true end
      if c:find("tumble s", 1, true) then sawSouth = true end
    end
    expect(sawEast).toBeTrue()                -- never tumble INTO our own wall
    expect(sawSouth).toBeFalse()
  end)
end)

-- ROLL HIDE PANIC, v4.7.202. Two user-driven changes: an ABSOLUTE hp floor beside the
-- percentage ("we are entering critical health, like 3000"), and tumbling specifically
-- back into the room we just cleared ("we should tumble out into the room we just cleared")
-- -- the one place on the grid known to be empty, and with Roll Hide shedding every pursuer
-- we arrive there alone.
describe("Roll Hide panic -- absolute hp floor", function()
  it("fires on the PERCENTAGE as before", function()
    fixture(4); mnemRollHide = true; S._lastPanicAt = nil
    local sc = S._cfg(); sc.panicAt, sc.panicHp = 40, 0
    ataxia.vitals = { hpp = 39, hp = 99999 }
    expect(S._panicHpHit(39)).toBeTrue()
    expect(S._panicHpHit(41)).toBeFalse()
  end)

  it("fires on the ABSOLUTE floor even while the percentage is comfortable", function()
    fixture(4); local sc = S._cfg(); sc.panicAt, sc.panicHp = 40, 3000
    -- 3000 of a 60k pool is 5% -- but a huge max HP means 40% is still 24000, so the
    -- percentage alone would not fire until long after 3000 became lethal.
    ataxia.vitals = { hpp = 80, hp = 2900 }
    expect(S._panicHpHit(80)).toBeTrue()
    ataxia.vitals = { hpp = 80, hp = 3100 }
    expect(S._panicHpHit(80)).toBeFalse()
  end)

  it("either line is enough -- whichever is crossed first", function()
    fixture(4); local sc = S._cfg(); sc.panicAt, sc.panicHp = 40, 3000
    ataxia.vitals = { hpp = 20, hp = 50000 } -- percentage only
    expect(S._panicHpHit(20)).toBeTrue()
    ataxia.vitals = { hpp = 90, hp = 100 }   -- absolute only
    expect(S._panicHpHit(90)).toBeTrue()
  end)

  it("a blackout/unknown hp reading never FAKES a panic", function()
    fixture(4); local sc = S._cfg(); sc.panicAt, sc.panicHp = 40, 3000
    ataxia.vitals = { hpp = 90, hp = 0 }
    expect(S._panicHpHit(90)).toBeFalse()
    ataxia.vitals = { hpp = 90 }
    expect(S._panicHpHit(90)).toBeFalse()
  end)

  it("panicHp 0 disables the floor and leaves the percentage alone", function()
    fixture(4); local sc = S._cfg(); sc.panicAt, sc.panicHp = 40, 0
    ataxia.vitals = { hpp = 90, hp = 1 }
    expect(S._panicHpHit(90)).toBeFalse()
  end)
end)

describe("Roll Hide panic -- tumble back into the cleared room", function()
  it("prefers the validated back-route, not just any exit", function()
    fixture(4)
    MAP.rooms[200].exits.east = 60      -- an unexplored alternative
    mnemRollHide = true; S._lastPanicAt = nil
    local back = select(1, S._backDir())
    expect(back ~= nil).toBeTrue()
    expect(S._panicDir()).toBe(back)    -- the cleared room wins over the unknown exit
  end)

  it("still refuses to tumble into our OWN icewall", function()
    fixture(4)
    local back, longBack = S._backDir()
    S.wallRaised[200] = longBack        -- the icewall sits on exactly the back edge
    MAP.rooms[200].exits.east = 60
    expect(S._panicDir() ~= back).toBeTrue() -- falls through to the heuristic
  end)

  it("falls back to a heuristic exit when there is no back-route at all", function()
    fixture(4)
    M.explore.fromRoom = nil            -- no validated route home
    MAP.rooms[200].exits.east = 60
    expect(S._panicDir() ~= nil).toBeTrue()
  end)
end)

-- BRAVADO affix (v4.7.206): "perpetually reckless and unable to benefit from shields,
-- prismatic barriers, or blood barriers". It removes our mitigations rather than adding a
-- threat, so the hit-and-run becomes the ONLY one left -- user rule: pull at 2 denizens
-- instead of 3, because "we will never know our health pool".
describe("Bravado clamps the hit-and-run threshold", function()
  it("leaves the threshold alone when the affix is off", function()
    fixture(3); mnemBravado = false
    local sc = S._cfg(); sc.threshold = 3; sc.deepAt, sc.deepThreshold = nil, nil
    expect(S.threshold()).toBe(3)
  end)

  it("pulls 3 down to 2 while the affix is up", function()
    fixture(3); mnemBravado = true
    local sc = S._cfg(); sc.threshold = 3; sc.deepAt, sc.deepThreshold = nil, nil
    expect(S.threshold()).toBe(2)
    mnemBravado = false
  end)

  it("clamps DOWN only -- never raises a threshold already at 2", function()
    fixture(3); mnemBravado = true
    local sc = S._cfg(); sc.threshold = 2; sc.deepAt, sc.deepThreshold = nil, nil
    expect(S.threshold()).toBe(2)
    mnemBravado = false
  end)

  it("also clamps the DEEP-ripple threshold, not just the base one", function()
    fixture(3); mnemBravado = true
    local sc = S._cfg()
    sc.threshold, sc.deepAt, sc.deepThreshold = 5, 25, 4
    M.run.ripple = 30
    expect(S.threshold()).toBe(2)
    mnemBravado = false
  end)

  it("is configurable", function()
    fixture(3); mnemBravado = true
    local sc = S._cfg()
    sc.threshold, sc.bravadoThreshold = 4, 3
    sc.deepAt, sc.deepThreshold = nil, nil
    expect(S.threshold()).toBe(3)
    sc.bravadoThreshold = 2
    mnemBravado = false
  end)
end)

describe("swarm stage 2 — fly-kite (outdoors)", function()
  local function swarmFollowed()
    fixture(3)
    S.onTick(); S.decorate("attack", ";")
    MAP.current = 100; mobs = 0; S.onTick() -- funnel
    mobs = 3 -- the whole swarm chased us
    S.onTick()
  end

  it("takes off when the swarm follows outdoors", function()
    swarmFollowed()
    expect(S.flying).toBeTrue()
    expect(sent[#sent]).toBe("queue addclear free stand;fly")
  end)

  it("wraps every attack in land/fly while flying", function()
    swarmFollowed()
    expect(S.decorate("attack", ";")).toBe("land;attack;fly")
  end)

  it("lands once the room thins below threshold", function()
    swarmFollowed()
    mobs = 2
    S.onTick()
    expect(S.flying).toBe(nil)
    expect(sent[#sent]).toBe("land")
  end)

  it("never kites in wall mode / indoors", function()
    fixture(3)
    gmcp.Room.Info.details = { "indoors" }
    S.onTick(); S.decorate("attack", ";")
    MAP.current = 100; mobs = 3
    S.onTick()
    expect(S.flying).toBe(nil)
  end)

  it("lands on reset so flight never leaks into the next context", function()
    swarmFollowed()
    S.reset("test")
    expect(S.flying).toBe(nil)
    local sawLand = false
    for _, c in ipairs(sent) do if c == "land" then sawLand = true end end
    expect(sawLand).toBeTrue()
  end)
end)

describe("swarm stage 2 — Roll Hide panic", function()
  local TUMBLE = "queue addclear free stand;tumble w"

  local function findCmd(needle)
    for i, c in ipairs(sent) do if c == needle then return i end end
    return nil
  end

  it("tumbles out (free-queued) at panic HP with the boon up, then resets", function()
    fixture(3)
    S.onTick(); S.decorate("attack", ";")
    MAP.current = 100; mobs = 2; S.onTick() -- funnel, fighting followers
    MAP.rooms[100].exits.west = 50 -- an escape exit away from the swarm room
    mnemRollHide = true
    ataxia.vitals = { hpp = 30 }
    S._lastPanicAt = nil
    expect(S.onTick()).toBeTrue()
    -- REQUIREMENT CHANGED v4.7.218: the tumble used to drop to `idle`, which handed straight
    -- back to the explorer and walked us into the room we had just fled once the hold expired
    -- (~8s), still at panic HP. Roll Hide's value is that the room we land in is QUIET; we now
    -- heal there first. This is a deliberate behaviour change, not a test bent to pass.
    expect(S.state).toBe("recovering")
    expect(S.recoverGround).toBeTrue()
    expect(findCmd(TUMBLE) ~= nil).toBeTrue()
    -- The hold must guard the queued tumble from the next attack's addclearfull.
    expect(ataxiaTemp.swarmHold).toBeTrue()
  end)

  it("LANDS before tumbling when the panic fires mid-kite", function()
    fixture(3)
    S.onTick(); S.decorate("attack", ";")
    MAP.current = 100; mobs = 0; S.onTick() -- funnel
    mobs = 3; S.onTick()                    -- swarm followed outdoors -> flying
    expect(S.flying).toBeTrue()
    MAP.rooms[100].exits.west = 50
    mnemRollHide = true
    ataxia.vitals = { hpp = 30 }
    S._lastPanicAt = nil
    expect(S.onTick()).toBeTrue()
    expect(S.flying).toBe(nil)
    local landAt, tumbleAt = findCmd("land"), findCmd(TUMBLE)
    expect(landAt ~= nil).toBeTrue()
    expect(tumbleAt ~= nil).toBeTrue()
    expect(landAt < tumbleAt).toBeTrue() -- ground FIRST, tumble second
  end)

  it("covers the fight-in-place fallback (idle state, crowded no-tactics room)", function()
    fixture(4)
    S.noTactics[200] = true -- pulls exhausted: we are standing in the crowd
    MAP.rooms[200].exits.east = 60 -- an escape exit
    mnemRollHide = true
    ataxia.vitals = { hpp = 30 }
    S._lastPanicAt = nil
    expect(S.onTick()).toBeTrue()
    local sawTumble = false
    for _, c in ipairs(sent) do if c:find("tumble", 1, true) then sawTumble = true end end
    expect(sawTumble).toBeTrue()
  end)

  it("does not panic without the boon or above the threshold", function()
    fixture(3)
    S.onTick(); S.decorate("attack", ";")
    MAP.current = 100; mobs = 2; S.onTick()
    -- 38%: inside panic's 40% window but ABOVE the 35% escape ladder, so this isolates
    -- the boon gate (at <=35% the low-HP escape correctly takes over regardless).
    ataxia.vitals = { hpp = 38 } -- low-ish HP but no boon
    S.onTick()
    expect(S.state).toBe("funnel")
    mnemRollHide = true
    ataxia.vitals = { hpp = 90 } -- boon but healthy
    S.onTick()
    expect(S.state).toBe("funnel")
  end)
end)

describe("swarm stage 2 — kite wrap room guard", function()
  it("does not wrap attacks after a forced move left the funnel room", function()
    fixture(3)
    S.onTick(); S.decorate("attack", ";")
    MAP.current = 100; mobs = 0; S.onTick()
    mobs = 3; S.onTick() -- flying in the funnel
    MAP.current = 300    -- forced/manual move elsewhere
    expect(S.decorate("attack", ";")).toBe("attack")
    MAP.current = 100
    expect(S.decorate("attack", ";")).toBe("land;attack;fly")
  end)
end)

describe("swarm low-HP escape ladder", function()
  local function findCmd(needle)
    for i, c in ipairs(sent) do if c == needle then return i end end
    return nil
  end

  it("flies to recover outdoors at escape HP (any mob count) and gates attacks", function()
    fixture(2) -- BELOW the swarm threshold: the cave-bat death had only two mobs
    ataxia.vitals = { hpp = 30 }
    expect(S.onTick()).toBeTrue()
    expect(S.state).toBe("recovering")
    expect(S.flying).toBeTrue()
    expect(findCmd("queue addclear free stand;fly") ~= nil).toBeTrue()
    expect(ataxiaTemp.swarmHold).toBeTrue()
  end)

  it("keeps hovering until FULLY healed (95%+ AND aff-free), then lands", function()
    fixture(2)
    ataxia.vitals = { hpp = 30 }
    S.onTick() -- recovering
    ataxia.vitals = { hpp = 80 } -- healthier but below the 95% bar
    expect(S.onTick()).toBeTrue()
    expect(S.state).toBe("recovering")
    ataxia.vitals = { hpp = 96 }
    ataxia.afflictions = { crippledrightarm = true } -- healed HP, limb still broken
    expect(S.onTick()).toBeTrue()
    expect(S.state).toBe("recovering") -- restoration must finish first
    ataxia.afflictions = { blindness = true, deafness = true } -- kept defences never hold us
    -- Landing CONSUMES the tick and settles (live catch 2026-07-27: airborne gmcp
    -- Items reflect the SKY, so denizensHere is empty -- deciding now would read a
    -- mob-filled ground room as "clear" and walk out of the fight on touchdown).
    -- DIAGNOSE FIRST (v4.7.233): the first tick that believes we are clean sends `diagnose`
    -- and waits one more, because S._afflicted() reads client-side tracking -- the thing that
    -- is least reliable straight after a chaotic fight. One extra tick per recovery.
    expect(S.onTick()).toBeTrue()
    expect(S.state).toBe("recovering")
    expect(findCmd("diagnose") ~= nil).toBeTrue()
    expect(S.onTick()).toBeTrue()
    expect(S.state).toBe("idle")
    expect(S.flying).toBe(nil)
    expect(findCmd("land") ~= nil).toBeTrue()
    expect(ataxiaTemp.swarmHold).toBe(nil)
    expect(M.explore.settling).toBeTrue() -- the land's Room/Items push decides next
    expect(#scheduled > 0).toBeTrue()     -- no-event backstop tick armed
    M.explore.settling = false
  end)

  it("lands with PARKED afflictions up -- the bash curing profile decided not to cure them", function()
    -- The PvE curing profile (ataxia/008) parks the junk mental spray at priority 25 so
    -- it cannot outbid a potash for the eating balance. Those affs therefore stay up for
    -- the rest of the fight -- and an unmodified aff-free test would hold every hover to
    -- its RECOVER_MAX cap waiting on a paranoia nobody is curing. A parked affliction is
    -- one we have DECIDED not to cure; only a REAL one may hold the hover.
    fixture(2)
    ataxia.vitals = { hpp = 30 }
    S.onTick() -- recovering
    ataxia.vitals = { hpp = 96 }
    ataxia.settings.bashcuring = { active = true }
    ataxia.afflictions = { paranoia = true, shyness = true, crippledrightarm = true }
    expect(S.onTick()).toBeTrue()
    expect(S.state).toBe("recovering") -- the BROKEN LIMB is real and still holds us
    ataxia.afflictions = { paranoia = true, shyness = true } -- only parked affs left
    expect(S.onTick()).toBeTrue()      -- diagnose tick (v4.7.233)
    expect(S.onTick()).toBeTrue()
    expect(S.state).toBe("idle")       -- lands rather than floating to the cap
    expect(findCmd("land") ~= nil).toBeTrue()
    ataxia.settings.bashcuring.active = false
    M.explore.settling = false
  end)

  it("still holds the hover for parked affs when the bash profile is OFF (PvP unchanged)", function()
    fixture(2)
    ataxia.vitals = { hpp = 30 }
    S.onTick()
    ataxia.vitals = { hpp = 96 }
    ataxia.settings.bashcuring = { active = false }
    ataxia.afflictions = { paranoia = true }
    expect(S.onTick()).toBeTrue()
    expect(S.state).toBe("recovering")
  end)

  it("lands at the hard cap even if never healed -- also settling, never deciding blind", function()
    fixture(2)
    ataxia.vitals = { hpp = 30 }
    S.onTick()
    clock = clock + 120 -- past RECOVER_MAX
    expect(S.onTick()).toBeTrue() -- consumed: settle on real ground data first
    expect(S.state).toBe("idle")
    expect(S.flying).toBe(nil)
    expect(M.explore.settling).toBeTrue()
    M.explore.settling = false
  end)

  it("retreats to the cleared room indoors (no fly available) -- by LEAP", function()
    fixture(2)
    gmcp.Room.Info.details = { "indoors" }
    ataxia.vitals = { hpp = 30 }
    expect(S.onTick()).toBeTrue()
    expect(S.state).toBe("pulling")
    expect(ataxiaTemp.swarmPullDir).toBe(nil) -- plain retreat, no swing decorator
    -- LEAP, not walk: the retreat may cross our OWN standing icewall (review
    -- CRITICAL -- a walk silently fails there and the escape ladder livelocks).
    expect(sent[#sent]).toBe("queue addclear free stand;leap s")
  end)

  it("leaves shield-in-place as the fallback indoors with no route", function()
    fixture(2)
    gmcp.Room.Info.details = { "indoors" }
    M.explore.fromDir = "d" -- no valid back-route
    ataxia.vitals = { hpp = 30 }
    expect(S.onTick()).toBeFalse()
    expect(S.state).toBe("idle")
  end)

  it("Deluge (underwater): the OUTDOOR escape goes grounded -- retreat, never fly", function()
    fixture(2)
    mnemDeluge = true -- "All rooms are underwater." -- FLY is impossible (v4.7.140)
    ataxia.vitals = { hpp = 30 }
    expect(S.onTick()).toBeTrue()
    expect(S.state).toBe("pulling") -- the grounded retreat branch, outdoors
    expect(S.flying).toBe(nil)
    expect(findCmd("queue addclear free stand;fly")).toBe(nil)
    expect(sent[#sent]).toBe("queue addclear free stand;leap s")
    mnemDeluge = false
  end)

  it("converts an active kite to a hover without land/fly churn", function()
    fixture(3)
    S.onTick(); S.decorate("attack", ";")
    MAP.current = 100; mobs = 0; S.onTick()
    mobs = 3; S.onTick() -- kiting
    local flyCount = 0
    for _, c in ipairs(sent) do if c == "queue addclear free stand;fly" then flyCount = flyCount + 1 end end
    ataxia.vitals = { hpp = 30 }
    expect(S.onTick()).toBeTrue()
    expect(S.state).toBe("recovering")
    expect(S.flying).toBeTrue()
    local flyCount2 = 0
    for _, c in ipairs(sent) do if c == "queue addclear free stand;fly" then flyCount2 = flyCount2 + 1 end end
    expect(flyCount2).toBe(flyCount) -- no second fly sent
  end)

  it("does nothing when escape is configured off", function()
    fixture(2)
    cfg.swarm.escape = false
    ataxia.vitals = { hpp = 30 }
    expect(S.onTick()).toBeFalse()
    expect(S.state).toBe("idle")
  end)
end)

describe("swarm reset + lifecycle", function()
  it("reset clears hold, armed decorator, and state, and flushes the queue", function()
    fixture(3)
    S.onTick()
    ataxiaTemp.swarmHold = true
    S.reset("test")
    expect(S.state).toBe("idle")
    expect(ataxiaTemp.swarmPullDir).toBe(nil)
    expect(ataxiaTemp.swarmHold).toBe(nil)
    expect(sent[#sent]).toBe("cq all")
  end)
  it("onRipple clears pull budgets and no-tactics marks", function()
    fixture(3)
    S.pulls[200] = 2; S.noTactics[300] = true
    S.onRipple()
    expect(S.pulls[200]).toBe(nil)
    expect(S.noTactics[300]).toBe(nil)
  end)
  -- REQUIREMENT CHANGED v4.7.235: a lost move is now RETRIED before we fall back to idle.
  -- Going idle relied on the next tick re-deciding, and the explorer tick is EVENT-driven --
  -- in a stationary slugfest almost nothing fires it. Against Seasone that gap was FOURTEEN
  -- SECONDS, by which point both legs were broken and every action was refused.
  it("onMoveFailed retries the move, then falls back to idle", function()
    fixture(3)
    S.onTick()
    S.onMoveFailed()
    expect(S.state).toBe("pulling")            -- retry #1 in flight
    S.onMoveFailed()
    expect(S.state).toBe("pulling")            -- retry #2
    S.onMoveFailed()
    expect(S.state).toBe("idle")               -- budget spent: hand back, condemn nothing
    expect(S.noTactics[200]).toBe(nil)
  end)

  it("re-arms the hold on each retry, so the attack cannot eat it either", function()
    fixture(3)
    S.onTick()
    ataxiaTemp.swarmHold = nil
    S.onMoveFailed()
    expect(ataxiaTemp.swarmHold).toBeTrue()
  end)
  it("sense stores raw recon lines", function()
    fixture(0)
    S.sense("test")
    expect(S.recon ~= nil).toBeTrue()
    expect(#S.recon.lines).toBe(2)
  end)
  it("passes through un-decorated after a forced move left the swarm room mid-arm", function()
    fixture(3)
    S.onTick()
    MAP.current = 300 -- forced/manual move before the swing came
    expect(S.decorate("attack", ";")).toBe("attack")
    expect(ataxiaTemp.swarmPullDir).toBe("s") -- still armed; the fallback handles it
    MAP.current = 200
  end)

  it("onGo schedules recon only with Sleuth up, swarm enabled, and in the tower", function()
    fixture(0)
    ataxiaBasher.inMnemosyne = true
    mnemSleuth = false
    expect(S.onGo()).toBeFalse()
    mnemSleuth = true
    cfg.swarm.enabled = false
    expect(S.onGo()).toBeFalse()
    cfg.swarm.enabled = true
    ataxiaBasher.inMnemosyne = false
    expect(S.onGo()).toBeFalse()
    ataxiaBasher.inMnemosyne = true
    expect(S.onGo()).toBeTrue() -- scheduled (delayed past the GO burst)
    mnemSleuth = false
  end)
end)

describe("vitals-driven emergency wake-up", function()
  local function findCmd(needle)
    for i, c in ipairs(sent) do if c == needle then return i end end
    return nil
  end

  it("fires the escape mid-pull, killing the in-flight move and the queued chain", function()
    fixture(3)
    S.onTick(); S.decorate("attack", ";") -- pull chain queued, hold armed, move in flight
    gmcp.Char = { Vitals = { hp = "3000", maxhp = "10000" } }
    S.onVitals()
    expect(S.state).toBe("recovering")
    expect(S.flying).toBeTrue()
    expect(disarmed > 0).toBeTrue() -- explorer move machinery released, no condemn
    expect(findCmd("cq all") ~= nil).toBeTrue() -- the queued pull chain is dead
    expect(findCmd("queue addclear free stand;fly") ~= nil).toBeTrue()
    expect(ataxiaTemp.swarmHold).toBeTrue()
  end)

  it("reads the FRESH gmcp payload, not the possibly-stale shared vitals", function()
    fixture(2)
    ataxia.vitals = { hpp = 100 } -- the shared table has not been updated yet
    gmcp.Char = { Vitals = { hp = "2800", maxhp = "11500" } }
    S.onVitals()
    expect(S.state).toBe("recovering")
  end)

  it("prefers the Roll Hide panic over the escape when the boon is up", function()
    fixture(4)
    S.noTactics[200] = true -- fight-in-place: the exact Pinnacle situation
    MAP.rooms[200].exits.east = 60
    mnemRollHide = true
    S._lastPanicAt = nil
    gmcp.Char = { Vitals = { hp = "3000", maxhp = "10000" } }
    S.onVitals()
    local sawTumble = false
    for _, c in ipairs(sent) do if c:find("tumble", 1, true) then sawTumble = true end end
    expect(sawTumble).toBeTrue()
    -- Recovers on the GROUND where it landed (v4.7.218), not in a hover: we landed to tumble.
    expect(S.state).toBe("recovering")
    expect(S.recoverGround).toBeTrue()
    expect(S.flying).toBe(nil)
  end)

  it("rate-limits repeat firings", function()
    fixture(2)
    gmcp.Char = { Vitals = { hp = "3000", maxhp = "10000" } }
    S.onVitals()
    S.reset("test")
    local n = #sent
    S.onVitals() -- same clock: inside EMERGENCY_COOLDOWN
    expect(#sent).toBe(n)
    expect(S.state).toBe("idle")
  end)

  it("stays quiet when healthy, blacked out, or disabled", function()
    fixture(2)
    gmcp.Char = { Vitals = { hp = "9000", maxhp = "10000" } }
    S.onVitals()
    expect(S.state).toBe("idle") -- healthy
    gmcp.Char = { Vitals = { hp = "0", maxhp = "10000" } }
    S.onVitals()
    expect(S.state).toBe("idle") -- blackout sentinel: hp 0 is "unknown", not "dying"
    gmcp.Char = { Vitals = { hp = "3000", maxhp = "10000" } }
    M.explore.on = false
    S.onVitals()
    expect(S.state).toBe("idle") -- disabled
  end)
end)

describe("pull retry after a lost move", function()
  it("restores the route anchor so the reassess can pull again", function()
    fixture(3)
    S.onTick(); S.decorate("attack", ";") -- pull #1 armed + consumed
    -- The tactical arm clobbered the explorer's anchor with the pull itself:
    M.explore.fromRoom, M.explore.fromDir = 200, "s"
    S.onMoveFailed() -- the step-out was eaten (stupidity); we never left room 200
    -- Retries first (v4.7.235), then hands back. The anchor restore still has to happen on
    -- the FIRST failure -- it is what stops the eventual reassess latching noTactics on the
    -- room that most needs tactics.
    expect(M.explore.fromRoom).toBe(100) -- anchor restored from the tactic's own route
    expect(M.explore.fromDir).toBe("n")
    S.onMoveFailed(); S.onMoveFailed()    -- spend the retry budget
    expect(S.state).toBe("idle")
    expect(S.onTick()).toBeTrue() -- reassess: pull #2, not a noTactics latch
    expect(S.state).toBe("pulling")
    expect(S.pulls[200]).toBe(2)
    expect(S.noTactics[200]).toBe(nil)
  end)

  it("still latches no-tactics once MAX_PULLS is spent on eaten moves", function()
    fixture(3)
    for _ = 1, 3 do
      expect(S.onTick()).toBeTrue()
      S.decorate("attack", ";")
      M.explore.fromRoom, M.explore.fromDir = 200, "s"
      S.onMoveFailed(); S.onMoveFailed(); S.onMoveFailed() -- retries then idle (v4.7.235)
    end
    expect(S.onTick()).toBeFalse()
    expect(S.noTactics[200]).toBeTrue()
  end)

  it("does not restore the anchor if a forced move took us elsewhere", function()
    fixture(3)
    S.onTick(); S.decorate("attack", ";")
    MAP.current = 300 -- forced move mid-chain
    M.explore.fromRoom, M.explore.fromDir = 300, "e"
    S.onMoveFailed()
    expect(M.explore.fromRoom).toBe(300) -- left alone: the saved route is for room 200
  end)
end)

describe("hit-and-run continuation (progress refunds the pull budget)", function()
  -- One full pull cycle ending back in the swarm room, ready to re-assess.
  local function pullCycle()
    S.onTick()                 -- (re)assess -> pull begins
    S.decorate("attack", ";")
    MAP.current = 100; mobs = 0
    S.onTick()                 -- funnel
    clock = clock + 10
    S.onTick()                 -- reenter
    MAP.current = 200
  end

  it("refunds the budget when a kill dropped the count", function()
    fixture(4)
    pullCycle()                -- snapshot: n=4
    mobs = 3                   -- one died to the pull swing
    expect(S.onTick()).toBeTrue()
    expect(S.state).toBe("pulling")
    expect(S.pulls[200]).toBe(1) -- refreshed, not 2: the loop keeps going
  end)

  it("refunds when the same focused target got chipped lower", function()
    fixture(3)
    target = 777
    ataxiaBasher_dsGet = function(id) return id == 777 and { hpp = 94 } or nil end
    pullCycle()                -- snapshot: n=3, id=777, hp=94
    mobs = 3                   -- nobody died...
    ataxiaBasher_dsGet = function(id) return id == 777 and { hpp = 71 } or nil end
    expect(S.onTick()).toBeTrue() -- ...but the soldier is 23% lower: progress
    expect(S.pulls[200]).toBe(1)
    target = nil; ataxiaBasher_dsGet = nil
  end)

  it("spends budget on unproductive cycles and still caps at MAX_PULLS", function()
    fixture(3)
    for _ = 1, 3 do
      pullCycle()              -- no kills, no target data: nothing improved
      mobs = 3
    end
    expect(S.pulls[200]).toBe(3)
    expect(S.onTick()).toBeFalse() -- budget spent -> fight in place
    expect(S.noTactics[200]).toBeTrue()
  end)
end)

describe("S._targetHp gmcp fallback", function()
  it("parses a percent-suffixed live hpperc (gsub multi-return trap regression)", function()
    fixture(3)
    target = 777
    ataxiaBasher_dsGet = nil -- no denizen-state: force the live-GMCP fallback path
    gmcp.IRE = { Target = { Info = { hpperc = "66%" } } }
    local id, hp = S._targetHp()
    expect(id).toBe(777)
    expect(hp).toBe(66) -- tonumber(str, count) would have thrown "base out of range"
    gmcp.IRE = nil
    target = nil
  end)
end)

describe("Bloodscent recon parser", function()
  it("parses sense rows into per-room counts (crowded-room detection)", function()
    fixture(0)
    ataxiaBasher.inMnemosyne = true
    S.onSenseStart()
    S.onSenseRow("a shadowy basilisk", "371988", "Beneath an ancient tree")
    S.onSenseRow("a fearsome lion", "419157", "Beneath an ancient tree")
    S.onSenseRow("a savage boar", "476131", "Among moss-coated trees")
    S.onSenseRow("a fearsome lion", "441807", "Beneath an ancient tree")
    S._senseCommit()
    expect(#S.recon.mobs).toBe(4)
    expect(S.recon.byRoom["Beneath an ancient tree"]).toBe(3) -- >= threshold: crowded
    expect(S.recon.byRoom["Among moss-coated trees"]).toBe(1)
    expect(S.recon.ripple).toBe(1)
    ataxiaBasher.inMnemosyne = false
  end)

  it("ignores sense lines outside the tower", function()
    fixture(0)
    ataxiaBasher.inMnemosyne = false
    S.onSenseStart()
    S.onSenseRow("a rat", "1", "Somewhere")
    expect(S._senseRows).toBe(nil)
    S.recon = nil
    S._senseCommit()
    expect(S.recon).toBe(nil)
  end)
end)

describe("flight confirmation for the recovery hover", function()
  local function flyCount()
    local n = 0
    for _, c in ipairs(sent) do if c == "queue addclear free stand;fly" then n = n + 1 end end
    return n
  end

  it("re-sends the fly each recovery tick until the flight line confirms", function()
    fixture(2)
    ataxia.vitals = { hpp = 30 }
    S.onTick() -- recovering; first fly sent
    expect(flyCount()).toBe(1)
    S.onTick() -- still unconfirmed: the fly was eaten -> re-send
    expect(flyCount()).toBe(2)
    S.onFlightUp() -- "The ring of shining metal carries you up into the skies."
    S.onTick()
    expect(flyCount()).toBe(2) -- confirmed: no more re-sends
    S.onFlightDown() -- forced/incidental landing mid-hover
    S.onTick()
    expect(flyCount()).toBe(3) -- grounded again -> re-send
  end)
end)

-- ROLL HIDE, the point of it (user, 2026-08-06): "the denizens wont follow so we can use this
-- to our advantage to heal up and then do hit and run tactics". The tumble was only ever half
-- the tactic -- shedding pursuers is worth nothing if we walk straight back in.
-- A TUMBLE THAT NEVER LANDED (v4.7.233). Death log, 2026-08-07: "You begin to tumble agilely
-- to the north." then paralysis, then still in the room, then dead. That line is the START of
-- a two-stage action; paralysis, prone or a stun between the halves cancels it. Nothing
-- checked, and the panic tumble is the one move the anti-death ladder depends on.
--
-- Confirmation is the ROOM CHANGING, not a success line -- the game prints several depending
-- on how the tumble ends, and picking one to trust is how triggers ship dead in this project.
-- THE KILLER FROM THE SEASONE DEATH (v4.7.235). `_beginEscape`'s HOVER branch armed the
-- attack hold; the indoor PULL branch never did. `_tacticalGo` queues `stand;<jump> <dir>`,
-- and the next attack dispatch sends `queue addclearfull`, which clears the FULL queue and
-- throws the escape away. The log shows three complete attack rounds between the disengage
-- and "pull move lost" -- we were swinging while trying to leave, and the swings ate it.
describe("the escape pull holds the attack dispatcher", function()
  it("arms the hold when retreating indoors", function()
    fixture(1)
    gmcp.Room.Info.details = { "indoors" } -- no hover: takes the pull branch
    ataxiaTemp.swarmHold = nil
    expect(S._beginEscape()).toBeTrue()
    expect(S.state).toBe("pulling")
    expect(ataxiaTemp.swarmHold).toBeTrue()
  end)

  it("arms it on a disengage too -- same branch, same hazard", function()
    fixture(1); ataxiaBasher.inMnemosyne = true
    gmcp.Room.Info.details = { "indoors" }
    S._lastDisengageAt = nil
    ataxiaTemp.swarmHold = nil
    expect(S.disengage("phial burst #2")).toBeTrue()
    expect(ataxiaTemp.swarmHold).toBeTrue()
  end)

  -- The echo said "LOW HP (97%)" on a tactical disengage -- 97 was the mana column and HP was
  -- nowhere near the threshold. Reporting the wrong reason made the death log much harder to
  -- read than it needed to be.
  it("reports the disengage as a disengage, not as low HP", function()
    fixture(1); ataxiaBasher.inMnemosyne = true
    gmcp.Room.Info.details = { "indoors" }
    S._lastDisengageAt = nil
    local said = {}
    local realEcho = S._echo
    S._echo = function(m) said[#said + 1] = tostring(m) end
    S.disengage("phial burst #2")
    S._echo = realEcho
    local sawLowHp, sawDisengage = false, false
    for _, m in ipairs(said) do
      if m:find("LOW HP", 1, true) then sawLowHp = true end
      if m:find("DISENGAGE", 1, true) then sawDisengage = true end
    end
    expect(sawDisengage).toBeTrue()
    expect(sawLowHp).toBeFalse()
  end)
end)

describe("tumble confirmation and retry", function()
  local function armTumble()
    fixture(1)
    ataxiaBasher.inMnemosyne = true
    MAP.current = 200
    sent = {}
    S.onTumbleDone()
    S.onTumbleStart("n")
  end
  local function tumbles()
    local n = 0
    for _, c in ipairs(sent) do if c:find("tumble", 1, true) then n = n + 1 end end
    return n
  end

  it("records where it started from, so the check has a baseline", function()
    armTumble()
    expect(ataxiaTemp.tumbleDir).toBe("n")
    expect(ataxiaTemp.tumbleFrom).toBe(200)
  end)

  it("re-sends when the room did NOT change", function()
    armTumble()
    S._tumbleCheck()               -- still in room 200: the tumble was cancelled
    expect(tumbles()).toBe(1)
    expect(ataxiaTemp.tumbleTries).toBe(1)
    expect(sent[#sent]).toBe("queue addclear free stand;tumble n")
  end)

  -- `stand` in front matters: prone is one of the two things that cancels a tumble, so a bare
  -- re-send would be cancelled exactly the same way.
  it("stands first on the retry", function()
    armTumble()
    S._tumbleCheck()
    expect(sent[#sent]:find("stand", 1, true) ~= nil).toBeTrue()
  end)

  it("stops re-sending once the room changed -- the tumble landed", function()
    armTumble()
    MAP.current = 100              -- we moved
    S._tumbleCheck()
    expect(tumbles()).toBe(0)
    expect(ataxiaTemp.tumbleDir).toBe(nil)   -- and the state is cleared
  end)

  -- Bounded: a genuinely stuck character (permanently paralysed, walled in) must not spin
  -- forever re-sending a move that cannot work.
  it("gives up after the retry budget and hands back", function()
    armTumble()
    S._tumbleCheck(); S._tumbleCheck(); S._tumbleCheck(); S._tumbleCheck()
    expect(tumbles()).toBe(2)      -- TUMBLE_RETRIES
    expect(ataxiaTemp.tumbleDir).toBe(nil)
  end)

  -- THE GAME'S OWN COMPLETION LINE (v4.7.234, user-supplied): "You tumble out of the room."
  -- Timed at FOUR SECONDS after the start line, which is why the v4.7.233 window of 2s was
  -- itself a bug -- it would have re-sent a tumble that was working. The line confirms
  -- directly; the timer is only the fallback for when it never comes.
  it("the completion line ends the watch outright, mid-flight", function()
    armTumble()
    expect(ataxiaTemp.tumbleDir).toBe("n")
    S.onTumbleDone()                 -- what trigger misc_alerts/005 calls
    expect(ataxiaTemp.tumbleDir).toBe(nil)
    expect(ataxiaTemp.tumbleFrom).toBe(nil)
    expect(ataxiaTemp.tumbleTries).toBe(nil)
    -- ...and a later check cannot resurrect it into a spurious re-send.
    sent = {}
    S._tumbleCheck()
    expect(tumbles()).toBe(0)
  end)

  -- The window must outlast the action it guards, or the "safety net" re-sends mid-tumble.
  it("allows longer than a real tumble takes before retrying", function()
    -- Observed: 11:52:29.160 start -> 11:52:33.178 complete = 4.0s.
    expect(S.TUMBLE_CONFIRM ~= nil).toBeTrue()
    expect(S.TUMBLE_CONFIRM > 4).toBeTrue()
  end)

  it("is inert outside the tower", function()
    fixture(1)
    ataxiaBasher.inMnemosyne = false
    sent = {}
    S.onTumbleStart("n")
    expect(ataxiaTemp.tumbleDir).toBe(nil)
    ataxiaBasher.inMnemosyne = true
  end)

  it("a reset clears any tumble in flight", function()
    armTumble()
    S.reset("test")
    expect(ataxiaTemp.tumbleDir).toBe(nil)
  end)
end)

describe("Roll Hide -- heal where we landed, then go back in", function()
  local function panicNow()
    fixture(3); mnemRollHide = true
    S._lastPanicAt = nil
    S.onTick(); S.decorate("attack", ";")
    MAP.current = 100; mobs = 2; S.onTick()
    MAP.rooms[100].exits.west = 50
    ataxia.vitals = { hpp = 30 }
    S._lastPanicAt = nil
    expect(S.onTick()).toBeTrue()
  end

  it("holds navigation and attacks after the tumble instead of walking back in", function()
    panicNow()
    expect(S.state).toBe("recovering")
    expect(ataxiaTemp.swarmHold).toBeTrue()
    -- Self-ticking: a recovery must never wait on an outside event to notice it healed.
    expect(#scheduled > 0).toBeTrue()
  end)

  it("stays put until FULLY healed -- HP alone is not enough", function()
    panicNow()
    mobs = 0
    ataxia.vitals = { hpp = 99 }
    ataxia.afflictions = { ["broken left leg"] = true } -- restoration still running
    expect(S.onTick()).toBeTrue()
    expect(S.state).toBe("recovering")
    ataxia.afflictions = {}
    expect(S.onTick()).toBeTrue()          -- diagnose tick (v4.7.233)
    local sawDiag = false
    for _, c in ipairs(sent) do if c == "diagnose" then sawDiag = true end end
    expect(sawDiag).toBeTrue()
    expect(S.state).toBe("recovering")
    expect(S.onTick()).toBeTrue()
    expect(S.state).toBe("idle") -- healed, clean AND confirmed: hand back for the next run-in
  end)

  it("does not land -- it never left the ground", function()
    panicNow()
    mobs = 0
    ataxia.vitals = { hpp = 99 }
    ataxia.afflictions = {}
    local before = #sent
    S.onTick()
    for i = before + 1, #sent do expect(sent[i] ~= "land").toBeTrue() end
  end)

  -- REQUIREMENT REVERSED, v4.7.233, from a death log. v4.7.218 handed straight back to the
  -- basher here; the log shows the cost -- "company arrived mid-recovery (43%) -- handing
  -- back", then "LOW HP (31%)" four seconds later, then dead. Handing back drops us into a
  -- mob-filled room at half health with the recovery abandoned. With Roll Hide up the answer
  -- is another tumble: it sheds pursuers, so the fight does not follow.
  it("tumbles ON rather than trading, when a denizen wanders in", function()
    panicNow()
    mobs = 2
    expect(S.onTick()).toBeTrue()
    expect(S.state).toBe("recovering")     -- still recovering, just somewhere else
    local sawTumble = false
    for _, c in ipairs(sent) do if c:find("tumble", 1, true) then sawTumble = true end end
    expect(sawTumble).toBeTrue()
    expect(ataxiaTemp.swarmHold).toBeTrue()
  end)

  -- ...but standing and fighting IS right when we genuinely cannot move: being attack-gated
  -- while something hits us is the one thing worse than trading.
  it("hands back when there is nowhere to tumble to", function()
    panicNow()
    mobs = 2
    mnemRollHide = false                   -- no boon: a tumble sheds nothing
    expect(S.onTick()).toBeFalse()
    expect(S.state).toBe("idle")
    expect(ataxiaTemp.swarmHold).toBe(nil)
    mnemRollHide = true
  end)

  it("does not tumble again while recovering", function()
    panicNow()
    mobs = 0
    clock = clock + 60 -- well past PANIC_COOLDOWN
    ataxia.vitals = { hpp = 20 } -- still deep in panic territory
    local before = #sent
    S.onTick()
    for i = before + 1, #sent do expect(sent[i]:find("tumble", 1, true) == nil).toBeTrue() end
  end)

  it("defaults to 35% and migrates a stored 40 exactly once", function()
    fixture(1)
    cfg.swarm = { enabled = true, threshold = 3, panicAt = 40 } -- the old shipped default
    expect(S._cfg().panicAt).toBe(35)
    -- ...but 40 stays TYPEABLE afterwards: `mnem swarm panic 40` must not be dragged back to
    -- 35 by the next _cfg() call, which happens every tick.
    S._cfg().panicAt = 40
    expect(S._cfg().panicAt).toBe(40)
  end)
end)

describe("which jump -- Bard backflips, everyone leaps", function()
  local function asBard()
    gmcp.Char = { Status = { class = "Bard" } }
  end
  local function lastJump()
    for i = #sent, 1, -1 do
      if sent[i]:find("leap ", 1, true) or sent[i]:find("backflip ", 1, true) then return sent[i] end
    end
  end

  it("uses backflip for a Bard -- faster balance on every tactical retreat", function()
    fixture(1); ataxiaBasher.inMnemosyne = true
    asBard()
    S._tacticalGo("s", nil)
    expect(lastJump()).toBe("queue addclear free stand;backflip s")
  end)

  it("leaves every other class on leap", function()
    fixture(1); ataxiaBasher.inMnemosyne = true
    gmcp.Char = { Status = { class = "Runewarden" } }
    S._tacticalGo("s", nil)
    expect(lastJump()).toBe("queue addclear free stand;leap s")
  end)

  -- The safeguard. Several of this module's jumps exist to clear our OWN icewall, and
  -- greaves-LEAP is the ability confirmed to do that; backflip is NOT confirmed to. Being
  -- wrong there is not a slow move, it is a silent no-op in the indoor low-HP escape --
  -- the anti-death ladder livelocking at crash HP, which is why the leap exists at all.
  it("falls back to leap when crossing OUR OWN walled edge", function()
    fixture(1); ataxiaBasher.inMnemosyne = true
    asBard()
    S.wallRaised[200] = "south" -- we walled the edge we are about to cross
    expect(S.moveVerb("s")).toBe("leap")
  end)

  it("still backflips across an edge that is not the walled one", function()
    fixture(1); ataxiaBasher.inMnemosyne = true
    asBard()
    S.wallRaised[200] = "south"
    expect(S.moveVerb("n")).toBe("backflip")
  end)

  it("falls back to leap when the wall state cannot be resolved to a direction", function()
    fixture(1); ataxiaBasher.inMnemosyne = true
    asBard()
    S.wallRaised[200] = true -- legacy/boolean marker: we know a wall stands, not where
    expect(S.moveVerb("s")).toBe("leap")
  end)

  it("is unaffected by a wall in a DIFFERENT room", function()
    fixture(1); ataxiaBasher.inMnemosyne = true
    asBard()
    S.wallRaised[100] = "south" -- the funnel room's wall, not ours
    expect(S.moveVerb("s")).toBe("backflip")
  end)
end)

-- ROLL HIDE OUTRANKS THE ICEWALL (v4.7.223). User: "if we have roll hide boon, we dont need to
-- icewall, just tumble out." The wall was never a barrier -- denizens walk through icewalls
-- without Maklak's Promise, so it only PACED the swarm -- and it costs a balance-gated `point`,
-- a wall-memory entry and a melt cycle later. Shedding every pursuer beats pacing them.
describe("Roll Hide replaces the icewall", function()
  it("takes the plain pull indoors instead of walling, while the boon is up", function()
    fixture(3)
    gmcp.Room.Info.details = { "indoors" }
    cfg.swarm.icewall = true
    mnemRollHide = true
    expect(S.onTick()).toBeTrue()
    expect(S.state).toBe("pulling")
    expect(S.mode).toBe("pull")
    -- ...and no bracers were pointed: that is the balance the boon saves us.
    for _, c in ipairs(sent) do expect(c:find("point ", 1, true) == nil).toBeTrue() end
    mnemRollHide = false
  end)

  it("still walls indoors when the boon is NOT up", function()
    fixture(3)
    gmcp.Room.Info.details = { "indoors" }
    cfg.swarm.icewall = true
    mnemRollHide = false
    expect(S.onTick()).toBeTrue()
    expect(S.mode).toBe("wall")
  end)

  it("tumbles out of the pull rather than stepping, so nothing follows", function()
    fixture(3)
    mnemRollHide = true
    S.onTick()
    local cmd = S.decorate("attack", ";")
    expect(cmd).toBe("attack;tumble s")
    mnemRollHide = false
  end)

  it("steps out normally without the boon -- the funnel branch still has work to do", function()
    fixture(3)
    mnemRollHide = false
    S.onTick()
    expect(S.decorate("attack", ";")).toBe("attack;s")
  end)

  it("leaves the wall-mode suffix alone -- a raised wall still needs leaping", function()
    fixture(3)
    gmcp.Room.Info.details = { "indoors" }
    cfg.swarm.icewall = true
    mnemRollHide = false
    S.onTick() -- enters wall mode and raises the wall
    local cmd = S.decorate("attack", ";")
    expect(cmd:find("point ", 1, true) ~= nil).toBeTrue()
    expect(cmd:find("leap s", 1, true) ~= nil).toBeTrue()
  end)
end)

-- VITALISING TINCTURE (v4.7.241): a third of max health on a 20s cooldown, which the escape
-- ladder never used. Gated on the BOON and on a command being configured -- I do not know what
-- imbibes a nutritional formulation, and guessing a command is how bare BOONS and bare
-- PERFORMANCE shipped as no-ops that ate real behaviour for a release each.
-- NEVER GO BACK IN HURT (v4.7.242). User, from a death log: "We should've never went back
-- into that room until fully cured!"
--
--   12:50:38  in the funnel room -- fighting what follows (window 2s)
--   12:50:40  trickle over (peak followers: 0) -- re-entering -> w
--
-- Two seconds, 28% HP, still locked. `_beginReenter` re-entered on ONE question -- "did
-- anything follow?" -- and "nothing followed" is not the same fact as "we are ready".
describe("re-entry readiness", function()
  local function funnelled(hp, affs)
    fixture(3)
    ataxiaBasher.inMnemosyne = true
    S.onTick(); S.decorate("attack", ";")   -- pull armed + consumed
    MAP.current = 100                        -- we are in the funnel room
    S.state = "funnel"
    S.fwdShort = "n"
    S.peakFollowers = 0
    ataxia.vitals = { hpp = hp }
    ataxia.afflictions = affs or {}
    sent = {}
  end
  local function movedBack()
    for _, c in ipairs(sent) do
      if c:find("leap n", 1, true) or c:find("backflip n", 1, true) then return true end
    end
    return false
  end

  it("goes back in when healthy and clean", function()
    funnelled(100, {})
    expect(S._beginReenter()).toBeTrue()
    expect(S.state).toBe("reenter")
    expect(movedBack()).toBeTrue()
  end)

  it("refuses at the HP from the death log, and heals instead", function()
    funnelled(28, {})
    expect(S._beginReenter()).toBeTrue()
    expect(S.state).toBe("recovering")   -- not "reenter"
    expect(movedBack()).toBeFalse()
    expect(ataxiaTemp.swarmHold).toBeTrue()
  end)

  -- Health alone is not the question: we left because of a LOCK, so returning while still
  -- carrying it walks back into the thing we fled.
  it("refuses while still afflicted even at full health", function()
    funnelled(100, { slickness = true, asthma = true })
    expect(S._beginReenter()).toBeTrue()
    expect(S.state).toBe("recovering")
    expect(movedBack()).toBeFalse()
  end)

  -- Kept defences must not hold us out forever -- the same exemption the hover already uses.
  it("is not held out by kept defences", function()
    funnelled(100, { blindness = true, deafness = true })
    expect(S._reenterReady()).toBeTrue()
  end)

  it("recovers on the GROUND -- we never left it", function()
    funnelled(28, {})
    S._beginReenter()
    expect(S.recoverGround).toBeTrue()
    for _, c in ipairs(sent) do expect(c ~= "land").toBeTrue() end
  end)
end)

describe("Vitalising Tincture", function()
  local function setup(boon, cmd, hp)
    fixture(1); ataxiaBasher.inMnemosyne = true
    mnemVitalisingTincture = boon
    M.tinctureCmd = cmd
    ataxia.vitals = { hpp = hp, hp = hp * 100 }
    ataxiaTemp.tinctureAt = nil
    sent = {}
  end
  local function fired()
    for _, c in ipairs(sent) do if c == "drink formulation" then return true end end
    return false
  end

  it("is inert without the boon, however low we are", function()
    setup(false, "drink formulation", 10)
    expect(S._maybeTincture(10)).toBeFalse()
    expect(fired()).toBeFalse()
  end)

  -- The command is NOT shipped: unset means the whole thing stays quiet rather than sending a
  -- guess and eating the round on a syntax error.
  it("is inert with the boon but no command configured", function()
    setup(true, nil, 10)
    expect(S._maybeTincture(10)).toBeFalse()
    expect(#sent).toBe(0)
  end)

  it("fires at the escape threshold with both in place", function()
    setup(true, "drink formulation", 30)
    expect(S._maybeTincture(30)).toBeTrue()
    expect(fired()).toBeTrue()
  end)

  -- At the escape threshold, not the panic floor: a heal we could have had ten seconds earlier
  -- is a heal we did not get.
  it("does not fire while healthy", function()
    setup(true, "drink formulation", 80)
    expect(S._maybeTincture(80)).toBeFalse()
    expect(fired()).toBeFalse()
  end)

  it("respects its 20s cooldown", function()
    setup(true, "drink formulation", 30)
    expect(S._maybeTincture(30)).toBeTrue()
    sent = {}
    expect(S._maybeTincture(30)).toBeFalse()   -- straight away: still on cooldown
    clock = clock + 21
    expect(S._maybeTincture(30)).toBeTrue()
    mnemVitalisingTincture = false
    M.tinctureCmd = nil
  end)
end)

describe("forced disengage (tactical, not HP-driven)", function()
  local function lastLeap()
    for i = #sent, 1, -1 do if sent[i]:find("leap ", 1, true) then return sent[i] end end
  end

  it("retreats to the cleared room and holds the attack dispatch", function()
    fixture(1); ataxiaBasher.inMnemosyne = true
    gmcp.Room.Info.details = { "indoors" } -- no hover: takes the pull branch
    S._lastDisengageAt = nil
    expect(S.disengage("phial burst #2")).toBeTrue()
    expect(S.state).toBe("pulling")
    -- Free-queued, never raw: at the moment we decide to leave the balance is normally
    -- spent mid-round, and a raw leap would simply be rejected.
    expect(lastLeap()).toBe("queue addclear free stand;leap s")
  end)

  it("does not need low HP -- that is the whole point", function()
    fixture(1); ataxiaBasher.inMnemosyne = true
    gmcp.Room.Info.details = { "indoors" }
    S._lastDisengageAt = nil
    ataxia.vitals = { hpp = 100 } -- far above escapeAt: the reactive ladder would not fire
    expect(S.disengage("test")).toBeTrue()
    expect(S.state).toBe("pulling")
  end)

  it("is cooldown-limited so repeat bursts cannot churn the retreat", function()
    fixture(1); ataxiaBasher.inMnemosyne = true
    gmcp.Room.Info.details = { "indoors" }
    S._lastDisengageAt = nil
    expect(S.disengage("one")).toBeTrue()
    S.state = "idle" -- pretend the pull completed
    expect(S.disengage("two")).toBeFalse()
    clock = clock + 11
    expect(S.disengage("three")).toBeTrue()
  end)

  -- A failed attempt must not burn the cooldown: the caller that read the fight as lethal
  -- gets to try again the moment a route exists, rather than being locked out for 10s.
  it("returns false WITHOUT stamping the cooldown when there is no route out", function()
    fixture(1); ataxiaBasher.inMnemosyne = true
    gmcp.Room.Info.details = { "indoors" }
    S._lastDisengageAt = nil
    M.explore.fromRoom = nil -- no validated back edge
    expect(S.disengage("no route")).toBeFalse()
    expect(S._lastDisengageAt).toBe(nil)
    M.explore.fromRoom = 100
    expect(S.disengage("route back")).toBeTrue()
  end)

  it("reports success when we are already out and recovering", function()
    fixture(1); ataxiaBasher.inMnemosyne = true
    S._lastDisengageAt = nil
    S.state = "recovering"
    local before = #sent
    expect(S.disengage("already gone")).toBeTrue()
    expect(#sent).toBe(before) -- no churn
  end)

  it("is inert when swarm tactics are disabled", function()
    fixture(1); ataxiaBasher.inMnemosyne = true
    S._lastDisengageAt = nil
    cfg.swarm.enabled = false
    local before = #sent
    expect(S.disengage("disabled")).toBeFalse()
    expect(#sent).toBe(before)
    cfg.swarm.enabled = true
  end)
end)

-- ============================================================================
-- v4.7.243 -- the movement lock and escape mode
-- ============================================================================

-- User: "If we tumble and then leap or walk in a direction it cancels the tumble."
-- A tumble is ~4s between "You begin to tumble agilely to the <dir>." and "You tumble out of
-- the room."; anything else we send in that window throws it away. Four of our own code paths
-- could do exactly that, and S.onVitals -- which runs on EVERY prompt and is exempt from every
-- existing hold -- was the worst of them.
describe("the movement lock (v4.7.243)", function()
  local function tumbling()
    fixture(3); ataxiaBasher.inMnemosyne = true
    mnemRollHide = true
    S.onTumbleStart("south")
    sent = {}
  end

  it("is armed by a tumble and released when it lands", function()
    tumbling()
    expect(S.moveLocked()).toBeTrue()
    S.onTumbleDone()
    expect(S.moveLocked()).toBeFalse()
  end)

  it("is off when nothing is tumbling", function()
    fixture(3)
    expect(S.moveLocked()).toBeFalse()
  end)

  it("blocks _tacticalGo -- the jump that cancelled the tumble", function()
    tumbling()
    S._tacticalGo("s", "test")
    expect(#sent).toBe(0)
    S.onTumbleDone()
    S._tacticalGo("s", "test")
    expect(#sent).toBe(1)
  end)

  it("blocks a second panic tumble", function()
    tumbling()
    S._lastPanicAt = nil -- or the panic COOLDOWN would refuse it and the lock go untested
    ataxia.vitals.hpp = 10
    expect(S._maybePanic(10)).toBeFalse()
    expect(#sent).toBe(0)
  end)

  it("blocks the escape ladder's hover", function()
    tumbling()
    gmcp.Room.Info.details = {} -- outdoors: the hover branch
    S.state = "idle"
    expect(S._beginEscape("test")).toBeFalse()
    expect(#sent).toBe(0)
  end)

  -- THE CRITICAL PATH. A Roll Hide pull tumble leaves state == "pulling", so the only early
  -- return in onVitals (the `recovering` one) does not apply -- two seconds later it fired
  -- `cq all` + _beginEscape -> `stand;leap <dir>` into a tumble that was 2s from landing.
  it("stops onVitals cancelling a tumble in flight", function()
    tumbling()
    S.state = "pulling"
    ataxia.vitals.hpp = 12
    gmcp.Char = { Vitals = { hp = "1200", maxhp = "10000" } }
    S.onVitals()
    expect(#sent).toBe(0)
  end)

  -- Healing is NOT movement. Blocking the tincture mid-tumble would take it away at exactly
  -- the moment it is worth most.
  it("does NOT block healing", function()
    tumbling()
    S.state = "pulling"
    mnemVitalisingTincture = true
    M.tinctureCmd = "apply tincture"
    ataxiaTemp.tinctureAt = nil
    ataxia.vitals.hpp = 12
    gmcp.Char = { Vitals = { hp = "1200", maxhp = "10000" } }
    S.onVitals()
    expect(#sent).toBe(1)
    expect(sent[1]).toBe("apply tincture")
    mnemVitalisingTincture = nil
    M.tinctureCmd = nil
  end)
end)

-- User: "We should've stopped attacking here and put a priority on leaving the room."
describe("escape mode (v4.7.243)", function()
  it("arms on every tactical move and reports the room it is leaving", function()
    fixture(3); ataxiaBasher.inMnemosyne = true
    expect(ataxiaTemp.escapeMode).toBe(nil)
    S._tacticalGo("s", "retreating")
    expect(ataxiaTemp.escapeMode).toBeTrue()
    expect(ataxiaTemp.escapeRoom).toBe(200)
  end)

  it("clears when the room ACTUALLY changes -- the only proof we got out", function()
    fixture(3); ataxiaBasher.inMnemosyne = true
    S._tacticalGo("s", "retreating")
    expect(ataxiaTemp.escapeMode).toBeTrue()
    S.escapeCheckRoom()                 -- same room: still trying
    expect(ataxiaTemp.escapeMode).toBeTrue()
    MAP.current = 100                   -- we arrived
    S.escapeCheckRoom()
    expect(ataxiaTemp.escapeMode).toBe(nil)
  end)

  it("arms on the panic tumble", function()
    fixture(3); ataxiaBasher.inMnemosyne = true
    mnemRollHide = true
    S._lastPanicAt = nil -- fixture() rewinds the clock but not the panic cooldown stamp
    ataxia.vitals.hpp = 10
    expect(S._maybePanic(10)).toBeTrue()
    expect(ataxiaTemp.escapeMode).toBeTrue()
  end)

  -- A pull's escape RIDES the next attack (the swarmPullDir decorator turns the round into
  -- "<attack>;<backdir>"), so arming the attack gate at _beginPull time would starve the very
  -- swing carrying the step-out. It must arm only once the chain has actually been sent.
  it("does NOT arm while the pull is still waiting for its swing", function()
    fixture(3); ataxiaBasher.inMnemosyne = true
    expect(S.onTick()).toBeTrue()
    expect(S.state).toBe("pulling")
    expect(ataxiaTemp.swarmPullDir).toBe("s")
    expect(ataxiaTemp.escapeMode).toBe(nil) -- the swing must still be allowed through
    S._onPullSent()
    expect(ataxiaTemp.escapeMode).toBeTrue() -- ...and gated the instant it is queued
  end)

  -- Fighting in place is sometimes the best answer. Muting the basher there would be lethal.
  it("does not latch when the escape had nowhere to go", function()
    fixture(3); ataxiaBasher.inMnemosyne = true
    M.explore.fromRoom, M.explore.fromDir = nil, nil -- no validated route back
    gmcp.Room.Info.details = { "indoors" }
    S.state = "idle"
    expect(S._beginEscape("test")).toBeFalse()
    expect(ataxiaTemp.escapeMode).toBe(nil)
  end)

  it("is dropped by a reset, so the next context starts clean", function()
    fixture(3); ataxiaBasher.inMnemosyne = true
    S._tacticalGo("s", "retreating")
    expect(ataxiaTemp.escapeMode).toBeTrue()
    S.reset("test")
    expect(ataxiaTemp.escapeMode).toBe(nil)
  end)
end)

-- ============================================================================
-- v4.7.245 -- the tumble chain, and the cancellation line
-- ============================================================================
--
-- User log, 2026-08-10: "Seems like tumble is a tad bit broken." FOUR tumbles in nineteen
-- seconds, across rooms whose descriptions named no denizens at all, while the Ablaze affix
-- took ~1,200 per tick. HP went 31% -> 14% and stayed there: a recovery that keeps moving
-- never recovers.
describe("the mid-recovery tumble chain (v4.7.245)", function()
  -- Put us in a ground recovery with company, the state the log was stuck in.
  local function recovering()
    fixture(3); ataxiaBasher.inMnemosyne = true
    mnemRollHide = true
    S._lastPanicAt = nil
    ataxia.vitals.hpp = 30
    gmcp.Char = { Vitals = { hp = "3000", maxhp = "10000" } }
    expect(S._maybePanic(30)).toBeTrue()
    expect(S.state).toBe("recovering")
    -- _maybePanic SENDS the tumble; trigger misc_alerts/004 is what arms the state off the
    -- game's "You begin to tumble" line. Stand in for it, then land it.
    S.onTumbleStart("n")
    S.onTumbleDone() -- the tumble landed
    sent = {}
    mobs = 2         -- ...and the stale denizen list still lists the room we fled
  end
  local function tumbles()
    local n = 0
    for _, c in ipairs(sent) do if c:find("tumble", 1, true) then n = n + 1 end end
    return n
  end

  -- `_roomHasDenizens` reads `ataxia.denizensHere`, fed by gmcp Char.Items, which lags the
  -- room change. The tick that fires ON arrival reads the OLD room's company.
  it("does not re-tumble on the stale denizen list right after landing", function()
    recovering()
    expect(S.onTick()).toBeTrue()   -- tick consumed...
    expect(tumbles()).toBe(0)       -- ...but nothing sent: re-decide on fresh data
    expect(S.state).toBe("recovering")
  end)

  it("does re-tumble once the arrival has settled and company is real", function()
    recovering()
    clock = clock + 5               -- past ARRIVE_SETTLE
    expect(S.onTick()).toBeTrue()
    expect(tumbles()).toBe(1)
  end)

  -- Roll Hide sheds pursuers, so needing a third tumble means something is wrong with our
  -- reading of the room. Chain-tumbling at panic HP pays the affix damage again every hop.
  it("spends at most RECOVER_TUMBLES before standing and fighting", function()
    recovering()
    for _ = 1, S.RECOVER_TUMBLES + 1 do
      S.onTumbleDone()   -- stamps the arrival...
      clock = clock + 5  -- ...and only then does it settle
      S.onTick()
    end
    expect(tumbles()).toBe(S.RECOVER_TUMBLES)
    expect(S.state).toBe("idle")    -- handed back to the basher rather than hopping on
  end)

  it("the budget is per RECOVERY, not per session", function()
    recovering()
    for _ = 1, S.RECOVER_TUMBLES + 1 do
      S.onTumbleDone()
      clock = clock + 5
      S.onTick()
    end
    expect(S.state).toBe("idle")
    recovering()                    -- a NEW panic recovery
    expect(S._recoverTumbles).toBe(nil)
    clock = clock + 5
    sent = {}
    expect(S.onTick()).toBeTrue()
    expect(tumbles()).toBe(1)       -- the fresh budget works
  end)

  -- A stamp that outlived its context must not hold the settle open forever, which would
  -- silently disable the re-tumble -- the failure direction that actually hurts.
  it("a stale future-dated stamp cannot wedge the settle", function()
    recovering()
    S.tumbleResolvedAt = clock + 10000
    expect(S.onTick()).toBeTrue()
    expect(tumbles()).toBe(1)
  end)
end)

describe("the tumble cancellation line (v4.7.245)", function()
  local function tumbling()
    fixture(3); ataxiaBasher.inMnemosyne = true
    mnemRollHide = true
    S.onTumbleStart("north")
    sent = {}
  end

  -- Before this the trigger printed a banner and flushed the queue, and the state machine
  -- sat on `tumbleDir` for the full TUMBLE_CONFIRM window -- which v4.7.243 made a MOVEMENT
  -- LOCK, so nothing could move for those seconds either.
  it("retries immediately instead of waiting out TUMBLE_CONFIRM", function()
    tumbling()
    S.onTumbleCanceled()
    expect(#sent).toBe(1)
    expect(sent[1]:find("tumble north", 1, true) ~= nil).toBeTrue()
  end)

  it("still respects the retry budget", function()
    tumbling()
    for _ = 1, S.TUMBLE_RETRIES + 1 do S.onTumbleCanceled() end
    expect(#sent).toBe(S.TUMBLE_RETRIES)
    expect(S.moveLocked()).toBeFalse() -- gave up and released the lock
  end)

  it("is inert when no tumble is being tracked", function()
    fixture(3); ataxiaBasher.inMnemosyne = true
    sent = {}
    S.onTumbleCanceled()
    expect(#sent).toBe(0)
  end)

  it("is inert outside the tower", function()
    tumbling()
    ataxiaBasher.inMnemosyne = false
    S.onTumbleCanceled()
    expect(#sent).toBe(0)
    ataxiaBasher.inMnemosyne = true
  end)
end)

-- ============================================================================
-- v4.7.252 -- a tumble in flight is not "nowhere to go"
-- ============================================================================
describe("recovery while a tumble is still in the air", function()
  local function recovering()
    fixture(3); ataxiaBasher.inMnemosyne = true
    mnemRollHide = true
    S._lastPanicAt = nil
    ataxia.vitals.hpp = 30
    gmcp.Char = { Vitals = { hp = "3000", maxhp = "10000" } }
    expect(S._maybePanic(30)).toBeTrue()
    S.onTumbleStart("n")   -- the game confirms the tumble started
    sent = {}
    mobs = 2               -- ...and something is in the room with us
  end

  -- THE LIVE BUG: the v4.7.243 move lock made `dir` falsy while a tumble was mid-air, and the
  -- fall-through read that as "we cannot leave" -- abandoning the recovery, clearing the hold
  -- and handing the round back to the basher WHILE THE ESCAPE WAS STILL RESOLVING.
  it("holds the recovery instead of handing back", function()
    recovering()
    clock = clock + 5                 -- past the arrival settle
    expect(S.moveLocked()).toBeTrue() -- the tumble has not landed yet
    expect(S.onTick()).toBeTrue()     -- tick consumed...
    expect(S.state).toBe("recovering") -- ...and we are STILL recovering
    expect(ataxiaTemp.swarmHold).toBeTrue() -- the basher is still held off
  end)

  it("sends nothing while it waits -- a second tumble would cancel the first", function()
    recovering()
    clock = clock + 5
    S.onTick()
    local tumbles = 0
    for _, c in ipairs(sent) do if c:find("tumble", 1, true) then tumbles = tumbles + 1 end end
    expect(tumbles).toBe(0)
  end)

  -- ...but a genuine dead end must still hand back: standing attack-gated while something
  -- hits us is the one thing worse than trading.
  it("still hands back when there is genuinely nowhere to go", function()
    recovering()
    S.onTumbleDone()                  -- the tumble resolved
    clock = clock + 5
    mnemRollHide = false              -- no boon: a tumble sheds nothing
    expect(S.onTick()).toBeFalse()
    expect(S.state).toBe("idle")
    mnemRollHide = true
  end)
end)

-- User: "We do have manaleech so our mana will decrease over time."
describe("manaleech must not hold a recovery (v4.7.252)", function()
  it("does not count as an affliction for readiness", function()
    fixture(3)
    ataxia.afflictions = { manaleech = true }
    expect(S._afflicted()).toBeFalse()
  end)

  it("a real affliction still does", function()
    fixture(3)
    ataxia.afflictions = { manaleech = true, paralysis = true }
    expect(S._afflicted()).toBeTrue()
    ataxia.afflictions = {}
  end)

  -- It is a DRAIN: waiting does not recover from it, it pays for it. Before this, a hover with
  -- manaleech up could never satisfy the aff-free gate and burned its full 60s cap.
  it("lets a healed recovery actually complete", function()
    fixture(3); ataxiaBasher.inMnemosyne = true
    S.state = "recovering"
    S.recoverGround = true
    S.recoverStarted = clock  -- `now` is module-local; the fixture clock is the same source
    S.recoverDiagnosed = true
    ataxia.vitals.hpp = 99
    gmcp.Char = { Vitals = { hp = "9900", maxhp = "10000" } }
    ataxia.afflictions = { manaleech = true }
    mobs = 0
    S.onTick()
    expect(S.state).toBe("idle")   -- handed back to the sweep, recovery done
    ataxia.afflictions = {}
  end)
end)

-- ============================================================================
-- v4.7.256 -- the escape routes refuse lava
-- ============================================================================
--
-- Death log: "LOW HP (65%) retreating -> s" walked into boiling lava, and at 20% the ladder
-- chose it again. 6,874 unblockable a tick, three times, dead. The room we came from is
-- normally the safest square on the grid -- but "we walked through it" is not the same fact
-- as "it is survivable".
describe("escape routes refuse lava (v4.7.256)", function()
  it("_backDir returns nil rather than retreating into it", function()
    fixture(3); ataxiaBasher.inMnemosyne = true
    expect(S._backDir()).toBe("s")            -- normally the cleared room behind us
    M.explore.lavaRooms = { [100] = true }    -- ...which turns out to be lava
    expect(S._backDir()).toBe(nil)            -- nil -> shield fallback, not death
    M.explore.lavaRooms = {}
  end)

  it("_backDir also refuses on the remembered EDGE", function()
    fixture(3); ataxiaBasher.inMnemosyne = true
    M.explore.lavaEdges = { [200] = { south = true } }
    expect(S._backDir()).toBe(nil)
    M.explore.lavaEdges = {}
  end)

  -- The lava edge must sort BEFORE the safe one, or the scan would reach the safe exit first
  -- and the test would pass whether or not the guard exists. (It did, on the first draft.)
  it("the panic tumble never tumbles into it", function()
    fixture(3); ataxiaBasher.inMnemosyne = true
    MAP.rooms[200].exits = { east = 0, west = 0 }
    M.explore.fromRoom, M.explore.fromDir = nil, nil  -- no back route: force the scan
    S.wallRaised = {}
    S.fwdShort = nil
    M.explore.lavaEdges = { [200] = { east = true } } -- "east" sorts first
    expect(S._panicDir()).toBe("w")           -- skips the lava despite it sorting first
    M.explore.lavaEdges = {}
  end)

  it("panic direction is deterministic", function()
    fixture(3); ataxiaBasher.inMnemosyne = true
    MAP.rooms[200].exits = { south = 100, east = 0, north = 0 }
    S.wallRaised = {}
    local first = S._panicDir()
    for _ = 1, 10 do expect(S._panicDir()).toBe(first) end
  end)
end)

-- Restore the mock send for whoever runs after us (see the note at the top).
send = _mockSend

describe("dragged out of the sky -- flight is a trap on this ripple", function()
  it("latches grounded so the ladder stops trying to fly", function()
    fixture(3); ataxiaBasher.inMnemosyne = true
    expect(S._canFly()).toBeTrue()
    S.onDraggedDown()
    expect(S._canFly()).toBeFalse()
    expect(S._canHover()).toBeFalse()
  end)

  it("aborts an in-progress hover instead of re-sending fly forever", function()
    fixture(3); ataxiaBasher.inMnemosyne = true
    S.state = "recovering"
    S.flying = true
    S.flightConfirmed = true
    S.onDraggedDown()
    expect(S.flying).toBe(nil)
    expect(S.flightConfirmed).toBe(nil)
    -- The ladder is re-run and, with flight now unavailable, takes the GROUNDED
    -- retreat -- which is the whole point. It must not be left sitting in
    -- "recovering", where it would re-send fly every tick while attack-gated.
    expect(S.state).toBe("pulling")
  end)

  it("is per-RIPPLE -- the next ripple is a different room set", function()
    fixture(3); ataxiaBasher.inMnemosyne = true
    S.onDraggedDown()
    expect(S.grounded).toBeTrue()
    S.onRipple()
    expect(S.grounded).toBe(nil)
    expect(S._canFly()).toBeTrue()
  end)

  it("is inert outside the tower", function()
    fixture(3); ataxiaBasher.inMnemosyne = true
    ataxiaBasher.inMnemosyne = false
    S.onDraggedDown()
    expect(S.grounded).toBe(nil)
    ataxiaBasher.inMnemosyne = true
  end)
end)
