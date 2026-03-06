if isTargeted(matches[2]) then
	tarAffed("epilepsy")
	if applyAffV3 then applyAffV3("epilepsy") end

	-- V3 integration: collapse branches (proves epilepsy present)
	if onTargetSeizureV3 then onTargetSeizureV3() end
end