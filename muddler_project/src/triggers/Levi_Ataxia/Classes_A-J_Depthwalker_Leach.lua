if isTargeted(matches[2]) then
	Target_Instill = "leach"
	if not haveAff("parasite") then
		tarAffed("parasite")
    if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..envenomList[1].. " and parasite") end
    if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and parasite") end
	elseif not haveAff("healthleech") then
		tarAffed("healthleech")
    if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..envenomList[1].. " and healthleech") end
    if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and healthleech") end
	elseif not haveAff("manaleech") then
		tarAffed("manaleech")
    if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..envenomList[1].. " and manaleech") end
    if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and manaleech") end
	else
		tarAffed("parasite", "healthleech", "manaleech")
	end
end