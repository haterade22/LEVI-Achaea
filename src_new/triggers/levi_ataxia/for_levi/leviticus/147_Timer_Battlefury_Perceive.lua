--[[mudlet
type: trigger
name: Timer Battlefury Perceive
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- INFERNAL
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
- pattern: ^Nothing can be seen here by that name\.$
  type: 1
- pattern: ^You cannot see that being here\.$
  type: 1
- pattern: ^I do not recognise anything called that here\.$
  type: 1
- pattern: ^You detect nothing here by that name\.$
  type: 1
]]--

disableTimer("Battlefury Perceive")