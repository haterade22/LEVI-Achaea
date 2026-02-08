if type(target) == "number" and ataxiaBasher.enabled then
	if not bashBalSub then
    if zgui then
      cecho("bashDisplay", "\n<yellow>BAL| <goldenrod>Got limb balance!")
    else
		  ataxiagui.bashConsole:cecho("\n<yellow>BAL| <goldenrod>Got limb balance!")		
    end
		bashBalSub = tempTimer(1, [[ bashBalSub = nil ]])
	end
	if not ataxiaBasher.manual and not autoHarvesting then
		deleteFull()
	end
end

if matches[2] == "legs" then
endBalTimer()
balanceHighlight()
tarc.write()
end