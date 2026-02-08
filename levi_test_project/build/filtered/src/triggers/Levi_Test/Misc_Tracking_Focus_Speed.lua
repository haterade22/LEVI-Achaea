if ataxiaBasher.enabled then
	deleteFull()
else
	selectString(line, 1)
	fg("NavajoWhite")
	deselect()
  
  
  if line:find("swift stroke") then
    ataxiaTemp.thfocus = "speed"
  else
    ataxiaTemp.thfocus = "precision"
  end
  tempTimer(2.8, [[ ataxiaTemp.thfocus = nil ]])
end