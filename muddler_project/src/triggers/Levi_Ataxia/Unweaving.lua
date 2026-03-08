local person = multimatches[1][2]
if isTargeted(person) then
	if multimatches[3][1] ~= "Your blow strikes "..person.." but is robbed of much of its impact by your faulty technique." then
		moveCursor(0, getLineNumber()-2)
		tarAffed("unweaving"..multimatches[1][3])	
		moveCursorEnd()	
	end
end