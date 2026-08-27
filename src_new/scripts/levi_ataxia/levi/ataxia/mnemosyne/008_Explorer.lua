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
-- Fields rather than locals so tests can tune them (v4.7.262).
M.LAVA_EPISODE_GAP = 6   -- seconds of silence that end one lava episode (matches M.roomLava)
M.LAVA_STRAY_TICKS = 1   -- mismatched struggle ticks discarded before we believe them

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

-- WHY NAVIGATION IS SUSPENDED, or nil when it may proceed (v4.7.263). Reason-string form, like
-- M._stepRefusal and M._chaseRefusal -- a refusal that cannot name itself cannot be diagnosed
-- from a transcript, which is what cost three versions of guesswork on the lava edge.
--
-- The axis is NOT paused/not-paused. It is:
--   INITIATION      -- choosing to move for positional reasons (sweep, patrol, pull, re-entry,
--                      boss chase, map upkeep, wall melt)  ->  SUSPEND
--   COMPLETION      -- a move already in flight landing, failing, slipping, retrying
--                      ->  NEVER suspend; suspending it strands `moving`, swarmHold, S.state
--   SELF-PRESERVATION -- lava, the escape ladder, the panic tumble, the recovery loop, the
--                      tincture, a forced disengage  ->  NEVER suspend
--
-- SUSPENSION, NOT LIVENESS. This answers "is the sweep paused?", not "is the sweep running?".
-- Callers keep their own `explore.on` check: the boss chase deliberately works while the
-- explorer is OFF (manual bashing in the tower is a legitimate chase context), and folding
-- liveness in here would silently kill it.
--
-- Deliberately NOT folded in, each because it already has an owner and a DIFFERENT action:
--   inMnem()       -- leaving the tower must STOP, not suspend; _exploreTick owns it, above.
--   M.roomLava()   -- lava outranks every pause; _chaseRefusal already names it separately.
--   explore.moving -- "a move is in flight" wants WAIT, not refuse.
-- A guard that answers every question is a guard that refuses everything.
function M._navRefusal()
  local e = M.explore
  if e and e.pausedAtBoon then return "paused at the boon screen" end
  return nil
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
-- WHY an exit cannot be swept, or nil when it can (v4.7.259).
--
-- The sweep used to refuse silently: four separate conditions collapsed into one boolean, and
-- when the answer came out "nothing to explore" the log said only "grid swept -- nowhere left
-- to patrol". A user hit exactly that in a room whose sole exit was an unwalked northeast, on
-- every ripple, and there was no way to tell WHICH gate had refused without reading the source
-- and guessing. Naming the reason is the same fix the boss chase got in v4.7.255.
--
-- Single source of truth on purpose: `usableUnexplored` and the `mnem explore why` diagnostic
-- both call this, so the explanation can never drift from the behaviour it explains.
function M._stepRefusal(num, d)
  local failed = (M.explore.failed and M.explore.failed[num]) or {}
  if failed[d] then return "condemned -- a previous move that way failed" end
  -- NAME THE SOURCE (v4.7.262). edgeIsLava is the OR of two independent facts with completely
  -- different repair paths -- a remembered inbound EDGE versus a DESTINATION room we burned in
  -- -- and collapsing them into one literal is why the live refusal could not be attributed from
  -- the transcript at all. Nothing branches on this string (callers use truthiness or print it),
  -- so splitting it costs nothing.
  local byEdge = (M.explore.lavaEdges[num] or {})[d]
  if byEdge then
    return "leads into lava (edge remembered"
      .. (type(byEdge) == "table" and (", ripple " .. tostring(byEdge.ripple or "?")) or "") .. ")"
  end
  if M.edgeIsLava and M.edgeIsLava(num, d) then
    return "leads into lava (destination " .. tostring(M._exitTarget and M._exitTarget(num, d))
      .. " is a known lava room)"
  end
  local planar = MAP.OFFSETS and MAP.OFFSETS[d]
  if not planar then
    -- up/in/out are never swept; `down` only from the holding room (no planar exit at all),
    -- which is the ripple entry.
    if d ~= "down" then return "non-planar (never swept)" end
    if roomHasPlanarExit(num) then return "down, but this room has planar exits" end
    return nil
  end
  if MAP.exitFitsGrid and not MAP.exitFitsGrid(num, d) then return "would leave the 4x4 grid" end
  return nil
end

local function usableUnexplored(num)
  local out = {}
  for _, d in ipairs(MAP.unexploredExits(num) or {}) do
    if not M._stepRefusal(num, d) then out[#out + 1] = d end
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
      -- REFUSE A PATH THAT STARTS BY WALKING INTO LAVA (v4.7.256). This is the one that killed
      -- us: once the lava room had been walked, its exits were no longer "unexplored", so the
      -- filter above never saw them -- but the room BEYOND it still had an unexplored exit, and
      -- the shortest path to that ran straight through the lava. The sweep took it three times
      -- at 6,874 a go. Checking only the FIRST step is sufficient and cheap: every step is
      -- re-decided on arrival, so a route we never enter is a route we never traverse.
      local firstOk = steps and steps[1] and not (M.edgeIsLava and M.edgeIsLava(cur, steps[1]))
      if steps and #steps > 0 and firstOk and planarStep(steps[1])
         and (not best or #steps < #best) then best = steps end
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
-- A BOSS THAT RUNS AWAY (v4.7.255)
-- ---------------------------------------------------------------------------
-- User, 2026-08-11: "When fighting this boss, we need to follow him out and continue
-- attacking."
--
--   Lyaeus, the travelling bard flails in panic.
--   His fingers plucking a plaintive melody on his lyre, a satyri bard strolls out to the
--   southeast, the sorrowful music gradually fading in his wake.
--
-- Two lines, and they name him DIFFERENTLY: the panic line uses the boss's proper name and the
-- departure line uses the generic denizen description. Neither alone is enough -- the panic
-- line says WHO but not where, the departure line says WHERE but, under its generic name,
-- could be any wandering denizen. So the panic latches the identity and the next departure
-- within PANIC_WINDOW supplies the direction.
--
-- Boss ripples end when the boss dies, so a boss that walks out is not a fight we can decline:
-- leaving him alone means the ripple never closes. That is the opposite of every other "should
-- we move?" decision in this module, which is why it gets its own path rather than a flag on
-- the sweep.
local PANIC_WINDOW = 6   -- seconds a panic stays fresh enough to explain a departure
local MAX_CHASES = 4     -- per ripple; a boss kiting us across the grid is its own hazard

-- Do the panicking name and the ripple's Objective boss refer to the same creature? Loose on
-- purpose: the Objective line and the room line rarely word a denizen identically. When we do
-- not know the boss at all we allow it -- something we were fighting just panicked, and that
-- is the case the user is describing.
function M._isBossName(name)
  local boss = M.run and M.run.boss
  if type(boss) ~= "string" or boss == "" then return true end
  if type(name) ~= "string" or name == "" then return false end
  local a, b = name:lower(), boss:lower()
  return a:find(b, 1, true) ~= nil or b:find(a, 1, true) ~= nil
end

function M.onDenizenPanic(name)
  if not inMnem() then return end
  if not M._isBossName(name) then return end
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.bossPanicAt = (getEpoch and getEpoch()) or 0
  ataxiaTemp.bossPanicName = name
end

-- Should we follow something that just left in `dir`? Split out from the send so the decision
-- is unit-testable, and so every refusal has a nameable reason rather than a silent `return`.
function M._chaseRefusal(dir)
  if not inMnem() then return "not in the tower" end
  if not (ataxiaBasher and ataxiaBasher.enabled) then return "basher off" end
  if not (MAP.normDir and MAP.normDir(dir)) then return "no direction" end
  local at = ataxiaTemp and tonumber(ataxiaTemp.bossPanicAt)
  local nowT = (getEpoch and getEpoch()) or 0
  if not at or (nowT - at) > PANIC_WINDOW then return "nothing panicked recently" end
  -- NEVER chase while leaving. Escape mode, a swarm recovery and lava all mean the room we are
  -- standing in is already losing us the fight; adding a pursuit to that is how a retreat turns
  -- into a death. The boss keeps until we are fit.
  --
  -- NAVIGATION is the first of that group as of v4.7.263. The boon screen IS the ripple ending,
  -- so a boss cannot still be alive and fleeing -- and a chase spends the per-ripple budget,
  -- arms a 5s move lock that then collides with the GO resume, and walks us off the holding
  -- square while the user is reading a menu. Deliberately placed AFTER the panic-freshness check
  -- above so an ordinary wandering denizen still refuses silently.
  local nav = M._navRefusal()
  if nav then return nav end
  if ataxiaTemp.escapeMode then return "escaping" end
  if M.roomLava and M.roomLava() then return "lava" end
  if M.swarm and M.swarm.state == "recovering" then return "recovering" end
  -- Defaulted, not conditional: a guard that evaporates because the config is missing a key
  -- fails in the wrong direction -- it would chase a boss at crash HP on a fresh profile.
  -- 35 is the same escapeAt default the swarm ladder documents.
  local s = M._cfg and M._cfg()
  local esc = (s and s.swarm and tonumber(s.swarm.escapeAt)) or 35
  local hp = tonumber(ataxia and ataxia.vitals and ataxia.vitals.hpp)
  if hp and hp <= esc then return "too hurt to chase" end
  if (tonumber(ataxiaTemp.bossChases) or 0) >= MAX_CHASES then return "chase budget spent" end
  return nil
end

-- Does the departure line itself name the creature that panicked? POSITIVE EVIDENCE ONLY, and the
-- asymmetry is the point: Celepharn's departure carries his proper name
-- ("...accompanies Celepharn as he departs east."), while Lyaeus's carries only a generic
-- description ("a satyri bard strolls out to the southeast"). So a match confirms; a non-match
-- proves NOTHING and must never veto, or the boss this whole path was written for stops being
-- followed. Compared on the FIRST WORD of the panicked name, since the panic line carries a
-- comma-title ("Celepharn, High Priest of Life") the room line does not repeat.
function M._fledLineNames(lineText)
  local name = ataxiaTemp and ataxiaTemp.bossPanicName
  if type(lineText) ~= "string" or type(name) ~= "string" then return false end
  local first = name:match("^([%a']+)")
  if not first or #first < 3 then return false end
  return lineText:lower():find(first:lower(), 1, true) ~= nil
end

function M.onDenizenFled(dir, lineText)
  local named = M._fledLineNames(lineText)
  local why = M._chaseRefusal(dir)
  if why then
    -- Only worth saying when we knew who ran: otherwise this fires on every wandering denizen.
    if ataxiaTemp and ataxiaTemp.bossPanicAt and why ~= "nothing panicked recently" then
      M._exploreEcho("<grey>" .. tostring(ataxiaTemp.bossPanicName or "the boss")
        .. " fled " .. tostring(dir) .. " -- not following (" .. why .. ").")
    end
    return
  end
  ataxiaTemp.bossChases = (tonumber(ataxiaTemp.bossChases) or 0) + 1
  ataxiaTemp.bossPanicAt = nil -- consumed: one departure per panic
  local short = MAP.shortDir(MAP.normDir(dir))
  local sep = (ataxia.settings and ataxia.settings.separator) or ";"
  send("queue addclear free stand" .. sep .. short)
  M._tacticalArm(short) -- a lost chase times out without condemning a real exit
  M._exploreEcho("<gold>" .. tostring(ataxiaTemp.bossPanicName or "the boss")
    .. " fled<reset> -- following <cyan>" .. short .. "<reset> ("
    .. ataxiaTemp.bossChases .. "/" .. MAX_CHASES .. ")"
    -- Which evidence identified the runner. Worth printing because the two are not equally
    -- strong: a named departure is proof, a panic window is an inference, and when a chase goes
    -- to the wrong room that distinction is the first thing worth knowing.
    .. (named and "." or " <grey>[by panic window]<reset>."))
end

-- ---------------------------------------------------------------------------
-- LAVA -- THE ONE ROOM WE LEAVE BY ANY DOOR (v4.7.254)
-- ---------------------------------------------------------------------------
-- User, 2026-08-11: "We need to move rooms if the room is lava."
--
--   In the depths of a murky lake.
--   Molten lava bubbles and churns. ...
--   You see exits leading east and northwest.
--   You splash into boiling lava!
--   Health lost: 5890 (unblockable).
--   ... You continue to struggle in the boiling grasp of the lava as it eats away at your body.
--   Health lost: 5890 (unblockable).
--
-- FIVE THOUSAND EIGHT HUNDRED AND NINETY, UNBLOCKABLE, PER TICK, against the 10,939 HP in that
-- prompt. That is 54% of the pool a tick: two of them is a death, and "unblockable" means no
-- shield, no barrier and no resistance changes it. Every other hazard in this module can be
-- fought through or healed against -- Ablaze is ~1,200 and only gates the hover. This one
-- cannot be traded with at all, so it gets the only unconditional "leave now" in the sweep.
--
-- THIS IS THE EXCEPTION TO THE VALIDATED-ROUTE RULE. The escape ladder deliberately refuses to
-- leave by an unvalidated exit (user decision, v4.7.243) because a wrong door there costs a
-- move and some HP. Here staying costs half the health pool per tick, so ANY door beats the
-- floor -- including one we have never walked.
M.explore.lavaRooms = M.explore.lavaRooms or {}
-- LAVA IS ALSO REMEMBERED AS AN EDGE (v4.7.256), and that is the half that actually saves us.
--
-- Marking the ROOM only helps if we can tell that an exit leads to it, and `_exitTarget` returns
-- nil whenever gmcp has not filled a destination id -- which is exactly the case for a
-- neighbour we have not visited. So "room 512 is lava" is unusable from the room next door.
--
-- At the instant we splash we know something better: which room we came FROM and which way we
-- walked. "From room P, going north, is lava" needs no destination id from anyone, and it is
-- the form both the sweep and the escape ladder can act on.
M.explore.lavaEdges = M.explore.lavaEdges or {}

-- EVERYTHING KEYED BY ROOM NUMBER DIES WITH THE RIPPLE (v4.7.260).
--
-- The tower draws each ripple's 4x4 from a POOL OF REAL ROOMS, and the same gmcp id comes back
-- on a later level with a different layout and different affixes. So a room number is only a
-- name for "this cell, this ripple" -- and every table below is keyed by one.
--
-- The bill: a user opened ripple 2 in a cavern whose sole exit was north, and `mnem explore why`
-- answered `north -> 65420 REFUSED: leads into lava`. We had never glanced north, let alone
-- stepped in it. The lava was remembered from an EARLIER ripple that happened to reuse the id,
-- and the only thing that had ever cleared it was a package reload. The sweep then reported
-- "grid swept -- nowhere left to patrol" and switched off with one room mapped.
--
-- `MAP.reset()` already draws exactly this line -- it is called on ripple change and on a fresh
-- tower entry, and it throws the whole room graph away. This hangs off it so there is ONE
-- definition of "the old level's room numbers mean nothing now", rather than two that drift.
--
-- `failed` is the same hazard and was carrying the same way: an exit condemned on the old level
-- (a wall, or an invented dementia exit) stayed condemned on a level where it is a real door.
function M.onRippleReset()
  M.explore.lavaRooms = {}
  M.explore.lavaEdges = {}
  M.explore.failed = {}
  M.explore.fromRoom = nil
  M.explore.fromDir = nil
  M.explore._noExitLooks = nil
  M.explore._noExitHolds = nil
  M.explore._retriedFailed = nil
  ataxiaTemp = ataxiaTemp or {}
  -- MAX_CHASES is documented "per ripple" and was only ever reset on reload.
  ataxiaTemp.bossChases, ataxiaTemp.bossPanicAt = nil, nil
  -- The lava EPISODE is stateful as of v4.7.262 (anchor room, stray-tick count, chosen door).
  -- All three are about a specific room on a specific level, so they die with the ripple too.
  ataxiaTemp.mnemLavaAt, ataxiaTemp.mnemLavaRoom = nil, nil
  ataxiaTemp.mnemLavaStray, ataxiaTemp.mnemLavaDir = nil, nil
end

-- A MARK MUST CARRY ITS REASON (v4.7.262). Both lava tables stored a bare `true`, so when a
-- refusal turned out to be wrong there was nothing anywhere -- screen, memory or disk -- saying
-- WHEN it was recorded, on which ripple, or which room we were burning in at the time. The live
-- 67777 incident could only be attributed by reconstructing the module offline. The value is now
-- a record; every other predicate here was already a truthiness test, so this `== true` was the
-- only thing that had to change.
function M.roomIsLava(key)
  return key ~= nil and M.explore.lavaRooms[key] ~= nil
end

-- Would stepping `dir` out of `num` put us in lava? True on either the remembered edge or a
-- known destination room.
function M.edgeIsLava(num, dir)
  local nd = MAP.normDir and MAP.normDir(dir)
  if not (num ~= nil and nd) then return false end
  local byEdge = M.explore.lavaEdges[num]
  if byEdge and byEdge[nd] then return true end
  local tgt = M._exitTarget and M._exitTarget(num, nd)
  return M.roomIsLava(tgt)
end

-- Where an exit leads, as a room key, or nil when we cannot tell. Works in both worlds: with
-- honest ids the exit table carries the destination; under dementia the destination is an
-- invention but the dead-reckoned cell is computable from our own position.
function M._exitTarget(num, dir)
  local r = MAP.rooms and MAP.rooms[num]
  if not r then return nil end
  if MAP.drActive and MAP.drActive() then
    local off = MAP.OFFSETS and MAP.OFFSETS[dir]
    if not (off and r.x and r.y) then return nil end
    return MAP.drKey(r.x + off[1], r.y + off[2])
  end
  local dest = r.exits and r.exits[dir]
  if type(dest) == "number" and dest > 0 then return dest end
  return nil
end

-- The door to take out of lava. Ordered by what we KNOW rather than by what the sweep wants:
--   1. back the way we came -- we were just standing there, so it is provably not lava;
--   2. any planar exit whose destination is not a room we have already burned in;
--   3. any planar exit at all.
-- Non-planar is excluded for the usual reason (`up` climbs out of the grid), except that
-- `down` stays eligible if it is genuinely all there is -- drowning beats boiling.
-- HOW WE GOT INTO THE ROOM WE ARE STANDING IN -- returns fromKey, longDir, or nil plus the
-- REASON we cannot say (v4.7.262). A falsy guard carrying no reason is why the 67777 refusal
-- went unexplained for a whole session.
--
-- The preference order IS the fix. `MAP._lastArrival` is written by the single owner of arrivals
-- and is true for tumbles and drags as well as sweep steps. The explorer's armed pair is only a
-- fallback, and only where the MAP can prove it adjacent -- `from ~= cur`, the old guard, proves
-- nothing whatsoever, since every other room on the grid satisfies it.
function M._inbound()
  local cur = MAP and MAP.current
  if cur == nil then return nil, nil, "no current room" end
  local a = MAP._lastArrival
  if a and a.to == cur and a.from ~= nil and a.from ~= cur then
    local nd = MAP.normDir and MAP.normDir(a.dir)
    if nd then return a.from, nd, nil end
  end
  local from = M.explore.fromRoom
  local fdir = MAP.normDir and MAP.normDir(M.explore.fromDir)
  if from == nil or not fdir then return nil, nil, "no inbound movement recorded" end
  if from == cur then return nil, nil, "the armed move never left the room" end
  local r = MAP.rooms and MAP.rooms[from]
  if not r then return nil, nil, "armed anchor " .. tostring(from) .. " is not a known room" end
  if (r.edges and r.edges[fdir] == cur) or (r.exits and r.exits[fdir] == cur) then
    return from, fdir, nil
  end
  return nil, nil, "armed anchor " .. tostring(from) .. " " .. fdir .. " does not lead to "
    .. tostring(cur) .. " -- something moved us without arming"
end

-- Just the DIRECTION we came in by, for the escape chooser. Deliberately NOT gated on knowing
-- the room: "back the way we came is provably not lava" needs the direction, not the id.
function M._inboundDir()
  local _, d = M._inbound()
  if d then return d end
  local from, cur = M.explore.fromRoom, MAP and MAP.current
  if from ~= nil and cur ~= nil and from == cur then return nil end -- our own escape arm
  return MAP.normDir and MAP.normDir(M.explore.fromDir)
end

function M._lavaExit()
  local cur = MAP and MAP.current
  local r = cur and MAP.rooms and MAP.rooms[cur]
  if not r then return nil end

  -- THE INBOUND DIRECTION, NOT THE LAST ARMED ONE (v4.7.262). onLava calls `_tacticalArm(dir)`
  -- with the ESCAPE direction, and the struggle line re-fires every tick -- so from tick 2 this
  -- read `fromDir` = the escape direction and took its OPPOSITE, turning us straight back INTO
  -- the room we were fleeing toward and abandoning the one door the comment below calls provably
  -- safe. Each send is `queue addclear`, which REPLACES the queued line, so the LAST tick before
  -- balance is the one that executed; and only tick 1 prints the banner, which is why the flip
  -- never appeared in any log. `_inboundDir` rejects an anchor equal to the current room --
  -- exactly what `_tacticalArm` writes -- so the read is now stable across ticks.
  local back = M._inboundDir()
  back = back and MAP.OPPOSITE and MAP.OPPOSITE[back]
  if back and r.exits[back] ~= nil and MAP.OFFSETS[back] then
    return MAP.shortDir(back)
  end

  -- SORTED, not pairs order. An unordered scan means the same room can pick a different door
  -- on different runs, which makes the behaviour unreproducible in exactly the situation where
  -- we most want to be able to read the log afterwards -- and it made the back-direction
  -- preference above untestable, because whether it mattered was a coin flip.
  local dirs = {}
  for d in pairs(r.exits) do dirs[#dirs + 1] = d end
  table.sort(dirs)

  local fallback
  for _, d in ipairs(dirs) do
    if MAP.OFFSETS[d] then
      local tgt = M._exitTarget(cur, d)
      if not (tgt and M.explore.lavaRooms[tgt]) then return MAP.shortDir(d) end
      fallback = fallback or MAP.shortDir(d)
    elseif d == "down" then
      fallback = fallback or MAP.shortDir(d)
    end
  end
  return fallback
end

-- Fired by the lava lines (triggers mnemosyne/064). Idempotent per tick: the struggle line
-- repeats every tick and each one re-sends, because a move that was eaten must be retried --
-- there is no budget worth preserving when the alternative is dying in place.
function M.onLava(lineText)
  if not inMnem() then return end
  ataxiaTemp = ataxiaTemp or {}
  local nowT = (getEpoch and getEpoch()) or 0
  local cur = MAP and MAP.current
  local entry = type(lineText) == "string"
    and lineText:find("splash into boiling lava", 1, true) ~= nil
  local at = tonumber(ataxiaTemp.mnemLavaAt)
  local live = at ~= nil and (nowT - at) <= M.LAVA_EPISODE_GAP
  local anchor = ataxiaTemp.mnemLavaRoom

  -- A STRUGGLE TICK NAMING A ROOM WE HAVE LEFT IS A LINE ABOUT THE PAST (v4.7.262). The two
  -- patterns mean different things: the splash is the ENTRY and always speaks for the room we
  -- are in now, while the struggle is the TICK -- and a buffered tick can be processed AFTER the
  -- escape's gmcp.Room has already moved MAP.current. Acting on it marks a perfectly good room
  -- as lava, condemns the escape edge (the one door we had just proven safe by walking it), and
  -- queues yet another move out of the room we legitimately reached.
  --
  -- Bounded, and deliberately so. ONE stray line is the race. A SECOND identical tick means we
  -- really are burning in a new room and the entry line was missed, so we adopt it. That caps
  -- the cost of being wrong at ONE tick of damage; refusing forever would cost a death, and this
  -- hazard kills in two. Never raise LAVA_STRAY_TICKS above 1 -- two discarded ticks is 11,780
  -- unblockable, which is a death at the observed pool -- and never apply this to the entry line.
  if (not entry) and live and anchor ~= nil and cur ~= nil and cur ~= anchor then
    local stray = (tonumber(ataxiaTemp.mnemLavaStray) or 0) + 1
    ataxiaTemp.mnemLavaStray = stray
    if stray <= M.LAVA_STRAY_TICKS then
      return M._exploreEcho("<indian_red>lava tick ignored<reset> -- it names "
        .. tostring(anchor) .. " and we are already in " .. tostring(cur)
        .. " (stray " .. stray .. "/" .. M.LAVA_STRAY_TICKS .. ").")
    end
    M._exploreEcho("<indian_red>second lava tick in " .. tostring(cur)
      .. "<reset> -- treating this room as lava too (entry line missed).")
  end
  ataxiaTemp.mnemLavaStray = nil

  -- THE BANNER RE-ARMS PER EPISODE. `first` was `not ataxiaTemp.mnemLavaAt`, and nothing ever
  -- nils that stamp except the lazy expiry inside M.roomLava, which nothing calls -- so every
  -- lava episode after the first in a session was completely SILENT. That is a large part of
  -- why phantom marking accumulated with no user-visible record of it happening.
  local first = (at == nil) or (nowT - at) > M.LAVA_EPISODE_GAP
  ataxiaTemp.mnemLavaAt = nowT
  ataxiaTemp.mnemLavaRoom = cur
  if cur then
    M.explore.lavaRooms[cur] = { at = nowT, cur = cur,
      ripple = tonumber(M.run and M.run.ripple) or 0,
      why = entry and "splashed in" or "struggle tick" }
  end

  -- Record the way IN, so the room next door can refuse the step even though it has no
  -- destination id for this room. The witness is the MAP's resolved arrival, NOT the pair the
  -- explorer armed -- see M._inbound. A refusal is ECHOED: an edge we declined to condemn is
  -- exactly the fact that was missing when a phantom refusal had to be diagnosed offline.
  local from, fdir, whyNot = M._inbound()
  if from and fdir then
    M.explore.lavaEdges[from] = M.explore.lavaEdges[from] or {}
    M.explore.lavaEdges[from][fdir] = { at = nowT, cur = cur,
      ripple = tonumber(M.run and M.run.ripple) or 0, why = "walked in" }
  elseif whyNot then
    M._exploreEcho("<indian_red>lava edge NOT recorded<reset> -- " .. whyNot .. ".")
  end

  -- Hold the attack dispatcher: every attack sends `queue addclearfull`, which would wipe the
  -- move we are about to queue. Same rule as every other queued non-attack action.
  if M.swarm and M.swarm.escapeOn then pcall(M.swarm.escapeOn, "LAVA") end

  -- Abandon any tactic in flight. A funnel or a pull is a plan for a room we can survive.
  if M.swarm and M.swarm.state and M.swarm.state ~= "idle" and M.swarm.reset then
    pcall(M.swarm.reset, "lava")
  end

  -- ONE DOOR PER EPISODE (v4.7.262). `_lavaExit` re-derives the exit on every struggle tick, and
  -- the ticks are not independent: `_tacticalArm` below overwrites explore.fromDir with the
  -- ESCAPE direction, so from tick 2 the "back the way we came" preference cannot resolve and
  -- the sorted planar scan answers instead -- a DIFFERENT door, chosen alphabetically. Since
  -- each send is `queue addclear` (it REPLACES the queued line), whichever tick lands last before
  -- balance is the one that executes, so alternating doors is not a cosmetic inconsistency: it is
  -- a coin flip over which way we actually leave, re-flipped every tick.
  --
  -- Remembering beats re-deriving. Re-validated against the room's exits each time so a stale
  -- direction can never strand us, and released when the episode ends.
  local dir
  local remembered = (not first) and ataxiaTemp.mnemLavaDir or nil
  if remembered then
    local r = cur and MAP.rooms and MAP.rooms[cur]
    local nd = MAP.normDir and MAP.normDir(remembered)
    if r and r.exits and nd and r.exits[nd] ~= nil then dir = remembered end
  end
  dir = dir or M._lavaExit()
  ataxiaTemp.mnemLavaDir = dir
  if not dir then
    -- No exit we know of. Ask -- the exits line is parsed (005) and QL is free -- and say so,
    -- because this is the one situation where the sweep genuinely cannot save us.
    if (nowT - (tonumber(ataxiaTemp.mnemLavaQlAt) or 0)) >= 2 then
      ataxiaTemp.mnemLavaQlAt = nowT
      send("ql", false)
    end
    M._exploreEcho("<indian_red>LAVA and no exit known<reset> -- looking. <a_darkmagenta>MOVE MANUALLY.")
    return
  end

  local sep = (ataxia.settings and ataxia.settings.separator) or ";"
  send("queue addclear free stand" .. sep .. dir)
  M._tacticalArm(dir) -- so a lost move times out without condemning a real exit
  if first then
    M._exploreEcho("<indian_red>BOILING LAVA<reset> (5890/tick, unblockable) -- leaving by <cyan>"
      .. dir .. "<reset> immediately.")
  end
end

-- True while lava is still eating us. Lazy expiry like roomAblaze: leaving the room stops the
-- struggle line, and no "you climb out" line has ever been captured.
function M.roomLava()
  local at = ataxiaTemp and tonumber(ataxiaTemp.mnemLavaAt)
  if not at then return false end
  local nowT = (getEpoch and getEpoch()) or 0
  if (nowT - at) > 6 then ataxiaTemp.mnemLavaAt = nil; return false end
  return true
end

-- `mnem explore why` -- answer "why is the sweep not moving?" from the GAME's state rather
-- than from reading the source (v4.7.259).
--
-- Everything printed here is something a wrong answer would have made obvious at a glance:
-- whether we are even in the tower, whether the room is recorded at all, what exits gmcp gave
-- us versus which we have walked, the grid bounding box (a box already wider than GRID means
-- the coordinates are wrong and every geometric refusal below is suspect), and the reason each
-- individual exit was refused.
function M.exploreWhy()
  local cur = MAP and MAP.current
  M._exploreEcho("<white>why<reset> -- sweep diagnostics")
  cecho("\n  <NavajoWhite>in tower:   " .. (inMnem() and "<green>yes" or "<red>no")
    .. "   <NavajoWhite>explore: " .. (M.explore.on and "<green>on" or "<red>off")
    .. "   <NavajoWhite>moving: " .. (M.explore.moving and "<yellow>yes" or "<DimGrey>no"))
  cecho("\n  <NavajoWhite>dead reckoning: "
    .. ((MAP.drActive and MAP.drActive()) and "<yellow>ON (dementia)" or "<DimGrey>off"))
  if not cur then
    cecho("\n  <red>no current room<reset> -- nothing to decide from.\n")
    return
  end
  local r = MAP.rooms and MAP.rooms[cur]
  cecho("\n  <NavajoWhite>room:       <white>" .. tostring(cur)
    .. (r and (" <DimGrey>(" .. tostring(r.name or "?") .. ")") or " <red>NOT RECORDED"))
  if not r then cecho("\n"); return end

  local minx, maxx, miny, maxy = MAP.bounds()
  local n = 0
  for _ in pairs(MAP.rooms) do n = n + 1 end
  if minx then
    local w, h = maxx - minx + 1, maxy - miny + 1
    local g = tonumber(MAP.GRID) or 4
    cecho("\n  <NavajoWhite>grid:       <white>" .. w .. "x" .. h .. "<reset> over " .. n .. " rooms"
      .. ((w > g or h > g) and " <red>(LARGER THAN " .. g .. "x" .. g
          .. " -- coordinates are wrong, geometry refusals below are suspect)" or ""))
  else
    cecho("\n  <NavajoWhite>grid:       <DimGrey>nothing placed<reset> (" .. n .. " rooms)")
  end

  local any = false
  for d, dest in pairs(r.exits or {}) do
    any = true
    local walked = r.edges and r.edges[d]
    local why = M._stepRefusal(cur, d)
    cecho("\n    <white>" .. d .. "<reset> -> " .. tostring(dest)
      .. (walked and " <DimGrey>[walked]" or "")
      .. (walked and "" or (why and (" <red>REFUSED: " .. why) or " <green>USABLE")))
  end
  if not any then
    -- The case worth shouting about: the game printed exits in prose and gmcp gave us none.
    cecho("\n    <red>gmcp reported NO EXITS for this room<reset> -- if the room description"
      .. " listed some, that is the fault.")
  end

  -- THE LEDGER (v4.7.262). Every consumer of these tables printed only their EFFECT ("REFUSED:
  -- leads into lava"), so when the effect was wrong there was nothing left to inspect -- the
  -- live 67777 refusal had to be attributed by reconstructing the module offline. Print the
  -- facts themselves, with provenance, and print the two candidate answers to "how did we get
  -- here" side by side: the map's witnessed arrival, and the pair the explorer merely ARMED.
  -- Seeing those disagree is the whole diagnosis at a glance.
  local ibFrom, ibDir, ibWhy = M._inbound()
  cecho("\n  <NavajoWhite>inbound:    " .. (ibFrom and ("<white>" .. tostring(ibFrom) .. " " .. ibDir)
    or ("<red>unknown<reset> <DimGrey>(" .. tostring(ibWhy) .. ")")))
  cecho("\n  <NavajoWhite>armed pair: <DimGrey>" .. tostring(M.explore.fromRoom) .. " "
    .. tostring(M.explore.fromDir))
  local marks = 0
  for key, rec in pairs(M.explore.lavaRooms or {}) do
    marks = marks + 1
    cecho("\n    <indian_red>lava room " .. tostring(key) .. "<reset> <DimGrey>"
      .. (type(rec) == "table"
          and ("ripple " .. tostring(rec.ripple) .. ", " .. tostring(rec.why))
          or "legacy mark, no provenance"))
  end
  for anchor, tbl in pairs(M.explore.lavaEdges or {}) do
    for d, rec in pairs(tbl) do
      marks = marks + 1
      cecho("\n    <indian_red>lava edge " .. tostring(anchor) .. " " .. d .. "<reset> <DimGrey>"
        .. (type(rec) == "table"
            and ("-> " .. tostring(rec.cur) .. ", ripple " .. tostring(rec.ripple))
            or "legacy mark, no provenance"))
    end
  end
  if marks == 0 then cecho("\n    <DimGrey>no lava recorded this ripple") end
  cecho("\n")
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
  -- Arm the dead reckoning for exactly this one step (v4.7.251). Under dementia several room
  -- events arrive inside one move's window; without arming, each advanced the position again.
  if MAP.drArm and MAP.drActive and MAP.drActive() then MAP.drArm(dir) end
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
  -- NAVIGATION: its whole purpose is to unstick the SWEEP with a ql. Nothing self-preserving
  -- reaches it. (Behaviour unchanged -- this moves ownership to M._navRefusal, v4.7.263.)
  if not M.explore.on or M._navRefusal() then return end
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
    if not M.explore.on or M._navRefusal() then return end
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
  -- NAVIGATION SUSPENDED -- and this gate sits BELOW the swarm delegation deliberately (v4.7.263).
  --
  -- It used to be the third line of this function, above the delegation, and that was the bug:
  -- every swarm state machine self-ticks through M._scheduleTick, so pausing the sweep also
  -- froze the recovery loop, the funnel and the re-entry. At the boon screen the escape ladder
  -- would fire ONCE (S.onVitals is independent) and then disable itself -- S.onVitals returns
  -- early while state == "recovering", and only the tick can leave that state. Nothing landed,
  -- nothing re-sent an eaten `fly`, nothing enforced RECOVER_MAX, until GO unwedged it. Which
  -- needs the user at the keyboard, i.e. exactly the case a pause is supposed to survive.
  --
  -- Below the delegation: the swarm finishes what is in flight, the sweep starts nothing new.
  if M._navRefusal() then return end
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
    -- NO DATA IS NOT THE SAME ANSWER AS NO EXITS (v4.7.260).
    --
    -- "Nowhere left to patrol" is a claim about the RIPPLE. If the room we are standing in has
    -- no exits recorded at all, it is really a claim about our own ignorance -- and stopping
    -- turns a missing reading into a finished sweep. That is the reported bug: the description
    -- said "You see a single exit leading northeast", the map held nothing, and we announced
    -- the grid was swept and switched off.
    --
    -- Note what else was closed at that moment: the failed-exit rescue above is skipped
    -- (nothing was ever attempted, which is exactly the case most deserving a second look), and
    -- _exploreStop kills the stall watchdog whose nudge would have sent the very `ql` that
    -- refills the exits. So every recovery path shut off together.
    --
    -- A quicklook is free (no balance) and re-prints the exits line, which now feeds the map in
    -- every state. Bounded by _noExitLooks so a room that genuinely has none still terminates.
    local r = MAP.rooms and MAP.current and MAP.rooms[MAP.current]
    local bare = true
    if r then for _ in pairs(r.exits or {}) do bare = false; break end end

    -- THE GAME ALREADY ANSWERED: ZERO (v4.7.263). "There are no obvious exits." is a positive
    -- statement, not silence, so asking again cannot change it -- and this branch is where the
    -- boon-screen storm ended up looping. HOLD rather than stop: `_exploreStop` restores the
    -- basher and clears `explore.on`, and `exploreOnGo` only UN-PAUSES (it needs pausedAtBoon),
    -- so stopping in the holding room kills the sweep for the rest of the run.
    --
    -- Note "no OBVIOUS exits" is not "no exits": the holding room prints this line and still has
    -- the `down` the sweep descends by. That is precisely why the marker never touches
    -- room.exits and is never consulted by unexploredExits / _stepRefusal / the stop decision.
    if r and bare and r.exitsTextZero then
      local held = (tonumber(M.explore._noExitHolds) or 0) + 1
      M.explore._noExitHolds = held
      if held <= 40 then -- x3s = 2 minutes, comfortably past a wave countdown
        if held == 1 then
          M._exploreEcho("<grey>the game reports NO exits from this room<reset>"
            .. " -- waiting for one to open (holding room before the descent?).")
        end
        return M._scheduleTick(3)
      end
    end

    -- Budget RESET ON A GENUINE ARRIVAL rather than per ripple (v4.7.263): as a single counter
    -- spanning the whole level, three bare rooms anywhere exhausted it and every later one was
    -- blind. Not keyed by room either -- a dead-reckoned cell is re-entered many times, and a
    -- spent-and-never-reset key would make that cell permanently unlookable.
    if r and bare and (tonumber(M.explore._noExitLooks) or 0) < 3 then
      M.explore._noExitLooks = (tonumber(M.explore._noExitLooks) or 0) + 1
      M._exploreEcho("<indian_red>no exits recorded for this room<reset> -- <cyan>QL<reset>"
        .. " and re-deciding (" .. M.explore._noExitLooks .. "/3).")
      send("ql", false)
      return M._scheduleTick(1.5)
    end
    -- SAY WHY, DO NOT JUST SAY "SWEPT" (v4.7.260). The reported stop printed "grid swept --
    -- nowhere left to patrol" in a room with one unwalked exit; the truth was a single refusal,
    -- and nothing on screen carried it. A stop that hides its reason costs a `mnem explore why`
    -- and a round trip to find out -- print the refusals with the stop instead.
    local refusals = {}
    for num in pairs(MAP.rooms or {}) do
      for _, d in ipairs(MAP.unexploredExits(num) or {}) do
        local why = M._stepRefusal(num, d)
        if why then refusals[#refusals + 1] = tostring(num) .. " " .. d .. ": " .. why end
      end
    end
    if #refusals > 0 then
      table.sort(refusals)
      M._exploreEcho("<indian_red>every remaining exit was refused<reset> --")
      for i = 1, math.min(#refusals, 6) do cecho("\n    <DimGrey>" .. refusals[i]) end
      cecho("\n")
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

-- FURY ON AT EVERY DESCENT (v4.7.285, user: "every time we enter the wade (go down into the main
-- rooms) we should ensure we do FURY ON").
--
-- Fury of Ages makes FURY worth holding almost permanently -- 45 minutes of every hour, +8
-- strength and 20% faster balance -- and the wade entry is the natural moment to assert it: the
-- boon screen is a gap in which it can lapse, exactly like the armour and the Bard's performance
-- that this sits beside.
--
-- ASKING COSTS NOTHING BECAUSE THE REFUSAL IS AN ANSWER. If fury is already up the game says
-- "You're already raged with fury!", which trigger 056 reads as confirmation -- so the redundant
-- send is not waste, it is a free state probe. That is why this does not gate on
-- `ataxiaTemp.infFuryOn`: our flag is the thing being verified, and gating on it would make the
-- check believe itself.
--
-- CLASS-KEYED to the two that actually have fury (Runewarden, Infernal), listed explicitly rather
-- than via ataxia_isClass("knight"), which is true for all three knights. Sent DIRECTLY, like the
-- armour: `queue addclearfull` would wipe it.
function M._furyCheck()
  if not infFuryOfAges then return end
  if not (ataxia_isClass and (ataxia_isClass("runewarden") or ataxia_isClass("infernal"))) then
    return
  end
  send("fury on", false)
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
  -- A NEW SWEEP INHERITS NO ADJACENCY CLAIM (v4.7.262). fromRoom/fromDir describe the last move
  -- ARMED, which across a pause/resume or an off/on belongs to a context that no longer exists
  -- -- and onLava reading them as fact is how an edge on the far side of the grid got condemned.
  M.explore.fromRoom, M.explore.fromDir = nil, nil
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
  M._furyCheck()            -- ...nor un-furied, if the boon makes fury worth holding
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
  -- A NEW SWEEP INHERITS NO ADJACENCY CLAIM (v4.7.262). fromRoom/fromDir describe the last move
  -- ARMED, which across a pause/resume or an off/on belongs to a context that no longer exists
  -- -- and onLava reading them as fact is how an edge on the far side of the grid got condemned.
  M.explore.fromRoom, M.explore.fromDir = nil, nil
  M.explore.failed = {}
  M.explore._retriedFailed = nil
  M.explore.hunting = false
  M.explore.patrolQueue = nil
  M.explore.patrolLoops = 0
  M.explore.iceSlips = 0
  M.explore.settling = true -- treat the starting room like an arrival: let its denizens settle first
  M._wearArmour()           -- never start a sweep undressed
  M._bardPerformanceCheck() -- ...nor unperforming
  M._furyCheck()            -- ...nor un-furied
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
  -- ARRIVAL UNDER DEMENTIA (v4.7.250, corrected v4.7.251). "The room number changed" is
  -- worthless when the number is re-invented: it reads TRUE for a plain look and never FALSE,
  -- so every event became an arrival, `moving` was cleared, and the tick issued ANOTHER move.
  -- The live log is that loop -- "room clear -> moving e" eight times in five seconds.
  --
  -- The reckoning's arm flag is the answer: it is set when a move is sent and consumed by the
  -- first event after it. While it is still armed we have not been credited with the step yet,
  -- so this IS the arrival; once consumed, further events are looks and must not end the move
  -- or re-decide.
  local dr = MAP and MAP.drActive and MAP.drActive()
  local sameRoom
  if dr then
    sameRoom = M.explore.moving and (MAP._drArmed ~= nil)
  else
    sameRoom = M.explore.moving and MAP and MAP.current ~= nil
      and MAP.current == M.explore.fromRoom
  end
  if not sameRoom then -- a genuine arrival (or we weren't moving): end the move
    M.explore.moving = false
    M.explore.tacticalMove = false
    if M._explMoveT then pcall(killTimer, M._explMoveT); M._explMoveT = nil end
    -- Open the settle window: the new room's Char.Items (denizens) will land in a
    -- following "targets updated"; keep the full TICK_DELAY until they've settled.
    M.explore.settling = true
    -- ASK FOR THE EXITS (v4.7.251, user: "if needed the auto mapper should do a QL to see
    -- room exits"). Under dementia gmcp's exit table is keyed to invented room ids, so the
    -- prose line -- "You see exits leading northeast, southeast, and south." -- is the only
    -- honest reading, and QL is how we get it on demand. Free (no balance), and only when the
    -- cell has no exits recorded yet, so it costs one line per genuinely new cell.
    -- A GENUINE ARRIVAL REFILLS THE ASK BUDGET. Both counters are about the room we are
    -- standing in, and we are now standing somewhere else.
    M.explore._noExitLooks, M.explore._noExitHolds = nil, nil

    -- THE ARRIVAL NO LONGER ASKS FOR EXITS (v4.7.263). This is where the boon-screen ql storm
    -- was emitted from: no counter, no throttle, no token, and its own `ql` re-raised the very
    -- event that re-ran it. Two things made it non-terminating -- 005 rebuilt room.exits from
    -- the empty gmcp table on each push (fixed there), and the holding room genuinely reports
    -- no obvious exits, so the answer could never satisfy the question.
    --
    -- It was also redundant even when it worked: this handler runs BEFORE the room's own
    -- description has been processed, so it asked for exits the very next line was about to
    -- supply. Asking now belongs to the tick, 0.5s later, by which point the description has
    -- already fed the map -- see M._askExitsMaybe.
  end
  -- THE TICK IS KEPT WHILE PAUSED, DELIBERATELY (v4.7.263). It is a decision point, not an
  -- action -- _exploreTick refuses to navigate, below the swarm delegation -- and it is the
  -- ONLY clock S._beginEscape's indoor branch has: that branch sets state = "pulling", arms the
  -- hold, sends the retreat, and does NOT self-schedule. Suppress this and an indoor escape
  -- taken during the pause never reaches `recovering`, swarmHold self-clears at 8s, and the
  -- basher resumes swinging at crash HP with the recovery abandoned (the v4.7.235/252 family).
  M._scheduleTick()
  -- The WATCHDOG is navigation-only -- it exists to `ql` the sweep unstuck -- so it does not
  -- re-arm while suspended. onBoonScreen killed the outstanding one, and both resume paths arm
  -- a fresh one, so nothing is lost.
  if not M._navRefusal() then M._armWatchdog() end
end

-- `gmcp.Room.Info`, NOT the `gmcp.Room` prefix (v4.7.263) -- and it MUST match 005's
-- registration. Mudlet raises the prefix for Room.Players / AddPlayer / RemovePlayer /
-- WrongDir too, and every one of those reached `sameRoom == false` here, i.e. was treated as a
-- genuine ARRIVAL: `moving` cleared, the move timeout killed, the settle window opened, all
-- while a move was still in flight. Another player entering the room was enough.
--
-- Moving 005 alone would not have been enough either: this handler is where the arrival
-- decision is actually made, so it has to decline the same events 005 declines.
if M._explRoomH then killAnonymousEventHandler(M._explRoomH) end
M._explRoomH = registerAnonymousEventHandler("gmcp.Room.Info", function() M._onExploreRoom() end)

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
  -- Same split as the arrival handler: a denizen change is exactly what a ground recovery must
  -- react to, so the tick still fires; the watchdog is navigation and does not re-arm.
  M._scheduleTick(M.explore.settling and TICK_DELAY or FAST_TICK)
  if not M._navRefusal() then M._armWatchdog() end
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
  M.explore.lavaRooms = {}
  M.explore.lavaEdges = {}
  M.explore._noExitLooks = nil
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.bossChases, ataxiaTemp.bossPanicAt = nil, nil
  M.explore._prevBasher = nil
end)
