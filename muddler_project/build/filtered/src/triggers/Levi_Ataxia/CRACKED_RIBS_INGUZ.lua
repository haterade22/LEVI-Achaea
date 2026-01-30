if isTargeted(matches[3]) then

		twohanded_increaseFracture("crackedribs", 1)

  if not ataxia.vitals.bal then
    ataxia_setAffPrio("paralysis", 25)
    tempTimer(1, [[ ataxia_restorePrio("paralysis") ]])
  end 
end