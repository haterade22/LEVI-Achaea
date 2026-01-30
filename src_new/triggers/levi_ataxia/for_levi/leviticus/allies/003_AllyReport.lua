--[[mudlet
type: trigger
name: AllyReport
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- ZulahGUI - Saonji Edit
- zGUI Redux
- Allies
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
- pattern: ^You feel an unusually strong lust for (\w+).$
  type: 1
- pattern: ^(\w+) is an ally.$
  type: 1
- pattern: ^(\w+) is an ally \(M\).$
  type: 1
- pattern: ^You feel an unusually strong lust for (\w+) \(M\).$
  type: 1
]]--

table.insert(zgui.allies, 1, matches[2])