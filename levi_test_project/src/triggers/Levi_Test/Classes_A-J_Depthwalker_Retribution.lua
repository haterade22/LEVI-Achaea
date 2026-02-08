if isTargeted(matches[2]) then
    Target_Instill = "retribution"
    -- Guard: get venom name safely (may be nil when using timeloop)
    local venomName = (envenomList and envenomList[1]) or "unknown"

    if not haveAff("justice") then
        tarAffed("justice")
        if applyAffV3 then applyAffV3("justice") end
        if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " and justice") end
        if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and justice") end
    else
        tarAffed("retribution")
        if applyAffV3 then applyAffV3("retribution") end
        if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " and retribution") end
        if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and retribution") end
    end
end
