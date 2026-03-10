if targetIshere then
  magi.offense = magi.offense or {}
  magi.offense.state = magi.offense.state or {}
  magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 1, 5)
  tburns = magi.offense.state.burns -- backward compat
  tarAffed("burning")
end

magi.firestorm = gmcp.Room.Info.num
selectCurrentLine() fg("red")

cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")

