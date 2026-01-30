local name = multimatches[1][2]
local class = (ataxiaNDB_getClass(name) or "Unknown")

if isTargeted(name) and class == "Depthswalker" then
  erAff("recklessness")
	-- V2 integration: Accelerate cures recklessness + 1-2 random
	if removeAffV2 then removeAffV2("recklessness") end
	if multimatches[3][1] == name.." grows older before your eyes." and not haveAff("prone") then
    ataxiaTemp.randomCure = 2
		if reduceRandomAffCertaintyV2 then
			reduceRandomAffCertaintyV2()
			reduceRandomAffCertaintyV2()
		end
	else
		ataxiaTemp.randomCure = 1
		if reduceRandomAffCertaintyV2 then reduceRandomAffCertaintyV2() end
	end
	targetIshere = true
end

