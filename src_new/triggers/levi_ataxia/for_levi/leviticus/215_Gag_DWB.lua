--[[mudlet
type: trigger
name: Gag DWB
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Runie
- DWB
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
- pattern: ^You cease wielding (.+) in your (\w+) hand\.$
  type: 1
- pattern: ^You begin to wield (.+) in your (\w+) hand\.$
  type: 1
- pattern: ^You begin to wield a (.+) in your (\w+) hand\.$
  type: 1
- pattern: You sense confusion in your falcon.
  type: 3
]]--

deleteFull()