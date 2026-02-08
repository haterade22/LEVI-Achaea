if ataxiaTemp.percussiaTiming then
  ataxiaTemp.percussiaTiming = tonumber(ataxiaTemp.percussiaTiming)
  ataxiaTemp.percussiaTimer = tempTimer(ataxiaTemp.percussiaTiming-0.25, [[ ataxiaTemp.percussiaTimer = nil ]])
  ataxiaTemp.percussiaTiming = nil
  
  selectString(line,1)
  fg("NavyBlue")
  bg("DarkOrchid")
end