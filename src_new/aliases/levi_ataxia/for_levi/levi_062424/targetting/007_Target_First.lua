--[[mudlet
type: alias
name: Target First
hierarchy:
- Levi_Ataxia
- General
- Targeting
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^tf$
command: ''
packageName: ''
]]--

if tprio and #tprio.list > 0 then tprio.first() end
