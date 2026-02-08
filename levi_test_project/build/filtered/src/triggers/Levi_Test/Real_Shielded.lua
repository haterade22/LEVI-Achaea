if type(target) == "string" and isTargeted(matches[2]) then
	selectString(line, 1)
	fg("orange")
	setBold(true)
	resetFormat()
	send("cq eqbal")

	tAffs.shield = true
	if applyAffV3 then applyAffV3("shield") end
  
end