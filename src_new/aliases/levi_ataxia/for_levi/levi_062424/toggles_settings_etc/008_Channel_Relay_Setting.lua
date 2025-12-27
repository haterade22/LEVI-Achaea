--[[mudlet
type: alias
name: Channel Relay Setting
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
regex: ^aconfig relay (.+)$
command: ''
packageName: ''
]]--

if matches[2] == "off" or matches[2] == "false" then
	ataxia.settings.relayingto = false
	ataxiaEcho("Disabled callouts for messages.")
else
	ataxia.settings.relayingto = matches[2]
	ataxiaEcho("Will now relay messages with "..matches[2].." <message>.")
end
ataxia_saveSettings(false)