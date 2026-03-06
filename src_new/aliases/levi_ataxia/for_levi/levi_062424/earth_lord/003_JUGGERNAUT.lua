--[[mudlet
type: alias
name: JUGGERNAUT
hierarchy:
- Levi_Ataxia
- Classes
- Earth Lord
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^j (\w+)$
command: ''
packageName: ''
]]--

wsys.pause()
send("clearqueue all;terran juggernaut "..target.." "..matches[2])