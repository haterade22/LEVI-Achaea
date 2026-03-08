if isTargeted(matches[2]) then
	tarAffed("dizziness")
	tarAffed("prone")

	-- V3 integration: collapse branches (proves dizziness present)
	if onTargetStumbleV3 then onTargetStumbleV3() end

	selectString(line,1)
	setBold(true)
	fg("purple")
end