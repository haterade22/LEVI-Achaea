--[[mudlet
type: alias
name: Target Previous
hierarchy:
- Levi_Ataxia
- General
- Targeting
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^tb$
command: ''
packageName: ''
]]--

if tprio and #tprio.list > 0 then tprio.previous() end
