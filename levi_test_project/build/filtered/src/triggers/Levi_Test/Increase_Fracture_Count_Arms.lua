if isTargeted(matches[3]) then
	if ataxiaTemp.thfocus == "precision" then
    twohanded_increaseFracture("wristfractures", 2)
	else
		twohanded_increaseFracture("wristfractures", 1)
	end
  ataxiaTemp.lastLimbHit = matches[2].."arm"
  twohanded_armsHit()
  
  if not ataxia.vitals.bal then
    ataxia_setAffPrio("paralysis", 25)
    tempTimer(1, [[ ataxia_restorePrio("paralysis") ]])
  end
end