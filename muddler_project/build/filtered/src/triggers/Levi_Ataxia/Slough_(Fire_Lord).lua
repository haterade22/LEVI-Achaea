local name = matches[2]
if isTargeted(matches[2]) then
	-- Slough cures weariness + 1 random affliction
	erAff("weariness")
	if removeAffV2 then removeAffV2("weariness") end
	ataxiaTemp.randomCure = 1
	if reduceRandomAffCertaintyV2 then reduceRandomAffCertaintyV2() end
	if onPassiveCureV3 then onPassiveCureV3(1) end
	selectString(line,1)
	fg("NavajoWhite")
	resetFormat()
	targetIshere = true
end