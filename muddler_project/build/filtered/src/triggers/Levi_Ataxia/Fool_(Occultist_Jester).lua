local name = matches[2]

local class = (ataxiaNDB_getClass(name) or "Unknown")

if isTargeted(matches[2]) then
  erAff("paralysis")
  -- V2 integration: Fool cures paralysis + 3 random
  if removeAffV2 then removeAffV2("paralysis") end
	if class == "Jester" or class == "Occultist" then
		ataxiaTemp.randomCure = 3
		if reduceRandomAffCertaintyV2 then
			reduceRandomAffCertaintyV2()
			reduceRandomAffCertaintyV2()
			reduceRandomAffCertaintyV2()
		end
		selectString(line,1)
		fg("goldenrod")
		resetFormat()
		targetIshere = true
	end
end