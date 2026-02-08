function ataxiaBasher_canShield()
	local canShield = true
	
	for num, thing in pairs(ataxia.denizensHere) do
		if not ataxiaBasher.noShieldBreak.mobs[thing] and table.contains(ataxiaBasher.targetList[gmcp.Room.Info.area], thing) then
			canShield = false
		end
	end
	
	return canShield
end

function isMorphed(what)
	if ataxia.vitals.morph and ataxia.vitals.morph:lower() == what:lower() then
		return true
	else
		return false
	end
end