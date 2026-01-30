if not ataxia_isClass("bard") then
	ataxiaEcho("Class is not currently bard.")
	return
end

if ataxia.bardStuff.symphony then
	ataxiaEcho("Symphony usage disabled.")
	ataxia.bardStuff.symphony = false
else
	ataxiaEcho("Symphony usage enabled.")
	ataxia.bardStuff.symphony = true
end

ataxia_saveSettings(false)