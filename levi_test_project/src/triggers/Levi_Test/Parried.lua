if isTargeted(matches[2]) then
  if infernalDWC and infernalDWC.onParry then
        infernalDWC.onParry()
    end
    if infernalDWC2L and infernalDWC2L.onParry then
        infernalDWC2L.onParry()
    end
	tAffs.paralysis = nil
	tAffs.prone = nil
  tAffs.numbedleftarm = nil
	selectString(line, 1)
	fg("black")
	bg("DarkSlateBlue")
	resetFormat()
	
	if ataxia_isClass("Runewarden") or ataxia_isClass("Infernal") or ataxia_isClass("Paladin") or ataxia_isClass("Unnamable") then
		erAff("nausea")
		if removeAffV3 then removeAffV3("nausea") end
  elseif ataxia_isClass("Blademaster") then  
    if bmFistTimer then killTimer(bmFistTimer) end
		tAffs.airfist = nil           
	end
 -- if ataxiaTemp.lastLimbHit then
    --ataxiaTemp.parriedLimb = ataxiaTemp.lastLimbHit
    --cecho("<green> -> "..ataxiaTemp.parriedLimb) 
 -- end
end

-- Notify DWC vivisect systems of parry detection
-- Each system reads its own state.lastTargetedLimb to know which limb was parried

