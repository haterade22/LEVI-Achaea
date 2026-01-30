local name = multimatches[1][2]
if isTargeted(multimatches[1][2]) then
	if anorexiaFailsafe then
		tAffs[lastFocus] = true
		ataxiaEcho("Backtracked anorexia being cured with last focus.")
		anorexiaFailsafe = nil
		lastFocus = nil
	end
  if passiveFailsafe then restorePassiveCure() end
	
	if multimatches[3][1] == name.." straightens, as if some great burden had been lifted from her shoulders."
		or multimatches[3][1] == name.." straightens, as if some great burden had been lifted from his shoulders." then
			erAff("guilt")
  elseif multimatches[3][1] == name.." ceases his violent trembling." or multimatches[3][1] == name.." ceases her violent trembling." then
    erAff("whisperingmadness")
	else
		targetAteWrapper("lobelia")
		if onHerbCureV3 then onHerbCureV3("lobelia") end
	end

	tBals.plant = false
  if tBals.timers.plant then killTimer(tBals.timers.plant) end
	if tAffs.mercury then
		tAffs.mercury = false
		tBals.timers.plant = tempTimer(1.9, [[tBals.plant = true; tBals.timers.plant = nil]])
	else
		tBals.timers.plant = tempTimer(1.3, [[tBals.plant = true; tBals.timers.plant = nil]])
	end
	targetIshere = true
end