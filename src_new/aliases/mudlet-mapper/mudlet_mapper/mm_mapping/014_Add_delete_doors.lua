--[[mudlet
type: alias
name: Add/delete doors
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^rd(?: (\d+))? (\w+)(?: (\w+))?$'
command: ''
packageName: ''
]]--

local room = (matches[2] ~= "" and tonumber(matches[2]) or mmp.currentroom)

local direction, status = matches[3], matches[4]

if not roomExists(room) then mmp.echo("Room "..room.." doesn't exist. It has to before we can make doors in it.") return end

local validdirs = {'e', 's', 'w', 'n', 'ne', 'se', 'sw', 'nw', 'in', 'out', 'up', 'down'}

if not table.contains(validdirs, direction) then
  mmp.echo("Can't make a door in the '"..direction.."' direction - available choices are:\n  "..table.concat(validdirs, ', '))
  return
end

local statusnum

if status == "" or status == "open" or status == "o" then
  statusnum = 1
elseif status == "closed" or status ==  "c" then
  statusnum = 2
elseif status == "locked" or status ==  "l" then
  statusnum = 3
elseif status == "clear" or status == "gone" then
  statusnum = 0
end

if not statusnum then mmp.echo("Unrecognized option - a door can be open, closed, locked or gone.") return end

setDoor(room, direction, statusnum)

if statusnum == 0 then
  mmp.echo("OK, door removed.")
else
  mmp.echo("OK, door added/adjusted.")
end