if matches[2] == "disabled" then
	ataxia.settings.paused = true
else
	ataxia.settings.paused = false
end
deleteLine()
ataxiaEcho("System has been "..(ataxia.settings.paused and "<red>paused." or "<green>unpaused."))