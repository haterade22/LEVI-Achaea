--[[mudlet
type: alias
name: Create a link between two rooms
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^(?:rlk|room link) ?(\d+)? (\w+)( one)?$
command: ''
packageName: ''
]]--

-- need the current room, but we're lost
if not mmp.currentroom or not mmp.roomexists(mmp.currentroom) then mmp.echo("Don't know where we are at the moment.") return end

-- make sure the dir is valid
local dir = mmp.anytolong(matches[3])
if not dir then mmp.echo(matches[3].." isn't a valid normal exit.") return end

-- if we don't give a room number, then we want to auto-locate an appropriate room nearby.
local otherroom
if matches[2] == "" then
  local w = matches[3]
  local ox, oy, oz, x,y,z = getRoomCoordinates(mmp.currentroom)
  local has = table.contains
  if has({"west", "left", "w", "l"}, w) then
    x = (x or ox) - 1; y = (y or oy); z = (z or oz)
  elseif has({"east", "right", "e", "r"}, w) then
    x = (x or ox) + 1; y = (y or oy); z = (z or oz)
  elseif has({"north", "top", "n", "t"}, w) then
    x = (x or ox); y = (y or oy) + 1; z = (z or oz)
  elseif has({"south", "bottom", "s", "b"}, w) then
    x = (x or ox); y = (y or oy) - 1; z = (z or oz)
  elseif has({"northwest", "topleft", "nw", "tl"}, w) then
    x = (x or ox) - 1; y = (y or oy) + 1; z = (z or oz)
  elseif has({"northeast", "topright", "ne", "tr"}, w) then
    x = (x or ox) + 1; y = (y or oy) + 1; z = (z or oz)
  elseif has({"southeast", "bottomright", "se", "br"}, w) then
    x = (x or ox) + 1; y = (y or oy) - 1; z = (z or oz)
  elseif has({"southwest", "bottomleft", "sw", "bl"}, w) then
    x = (x or ox) - 1; y = (y or oy) - 1; z = (z or oz)
  elseif has({"up", "u"}, w) then
    x = (x or ox); y = (y or oy); z = (z or oz) + 1
  elseif has({"down", "d"}, w) then
    x = (x or ox); y = (y or oy); z = (z or oz) - 1
  end

  local carea = getRoomArea(mmp.currentroom)
  if not carea then mmp.echo("Don't know what area are we in.") return end

  otherroom = select(2, next(getRoomsByPosition(carea,x,y,z)))

  if not otherroom then
    mmp.echo("There isn't a room to the "..w.." that I see - try with an exact room id.") return
  end

else
  if not mmp.roomexists(matches[2]) then -- check that an explicit other room ID is valid
    mmp.echo("A room with id "..matches[2].. " doesn't exist.") return
  else
    otherroom = tonumber(matches[2])
  end
end

if mmp.setExit(mmp.currentroom, otherroom, matches[3]) then
  if not matches[4] then mmp.setExit(otherroom, mmp.currentroom, mmp.ranytolong(matches[3])) end

  mmp.echo(string.format("Linked %s (%d) to %s (%d) via a %s%s exit.",
    (getRoomName(mmp.currentroom) ~= "" and getRoomName(mmp.currentroom) or "''"), mmp.currentroom, (getRoomName(otherroom) ~= "" and getRoomName(otherroom) or "''"), otherroom, (matches[4] and "one-way " or ''), matches[3]))
else
  mmp.echo("Couldn't create an exit.")
end
centerview(mmp.currentroom)