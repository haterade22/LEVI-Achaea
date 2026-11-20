--[[mudlet
type: script
name: Misc CanDo
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
- Curing Stuff
- Can(x)
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function ataxiaBasher_canShield()
	local canShield = true
	-- 2026-11-20 (manifested nightmare): in a room where hits passed our shield, a `touch shield`
	-- is a wasted round -- the spike branch and the shieldThresholdPct branch of dangerLevel both
	-- ask here, so both stop shielding in that room (basher/001, ataxiaBasher_lastStandHit).
	if ataxiaBasher_shieldPassHere and ataxiaBasher_shieldPassHere() then return false end

	for num, thing in pairs(ataxia.denizensHere) do
		if not ataxiaBasher.noShieldBreak.mobs[thing] and table.contains(ataxiaBasher.targetList[ataxiaBasher_areaKey()], thing) then
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