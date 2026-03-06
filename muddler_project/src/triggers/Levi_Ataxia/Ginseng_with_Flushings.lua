if isTargeted(multimatches[1][2]) then
tdeliverance = false
  predictBal("herb", 1.55)	
	if anorexiaFailsafe then
		tAffs[lastFocus] = true
		ataxiaEcho("Backtracked anorexia being cured with last focus.")
		anorexiaFailsafe = nil
		lastFocus = nil
	end
  if passiveFailsafe then restorePassiveCure() end
	targetAteWrapper("ginseng")
	if onHerbCureV3 then onHerbCureV3("ginseng") end
	flushingsProc()

	selectString(line, 1)
	fg("NavajoWhite")
	resetFormat()

	tBals.plant = false
  if tBals.timers.plant then killTimer(tBals.timers.plant) end
	if tAffs.mercury then
		tAffs.mercury = false
		if removeAffV3 then removeAffV3("mercury") end
		tBals.timers.plant = tempTimer(1.9, [[tBals.plant = true; tBals.timers.plant = nil]])
	else
		tBals.timers.plant = tempTimer(1.3, [[tBals.plant = true; tBals.timers.plant = nil]])
	end
	if strikingHigh and not strikeHighTimer then
		strikingHigh = nil
		strikeHighTimer = tempTimer(1.15, [[
			if ataxia.vitals.class == 4 and not haveAff("rebounding") then
				send("shieldstrike "..target.." high")
			end 	
			strikeHighTimer = nil
		]])
	end	
	
	targetIshere = true
end

selectString(line, 1)
fg("green")
resetFormat()