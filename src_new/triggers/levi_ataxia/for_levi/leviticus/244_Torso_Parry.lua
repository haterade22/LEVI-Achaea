--[[mudlet
type: trigger
name: Torso Parry
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- BM
- Parry
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^In a single motion, you draw Blazing Flames from its scabbard and loose a vicious rising slash at (\w+)'s torso\.$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^(\w+) parries the attack with a deft manoeuvre\.$
  type: 1
]]--

tparrying = "torso"
ataxia_Echo("Parry HIT!!!")