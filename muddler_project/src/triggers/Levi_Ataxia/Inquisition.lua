if isTargeted(matches[2]) then
	if haveAff("spiritburn") and haveAff("guilt") then
		tarAffed("inquisition")
		ataxia_boxEcho(target:upper().." HAS BEEN INQUISITIONED!", "LightSkyBlue")
		if inquisTimer then killTimer(inquisTimer); inquisTimer = nil end
		inquisTimer = tempTimer(20, [[ erAff("inquisition"); inquisTimer = nil ]])
	end
end

