local person = multimatches[1][3]
if isTargeted(person) then
	if multimatches[3][1] ~= "Your blow strikes "..person.." but is robbed of much of its impact by your faulty technique." then
		moveCursor(0, getLineNumber()-1)
		if multimatches[1][2] == "left" then
			if tLimbs.LL < 79 or lb[target].hits["left leg"] < 75 then
				tarAffed("brokenleftleg")
			else
				tarAffed("damagedleftleg", "prone")
			end
		else
			if tLimbs.RL < 79 or lb[target].hits["right leg"] < 75 then
				tarAffed("brokenrightleg")
			else
				tarAffed("damagedrightleg", "prone")
			end	
		end

		psion_hitLimb(multimatches[1][2].." leg")
		send("contemplate "..target,false)		
		moveCursorEnd()
		psion_bleedAdd("20")	
	end
end