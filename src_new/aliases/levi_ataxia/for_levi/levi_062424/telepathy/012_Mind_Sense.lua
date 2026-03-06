--[[mudlet
type: alias
name: Mind Sense
hierarchy:
- Levi_Ataxia
- Classes
- Monk
- Telepathy
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^ms$
command: ''
packageName: ''
]]--

sendAll("queue addclear free mind sense " ..target)