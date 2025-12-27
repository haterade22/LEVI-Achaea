--[[mudlet
type: alias
name: MOUNTKICK
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
regex: ^mk (\w+)$
command: ''
packageName: ''
]]--

send("clearqueue all;mountkick "..target.." " ..matches[2])