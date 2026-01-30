if type(target) ~= "string" then
	return false
end

depdistort = false

if isTargeted(matches[3]) then
	selectString(line,1)
	fg("black") bg("LightSkyBlue")
	resetFormat()
	dir_left = matches[4]

	if not string.find(matches[1], "tumble") then
		tAffs.paralysis = false
	end

	ataxia_boxEcho(target.." HAS LEFT TO THE "..dir_left, "black:green")

	if not chasing_Targets then cecho("<red>           -= Target chasing is currently disabled =-") return end

	sendAll("cq all;queue addclear free "..dir_left)

	if tChaseTimer then
		killTimer(tostring(tChaseTimer))
 	end
 	tChaseTimer = tempTimer(2.5, [[tChaseTimer = nil]])

	if ataxiaTemp.tarTumble then ataxiaTemp.tarTumble = nil end
	if ataxiaTemp.tumbleTimer then killTimer(ataxiaTemp.tumbleTimer) end

	targetIshere = false
	enableTimer("TargetOutOfRoom")
	
	if ataxiaTemp.repeatOffence and not ataxiaTemp.doRepeat and chasing_Targets then
		enableTrigger("Repeat Offence")
	end
end