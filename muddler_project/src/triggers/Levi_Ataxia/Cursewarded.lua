if isTargeted(matches[2]) then
	selectString(line, 1)
	fg("black")
	bg("yellow")
	resetFormat()
	targetIshere = true
	tAffs.curseward = true
	if applyAffV3 then applyAffV3("curseward") end
end