if target == matches[2] then
  if tAffs.epilepsy and tAffs.fulminated and not tAffs.paralysis then
    tarAffed("paralysis")
    if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Paralysis") end
  elseif not tAffs.epilepsy and tAffs.fulminated then
    tarAffed("epilepsy")
    if partyrelay and not ataxia.afflictions.aeon  then send("pt " ..target.. ": Epilepsy") end
  else 
  tarAffed("fulminated")
  if partyrelay and not ataxia.afflictions.aeon  then send("pt " ..target.. ": Fulminated") end
  end

end
  
 
