local name = matches[2]
if isTargeted(matches[2]) then
	ataxiaTemp.randomCure = 1
	-- V2 integration: Eruption cures 1 random affliction
	if reduceRandomAffCertaintyV2 then reduceRandomAffCertaintyV2() end
	selectString(line,1)
	fg("NavajoWhite")
	resetFormat()
	targetIshere = true
end