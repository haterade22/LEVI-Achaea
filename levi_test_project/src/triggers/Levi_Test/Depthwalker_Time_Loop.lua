if isTargeted(matches[2]) then
	checkTimeloop = true
	tarAffed("timeloop")
	if applyAffV3 then applyAffV3("timeloop") end
  erAff("haemophilia")
  if removeAffV3 then removeAffV3("haemophilia") end
  tloop = false
  tloop2 = false
  erAff("paralysis")
  if removeAffV3 then removeAffV3("paralysis") end
end