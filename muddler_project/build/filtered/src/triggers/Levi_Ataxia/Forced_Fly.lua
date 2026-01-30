selectString(line,1)
fg("black") bg("blue")
resetFormat()
send("ql")
dir_left = "forcefly"
tAffs.paralysis = false

if tChaseTimer then
	killTimer(tostring(tChaseTimer))
end
tChaseTimer = tempTimer(2.0, [[tChaseTimer = nil]])
targetIshere = false
enableTimer("TargetOutOfRoom")