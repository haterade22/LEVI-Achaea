if isTargeted(matches[2]) and matches[1]:find("eats") then
tdeliverance = false
  predictBal("herb", 1.55)	
	selectString(line, 1)
	fg("NavajoWhite")
	resetFormat()

	tAffs.blindness = true
	tBals.plant = false
  if tBals.timers.plant then killTimer(tBals.timers.plant) end
	if tAffs.mercury then
		tAffs.mercury = false
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
	targetIshere = true
end
