--[[mudlet
type: alias
name: FREEZE DIR
hierarchy:
- Levi_Ataxia
- General
- Freezetag
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^fr (\d+)$
command: ''
packageName: ''
]]--

send("freeze "..target.." "..matches[2])