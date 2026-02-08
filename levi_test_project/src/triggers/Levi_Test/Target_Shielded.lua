if type(target) == "string" and isTargeted(matches[2]) then
	selectString(line, 1)
	fg("orange")
	setBold(true)
	resetFormat()
	send("cq eqbal")
  if target == "Kshavatra" then
  tAffs.shield = false
  if removeAffV3 then removeAffV3("shield") end
  else
	tAffs.shield = true
	if applyAffV3 then applyAffV3("shield") end
  end
  
end