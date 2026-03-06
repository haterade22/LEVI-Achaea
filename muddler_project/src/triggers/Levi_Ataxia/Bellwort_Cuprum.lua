local name = multimatches[1][2]
if isTargeted(multimatches[1][2]) then
tdeliverance = false
	if anorexiaFailsafe then
		tAffs[lastFocus] = true
		ataxiaEcho("Backtracked anorexia being cured with last focus.")
		anorexiaFailsafe = nil
		lastFocus = nil
	end
  if passiveFailsafe then restorePassiveCure() end
	
	if multimatches[3][1] == name .. " gives a sigh of relief." then
		erAff("retribution")
		erAff("earworm")
		-- V3: Definite cure (we know exactly what was cured)
		if removeAffV3 then removeAffV3("retribution") end
		if removeAffV3 then removeAffV3("earworm") end
	elseif multimatches[3][1] == name .. " shakes his head and a look of clarity returns to his eyes."
		or multimatches[3][1] == name .. " shakes her head and a look of clarity returns to her eyes." then
			erAff("lovers")
			-- V3: Definite cure (we know exactly what was cured)
			if removeAffV3 then removeAffV3("lovers") end
	else
		targetAteWrapper("bellwort")
		if onHerbCureV3 then onHerbCureV3("bellwort") end
	end
	tBals.plant = false
  if tBals.timers.plant then killTimer(tBals.timers.plant) end
	if tAffs.mercury then
		tAffs.mercury = false
		if removeAffV3 then removeAffV3("mercury") end
		tBals.timers.plant = tempTimer(1.9, [[tBals.plant = true; tBals.timers.plant = nil]])
	else
		tBals.timers.plant = tempTimer(1.3, [[tBals.plant = true; tBals.timers.plant = nil]])
	end
	targetIshere = true
end