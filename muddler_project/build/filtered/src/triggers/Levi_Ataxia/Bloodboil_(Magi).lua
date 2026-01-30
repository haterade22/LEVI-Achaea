local name = matches[2]
local class = (ataxiaNDB_getClass(name) or "Unknown")

if isTargeted(matches[2]) and class == "Magi" then
  erAff("haemophilia")
	ataxiaTemp.randomCure = 1
	-- V2 integration: Bloodboil cures haemophilia + 1 random
	if removeAffV2 then removeAffV2("haemophilia") end
	if reduceRandomAffCertaintyV2 then reduceRandomAffCertaintyV2() end
	selectString(line,1)
	fg("NavajoWhite")
	resetFormat()
	targetIshere = true
end
