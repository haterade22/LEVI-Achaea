if type(target) ~= "string" then
	return false
end

if isTargeted(matches[2]) then
	selectString(line,1)
	fg("black") bg("LightSkyBlue")
	resetFormat()
	dir_left = matches[3]
  engaged = false

	if not string.find(matches[1], "tumble") then
		tAffs.paralysis = false
	end

	ataxia_boxEcho(target.." HAS LEFT TO THE "..dir_left, "black:green")
  ataxia_boxEcho(target.." HAS LEFT TO THE "..dir_left, "black:green")

	if not chasing_Targets then cecho("<red>           -= Target chasing is currently disabled =-") return end
  
  if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] ~= "Spec: Dual Blunt" then
  send("queue addclear free lunge "..target..";tyranny")
elseif jumping and jumping == true then
	sendAll("cq all", "queue addclear free mountjump "..dir_left)
  elseif not jumping or jumping == false then

	sendAll("cq all;queue addclear free "..dir_left)
end
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