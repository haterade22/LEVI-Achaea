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
	ataxiaEcho("Enabled wand of reflection emergency usage." .. (ataxiaBasher.wandId and (" Wand ID: " .. ataxiaBasher.wandId) or " (no wand ID set -- use 'abwand <id>' to set)"))
else
	ataxiaBasher.wandReflection = false
	-- Transient state moved to ataxiaTemp in v4.7.194 (it was being serialized with
	-- `ataxia`, so an hour-long cooldown survived a reload with no timer left to clear it).
	-- The two `ataxia.*` nils stay for one release to scrub the key off existing saves.
	ataxia.wandReflectionActive = nil
	ataxia.wandReflectionCooldown = nil
	if ataxiaTemp then
		ataxiaTemp.wandReflectActive, ataxiaTemp.wandReflectAt = nil, nil
	end
	ataxiaEcho("Disabled wand of reflection emergency usage.")
end
ataxia_saveSettings(false)
