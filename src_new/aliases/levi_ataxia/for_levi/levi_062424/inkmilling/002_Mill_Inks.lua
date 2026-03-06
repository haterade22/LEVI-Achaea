--[[mudlet
type: alias
name: Mill Inks
hierarchy:
- Levi_Ataxia
- Ataxia
- Crafting
- Inkmilling
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^mill (\d+) (gold|blue|red|purple|yellow|green)$
command: ''
packageName: ''
]]--

ataxiaTemp.inkColour = matches[3]
ataxiaTemp.inkAmount = tonumber(matches[2])
ataxiaTemp.inkMaking = true
inkmilling_createInks()