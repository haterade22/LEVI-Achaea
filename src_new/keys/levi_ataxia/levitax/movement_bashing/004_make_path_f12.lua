--[[mudlet
type: key
name: make path f12
hierarchy:
- Levi_Ataxia
- Levitax
- Movement/Bashing
attributes:
  isActive: 'yes'
  isFolder: 'no'
keyCode: 16777275
keyModifier: 0
command: ''
packageName: ''
]]--

if not ataxiaBasherPaths then ataxiaBasherPaths = {}; ataxiaEcho("Initialised paths' table.") end
mapping_bpath = true
mapping_path = {}
table.insert(mapping_path, gmcp.Room.Info.num)
ataxiaEcho("Pather ready to go.")