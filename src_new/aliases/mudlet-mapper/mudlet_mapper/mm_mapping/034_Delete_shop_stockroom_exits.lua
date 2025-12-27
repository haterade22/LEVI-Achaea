--[[mudlet
type: alias
name: Delete shop stockroom exits
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^delete known stockrooms$
command: ''
packageName: ''
]]--

mmp.echo("Deleting all known stockroom exits (rooms with $ and a down exit)")
local c = 0

for area, areaname in pairs(mmp.areatabler) do
  local rooms = getAreaRooms(area) or {}
  for i = 0, #rooms do
    if rooms[i] then
      local char = getRoomChar(rooms[i])
      if char == '$' then
        local exits = getRoomExits(rooms[i]) -- retrieve after $, more efficient

        if exits.down then
          mmp.setExit(rooms[i], -1, 'down')
          mmp.echo(string.format("Deleted the stockroom exit at %s (#%d in %s)", getRoomName(rooms[i]), rooms[i], mmp.areatabler[getRoomArea(rooms[i])]))
          c = c + 1
        end
      end
    end

  end
end

mmp.echo(string.format("Deleted %s known stockroom exit%s.", c, (c ~= 1 and 's' or '')))
centerview(mmp.currentroom)