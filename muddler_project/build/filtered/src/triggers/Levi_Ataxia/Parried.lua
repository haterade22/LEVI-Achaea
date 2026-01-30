if isTargeted(matches[2]) then
  
	tAffs.paralysis = nil
	tAffs.prone = nil
  tAffs.numbedleftarm = nil
	selectString(line, 1)
	fg("black")
	bg("DarkSlateBlue")
	resetFormat()
	
	if ataxia_isClass("Runewarden") or ataxia_isClass("Infernal") or ataxia_isClass("Paladin") or ataxia_isClass("Unnamable") then
		erAff("nausea")
  elseif ataxia_isClass("Blademaster") then  
    if bmFistTimer then killTimer(bmFistTimer) end
		tAffs.airfist = nil           
	end
 -- if ataxiaTemp.lastLimbHit then
    --ataxiaTemp.parriedLimb = ataxiaTemp.lastLimbHit
    --cecho("<green> -> "..ataxiaTemp.parriedLimb) 
 -- end
end