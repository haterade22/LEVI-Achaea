--[[mudlet
type: trigger
name: Salves
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Groups
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
- pattern: ^(\w+) takes some salve from a vial
  type: 1
]]--

if isTargeted(matches[2]) then
tdeliverance = false
  if passiveFailsafe then restorePassiveCure() end
	-- Before the erase, which would leave the branches this proof rules out standing (007).
	if proveAffAbsentV3 then proveAffAbsentV3("slickness", "salve") end
	erAff("slickness")

	-- V3 integration: salve proves slickness absent. Runs after 391-395 on the same line; when one
	-- of them has charged the application (onSalveCureV3), this call does nothing (008).
	if onTargetApplySalveV3 then onTargetApplySalveV3() end

	targetIshere = true
end