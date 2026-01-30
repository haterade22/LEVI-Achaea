if ataxia.settings.priohealth then
	ataxia.settings.priohealth = false
	send("curing priority mana",false)
else
	ataxia.settings.priohealth = true
	send("curing priority health",false)
end