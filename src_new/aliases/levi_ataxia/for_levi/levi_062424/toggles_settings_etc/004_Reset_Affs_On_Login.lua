--[[mudlet
type: alias
name: Reset Affs On Login
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
regex: ^aconfig resetaffs (yes|no)$
command: ''
packageName: ''
]]--

local opt = matches[2]:lower()
ataxiaEcho((opt == "yes" and "<green>Will" or "<red>Won't").."<NavajoWhite> reset affs to default order on login.")
if opt == "yes" then
	ataxia.settings.resetonlogin = true
else
	ataxia.settings.resetonlogin = false
end
ataxia_saveSettings(false)