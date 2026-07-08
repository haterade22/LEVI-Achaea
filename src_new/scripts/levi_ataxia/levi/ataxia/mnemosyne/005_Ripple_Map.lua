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

  -- Assign coordinates. First choice: follow the path we just walked (relative
  -- to `from`). Otherwise anchor to ANY already-placed neighbour via our own
  -- exit graph -- this is what lets the grid bootstrap from the origin without a
  -- known move direction or forward-populated exits.
  if MAP.origin == nil then
    MAP.origin = num
    room.x, room.y = 0, 0
  elseif room.x == nil then
    if from and from.x ~= nil and dir and MAP.OFFSETS[dir] then
      room.x = from.x + MAP.OFFSETS[dir][1]
      room.y = from.y + MAP.OFFSETS[dir][2]
    else
      MAP._anchor(room)
    end
  end

  -- Record the traversed edge both ways (only the pair we actually walked).
  if from and num ~= from.num and dir then
    from.edges[dir] = num
    local opp = MAP.OPPOSITE[dir]
    if opp then room.edges[opp] = from.num end
  end
  if from and num ~= from.num then MAP._prev = from.num end -- for `mnem map status`

  -- Topology propagation: the game reports each room's exits as dir->neighbour
  -- num, so once a room is placed we can position its neighbours straight from
  -- the exit graph -- no need to have captured which way we moved. This is what
  -- makes the grid fill in reliably even when the movement direction is unknown.
  MAP._propagate(room)

  MAP.current = num
  MAP._lastMoveDir = nil
end

-- Place `room` next to any neighbour that ALREADY has coordinates, using room's
-- own exit graph: an exit `d` to a placed neighbour means the neighbour lies `d`
-- of us, so we lie OPPOSITE[d] of it. This is the primary bootstrap -- a freshly
-- entered room's exits reliably carry real nums for the (visited) rooms around
-- it, even when we couldn't tell which way we moved. Returns true if placed.
function MAP._anchor(room)
  if not room or room.x ~= nil then return false end
  for d, dest in pairs(room.exits) do
    local opp = MAP.OPPOSITE[d]
    local off = opp and MAP.OFFSETS[opp]
    local nb = (type(dest) == "number") and MAP.rooms[dest] or nil
    if off and nb and nb.x ~= nil and dest ~= room.num then
      room.x = nb.x + off[1]
      room.y = nb.y + off[2]
      return true
    end
  end
  return false
end

-- Place a room's not-yet-positioned exit neighbours from the exit graph.
-- Neighbours are created as unvisited stubs (coords only); each gains a name,
-- its own exits, and starts rendering once it's actually visited.
function MAP._propagate(room)
  if not room or room.x == nil then return end
  for d, dest in pairs(room.exits) do
    local off = MAP.OFFSETS[d]
    if off and type(dest) == "number" and dest > 0 and dest ~= room.num then
      local nb = MAP.rooms[dest]
      if not nb then
        nb = { num = dest, exits = {}, edges = {}, visited = false }
        MAP.rooms[dest] = nb
        table.insert(MAP.order, dest)
      end
      if nb.x == nil then
        nb.x = room.x + off[1]
        nb.y = room.y + off[2]
      end
    end
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
