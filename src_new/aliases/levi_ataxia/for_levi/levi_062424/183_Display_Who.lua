--[[mudlet
type: alias
name: Display Who
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Ataxia NDB
- Actions
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^whois (\w+)$
command: ''
packageName: ''
]]--

ataxiaNDB.player_Notes = ataxiaNDB.player_Notes or {}
ataxia_Echo("Getting information on <green>"..matches[2]:title().."...")

ataxiaNDB_Acquire(matches[2]:title(),false)
ataxiaNDB.checking = true
