--[[mudlet
type: alias
name: Add a special exit
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^(?:spe|exit special) (\w+) (.+)$
command: ''
packageName: ''
]]--

-- spe clear and spe list match on this
if matches[2] == "clear" or matches[2] == "list" then return end

-- need the current room, but we're lost
if not mmp.currentroom or not mmp.roomexists(mmp.currentroom) then mmp.echo("Don't know where we are at the moment.") return end

local otherroom = tonumber(matches[2]) or mmp.relativeroom(mmp.currentroom, matches[2])

-- need the another room, but it doesn't actually exist
if not otherroom or not mmp.roomexists(otherroom) then mmp.echo(matches[2].." doesn't exist.") return end

addSpecialExit(mmp.currentroom, tonumber(otherroom), matches[3])
addSpecialExit(mmp.currentroom, tonumber(otherroom), matches[3])
mmp.echo(string.format("Added special exit with command '%s' to %s (%d).", matches[3], getRoomName(otherroom), otherroom))
centerview(mmp.currentroom)