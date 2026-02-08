if isTargeted(matches[2]) then
  if ataxiaTemp.randomCure and ataxiaTemp.randomCure > 0 then ataxiaTemp.randomCure = ataxiaTemp.randomCure - 1 end
	erAff("guilt")
	if removeAffV3 then removeAffV3("guilt") end
	targetIshere = true
end