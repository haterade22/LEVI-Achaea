local person = multimatches[1][2]
if isTargeted(person) then
	if multimatches[3][1] ~= "Your blow strikes "..person.." but is robbed of much of its impact by your faulty technique." then
		moveCursor(0, getLineNumber()-1)
		if haveAff("bloodfire") then
			tarAffed("nausea", "anorexia")
		else
			tarAffed("nausea")
		end
		psion_hitLimb("torso")
	
		send("contemplate "..target,false)		
		moveCursorEnd()
		psion_bleedAdd("30")	
	end
end

