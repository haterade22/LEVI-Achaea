--[[mudlet
type: alias
name: TUMBLE
hierarchy:
- Levi_Ataxia
- General
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^tu (\w+)$
command: ''
packageName: ''
]]--

send("clearqueue all;tumble " ..matches[2])