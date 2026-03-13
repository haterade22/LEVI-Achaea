--[[mudlet
type: alias
name: Gem Cloaking
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^abgcuse$
command: ''
packageName: ''
]]--

if not ataxiaBasher.gemCloaking then
	ataxiaBasher.gemCloaking = true
	ataxiaEcho("Enabled gem of cloaking auto-activation in Moghedu.")
else
	ataxiaBasher.gemCloaking = false
	ataxiaEcho("Disabled gem of cloaking auto-activation in Moghedu.")
end
ataxia_saveSettings(false)
