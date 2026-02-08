local name = matches[2]

if isTargeted(name) and tBals.tree then
tdeliverance = false
	if tAffs.paralysis then
		erAff("paralysis")
		if removeAffV3 then removeAffV3("paralysis") end
	end
  if passiveFailsafe then restorePassiveCure() end

	-- V3 integration: handle branching state tracker
	if onTargetTreeV3 then onTargetTreeV3() end

	-- V2 integration: track tree cure (mutually exclusive with old system)
	if ataxia.settings.useAffTrackingV2 then
		onTargetTreeV2(name)
	else
		tSingleRandom()
	end
  	selectString(line, 1)
	fg("green")
	resetFormat()
	tBals.tree = false
  if tBals.timers.tree then killTimer(tBals.timers.tree) end
	tBals.timers.tree = tempTimer(13, [[tBals.tree = true; tBals.timers.tree = nil]])
	targetIshere = true
	
  if tburns >= 1 then
    if tburns == 1 then
      tburns = 0
    elseif tburns == 2 then
      tburns = 1
    elseif tburns == 3 then
      tburns = 2
    elseif tburns == 4 then
      tburns = 3
    elseif tburns == 5 then
      tburns = 4
    end
  end
if treeTimer0 then return end
if treeTimer4 then return end
if treeTimer9 then return end
if treeTimer then return end
treeTimer0 = tempTimer(0,[[cecho("<orange>\n[TREE]: <yellow>tree down on <red>"..target.." <yellow>for <white>14 seconds...\n") treeTimer0 = nil]])
treeTimer4 = tempTimer(4,[[cecho("<orange>\n[TREE]: <yellow>tree down on <red>"..target.." <yellow>for <white>10 seconds...\n") treeTimer4 = nil]])
treeTimer9 = tempTimer(9,[[cecho("<orange>\n[TREE]: <yellow>tree down on <red>"..target.." <yellow>for <white>5 seconds...\n") treeTimer9 = nil]])
treeTimer = tempTimer(14, [[cecho("<orange>\n[TREE]: <red>"..target.." <yellow>can now use tree!!!\n") treeTimer = nil]])
 

end