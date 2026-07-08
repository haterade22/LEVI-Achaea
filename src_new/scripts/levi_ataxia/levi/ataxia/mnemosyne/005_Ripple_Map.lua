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

function MAP.reset()
  MAP.rooms = {} -- [num] = room record
  MAP.order = {} -- visit order (nums)
  MAP.current = nil
  MAP.origin = nil
  MAP._lastMoveDir = nil
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
    for d, dest in pairs(exits) do
      local nd = MAP.normDir(d)
      if nd then room.exits[nd] = tonumber(dest) or dest end
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

  local function bfs(anchor)
    for _, r in pairs(rooms) do r.x, r.y = nil, nil end
    if not (anchor and rooms[anchor]) then return end
    rooms[anchor].x, rooms[anchor].y = 0, 0
    local q, head = { anchor }, 1
    while head <= #q do
      local cur = q[head]; head = head + 1
      local cr = rooms[cur]
      for _, e in ipairs(adj[cur] or {}) do
        local nb = rooms[e.to]
        if nb and nb.x == nil then
          nb.x, nb.y = cr.x + e.dx, cr.y + e.dy
          q[#q + 1] = e.to
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
  MAP.onRoom(ri.num, ri.name, ri.exits, MAP._lastMoveDir)
  if MAP.render then MAP.render() end
end)
