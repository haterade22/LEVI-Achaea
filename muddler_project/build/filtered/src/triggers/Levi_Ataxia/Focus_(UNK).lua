if isTargeted(matches[2]) and tBals.focus then
	-- V3 integration: handle branching state tracker
	if onTargetFocusV3 then onTargetFocusV3() end

	-- Focus used → target doesn't have impatience (focus would cure it first if present)
	erAff("impatience")

	tFocused()
end
	tBals.focus = false
  
  if tBals.timers.focus then killTimer(tBals.timers.focus) end
	if haveAff("shadowmadness") then
		tBals.timers.focus = tempTimer(5, [[tBals.focus = true; tBals.timers.focus = nil]])
	else
		tBals.timers.focus = tempTimer(2, [[tBals.focus = true; tBals.timers.focus = nil]])
	end  
	targetIshere = true
