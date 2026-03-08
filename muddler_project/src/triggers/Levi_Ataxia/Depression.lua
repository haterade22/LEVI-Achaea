if isTargeted(matches[2]) then
    Target_Instill = "depression"
    -- Guard: get venom name safely (may be nil when using timeloop)
    local venomName = (envenomList and envenomList[1]) or "unknown"

    if not haveAff("depression") then
        tarAffed("depression")
        if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " and depression")
        elseif partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and depression") end
    elseif not haveAff("nausea") then
        tarAffed("nausea")
        if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " and nausea")
        elseif partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and nausea") end
    elseif not haveAff("hypochondria") then
        tarAffed("hypochondria")
        if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " and hypochondria")
        elseif partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and hypochondria") end
    else
        tarAffed("depression", "anorexia", "masochism")
        if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " and depression and anorexia and masochism")
        elseif partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and depression and anorexia and masochism") end
    end
end


 
      