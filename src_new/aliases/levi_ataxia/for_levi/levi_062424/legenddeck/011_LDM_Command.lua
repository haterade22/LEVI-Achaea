--[[mudlet
type: alias
name: LDM Command
hierarchy:
- Levi_Ataxia
- Artefacts
- LegendDeck
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^ldm(?:| (.+))$
command: ''
packageName: ''
]]--

if ldm and ldm.command then
    ldm.command(matches[2] or "")
end
