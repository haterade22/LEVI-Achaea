--[[mudlet
type: alias
name: Create a room
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^(?:rlc|room create) (.+)?$
command: ''
packageName: ''
]]--

local m = matches[2]
if m:starts("feature") then
  -- another alias was meant.
  return
end
local rid, rname
if mmp.roomexists(mmp.currentroom) then
  rid, rname = mmp.currentroom, mmp.currentroomname
end
local x, y, z

local function set(newid)
  -- small func to set things
  local rid = newid or createRoomID()
  addRoom(rid)
  setRoomCoordinates(rid, x, y, z)
  if mmp.roomexists(mmp.currentroom) then
    setRoomArea(rid, getRoomArea(mmp.currentroom))
  end
  if mmp.roomexists(mmp.currentroom) then
    setRoomEnv(rid, getRoomEnv(mmp.currentroom))
  end
  mmp.setExit(mmp.currentroom, rid, m)
  clearRoomUserDataItem(newid, "hashonly")
  mmp.echo(string.format("Created new room (%d) at %dx, %dy, %dz.\n", rid, x, y, z))
  centerview(mmp.roomexists(mmp.currentroom) and mmp.currentroom or rid)
  if not mmp.roomexists(mmp.currentroom) then
    mmp.currentroom = rid;
    mmp.currentroomname = ""
  end
end

-- let's be flexible and allow several ways if giving an arg
-- rc v# x y z
newid, x, y, z = string.match(m, "v(%d+) (%-?%d+) (%-?%d+) (%-?%d+)")
if x then
  set(newid);
  return
end
-- rc x y z
x, y, z = string.match(m, "(%-?%d+) (%-?%d+) (%-?%d+)")
if x then
  set();
  return
end
if not rid then
  mmp.echo("Don't know where we are at the moment in order to use relative coordinates.")
  return
end
-- rc xx? yy? zz?
x, y, z = string.match(m, "(%-?%d+)x"), string.match(m, "(%-?%d+)y"), string.match(m, "(%-?%d+)z")
if x or y or z then
  -- merge w/ old coords if any are missing
  local ox, oy, oz = getRoomCoordinates(rid)
  x = x or ox;
  y = y or oy;
  z = z or oz
  set();
  return
end
-- rc left/west, right/east, ...
local ox, oy, oz = getRoomCoordinates(rid)
local has = table.contains
for w in string.gmatch(m, "%a+") do
  if has({"west", "left", "w", "l"}, w) then
    x = (x or ox) - 1;
    y = (y or oy);
    z = (z or oz)
  elseif has({"east", "right", "e", "r"}, w) then
    x = (x or ox) + 1;
    y = (y or oy);
    z = (z or oz)
  elseif has({"north", "top", "n", "t"}, w) then
    x = (x or ox);
    y = (y or oy) + 1;
    z = (z or oz)
  elseif has({"south", "bottom", "s", "b"}, w) then
    x = (x or ox);
    y = (y or oy) - 1;
    z = (z or oz)
  elseif has({"northwest", "topleft", "nw", "tl"}, w) then
    x = (x or ox) - 1;
    y = (y or oy) + 1;
    z = (z or oz)
  elseif has({"northeast", "topright", "ne", "tr"}, w) then
    x = (x or ox) + 1;
    y = (y or oy) + 1;
    z = (z or oz)
  elseif has({"southeast", "bottomright", "se", "br"}, w) then
    x = (x or ox) + 1;
    y = (y or oy) - 1;
    z = (z or oz)
  elseif has({"southwest", "bottomleft", "sw", "bl"}, w) then
    x = (x or ox) - 1;
    y = (y or oy) - 1;
    z = (z or oz)
  elseif has({"up", "u"}, w) then
    x = (x or ox);
    y = (y or oy);
    z = (z or oz) + 1
  elseif has({"down", "d"}, w) then
    x = (x or ox);
    y = (y or oy);
    z = (z or oz) - 1
  end
end
if x then
  set();
  return
end
mmp.echo(
  [[Where do you want to move the room to?
  You can use direct coordinates or relative directions.]]
)