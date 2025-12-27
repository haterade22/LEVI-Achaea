--[[mudlet
type: alias
name: Reset Afflictions on Target
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Combat Aliases
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^raffs$
command: ''
packageName: ''
]]--

tAffs = {blindness = true, deafness = true, shield = false, rebounding = true, curseward = true}
ataxia_Echo("Reset target afflictions.")