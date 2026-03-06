--[[mudlet
type: alias
name: Eat
hierarchy:
- Levi_Ataxia
- Ataxia
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^eat (\w+)$
command: ''
packageName: ''
]]--

if ataxiaTemp.riftContents and ataxiaTemp.riftContents[matches[2]:lower()] then
  send("outrift "..matches[2]..ataxia.settings.separator.."eat "..matches[2],false)
else
  send("eat "..matches[2],false)
end