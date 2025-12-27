--[[mudlet
type: alias
name: Set a room character
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^rcc ([^ ]+)(?: (\w+))?$'
command: ''
packageName: ''
]]--

local room = matches[3] or mmp.currentroom
room = tonumber(room) or mmp.relativeroom(mmp.currentroom, room)
if not room or not mmp.roomexists(room) then
  mmp.echo("Sorry - which room do you want to put this character in? I don't know where you are at the moment, if you want to do the current room.")
  return
end

local char = matches[2]

if char == "clear" then
  setRoomChar(room, ' ')
  mmp.echo("Cleared the character from "..room.." ("..getRoomName(room)..")")
else
  setRoomChar(room, char)
  mmp.echo("Set the "..char:sub(1,1).." character on "..room.." ("..getRoomName(room)..")")
end
centerview(mmp.currentroom)