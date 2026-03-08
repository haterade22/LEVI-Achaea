if type(target) == "string" and isTargeted(matches[2]) then
	erAff("rebounding")
	erAff("shield")
	selectString(line,1)
	setBold(true)
	fg("NavajoWhite")
	resetFormat()
end

if matches[2] == target then
	erAff("rebounding")
	erAff("shield")
end
