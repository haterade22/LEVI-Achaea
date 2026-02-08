if type(target) == "number" and ataxiaBasher.enabled then
	if not bashBalSub then
    if zgui then
      cecho("bashDisplay", "\n<yellow>BAL| <goldenrod>Got equilibrium!")
    else 
		  ataxiagui.bashConsole:cecho("\n<yellow>BAL| <goldenrod>Got equilibrium!")		
    end
		bashBalSub = tempTimer(1, [[ bashBalSub = nil ]])
	end
	if ataxia.afflictions.blackout then
		ataxiaBasher_attack()
	end
	if not ataxiaBasher.manual then
		deleteFull()
	end
end

ataxia_gotbal("eq")