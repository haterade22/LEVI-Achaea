--[[mudlet
type: alias
name: Reply ooc
hierarchy:
- Levi_Ataxia
- Ataxia
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^rooc (.+)$
command: ''
packageName: ''
]]--

send("reply (( "..matches[2]:title().." ))")