if ataxiaTemp.firelord.brand >= 1 then
  selectString(line, 1)
  fg("DodgerBlue")
  deselect()
  ataxiaTemp.firelord.brand = nil
  ataxiaTemp.firelord.latency = tempTimer(10, [[ ataxiaTemp.firelord.latency = nil ]])
end