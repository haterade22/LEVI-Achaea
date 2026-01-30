function setPriestBreakPoint(hp)
	if hp >= 6500 then
		tLimbs.BP = 6
	elseif hp > 5000 then
		tLimbs.BP = 5
	elseif hp < 3200 then
		tLimbs.BP = 3
	else
		tLimbs.BP = 4
	end
	ataxiaEcho("Hmm... Looks like "..target.." will break in <red>"..tLimbs.BP.."<LightSkyBlue> hits from your mace.")
end

function smoteLimb(limb)
	local toLimb = {
		["head"] = "H",
		["torso"] = "T",
		["right leg"] = "RL",
		["left leg"] = "LL",
		["right arm"] = "RA",
		["left arm"] = "LA",
	}
	local lco = toLimb[limb]
	tLimbs[lco] = tLimbs[lco] + 1
	
	if tLimbs[lco] == tLimbs.BP then
		if limb == "head" then
			tarAffed("stupidity")
		end
		target_limbBroke(limb)
		ataxia_echo("<black:LightSkyBlue>      "..target:upper().."'S<black:green> "..limb:upper().." <black:LightSkyBlue>IS BROKEN!      ")
	end
	targetLimbs_updateTimers(limb)
end