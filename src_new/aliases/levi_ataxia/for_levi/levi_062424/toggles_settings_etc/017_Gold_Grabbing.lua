--[[mudlet
type: alias
name: Gold Grabbing
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
regex: ^aconfig goldgrab (.+)$
command: ''
packageName: ''
]]--

ataxia.settings.goldcommand = matches[2]
ataxiaEcho("When gold drops, will queue: "..ataxia.settings.goldcommand)
ataxiaEcho("This does not affect prosperian attractor, only dropped gold.")
ataxia_saveSettings(false)