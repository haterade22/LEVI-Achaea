if isTargeted(matches[2]) then
	tAffs.prone = true
	tAffs.shield = false
	selectString(line,1)
	setBold(true)
	fg("violet")
	resetFormat()
end

