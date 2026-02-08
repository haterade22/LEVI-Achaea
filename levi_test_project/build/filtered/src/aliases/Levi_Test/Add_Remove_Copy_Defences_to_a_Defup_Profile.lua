local profile = ataxia.settings.defences.current

if profile == "none" or profile == nil then
	ataxiaEcho("Not currently in a defup profile. Please switch to one first.")
	return
elseif not ataxia.settings.defences.defup[profile] then
	ataxia.settings.defences.defup[profile] = {}
end

local def = matches[3]
if matches[2] == "add" then
	if not ataxia.settings.defences.defup[profile] then
		ataxiaEcho("Your current defup is set to "..profile.." and we don't have a defup profile for that yet.")
	elseif not supportedDefence(def) then
		ataxiaEcho("That defence is not currently supported, sorry.")
	elseif ataxia.settings.defences.defup[profile][def] then
		ataxiaEcho("That defence is already in this profile.")
	else
		addToDefup(def)
	end
elseif matches[2] == "copy" then
	if not ataxia.settings.defences.defup[profile] then
		ataxiaEcho("Your current defup is set to "..profile.." and we don't have a defup profile for that yet.")
	elseif not ataxia.settings.defences.defup[matches[3]] then
		ataxiaEcho("Specified profile of "..matches[3].." does not exist!")
	else
		for def,val in pairs(ataxia.settings.defences.defup[matches[3]]) do
			ataxia.settings.defences.defup[profile][def] = true
			ataxiaEcho("Copied "..def.." to the "..profile.." defup profile.")
		end
	end	
else
	if not ataxia.settings.defences.defup[profile] then
		ataxiaEcho("Your current defup is set to "..profile.." and we don't have a defup profile for that yet.")
	elseif not ataxia.settings.defences.defup[profile][def] then
		ataxiaEcho("That defence is already not included in the defup profile.")
	else
		ataxia.settings.defences.defup[profile][def] = nil
		ataxiaEcho("Removed <white>"..def.." from <green>"..profile.."<white>'s defence list.")
	end
end

ataxia_saveSettings(false)