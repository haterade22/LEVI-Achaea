--[[mudlet
type: alias
name: Toggle map sizes
hierarchy:
- mudlet-mapper
- Mudlet Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^(small|big|biggest)map(?: (\d+))?$'
command: ''
packageName: ''
]]--

local size = matches[2]

if size == "biggest" then
  mapper = Geyser.Mapper:new({
    name = "mapper",
    x = 0, y = 0,
    width = "100%", height = "97%"
  })
  mmp.echo("Map size set to pretty damn big.")

elseif size == "small" then
  mapper = Geyser.Mapper:new({
    x = "70%", y = 0,
    width = "28%", height = "50%"
  })
  mmp.echo("Map size set to comfortable.")

elseif size == "big" then
  local window_width, window_height = getMainWindowSize()
  local used_width = getMainConsoleWidth()

  local available_space = window_width - used_width

  if matches[3] then available_space = available_space - tonumber(matches[3]) end

  mapper = Geyser.Mapper:new({
    x = available_space*-1, y = 0,
    width = available_space, height = "100%"
  })

  mmp.echo("Set the map size to big - it'll cover all of the space on the right that game text isn't using. You'll want to call this alias again if you resize the window to update.")
end