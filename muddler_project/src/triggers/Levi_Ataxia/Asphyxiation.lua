if isTargeted(matches[2]) then
	tarAffed("asphyxiation")
	if ataxiaTemp.asphyxTimer then killTimer( ataxiaTemp.asphyxTimer ) end
	ataxiaTemp.asphyxTimer = tempTimer(30, [[ erAff("asphyxiation"); ataxiaEcho("Target's no longer asphyxiated.") ]])
end