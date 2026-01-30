--[[mudlet
type: alias
name: Morimbuul Card
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
regex: ^aconfig morim$
command: ''
packageName: ''
]]--

if not ataxiaBasher.morimbuul then
	ataxiaBasher.morimbuul = true
	ataxiaEcho("Will use LDECK Morimbuul for anti-webbing from mobs.")
else
	ataxiaBasher.morimbuul = false
	ataxiaEcho("Will NOT use LDECK Morimbuul for anti-webbing from mobs")
end
ataxia_saveSettings(false)



    