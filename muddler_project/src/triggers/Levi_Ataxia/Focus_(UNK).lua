local name = matches[2]
if isTargeted(matches[2]) and tBals.focus then
	-- V3 integration: handle branching state tracker
	if onTargetFocusV3 then onTargetFocusV3() end

	-- V2 integration: Focus cures a random mental affliction (mutually exclusive with old system)
	if ataxia.settings.useAffTrackingV2 then
		onTargetFocusV2(name)
	else
		tFocused()
	end
end
	tBals.focus = false
  
  if tBals.timers.focus then killTimer(tBals.timers.focus) end
	if haveAff("shadowmadness") then
		tBals.timers.focus = tempTimer(5, [[tBals.focus = true; tBals.timers.focus = nil]])
	else
		tBals.timers.focus = tempTimer(2, [[tBals.focus = true; tBals.timers.focus = nil]])
	end  
	targetIshere = true
