--[[mudlet
type: trigger
name: No Enemies
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
- pattern: You have no enemies.
  type: 0
- pattern: In a moment of forgiveness, you declare that you have no enemies.
  type: 0
]]--

disableTrigger("EnemyReport")
zgui.enemies = {}
zgui.showEnemies()