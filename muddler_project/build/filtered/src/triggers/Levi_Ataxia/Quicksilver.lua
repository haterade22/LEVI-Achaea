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