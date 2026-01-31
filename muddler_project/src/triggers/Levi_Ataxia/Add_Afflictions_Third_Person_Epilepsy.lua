if isTargeted(matches[2]) then
	tarAffed("epilepsy")

	-- V3 integration: collapse branches (proves epilepsy present)
	if onTargetSeizureV3 then onTargetSeizureV3() end
end