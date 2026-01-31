if isTargeted(matches[2]) then
  tarAffed("blistered", "burns")
  
  if ataxiaTemp.blisterTimer then killTimer(ataxiaTemp.blisterTimer) end
  ataxiaTemp.blisterTimer = tempTimer(15, [[ erAff("blistered"); ataxiaEcho("Target no longer has blisters.") ]])
end