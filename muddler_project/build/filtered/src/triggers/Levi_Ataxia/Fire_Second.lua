if target == matches[2] then
  if tAffs.scalded then
    magi.offense = magi.offense or {}
    magi.offense.state = magi.offense.state or {}
    magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 1, 5)
    tburns = magi.offense.state.burns -- backward compat
    tarAffed("burning")
  cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")
    if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Burning") end
  elseif not tAffs.scalded then
    tarAffed("scalded")
    if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Scalded") end
    tempTimer(20, [[erAff("scalded")]])
  end

  
end
  
 

