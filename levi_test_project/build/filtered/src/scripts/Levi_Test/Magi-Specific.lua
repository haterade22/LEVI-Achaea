function magi_checkDestroy()
	if not tAffs.burns or tAffs.burns == 0 then return false end
	if not ataxiaTemp.lastDiag then return false end
	
	if tAffs.burns >= ataxiaTemp.lastDiag then
		return true
	else
		return false
	end
end

function magi_setDestroy(num)
	if not tAffs.burns or tAffs.burns == 0 then return end
  if num >= 40 and tAffs.burns >= 2 then
		ataxia_boxEcho(target.." CAN BE DESTROYED", "orange")
		ataxiaTemp.lastDiag = needed
		tempTimer(2, [[ ataxiaTemp.lastDiag = nil ]])
	end
end

function magi_addBurns()
tAffs.burns = tAffs.burns or 0
tAffs.burns = tAffs.burns + 1
  if tAffs.burns > 5 then tAffs.burns = 5 end
cecho(" <DimGrey>[<red>"..tAffs.burns.."/5<DimGrey>]")
end



function magi_resetLimbs()
	tLimbs = {
		H = 0,	T = 0,
		RL = 0,	RA = 0,
		LL = 0, LA = 0,
		BP = 100,
		staff = 15,
    airstrike = 8,
	}
	ataxiaEcho("Breakpoints have been reset.")
end

function magi_setBreakpoint(health)
	if health <= 3499 then
		tLimbs.staff = tonumber(string.format("%2.2f", (100/6)))
	elseif health <= 6700 then
		tLimbs.staff = tonumber(string.format("%2.2f", (100/6.5)))
	else
		tLimbs.staff = tonumber(string.format("%2.2f", (100/7)))
	end
	tLimbs.airstrike = tonumber(string.format("%2.2f", (100/12)))
	cecho("\n<a_blue>    >> <a_green>"..health.."h <a_blue>| <a_magenta>"..tLimbs.staff.."("..math.floor((100/tLimbs.staff)+0.05)..") <a_blue>| <a_brown>"..tLimbs.airstrike.."("..math.floor((100/tLimbs.airstrike)+0.05)..") <a_blue><<")	
end

function magi_staffStrike(element, limb)
	local toLimb = {
		["head"] = "H",
		["torso"] = "T",
		["right leg"] = "RL",
		["left leg"] = "LL",
		["right arm"] = "RA",
		["left arm"] = "LA",
	}
	local lco = toLimb[limb]
	if element:title() == "Whiirh" then
		tLimbs[lco] = tLimbs[lco] + tLimbs.airstrike
		tAffs.prone = true
	else
		tLimbs[lco] = tLimbs[lco] + tLimbs.staff
    if element:title() == "Sllshya" then
      for _, aff in pairs({"nocaloric", "shivering", "frozen"}) do
        if not haveAff(aff) then
          tAffs[aff] = true
          cecho("<green>+<DodgerBlue>"..aff.."<green>+")
          break
        end
      end
    end
	end
	
	if tLimbs[lco] >= 98 then
		target_limbBroke(limb)
		cecho("\n<a_red> >> [ <a_darkcyan>"..target:upper().."'S "..limb:upper().." HAS BEEN BROKEN <a_red> ] <<")
	end
	targetLimbs_updateTimers(limb)
end