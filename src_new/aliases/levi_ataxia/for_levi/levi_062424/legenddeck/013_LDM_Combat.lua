--[[mudlet
type: alias
name: LDM Combat
hierarchy:
- Levi_Ataxia
- Artefacts
- LegendDeck
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^ldc$
command: ''
packageName: ''
]]--

if ldm and ldm.printCombat then
    ldm.printCombat()
end
