local name = matches[2]
if isTargeted(matches[2]) then
  erAff("weariness")
	ataxiaTemp.randomCure = 1
	-- V2 integration: Purify cures weariness + 1 random
	if removeAffV2 then removeAffV2("weariness") end
	if removeAffV3 then removeAffV3("weariness") end
	if reduceRandomAffCertaintyV2 then reduceRandomAffCertaintyV2() end
	if onPassiveCureV3 then onPassiveCureV3(1) end
	selectString(line,1)
	fg("NavajoWhite")
	resetFormat()
	targetIshere = true
end