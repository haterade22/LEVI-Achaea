--[[mudlet
type: trigger
name: Deconstruct False
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Psion
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
- pattern: ^You point imperiously at \w+, but only succeed at looking rather foolish\.$
  type: 1
]]--

tAffs.criticalspirit = false
if removeAffV3 then removeAffV3("criticalspirit") end
tAffs.criticalmind = false
if removeAffV3 then removeAffV3("criticalmind") end
tAffs.criticalbody = false
if removeAffV3 then removeAffV3("criticalbody") end
pdeconstruct = false