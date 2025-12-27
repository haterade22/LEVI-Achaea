--[[mudlet
type: alias
name: Set Serverside Separator
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
regex: ^aconfig separator (.+)$
command: ''
packageName: ''
]]--

ataxia.settings.separator = matches[2]
ataxiaEcho("Will now use "..ataxia.settings.separator.." as our separator.")
ataxia_saveSettings(false)

