--[[mudlet
type: alias
name: MIND PARALYZE
hierarchy:
- Levi_Ataxia
- Classes
- Monk
- Telepathy
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^mp$
command: ''
packageName: ''
]]--

sendAll("queue addclear free mind paralyze " ..target)