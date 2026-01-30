ataxiaBasher.shielded = false
ataxiaTemp.ignoreCrits = false
bashStats.attacks = bashStats.attacks + 1

battleRage_Timers.small = tempTimer(17, [[battleRage_Timers.small = nil]])

if type(target) == "number" and ataxiaBasher.enabled then
  bashConsoleEcho("battlerage", "Used Small battlerage")
	if not ataxiaBasher.manual then
		deleteFull()
	end
end



