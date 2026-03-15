--[[mudlet
type: alias
name: Switch to without deffing
hierarchy:
- Levi_Ataxia
- Ataxia
- Defence Config
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^defswitch (\w+)$
command: ''
packageName: ''
]]--

if not ataxia.settings or not ataxia.settings.defences then ataxiaEcho("Settings not loaded yet.") return end
local profile = matches[2]
if ataxia.settings.defences.defup[profile] then
	ataxia.settings.defences.current = matches[2]
	ataxia_Echo("Switched to the "..profile.." profile. Will not defup until instructed.")
elseif profile == "none" then
	systemDefup("none")
else
	ataxiaEcho("That profile does not exist.")
end