if type(target) == "number" and ataxiaBasher.enabled then
	bashConsoleEcho("curing", "Transmuted!")
elseif not ataxiaBasher.enabled then
	selectString(line, 1)
	setItalics(true)
	fg("DodgerBlue")
	resetFormat()
end