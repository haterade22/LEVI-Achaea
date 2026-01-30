if (autoHarvesting  or type(target) == "number") and ataxiaBasher.enabled then
	if not bashBalSub then 
    if zgui then
      cecho("bashDisplay","\n<yellow>BAL| <goldenrod>Got voice balance!")	
    else
		  ataxiagui.bashConsole:cecho("\n<yellow>BAL| <goldenrod>Got voice balance!")		
    end
		bashBalSub = tempTimer(1, [[ bashBalSub = nil ]])
	end

	if not ataxiaBasher.manual then
		deleteFull()
	end
end

if not line:find("stunned") then
  ataxia_gotbal("voice")
end