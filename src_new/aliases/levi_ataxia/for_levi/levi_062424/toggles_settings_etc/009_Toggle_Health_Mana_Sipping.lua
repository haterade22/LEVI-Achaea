--[[mudlet
type: alias
name: Toggle Health/Mana Sipping
hierarchy:
- Levi_Ataxia
- Ataxia
- Config
- Toggles
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^hh$
command: ''
packageName: ''
]]--

if ataxia.settings.priohealth then
	ataxia.settings.priohealth = false
	send("curing priority mana",false)
else
	ataxia.settings.priohealth = true
	send("curing priority health",false)
end