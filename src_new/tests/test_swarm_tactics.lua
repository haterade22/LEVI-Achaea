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
  _exploreEcho = function() end,
  echo = function() end,
  _captureLines = function(opts) opts.onDone({ "line one", "line two" }) end,
}
ataxiaBasher = { enabled = true }
ataxiaTemp = {}
found_target = false

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
    expect(sent[#sent]).toBe("queue addclear free stand;n")
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

  it("melts our own wall on re-entry", function()
    fixture(3)
    gmcp.Room.Info.details = { "indoors" }
    S.onTick(); S.decorate("attack", ";")
    MAP.current = 100; mobs = 0; S.onTick()
    clock = clock + 20 -- past WALL_WINDOW
    S.onTick()
    expect(S.state).toBe("reenter")
    expect(sent[#sent]).toBe("queue addclear free point bracers151113 at icewall;stand;n")
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
  it("tumbles out at panic HP with the boon up, then resets", function()
    fixture(3)
    S.onTick(); S.decorate("attack", ";")
    MAP.current = 100; mobs = 2; S.onTick() -- funnel, fighting followers
    MAP.rooms[100].exits.west = 50 -- an escape exit away from the swarm room
    mnemRollHide = true
    ataxia.vitals = { hpp = 30 }
    S._lastPanicAt = nil
    expect(S.onTick()).toBeTrue()
    expect(S.state).toBe("idle")
    local sawTumble = false
    for _, c in ipairs(sent) do if c == "tumble w" then sawTumble = true end end
    expect(sawTumble).toBeTrue()
  end)

  it("does not panic without the boon or above the threshold", function()
    fixture(3)
    S.onTick(); S.decorate("attack", ";")
    MAP.current = 100; mobs = 2; S.onTick()
    ataxia.vitals = { hpp = 30 } -- low HP but no boon
    S.onTick()
    expect(S.state).toBe("funnel")
    mnemRollHide = true
    ataxia.vitals = { hpp = 90 } -- boon but healthy
    S.onTick()
    expect(S.state).toBe("funnel")
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

-- Restore the mock send for whoever runs after us (see the note at the top).
send = _mockSend
