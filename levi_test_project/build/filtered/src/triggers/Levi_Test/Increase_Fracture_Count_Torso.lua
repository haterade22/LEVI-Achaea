if isTargeted(matches[2]) then
	if ataxiaTemp.thfocus == "precision" then
    twohanded_increaseFracture("crackedribs", 2)
	else
		twohanded_increaseFracture("crackedribs", 1)
	end
  ataxiaTemp.lastLimbHit = "torso"
  twohanded_torsoHit()

  if not ataxia.vitals.bal then
    ataxia_setAffPrio("paralysis", 25)
    tempTimer(1, [[ ataxia_restorePrio("paralysis") ]])
  end 
end