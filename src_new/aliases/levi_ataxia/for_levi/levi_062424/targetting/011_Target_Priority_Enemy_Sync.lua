--[[mudlet
type: alias
name: Target Priority Enemy Sync
hierarchy:
- Levi_Ataxia
- General
- Targeting
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^tpe$
command: ''
packageName: ''
]]--

if tprio then tprio.syncEnemies() else ataxiaEcho("Target Priority system not loaded.") end
