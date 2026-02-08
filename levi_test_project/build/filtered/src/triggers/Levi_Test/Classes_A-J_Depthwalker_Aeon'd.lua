if isTargeted(matches[2]) then
	selectString(line,1)
	setBold(true)
	fg("LightSkyBlue")
	resetFormat()
	ataxia_boxEcho(target:upper().." HAS BEEN AEONED!", "black:LightSkyBlue")

end