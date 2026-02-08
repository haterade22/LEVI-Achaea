if ataxiaBasher.enabled then
	  haveBeenHit = tempTimer(1, [[ haveBeenHit = nil ]])
		bashConsoleEcho("denizen", "Denizen attacked us!")
		bashStats.mobhits = bashStats.mobhits + 1
	if not ataxiaBasher.manual then
		deleteFull()
	end
end

