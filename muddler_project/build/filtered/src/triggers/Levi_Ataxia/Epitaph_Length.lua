ataxia.vitals.epitaph = tonumber(matches[2])
if ataxiaBasher.enabled then
  if not ataxiaBasher.manual then
    deleteFull()
  end
else
  selectString(line, 1)
  if ataxia.vitals.epitaph < 2 then
    fg("DimGrey")
    pariah.expose = false
  else
    fg("DarkSlateGrey")
    pariah.expose = true
  end
  deselect()
  resetFormat()
end
