--[[mudlet
type: alias
name: Butchering
hierarchy:
- Levi_Ataxia
- Ataxia
- Crafting
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^reagents$
command: ''
packageName: ''
]]--

ataxiaTemp.butchering = true
send("ii corpse"..ataxia.settings.separator.."more",false)