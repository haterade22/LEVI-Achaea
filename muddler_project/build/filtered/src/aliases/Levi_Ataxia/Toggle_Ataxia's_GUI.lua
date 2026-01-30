if matches[2] == "on" then
  ataxiaEcho("Will use Ataxia's GUI. Make sure no others are installed.")
  ataxia.usegui = true
else
  ataxiaEcho("Will no longer use Ataxia's GUI.")
  ataxia.usegui = false
end
ataxiaEcho("Restarting Mudlet is required for this to update.")
ataxia_saveSettings(false)