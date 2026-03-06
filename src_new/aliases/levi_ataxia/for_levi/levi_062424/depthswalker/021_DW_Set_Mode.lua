--[[mudlet
type: alias
name: DW Set Mode
hierarchy:
- Levi_Ataxia
- Classes
- Depthswalker
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^dwm (\w+)$
command: ''
packageName: ''
]]--

depthswalker.setMode(matches[2])
