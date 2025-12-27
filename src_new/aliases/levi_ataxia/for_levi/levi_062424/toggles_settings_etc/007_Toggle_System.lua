--[[mudlet
type: alias
name: Toggle System
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
regex: '^pp(?: (\w+)|)$'
command: ''
packageName: ''
]]--

if not matches[2] then
	ataxiaToggle()
else
	if matches[2] == "on" or matches[2] == "off" then
		ataxiaToggle(matches[2])
	else
		ataxiaEcho("Not a valid option. Please specify either on, or off.")
	end
end