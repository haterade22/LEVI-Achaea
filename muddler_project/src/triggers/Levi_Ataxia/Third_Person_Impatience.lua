if isTargeted(matches[2]) then
	tAffs.impatience = true

	-- V3 integration: collapse branches (proves impatience present)
	if onTargetImpatienceV3 then onTargetImpatienceV3() end

	selectString(line, 1)
	fg("goldenrod")
	resetFormat()
	if ataxia_isClass("depthswalker") then
		if matches[1]:find("in boredom") then
			tAffs.hypochondria = true
			tAffs.nausea = true
			tAffs.addiction = true
			tAffs.lethargy = true
		end
	end
end