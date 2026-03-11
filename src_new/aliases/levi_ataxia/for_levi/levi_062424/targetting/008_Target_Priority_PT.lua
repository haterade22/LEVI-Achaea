--[[mudlet
type: alias
name: Target Priority PT
hierarchy:
- Levi_Ataxia
- General
- Targeting
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^tpt$
command: ''
packageName: ''
]]--

if tprio and #tprio.list > 0 then tprio.pt() else ataxiaEcho("No targets in priority list.") end
