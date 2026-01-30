local person = multimatches[1][3]
if isTargeted(person) then
	if multimatches[3][1] ~= "Your blow strikes "..person.." but is robbed of much of its impact by your faulty technique." then
		moveCursor(0, getLineNumber()-1)
		tarAffed("clumsiness")
		psion_hitLimb(multimatches[1][2].." arm")
		moveCursorEnd()
		psion_bleedAdd("20")		
	end
end
if partyrelay and not ataxia.afflictions.aeon then
send("pt " ..target.. ": clumsiness")
end