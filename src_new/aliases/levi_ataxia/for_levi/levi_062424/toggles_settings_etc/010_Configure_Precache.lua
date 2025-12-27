--[[mudlet
type: alias
name: Configure Precache
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
regex: ^pconfig (\w+) (\d+)$
command: ''
packageName: ''
]]--

ataxia_precacheSet(matches[2], matches[3])

ataxia_saveSettings(false)