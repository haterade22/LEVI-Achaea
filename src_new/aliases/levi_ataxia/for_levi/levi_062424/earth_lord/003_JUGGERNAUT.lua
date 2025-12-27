--[[mudlet
type: alias
name: JUGGERNAUT
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- EARTH LORD
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^j (\w+)$
command: ''
packageName: ''
]]--

wsys.pause()
send("clearqueue all;terran juggernaut "..target.." "..matches[2])