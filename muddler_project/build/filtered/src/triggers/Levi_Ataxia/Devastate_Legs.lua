if isTargeted(matches[2]) then

  if ataxiaTemp.fractures.torntendons >= 6 then
    tarAffed("mangledleftleg", "mangledrightleg", "prone")
  elseif ataxiaTemp.fractures.torntendons >= 4 then
    tarAffed("damagedleftleg", "damagedrightleg", "prone")
  else
    tarAffed("brokenleftleg", "brokenrightleg", "prone")
  end
  
  ataxiaTemp.fractures.torntendons = 0
  twohanded_legsHit()  
end