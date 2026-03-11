--[[mudlet
type: alias
name: Target Priority Show
hierarchy:
- Levi_Ataxia
- General
- Targeting
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^tps$
command: ''
packageName: ''
]]--

if tprio then tprio.print() else ataxiaEcho("Target Priority system not loaded.") end
