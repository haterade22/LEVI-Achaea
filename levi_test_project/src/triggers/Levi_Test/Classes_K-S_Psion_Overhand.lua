local person = multimatches[1][2]
if isTargeted(person) then
	if multimatches[3][1] ~= "Your blow strikes "..person.." but is robbed of much of its impact by your faulty technique." then
		moveCursor(0, getLineNumber()-1)
		if tLimbs.H >= 75 or lb[target].hits["head"] >= 75 then
			tarAffed("impatience", "stupidity", "prone")
			if applyAffV3 then applyAffV3("impatience"); applyAffV3("stupidity"); applyAffV3("prone") end
    elseif haveAff("prone") then
      tarAffed("impatience")
      if applyAffV3 then applyAffV3("impatience") end
		else
			tarAffed("stupidity", "prone")
			if applyAffV3 then applyAffV3("stupidity"); applyAffV3("prone") end
		end
		psion_hitLimb("head")
	
		send("contemplate "..target,false)		
		moveCursorEnd()	
		
		psion_bleedAdd("20")
		
	end
end

if tAffs.prone then
send("pt " ..target.. ": impatience")
else 
send("pt " ..target.. ": prone and stupidity")
end

