--[[mudlet
type: alias
name: Blood Maiden Cloak
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bmc$
command: ''
packageName: ''
]]--

if not ataxiaBasher.bloodMaiden then
	ataxiaBasher.bloodMaiden = true
	ataxiaEcho("Enabled Blood Maiden cloak auto-activation.")
else
	ataxiaBasher.bloodMaiden = false
	ataxiaTemp.bloodshieldReady = nil
	ataxiaTemp.bloodshieldActive = nil
	if ataxiaTemp.bloodshieldTimer then
		killTimer(ataxiaTemp.bloodshieldTimer)
		ataxiaTemp.bloodshieldTimer = nil
	end
	ataxiaEcho("Disabled Blood Maiden cloak auto-activation.")
end
ataxia_saveSettings(false)
