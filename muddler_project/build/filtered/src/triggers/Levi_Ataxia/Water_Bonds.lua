if isTargeted(matches[2]) then
	tarAffed("bonds")
	
	if ataxiaTemp.bondsTimer then killTimer(ataxiaTemp.bondsTimer); ataxiaTemp.bondsTimer = nil end
	ataxiaTemp.bondsTimer = tempTimer(32, [[
		if haveAff("bonds") then
			erAff("bonds")
			ataxia_boxEcho("Water bonds has faded from "..target, "purple")
		end
	]])
end