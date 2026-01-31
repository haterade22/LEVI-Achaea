--[[mudlet
type: trigger
name: Dizziness Prone
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
- pattern: ^(\w+) staggers and falls to the ground.$
  type: 1
]]--

if isTargeted(matches[2]) then
	tAffs.dizziness = true
	tAffs.prone = true

	-- V3 integration: collapse branches (proves dizziness present) and track prone
	if onTargetStumbleV3 then onTargetStumbleV3() end
	if applyAffV3 then applyAffV3("prone") end

	selectString(line,1)
	setBold(true)
	fg("purple")
end