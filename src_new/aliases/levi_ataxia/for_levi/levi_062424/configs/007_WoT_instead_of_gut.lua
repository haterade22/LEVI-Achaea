--[[mudlet
type: alias
name: WoT instead of gut
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
regex: ^aconfig wot$
command: ''
packageName: ''
]]--

if ataxiaBasher.jabBash then
  ataxiaBasher.jabBash = false
  ataxiaEcho("Disable the use of jab while in dragonform.")
end

if not ataxiaBasher.wotBash then
	ataxiaBasher.wotBash = true
	ataxiaEcho("Will use whip of taming instead of gut while in dragonform.")
else
	ataxiaBasher.wotBash = false
	ataxiaEcho("Returning to gutting while in dragonform.")
end
ataxia_saveSettings(false)