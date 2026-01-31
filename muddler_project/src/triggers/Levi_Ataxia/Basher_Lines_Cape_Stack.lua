if type(target) == "number" and ataxiaBasher.enabled then
	bashConsoleEcho("denizen", "Deathcape Stack Gained")
	if not ataxiaBasher.manual then
		deleteFull()
	end
end