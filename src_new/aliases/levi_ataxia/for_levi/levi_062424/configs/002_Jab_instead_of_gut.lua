--[[mudlet
type: alias
name: Jab instead of gut
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^aconfig jab$
command: ''
packageName: ''
]]--

if not ataxiaBasher.jabBash then
	ataxiaBasher.jabBash = true
	ataxiaEcho("Will jab instead of gut while in dragonform.")
else
	ataxiaBasher.jabBash = false
	ataxiaEcho("Returning to gutting while in dragonform.")
end
ataxia_saveSettings(false)



    