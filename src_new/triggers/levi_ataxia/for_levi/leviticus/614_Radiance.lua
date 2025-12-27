--[[mudlet
type: trigger
name: Radiance
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Warnings
- Instakills
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
- pattern: A shiver runs down your spine, and you feel an instinctive urge to run as far and fast as you can.
  type: 2
]]--

cecho("\n\n<red>[WARNING]:<white> You are being RADIANCED!!\n<red>[WARNING]:<white> You are being RADIANCED!!\n<red>[WARNING]:<white> You are being RADIANCED!!\n\n")
ataxia_setWarning("you're being radianced",  2.5)	