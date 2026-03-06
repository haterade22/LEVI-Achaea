--[[mudlet
type: alias
name: Configure Precache
hierarchy:
- Levi_Ataxia
- Ataxia
- Config
- Toggles
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^pconfig (\w+) (\d+)$
command: ''
packageName: ''
]]--

ataxia_precacheSet(matches[2], matches[3])

ataxia_saveSettings(false)