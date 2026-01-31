--[[mudlet
type: alias
name: Install/Reset System
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Installation / Configuration
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^atinstall$
command: ''
packageName: ''
]]--

if not installSystem then
	installSystem = tempTimer(5, [[
		ataxiaEcho("System installation aborted.")
		installSystem = nil
	]])
	ataxiaEcho("This will reset the system, if you wish to do so, please use atinstall again.")
else
	ataxia_installSystem()
	killTimer(installSystem)
end

ataxia_saveSettings(false)
