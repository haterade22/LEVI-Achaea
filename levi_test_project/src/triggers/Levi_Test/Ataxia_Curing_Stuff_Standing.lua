if ataxiaBasher.enabled then
	bashConsoleEcho("curing", "No longer prone!")
	if not ataxiaBasher.manual then
		deleteFull()
	end
end