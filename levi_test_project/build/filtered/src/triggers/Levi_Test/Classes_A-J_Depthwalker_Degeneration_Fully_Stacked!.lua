if isTargeted(matches[2]) then
	selectString(line,1)
	fg("black")
	bg("purple")
	setBold(true)
	resetFormat()
	tarAffed("weariness", "clumsiness", "paralysis")
	if applyAffV3 then applyAffV3("weariness"); applyAffV3("clumsiness"); applyAffV3("paralysis") end
end