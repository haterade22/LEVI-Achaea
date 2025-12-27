--[[mudlet
type: alias
name: Show char marks
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^show char marks$
command: ''
packageName: ''
]]--

local c = 0
local m = {}
local areas = getAreaTable()
local show_area = table.size(areas) > 1 and true or false

for area, id in pairs(areas) do
  for _, roomid in pairs(getAreaRooms(id)) do
    local c = getRoomChar(roomid)
    if c ~= '' and c ~= ' ' then
      m[c] = m[c] or {}
      m[c][#m[c]+1] = roomid
    end
  end
end

if not next(m) then mmp.echo("This map has no char marks on it. Do mc on and rcc <mark> in a room to add them!") return end

for letter, rooms in pairs(m) do
  table.sort(rooms)
  mmp.echo("Rooms with the <"..mmp.settings.echocolour..">"..letter.."<reset> character on them:")
  for i = 1, #rooms do
    if not show_area then
      cecho(string.format("  <sea_green>%-5s<reset> %s\n", rooms[i], getRoomName(rooms[i])))
    else
      cecho(string.format("  <sea_green>%-5s<reset> %-35s <dim_grey>(in<reset> %s<dim_grey>)\n", rooms[i], getRoomName(rooms[i]), mmp.areatabler[getRoomArea(rooms[i])]))
    end
  end
end