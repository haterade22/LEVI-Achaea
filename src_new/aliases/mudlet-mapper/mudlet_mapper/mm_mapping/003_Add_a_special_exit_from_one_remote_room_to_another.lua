--[[mudlet
type: alias
name: Add a special exit from one remote room to another
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^spev (\d+) (\d+) (.+)$
command: ''
packageName: ''
]]--

local room1, room2 = tonumber(matches[2]), tonumber(matches[3])

if not room1 or not mmp.roomexists(room1) then
  mmp.echo("Room #"..matches[2].." doesn't exist - create it first, or make sure you got the room ID right?")
  return
end

if not room2 or not mmp.roomexists(room2) then
  mmp.echo("Room #"..matches[3].." doesn't exist - create it first, or make sure you got the room ID right?")
  return
end

addSpecialExit(room1, room2, matches[4])
mmp.echo(string.format("Added special exit with command '%s' to from %s (%d) to %s (%d).", matches[4], getRoomName(room1), room1, getRoomName(room2), room2))