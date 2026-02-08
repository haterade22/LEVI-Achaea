if targetIshere then
  if tburns == 0 or nil then
      tburns = 1
  else
    tburns = tburns + 1
  end
end

magi.firestorm = gmcp.Room.Info.num
selectCurrentLine() fg("red")

cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")

