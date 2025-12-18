-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > Combat > Offensive Things > Limb Management > Dragon/Elord

function dragon_rendHit(limb)
	local toLimb = {
		["head"] = "H",
		["torso"] = "T",
		["right leg"] = "RL",
		["left leg"] = "LL",
		["right arm"] = "RA",
		["left arm"] = "LA",
	}
	local lco = toLimb[limb]
	
	tLimbs[lco] = tLimbs[lco] + 25
	
	if tLimbs[lco] >= 98 then
		cecho("\n<a_red> >> [ <a_darkcyan>"..target:upper().."'S "..limb:upper().." HAS BEEN BROKEN <a_red> ] <<")
		target_limbBroke(limb)
		if limb == "head" then
			tarBonusAff("stupidity")
		end
	end
	targetLimbs_updateTimers(limb)
end


function earth_powderiseHit(limb)
	local toLimb = {
		["head"] = "H",
		["torso"] = "T",
		["right leg"] = "RL",
		["left leg"] = "LL",
		["right arm"] = "RA",
		["left arm"] = "LA",
	}
	local lco = toLimb[limb]
  local x = (ataxia.vitals.shaping == 4 and 40 or 20)	
	tLimbs[lco] = tLimbs[lco] + x
  
	
	if tLimbs[lco] >= 100 then
		cecho("\n<red> -= "..limb.." broke! =-")
    cecho("\n<red> -= "..limb.." broke! =-")
		target_limbBroke(limb)
		if limb == "head" then
			tarBonusAff("stupidity")
		end
	end
	targetLimbs_updateTimers(limb)
end