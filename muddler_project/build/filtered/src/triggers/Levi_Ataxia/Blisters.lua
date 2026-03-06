if isTargeted(matches[2]) then
  tarAffed("blistered", "burns")
  if applyAffV3 then applyAffV3("blistered"); applyAffV3("burns") end
  
  if ataxiaTemp.blisterTimer then killTimer(ataxiaTemp.blisterTimer) end
  ataxiaTemp.blisterTimer = tempTimer(15, [[ erAff("blistered"); ataxiaEcho("Target no longer has blisters.") ; if removeAffV3 then removeAffV3("blistered") end]])
end