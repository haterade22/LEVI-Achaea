--[[mudlet
type: trigger
name: Quicksilver
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Herbs
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
- pattern: ^(\w+) applies a (sileris berry|quicksilver droplet) to \w+\.$
  type: 1
]]--

if isTargeted(matches[2]) then
tdeliverance = false
	-- V1: bloodroot disambiguation (must be before erAff clears)
	if pendingBloodrootV1 then
		ataxiaEcho("Apply confirms bloodroot cured slickness")
		erAff("slickness")
		if removeAffV3 then removeAffV3("slickness") end
		pendingBloodrootV1 = nil
		if bloodrootApplyTimerV1 then killTimer(bloodrootApplyTimerV1); bloodrootApplyTimerV1 = nil end
	end
	-- V2: bloodroot disambiguation + clear affs
	if onBloodrootApplyConfirmV2 then onBloodrootApplyConfirmV2() end
	if removeAffV2 then
		removeAffV2("slickness")
		removeAffV2("paralysis")
	end
	-- V3: collapse branches (proves no slickness) + remove paralysis
	if onTargetApplySalveV3 then onTargetApplySalveV3() end
	if removeAffV3 then removeAffV3("paralysis") end
	-- V1: clear remaining
	erAff("slickness")
	erAff("paralysis")
	-- Note: fangbarrier comes later with "metallic shell" message
	targetIshere = true
end