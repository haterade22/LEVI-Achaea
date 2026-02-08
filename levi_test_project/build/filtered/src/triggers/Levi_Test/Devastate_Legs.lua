if isTargeted(matches[2]) then

  if ataxiaTemp.fractures.torntendons >= 6 then
    tarAffed("mangledleftleg", "mangledrightleg", "prone")
    if applyAffV3 then applyAffV3("mangledleftleg"); applyAffV3("mangledrightleg"); applyAffV3("prone") end
  elseif ataxiaTemp.fractures.torntendons >= 4 then
    tarAffed("damagedleftleg", "damagedrightleg", "prone")
    if applyAffV3 then applyAffV3("damagedleftleg"); applyAffV3("damagedrightleg"); applyAffV3("prone") end
  else
    tarAffed("brokenleftleg", "brokenrightleg", "prone")
    if applyAffV3 then applyAffV3("brokenleftleg"); applyAffV3("brokenrightleg"); applyAffV3("prone") end
  end
  
  ataxiaTemp.fractures.torntendons = 0
  twohanded_legsHit()  
end