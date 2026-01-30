if svo then
	svo.bals.voice = false
	svo.startbalancewatch("voice")
	raiseEvent("svo lost balance", "voice")
end

if matches[2] == target then
tAffs.rebounding = false
tAffs.shield = false
end