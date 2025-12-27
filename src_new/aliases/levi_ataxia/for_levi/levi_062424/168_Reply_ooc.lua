--[[mudlet
type: alias
name: Reply ooc
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
regex: ^rooc (.+)$
command: ''
packageName: ''
]]--

send("reply (( "..matches[2]:title().." ))")