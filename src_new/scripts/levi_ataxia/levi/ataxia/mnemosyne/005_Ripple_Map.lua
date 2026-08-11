--[[mudlet
type: script
name: Mnemosyne Ripple Map
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
    MNEMOSYNE RIPPLE MAP - room graph (data model + hooks)
    ============================================================================
    Each Mnemosyne ripple ("level") is a fresh room layout, so this builds a
    per-ripple graph as you walk and resets each ripple. Mnemosyne is an unmapped
    instance (gmcp.Room.Info.area == ""), but num/name/exits still arrive, so we
    plot rooms on our own grid.

    Room record: { num, name, x, y, exits = {dir=dest|true}, edges = {dir=nbNum} }
      * exits  = every exit the game reports for the room (dir -> dest id/true)
      * edges  = exits we've actually WALKED (dir -> neighbour num) -- used for
                 pathfinding and to tell explored vs unexplored exits apart.

    Direction of travel is captured from sysDataSendRequest (the movement aliases
    send ".. <dir>"), with a gmcp exits-dest fallback. Coordinates are assigned by
    walking a dir->offset table from the origin room.

    Rendering lives in 006_Ripple_Map_Window.lua; this file is pure logic + hooks.
    ============================================================================
]]--

ataxia.mnemosyne = ataxia.mnemosyne or {}
ataxia.mnemosyne.map = ataxia.mnemosyne.map or {}
local MAP = ataxia.mnemosyne.map

-- Planar grid offsets (+y = north/up). up/down/in/out are non-planar: tracked as
-- edges for pathfinding but not placed on the grid.
MAP.OFFSETS = {
  north = { 0, 1 }, south = { 0, -1 }, east = { 1, 0 }, west = { -1, 0 },
  northeast = { 1, 1 }, northwest = { -1, 1 }, southeast = { 1, -1 }, southwest = { -1, -1 },
}
MAP.OPPOSITE = {
  north = "south", south = "north", east = "west", west = "east",
  northeast = "southwest", southwest = "northeast", northwest = "southeast", southeast = "northwest",
  up = "down", down = "up", ["in"] = "out", out = "in",
}
local DIRNORM = {
  n = "north", s = "south", e = "east", w = "west", ne = "northeast", nw = "northwest",
  se = "southeast", sw = "southwest", u = "up", d = "down", ["in"] = "in", out = "out",
  north = "north", south = "south", east = "east", west = "west", northeast = "northeast",
  northwest = "northwest", southeast = "southeast", southwest = "southwest", up = "up", down = "down",
}
-- long form -> short form for sending as a movement command
local DIRSHORT = {
  north = "n", south = "s", east = "e", west = "w", northeast = "ne", northwest = "nw",
  southeast = "se", southwest = "sw", up = "u", down = "d", ["in"] = "in", out = "out",
}

function MAP.normDir(d)
  if type(d) ~= "string" then return nil end
  return DIRNORM[d:lower()]
end

function MAP.shortDir(d)
  return DIRSHORT[MAP.normDir(d) or ""] or d
end

-- ---------------------------------------------------------------------------
-- Graph
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- THE RIPPLE IS 4x4, AND THAT IS EVIDENCE (v4.7.249)
-- ---------------------------------------------------------------------------
-- User, 2026-08-11: "The dementia mapping in the wade isnt working right. We KNOW the exits
-- we have available. We know it is a 4 X 4 so we should know."
--
-- DEMENTIA (Creville's Legacy, a common boon -- "You attack 20% faster but you have incurable
-- dementia") hallucinates the room wholesale. A live capture:
--
--   Nothing can be seen here by that name.
--   ... [ dem ]
--   Meadows east of the Pachacacha.
--   ... The area is ablaze! Lokash stands here, engrossed in some administrative task.
--   You see exits leading north and west.
--   You have no idea where you are.
--   Your environment conforms to that of Urban.
--   You are in wading the Mnemosyne.
--
-- A real Achaea room name, a real room NUMBER in the prompt (79390), an NPC that is not
-- there, and a pair of exits -- none of it true, and all of it arriving through the same
-- gmcp channel the map trusts. Until now nothing could tell it apart: `MAP.onRoom` recorded
-- whatever exits it was handed and `relayout` placed rooms wherever those exits implied,
-- so one demented room could stretch the layout across the map and strand the sweep.
--
-- The 4x4 is the one fact dementia cannot fake, and it was known ONLY to the renderer
-- (006's `LEVEL = 4`) -- the graph never used it. It is a hard geometric constraint: every
-- room of a ripple fits inside a 4x4 box, so any exit whose destination would push the
-- bounding box past 4 cells on either axis CANNOT be a real exit of this ripple.
--
-- It only ever rejects what it can PROVE impossible: with few rooms placed the box is small,
-- nothing exceeds it, and every exit is allowed. The check tightens as the ripple is explored,
-- which is exactly when dementia has had time to inject something.
MAP.GRID = 4

-- Would stepping `dir` out of room `num` land inside the ripple's 4x4?
-- TRUE when it fits, when the direction is non-planar (up/down carry no offset -- the
-- holding room's descent is the one legitimate one), or whenever we cannot tell. Only a
-- provable overflow returns false: never reject on ignorance, or a half-mapped ripple would
-- refuse its own real exits.
function MAP.exitFitsGrid(num, dir)
  local rooms = MAP.rooms or {}
  local r = rooms[num]
  if not r or r.x == nil or r.y == nil then return true end
  local off = MAP.OFFSETS and MAP.OFFSETS[dir]
  if not off then return true end -- non-planar: no 2-D claim to check
  local tx, ty = r.x + off[1], r.y + off[2]
  local minx, maxx, miny, maxy = MAP.bounds()
  if not minx then return true end
  local g = tonumber(MAP.GRID) or 4
  local w = math.max(maxx, tx) - math.min(minx, tx) + 1
  local h = math.max(maxy, ty) - math.min(miny, ty) + 1
  return w <= g and h <= g
end

-- ---------------------------------------------------------------------------
-- DEAD RECKONING -- WHEN THE ROOM ID ITSELF IS A LIE (v4.7.250)
-- ---------------------------------------------------------------------------
-- User, 2026-08-11: "the gmcp room id will be changed every time we look because of dementia
-- that we cannot cure, so we need to track by exits and map it out like that."
--
-- This is deeper than the faked EXITS handled in v4.7.249. If `gmcp.Room.Info.num` is a fresh
-- invention on every look, then keying the graph by it is broken at the root:
--
--   * every look mints a NEW room record, so MAP.rooms fills with phantoms;
--   * MAP.current changes without us moving, so the explorer's arrival test
--     (`MAP.current ~= explore.fromRoom`) reads TRUE on every gmcp.Room -- including a plain
--     `ql` -- and every look looks like an arrival;
--   * `room.exits` destination ids never match any key we hold, so relayout links nothing
--     and the layout never forms.
--
-- And Creville's Legacy says "incurable", so this is not a state to wait out.
--
-- THE ONE THING DEMENTIA CANNOT TOUCH IS WHAT WE OURSELVES DID. We know which direction we
-- sent, and we know when a move failed, because failure has its own lines (Room.WrongDir, the
-- wall line, the ice slip). So position is dead-reckoned from our own movement and the room
-- KEY becomes that position -- "dr:2,1" -- instead of the server's id.
--
-- Deliberately a KEY SWAP rather than a parallel map. Everything downstream -- MAP.rooms,
-- room.edges, MAP.path, unexploredExits, the explorer's whole sweep -- treats the key as
-- opaque, so it all keeps working unchanged on synthetic keys. A second implementation of the
-- navigation would have been a second thing to keep correct.
MAP.dr = MAP.dr or { on = false, x = 0, y = 0 }

-- Dementia is the trigger, not a guess: the affliction is tracked already (it is in the
-- default curing table and rides the prompt as `dem`). Outside the tower this is inert.
function MAP.drActive()
  if not MAP.inMnem() then return false end
  if MAP.drForce ~= nil then return MAP.drForce == true end -- test/manual override
  return (ataxia.afflictions ~= nil and ataxia.afflictions.dementia == true)
end

function MAP.drKey(x, y)
  return "dr:" .. tostring(x) .. "," .. tostring(y)
end

-- The key for where dead reckoning currently believes we are.
function MAP.drHereKey()
  return MAP.drKey(MAP.dr.x, MAP.dr.y)
end

-- A confirmed move. Called only where the move is known to have happened, never speculatively:
-- a wrong step here silently mislabels every room from now on, which is worse than not mapping.
function MAP.drMoved(dir)
  local nd = MAP.normDir(dir)
  local off = nd and MAP.OFFSETS and MAP.OFFSETS[nd]
  if not off then return end -- non-planar (the holding room's descent) carries no 2-D step
  MAP.dr.x = MAP.dr.x + off[1]
  MAP.dr.y = MAP.dr.y + off[2]
end

function MAP.drResetPos()
  MAP.dr.x, MAP.dr.y = 0, 0
end

-- The whole dead-reckoned arrival, in one place so it can be exercised directly. ONE OWNER:
-- this runs from 005's gmcp.Room handler, which is registered before the explorer's (package
-- load order) and so still sees `explore.moving` before the explorer clears it. Advancing in
-- both would double-step; advancing only in the explorer would miss every move made outside
-- the sweep -- the swarm's tumbles and pulls.
function MAP.drArrive(exits)
  local ex = ataxia.mnemosyne and ataxia.mnemosyne.explore
  local movedDir = (ex and ex.moving and ex.fromDir) or MAP._lastMoveDir
  if movedDir then MAP.drMoved(movedDir) end
  -- Pass the direction so the WALKED edge is recorded: without it `room.edges` stays empty,
  -- every exit reads as unexplored forever and MAP.path can never backtrack.
  MAP.onRoom(MAP.drHereKey(), nil, exits, movedDir)
end

function MAP.reset()
  MAP.rooms = {} -- [num] = room record
  MAP.order = {} -- visit order (nums)
  MAP.current = nil
  MAP.origin = nil
  MAP._lastMoveDir = nil
  MAP.drResetPos() -- a new ripple starts the reckoning at its own origin
end
MAP.reset()

-- Record arrival in room `num`. `exits` = gmcp dir->dest table. `moveDir` = the
-- direction moved to get here (any form) or nil to infer.
function MAP.onRoom(num, name, exits, moveDir)
  num = tonumber(num) or num
  if num == nil then return end
  MAP.rooms = MAP.rooms or {}

  local from = MAP.current and MAP.rooms[MAP.current] or nil
  local room = MAP.rooms[num]
  if not room then
    room = { num = num, name = name, exits = {}, edges = {} }
    MAP.rooms[num] = room
    table.insert(MAP.order, num)
  end
  room.visited = true -- arriving here (vs being a propagation stub) means we've been in it
  if name and name ~= "" then room.name = name end

  -- Record the room's exits (normalise dir keys; coerce dest ids to numbers so
  -- they compare against room nums -- gmcp reports exit dests as strings).
  room.exits = {}
  if type(exits) == "table" then
    -- Under dead reckoning the DESTINATION ids are inventions and will never match a synthetic
    -- key, so store 0 ("known exit, unknown destination") and keep only the DIRECTION. That is
    -- the half the sweep actually needs, and it is what the user meant by tracking by exits:
    -- the direction set is the room's fingerprint, the id attached to it is noise.
    local dr = MAP.drActive()
    for d, dest in pairs(exits) do
      local nd = MAP.normDir(d)
      if nd then room.exits[nd] = dr and 0 or (tonumber(dest) or dest) end
    end
  end

  -- Work out which direction we moved from `from` to here. gmcp only fills a
  -- real exit dest for neighbours it already knows (visited rooms) and reports
  -- 0 otherwise, so on first arrival the FORWARD exit (from -> here) is still 0
  -- while the REVERSE exit (here -> from) already carries from's real num. Try:
  -- explicit moveDir, then forward, then reverse, then the captured send.
  local dir = MAP.normDir(moveDir)
  if not dir and from and num ~= from.num then
    for d, dest in pairs(from.exits) do -- forward: from's exit that points here
      if dest == num then dir = d break end
    end
  end
  if not dir and from and num ~= from.num then
    for d, dest in pairs(room.exits) do -- reverse: our exit that points back to from
      if dest == from.num then dir = MAP.OPPOSITE[d] break end
    end
  end
  if not dir and from and num ~= from.num and MAP._lastMoveDir then
    dir = MAP.normDir(MAP._lastMoveDir)
  end

  -- Record the traversed edge both ways (only the pair we actually walked). This
  -- is WALKED connectivity, used by MAP.path for click-to-walk -- kept separate
  -- from grid coordinates (which are derived from the exit graph in relayout).
  if from and num ~= from.num and dir then
    from.edges[dir] = num
    local opp = MAP.OPPOSITE[dir]
    if opp then room.edges[opp] = from.num end
  end
  if from and num ~= from.num then MAP._prev = from.num end -- for `mnem map status`

  if MAP.origin == nil then MAP.origin = num end
  MAP.current = num
  MAP._lastMoveDir = nil

  -- Re-derive every room's coordinate from the exit graph now that this room and
  -- its exits are recorded (see MAP.relayout).
  MAP.relayout()
end

-- Recompute EVERY room's grid coordinate from scratch by BFS over the
-- bidirectional exit graph. Run on every arrival, so it always uses the latest
-- exits from ALL rooms -- gmcp fills a real exit dest only for rooms it already
-- knows, so a pair A<->B becomes linkable as soon as EITHER side reports the
-- other, and a room that couldn't be placed on arrival gets placed on a later
-- pass once a neighbour's exit back to it is known. Placing per-arrival (the old
-- approach) got stuck: if `from` wasn't placed yet, nothing downstream could be.
--
-- Anchored on the origin so coordinates stay stable as you walk; if the origin's
-- component doesn't reach the room you're standing in (a not-yet-known link),
-- re-anchor the whole layout on the current room so it's always visible.
function MAP.relayout()
  local rooms = MAP.rooms or {}

  -- Under dead reckoning the coordinate IS the key, so there is nothing to derive: parse it
  -- back out. BFS would have nothing to work with anyway -- we deliberately discarded the
  -- faked exit destinations that its adjacency is built from.
  if MAP.drActive() then
    for key, r in pairs(rooms) do
      local sx, sy = tostring(key):match("^dr:(-?%d+),(-?%d+)$")
      r.x, r.y = tonumber(sx), tonumber(sy)
    end
    return
  end

  -- Undirected planar adjacency from every known exit edge (both directions):
  -- an exit `d` from A to a known room B means B sits `d` of A, and A sits
  -- OPPOSITE[d] of B. Non-planar exits (up/down/in/out) carry no 2-D offset.
  local adj = {}
  local function link(a, b, dx, dy)
    adj[a] = adj[a] or {}
    adj[a][#adj[a] + 1] = { to = b, dx = dx, dy = dy }
  end
  for n, r in pairs(rooms) do
    for d, dest in pairs(r.exits) do
      local off = MAP.OFFSETS[d]
      if off and type(dest) == "number" and dest ~= n and rooms[dest] then
        link(n, dest, off[1], off[2])
        link(dest, n, -off[1], -off[2])
      end
    end
  end

  -- BFS, BOUNDED BY THE 4x4 (v4.7.249). A dementia-faked exit is a link like any other, so
  -- without this one lie drags the layout across the map and every room placed through it is
  -- in the wrong cell. Refusing a placement that would burst the box keeps the lie OUT of the
  -- coordinates entirely: the room simply stays unplaced (invisible on the mini-map, and
  -- MAP.path already tolerates unplaced rooms) instead of corrupting the rooms around it.
  --
  -- The running box is tracked over VISITED rooms only, matching MAP.bounds() -- propagation
  -- stubs are not drawn and must not stretch the grid.
  local function bfs(anchor)
    for _, r in pairs(rooms) do r.x, r.y = nil, nil end
    if not (anchor and rooms[anchor]) then return end
    local g = tonumber(MAP.GRID) or 4
    local minx, maxx, miny, maxy
    local function note(r)
      if not r.visited then return end
      minx = math.min(minx or r.x, r.x); maxx = math.max(maxx or r.x, r.x)
      miny = math.min(miny or r.y, r.y); maxy = math.max(maxy or r.y, r.y)
    end
    rooms[anchor].x, rooms[anchor].y = 0, 0
    note(rooms[anchor])
    local q, head = { anchor }, 1
    while head <= #q do
      local cur = q[head]; head = head + 1
      local cr = rooms[cur]
      for _, e in ipairs(adj[cur] or {}) do
        local nb = rooms[e.to]
        if nb and nb.x == nil then
          local nx, ny = cr.x + e.dx, cr.y + e.dy
          local fits = true
          if nb.visited and minx then
            local w = math.max(maxx, nx) - math.min(minx, nx) + 1
            local h = math.max(maxy, ny) - math.min(miny, ny) + 1
            fits = (w <= g and h <= g)
          end
          if fits then
            nb.x, nb.y = nx, ny
            note(nb)
            q[#q + 1] = e.to
          end
        end
      end
    end
  end

  bfs(MAP.origin)
  if MAP.current and rooms[MAP.current] and rooms[MAP.current].x == nil then
    bfs(MAP.current) -- guarantee the room we're in is on the grid
  end
end

-- Exits the game reports that we haven't walked yet.
function MAP.unexploredExits(num)
  local room = MAP.rooms and MAP.rooms[num]
  if not room then return {} end
  local out = {}
  for d in pairs(room.exits) do
    if not room.edges[d] then table.insert(out, d) end
  end
  return out
end

function MAP.hasUnexplored(num)
  return #MAP.unexploredExits(num) > 0
end

-- BFS over walked edges from `fromNum` to `toNum`; returns a list of SHORT
-- direction steps to send, or nil if unreachable.
function MAP.path(fromNum, toNum)
  fromNum = tonumber(fromNum) or fromNum
  toNum = tonumber(toNum) or toNum
  if not (MAP.rooms and MAP.rooms[fromNum] and MAP.rooms[toNum]) then return nil end
  if fromNum == toNum then return {} end
  local queue, prev, head = { fromNum }, { [fromNum] = true }, 1
  local from_of = {}
  while head <= #queue do
    local cur = queue[head]; head = head + 1
    for dir, nb in pairs(MAP.rooms[cur].edges) do
      if not prev[nb] then
        prev[nb] = true
        from_of[nb] = { room = cur, dir = dir }
        if nb == toNum then
          local steps, node = {}, toNum
          while node ~= fromNum do
            local p = from_of[node]
            table.insert(steps, 1, MAP.shortDir(p.dir))
            node = p.room
          end
          return steps
        end
        table.insert(queue, nb)
      end
    end
  end
  return nil
end

-- BFS over the KNOWN-room graph (every reported exit whose dest is a real known room,
-- both directions) UNION the walked edges -- a superset of MAP.path. Used as a routing
-- fallback: the map places all rooms from the exit graph (relayout), so a room can be on
-- the grid (and show `?`) while the WALKED graph doesn't reach it -- dementia (Creville's
-- Legacy) fakes gmcp exits, so a move's direction can't always be determined and its walked
-- edge is dropped, fragmenting MAP.path's graph. Routing over the known graph still reaches
-- it; a wrong (faked) exit just fails the move, which marks it failed and self-corrects.
-- Returns a list of SHORT direction steps, or nil if unreachable.
function MAP.pathKnown(fromNum, toNum)
  fromNum = tonumber(fromNum) or fromNum
  toNum = tonumber(toNum) or toNum
  if not (MAP.rooms and MAP.rooms[fromNum] and MAP.rooms[toNum]) then return nil end
  if fromNum == toNum then return {} end
  local adj = {}
  local function add(a, dir, b)
    if not (MAP.rooms[b] and b ~= a) then return end
    adj[a] = adj[a] or {}
    adj[a][#adj[a] + 1] = { dir = dir, to = b }
  end
  for n, r in pairs(MAP.rooms) do
    for dir, dest in pairs(r.exits) do
      if type(dest) == "number" then
        add(n, dir, dest)
        local opp = MAP.OPPOSITE[dir]
        if opp then add(dest, opp, n) end -- reverse, in case only one side reported the link
      end
    end
    for dir, dest in pairs(r.edges) do add(n, dir, dest) end -- keep walked connectivity too
  end
  local queue, seen, head = { fromNum }, { [fromNum] = true }, 1
  local from_of = {}
  while head <= #queue do
    local cur = queue[head]; head = head + 1
    for _, e in ipairs(adj[cur] or {}) do
      if not seen[e.to] then
        seen[e.to] = true
        from_of[e.to] = { room = cur, dir = e.dir }
        if e.to == toNum then
          local steps, node = {}, toNum
          while node ~= fromNum do
            local p = from_of[node]
            table.insert(steps, 1, MAP.shortDir(p.dir))
            node = p.room
          end
          return steps
        end
        queue[#queue + 1] = e.to
      end
    end
  end
  return nil
end

-- Grid extent over VISITED rooms (propagation stubs carry coords too, but they
-- aren't drawn, so they must not stretch the grid).
function MAP.bounds()
  local minx, maxx, miny, maxy
  for _, r in pairs(MAP.rooms or {}) do
    if r.x ~= nil and r.visited then
      minx = math.min(minx or r.x, r.x); maxx = math.max(maxx or r.x, r.x)
      miny = math.min(miny or r.y, r.y); maxy = math.max(maxy or r.y, r.y)
    end
  end
  return minx, maxx, miny, maxy
end

-- Reset when the ripple changes (new level). Called from onRipple; independent
-- of whether telemetry reporting is on.
function MAP.onRipple(n)
  if n ~= nil and n ~= MAP._ripple then
    MAP.reset()
    MAP._ripple = n
    -- The ripple line fires while you're already standing in the new level's
    -- first room, so re-seed it -- otherwise the map is blank until you move.
    if MAP.inMnem() and gmcp and gmcp.Room and gmcp.Room.Info then
      local ri = gmcp.Room.Info
      MAP.onRoom(ri.num, ri.name, ri.exits, nil)
    end
    if MAP.render then MAP.render() end
  end
end

-- ---------------------------------------------------------------------------
-- Runtime hooks
-- ---------------------------------------------------------------------------

-- In a Mnemosyne context: the survey flag OR an active telemetry run (the flag
-- is set opportunistically by the SURVEY line and can be missed between floors,
-- so accept either signal).
function MAP.inMnem()
  return (ataxiaBasher ~= nil and ataxiaBasher.inMnemosyne == true)
    or (ataxia.mnemosyne.run ~= nil and ataxia.mnemosyne.run.active == true)
end

-- Capture the direction of movement from the outgoing command (movement aliases
-- send ".. <dir>"). Only while in Mnemosyne; self-correcting (the actual move is
-- the last movement command before the room changes).
if MAP._sendHandler then killAnonymousEventHandler(MAP._sendHandler) end
MAP._sendHandler = registerAnonymousEventHandler("sysDataSendRequest", function(_, cmd)
  if not MAP.inMnem() or type(cmd) ~= "string" then return end
  local last = cmd:match("(%a+)%s*$")
  if last and MAP.normDir(last) then MAP._lastMoveDir = MAP.normDir(last) end
end)

-- On each room arrival: show/hide the widget by context; a fresh Mnemosyne entry
-- starts a clean map; while inside, record the room and refresh.
if MAP._roomHandler then killAnonymousEventHandler(MAP._roomHandler) end
MAP._roomHandler = registerAnonymousEventHandler("gmcp.Room", function()
  local here = MAP.inMnem()
  if here and not MAP._wasInMnem then
    MAP.reset()
    MAP._ripple = nil
  end
  MAP._wasInMnem = here
  if MAP.autoShow then MAP.autoShow() end
  if not here or not (gmcp and gmcp.Room and gmcp.Room.Info) then return end
  local ri = gmcp.Room.Info
  -- Under dementia the id and the name are both inventions; the key comes from our own dead
  -- reckoning instead, and the name is dropped rather than recorded as this cell's identity
  -- (it would be a different lie every look).
  if MAP.drActive() then
    -- ONE OWNER for the reckoning. This handler is registered in 005 and the explorer's in
    -- 008, so this one fires first (package load order) and sees `moving` before the explorer
    -- clears it. Advancing in both places would double-step; advancing in the explorer alone
    -- would miss moves made outside the sweep (the swarm's tumbles and pulls).
    MAP.drArrive(ri.exits)
  else
    MAP.onRoom(ri.num, ri.name, ri.exits, MAP._lastMoveDir)
  end
  if MAP.render then MAP.render() end
end)
