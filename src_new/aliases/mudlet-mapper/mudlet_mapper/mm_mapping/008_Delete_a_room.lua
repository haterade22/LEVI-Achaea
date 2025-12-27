--[[mudlet
type: alias
name: Delete a room
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^(?:rld|room delete) ?(\w+)?$
command: ''
packageName: ''
]]--

-- want the current room, but we're lost
if not matches[2] and (not mmp.currentroom or not mmp.roomexists(mmp.currentroom)) then mmp.echo("Don't know where we are at the moment.") return end

-- want another room, but it doesn't exist
if matches[2] and tonumber(matches[2]) and not mmp.roomexists(matches[2]) then mmp.echo("v"..matches[2].." doesn't exist.") return end

-- or a relative one
if matches[2] and not tonumber(matches[2]) and not mmp.relativeroom(mmp.currentroom, matches[2]) then mmp.echo("There is no room "..matches[2].. " of us.") return end

local rid = (not matches[2] and mmp.currentroom or (tonumber(matches[2]) or mmp.relativeroom(mmp.currentroom, matches[2])))

local n = getRoomName(rid)
deleteRoom(rid)
mmp.echo(string.format("Deleted the %s (%d) room.\n", (n ~= "" and n or "''"), rid))
centerview(mmp.currentroom)