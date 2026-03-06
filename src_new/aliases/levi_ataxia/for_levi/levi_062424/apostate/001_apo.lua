--[[mudlet
type: alias
name: apo
hierarchy:
- Levi_Ataxia
- Classes
- Apostate
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^apo$
command: ''
packageName: ''
]]--

if ataxiaNDB_getClass(target) == "Occultist" or ataxiaNDB_getClass(target) == "Pariah" or ataxiaNDB_getClass(target) == "Priest" then
apostate_weari()
else
apostate_clumsy()
end