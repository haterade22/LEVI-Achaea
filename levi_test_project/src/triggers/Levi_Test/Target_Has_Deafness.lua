if isTargeted(matches[2]) and matches[1]:find("eats") then
tdeliverance = false
  predictBal("herb", 1.55)
	selectString(line, 1)
	fg("NavajoWhite")
	resetFormat()
	tBals.plant = false
  if tBals.timers.plant then killTimer(tBals.timers.plant) end
	if tAffs.mercury then
		tAffs.mercury = false
		if removeAffV3 then removeAffV3("mercury") end
		tBals.timers.plant = tempTimer(1.9, [[tBals.plant = true; tBals.timers.plant = nil]])
	else
		tBals.timers.plant = tempTimer(1.3, [[tBals.plant = true; tBals.timers.plant = nil]])
	end

	-- Calamine cures deafness - clear it immediately (V1 and V2)
	tAffs.deafness = false
	if removeAffV3 then removeAffV3("deafness") end
	if tAffsV2 then tAffsV2.deafness = 0 end
	tempTimer(2.5, [[tAffs.deafness = true; if tAffsV2 then tAffsV2.deafness = 0 end; if applyAffV3 then applyAffV3("deafness") end]])
	targetIshere = true
elseif isTargeted(matches[2]) and matches[1]:find("concentration") then
	selectString(line, 1)
	fg("NavajoWhite")
	resetFormat()

	tempTimer(5, [[tAffs.deafness = true; if applyAffV3 then applyAffV3("deafness") end]])
	targetIshere = true
end