local name = matches[2]
local class = (ataxiaNDB_getClass(name) or "Unknown")

if isTargeted(matches[2]) and (class == "Druid" or class == "Sentinel") then
  erAff("prone")
	ataxiaTemp.randomCure = 1
	-- V2 integration: Might cures prone + 1 random
	if removeAffV2 then removeAffV2("prone") end
	if removeAffV3 then removeAffV3("prone") end
	if reduceRandomAffCertaintyV2 then reduceRandomAffCertaintyV2() end
	if onPassiveCureV3 then onPassiveCureV3(1) end
	selectString(line,1)
	fg("NavajoWhite")
	resetFormat()
	targetIshere = true
end
