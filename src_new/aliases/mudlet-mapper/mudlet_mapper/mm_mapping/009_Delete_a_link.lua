--[[mudlet
type: alias
name: Delete a link
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^(?:urlk|room unlink) (\w+)$
command: ''
packageName: ''
]]--

-- need the current room, but we're lost
if not mmp.currentroom or not mmp.roomexists(mmp.currentroom) then mmp.echo("Don't know where we are at the moment.") return end

-- make sure the dir is valid
local dir = mmp.anytolong(matches[2])
if not dir then mmp.echo(matches[2].." isn't a valid normal exit.") return end

-- gone already?
if not getRoomExits(mmp.currentroom)[dir] then mmp.echo(dir.." link doesn't exist already.") end

-- locate the room on the other end, so we can unlink it from there as well if necessary
local otherroom
if getRoomExits(getRoomExits(mmp.currentroom)[dir])[mmp.ranytolong(dir)] then
  otherroom = getRoomExits(mmp.currentroom)[dir]
end

if mmp.setExit(mmp.currentroom, -1, dir) then
  if otherroom then
    if mmp.setExit(otherroom, -1, mmp.ranytolong(dir)) then
      mmp.echo(string.format("Deleted the %s exit from %s (%d).",
        dir, getRoomName(mmp.currentroom), mmp.currentroom))
     else mmp.echo("Couldn't delete the incoming exit.") end
  else
    mmp.echo(string.format("Deleted the one-way %s exit from %s (%d).",
      dir, getRoomName(mmp.currentroom), mmp.currentroom))
  end
else
  mmp.echo("Couldn't delete the outgoing exit.")
end
centerview(mmp.currentroom)