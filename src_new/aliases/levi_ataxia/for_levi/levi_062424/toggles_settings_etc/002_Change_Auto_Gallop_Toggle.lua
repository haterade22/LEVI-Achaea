--[[mudlet
type: alias
name: Change Auto Gallop Toggle
hierarchy:
- Levi_Ataxia
- Ataxia
- Config
- Toggles
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^aconfig gallop (on|off)$
command: ''
packageName: ''
]]--

if matches[2] == "on" then
	ataxia.settings.autogallop = true
	ataxiaEcho("Will automatically toggle gallop when mounted.")
else
	ataxia.settings.autogallop = false
	ataxiaEcho("Won't automatically toggle gallop when mounted.")
end
ataxia_saveSettings(false)