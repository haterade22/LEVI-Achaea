if (autoHarvesting or autoExtracting or type(target) == "number") and ataxiaBasher.enabled then
	if not bashBalSub then
    if zgui then 
      cecho("bashDisplay","\n<yellow>BAL| <goldenrod>Got limb balance!")
    else
		  ataxiagui.bashConsole:cecho("\n<yellow>BAL| <goldenrod>Got limb balance!")
    end		
		bashBalSub = tempTimer(1, [[ bashBalSub = nil ]])
	end
	if ataxia.afflictions.blackout then
		ataxiaBasher_attack()
	end
	if (autoHarvesting or autoExtracting) or not ataxiaBasher.manual then
		--deleteFull()
	end
elseif ataxia.fishing and ataxia.fishing.enabled then
	bashConsoleEcho("curing", "Got balance back.")	
	deleteFull()
end

if not line:find("stunned") then
  ataxia_gotbal("bal")
end

deleteFull()
endBalTimer()
balanceHighlight()
tarc.write()