if isTargeted(matches[2]) then
	if ataxiaTemp.thfocus == "precision" then
    twohanded_increaseFracture("skullfractures", 2)
	else
		twohanded_increaseFracture("skullfractures", 1)
	end
  ataxiaTemp.lastLimbHit = "head"
  twohanded_headHit()
  
  if not ataxia.vitals.bal then
    ataxia_setAffPrio("paralysis", 25)
    tempTimer(1, [[ ataxia_restorePrio("paralysis") ]])
  end
end