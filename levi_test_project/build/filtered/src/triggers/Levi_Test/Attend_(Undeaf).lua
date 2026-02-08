if isTargeted(matches[2]) then
	selectString(line,1)
	fg("DimGrey")
	tAffs.deafness = false
	if removeAffV3 then removeAffV3("deafness") end
	deselect()
	
	ataxiaTemp.prayerList = ataxiaTemp.prayerList or {}
	table.insert(ataxiaTemp.prayerList, "attend")
end