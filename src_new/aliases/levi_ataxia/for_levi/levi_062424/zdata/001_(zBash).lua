--[[mudlet
type: alias
name: (zBash)
hierarchy:
- Levi_Ataxia
- Systems
- zData
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^zbash(?: (\w+))?(?: (\w+))?$'
command: ''
packageName: ''
]]--

if matches[3] then
  zData.db.showData(matches[2], matches[3])
elseif matches[2] then
  zData.db.showData(matches[2])
else
  zData.db.showData()
end