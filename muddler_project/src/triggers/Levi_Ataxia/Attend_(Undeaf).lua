if isTargeted(matches[2]) then
	selectString(line,1)
	fg("DimGrey")
	erAff("deafness")
	deselect()
	
	ataxiaTemp.prayerList = ataxiaTemp.prayerList or {}
	table.insert(ataxiaTemp.prayerList, "attend")
end