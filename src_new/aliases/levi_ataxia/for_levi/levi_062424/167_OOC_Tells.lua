--[[mudlet
type: alias
name: OOC Tells
hierarchy:
- Levi_Ataxia
- Ataxia
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^ooc (\w+) (.+)$
command: ''
packageName: ''
]]--

send("tell "..matches[2].." (( "..matches[3]:title().." ))")