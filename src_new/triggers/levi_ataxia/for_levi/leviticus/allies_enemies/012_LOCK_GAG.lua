--[[mudlet
type: trigger
name: LOCK GAG
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Allies/Enemies
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
- pattern: You must cease your current lock attempt before trying another.
  type: 3
- pattern: ^You focus your mind, and begin to concentrate on forming a mind lock with (\w+).$
  type: 1
- pattern: ^You continue to delve deeper and deeper into the mind of (\w+).$
  type: 1
- pattern: You do not possess a mindlock.
  type: 3
]]--

mindlocked = false
deleteFull()
