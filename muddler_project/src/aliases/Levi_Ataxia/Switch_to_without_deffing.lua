local profile = matches[2]
if ataxia.settings.defences.defup[profile] then
	ataxia.settings.defences.current = matches[2]
	ataxia_Echo("Switched to the "..profile.." profile. Will not defup until instructed.")
elseif profile == "none" then
	systemDefup("none")
else
	ataxiaEcho("That profile does not exist.")
end