--[[mudlet
type: alias
name: Honours Person
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
regex: ^honou?rs? (\w+)$
command: ''
packageName: ''
]]--

honoursPerson = matches[2]:title()
enableTrigger("Get Player Information")
enableTrigger("Check Player City")
--enableTrigger("No city found")
ataxiaNDB_Acquire(matches[2]:title(),false)