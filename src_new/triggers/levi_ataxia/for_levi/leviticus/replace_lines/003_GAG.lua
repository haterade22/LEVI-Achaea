--[[mudlet
type: trigger
name: GAG
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Runie
- RuneWarden
- 2H
- Replace Lines
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
- pattern: ^You have no entourage\.$
  type: 1
- pattern: ^You are not fallen or kneeling\.$
  type: 1
- pattern: ^You rub some .+ on Apocalypse, a blackrock sword of black-hued steel\.$
  type: 1
- pattern: ^You are already fighting in perfect form\.$
  type: 1
- pattern: ^You may not execute such an ability again so soon, warrior\.$
  type: 1
]]--

deleteLine()