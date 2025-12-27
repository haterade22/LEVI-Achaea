--[[mudlet
type: alias
name: Delete suffixed periods
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^delete suffixed periods$
command: ''
packageName: ''
]]--

mmp.echo("Deleting removing all periods at the end of room names...")
local c = 0

for area, areaname in pairs(mmp.areatabler) do
  local rooms = getAreaRooms(area) or {}
  for i = 0, #rooms do
    local name = getRoomName(rooms[i] or 0)
    if string.ends(name, ".") then
      name = string.sub(name, 1, (#name-1))
      setRoomName(rooms[i], name)
      mmp.echo(string.format("Patched up room #%s - '%s'", rooms[i], name))
      c = c + 1
    end
  end
end

mmp.echo(string.format("Fixed up %s room%s.", c, (c ~= 1 and 's' or '')))