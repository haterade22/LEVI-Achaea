if isTargeted(matches[2]) then
	tAffs.impatience = true
	if applyAffV3 then applyAffV3("impatience") end

	-- V3 integration: collapse branches (proves impatience present)
	if onTargetImpatienceV3 then onTargetImpatienceV3() end

	selectString(line, 1)
	fg("goldenrod")
	resetFormat()
	if ataxia_isClass("depthswalker") then
		if matches[1]:find("in boredom") then
			tAffs.hypochondria = true
			if applyAffV3 then applyAffV3("hypochondria") end
			tAffs.nausea = true
			if applyAffV3 then applyAffV3("nausea") end
			tAffs.addiction = true
			if applyAffV3 then applyAffV3("addiction") end
			tAffs.lethargy = true
			if applyAffV3 then applyAffV3("lethargy") end
		end
	end
end