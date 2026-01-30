bashConsoleEcho("denizen", "Denizen attack blocked!")
bashStats.mobhits = bashStats.mobhits + 1
bashStats.blockedhits = bashStats.blockedhits + 1
if ataxiaBasher.enabled and not ataxiaBasher.manual then
	--deleteFull()
	moveCursor(0, getLineNumber()-1)
	--deleteLine()

	moveCursor(0, getLineNumber()-1)
	if not isPrompt() then
		--deleteLine()
	end
end
