--[[mudlet
type: alias
name: Impale
hierarchy:
- Levi_Ataxia
- Classes
- Knight
- RUNIE
- SNB
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^ip$
command: ''
packageName: ''
]]--

send("queue addclear free stand;falcon slay " ..target.. " ;impale " ..target.. " ;club " ..target.. " ;fury on;assess " ..target)