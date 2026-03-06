--[[mudlet
type: alias
name: Horror
hierarchy:
- Levi_Ataxia
- Artefacts
- LegendDeck
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^lhor$
command: ''
packageName: ''
]]--

send("queue addclear free legenddeck draw horror for " ..target)