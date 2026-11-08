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
-- Was osend, which nothing defines: the unlock went out and the party call threw.
send("pt MIND UNLOCK: " ..target)
