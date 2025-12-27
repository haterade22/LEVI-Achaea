--[[mudlet
type: alias
name: enemy city
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- AzzysEnemyManagement
- Enemy Management
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^cenemy (.*)$
command: ''
packageName: ''
]]--

enemycity = matches[2]:title()
enemystring = ": "
targetindex = 0
dembaddies.enemies = {}
expandAlias("qwc")
enableTrigger("copy qwc trigger")

tempTimer(3, [[SetAndReportEnemies()]])
tempTimer(4, [[disableTrigger("copy qwc trigger")]])
 