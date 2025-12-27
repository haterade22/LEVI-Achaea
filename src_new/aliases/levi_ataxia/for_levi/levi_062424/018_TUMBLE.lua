--[[mudlet
type: alias
name: TUMBLE
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- General
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^tu (\w+)$
command: ''
packageName: ''
]]--

send("clearqueue all;tumble " ..matches[2])