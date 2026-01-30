local name = matches[2]
local class = (ataxiaNDB_getClass(name) or "Unknown")

if isTargeted(matches[2]) and class == "Alchemist" then
  erAff("stupidity")
	ataxiaTemp.randomCure = 1
	-- V2 integration: Salt cures stupidity + 1 random
	if removeAffV2 then removeAffV2("stupidity") end
	if reduceRandomAffCertaintyV2 then reduceRandomAffCertaintyV2() end
	selectString(line,1)
	fg("NavajoWhite")
	resetFormat()
	targetIshere = true
end