if svo then
	svo.bals.voice = false
	svo.startbalancewatch("voice")
	raiseEvent("svo lost balance", "voice")
end

if matches[2] == target then
tAffs.rebounding = false
if removeAffV3 then removeAffV3("rebounding") end
tAffs.shield = false
if removeAffV3 then removeAffV3("shield") end
end