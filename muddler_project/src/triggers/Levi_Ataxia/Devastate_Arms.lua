if isTargeted(matches[3]) then

  if ataxiaTemp.fractures.torntendons >= 6 then
    tarAffed("mangledleftarm", "mangledrightarm")
    if applyAffV3 then applyAffV3("mangledleftarm"); applyAffV3("mangledrightarm") end
  elseif ataxiaTemp.fractures.torntendons >= 4 then
    tarAffed("damagedleftarm", "damagedrightarm")
    if applyAffV3 then applyAffV3("damagedleftarm"); applyAffV3("damagedrightarm") end
  else
    tarAffed("brokenleftarm", "brokenrightarm")
    if applyAffV3 then applyAffV3("brokenleftarm"); applyAffV3("brokenrightarm") end
  end
  
  ataxiaTemp.fractures.wristfractures = 0
  twohanded_armsHit()  
end