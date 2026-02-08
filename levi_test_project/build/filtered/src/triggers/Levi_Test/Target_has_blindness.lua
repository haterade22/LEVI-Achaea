if isTargeted(matches[2]) and tBals.plant and matches[1]:find("eats") then
tdeliverance = false
  predictBal("herb", 1.55)	
	selectString(line, 1)
	fg("NavajoWhite")
	resetFormat()

	tAffs.blindness = true
	if applyAffV3 then applyAffV3("blindness") end
	tBals.plant = false
  if tBals.timers.plant then killTimer(tBals.timers.plant) end
	if tAffs.mercury then
		tAffs.mercury = false
		if removeAffV3 then removeAffV3("mercury") end
		tBals.timers.plant = tempTimer(1.9, [[tBals.plant = true; tBals.timers.plant = nil]])
	else
		tBals.timers.plant = tempTimer(1.3, [[tBals.plant = true; tBals.timers.plant = nil]])
	end
	targetIshere = true
elseif isTargeted(matches[2]) and matches[1]:find("is blind") then
	selectString(line, 1)
	fg("NavajoWhite")
	resetFormat()

	tAffs.blindness = true
	if applyAffV3 then applyAffV3("blindness") end
	targetIshere = true
end
