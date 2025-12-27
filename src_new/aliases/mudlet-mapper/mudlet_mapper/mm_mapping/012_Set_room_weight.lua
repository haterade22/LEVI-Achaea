--[[mudlet
type: alias
name: Set room weight
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^rw(?: (\w+))? (\d+)$'
command: ''
packageName: ''
]]--

local weight = tonumber(matches[3]), room
if matches[2] == '' then room = mmp.currentroom
else
  room = tonumber(matches[2]) or mmp.relativeroom(mmp.currentroom, matches[2])
end

if not room or not mmp.roomexists(room) then
  mmp.echo("Sorry - which room do you want to set the weight on? I don't know where you are at the moment, if you want to do the current room.")
  return
end

if not weight then
  mmp.echo("What weight do you want to set on #"..room.."?")
end

local oldweight = getRoomWeight(room)
setRoomWeight(room, weight)

if weight > oldweight then
  mmp.echo("Increased the room weight on #"..room.." ("..getRoomName(room)..") by "..(weight-oldweight).." to "..weight.." - making it less desirable to travel through.")
elseif weight < oldweight then
  mmp.echo("Decreased the room weight on #"..room.." ("..getRoomName(room)..") by "..(oldweight-weight).." to "..weight.." - making it more desirable to travel through.")
else
  mmp.echo("The room weight on #"..room.." ("..getRoomName(room)..") is already "..weight..".")
end