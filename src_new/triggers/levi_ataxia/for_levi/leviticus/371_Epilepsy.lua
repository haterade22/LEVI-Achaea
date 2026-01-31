--[[mudlet
type: trigger
name: Epilepsy
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Third Person
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
- pattern: ^(\w+) begins to shake uncontrollably.$
  type: 1
- pattern: ^\w+ sings an irritating, mind-numbing ditty at (\w+)\.$
  type: 1
- pattern: ^(\w+) begins to jerk and shake violently, foaming at the mouth\.$
  type: 1
]]--

if isTargeted(matches[2]) then
	tarAffed("epilepsy")

	-- V3 integration: collapse branches (proves epilepsy present)
	if onTargetSeizureV3 then onTargetSeizureV3() end
end