if isTargeted(matches[2]) then
	if haveAff("spiritburn") and haveAff("guilt") then
		tarAffed("inquisition")
		if applyAffV3 then applyAffV3("inquisition") end
		ataxia_boxEcho(target:upper().." HAS BEEN INQUISITIONED!", "LightSkyBlue")
		if inquisTimer then killTimer(inquisTimer); inquisTimer = nil end
		inquisTimer = tempTimer(20, [[ erAff("inquisition"); inquisTimer = nil ; if removeAffV3 then removeAffV3("inquisition") end]])
	end
end

