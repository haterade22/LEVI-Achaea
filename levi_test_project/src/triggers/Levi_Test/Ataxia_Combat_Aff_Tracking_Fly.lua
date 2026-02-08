if type(target) ~= "string" then
	return false
end

if isTargeted(matches[2]) then
	selectString(line,1)
	fg("black") bg("blue")
	resetFormat()
	dir_left = "fly"
	tAffs.paralysis = false
	tAffs.vertigo = false
	if removeAffV3 then removeAffV3("paralysis"); removeAffV3("vertigo") end
  send("pt " ..target.. ": Flying!")
  if gmcp.Char.Status.class == "Runewarden" and rtiwaz == true then
    send("queue addclear free empower tiwaz " ..target)
  else
    send("queue addclear free touch tentacle " ..target)
  end
end
  if tChaseTimer then
		killTimer(tostring(tChaseTimer))
 	end
 	tChaseTimer = tempTimer(2.3, [[tChaseTimer = nil]])

	targetIshere = false
	enableTimer("TargetOutOfRoom")
	
