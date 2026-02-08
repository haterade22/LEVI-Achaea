ataxiaTemp.lastLimbHit = "left arm"

local person = multimatches[1][2]

if isTargeted(person) then
	if multimatches[3][1] == "The attack rebounds back onto you!"
		or multimatches[3][1] == person .. " dodges nimbly out of the way." 
		or multimatches[3][1] == person .. " parries the attack with a deft manoeuvre." 
		or multimatches[3][1] == person .. " steps into the attack, grabs your arm, and throws you violently to the ground." 
		or multimatches[3][1] == person .. " quickly jumps back, avoiding the attack."  
		or multimatches[3][1] == "A reflection of " .. person .. " blinks out of existence." 
		or multimatches[3][1] == person .. " moves into your attack, knocking your blow aside before viciously countering with a strike to your head." 
		or multimatches[3][1] == "You lash out at " .. person .. " with a " .. multimatches[1][2] .. ", but miss."
		or multimatches[3][1] == person .. " twists his body out of harm's way."
		or multimatches[3][1] == person .. " twists her body out of harm's way."
	then
    if multimatches[3][1] == person .. " parries the attack with a deft manoeuvre." then
      ataxiaTemp.parriedLimb = ataxiaTemp.lastLimbHit
      cecho("<green> -> "..ataxiaTemp.parriedLimb)
    end      
	else
		bard_addLimbDamage(multimatches[1][3])
		if next(envenomList) then
			moveCursor(0, getLineNumber()-1)
			tarAffed(envenomList[1])
			if applyAffV3 then applyAffV3(envenomList[1]) end
			table.remove(envenomList, 1)
			moveCursorEnd()
      if not ataxia_isClass("bard") or ataxia.bardStuff.tunesmith ~= "martellato" then	
        tAffs.shield = false; tAffs.rebounding = false
        if removeAffV3 then removeAffV3("shield"); removeAffV3("rebounding") end
      end
		end
	end
	enableTrigger("Martellato Check")
	if ataxia.defences.heartsfury then
		send("envenom rapier with curare",false)
	end	
end

showMultimatches()