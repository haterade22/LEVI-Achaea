if ataxia.bardStuff.ariaBash then
	ataxia.bardStuff.ariaBash = false
	ataxiaEcho("Won't keep aria up while bashing anymore.")
else
	ataxia.bardStuff.ariaBash = true
	ataxiaEcho("Keeping aria up while bashing; toggling deafness off while bashing.")
end

ataxia_saveSettings(false)