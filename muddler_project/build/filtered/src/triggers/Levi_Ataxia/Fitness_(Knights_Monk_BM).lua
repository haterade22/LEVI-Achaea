if isTargeted(matches[2]) then
	erAff("asthma")
	erAff("weariness")
	-- V2 integration: Fitness cures asthma and weariness specifically
	if removeAffV2 then
		removeAffV2("asthma")
		removeAffV2("weariness")
	end
	fg("DarkSlateGrey")
end
