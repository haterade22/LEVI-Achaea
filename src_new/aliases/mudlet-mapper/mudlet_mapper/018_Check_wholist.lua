--[[mudlet
type: alias
name: Check wholist
hierarchy:
- mudlet-mapper
- Mudlet Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^who b$
command: ''
packageName: ''
]]--

enableTrigger("Parse wholist")
send("who b")
tempTimer(10, [[disableTrigger'Parse wholist']])