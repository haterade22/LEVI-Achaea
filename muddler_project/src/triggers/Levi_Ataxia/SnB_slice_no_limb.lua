local person = multimatches[1][2]
if isTargeted(person) then
  if not wearicheck and haveAff("weariness") then
  erAff("weariness")
  end
	if multimatches[3][1] == "The attack rebounds back onto you!"
		or multimatches[3][1] == person .. " dodges nimbly out of the way." 
		or multimatches[3][1] == person .. " quickly jumps back, avoiding the attack."  
		or multimatches[3][1] == "A reflection of " .. person .. " blinks out of existence." 
		or multimatches[3][1] == "You lash out at " .. person .. " with a " .. multimatches[1][3] .. ", but miss."
		or multimatches[3][1] == person .. " twists his body out of harm's way."
		or multimatches[3][1] == person .. " twists her body out of harm's way."
	then
		if multimatches[3][1] == "The attack rebounds back onto you!" then
			ataxiaTemp.ignoreShield = true
		end
	else
		ataxiaTemp.ignoreShield = false
    
  if gmcp.Char.Status.class == "Runewarden" then
    if next(envenomList) then
			moveCursor(0, getLineNumber()-1)
			tarAffed(envenomList[1])
     local affstruck = envenomList[1]
			table.remove(envenomList, 1)
			moveCursorEnd()
       if partyrelay then send("pt "..target..": "..affstruck)
      end
    end
  end
  if gmcp.Char.Status.class == "Infernal" then
    if invest ~= "agony" then
    envenomList = {}
    else
		if next(envenomList) then
			moveCursor(0, getLineNumber()-1)
			tarAffed(envenomList[1])
     local affstruck = envenomList[1]
			table.remove(envenomList, 1)
			moveCursorEnd()
       if partyrelay then send("pt "..target..": "..affstruck)
         end
		    end
	   end
    end
  end
end

if swordneed[1] == "combination "..target.." slice "..targetlimb.." gecko "..shieldneed[1]..";shieldstrike "..target.." low" or "combination "..target.." slice gecko "..shieldneed[1]..";shieldstrike "..target.." low"
then
paraslick = true
else paraslick = false
end
