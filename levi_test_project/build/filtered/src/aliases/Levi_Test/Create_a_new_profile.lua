local profile = matches[3]
local option = matches[2]

if option == "create" then
	if not ataxia.settings.defences.defup[profile] then
		ataxia.settings.defences.defup[profile] = {}
		ataxia.settings.defences.keepup[profile] = {}
		ataxiaEcho("Created a new defup profile with id of "..profile..".")
	else
		ataxiaEcho("That profile already exists. Remove it, if you wish to start it over.")
	end
else
	if ataxia.settings.defences.defup[profile] then
		ataxia.settings.defences.defup[profile] = nil
		ataxia.settings.defences.keepup[profile] = nil
		ataxiaEcho("Removed the "..profile.." profile.")
	else
		ataxiaEcho("That profile doesn't exist.")
	end
end
	
ataxia_saveSettings(false)