local person = multimatches[1][2]
if isTargeted(person) then
	if multimatches[3][1] ~= "Your blow strikes "..person.." but is robbed of much of its impact by your faulty technique." then
		if haveAff("prone") then
			moveCursor(0, getLineNumber()-1)
			tarAffed("blackout")
			tempTimer(3.5, [[erAff("blackout")]])
		end
		psion_hitLimb("head")
		send("contemplate "..target,false)		
		moveCursorEnd()	
	end
end
if partyrelay and not ataxia.afflictions.aeon then
send("pt " ..target.. ": blackout")
end
