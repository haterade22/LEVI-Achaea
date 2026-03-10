if target == matches[2] then
  if tAffs.blistered then
    magi.offense = magi.offense or {}
    magi.offense.state = magi.offense.state or {}
    magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 1, 5)
    tburns = magi.offense.state.burns -- backward compat
    tarAffed("burning")
    cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")
  elseif not tAffs.blistered then
    tarAffed("blistered")
    tempTimer(15, [[erAff("blistered")]])
    if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Blistered and Scalded") end
  end
end
  
  

 
