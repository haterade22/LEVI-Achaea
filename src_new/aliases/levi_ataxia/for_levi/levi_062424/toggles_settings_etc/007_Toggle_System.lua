--[[mudlet
type: alias
name: Toggle System
hierarchy:
- Levi_Ataxia
- Ataxia
- Config
- Toggles
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