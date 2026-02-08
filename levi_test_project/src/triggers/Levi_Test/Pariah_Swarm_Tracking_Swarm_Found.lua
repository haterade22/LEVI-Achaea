if matches[5] == "Burrowed" then
  selectString(matches[5],1)
  fg("green")
  deselect()
  resetFormat()
  
  pariah.burrow = matches[2]
end