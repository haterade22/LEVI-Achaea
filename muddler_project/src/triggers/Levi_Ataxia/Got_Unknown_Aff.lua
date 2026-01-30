gotUnknownAff()

if type(target) == "number" and ataxiaBasher.enabled then
	bashConsoleEcho("denizen", "Unknown affliction!")
	if not ataxiaBasher.manual then
		deleteFull()
	end
elseif not ataxiaBasher.enabled then
	selectString(line, 1)
	setBold(true)
	fg("DarkGreen")
	resetFormat()
end