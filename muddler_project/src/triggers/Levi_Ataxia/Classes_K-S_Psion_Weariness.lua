local person = multimatches[1][3]
if isTargeted(person) then
	if multimatches[3][1] ~= "Your blow strikes "..person.." but is robbed of much of its impact by your faulty technique." then
		moveCursor(0, getLineNumber()-1)
		tarAffed("weariness")
		psion_hitLimb(multimatches[1][2].." arm")
		
		moveCursorEnd()
		psion_bleedAdd("35")		
	end
end

send("pt " ..target.. ": weariness")
