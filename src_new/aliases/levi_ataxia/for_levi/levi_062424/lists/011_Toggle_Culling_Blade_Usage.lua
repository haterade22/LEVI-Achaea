--[[mudlet
type: alias
name: Toggle Culling Blade Usage
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Lists
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^cbuse$
command: ''
packageName: ''
]]--

if ataxiaBasher.cullingBlade then
	ataxiaBasher.cullingBlade = false
	ataxia_Echo("Will not use culling blade from now on.")
else
	ataxiaBasher.cullingBlade = true
	ataxia_Echo("Will use culling blade when we're able to.")
end
ataxia_saveSettings(false)