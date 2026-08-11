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

local TICK_DELAY = 0.5 -- on ARRIVAL: let the new room's denizens (Char.Items) load before deciding, so we don't walk past a room whose mobs hadn't arrived yet
local FAST_TICK = 0.15 -- on a DENIZEN change (a kill): denizensHere is already current, so react quickly -- snappier "killed the last mob -> move on"
local MOVE_TIMEOUT = 5 -- a move that produces no arrival -> retry / unstick
local MOVE_RETRIES = 1 -- re-send a stalled move this many times before condemning the exit
local WATCHDOG = 30 -- seconds of no progress (no arrival / no denizen change) before a soft nudge
local HAEMO_MOVE_HP = 90 -- Haemophiliac affix: hold navigation below this HP% (kills bleed thousands)
local HAEMO_MOVE_BLEED = 50 -- ...and while bleeding above this (SSC clots it down; we stand still meanwhile)
local MAX_PATROL_LOOPS = 3 -- fruitless full patrol loops (hunting the boss) before giving up
local MAX_ICE_SLIPS = 15 -- re-send a move this many times after slipping on ice before giving up on the exit
-- A TACTICAL move gets a far smaller budget (v4.7.243). 15 re-sends is defensible for an idle
-- sweep that has all day; under fire it is 13 seconds of standing in the room we are trying to
-- flee. The caves-beneath-Kuthalebak death log spent exactly that, slipping, while three
-- infested Vertani did ~2,150 HP/s to an ~18,700 pool.
local MAX_TACTICAL_ICE_SLIPS = 3

-- Check for STARTING: must be physically in the tower. This used to also require
-- gmcp.Room.Info.area == "" as direct proof, so a telemetry run that outlived your presence
-- (e.g. a missed /run_end) couldn't start a sweep in a real area off a stale map. But DEMENTIA
-- hallucinates a real area while we are still inside the tower, and that blocked the sweep
-- outright -- the explorer simply refused to start. ataxiaBasher.inMnemosyne (= MAP.inMnem) is
-- now SURVEY-verified rather than inferred from the area (see ataxiaBasher_mnemLeftMaybe):
-- SURVEY is free and still tells the truth while demented, and a stale flag now self-clears on
-- the next room change instead of lingering. So the verified flag is the better authority, and
-- the raw-area check only re-introduced the dementia blind spot.
local function canStart()
  return MAP and MAP.inMnem and MAP.inMnem()
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

-- Count of killable denizens in the current room (progress echoes + the swarm
-- module's assess threshold -- public so 009 and the tests can read it).
function M._denizenCount()
  local n, dz = 0, ataxia.denizensHere
  if type(dz) == "table" then
    for _, name in pairs(dz) do
      if not isOwnDenizen(name) then n = n + 1 end
    end
  end
  return n
end
local denizenCount = M._denizenCount

-- Does the room have any planar (grid) exit? A room with NONE is the ripple's entry
-- holding room (only `down`), not part of the 4x4 -- never a sweep or patrol goal.
local function roomHasPlanarExit(num)
  local room = MAP.rooms and MAP.rooms[num]
  if not (room and room.exits) then return false end
  for d in pairs(room.exits) do
    if MAP.OFFSETS and MAP.OFFSETS[d] then return true end
  end
  return false
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
  local hasPlanar = roomHasPlanarExit(num)
  local out = {}
  for _, d in ipairs(MAP.unexploredExits(num) or {}) do
    local planar = MAP.OFFSETS and MAP.OFFSETS[d]
    -- An exit that would leave the ripple's 4x4 cannot be real, so do not spend a move on it
    -- (v4.7.249). Under DEMENTIA the game reports invented exits through the same gmcp channel
    -- as the true ones -- "You see exits leading north and west" in a room that has neither --
    -- and walking one costs MOVE_TIMEOUT plus a retry before Room.WrongDir or the timeout
    -- condemns it. The geometry knows in advance, and only ever rejects a provable overflow.
    local fits = (MAP.exitFitsGrid == nil) or MAP.exitFitsGrid(num, d)
    if not failed[d] and fits and (planar or (not hasPlanar and d == "down")) then
      out[#out + 1] = d
    end
  end
  return out
end

-- A path step (short dir, e.g. "n"/"u") we're willing to WALK during backtrack /
-- patrol: planar only. The grid is flat and planar-connected; the ONE non-planar
-- walked edge is the holding room's down/up (the ripple entry). MAP.path is BFS over
-- walked edges and happily returns the `up` back to the holding room -- climbing out
-- of the grid. That was the "explorer went up" bug. Reject u/d/in/out here (the
-- forward descent `down` is handled by usableUnexplored, not by a path step).
local function planarStep(shortD)
  local nd = MAP.normDir and MAP.normDir(shortD)
  return nd ~= nil and MAP.OFFSETS ~= nil and MAP.OFFSETS[nd] ~= nil
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
  -- usable unexplored exit; take the first step of that path -- but never a
  -- non-planar step (that would climb `up` out of the grid to the holding room).
  local best
  for num, r in pairs(MAP.rooms) do
    if r.visited and num ~= cur and #usableUnexplored(num) > 0 then
      -- Prefer the walked path; fall back to the known-room graph so a walked-graph gap
      -- (dropped edge in the demented tower) can't strand a placed, unexplored room.
      local steps = MAP.path(cur, num) or (MAP.pathKnown and MAP.pathKnown(cur, num))
      if steps and #steps > 0 and planarStep(steps[1]) and (not best or #steps < #best) then best = steps end
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
      -- Only re-visit 4x4 grid rooms; skip the pure-vertical holding room (a boss
      -- never spawns there, and pathing to it is what tried to walk `up`).
      if r.visited and num ~= cur and roomHasPlanarExit(num) then
        table.insert(M.explore.patrolQueue, num)
      end
    end
    table.sort(M.explore.patrolQueue)
    M.explore.patrolLoops = (M.explore.patrolLoops or 0) + 1
  end
  while #M.explore.patrolQueue > 0 do
    local t = M.explore.patrolQueue[1]
    if t == cur or not (MAP.rooms[t] and MAP.rooms[t].visited) then
      table.remove(M.explore.patrolQueue, 1) -- reached it / it's gone: advance
    else
      local steps = MAP.path(cur, t) or (MAP.pathKnown and MAP.pathKnown(cur, t))
      -- Skip a target whose first step is non-planar: that's the holding room (up
      -- out of the grid). The boss spawns in the 4x4, never the entry holding room.
      if steps and #steps > 0 and planarStep(steps[1]) then return steps[1] end
      table.remove(M.explore.patrolQueue, 1) -- unreachable / non-planar first step: skip
    end
  end
  return nil
end

-- ---------------------------------------------------------------------------
-- Movement + tick loop
-- ---------------------------------------------------------------------------

function M._exploreMove(dir, isRetry)
  -- Never move while a tumble is in flight (v4.7.243): a walk between "You begin to tumble"
  -- and "You tumble out of the room." cancels it. The swarm's own machinery re-decides once
  -- the tumble resolves (S.onTumbleDone), so dropping the step here loses nothing.
  if M.swarm and M.swarm.moveLocked and M.swarm.moveLocked() then return end
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
  -- HOMEBOUND boon (Runewarden, v4.7.163): "Returning to your raido cures you of all
  -- afflictions and restores you to full health. Not effective in the same location."
  -- The raido has to be laid somewhere we will NOT be standing, and the holding room is
  -- exactly that: we descend out of it and fight the whole 4x4 below. So sketch it on the
  -- ground in the holding room immediately before the descent -- the one `down` that
  -- leaves a room with no planar exits (see usableUnexplored). Once per ripple.
  local pre = ""
  if mnemHomebound and dir == "down" and not M._raidoRipple then
    M._raidoRipple = true
    pre = "sketch raido on ground" .. sep
    M._exploreEcho("<cyan>Homebound<reset> -- raido sketched in the holding room.")
  end
  send("queue addclear free stand" .. sep .. pre .. dir)
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
      -- Give up on this exit for the session so we don't retry a wall forever --
      -- UNLESS this was a swarm-tactics move: those walk KNOWN edges (we just came
      -- through them), and condemning a real exit would poison the sweep.
      local nd = MAP.normDir and MAP.normDir(dir)
      if nd and not M.explore.tacticalMove then
        M.explore.failed[M.explore.fromRoom] = M.explore.failed[M.explore.fromRoom] or {}
        M.explore.failed[M.explore.fromRoom][nd] = true
      end
    end
    M.explore.moving = false
    if M.explore.tacticalMove then
      M.explore.tacticalMove = false
      if M.swarm and M.swarm.onMoveFailed then pcall(M.swarm.onMoveFailed) end
    end
    M._exploreTick()
  end)
end

-- Arm the in-flight machinery for a SWARM-TACTICS move whose actual send rides the
-- attack chain (or is sent by 009 itself). Same guards as _exploreMove -- one move in
-- flight, timeout recovery -- but flagged so no failure path ever condemns the walked
-- edge into explore.failed. `timeout` overrides MOVE_TIMEOUT for moves that wait on a
-- queued balance chain (the pull) so the hold isn't cleared under a still-live chain.
function M._tacticalArm(dir, timeout)
  M.explore.moving = true
  M.explore.tacticalMove = true
  M.explore.fromRoom = MAP and MAP.current
  M.explore.fromDir = dir
  M.explore.tries = 0
  M.explore.iceSlips = 0
  if M._explMoveT then pcall(killTimer, M._explMoveT); M._explMoveT = nil end
  M._explMoveT = tempTimer(timeout or MOVE_TIMEOUT, function()
    M._explMoveT = nil
    if not M.explore.moving then return end
    M.explore.moving = false
    M.explore.tacticalMove = false
    if M.swarm and M.swarm.onMoveFailed then pcall(M.swarm.onMoveFailed) end
    M._scheduleTick()
  end)
end

-- Cancel an in-flight move WITHOUT any failure/condemn callback: the swarm module is
-- seizing control (emergency escape at crash HP) and a stale `moving` flag would gate
-- every later tick -- including the recovery hover's own self-tick loop. A genuine
-- explorer move that gets disarmed is simply re-decided on the next decidable tick.
function M._disarmMove()
  if M._explMoveT then pcall(killTimer, M._explMoveT); M._explMoveT = nil end
  M.explore.moving = false
  M.explore.tacticalMove = false
end

-- "You slip and fall on the ice as you try to leave." An icy room fails the move
-- (you fall prone) but the EXIT is fine, so keep re-sending the stand+move until we
-- actually leave -- never count it against the exit as failed, and re-arm the move
-- timeout so it doesn't fire mid-struggle. Capped at MAX_ICE_SLIPS so a permanently
-- stuck exit still yields eventually.
function M.onIceSlip()
  if not (M.explore.on and M.explore.moving and M.explore.fromDir) then return end
  -- A tumble in flight owns the movement (v4.7.243) -- do not count its slip or re-send under it.
  if M.swarm and M.swarm.moveLocked and M.swarm.moveLocked() then return end
  M.explore.iceSlips = (M.explore.iceSlips or 0) + 1
  -- TACTICAL moves get their own, much smaller budget (v4.7.243).
  local tactical = M.explore.tacticalMove and true or false
  local cap = tactical and MAX_TACTICAL_ICE_SLIPS or MAX_ICE_SLIPS
  if M.explore.iceSlips > cap then
    M._exploreEcho("<indian_red>stuck on the ice<reset> after " .. cap .. " tries -- skipping this exit.")
    if M._explMoveT then pcall(killTimer, M._explMoveT); M._explMoveT = nil end
    local nd = MAP.normDir and MAP.normDir(M.explore.fromDir)
    if nd and M.explore.fromRoom and not M.explore.tacticalMove then -- never condemn a walked tactical edge
      M.explore.failed[M.explore.fromRoom] = M.explore.failed[M.explore.fromRoom] or {}
      M.explore.failed[M.explore.fromRoom][nd] = true
    end
    M.explore.moving = false
    if M.explore.tacticalMove then
      M.explore.tacticalMove = false
      if M.swarm and M.swarm.onMoveFailed then pcall(M.swarm.onMoveFailed) end
    end
    return M._exploreTick()
  end
  -- RE-SEND THE REAL COMMAND (v4.7.243). `_exploreMove` sends a bare `stand;<dir>` WALK. For a
  -- sweep step that is exactly right; for a tactical retreat it is the wrong command entirely --
  -- it discards the `leap`/`backflip` the escape was, and a walk into our own standing icewall
  -- silently fails. The death log shows this looping: "slipped on the ice -- up and going again"
  -- against a room reporting "An icewall is here, blocking passage to the north".
  --
  -- So hand tactical slips back to the swarm, which re-sends its OWN verb via `_tacticalGo`
  -- (bounded by S.PULL_RETRIES, hold re-armed, route anchor restored). `M.explore.moving` must
  -- be cleared first or S.onMoveFailed's re-arm would collide with the in-flight move it is
  -- replacing.
  if tactical then
    M._exploreEcho("<grey>slipped on the ice mid-retreat -- <cyan>re-sending the retreat<reset>.")
    if M._explMoveT then pcall(killTimer, M._explMoveT); M._explMoveT = nil end
    M.explore.moving = false
    M.explore.tacticalMove = false
    if M.swarm and M.swarm.onMoveFailed then pcall(M.swarm.onMoveFailed) end
    return
  end
  M._exploreEcho("<grey>slipped on the ice -- up and going again.")
  M._exploreMove(M.explore.fromDir, true) -- re-send (silent; keeps tries, re-arms timeout)
end

-- "A wall blocks your way." / "A wall bars your path." (trigger 025): an icewall --
-- ours from the swarm tactic, or any affix/denizen wall -- rejects a WALK but not a
-- chitin-greaves LEAP (user-directed: leap it). The exit is REAL, so like the ice
-- slip this must never condemn it: replace the in-flight move with a leap and let
-- the already-armed move timer keep watching (its walk-retry just earns another
-- wall line -> another leap). Shares the ice-slip budget so a wall that somehow
-- defeats the leap still yields eventually.
function M.onWallBlocked()
  if not (M.explore.on and M.explore.moving and M.explore.fromDir) then return end
  if M.swarm and M.swarm.moveLocked and M.swarm.moveLocked() then return end -- v4.7.243
  M.explore.iceSlips = (M.explore.iceSlips or 0) + 1
  if M.explore.iceSlips > MAX_ICE_SLIPS then
    M._exploreEcho("<indian_red>wall would not yield<reset> after " .. MAX_ICE_SLIPS .. " leaps -- giving up on this exit.")
    if M._explMoveT then pcall(killTimer, M._explMoveT); M._explMoveT = nil end
    local nd = MAP.normDir and MAP.normDir(M.explore.fromDir)
    if nd and M.explore.fromRoom and not M.explore.tacticalMove then -- never condemn a walked tactical edge
      M.explore.failed[M.explore.fromRoom] = M.explore.failed[M.explore.fromRoom] or {}
      M.explore.failed[M.explore.fromRoom][nd] = true
    end
    M.explore.moving = false
    if M.explore.tacticalMove then
      M.explore.tacticalMove = false
      if M.swarm and M.swarm.onMoveFailed then pcall(M.swarm.onMoveFailed) end
    end
    return M._exploreTick()
  end
  local nd = (MAP.normDir and MAP.normDir(M.explore.fromDir)) or M.explore.fromDir
  local short = (MAP.shortDir and MAP.shortDir(nd)) or M.explore.fromDir
  local sep = (ataxia.settings and ataxia.settings.separator) or ";"
  send("queue addclear free stand" .. sep .. "leap " .. short)
  M._exploreEcho("<grey>a wall blocks the way -- <cyan>leaping it<reset>.")
end

-- gmcp Room.WrongDir: the server tells us the direction we just tried does not exist -- an
-- AUTHORITATIVE wall signal. Condemn the exit immediately instead of waiting out MOVE_TIMEOUT
-- (~10s with the one retry), and PRUNE it from the reported-exit graph so MAP.pathKnown/relayout
-- stop routing through a dementia-faked exit (005 otherwise leaves faked exits in .exits and the
-- sweep dead-ends "nowhere left to patrol"). Only acts on an in-flight explorer move; the failed
-- direction comes straight from the server body, not our reconstructed move-dir. Distinct from an
-- ice slip (move failed but exit is real -> onIceSlip re-sends) -- WrongDir fires ONLY for a truly
-- nonexistent exit, so it's safe to condemn outright.
function M.onWrongDir(dir)
  if not (M.explore.on and M.explore.moving) then return end
  local nd = MAP and MAP.normDir and MAP.normDir(dir)
  if not nd then return end
  local from = M.explore.fromRoom or (MAP and MAP.current)
  if from and not M.explore.tacticalMove then -- a tactical move walks a KNOWN edge; never condemn it
    M.explore.failed[from] = M.explore.failed[from] or {}
    M.explore.failed[from][nd] = true
    if MAP.rooms and MAP.rooms[from] and MAP.rooms[from].exits then
      MAP.rooms[from].exits[nd] = nil -- drop the non-existent exit from the known graph
    end
  end
  if M._explMoveT then pcall(killTimer, M._explMoveT); M._explMoveT = nil end
  M.explore.moving = false
  if M.explore.tacticalMove then
    M.explore.tacticalMove = false
    if M.swarm and M.swarm.onMoveFailed then pcall(M.swarm.onMoveFailed) end
    M._exploreEcho("<red>wall<reset> (" .. tostring(dir) .. ", server) on a tactical move -- reassessing.")
  else
    M._exploreEcho("<red>wall<reset> (" .. tostring(dir) .. ", server) -> condemned; rerouting.")
  end
  if MAP then MAP._lastMoveDir = nil end
  M._scheduleTick()
end

-- delay defaults to TICK_DELAY (the arrival settle time). Pass FAST_TICK after a
-- denizen change, where denizensHere is already current and we want to move on fast.
function M._scheduleTick(delay)
  if M._explTickT then pcall(killTimer, M._explTickT); M._explTickT = nil end
  M._explTickT = tempTimer(delay or TICK_DELAY, function()
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
  if not M.explore.on or M.explore.pausedAtBoon then return end
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
    if not M.explore.on or M.explore.pausedAtBoon then return end
    M._watchdogNudge() -- ql-refresh + re-tick on fresh data
    M._armWatchdog()   -- keep watching
  end)
end

-- Haemophiliac affix pacing predicate: TRUE while post-clear navigation should hold --
-- the kill's bleed must be CLOTTED before moving on (user spec), not just outlasted:
-- SSC's `curing clotat` (installed at 30) does the clotting, spending the affix's +20%
-- mana; our job is to stand still while it works. `ataxia.vitals.bleed` is live per
-- prompt (gmcp charstats "Bleed: N"). Hold while bleeding OR while HP is still down.
-- Pure (globals only); unit-tested. The flag is set by trigger 029 via
-- onHaemophiliacSeen (004) and cleared on run start / confirmed run end.
-- Last Word affix pacing predicate ("Denizens explode on death!", user spec 2026-08-02):
-- move to the next room only at >= 90% HP. The explosion lands at the exact moment the room
-- goes quiet -- i.e. the moment the sweep wants to walk on -- so without this the next
-- fight starts on a pool the last corpse already bit into.
--
-- Shares HAEMO_MOVE_HP with the Haemophiliac hold because the user set both to 90, but does
-- NOT share the bleed clause: an explosion is instantaneous, so there is nothing for SSC to
-- clot down and nothing to wait on but regeneration. Pure (globals only); unit-tested. The
-- flag is set by trigger 056 via onLastWordSeen (004), reset on run start and cleared on the
-- confirmed run end.
function M._lastWordHold()
  if not mnemLastWord then return false end
  local hp = tonumber(ataxia and ataxia.vitals and ataxia.vitals.hpp) or 100
  return hp < HAEMO_MOVE_HP
end

function M._haemoHold()
  if not mnemHaemophiliac then return false end
  local v = ataxia and ataxia.vitals
  local bleed = tonumber(v and v.bleed) or 0
  local hp = tonumber(v and v.hpp) or 100
  return bleed >= HAEMO_MOVE_BLEED or hp < HAEMO_MOVE_HP
end

function M._exploreTick()
  if not M.explore.on then return end
  if not inMnem() then return M._exploreStop("left Mnemosyne") end
  if M.explore.pausedAtBoon then return end -- paused at the boon screen: leave-tower handled above; don't navigate
  if M.explore.moving then return end -- awaiting arrival
  -- A tick ran in a decidable state, so the post-arrival settle window is over: the
  -- room's denizens have had the full TICK_DELAY of quiet to load (each load re-armed
  -- the tick while `settling`). From here, denizen changes (kills) may react fast.
  M.explore.settling = false
  -- Swarm tactics (009) get first look at every decidable tick: assess a crowded
  -- room, hold navigation while pulling/funneling, drive re-entry. Consumed tick =
  -- the sweep must neither announce nor navigate. Loads after us, hence the guard.
  if M.swarm and M.swarm.onTick then
    local ok, consumed = pcall(M.swarm.onTick)
    if ok and consumed then return end
  end
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

  -- Haemophiliac affix pacing (user-directed: "wade significantly slower"): the room
  -- is clear but the kill's bleed is still draining -- thousands of HP per kill.
  -- Charging into the next room mid-bleed stacks the next fight onto a draining
  -- pool, so hold navigation until HP recovers, re-checking on a short timer.
  if M._haemoHold() then
    if not M.explore._haemoWait then
      M.explore._haemoWait = true
      local bleed = tonumber(ataxia and ataxia.vitals and ataxia.vitals.bleed) or 0
      M._exploreEcho("<indian_red>Haemophiliac<reset> -- clotting the bleed down before moving on"
        .. (bleed > 0 and (" (bleeding " .. bleed .. ")") or "") .. ".")
    end
    M._scheduleTick(1.5)
    return
  end
  M.explore._haemoWait = nil

  -- Last Word affix pacing (user-directed, 2026-08-02): "Denizens explode on death!" -- the
  -- damage lands exactly as the room goes quiet, which is exactly when we would otherwise
  -- walk. Hold until 90% HP so the next room's fight does not open on a bitten-into pool.
  -- Checked AFTER the haemophiliac hold purely so its echo wins when both affixes are up;
  -- either one holding is sufficient, and both use the same 1.5s re-check.
  if M._lastWordHold() then
    if not M.explore._lastWordWait then
      M.explore._lastWordWait = true
      local hp = tonumber(ataxia and ataxia.vitals and ataxia.vitals.hpp) or 0
      M._exploreEcho("<indian_red>Last Word<reset> -- denizens explode on death; healing to 90% before moving on"
        .. " (at " .. hp .. "%).")
    end
    M._scheduleTick(1.5)
    return
  end
  M.explore._lastWordWait = nil

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
    -- Before giving up: if we've blacklisted any exits this ripple, give them ONE second
    -- chance (a spurious move-timeout / lingering prone shouldn't permanently strand a real
    -- exit). Clear the failed set and re-decide once per ripple; if it's a genuine wall it
    -- just re-fails and we quit next time.
    local hasFailed = false
    for _ in pairs(M.explore.failed or {}) do hasFailed = true; break end
    if hasFailed and not M.explore._retriedFailed then
      M.explore._retriedFailed = true
      M.explore.failed = {}
      M._exploreEcho("<grey>clearing failed exits and retrying before giving up.")
      return M._exploreTick()
    end
    M._exploreStop("nowhere left to patrol")
  end
end

-- ---------------------------------------------------------------------------
-- Start / stop
-- ---------------------------------------------------------------------------

-- WEAR ARMOUR before a sweep starts (v4.7.175, user-directed). Diving a ripple without
-- armour is a silent, entirely avoidable damage multiplier, and armour comes off for all
-- sorts of ordinary reasons (a morph, a swap, a death). Cheap insurance: WEAR costs no
-- balance, so this rides any round, and re-wearing what is already on is a harmless no-op
-- ("You are already wearing this item.").
--
-- Sent DIRECTLY rather than queued: the basher rebuilds its command every prompt with
-- `queue addclearfull`, which wipes queued lines -- the same reason the hyena/falcon
-- passive orders and the disarm recovery bypass the queue.
function M._wearArmour()
  send("wear armour", false)
end

-- BARD: confirm the bash performance survived the ripple (user, 2026-08-03: "after selecting
-- the boons, we should send the command PERFORMANCE to ensure we have our stuff up").
--
-- The boon screen is a natural gap -- the wave ends, you pick, you wade -- and a performance
-- can lapse across it with nothing on screen to say so. Everything else that knows about the
-- performance is REACTIVE: the fade line (trigger 002), the "not in fact performing" error
-- (005), the "already performing" refusal (006). All of them need something to go wrong first.
-- PERFORMANCE is the one cheap way to ASK, and the natural moment to ask is the same
-- per-ripple entry that re-wears armour.
--
-- Trigger 001 parses the answer ("Your grand performance shall last another N minutes.") and
-- clears the probe stamp. If nothing clears it inside the window the honest reading is "we are
-- not performing" -- whatever the game actually said -- so recompose. That covers the reply
-- wording we have never captured without guessing at it.
--
-- Sent DIRECTLY, like the armour: `queue addclearfull` would wipe it.
function M._bardPerformanceCheck()
  if (gmcp and gmcp.Char and gmcp.Char.Status and gmcp.Char.Status.class) ~= "Bard" then return end
  if not (ataxiaBasher and ataxiaBasher.enabled) then return end
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.bardPerfProbe = true
  -- `PERFORMANCE SHOW`, not bare `PERFORMANCE` (v4.7.209). The bare form is NOT a command --
  -- the game answers it with its syntax help: PERFORMANCE SHOW / END / SUSPEND / RESUME.
  --
  -- This was worse than a no-op. Trigger 001 never saw an answer, so the probe ALWAYS timed
  -- out and ALWAYS recomposed -- on every ripple entry, whether or not a performance was up.
  -- A check added to "ensure our stuff is up" was instead forcing a redundant recompose at
  -- every boon screen, and generating the "You are already performing" refusals that trigger
  -- 006 then had to absorb.
  --
  -- Galling because this is the SECOND time in one day, and I wrote the rule down after the
  -- first: v4.7.203 fixed exactly this in `M._relatchBoons` (bare `BOONS`, when the valid
  -- forms are BOON CLAIMED / OPTIONS / CLAIM / CONTEMPLATE), and the lesson recorded in
  -- AGENTS.md was "unexplained syntax help in a combat log is one of OUR commands being
  -- rejected -- for any command the package sends only once, check the verb form against its
  -- siblings". Then I shipped a bare-verb command in the very next feature.
  send("performance show", false)
  tempTimer(2, function()
    if not ataxiaTemp.bardPerfProbe then return end -- trigger 001 answered: performance is up
    ataxiaTemp.bardPerfProbe = nil
    if ataxiaBasher_bardCompose then ataxiaBasher_bardCompose() end
  end)
end

-- RE-LATCH THE BOON FLAGS (v4.7.188). Every boon flag (mnemRageFuelled, mnemThunderclap,
-- bardWarmarch, ...) is set by one of exactly two signals: the `BOON CLAIM` alias intercept
-- at the moment you take it, or that boon's row in the BOONS list. Neither fires for a boon
-- you ALREADY OWNED before its handling shipped, or when a claim happened outside the alias
-- -- so a boon could be active in the game and inert in the system, silently, with nothing
-- on screen to say so.
--
-- `BOONS` is authoritative for what we own, and every boon trigger latches off its rows, so
-- one send re-latches ALL of them at once. Fired once per run (not per ripple -- the flags
-- only reset at run start, so repeating it would be pure spam), from whichever explorer
-- entry point comes first.
--
-- Deliberately NOT latched from the boon's DESCRIPTION text, which would be the obvious
-- trick and is wrong here: descriptions also appear on the OFFER screen, listing boons we
-- were shown and did not take. That is the opposite of the affix parser, where the
-- ongoing-effects block only ever lists what is actually active.
-- The guard lives on ataxiaTemp, NOT on M (= ataxia.mnemosyne), and that is load-bearing.
-- `ataxia` is serialized wholesale (`table.save(file_loc, sanitizeForSave(ataxia))`,
-- 001_Save_Load_Settings:79) and deepMerge lets a non-table disk value overwrite
-- unconditionally (:239). The boon flags this exists to restore are bare globals that do NOT
-- persist -- so after a reload they come back nil while a guard stored on M would come back
-- TRUE from disk, the relatch would no-op, and the boons would stay inert. That is precisely
-- the bug this function exists to prevent, reappearing through the one path (reload
-- mid-run) where it matters most, and failing silently. Found by review, v4.7.192.
function M._relatchBoons()
  ataxiaTemp = ataxiaTemp or {}
  if ataxiaTemp.mnemBoonsRelatched then return end
  ataxiaTemp.mnemBoonsRelatched = true
  -- `BOON CLAIMED`, not `BOONS` (v4.7.203). `BOONS` is not a command -- the game answers it
  -- with its syntax help, which lists exactly four forms: BOON CLAIMED / OPTIONS /
  -- CLAIM <name> / CONTEMPLATE <name>. So this function has NEVER re-latched anything since
  -- it shipped in v4.7.188; it sent an invalid command once per run and printed a syntax
  -- block into the middle of combat. Caught from a live log, 2026-08-03.
  --
  -- Sobering, because the function was touched three times without anyone checking the
  -- command existed: shipped v4.7.188, "corrected" in v4.7.192 (its guard moved to
  -- ataxiaTemp -- a real bug, but in a no-op), and read by the Codex review. Every pass
  -- reasoned about WHEN to send and never about WHAT.
  --
  -- CLAIMED is the right form: it lists the boons we own as `<name>  <echoes>  <rarity>`,
  -- which is exactly the row `mnemosyne/013_Boons_List_Row` parses and the shape of every
  -- per-boon flag trigger (`^Songstep\s+\d+\s+\w+`). Every other boon command in the
  -- package already uses the `boon <verb>` form -- `boon claim`, `boon contemplate`.
  send("boon claimed", false)
end

-- Resume a paused sweep. Re-assert the explore-mode basher config (idempotent; guards a flag that
-- flickered during the pause -- notably inMnemosyne, missed between floors) and reset per-ripple
-- progress, mirroring the fresh-start path so the next ripple starts clean. _prevBasher is
-- deliberately NOT re-saved -- it still holds the original pre-sweep state for the eventual real stop.
function M._exploreResume(reason)
  ataxiaBasher = ataxiaBasher or {}
  ataxiaBasher.enabled = true
  ataxiaBasher.manual = true
  ataxiaBasher.areabash = false
  ataxiaBasher.autoLearn = true
  -- Through the shared setter, not a direct write: it owns the transition guard and raises
  -- "mnemosyne entered", which arms every tower-only mode. A direct write is silent, so a
  -- resume that is the FIRST thing to notice we are inside would arm none of them.
  if ataxiaBasher_mnemHere then ataxiaBasher_mnemHere("explore resume") else ataxiaBasher.inMnemosyne = true end
  M.explore.pausedAtBoon = false
  M.explore.moving = false
  M.explore.failed = {}
  M.explore._retriedFailed = nil -- fresh one-shot failed-exit retry for this ripple
  M.explore.hunting = false
  M.explore.patrolQueue = nil
  M.explore.patrolLoops = 0
  M.explore.iceSlips = 0
  M.explore.settling = true -- treat the current room like an arrival: let denizens settle first
  M._raidoRipple = nil      -- new ripple, new holding room: the Homebound raido re-arms
  -- Resume is the per-RIPPLE entry point (GO calls it after every boon screen), so this is
  -- also where armour gets re-checked before each dive -- not just on the first `explore on`.
  M._wearArmour()
  M._bardPerformanceCheck() -- per-ripple: a performance can lapse across the boon screen
  M._relatchBoons()   -- once per run: re-latch boon flags we may have owned before load
  if M.swarm and M.swarm.onRipple then pcall(M.swarm.onRipple) end -- fresh ripple: new pull budgets
  M._exploreEcho("<green>resuming<reset> the sweep" .. (reason and (" (" .. reason .. ")") or "") .. ".")
  M._scheduleTick()
  M._armWatchdog()
end

-- On GO (the new wave, after you pick a boon and wade), auto-resume a boon-screen pause: LOOK first
-- to establish the ripple's holding room (its only exit is `down` into the 4x4, and dementia can
-- otherwise leave a stale room around us), then resume the sweep. No-op unless paused at a boon.
function M.exploreOnGo()
  if not M.explore.pausedAtBoon then return end
  send("look")
  M._exploreResume("GO")
end

function M.exploreOn()
  if M.explore.on and M.explore.pausedAtBoon then
    return M._exploreResume() -- manual `mnem explore on` also un-pauses
  end
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
  if ataxiaBasher_mnemHere then ataxiaBasher_mnemHere("explore on") else ataxiaBasher.inMnemosyne = true end
  if M.explore._raisedBasher and raiseEvent then raiseEvent("basher enabled") end

  M.explore.on = true
  M.explore.moving = false
  M.explore.failed = {}
  M.explore._retriedFailed = nil
  M.explore.hunting = false
  M.explore.patrolQueue = nil
  M.explore.patrolLoops = 0
  M.explore.iceSlips = 0
  M.explore.settling = true -- treat the starting room like an arrival: let its denizens settle first
  M._wearArmour()           -- never start a sweep undressed
  M._bardPerformanceCheck() -- ...nor unperforming
  M._relatchBoons()   -- once per run: re-latch boon flags we may have owned before load
  if M.swarm and M.swarm.onRipple then pcall(M.swarm.onRipple) end -- fresh sweep: fresh tactics state
  M._exploreEcho("<green>ON<reset> -- sweeping the 4x4, clearing to the boon screen (patrols for the boss on boss ripples). (<a_darkmagenta>mnem explore off<reset> to stop)")
  M._scheduleTick()
  M._armWatchdog()
end

function M._exploreStop(reason)
  if not M.explore.on then return end
  if M.swarm and M.swarm.reset then pcall(M.swarm.reset, reason) end -- covers death + leave-tower
  M.explore.on = false
  M.explore.pausedAtBoon = false
  M.explore.moving = false
  M.explore.tacticalMove = false
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
  M.echo("<gold>[explore]<reset> " .. (M.explore.on and (M.explore.pausedAtBoon and "<cyan>paused (boon screen)" or "<green>ON") or "<grey>off")
    .. "<reset> inMnem=" .. tostring(inMnem())
    .. " denizens=" .. tostring(M._roomHasDenizens())
    .. " moving=" .. tostring(M.explore.moving) .. (M.explore.tacticalMove and " (tactical)" or "")
    .. " swarm=" .. tostring(M.swarm and M.swarm.state or "n/a")
    .. " next=" .. tostring(M._nextExploreStep()))
end

-- The ripple is complete when the boon-offer screen appears. PAUSE the sweep (stop navigating so
-- you can pick a boon + wade) but leave the basher exactly as the sweep set it -- enabled + manual
-- + autoLearn + no-flee. We no longer stop/restore/disable the basher here: it stays on through the
-- boon pick and into the next ripple, and `mnem explore on` un-pauses to sweep again. `on` stays
-- true so the normal lifecycle (leave-tower, death, `mnem explore off`) still restores the basher on
-- the real stop, and `_prevBasher` is preserved so that restore uses the original pre-sweep state.
-- Called from the boon-offer trigger regardless of telemetry state.
function M.onBoonScreen()
  if not M.explore.on or M.explore.pausedAtBoon then return end
  if M.swarm and M.swarm.reset then pcall(M.swarm.reset, "boon screen") end -- every ripple ends here
  M.explore.pausedAtBoon = true
  M.explore.moving = false
  M.explore.tacticalMove = false
  if M._explTickT then pcall(killTimer, M._explTickT); M._explTickT = nil end
  if M._explMoveT then pcall(killTimer, M._explMoveT); M._explMoveT = nil end
  if M._explWatchT then pcall(killTimer, M._explWatchT); M._explWatchT = nil end
  M._exploreEcho("<green>boon screen up<reset> -- ripple swept. Pick a boon and wade; basher stays on (<a_darkmagenta>mnem explore on<reset> to resume, <a_darkmagenta>off<reset> to stop).")
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
  -- ARRIVAL DETECTION UNDER DEMENTIA (v4.7.250). The normal test is "the room number changed",
  -- which is worthless when the number is re-invented on every look: it reads TRUE for a plain
  -- `ql` and FALSE never. Under dead reckoning the question is answered by what WE did instead
  -- -- a gmcp.Room while a move is in flight is the arrival, because every way a move can fail
  -- (Room.WrongDir, the wall line, the ice slip, the move timeout) clears `moving` first.
  -- The recording and the reckoning belong to 005's handler, which fires first. All this
  -- needs to know is that the normal arrival test cannot be trusted here: "the room number
  -- changed" is worthless when the number is re-invented on every look -- it reads TRUE for a
  -- plain `ql` and never FALSE. Under dead reckoning a gmcp.Room while a move is in flight IS
  -- the arrival, because every way a move can fail (Room.WrongDir, the wall line, the ice
  -- slip, the move timeout) clears `moving` first.
  local dr = MAP and MAP.drActive and MAP.drActive()
  local sameRoom = (not dr) and M.explore.moving and MAP and MAP.current ~= nil
    and MAP.current == M.explore.fromRoom
  if not sameRoom then -- a genuine arrival (or we weren't moving): end the move
    M.explore.moving = false
    M.explore.tacticalMove = false
    if M._explMoveT then pcall(killTimer, M._explMoveT); M._explMoveT = nil end
    -- Open the settle window: the new room's Char.Items (denizens) will land in a
    -- following "targets updated"; keep the full TICK_DELAY until they've settled.
    M.explore.settling = true
  end
  M._scheduleTick()
  M._armWatchdog()
end

if M._explRoomH then killAnonymousEventHandler(M._explRoomH) end
M._explRoomH = registerAnonymousEventHandler("gmcp.Room", function() M._onExploreRoom() end)

-- Denizen change (killed / left / arrived): re-decide. The "killed the last mob ->
-- move on" case wants FAST_TICK -- denizensHere is already current. BUT arriving in a
-- room ALSO raises "targets updated" (the new room's Char.Items load), and a mob can
-- load a beat AFTER the room does; while `settling` (set on arrival, cleared by the
-- first tick) we must keep the full TICK_DELAY so we don't decide the room is empty
-- and walk past a late-loading denizen. Each load during settling re-arms TICK_DELAY,
-- so the tick only fires after the contents have been quiet for the settle window.
if M._explTgtH then killAnonymousEventHandler(M._explTgtH) end
M._explTgtH = registerAnonymousEventHandler("targets updated", function()
  if not M.explore.on then return end
  M._scheduleTick(M.explore.settling and TICK_DELAY or FAST_TICK)
  M._armWatchdog()
end)

-- Server-authoritative wall: gmcp Room.WrongDir (body = the non-existent direction). Condemns
-- the exit instantly instead of waiting out MOVE_TIMEOUT and prunes it from the known graph.
if M._explWrongDirH then killAnonymousEventHandler(M._explWrongDirH) end
M._explWrongDirH = registerAnonymousEventHandler("gmcp.Room.WrongDir", function()
  M.onWrongDir(gmcp and gmcp.Room and gmcp.Room.WrongDir)
end)

-- Reload / auto-update: M (and M.explore) persist across an uninstall→install but
-- the timers don't, so a running sweep would be left half-alive with the basher
-- force-mutated. Start clean: mark it off (the user re-issues `mnem explore on`).
if M._explLoadH then killAnonymousEventHandler(M._explLoadH) end
M._explLoadH = registerAnonymousEventHandler("sysLoadEvent", function()
  M.explore.on = false
  M.explore.pausedAtBoon = false
  M.explore.moving = false
  M.explore.tacticalMove = false
  M.explore._prevBasher = nil
end)
