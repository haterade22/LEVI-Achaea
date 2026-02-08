if isTargeted(matches[2]) then
	if ataxiaTemp.thfocus == "precision" then
    twohanded_increaseFracture("torntendons", 2)
	else
		twohanded_increaseFracture("torntendons", 1)
	end
  ataxiaTemp.lastLimbHit = matches[4].."leg"
  twohanded_legsHit()

  if not ataxia.vitals.bal then
    ataxia_setAffPrio("paralysis", 25)
    tempTimer(1, [[ ataxia_restorePrio("paralysis") ]])
  end 
end