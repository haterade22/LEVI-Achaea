--[[mudlet
type: alias
name: Target Next
hierarchy:
- Levi_Ataxia
- General
- Targeting
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^tn$
command: ''
packageName: ''
]]--

if tprio and #tprio.list > 0 then tprio.next() end
