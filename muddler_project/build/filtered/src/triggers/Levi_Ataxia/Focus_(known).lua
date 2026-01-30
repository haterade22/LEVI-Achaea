local name = multimatches[1][2]
if isTargeted(multimatches[1][2]) and tBals.focus then
onTargetFocusV3()
  if passiveFailsafe then restorePassiveCure() end
	if multimatches[3][1] == name .. " shakes his head and a look of clarity returns to his eyes."
		or multimatches[3][1] == name .. " shakes her head and a look of clarity returns to her eyes." then
			erAff("lovers")
			erAff("impatience")
			-- V2 integration: Focus cured lovers and impatience specifically
			if removeAffV2 then
				removeAffV2("lovers")
				removeAffV2("impatience")
			end
	else
		-- V2 integration: Focus cured a random mental affliction (mutually exclusive with old system)
		if ataxia.settings.useAffTrackingV2 then
			onTargetFocusV2(name)
		else
			tFocused()
		end
	end
	-- Track for adaptive serpent offense
	if serpent and serpent.trackCure then serpent.trackCure("focus") end
	tBals.focus = false
  
  if tBals.timers.focus then killTimer(tBals.timers.focus) end
	if haveAff("shadowmadness") then
		tBals.timers.focus = tempTimer(5, [[tBals.focus = true; tBals.timers.focus = nil]])
	else
		tBals.timers.focus = tempTimer(2, [[tBals.focus = true; tBals.timers.focus = nil]])
	end  
	targetIshere = true
end