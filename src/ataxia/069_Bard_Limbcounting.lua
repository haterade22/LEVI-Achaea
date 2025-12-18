-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > Combat > Offensive Things > Limb Management > Bard Limbcounting

--unsure on how well it works yet
function bard_setBreakpoint(maxhp)
  local hits_to_break = linearFit(maxhp)
  local dmg_per_hit = 100/hits_to_break
	ataxiaTemp.rapierJab = string.format("%2.2f", (dmg_per_hit))
	cecho("  <red>[<CadetBlue>pj- <green>"..ataxiaTemp.rapierJab.."%<red>]")
end

function bard_addLimbDamage(limbhit)
	if not ataxiaTemp.rapierJab then return end
	local toLimb = {
		["head"] = "H",
		["torso"] = "T",
		["right leg"] = "RL",
		["left leg"] = "LL",
		["right arm"] = "RA",
		["left arm"] = "LA",
	}
	local lco = toLimb[limbhit]
	tLimbs[lco] = tLimbs[lco] + ataxiaTemp.rapierJab
	
	if tLimbs[lco] >= 99 then
		cecho("\n<a_red> >> [ <a_darkcyan>"..target:upper().."'S "..limbhit:upper().." HAS BEEN BROKEN <a_red> ] <<")
		target_limbBroke(limbhit)
  elseif ataxia.bardStuff.tunesmith == "acciaccatura" and tLimbs[lco] >= 80 then
    tLimbs[lco] = 100
    cecho("\n<a_red> >> [ <a_darkcyan>"..target:upper().."'S "..limbhit:upper().." HAS BEEN BROKEN <a_red> ] <<")
    target_limbBroke(limbhit)
	end
	targetLimbs_updateTimers(limbhit)
end

function bard_tremvib(limbhit)
	if not ataxiaTemp.rapierJab then return end
	local toLimb = {
		["head"] = "H",
		["torso"] = "T",
		["right leg"] = "RL",
		["left leg"] = "LL",
		["right arm"] = "RA",
		["left arm"] = "LA",
	}
	local lco = toLimb[limbhit]
	tLimbs[lco] = tLimbs[lco] + 60
	
	if tLimbs[lco] >= 99.99 then
		cecho("\n<a_red> >> [ <a_darkcyan>"..target:upper().."'S "..limbhit:upper().." HAS BEEN BROKEN <a_red> ] <<")
		target_limbBroke(limbhit)
	end
	targetLimbs_updateTimers(limbhit)
end