if target == matches[2] then
  if tAffs.blistered then
    if tburns == 0 or nil then
      tburns = 1
    else
      tburns = tburns + 1
    end
    cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")
  elseif not tAffs.blistered then
    tarAffed("blistered")
    if applyAffV3 then applyAffV3("blistered") end
    tempTimer(15, [[erAff("blistered"); if removeAffV3 then removeAffV3("blistered") end]])
    if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Blistered and Scalded") end
  end
end
  
  

 
