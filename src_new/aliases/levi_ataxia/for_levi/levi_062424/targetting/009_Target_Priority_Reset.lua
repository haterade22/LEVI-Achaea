--[[mudlet
type: alias
name: Target Priority Reset
hierarchy:
- Levi_Ataxia
- General
- Targeting
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^tpr$
command: ''
packageName: ''
]]--

if tprio then tprio.reset() end
