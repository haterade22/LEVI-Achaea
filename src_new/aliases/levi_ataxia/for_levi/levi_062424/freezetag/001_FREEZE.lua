--[[mudlet
type: alias
name: FREEZE
hierarchy:
- Levi_Ataxia
- General
- Freezetag
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^fr$
command: ''
packageName: ''
]]--

send("clearqueue all;freeze "..target)