--[[mudlet
type: script
name: Mnemosyne Explorer
hierarchy:
- Levi_Ataxia
- Ataxia
- Mnemosyne
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    MNEMOSYNE AUTO-EXPLORER  (mnem explore)
    ============================================================================
    Sweeps the per-ripple 4x4 room grid, clearing denizens in each room, and
    stops when the boon-selection screen appears (ripple complete). MVP: it
    sweeps to the boon screen then hands back -- you pick the boon and wade.

    Division of labour (reuses existing systems, no new combat logic):
      * COMBAT is the autobasher in MANUAL mode. Manual mode attacks whatever is
        in the room but never auto-moves (its auto-move is Mudlet-mapper based and
        can't work in the unmapped tower). Mnemosyne's no-flee/shield behaviour is
        already handled by ataxiaBasher.inMnemosyne.
      * NAVIGATION is this module. "Room clear" = ataxia.denizensHere empty of
        non-own denizens (GMCP ground truth). Movement is `queue addclear free
        <dir>` (the only thing that routes in an unmapped area). The 4x4 graph,
        unexplored-exit detection and BFS pathfinding are reused from the ripple
        map (005_Ripple_Map.lua, namespace MAP).

    Loop (event-driven): on each room-clear, step through an unexplored exit of
    the current room, or the first step toward the nearest visited room that
    still has one -- a DFS sweep with backtracking. Stop on the boon screen,
    leaving Mnemosyne, a fully-swept grid, or `mnem explore off`.

    Depends on 001 (echo), 002 (run state) and 005 (MAP). Loads after them.
    ============================================================================
]]--

ataxia.mnemosyne = ataxia.mnemosyne or {}
local M = ataxia.mnemosyne
local MAP = ataxia.mnemosyne.map

M.explore = M.explore or { on = false, moving = false, failed = {} }

local TICK_DELAY = 0.5 -- let room contents settle after an event before deciding
local MOVE_TIMEOUT = 5 -- a move that produces no arrival -> retry / unstick
local MOVE_RETRIES = 1 -- re-send a stalled move this many times before condemning the exit
local WATCHDOG = 30 -- seconds of no progress (no arrival / no denizen change) before a soft nudge
local MAX_PATROL_LOOPS = 3 -- fruitless full patrol loops (hunting the boss) before giving up
local MAX_ICE_SLIPS = 15 -- re-send a move this many times after slipping on ice before giving up on the exit

-- Check for STARTING: must be physically in the tower. Mnemosyne rooms are an
-- unmapped instance (area == ""), and we require that directly so a telemetry run
-- that outlived your presence (e.g. a missed /run_end) can't start a sweep in a
-- real area off a stale map.
local function canStart()
  return MAP and MAP.inMnem and MAP.inMnem()
    and gmcp and gmcp.Room and gmcp.Room.Info and gmcp.Room.Info.area == ""
end

-- Strict physical check for the RUNNING loop: the room-update clears
-- ataxiaBasher.inMnemosyne the instant you enter any real (mapped) area, so this
-- guarantees the explorer stops walking/fighting the moment you leave the tower.
local function inMnem()
  return ataxiaBasher ~= nil and ataxiaBasher.inMnemosyne == true
end

function M._exploreEcho(msg)
  M.echo("<gold>[explore]<reset> " .. tostring(msg))
end

-- ---------------------------------------------------------------------------
-- Room state
-- ---------------------------------------------------------------------------

-- True if `name` is one of our own pets/summons (never a kill target). Guarded:
-- ataxiaBasher_isOwnDenizen indexes ataxiaBasher, so skip it if that's absent and
-- never let it error -- an unrecognised name safely counts as a real denizen.
local function isOwnDenizen(name)
  if not (ataxiaBasher and ataxiaBasher_isOwnDenizen) then return false end
  local ok, res = pcall(ataxiaBasher_isOwnDenizen, name)
  return ok and res == true
end

-- Ground truth: does the current room still hold denizens to kill? Own
-- denizens (pets/summons) don't count.
function M._roomHasDenizens()
  local dz = ataxia.denizensHere
  if type(dz) ~= "table" then return false end
  for _, name in pairs(dz) do
    if not isOwnDenizen(name) then return true end
  end
  return false
end

-- Count of killable denizens in the current room (for progress echoes).
local function denizenCount()
  local n, dz = 0, ataxia.denizensHere
  if type(dz) == "table" then
    for _, name in pairs(dz) do
      if not isOwnDenizen(name) then n = n + 1 end
    end
  end
  return n
end

-- Unexplored exits of `num` the sweep can actually use: reported-but-unwalked,
-- not recorded as failed this session, and PLANAR (n/s/e/w + diagonals) -- the 4x4
-- is flat and there is no `up`/`in`/`out` in Mnemosyne. The ONE non-planar move
-- is the ripple's holding room's `down` into the grid, so `down` is allowed only
-- from a room that has no planar exit at all (the holding room); `up`/`in`/`out`
-- are never used, and a grid room's deeper `down` (alongside planar exits) is not
-- taken either. Used for both the current-room pick and backtrack candidacy.
local function usableUnexplored(num)
  local failed = (M.explore.failed and M.explore.failed[num]) or {}
  local room = MAP.rooms and MAP.rooms[num]
  local hasPlanar = false
  if room and room.exits then
    for d in pairs(room.exits) do
      if MAP.OFFSETS and MAP.OFFSETS[d] then hasPlanar = true; break end
    end
  end
  local out = {}
  for _, d in ipairs(MAP.unexploredExits(num) or {}) do
    local planar = MAP.OFFSETS and MAP.OFFSETS[d]
    if not failed[d] and (planar or (not hasPlanar and d == "down")) then
      out[#out + 1] = d
    end
  end
  return out
end

-- Next single-step short direction to sweep the grid: a usable unexplored exit of
-- the current room, else the first step toward the nearest visited room that has
-- one. nil when the reachable grid is fully swept.
function M._nextExploreStep()
  if not (MAP and MAP.current and MAP.rooms and MAP.rooms[MAP.current]) then return nil end
  local cur = MAP.current

  local un = usableUnexplored(cur)
  if #un > 0 then return MAP.shortDir(un[1]) end

  -- Backtrack: BFS (over walked edges) to the nearest room that still has a
  -- usable unexplored exit; take the first step of that path.
  local best
  for num, r in pairs(MAP.rooms) do
    if r.visited and num ~= cur and #usableUnexplored(num) > 0 then
      local steps = MAP.path(cur, num)
      if steps and #steps > 0 and (not best or #steps < #best) then best = steps end
    end
  end
  if best then return best[1] end
  return nil
end

-- Patrol step (boss hunt). Once the grid is swept there are no unexplored exits,
-- but a boss ripple (every 5th) spawns the boss at the end in some already-cleared
-- room -- so we re-visit visited rooms round-robin (a refilling, sorted queue) and
-- let the basher clear whatever we find. Returns the first walked-edge step toward
-- the next room to re-check, or nil if nothing is reachable. Bumps `patrolLoops`
-- each time the queue refills (a full loop), which caps the fruitless hunt.
function M._nextPatrolStep()
  if not (MAP and MAP.current and MAP.rooms) then return nil end
  local cur = MAP.current
  if not M.explore.patrolQueue or #M.explore.patrolQueue == 0 then
    M.explore.patrolQueue = {}
    for num, r in pairs(MAP.rooms) do
      if r.visited and num ~= cur then table.insert(M.explore.patrolQueue, num) end
    end
    table.sort(M.explore.patrolQueue)
    M.explore.patrolLoops = (M.explore.patrolLoops or 0) + 1
  end
  while #M.explore.patrolQueue > 0 do
    local t = M.explore.patrolQueue[1]
    if t == cur or not (MAP.rooms[t] and MAP.rooms[t].visited) then
      table.remove(M.explore.patrolQueue, 1) -- reached it / it's gone: advance
    else
      local steps = MAP.path(cur, t)
      if steps and #steps > 0 then return steps[1] end
      table.remove(M.explore.patrolQueue, 1) -- unreachable: skip
    end
  end
  return nil
end

-- ---------------------------------------------------------------------------
-- Movement + tick loop
-- ---------------------------------------------------------------------------

function M._exploreMove(dir, isRetry)
  M.explore.moving = true
  M.explore.fromRoom = MAP and MAP.current
  M.explore.fromDir = dir
  if not isRetry then
    M.explore.tries = 0
    M.explore.iceSlips = 0
    M._exploreEcho("room clear -> moving <cyan>" .. dir .. "<reset>.")
  end -- internal retries (timeout / ice) re-send silently
  -- Stand as part of the move: after clearing a room you're frequently prone, and
  -- a bare "free <dir>" would silently fail. Mirrors the basher's stand-first queue.
  local sep = (ataxia.settings and ataxia.settings.separator) or ";"
  send("queue addclear free stand" .. sep .. dir)
  if M._explMoveT then pcall(killTimer, M._explMoveT); M._explMoveT = nil end
  M._explMoveT = tempTimer(MOVE_TIMEOUT, function()
    M._explMoveT = nil
    if not (M.explore.on and M.explore.moving) then return end
    -- Still in the room we left -> the move didn't take.
    if MAP and MAP.current == M.explore.fromRoom and M.explore.fromRoom then
      if (M.explore.tries or 0) < MOVE_RETRIES then
        M.explore.tries = (M.explore.tries or 0) + 1
        return M._exploreMove(dir, true) -- retry the same exit (lag / transient prone)
      end
      -- Give up on this exit for the session so we don't retry a wall forever.
      local nd = MAP.normDir and MAP.normDir(dir)
      if nd then
        M.explore.failed[M.explore.fromRoom] = M.explore.failed[M.explore.fromRoom] or {}
        M.explore.failed[M.explore.fromRoom][nd] = true
      end
    end
    M.explore.moving = false
    M._exploreTick()
  end)
end

-- "You slip and fall on the ice as you try to leave." An icy room fails the move
-- (you fall prone) but the EXIT is fine, so keep re-sending the stand+move until we
-- actually leave -- never count it against the exit as failed, and re-arm the move
-- timeout so it doesn't fire mid-struggle. Capped at MAX_ICE_SLIPS so a permanently
-- stuck exit still yields eventually.
function M.onIceSlip()
  if not (M.explore.on and M.explore.moving and M.explore.fromDir) then return end
  M.explore.iceSlips = (M.explore.iceSlips or 0) + 1
  if M.explore.iceSlips > MAX_ICE_SLIPS then
    M._exploreEcho("<indian_red>stuck on the ice<reset> after " .. MAX_ICE_SLIPS .. " tries -- skipping this exit.")
    if M._explMoveT then pcall(killTimer, M._explMoveT); M._explMoveT = nil end
    local nd = MAP.normDir and MAP.normDir(M.explore.fromDir)
    if nd and M.explore.fromRoom then
      M.explore.failed[M.explore.fromRoom] = M.explore.failed[M.explore.fromRoom] or {}
      M.explore.failed[M.explore.fromRoom][nd] = true
    end
    M.explore.moving = false
    return M._exploreTick()
  end
  M._exploreEcho("<grey>slipped on the ice -- up and going again.")
  M._exploreMove(M.explore.fromDir, true) -- re-send (silent; keeps tries, re-arms timeout)
end

function M._scheduleTick()
  if M._explTickT then pcall(killTimer, M._explTickT); M._explTickT = nil end
  M._explTickT = tempTimer(TICK_DELAY, function()
    M._explTickT = nil
    M._exploreTick()
  end)
end

-- Stall nudge (extracted from the watchdog timer so it's unit-testable without a
-- live timer). Nothing has progressed for WATCHDOG seconds -- no arrival, no
-- denizen change. The usual cause is a STALE GMCP snapshot: we actually moved, or
-- the room actually cleared, but Achaea never pushed a fresh Room.Info /
-- Char.Items, so no event ever woke us. A QUICKLOOK forces the server to re-send
-- both -- that fires gmcp.Room / "targets updated", which re-arms us and re-ticks
-- on fresh data. ql is free (no balance) so it's cheap and safe to do every stall.
-- Then schedule a tick anyway, so we re-decide even if the ql yields no event.
function M._watchdogNudge()
  if not M.explore.on then return end
  -- A move / ice-slip is in flight: its own machinery owns this (MOVE_TIMEOUT for a
  -- lost move; onIceSlip's MAX_ICE_SLIPS cap for a stuck icy exit). A ql here would
  -- fire gmcp.Room, be mistaken for an arrival, clear `moving`, kill the ice-slip
  -- retry chain and reset its counter -- livelocking the sweep on one exit. Leave it.
  if M.explore.moving then return end
  if M._roomHasDenizens() then
    M._exploreEcho("no progress for " .. WATCHDOG .. "s -- <cyan>QL<reset> to refresh (basher may be mid-fight; <a_darkmagenta>mnem explore off<reset> if stuck).")
  else
    M._exploreEcho("<grey>no progress for " .. WATCHDOG .. "s -- <cyan>QL<reset> to refresh the room.")
  end
  send("ql")
  M._scheduleTick()
end

-- Stall watchdog: if nothing progresses for WATCHDOG seconds while running, refresh
-- the room (QL) and re-decide rather than sit silently forever -- a room that never
-- clears (a wandered-in unlearned mob, a hard affliction, the basher switched off
-- underneath) or a stale GMCP snapshot would otherwise park the sweep. Re-armed on
-- every progress event; never hard-stops on its own.
function M._armWatchdog()
  if M._explWatchT then pcall(killTimer, M._explWatchT); M._explWatchT = nil end
  M._explWatchT = tempTimer(WATCHDOG, function()
    M._explWatchT = nil
    if not M.explore.on then return end
    M._watchdogNudge() -- ql-refresh + re-tick on fresh data
    M._armWatchdog()   -- keep watching
  end)
end

function M._exploreTick()
  if not M.explore.on then return end
  if not inMnem() then return M._exploreStop("left Mnemosyne") end
  if M.explore.moving then return end -- awaiting arrival
  if M._roomHasDenizens() then
    -- basher is clearing this room; wait. Finding denizens is progress, so reset the
    -- boss-hunt counter. Announce once per room, not every tick.
    M.explore.patrolLoops = 0
    if M.explore.fightingRoom ~= MAP.current then
      M.explore.fightingRoom = MAP.current
      M._exploreEcho("clearing this room (" .. denizenCount() .. " denizen(s)) -- basher on it.")
    end
    return
  end
  M.explore.fightingRoom = nil

  local dir = M._nextExploreStep()
  if dir then -- still sweeping new ground
    M.explore.hunting = false
    M.explore.patrolLoops = 0
    M.explore.patrolQueue = nil
    return M._exploreMove(dir)
  end

  -- Grid fully swept. Don't stop: on a boss ripple (every 5th) the boss spawns at
  -- the end in some already-cleared room, so PATROL the grid to find + clear it and
  -- stop on the boon screen. Give up only after MAX_PATROL_LOOPS fruitless loops
  -- (reset whenever we find something to fight, so a real boss keeps us going).
  if not M.explore.hunting then
    M.explore.hunting = true
    M.explore.patrolLoops = 0
    M.explore.patrolQueue = nil
    M._exploreEcho("grid swept -- patrolling for a boss / straggler until the boon screen.")
  end
  if (M.explore.patrolLoops or 0) > MAX_PATROL_LOOPS then
    M._exploreEcho("no boss / straggler found after patrolling; stopping.")
    return M._exploreStop("nothing left")
  end
  local pdir = M._nextPatrolStep()
  if pdir then
    M._exploreMove(pdir)
  else
    M._exploreStop("nowhere left to patrol")
  end
end

-- ---------------------------------------------------------------------------
-- Start / stop
-- ---------------------------------------------------------------------------

function M.exploreOn()
  if M.explore.on then return M._exploreEcho("already running.") end
  if not canStart() then
    return M.echo("<indian_red>[explore]<reset> not in Mnemosyne -- nothing to sweep.")
  end
  -- Drive combat with the autobasher in MANUAL mode (attacks in place, no
  -- mapper-move) + auto-learn (so Mnemosyne denizens populate targetList[""]) +
  -- no-flee. Save prior state to restore on stop.
  ataxiaBasher = ataxiaBasher or {}
  M.explore._prevBasher = {
    enabled = ataxiaBasher.enabled, manual = ataxiaBasher.manual,
    areabash = ataxiaBasher.areabash, autoLearn = ataxiaBasher.autoLearn,
  }
  M.explore._raisedBasher = not ataxiaBasher.enabled
  ataxiaBasher.enabled = true
  ataxiaBasher.manual = true
  ataxiaBasher.areabash = false
  ataxiaBasher.autoLearn = true
  ataxiaBasher.inMnemosyne = true
  if M.explore._raisedBasher and raiseEvent then raiseEvent("basher enabled") end

  M.explore.on = true
  M.explore.moving = false
  M.explore.failed = {}
  M.explore.hunting = false
  M.explore.patrolQueue = nil
  M.explore.patrolLoops = 0
  M.explore.iceSlips = 0
  M._exploreEcho("<green>ON<reset> -- sweeping the 4x4, clearing to the boon screen (patrols for the boss on boss ripples). (<a_darkmagenta>mnem explore off<reset> to stop)")
  M._scheduleTick()
  M._armWatchdog()
end

function M._exploreStop(reason)
  if not M.explore.on then return end
  M.explore.on = false
  M.explore.moving = false
  if M._explTickT then pcall(killTimer, M._explTickT); M._explTickT = nil end
  if M._explMoveT then pcall(killTimer, M._explMoveT); M._explMoveT = nil end
  if M._explWatchT then pcall(killTimer, M._explWatchT); M._explWatchT = nil end
  -- Restore the basher to how we found it.
  local p = M.explore._prevBasher
  if p and ataxiaBasher then
    ataxiaBasher.manual = p.manual
    ataxiaBasher.areabash = p.areabash
    ataxiaBasher.autoLearn = p.autoLearn
    if M.explore._raisedBasher then
      ataxiaBasher.enabled = p.enabled
      if raiseEvent then raiseEvent("basher disabled") end
    end
  end
  M.explore._prevBasher = nil
  M._exploreEcho("<grey>off<reset>" .. (reason and (" (" .. reason .. ")") or "") .. ".")
end

function M.exploreOff()
  if not M.explore.on then return M._exploreEcho("not running.") end
  M._exploreStop("stopped")
end

function M.exploreToggle()
  if M.explore.on then M.exploreOff() else M.exploreOn() end
end

function M.exploreStatus()
  M.echo("<gold>[explore]<reset> " .. (M.explore.on and "<green>ON" or "<grey>off")
    .. "<reset> inMnem=" .. tostring(inMnem())
    .. " denizens=" .. tostring(M._roomHasDenizens())
    .. " moving=" .. tostring(M.explore.moving)
    .. " next=" .. tostring(M._nextExploreStep()))
end

-- The ripple is complete when the boon-offer screen appears; stop sweeping and
-- hand back. Called from the boon-offer trigger regardless of telemetry state.
function M.onBoonScreen()
  if M.explore.on then
    M._exploreEcho("<green>boon screen up<reset> -- ripple swept. Pick a boon and wade deeper.")
    M._exploreStop("boon screen")
  end
end

-- Slain in the tower: death boots you out of the ripple (you respawn elsewhere),
-- so a running sweep must stop -- otherwise it keeps trying to walk/fight from the
-- wrong place. No-op if not sweeping. Called from the Mnemosyne death trigger.
function M.exploreOnDeath(killer)
  if not M.explore.on then return end
  M._exploreEcho("<indian_red>slain" .. ((type(killer) == "string" and killer ~= "") and (" by " .. killer) or "") .. "<reset> -- stopping the sweep.")
  M._exploreStop("slain")
end

-- ---------------------------------------------------------------------------
-- Event hooks
-- ---------------------------------------------------------------------------

-- Arrival handler body (extracted so it's unit-testable). The map (005) records the
-- room first (loads earlier, registers first, so MAP.current is already updated when
-- we run), then we clear the moving flag and (debounced) decide the next step.
--
-- Only a REAL arrival -- the room actually changed -- ends a move. A same-room
-- Room.Info re-push must NOT be mistaken for an arrival: several things re-push the
-- current room without our having moved (our own stall-watchdog `ql`, the
-- target-not-here `ql` reflex, a stray server re-send). If we cleared `moving` on
-- those, an in-flight move -- specifically the ice-slip retry loop, the one thing
-- that keeps `moving` true past the move timeout -- would be aborted: onIceSlip's
-- `moving` guard would then drop subsequent slips and the next tick would re-issue
-- the exit as a fresh move, resetting the MAX_ICE_SLIPS counter and livelocking the
-- sweep on a stuck icy exit. So treat "moving AND still in the room we left" as
-- "not arrived yet" and leave the move/ice machinery alone.
function M._onExploreRoom()
  if not M.explore.on then return end
  local sameRoom = M.explore.moving and MAP and MAP.current ~= nil
    and MAP.current == M.explore.fromRoom
  if not sameRoom then -- a genuine arrival (or we weren't moving): end the move
    M.explore.moving = false
    if M._explMoveT then pcall(killTimer, M._explMoveT); M._explMoveT = nil end
  end
  M._scheduleTick()
  M._armWatchdog()
end

if M._explRoomH then killAnonymousEventHandler(M._explRoomH) end
M._explRoomH = registerAnonymousEventHandler("gmcp.Room", function() M._onExploreRoom() end)

-- Denizen change (killed / left / arrived): re-decide once things settle. Also
-- progress, so re-arm the watchdog.
if M._explTgtH then killAnonymousEventHandler(M._explTgtH) end
M._explTgtH = registerAnonymousEventHandler("targets updated", function()
  if not M.explore.on then return end
  M._scheduleTick()
  M._armWatchdog()
end)

-- Reload / auto-update: M (and M.explore) persist across an uninstall→install but
-- the timers don't, so a running sweep would be left half-alive with the basher
-- force-mutated. Start clean: mark it off (the user re-issues `mnem explore on`).
if M._explLoadH then killAnonymousEventHandler(M._explLoadH) end
M._explLoadH = registerAnonymousEventHandler("sysLoadEvent", function()
  M.explore.on = false
  M.explore.moving = false
  M.explore._prevBasher = nil
end)
