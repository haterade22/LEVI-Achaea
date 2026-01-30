if isTargeted(matches[2]) then
		selectString(line, 1)
		fg("black")
		bg("orange")
		resetFormat()
		tAffs.dehydrate = false
		tAffs.burns = 0
		
		if dehydrateTimer then killTimer(dehydrateTimer) end
end