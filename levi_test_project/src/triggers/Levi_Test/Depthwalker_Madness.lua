if isTargeted(matches[2]) then
    Target_Instill = "madness"
    -- Guard: get venom name safely (may be nil when using timeloop)
    local venomName = (envenomList and envenomList[1]) or "unknown"

    if not haveAff("shadowmadness") then
        tarAffed("shadowmadness")
        if applyAffV3 then applyAffV3("shadowmadness") end
        if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " and shadowmadness") end
        if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and shadowmadness") end
    elseif not haveAff("vertigo") then
        tarAffed("vertigo")
        if applyAffV3 then applyAffV3("vertigo") end
        if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " and vertigo") end
        if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and vertigo") end
    else
        tarAffed("hallucinations")
        if applyAffV3 then applyAffV3("hallucinations") end
        if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..venomName.. " and hallucinations") end
        if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and hallucinations") end
    end
end

