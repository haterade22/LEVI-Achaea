if isTargeted(matches[2]) then
	tarAffed("asphyxiation")
	if applyAffV3 then applyAffV3("asphyxiation") end
	if ataxiaTemp.asphyxTimer then killTimer( ataxiaTemp.asphyxTimer ) end
	ataxiaTemp.asphyxTimer = tempTimer(30, [[ erAff("asphyxiation"); ataxiaEcho("Target's no longer asphyxiated.") ; if removeAffV3 then removeAffV3("asphyxiation") end]])
end