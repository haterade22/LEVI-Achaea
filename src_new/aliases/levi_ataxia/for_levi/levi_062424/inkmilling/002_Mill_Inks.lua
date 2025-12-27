--[[mudlet
type: alias
name: Mill Inks
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Other stuff
- Crafting/Tradeskill Related
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