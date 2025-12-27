--[[mudlet
type: alias
name: remove area from continent
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^acr ([\w'']+)(?: (.+))?$'
command: ''
packageName: ''
]]--

-- acr continent [optional area]

local continent = matches[2]:title()
local area
if not matches[3] then area = getRoomArea(mmp.currentroom)
elseif tonumber(matches[3]) then
  area = tonumber(matches[3])
  if getRoomAreaName(area) == -1 then area = nil end
else
  local areas = getAreaTable()

  for karea, id in pairs(areas) do if karea:lower():find(matches[3]:lower(), 1, true) then area = id break end end
end

if not area then mmp.echo(matches[3].." isn't a known area. Which one do you want to set?") return end

local res, error = mmp.removecontinent(area, continent)
if res then
  mmp.echo("Recorded that "..getRoomAreaName(area).." is not on the "..continent.." continent.")
else
  mmp.echo(error)
end