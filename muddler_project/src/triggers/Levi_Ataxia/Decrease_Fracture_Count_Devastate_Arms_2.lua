if isTargeted(matches[3]) then

  if ataxiaTemp.fractures.torntendons >= 6 then
    tarAffed("mangledleftarm", "mangledrightarm")
  elseif ataxiaTemp.fractures.torntendons >= 4 then
    tarAffed("damagedleftarm", "damagedrightarm")
  else
    tarAffed("brokenleftarm", "brokenrightarm")
  end
  
  ataxiaTemp.fractures.wristfractures = 0
  twohanded_armsHit()  
end