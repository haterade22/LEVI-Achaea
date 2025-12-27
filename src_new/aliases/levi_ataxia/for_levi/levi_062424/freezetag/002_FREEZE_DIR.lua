--[[mudlet
type: alias
name: FREEZE DIR
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- General
- FREEZETAG
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^fr (\d+)$
command: ''
packageName: ''
]]--

send("freeze "..target.." "..matches[2])