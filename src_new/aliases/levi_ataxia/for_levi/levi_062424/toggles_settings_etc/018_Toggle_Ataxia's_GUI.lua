--[[mudlet
type: alias
name: Toggle Ataxia's GUI
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
  isActive: 'no'
  isFolder: 'no'
regex: ^aconfig gui (on|off)$
command: ''
packageName: ''
]]--

if matches[2] == "on" then
  ataxiaEcho("Will use Ataxia's GUI. Make sure no others are installed.")
  ataxia.usegui = true
else
  ataxiaEcho("Will no longer use Ataxia's GUI.")
  ataxia.usegui = false
end
ataxiaEcho("Restarting Mudlet is required for this to update.")
ataxia_saveSettings(false)