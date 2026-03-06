--[[mudlet
type: alias
name: DRAGONCOLOR
hierarchy:
- Levi_Ataxia
- Artefacts
- Dragon Talisman
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^dracol (\w+)$
command: ''
packageName: ''
]]--

color = matches[2]
cecho("\nYOUR DRAGON COLOR IS: "..color)