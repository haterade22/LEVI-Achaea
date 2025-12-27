--[[mudlet
type: alias
name: Gag clot
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
regex: ^aconfig gagclot (on|off)$
command: ''
packageName: ''
]]--

local opt = matches[2]:lower()
ataxiaEcho((opt == "on" and "<green>Will" or "<red>Won't").."<NavajoWhite> gag clotting.")
if opt == "on" then
	ataxia.settings.gagclot = true
else
	ataxia.settings.gagclot = false
end
ataxia_saveSettings(false)