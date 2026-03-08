if type(target) == "string" and isTargeted(matches[2]) then
	selectString(line, 1)
	fg("orange")
	setBold(true)
	resetFormat()
	send("cq eqbal")
  if target == "Kshavatra" then
  erAff("shield")
  else
	tarAffed("shield")
  end
  
end