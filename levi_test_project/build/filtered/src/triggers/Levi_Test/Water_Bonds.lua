if isTargeted(matches[2]) then
	tarAffed("bonds")
	if applyAffV3 then applyAffV3("bonds") end
	
	if ataxiaTemp.bondsTimer then killTimer(ataxiaTemp.bondsTimer); ataxiaTemp.bondsTimer = nil end
	ataxiaTemp.bondsTimer = tempTimer(32, [[
		if haveAff("bonds") then
			erAff("bonds")
			if removeAffV3 then removeAffV3("bonds") end
			ataxia_boxEcho("Water bonds has faded from "..target, "purple")
		end
	]])
end