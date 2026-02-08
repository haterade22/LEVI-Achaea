local opt = matches[2]:lower()
ataxiaEcho((opt == "yes" and "<green>Will" or "<red>Won't").."<NavajoWhite> reset affs to default order on login.")
if opt == "yes" then
	ataxia.settings.resetonlogin = true
else
	ataxia.settings.resetonlogin = false
end
ataxia_saveSettings(false)