--[[mudlet
type: alias
name: Toggle Monk Bashing
hierarchy:
- Levi_Ataxia
- Ataxia
- Config
- Toggles
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