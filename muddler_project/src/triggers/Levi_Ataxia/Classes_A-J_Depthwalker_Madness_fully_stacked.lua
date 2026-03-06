if isTargeted(matches[2]) then
	selectString(line,1)
	fg("goldenrod")
	setBold(true)
	resetFormat()
	tarAffed("shadowmadness", "vertigo", "hallucinations")
	if applyAffV3 then applyAffV3("shadowmadness"); applyAffV3("vertigo"); applyAffV3("hallucinations") end
end