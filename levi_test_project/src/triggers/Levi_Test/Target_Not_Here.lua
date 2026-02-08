if type(target) == "number" and ataxiaBasher.enabled then
	bashConsoleEcho("denizen", "Target is gone!")
	if not ataxiaBasher.manual then
		deleteFull()
	end
end
