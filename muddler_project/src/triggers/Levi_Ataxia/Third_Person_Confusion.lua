if isTargeted(matches[2]) then
	tarAffed("confusion")

	-- V3 integration: collapse branches (proves confusion present)
	if onTargetConfusionV3 then onTargetConfusionV3() end
end