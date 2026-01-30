local person = multimatches[1][2]
if isTargeted(person) then
	if multimatches[3][1] ~= "Your blow strikes "..person.." but is robbed of much of its impact by your faulty technique." then
		moveCursor(0, getLineNumber()-1)
		tarAffed("asthma")
		psion_hitLimb("head")
		send("contemplate "..target,false)		
		moveCursorEnd()
		if haveAff("prone") then
			psion_bleedAdd("150")
		else
			psion_bleedAdd("65")
		end
	end
end

if partyrelay and not ataxia.afflictions.aeon then
send("pt " ..target.. ": asthma")
end