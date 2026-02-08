local person = multimatches[1][2]
if isTargeted(person) then
	if multimatches[3][1] == "The attack rebounds back onto you!"
		or multimatches[3][1] == person .. " dodges nimbly out of the way." 
		or multimatches[3][1] == person .. " quickly jumps back, avoiding the attack."  
		or multimatches[3][1] == "A reflection of " .. person .. " blinks out of existence." 
		or multimatches[3][1] == person .. " twists his body out of harm's way."
		or multimatches[3][1] == person .. " twists her body out of harm's way."
	then

	else
		if next(envenomList) then
			moveCursor(0, getLineNumber()-1)
			tarAffed(envenomList[1])
			if applyAffV3 then applyAffV3(envenomList[1]) end
			table.remove(envenomList, 1)
			moveCursorEnd()	
		end
	end
end

if ataxiaTemp.juggling then
	ataxiaTemp.juggling = ataxiaTemp.juggling - 1
	if ataxiaTemp.juggling == 0 then
		ataxiaTemp.juggling = nil
	end
end