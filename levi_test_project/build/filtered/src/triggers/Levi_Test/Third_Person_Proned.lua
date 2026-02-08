if isTargeted(matches[2]) then
	tAffs.prone = true
	tAffs.shield = false
	if removeAffV3 then removeAffV3("shield") end
	selectString(line,1)
	setBold(true)
	fg("violet")
	resetFormat()
  tarAffed("prone")
  confirmAffV2("prone")
  applyAffV3("prone")
end

