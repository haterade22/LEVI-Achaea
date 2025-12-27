--[[mudlet
type: alias
name: Add Room Mark
hierarchy:
- mudlet-mapper
- Mudlet Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^room mark (\w+)(?: (\w+))?$'
command: ''
packageName: ''
]]--

local tmp = getRoomUserData(1, "gotoMapping")
local maptable = {}

if tmp ~= "" then
  maptable = yajl.to_value(tmp)
end

local location, markname
if not matches[3] then
  markname = matches[2]
  location = mmp.currentroom
elseif tonumber(matches[2]) then
  location = matches[2]; markname = matches[3]
else
  location = matches[3]; markname = matches[2]
end

-- can't allow mark name to ne a number - yajl then generates a giant table of null's
if tonumber(markname) then
  mmp.echo("The mark name can't be a number.") return
end

maptable[markname] = location
local tmp2 = yajl.to_string(maptable)

if not mmp.roomexists(1) then
  addRoom(1)
end

setRoomUserData(1, "gotoMapping", tmp2)
mmp.echo(string.format("Room mark for '%s' set to room %s.", markname, location))