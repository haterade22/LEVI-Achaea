local person = multimatches[1][3]
if isTargeted(person) then
	if multimatches[3][1] ~= "Your blow strikes "..person.." but is robbed of much of its impact by your faulty technique." then
		moveCursor(0, getLineNumber()-1)
		if multimatches[1][2] == "left" then
			if tLimbs.LL < 79 or lb[target].hits["left leg"] < 75 then
				tarAffed("brokenleftleg")
				if applyAffV3 then applyAffV3("brokenleftleg") end
			else
				tarAffed("damagedleftleg", "prone")
				if applyAffV3 then applyAffV3("damagedleftleg"); applyAffV3("prone") end
			end
		else
			if tLimbs.RL < 79 or lb[target].hits["right leg"] < 75 then
				tarAffed("brokenrightleg")
				if applyAffV3 then applyAffV3("brokenrightleg") end
			else
				tarAffed("damagedrightleg", "prone")
				if applyAffV3 then applyAffV3("damagedrightleg"); applyAffV3("prone") end
			end	
		end

		psion_hitLimb(multimatches[1][2].." leg")
		send("contemplate "..target,false)		
		moveCursorEnd()
		psion_bleedAdd("20")	
	end
end