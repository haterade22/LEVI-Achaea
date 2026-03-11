if target == matches[2] then

  if tAffs.weariness and tAffs.nausea then
      magi.offense = magi.offense or {}
      magi.offense.state = magi.offense.state or {}
      magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 1, 5)
      tburns = magi.offense.state.burns -- backward compat
      tarAffed("burning")
      cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")
  end

  if not tAffs.weariness and not tAffs.nausea then
   tarAffed("weariness")
   tarAffed("nausea")
  end

  if not tAffs.weariness and tAffs.nausea and not tAffs.shivering and tAffs.nocaloric then
    tarAffed("weariness")
    tarAffed("shivering")
  elseif not tAffs.weariness and tAffs.nausea and not tAffs.nocaloric then
    tarAffed("weariness")
    tarAffed("nocaloric")
  elseif not tAffs.weariness and tAffs.nausea and tAffs.shivering and tAffs.nocaloric and not tAffs.frozen then
    tarAffed("frozen")
    tarAffed("weariness")
  end

  if not tAffs.nausea and tAffs.weariness then
    magi.offense = magi.offense or {}
    magi.offense.state = magi.offense.state or {}
    magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 1, 5)
    tburns = magi.offense.state.burns -- backward compat
    tarAffed("burning")
    tarAffed("frozen")
    tarAffed("nausea")
    haveAff("weariness")
    cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")
  end
  if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": weariness and nausea") end
end



   
   
