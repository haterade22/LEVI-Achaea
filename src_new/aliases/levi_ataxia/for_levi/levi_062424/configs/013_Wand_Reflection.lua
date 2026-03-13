--[[mudlet
type: alias
name: Wand Reflection
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^abwand(?:\s+(.+))?$
command: ''
packageName: ''
]]--

local arg = matches[2]

if arg and arg ~= "" then
	ataxiaBasher.wandId = arg
	ataxiaEcho("Wand of reflection ID set to: " .. arg)
	ataxia_saveSettings(false)
	return
end

if not ataxiaBasher.wandReflection then
	ataxiaBasher.wandReflection = true
	ataxiaEcho("Enabled wand of reflection emergency usage." .. (ataxiaBasher.wandId and (" Wand ID: " .. ataxiaBasher.wandId) or " (no wand ID set — use 'abwand <id>' to set)"))
else
	ataxiaBasher.wandReflection = false
	ataxia.wandReflectionActive = nil
	ataxia.wandReflectionCooldown = nil
	ataxiaEcho("Disabled wand of reflection emergency usage.")
end
ataxia_saveSettings(false)
