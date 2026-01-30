function psion_hitLimb(limb)
	local toLimb = {
		["head"] = "H",
		["torso"] = "T",
		["right leg"] = "RL",
		["left leg"] = "LL",
		["right arm"] = "RA",
		["left arm"] = "LA",
	}
	local lco = toLimb[limb]
	
	if lco == "RL" or lco == "LL" then
		tLimbs[lco] = tLimbs[lco] + 20
	else
		tLimbs[lco] = tLimbs[lco] + 25
	end
	
	if tLimbs[lco] >= 98 then
		cecho("\n<a_red> >> [ <a_darkcyan>"..target:upper().."'S "..limb:upper().." HAS BEEN BROKEN <a_red> ] <<")
		target_limbBroke(limb)
		if limb == "head" then
			tAffs.stupidity = true
		end
	end
	targetLimbs_updateTimers(limb)
end