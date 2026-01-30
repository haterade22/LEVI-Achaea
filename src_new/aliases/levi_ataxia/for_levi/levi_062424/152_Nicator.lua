--[[mudlet
type: alias
name: Nicator
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Autobashing
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^nic$
command: ''
packageName: ''
]]--

if not ataxiaBasher.nicator then
	ataxiaBasher.nicator = true
	ataxiaEcho("Enabled automatic nicator usage.")
else
	ataxiaBasher.nicator = false
	ataxiaEcho("Disabled automatic nicator usage.")
end
ataxia_saveSettings(false)