if ataxiaBasher.enabled and not ataxiaBasher.manual then
	deleteFull()
	if not powerEcho then
		bashConsoleEcho("curing", "Powered angel.")
		powerEcho = tempTimer(0.5, [[powerEcho = nil]])
	end
end
empathyTick = 0