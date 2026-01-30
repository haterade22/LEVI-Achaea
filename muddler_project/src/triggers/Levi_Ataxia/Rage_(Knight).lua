local name = multimatches[1][2]
if isTargeted(name) then
	if multimatches[3][1] == name .. " gives a sigh of relief." then
		erAff("retribution")
		-- V2 integration: Rage cured retribution
		if removeAffV2 then removeAffV2("retribution") end
	elseif multimatches[3][1] == name .. " shakes his head and a look of clarity returns to his eyes."
		or multimatches[3][1] == name .. " shakes her head and a look of clarity returns to her eyes." then
			erAff("lovers")
			-- V2 integration: Rage cured lovers
			if removeAffV2 then removeAffV2("lovers") end
	else
		taRaged()
		-- V2 integration: Rage cured paralysis (taRaged removes it)
		if removeAffV2 then removeAffV2("paralysis") end
	end
	targetIshere = true
end