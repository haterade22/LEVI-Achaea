if type(target) == "number" and ataxiaBasher.enabled then
	if not bashMossSub then
    if zgui then
      cecho("bashDisplay", "\n<DarkGreen>MOSS| <green>Used moss balance!")	
    else
		  ataxiagui.bashConsole:cecho("\n<DarkGreen>MOSS| <green>Used moss balance!")		
    end
		bashMossSub = tempTimer(1, [[ bashMossSub = nil ]])
	end
	if not ataxiaBasher.manual then
		deleteFull()
	end
end
