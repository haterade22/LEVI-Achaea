--[[mudlet
type: alias
name: Shaman config
hierarchy:
- Levi_Ataxia
- Ataxia
- Shaman System
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^shaman profile save (\w+)$
command: ''
packageName: ''
]]--

shaman.savecurrentprofile(matches[2])