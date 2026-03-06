if isTargeted(matches[2]) then
  if ataxiaTemp.randomCure and ataxiaTemp.randomCure > 0 then ataxiaTemp.randomCure = ataxiaTemp.randomCure - 1 end
	erAff("unweavingmind")
	if removeAffV3 then removeAffV3("unweavingmind") end
	erAff("criticalmind")
	if removeAffV3 then removeAffV3("criticalmind") end
	targetIshere = true
end

tAffs.criticalmind = false
mindinvert = false
inverted = false