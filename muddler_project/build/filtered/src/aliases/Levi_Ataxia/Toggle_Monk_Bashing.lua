if ataxia.settings.crushbash then
  ataxia.settings.crushbash = false
  ataxiaEcho("No longer bashing with mind crush/DRS.")
else
  ataxia.settings.crushbash = true
  ataxiaEcho("Will use mind crush/DRS for bashing now.")
end
ataxia_saveSettings(false)
send(" ")