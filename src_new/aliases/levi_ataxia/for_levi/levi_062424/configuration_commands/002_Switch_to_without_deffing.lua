--[[mudlet
type: alias
name: Switch to without deffing
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Defence Stuff
- Configuration Commands
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^defswitch (\w+)$
command: ''
packageName: ''
]]--

local profile = matches[2]
if ataxia.settings.defences.defup[profile] then
	ataxia.settings.defences.current = matches[2]
	ataxia_Echo("Switched to the "..profile.." profile. Will not defup until instructed.")
elseif profile == "none" then
	systemDefup("none")
else
	ataxiaEcho("That profile does not exist.")
end