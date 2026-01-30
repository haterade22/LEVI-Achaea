if isTargeted(matches[2]) then
	tarAffed("dizziness")

	-- V3 integration: collapse branches (proves dizziness present)
	if onTargetStumbleV3 then onTargetStumbleV3() end
end