if isTargeted(matches[2]) then
	Target_Instill = "retribution"
	if not haveAff("justice") then
		tarAffed("justice")
    if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..envenomList[1].. " and justice") end
    if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and justice") end
	else
		tarAffed("retribution")
    if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..envenomList[1].. " and retribution") end
    if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and retribution") end
	end
end
