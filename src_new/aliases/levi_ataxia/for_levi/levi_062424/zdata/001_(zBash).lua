--[[mudlet
type: alias
name: (zBash)
hierarchy:
- Levi_Ataxia
- Systems
- ataxia.data
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^zbash(?: (\w+))?(?: (\w+))?$'
command: ''
packageName: ''
]]--

if matches[3] then
  ataxia.data.db.showData(matches[2], matches[3])
elseif matches[2] then
  ataxia.data.db.showData(matches[2])
else
  ataxia.data.db.showData()
end