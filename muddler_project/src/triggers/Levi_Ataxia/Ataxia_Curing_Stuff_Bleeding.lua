if type(target) == "number" and ataxiaBasher.enabled then
	bashConsoleEcho("curing", "Bled for "..matches[2])
	if not ataxiaBasher.manual then
		deleteFull()
	end
end