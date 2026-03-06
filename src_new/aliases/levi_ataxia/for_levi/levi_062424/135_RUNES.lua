--[[mudlet
type: alias
name: RUNES
hierarchy:
- Levi_Ataxia
- Classes
- Knight
- RUNIE
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^runes (\w+)$
command: ''
packageName: ''
]]--

send("queue addclear free sketch jera on "..matches[2])
send("queue add free sketch algiz on "..matches[2])
send("queue add free sketch berkana on "..matches[2])