--[[mudlet
type: script
name: dmap Explorer
hierarchy:
- Dementia_Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    dmap auto-explorer  (dmap explore)   [ported/decoupled from LEVI 008]
    ============================================================================
    Sweeps the per-ripple 4x4 grid room-by-room and stops at the boon screen.
    Basher-FREE: navigation is this module; combat is the OPTIONAL pluggable hook
    dmap.config.attack (set via `dmap attack <cmd>`). With no attack set it's
    MAP-ONLY -- the sweep waits for you to clear each room, then moves on.

    "Room clear" = dmap.denizensHere empty of own denizens (004). Movement is
    `queue addclear free stand;<dir>` (the only thing that routes in an unmapped
    area). The 4x4 graph + BFS pathfinding (dementia-tolerant) come from dmap.map.

    Dementia handling kept intact: Room.WrongDir instant wall condemnation, ice-slip
    re-sends, move-timeout fallback, planar-only stepping, boss patrol.
    ============================================================================
]]--

dmap = dmap or {}
local MAP = dmap.map
dmap.explore = dmap.explore or { on = false, moving = false, failed = {} }

local TICK_DELAY = 0.5   -- on ARRIVAL: let the new room's denizens (Char.Items) load before deciding
local FAST_TICK = 0.15   -- on a DENIZEN change (a kill): denizensHere is current, so react quickly
local MOVE_TIMEOUT = 5    -- a move that produces no arrival -> retry / unstick
local MOVE_RETRIES = 1    -- re-send a stalled move this many times before condemning the exit
local WATCHDOG = 30       -- seconds of no progress before a soft ql nudge
local MAX_PATROL_LOOPS = 3 -- fruitless full patrol loops (boss hunt) before giving up
local MAX_ICE_SLIPS = 15  -- re-send a move this many times after ice before giving up on the exit
local ATTACK_EVERY = 1.5  -- while a room has denizens + a combat hook is set, re-send the attack this often

local EXP = dmap.explore

local function inMnem() return MAP and MAP.inMnem and MAP.inMnem() end
local function canStart() return inMnem() end

function dmap._exploreEcho(msg)
  dmap.echo("<gold>[explore]<reset> " .. tostring(msg))
end

-- ---------------------------------------------------------------------------
-- Room / grid helpers
-- ---------------------------------------------------------------------------

local function roomHasPlanarExit(num)
  local room = MAP.rooms and MAP.rooms[num]
  if not (room and room.exits) then return false end
  for d in pairs(room.exits) do
    if MAP.OFFSETS and MAP.OFFSETS[d] then return true end
  end
  return false
end

-- Unexplored exits `num` can use: reported-but-unwalked, not failed this session, and PLANAR
-- (the 4x4 is flat). `down` is allowed ONLY from a room with no planar exit (the holding room's
-- descent into the grid); up/in/out are never used.
local function usableUnexplored(num)
  local failed = (EXP.failed and EXP.failed[num]) or {}
  local hasPlanar = roomHasPlanarExit(num)
  local out = {}
  for _, d in ipairs(MAP.unexploredExits(num) or {}) do
    local planar = MAP.OFFSETS and MAP.OFFSETS[d]
    if not failed[d] and (planar or (not hasPlanar and d == "down")) then
      out[#out + 1] = d
    end
  end
  return out
end

-- A path step we'll WALK during backtrack/patrol: planar only (reject up/down/in/out so we never
-- climb out of the grid to the holding room -- MAP.path over walked edges would otherwise return it).
local function planarStep(shortD)
  local nd = MAP.normDir and MAP.normDir(shortD)
  return nd ~= nil and MAP.OFFSETS ~= nil and MAP.OFFSETS[nd] ~= nil
end

function dmap._nextExploreStep()
  if not (MAP and MAP.current and MAP.rooms and MAP.rooms[MAP.current]) then return nil end
  local cur = MAP.current
  local un = usableUnexplored(cur)
  if #un > 0 then return MAP.shortDir(un[1]) end

  -- Backtrack: nearest room with a usable unexplored exit; walked path then known-graph fallback.
  local best
  for num, r in pairs(MAP.rooms) do
    if r.visited and num ~= cur and #usableUnexplored(num) > 0 then
      local steps = MAP.path(cur, num) or (MAP.pathKnown and MAP.pathKnown(cur, num))
      if steps and #steps > 0 and planarStep(steps[1]) and (not best or #steps < #best) then best = steps end
    end
  end
  if best then return best[1] end
  return nil
end

-- Patrol step (boss hunt): round-robin re-visit of grid rooms; caps fruitless loops.
function dmap._nextPatrolStep()
  if not (MAP and MAP.current and MAP.rooms) then return nil end
  local cur = MAP.current
  if not EXP.patrolQueue or #EXP.patrolQueue == 0 then
    EXP.patrolQueue = {}
    for num, r in pairs(MAP.rooms) do
      if r.visited and num ~= cur and roomHasPlanarExit(num) then
        table.insert(EXP.patrolQueue, num)
      end
    end
    table.sort(EXP.patrolQueue)
    EXP.patrolLoops = (EXP.patrolLoops or 0) + 1
  end
  while #EXP.patrolQueue > 0 do
    local t = EXP.patrolQueue[1]
    if t == cur or not (MAP.rooms[t] and MAP.rooms[t].visited) then
      table.remove(EXP.patrolQueue, 1)
    else
      local steps = MAP.path(cur, t) or (MAP.pathKnown and MAP.pathKnown(cur, t))
      if steps and #steps > 0 and planarStep(steps[1]) then return steps[1] end
      table.remove(EXP.patrolQueue, 1)
    end
  end
  return nil
end

-- ---------------------------------------------------------------------------
-- Combat hook (optional, pluggable). Repeats the user's attack command while a room
-- has denizens; self-terminates when the room clears / we leave / the sweep stops. Off-balance
-- re-sends are simply rejected by the game, so a fixed cadence is fine.
-- ---------------------------------------------------------------------------

function dmap._stopAttacking()
  if EXP._atkT then pcall(killTimer, EXP._atkT); EXP._atkT = nil end
end

function dmap._attackLoop()
  EXP._atkT = nil
  if not (EXP.on and inMnem() and dmap.config.attack and dmap.roomHasDenizens()) then return end
  local id, name = dmap.firstDenizen()
  if id then pcall(dmap.config.attack, id, name) end
  EXP._atkT = tempTimer(ATTACK_EVERY, dmap._attackLoop)
end

function dmap._startAttacking()
  if EXP._atkT then return end
  dmap._attackLoop()
end

-- ---------------------------------------------------------------------------
-- Movement + tick loop
-- ---------------------------------------------------------------------------

function dmap._exploreMove(dir, isRetry)
  dmap._stopAttacking()
  EXP.moving = true
  EXP.fromRoom = MAP and MAP.current
  EXP.fromDir = dir
  if not isRetry then
    EXP.tries = 0
    EXP.iceSlips = 0
    dmap._exploreEcho("room clear -> moving <cyan>" .. dir .. "<reset>.")
  end
  local sep = (dmap.config and dmap.config.separator) or ";"
  send("queue addclear free stand" .. sep .. dir)
  if EXP._moveT then pcall(killTimer, EXP._moveT); EXP._moveT = nil end
  EXP._moveT = tempTimer(MOVE_TIMEOUT, function()
    EXP._moveT = nil
    if not (EXP.on and EXP.moving) then return end
    if MAP and MAP.current == EXP.fromRoom and EXP.fromRoom then
      if (EXP.tries or 0) < MOVE_RETRIES then
        EXP.tries = (EXP.tries or 0) + 1
        return dmap._exploreMove(dir, true)
      end
      local nd = MAP.normDir and MAP.normDir(dir)
      if nd then
        EXP.failed[EXP.fromRoom] = EXP.failed[EXP.fromRoom] or {}
        EXP.failed[EXP.fromRoom][nd] = true
      end
    end
    EXP.moving = false
    dmap._exploreTick()
  end)
end

-- Ice slip: the move failed (fell prone) but the exit is fine -- re-send, don't condemn.
function dmap.exploreIceSlip()
  if not (EXP.on and EXP.moving and EXP.fromDir) then return end
  EXP.iceSlips = (EXP.iceSlips or 0) + 1
  if EXP.iceSlips > MAX_ICE_SLIPS then
    dmap._exploreEcho("<indian_red>stuck on the ice<reset> after " .. MAX_ICE_SLIPS .. " tries -- skipping this exit.")
    if EXP._moveT then pcall(killTimer, EXP._moveT); EXP._moveT = nil end
    local nd = MAP.normDir and MAP.normDir(EXP.fromDir)
    if nd and EXP.fromRoom then
      EXP.failed[EXP.fromRoom] = EXP.failed[EXP.fromRoom] or {}
      EXP.failed[EXP.fromRoom][nd] = true
    end
    EXP.moving = false
    return dmap._exploreTick()
  end
  dmap._exploreEcho("<grey>slipped on the ice -- up and going again.")
  dmap._exploreMove(EXP.fromDir, true)
end

-- Room.WrongDir: server-authoritative wall -> condemn instantly + prune the faked exit.
function dmap._onWrongDir(dir)
  if not (EXP.on and EXP.moving) then return end
  local nd = MAP and MAP.normDir and MAP.normDir(dir)
  if not nd then return end
  local from = EXP.fromRoom or (MAP and MAP.current)
  if from then
    EXP.failed[from] = EXP.failed[from] or {}
    EXP.failed[from][nd] = true
    if MAP.rooms and MAP.rooms[from] and MAP.rooms[from].exits then
      MAP.rooms[from].exits[nd] = nil
    end
  end
  if EXP._moveT then pcall(killTimer, EXP._moveT); EXP._moveT = nil end
  EXP.moving = false
  if MAP then MAP._lastMoveDir = nil end
  dmap._exploreEcho("<red>wall<reset> (" .. tostring(dir) .. ", server) -> condemned; rerouting.")
  dmap._scheduleTick()
end

function dmap._scheduleTick(delay)
  if EXP._tickT then pcall(killTimer, EXP._tickT); EXP._tickT = nil end
  EXP._tickT = tempTimer(delay or TICK_DELAY, function()
    EXP._tickT = nil
    dmap._exploreTick()
  end)
end

function dmap._watchdogNudge()
  if not EXP.on or EXP.pausedAtBoon then return end
  if EXP.moving then return end
  dmap._exploreEcho("<grey>no progress for " .. WATCHDOG .. "s -- <cyan>ql<reset> to refresh.")
  send("ql")
  dmap._scheduleTick()
end

function dmap._armWatchdog()
  if EXP._watchT then pcall(killTimer, EXP._watchT); EXP._watchT = nil end
  EXP._watchT = tempTimer(WATCHDOG, function()
    EXP._watchT = nil
    if not EXP.on or EXP.pausedAtBoon then return end
    dmap._watchdogNudge()
    dmap._armWatchdog()
  end)
end

function dmap._exploreTick()
  if not EXP.on then return end
  if not inMnem() then return dmap.exploreStop("left Mnemosyne") end
  if EXP.pausedAtBoon then return end
  if EXP.moving then return end
  EXP.settling = false

  if dmap.roomHasDenizens() then
    EXP.patrolLoops = 0
    if EXP.fightingRoom ~= MAP.current then
      EXP.fightingRoom = MAP.current
      dmap._exploreEcho("clearing this room (" .. dmap.denizenCount() .. " denizen(s))"
        .. (dmap.config.attack and " -- attacking." or " -- waiting (map-only; set <cyan>dmap attack<reset> for auto-combat)."))
    end
    if dmap.config.attack then dmap._startAttacking() end
    return
  end
  dmap._stopAttacking()
  EXP.fightingRoom = nil

  local dir = dmap._nextExploreStep()
  if dir then
    EXP.hunting = false
    EXP.patrolLoops = 0
    EXP.patrolQueue = nil
    return dmap._exploreMove(dir)
  end

  -- Grid swept: patrol for a boss/straggler until the boon screen; cap fruitless loops.
  if not EXP.hunting then
    EXP.hunting = true
    EXP.patrolLoops = 0
    EXP.patrolQueue = nil
    dmap._exploreEcho("grid swept -- patrolling for a boss / straggler until the boon screen.")
  end
  if (EXP.patrolLoops or 0) > MAX_PATROL_LOOPS then
    dmap._exploreEcho("no boss / straggler found after patrolling; stopping.")
    return dmap.exploreStop("nothing left")
  end
  local pdir = dmap._nextPatrolStep()
  if pdir then
    dmap._exploreMove(pdir)
  else
    -- One second chance for blacklisted exits before giving up (spurious timeout/prone).
    local hasFailed = false
    for _ in pairs(EXP.failed or {}) do hasFailed = true; break end
    if hasFailed and not EXP._retriedFailed then
      EXP._retriedFailed = true
      EXP.failed = {}
      dmap._exploreEcho("<grey>clearing failed exits and retrying before giving up.")
      return dmap._exploreTick()
    end
    dmap.exploreStop("nowhere left to patrol")
  end
end

-- ---------------------------------------------------------------------------
-- Start / stop / resume
-- ---------------------------------------------------------------------------

local function resetSweepState()
  EXP.moving = false
  EXP.failed = {}
  EXP._retriedFailed = nil
  EXP.hunting = false
  EXP.patrolQueue = nil
  EXP.patrolLoops = 0
  EXP.iceSlips = 0
  EXP.settling = true -- treat the current room like an arrival: let denizens settle first
end

function dmap._exploreResume(reason)
  EXP.pausedAtBoon = false
  resetSweepState()
  dmap._exploreEcho("<green>resuming<reset> the sweep" .. (reason and (" (" .. reason .. ")") or "") .. ".")
  dmap._scheduleTick()
  dmap._armWatchdog()
end

function dmap.exploreOnGo()
  if not EXP.pausedAtBoon then return end
  send("look")
  dmap._exploreResume("GO")
end

function dmap.exploreStart()
  if EXP.on and EXP.pausedAtBoon then return dmap._exploreResume() end
  if EXP.on then return dmap._exploreEcho("already running.") end
  if not canStart() then
    return dmap.echo("<indian_red>[explore]<reset> not in a Mnemosyne ripple -- nothing to sweep.")
  end
  EXP.on = true
  resetSweepState()
  dmap._exploreEcho("<green>ON<reset> -- sweeping the 4x4 to the boon screen"
    .. (dmap.config.attack and " (auto-combat on)" or " (map-only: clear each room yourself)")
    .. ". <a_darkmagenta>dmap explore off<reset> to stop.")
  dmap._scheduleTick()
  dmap._armWatchdog()
end

function dmap.exploreStop(reason)
  if not EXP.on then
    if reason == "user" then dmap._exploreEcho("not running.") end
    return
  end
  EXP.on = false
  EXP.pausedAtBoon = false
  EXP.moving = false
  dmap._stopAttacking()
  if EXP._tickT then pcall(killTimer, EXP._tickT); EXP._tickT = nil end
  if EXP._moveT then pcall(killTimer, EXP._moveT); EXP._moveT = nil end
  if EXP._watchT then pcall(killTimer, EXP._watchT); EXP._watchT = nil end
  dmap._exploreEcho("<grey>off<reset>" .. (reason and (" (" .. reason .. ")") or "") .. ".")
end

function dmap.exploreStatus()
  dmap.echo("<gold>[explore]<reset> " .. (EXP.on and (EXP.pausedAtBoon and "<cyan>paused (boon screen)" or "<green>ON") or "<grey>off")
    .. "<reset> inMnem=" .. tostring(inMnem())
    .. " denizens=" .. tostring(dmap.roomHasDenizens())
    .. " combat=" .. (dmap.config.attack and "on" or "off (map-only)")
    .. " moving=" .. tostring(EXP.moving)
    .. " next=" .. tostring(dmap._nextExploreStep()))
end

-- Ripple complete -> boon screen appears. PAUSE navigation (pick a boon + wade); resume on GO
-- or `dmap explore on`. `on` stays true so leave-tower / death / `off` still stop cleanly.
function dmap.exploreOnBoonScreen()
  if not EXP.on or EXP.pausedAtBoon then return end
  EXP.pausedAtBoon = true
  EXP.moving = false
  dmap._stopAttacking()
  if EXP._tickT then pcall(killTimer, EXP._tickT); EXP._tickT = nil end
  if EXP._moveT then pcall(killTimer, EXP._moveT); EXP._moveT = nil end
  if EXP._watchT then pcall(killTimer, EXP._watchT); EXP._watchT = nil end
  dmap._exploreEcho("<green>boon screen up<reset> -- ripple swept. Pick a boon and wade (<a_darkmagenta>dmap explore on<reset> to resume).")
end

function dmap.exploreOnDeath(killer)
  if not EXP.on then return end
  dmap._exploreEcho("<indian_red>slain" .. ((type(killer) == "string" and killer ~= "") and (" by " .. killer) or "") .. "<reset> -- stopping the sweep.")
  dmap.exploreStop("slain")
end

-- ---------------------------------------------------------------------------
-- Event hooks
-- ---------------------------------------------------------------------------

-- Arrival: only a REAL room change ends a move (a same-room re-push -- our ql, a stray re-send --
-- must not abort the in-flight move / ice-slip retry chain).
function dmap._onExploreRoom()
  if not EXP.on then return end
  local sameRoom = EXP.moving and MAP and MAP.current ~= nil and MAP.current == EXP.fromRoom
  if not sameRoom then
    EXP.moving = false
    if EXP._moveT then pcall(killTimer, EXP._moveT); EXP._moveT = nil end
    EXP.settling = true
  end
  dmap._scheduleTick()
  dmap._armWatchdog()
end

dmap._handlers = dmap._handlers or {}
local function reg(ev, fn)
  if dmap._handlers[ev] then pcall(killAnonymousEventHandler, dmap._handlers[ev]) end
  dmap._handlers[ev] = registerAnonymousEventHandler(ev, fn)
end

reg("gmcp.Room", "dmap._onExploreRoom")
-- Denizen change (kill / arrival): re-decide. Fast after a kill; full settle window on arrival.
reg("dmap denizens updated", function()
  if not EXP.on then return end
  dmap._scheduleTick(EXP.settling and TICK_DELAY or FAST_TICK)
  dmap._armWatchdog()
end)
reg("gmcp.Room.WrongDir", function()
  dmap._onWrongDir(gmcp and gmcp.Room and gmcp.Room.WrongDir)
end)
-- Reload / auto-update: timers don't survive but EXP does -- mark off so a half-alive sweep can't run.
reg("sysLoadEvent", function()
  EXP.on = false
  EXP.pausedAtBoon = false
  EXP.moving = false
  dmap._stopAttacking()
end)
