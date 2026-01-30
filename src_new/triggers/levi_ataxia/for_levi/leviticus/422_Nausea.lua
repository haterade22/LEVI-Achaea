--[[mudlet
type: trigger
name: Nausea
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
- pattern: ^(\w+) doubles over\, vomiting violently\.$
  type: 1
- pattern: (?:\w+)'s poem of gluttony and decay makes (\w+) green in the cheeks\.$
  type: 1
- pattern: ^(\w+) attempts to defend against your attack but you bat \w+ weak attempt aside.
  type: 1
]]--

if isTargeted(matches[2]) then
	tarAffed("nausea")

	-- V3 integration: collapse branches (proves nausea present)
	if onTargetVomitV3 then onTargetVomitV3() end
end