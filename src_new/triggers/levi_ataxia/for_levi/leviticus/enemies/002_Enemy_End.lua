--[[mudlet
type: trigger
name: Enemy End
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- ZulahGUI - Saonji Edit
- zGUI Redux
- Enemies
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You have currently used (\d+) enemy slots of your (\d+) maximum.$
  type: 1
- pattern: ^You have currently used (\d+) enemy slot of your (\d+) maximum.$
  type: 1
]]--

zgui.showEnemies()
disableTrigger("EnemyReport")
--local enemyString = table.concat(zgui.enemies, ", ")
--if zgui.partyReport then send("pt My Enemies: "..enemyString) end