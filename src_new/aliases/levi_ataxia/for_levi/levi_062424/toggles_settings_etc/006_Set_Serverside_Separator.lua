--[[mudlet
type: alias
name: Set Serverside Separator
hierarchy:
- Levi_Ataxia
- Ataxia
- Config
- Toggles
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

