if isTargeted(matches[2]) then
	Target_Instill = "depression"
	if not haveAff("depression") then
		tarAffed("depression")
    if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..envenomList[1].. " and depression") 
    elseif partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and depression") end
	elseif not haveAff("nausea") then
		tarAffed("nausea")
    if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..envenomList[1].. " and nausea") 
    elseif partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and nausea") end
	elseif not haveAff("hypochondria") then
		tarAffed("hypochondria")
    if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..envenomList[1].. " and hypochondria") elseif
	   partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and hypochondria") end
  else
		tarAffed("depression", "anorexia", "masochism")
    if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..envenomList[1].. " and depression and anoreixa and masochism")
    elseif partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and depression and anorexia and masochism") end
     end
    
	end


 
      