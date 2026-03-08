local person = multimatches[1][2]
if isTargeted(person) then
	if multimatches[3][1] ~= "Your blow strikes "..person.." but is robbed of much of its impact by your faulty technique." then
		moveCursor(0, getLineNumber()-1)
		tarAffed("dizziness", "stupidity")
		psion_hitLimb("head")	
		moveCursorEnd()
		psion_bleedAdd("20")		
	end
end


send("pt " ..target.. ": stupidity and dizziness")

