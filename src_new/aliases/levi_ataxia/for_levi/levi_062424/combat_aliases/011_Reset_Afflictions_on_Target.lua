--[[mudlet
type: alias
name: Reset Afflictions on Target
hierarchy:
- Levi_Ataxia
- Combat
- Combat Aliases
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^raffs$
command: ''
packageName: ''
]]--

tAffs = {blindness = true, deafness = true, shield = false, rebounding = true, curseward = true}
if resetStatesV3 then resetStatesV3() end
ataxia_Echo("Reset target afflictions.")