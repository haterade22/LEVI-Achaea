local name = matches[2]
local class = (ataxiaNDB_getClass(name) or "Unknown")

if isTargeted(matches[2]) and class == "Shaman" then
  erAff("selarnia")
	ataxiaTemp.randomCure = 1
	-- V2 integration: Purification cures selarnia + 1 random
	if removeAffV2 then removeAffV2("selarnia") end
	if reduceRandomAffCertaintyV2 then reduceRandomAffCertaintyV2() end
	selectString(line,1)
	fg("NavajoWhite")
	resetFormat()
	targetIshere = true
end
