if isTargeted(matches[2]) then
	Target_Instill = "madness"
	if not haveAff("shadowmadness") then
		tarAffed("shadowmadness")
    if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..envenomList[1].. " and shadowmadness") end
    if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and shadowmadness") end
	elseif not haveAff("vertigo") then
		tarAffed("vertigo")
    if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..envenomList[1].. " and vertigo") end
    if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and vertigo") end
	else
		tarAffed("hallucinations")
    if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..envenomList[1].. " and hallucinations") end
    if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and hallucinations") end
	end
end

