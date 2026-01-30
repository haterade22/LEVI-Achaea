--aconfig customprompt #grey@timestamp #white[#hcolour@health#white] #white[#mcolour@percentmana#white] #gold|@targetinfo#gold|[@affs] @paused

--Refer to 'Custom Prompt Aliases' folder for information on how this is setup. (click the folder itself)
--If you wish to reset the custom prompt, simply use ACONFIG CUSTOMPROMPT NONE or ACONFIG CUSTOMPROMPT CLEAR
--If you want to see what it is currently set to, use ACONFIG CUSTOMPROMPT SHOW
if matches[2] == "none" or matches[2] == "clear" then
	ataxia.settings.customprompt = ""	
	ataxiaEcho("No longer using a custom prompt.")
elseif matches[2] == "show" then
	ataxiaEcho("Custom prompt is currently set to: \n"..ataxia.settings.customprompt)
	clearCmdLine()
	appendCmdLine("aconfig customprompt "..ataxia.settings.customprompt)	
else
	ataxia.settings.customprompt = tostring(matches[2])
	ataxiaEcho("Custom prompt has been set to:  "..ataxia.settings.customprompt)
end
ataxia_saveSettings(false)