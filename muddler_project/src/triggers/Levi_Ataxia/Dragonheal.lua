local name = matches[2]

if isTargeted(matches[2]) then
  erAff("recklessness"); erAff("weariness")
	ataxiaTemp.randomCure = 3
	-- V2 integration: Dragonheal cures recklessness, weariness + 3 random
	if removeAffV2 then
		removeAffV2("recklessness")
		removeAffV2("weariness")
	end
	if reduceRandomAffCertaintyV2 then
		reduceRandomAffCertaintyV2()
		reduceRandomAffCertaintyV2()
		reduceRandomAffCertaintyV2()
	end
	selectString(line,1)
	fg("NavajoWhite")
	resetFormat()
	targetIshere = true
end
