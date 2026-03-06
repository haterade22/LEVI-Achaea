--[[mudlet
type: alias
name: LDM Joker
hierarchy:
- Levi_Ataxia
- Artefacts
- LegendDeck
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^ldraw\s+(\w+)$
command: ''
packageName: ''
]]--

if ldm and ldm.useJoker then
    ldm.useJoker(matches[2])
end
