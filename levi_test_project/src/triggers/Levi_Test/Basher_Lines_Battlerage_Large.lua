ataxiaBasher.shielded = false
ataxiaTemp.ignoreCrits = false
bashStats.attacks = bashStats.attacks + 1

battleRage_Timers.large = tempTimer(24, [[battleRage_Timers.large = nil]])

if type(target) == "number" and ataxiaBasher.enabled then
	bashConsoleEcho("battlerage", "Used hard-hitting battlerage")
	if not ataxiaBasher.manual then
		deleteFull()
	end
end

