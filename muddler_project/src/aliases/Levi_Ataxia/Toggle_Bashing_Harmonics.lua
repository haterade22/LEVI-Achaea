--Automatically turns on symphony if it's not already enabled.
if not ataxia_isClass("bard") then
	ataxiaEcho("Class is not currently bard.")
	return
end

if ataxia.bardStuff.bashHarms then
	ataxia.bardStuff.bashHarms = false
	ataxiaEcho("Bashing harmonics disabled.")
else
	ataxia.bardStuff.bashHarms = true
	ataxia.bardStuff.symphony = true
	ataxiaEcho("Bashing harmonics enabled.")
end

ataxia_saveSettings(false)