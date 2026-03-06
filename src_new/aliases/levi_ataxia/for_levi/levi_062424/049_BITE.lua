--[[mudlet
type: alias
name: BITE
hierarchy:
- Levi_Ataxia
- Classes
- Dragon
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bit$
command: ''
packageName: ''
]]--

send("queue addclear freestand bite "..target)