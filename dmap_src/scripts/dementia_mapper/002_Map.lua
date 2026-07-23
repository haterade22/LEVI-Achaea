--[[mudlet
type: script
name: dmap Map
hierarchy:
- Dementia_Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    dmap.map - room graph (data model + hooks)  [ported from LEVI 005_Ripple_Map]
    ============================================================================
    Each Mnemosyne ripple is a fresh room layout, so this builds a per-ripple
    graph as you walk and resets each ripple. Mnemosyne is an unmapped instance
    (gmcp.Room.Info.area == ""), but num/name/exits still arrive, so we plot rooms
    on our own grid.

    Room record: { num, name, x, y, exits = {dir=dest|true}, edges = {dir=nbNum} }
      * exits = every exit the game reports (dir -> dest id/true)
      * edges = exits we've actually WALKED (dir -> neighbour num)

    Dementia tolerance: Creville's Legacy fakes gmcp exits, so a move's direction
    can't always be determined and its walked edge is dropped -- MAP.pathKnown
    routes over the reported-exit graph anyway, and a wrong (faked) exit just fails
    the move (the explorer marks it failed and self-corrects).

    Rendering hooks (MAP.render / MAP.autoShow) live in 005_Window.
    ============================================================================
]]--

dmap = dmap or {}
dmap.map = dmap.map or {}
local MAP = dmap.map

-- Planar grid offsets (+y = north). up/down/in/out are non-planar: tracked as edges
-- for pathfinding but not placed on the grid.
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
  MAP.rooms = {}
  MAP.order = {}
  MAP.current = nil
  MAP.origin = nil
  MAP._lastMoveDir = nil
end
MAP.reset()

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
  room.visited = true
  if name and name ~= "" then room.name = name end

  room.exits = {}
  if type(exits) == "table" then
    for d, dest in pairs(exits) do
      local nd = MAP.normDir(d)
      if nd then room.exits[nd] = tonumber(dest) or dest end
    end
  end

  -- Direction from `from` to here: explicit moveDir, then forward exit, then reverse, then send.
  local dir = MAP.normDir(moveDir)
  if not dir and from and num ~= from.num then
    for d, dest in pairs(from.exits) do
      if dest == num then dir = d break end
    end
  end
  if not dir and from and num ~= from.num then
    for d, dest in pairs(room.exits) do
      if dest == from.num then dir = MAP.OPPOSITE[d] break end
    end
  end
  if not dir and from and num ~= from.num and MAP._lastMoveDir then
    dir = MAP.normDir(MAP._lastMoveDir)
  end

  if from and num ~= from.num and dir then
    from.edges[dir] = num
    local opp = MAP.OPPOSITE[dir]
    if opp then room.edges[opp] = from.num end
  end
  if from and num ~= from.num then MAP._prev = from.num end

  if MAP.origin == nil then MAP.origin = num end
  MAP.current = num
  MAP._lastMoveDir = nil

  MAP.relayout()
end

-- Recompute EVERY room's grid coordinate by BFS over the bidirectional exit graph,
-- anchored on the origin; re-anchor on the current room if the origin can't reach it.
function MAP.relayout()
  local rooms = MAP.rooms or {}
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
    bfs(MAP.current)
  end
end

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

-- BFS over WALKED edges: SHORT direction steps from -> to, or nil.
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

-- BFS over the KNOWN-room graph (reported exits whose dest is a known room, both directions)
-- UNION walked edges -- the dementia-tolerant fallback: the map places rooms from the exit graph,
-- so a room can be on the grid while the WALKED graph can't reach it (faked exits fragment it).
-- Routing over the known graph still reaches it; a faked exit just fails the move + self-corrects.
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
        if opp then add(dest, opp, n) end
      end
    end
    for dir, dest in pairs(r.edges) do add(n, dir, dest) end
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

function MAP.onRipple(n)
  if n ~= nil and n ~= MAP._ripple then
    MAP.reset()
    MAP._ripple = n
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

-- In a Mnemosyne ripple: dmap's single lifecycle flag (set by the wade-status trigger).
function MAP.inMnem()
  return dmap.run ~= nil and dmap.run.active == true
end

-- Capture move direction from the outgoing command (movement sends ".. <dir>").
if MAP._sendHandler then killAnonymousEventHandler(MAP._sendHandler) end
MAP._sendHandler = registerAnonymousEventHandler("sysDataSendRequest", function(_, cmd)
  if not MAP.inMnem() or type(cmd) ~= "string" then return end
  local last = cmd:match("(%a+)%s*$")
  if last and MAP.normDir(last) then MAP._lastMoveDir = MAP.normDir(last) end
end)

-- On each room arrival: fresh tower entry starts a clean map; while inside, record + refresh.
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
