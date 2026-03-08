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
    tempTimer(15, [[erAff("blistered")]])
    if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Blistered and Scalded") end
  end
end
  
  

 
