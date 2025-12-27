--[[mudlet
type: trigger
name: Can Jinx
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Jinx
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
- pattern: Your malign power may be unleashed in the form of a jinx against your victim.
  type: 3
]]--

ataxiaTemp.jinxCharge = ataxiaTemp.jinxCharge or 0
ataxiaTemp.jinxCharge = ataxiaTemp.jinxCharge + 1
ataxiaTemp.canJinx = true

if ataxiaBasher.enabled and not ataxiaBasher.manual then
	deleteFull()
end

