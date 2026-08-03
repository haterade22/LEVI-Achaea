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
  explore = { on = true, fromRoom = nil, fromDir = nil },
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
  S._wallsRipple = nil
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
    expect(S.state).toBe("idle")
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
  it("onMoveFailed returns to idle without condemning anything", function()
    fixture(3)
    S.onTick()
    S.onMoveFailed()
    expect(S.state).toBe("idle")
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
    expect(S.state).toBe("idle") -- panic resets; no hover started
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
    expect(S.state).toBe("idle")
    expect(M.explore.fromRoom).toBe(100) -- anchor restored from the tactic's own route
    expect(M.explore.fromDir).toBe("n")
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
      S.onMoveFailed()
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
