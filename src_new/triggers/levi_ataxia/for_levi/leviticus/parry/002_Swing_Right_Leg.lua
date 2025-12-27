--[[mudlet
type: trigger
name: Swing Right Leg
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Knight
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
- pattern: ^You swing .+ at \w+'s right leg with all your might\.$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^\w+ parries the attack with a deft manoeuvre\.$
  type: 1
]]--

ataxiaTemp.parriedLimb = "right leg"
cecho("Parrying " ..ataxiaTemp.parriedLimb)