if isTargeted(matches[2]) then
	tAffs.prone = true
	erAff("shield")
	selectString(line,1)
	setBold(true)
	fg("violet")
	resetFormat()
  tarAffed("prone")
  confirmAffV2("prone")
  tarAffed("prone")
end

