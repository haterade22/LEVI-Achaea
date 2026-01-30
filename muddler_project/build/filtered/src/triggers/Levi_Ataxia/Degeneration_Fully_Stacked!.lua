if isTargeted(matches[2]) then
	selectString(line,1)
	fg("black")
	bg("purple")
	setBold(true)
	resetFormat()
	tarAffed("weariness", "clumsiness", "paralysis")
end