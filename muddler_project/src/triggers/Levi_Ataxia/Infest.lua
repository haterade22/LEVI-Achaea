tAffs.burrow = false
  if removeAffV3 then removeAffV3("burrow") end
  pariah.burrow = false

if pariah.infest then killTimer(pariah.infest) end
pariah.infest = tempTimer(13, [[ pariah.infest = nil ]])


  selectString(line,1)
  fg("orange")
  deselect()
  resetFormat()