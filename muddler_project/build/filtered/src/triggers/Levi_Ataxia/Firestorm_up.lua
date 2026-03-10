if target == matches[2] then
selectCurrentLine() fg("red")
  magi.offense = magi.offense or {}
  magi.offense.state = magi.offense.state or {}
  magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 1, 5)
  tburns = magi.offense.state.burns -- backward compat
  tAffs.burns = tburns
  tarAffed("burning")
cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")
end

if not magi.firestorm then
  magi.firestorm = gmcp.Room.Info.num
end

magi.firestormm = true

tarAffed("firestorm")