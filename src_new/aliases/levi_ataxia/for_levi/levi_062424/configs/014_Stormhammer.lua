--[[mudlet
type: alias
name: Stormhammer
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^abshuse$
command: ''
packageName: ''
]]--

if not ataxiaBasher.stormhammer then
	ataxiaBasher.stormhammer = true
	ataxiaEcho("Enabled stormhammer multi-target bashing.")
else
	ataxiaBasher.stormhammer = false
	ataxiaEcho("Disabled stormhammer multi-target bashing.")
end
ataxia_saveSettings(false)
