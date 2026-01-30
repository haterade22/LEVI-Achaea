--[[mudlet
type: trigger
name: Morningstar Parry Left Arm
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Runie
- DWB
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
- pattern: ^You whip .+ toward the left arm of \w+\.$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^\w+ parries the attack with a deft manoeuvre\.$
  type: 1
]]--

tparrying = "left arm"
ataxiaTemp.parriedLimb = "left arm"

send("pt " ..target.. ": PARRYING " ..tparrying)