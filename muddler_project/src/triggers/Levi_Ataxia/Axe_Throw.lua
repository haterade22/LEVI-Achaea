local axe = multimatches[1][2]
local person = multimatches[1][3]
if isTargeted(person) then
	if multimatches[3][1] == "The attack rebounds back onto you!"
		or multimatches[3][1] == person .. " dodges nimbly out of the way." 
		or multimatches[3][1] == person .. " quickly jumps back, avoiding the attack."  
		or multimatches[3][1] == "A reflection of " .. person .. " blinks out of existence." 
		or multimatches[3][1] == "You lash out at " .. person .. " with a " .. multimatches[1][4] .. ", but miss."
		or multimatches[3][1] == person .. " twists his body out of harm's way."
		or multimatches[3][1] == person .. " twists her body out of harm's way."
    or multimatches[3][1] == person .. " parries the attack with a deft manoeuvre."
    or multimatches[3][1] == person .. " moves into your attack, knocking your blow aside before viciously countering with a strike to your head."
    or multimatches[1][2] == axe.." misses "..target.." completely." 
		then
			if multimatches[3][1] == "The attack rebounds back onto you!" then
				tAffs.rebounding = true
			end
	else
		if next(envenomList) then
			moveCursor(0, getLineNumber()-1)
			tarAffed(envenomList[1])
			table.remove(envenomList, 1)
			moveCursorEnd()
		end
	end
end