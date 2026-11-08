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
	-- V3: an apply proves no slickness. First, while the branches still say who held it: every erase
	-- below strips it from each branch. Not onTargetApplySalveV3, which reads and starts the SALVE
	-- clock: a berry or a droplet is not on salve balance, and the game prints them inside each
	-- other's 0.8 s (kb/raw/logs/ours/2026-11-03_081532_Tabethys.log:1435/1455, legs then sileris in
	-- 0.143 s; kb/raw/logs/ours/2026-10-27_112717_Tabethys.log:1328/1351, quicksilver then skin in 0.168 s).
	if proveAffAbsentV3 then proveAffAbsentV3("slickness") end
	-- V1: bloodroot disambiguation (must be before erAff clears)
	if pendingBloodrootV1 then
		ataxiaEcho("Apply confirms bloodroot cured slickness")
		erAff("slickness")
		pendingBloodrootV1 = nil
		if bloodrootApplyTimerV1 then killTimer(bloodrootApplyTimerV1); bloodrootApplyTimerV1 = nil end
	end
	-- V2: bloodroot disambiguation + clear affs
	if onBloodrootApplyConfirmV2 then onBloodrootApplyConfirmV2() end
	if removeAffV2 then
		removeAffV2("slickness")
		removeAffV2("paralysis")
	end
	-- V1: clear remaining (erAff handles V3 internally)
	erAff("slickness")
	erAff("paralysis")
	-- Note: fangbarrier comes later with "metallic shell" message
	targetIshere = true
end