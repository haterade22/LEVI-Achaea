if isTargeted(matches[2]) then
	tAffs.shield = false
	if removeAffV3 then removeAffV3("shield") end
	selectString(line,1)
	setBold(true)
	fg("NavajoWhite")
	resetFormat()
end

