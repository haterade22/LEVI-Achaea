if ataxiaBasher.cullingBlade then
	ataxiaBasher.cullingBlade = false
	ataxia_Echo("Will not use culling blade from now on.")
else
	ataxiaBasher.cullingBlade = true
	ataxia_Echo("Will use culling blade when we're able to, in areas with a set keyword.")
end
ataxia_saveSettings(false)