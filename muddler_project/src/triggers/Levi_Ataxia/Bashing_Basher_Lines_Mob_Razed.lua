ataxiaBasher.shielded = false
ataxiaTemp.ignoreCrits = true

if type(target) == "number" and ataxiaBasher.enabled then
	if not bashRazeSub then
		--ataxiaBasher_attack()
    basher_needAction = true 
		bashConsoleEcho("attack", "Razed that dirty bitch!")		
		bashRazeSub = tempTimer(1, [[ bashRazeSub = nil ]])
	else
		if not ataxiaBasher.manual then
			deleteFull()
		end
	end
else
	erAff("rebounding")
	erAff("shield")
end




                                                
