--[[mudlet
type: alias
name: Staffcast
hierarchy:
- Levi_Ataxia
- Classes
- Mage
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^stc$
command: ''
packageName: ''
]]--

send("queue addclear freestand staffcast horripilation at " ..target)