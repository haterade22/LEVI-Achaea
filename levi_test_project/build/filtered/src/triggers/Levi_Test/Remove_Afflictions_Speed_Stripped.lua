if isTargeted(matches[2]) then
	selectString(line,1)
	setBold(true)
	fg("LightSkyBlue")
	resetFormat()
	tarAffed("nospeed")
	if applyAffV3 then applyAffV3("nospeed") end
end