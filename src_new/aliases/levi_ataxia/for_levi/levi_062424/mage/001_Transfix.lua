--[[mudlet
type: alias
name: Transfix
hierarchy:
- Levi_Ataxia
- Classes
- Mage
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^tr$
command: ''
packageName: ''
]]--

send("queue addclear freestand cast transfix " ..target)