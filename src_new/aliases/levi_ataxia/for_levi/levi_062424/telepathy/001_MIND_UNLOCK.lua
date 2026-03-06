--[[mudlet
type: alias
name: MIND UNLOCK
hierarchy:
- Levi_Ataxia
- Classes
- Monk
- Telepathy
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^mu$
command: ''
packageName: ''
]]--

sendAll("mind unlock " ..target)
osend("pt MIND UNLOCK: " ..target)
