if target == matches[2] then
  if tAffs.scalded then
    if tburns == 0 or nil then
     tburns = 1
    else
    tburns = tburns + 1
    end
  cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")
    if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Burning") end
  elseif not tAffs.scalded then
    tarAffed("scalded")
    if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Scalded") end
    tempTimer(20, [[erAff("scalded")]])
  end

  
end
  
 

