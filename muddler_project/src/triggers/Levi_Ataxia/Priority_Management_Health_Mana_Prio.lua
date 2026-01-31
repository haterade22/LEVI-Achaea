if matches[2] == "health" then
	ataxia.settings.priohealth = true
	deleteLine()
	ataxiaEcho("Will now prioritise <firebrick>health <NavajoWhite>over <LightSkyBlue>mana <NavajoWhite>for sipping.")
else
	ataxia.settings.priohealth = false
	deleteLine()
	ataxiaEcho("Will now prioritise <LightSkyBlue>mana <NavajoWhite>over <firebrick>health <NavajoWhite>for sipping.")
end