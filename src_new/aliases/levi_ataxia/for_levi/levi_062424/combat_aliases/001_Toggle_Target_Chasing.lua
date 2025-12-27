--[[mudlet
type: alias
name: Toggle Target Chasing
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Combat Aliases
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^tch$
command: ''
packageName: ''
]]--

if chasing_Targets then chasing_Targets = false else chasing_Targets = true end
ataxiaEcho("Target chasing has been "..(chasing_Targets and "<green>Enabled." or "<red>Disabled."))