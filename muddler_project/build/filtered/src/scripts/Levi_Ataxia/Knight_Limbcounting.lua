--[[if gmcp.Char.Status.class == "Paladin" then
    if matches[2] == target then
        tarMaxHealth = matches[5]
            if tarMaxHealth > "8399" then
                sliceLimb = (((7*tarMaxHealth)/(400-125))+((17/8)*(125+10))+2)
                breakpoint = math.ceil(tarMaxHealth/sliceLimb)
                cecho("\n<red>[<gold>Breakpoint: " ..breakpoint.. "<red>]")
            elseif tarMaxHealth < "8400" then
                sliceLimb = ((7*tarMaxHealth)/(400-125))+((17/8)*(125+10))
                breakpoint = math.ceil(tarMaxHealth/sliceLimb)
                cecho("\n<red>[<gold>Breakpoint: " ..breakpoint.. "<red>]")
        end
    end
displaySC()
end]]--

--unsure on how well it works yet
--this also only works for SnB, but with some tweaking it might be possible to work in general
--you will have to change the '125' to match whatever level sword you have
function knight_setBreakPoint(maxhp)
	local tarHP = maxhp
	local sliceLimb, perHit = 0, 0
  if ataxia.vitals.knight == "Dual Blunt" then
    --This isn't 100% correct, and will likely require tweaks. It's also based off of Level 1s.
    --This is also morningstars only.
    if tarHP >= 10000 then
      sliceLimb = 10
    elseif tarHP >= 8200 then
      sliceLimb = 9
    elseif tarHP >= 6500 then
      sliceLimb = 8
    elseif tarHP >= 5000 then
      sliceLimb = 7
    else
      sliceLimb = 6
    end
    sliceLimb = string.format("%2.2f", 100/sliceLimb)
    ataxiaTemp.maceHit = tonumber(sliceLimb)
  else
    if tarHP >= 8400 then
  		sliceLimb = (((7*tarHP)/(400-125))+((17/8)*(125+10))+2)
    else
  		sliceLimb = ((7*tarHP)/(400-125))+((17/8)*(125+10))
  	end
  	if ataxia_isClass("runewarden") then
  		sliceLimb = sliceLimb * 1.1
  	end
  	perHit = (sliceLimb/tarHP)*100
  	perHit = string.format("%2.2f", perHit)
  	
  	ataxiaTemp.swordHit = perHit
  end
end

function knight_addLimbDamage(limbhit)
	if not ataxiaTemp.swordHit then return end
	local toLimb = {
		["head"] = "H",
		["torso"] = "T",
		["right leg"] = "RL",
		["left leg"] = "LL",
		["right arm"] = "RA",
		["left arm"] = "LA",
	}
	local lco = toLimb[limbhit]
	tLimbs[lco] = tLimbs[lco] + ataxiaTemp.swordHit
	
	if tLimbs[lco] >= 97 then
		cecho("\n<a_red> >> [ <a_darkcyan>"..target:upper().."'S "..limbhit:upper().." HAS BEEN BROKEN <a_red> ] <<")
		target_limbBroke(limbhit)
	end
	targetLimbs_updateTimers(limbhit)
end

function knight_dwbAddHit(limbhit)
  if not ataxiaTemp.maceHit then return end
	local toLimb = {
		["head"] = "H",
		["torso"] = "T",
		["right leg"] = "RL",
		["left leg"] = "LL",
		["right arm"] = "RA",
		["left arm"] = "LA",
	}
	local lco = toLimb[limbhit]
	tLimbs[lco] = tLimbs[lco] + ataxiaTemp.maceHit
	
	if tLimbs[lco] >= 98 then
		cecho("\n<a_red> >> [ <a_darkcyan>"..target:upper().."'S "..limbhit:upper().." HAS BEEN BROKEN <a_red> ] <<")
		target_limbBroke(limbhit)
	end
	targetLimbs_updateTimers(limbhit)  
end