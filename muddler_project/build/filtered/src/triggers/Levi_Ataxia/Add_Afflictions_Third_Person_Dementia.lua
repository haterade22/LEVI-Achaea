if isTargeted(matches[2]) then
	tarAffed("dementia")

	-- V3 integration: collapse branches (proves dementia present)
	if onTargetDementiaV3 then onTargetDementiaV3() end
end