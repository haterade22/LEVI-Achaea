if isTargeted(matches[2]) then
  if ataxiaTemp.randomCure and ataxiaTemp.randomCure > 0 then ataxiaTemp.randomCure = ataxiaTemp.randomCure - 1 end
	erAff("unweavingbody")
	if removeAffV3 then removeAffV3("unweavingbody") end
	erAff("criticalbody")
	if removeAffV3 then removeAffV3("criticalbody") end
	targetIshere = true
end

bodyinvert = false
inverted = false
