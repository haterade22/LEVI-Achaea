if not ataxiaBasher.nicator then
	ataxiaBasher.nicator = true
	ataxiaEcho("Enabled automatic nicator usage.")
else
	ataxiaBasher.nicator = false
	ataxiaEcho("Disabled automatic nicator usage.")
end
ataxia_saveSettings(false)