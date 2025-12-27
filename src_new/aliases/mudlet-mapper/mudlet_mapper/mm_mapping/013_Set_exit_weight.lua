--[[mudlet
type: alias
name: Set exit weight
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^rwe(?: (\d+))? (\d+) (.+)$'
command: ''
packageName: ''
]]--

local room = (matches[2] ~= "" and tonumber(matches[2]) or mmp.currentroom)

local weight, exit = tonumber(matches[3]), matches[4]

if not roomExists(room) then mmp.echo("Room "..room.." doesn't exist. It has to before we can set weights on exits.") return end

setExitWeight(room, exit, weight)

mmp.echo(string.format("Set the weight on the %d room going %s to %s. If it's a two-way exit, please set the reverse exit as well.", room, exit, weight))