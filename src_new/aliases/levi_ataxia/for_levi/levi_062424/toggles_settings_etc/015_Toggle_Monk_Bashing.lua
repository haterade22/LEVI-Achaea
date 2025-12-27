--[[mudlet
type: alias
name: Toggle Monk Bashing
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Installation / Configuration
- Toggles/Settings/Etc.
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^aconfig monk$
command: ''
packageName: ''
]]--

if ataxia.settings.crushbash then
  ataxia.settings.crushbash = false
  ataxiaEcho("No longer bashing with mind crush/DRS.")
else
  ataxia.settings.crushbash = true
  ataxiaEcho("Will use mind crush/DRS for bashing now.")
end
ataxia_saveSettings(false)
send(" ")