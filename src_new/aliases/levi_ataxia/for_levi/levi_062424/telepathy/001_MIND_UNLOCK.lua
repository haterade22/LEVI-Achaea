--[[mudlet
type: alias
name: MIND UNLOCK
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- Monks
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
