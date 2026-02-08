local name = matches[2]

if isTargeted(matches[2]) then
  erAff("recklessness"); erAff("weariness")
	ataxiaTemp.randomCure = 3
	-- V2 integration: Dragonheal cures recklessness, weariness + 3 random
	if removeAffV2 then
		removeAffV2("recklessness")
		removeAffV2("weariness")
	end
	if removeAffV3 then removeAffV3("recklessness"); removeAffV3("weariness") end
	if reduceRandomAffCertaintyV2 then
		reduceRandomAffCertaintyV2()
		reduceRandomAffCertaintyV2()
		reduceRandomAffCertaintyV2()
	end
	if onPassiveCureV3 then onPassiveCureV3(3) end
	selectString(line,1)
	fg("NavajoWhite")
	resetFormat()
	targetIshere = true
end
