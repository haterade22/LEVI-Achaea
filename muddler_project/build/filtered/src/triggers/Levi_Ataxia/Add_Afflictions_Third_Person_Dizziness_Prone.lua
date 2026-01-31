if isTargeted(matches[2]) then
	tAffs.dizziness = true
	tAffs.prone = true

	-- V3 integration: collapse branches (proves dizziness present) and track prone
	if onTargetStumbleV3 then onTargetStumbleV3() end
	if applyAffV3 then applyAffV3("prone") end

	selectString(line,1)
	setBold(true)
	fg("purple")
end