--[[mudlet
type: alias
name: OOC Tells
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Other stuff
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^ooc (\w+) (.+)$
command: ''
packageName: ''
]]--

send("tell "..matches[2].." (( "..matches[3]:title().." ))")