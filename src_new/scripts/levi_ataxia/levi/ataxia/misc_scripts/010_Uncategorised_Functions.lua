--[[mudlet
type: script
name: Uncategorised Functions
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Misc Scripts
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function math.round(number, decimals) 
    decimals = decimals or 0 
    return tonumber(("%."..decimals.."f"):format(number))
end

-- Update the warning text kept by the @warning prompt tag

ataxiaTemp.warningText = ""

function ataxia_setWarning(message, duration)
  ataxiaTemp.warningText = "<a_blue>( <red>" .. message .. " <a_blue>) "
  if ataxiaTemp.warningTimer then killTimer(ataxiaTemp.warningTimer) end
  ataxiaTemp.warningTimer = tempTimer(duration, [[ataxiaTemp.warningTimer = nil; ataxiaTemp.warningText = ""]])
  
  ataxiaBasher_alert("Normal")

end

function ataxia_paused()
  if ataxia.settings.paused then
    return true
  else
    return false
  end
end