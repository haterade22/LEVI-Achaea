local name = matches[2]
local class = (ataxiaNDB_getClass(name) or "Unknown")

if isTargeted(matches[2]) and class == "Blademaster" then
  erAff("paralysis")
	ataxiaTemp.randomCure = 1
	-- V2 integration: Alleviate cures paralysis + 1 random
	if removeAffV2 then removeAffV2("paralysis") end
	if removeAffV3 then removeAffV3("paralysis") end
	if reduceRandomAffCertaintyV2 then reduceRandomAffCertaintyV2() end
	if onPassiveCureV3 then onPassiveCureV3(1) end
	selectString(line,1)
	fg("NavajoWhite")
	resetFormat()
	targetIshere = true
end
