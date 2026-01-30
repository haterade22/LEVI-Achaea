tAffs.burrow = false
  pariah.burrow = false

if pariah.infest then killTimer(pariah.infest) end
pariah.infest = tempTimer(13, [[ pariah.infest = nil ]])


  selectString(line,1)
  fg("orange")
  deselect()
  resetFormat()