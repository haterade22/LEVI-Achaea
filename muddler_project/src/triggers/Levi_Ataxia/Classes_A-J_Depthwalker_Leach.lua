if isTargeted(matches[2]) then
    Target_Instill = "leach"
    -- Guard: get venom name safely (may be nil when using timeloop)
    local venomName = (envenomList and envenomList[1]) or "unknown"

    if not haveAff("parasite") then
        tarAffed("parasite")
        if applyAffV3 then applyAffV3("parasite") end
        if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " and parasite") end
        if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and parasite") end
    elseif not haveAff("healthleech") then
        tarAffed("healthleech")
        if applyAffV3 then applyAffV3("healthleech") end
        if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " and healthleech") end
        if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and healthleech") end
    elseif not haveAff("manaleech") then
        tarAffed("manaleech")
        if applyAffV3 then applyAffV3("manaleech") end
        if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " and manaleech") end
        if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and manaleech") end
    else
        tarAffed("parasite", "healthleech", "manaleech")
        if applyAffV3 then applyAffV3("parasite"); applyAffV3("healthleech"); applyAffV3("manaleech") end
    end
end