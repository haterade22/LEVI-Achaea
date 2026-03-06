if target == matches[2] then
  if tAffs.epilepsy and tAffs.fulminated and not tAffs.paralysis then
    tarAffed("paralysis")
    if applyAffV3 then applyAffV3("paralysis") end
    if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Paralysis") end
  elseif not tAffs.epilepsy and tAffs.fulminated then
    tarAffed("epilepsy")
    if applyAffV3 then applyAffV3("epilepsy") end
    if partyrelay and not ataxia.afflictions.aeon  then send("pt " ..target.. ": Epilepsy") end
  else
  tarAffed("fulminated")
  if applyAffV3 then applyAffV3("fulminated") end
  if partyrelay and not ataxia.afflictions.aeon  then send("pt " ..target.. ": Fulminated") end
  end

end
  
 
