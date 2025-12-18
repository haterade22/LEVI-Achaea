-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > Combat > Offensive Things > Limb Management > Target Applied Somewhere

function target_curedLimb(limb)

  if haveAff("mangled"..limb) then
    erAff("mangled"..limb)
    tAffs["damaged"..limb] = true
  else
    erAff("damaged"..limb)
    tBals.salve = true
    if tBals.timers.salve then killTimer(tBals.timers.salve); tBals.timers.salve = nil end
    if limb ~= "head" and limb ~= "torso" then
      tAffs["broken"..limb] = true
    end
	end
end

function target_salveBal(num)
  local offSalve = num - 0.25
  if tBals.timers.salve then killTimer(tBals.timers.salve) end
  tBals.salve = false
  tBals.timers.salve = tempTimer(offSalve, [[ tBals.salve = true; tBals.timers.salve = nil ]])
end

function target_appliedTo(where)
	if where == "arms" then
		if ataxiaTemp.mendingWait then
			ataxia_Echo("Looks like the last apply was mending.")
			killTimer(ataxiaTemp.mendingWait)
			ataxiaTemp.mendingWait = nil
			killTimer(ataxiaTemp.checkBreak)
			ataxiaTemp.checkBreak = nil
			target_salveBal(1.1)
           
			if haveAff("brokenleftarm") then
				erAff("brokenleftarm")
			else
				erAff("brokenrightarm")
			end
		end
		if haveAff("damagedleftarm") or haveAff("mangledleftarm") then
			ataxiaTemp.mendingWait = tempTimer(2, [[ ataxiaTemp.mendingWait = nil ]])
			ataxiaTemp.checkBreak = tempTimer(3.7, [[
				target_curedLimb("leftarm");
				target_resetLimb("left arm")
			]])
      target_salveBal(4)
      
		elseif haveAff("damagedrightarm") or haveAff("mangledrightarm") then
			ataxiaTemp.mendingWait = tempTimer(2, [[ ataxiaTemp.mendingWait = nil ]])
			ataxiaTemp.checkBreak = tempTimer(3.7, [[
				target_curedLimb("rightarm");
				target_resetLimb("right arm")
			]])
			target_salveBal(4)
      
		elseif haveAff("brokenleftarm") then
			erAff("brokenleftarm")
      target_salveBal(1.1)
		else
			erAff("brokenrightarm")
      target_salveBal(1.1)      	
		end
	else
		if ataxiaTemp.mendingWait then
			ataxia_Echo("Looks like the last apply was mending.")
			tBals.salve = true
			killTimer(ataxiaTemp.mendingWait)
			ataxiaTemp.mendingWait = nil
			killTimer(ataxiaTemp.checkBreak)
			ataxiaTemp.checkBreak = nil
      target_salveBal(1.1)
			
			if haveAff("brokenleftleg") then
				erAff("brokenleftleg")
			else
				erAff("brokenrightleg")
			end
		end
		if haveAff("damagedleftleg") or haveAff("mangledleftleg") then
			ataxiaTemp.mendingWait = tempTimer(2, [[ ataxiaTemp.mendingWait = nil ]])
			ataxiaTemp.checkBreak = tempTimer(3.7, [[
				target_curedLimb("leftleg");
				target_resetLimb("left leg")
			]])
      target_salveBal(4)
      
		elseif haveAff("damagedrightleg") or haveAff("mangledrightleg") then
			ataxiaTemp.mendingWait = tempTimer(2, [[ ataxiaTemp.mendingWait = nil ]])
			ataxiaTemp.checkBreak = tempTimer(3.7, [[
				target_curedLimb("rightleg");
				target_resetLimb("right leg")
			]])
			target_salveBal(4)
      
		elseif haveAff("brokenleftleg") then
			erAff("brokenleftleg")
      target_salveBal(1.1)
		else
			erAff("brokenrightleg")
      target_salveBal(1.1)		
		end
	end
end

