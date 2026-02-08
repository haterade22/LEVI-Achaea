local opt = matches[2]:lower()
ataxiaEcho((opt == "on" and "<green>Will" or "<red>Won't").."<NavajoWhite> gag clotting.")
if opt == "on" then
	ataxia.settings.gagclot = true
else
	ataxia.settings.gagclot = false
end
ataxia_saveSettings(false)