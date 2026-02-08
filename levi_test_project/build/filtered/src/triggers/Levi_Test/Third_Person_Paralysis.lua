if isTargeted(matches[2]) then
	tarAffedConfirmed("paralysis")
	if applyAffV3 then applyAffV3("paralysis") end

	-- V3 integration: collapse branches (proves paralysis present)
	if onTargetParalysisBlockV3 then onTargetParalysisBlockV3() end
end