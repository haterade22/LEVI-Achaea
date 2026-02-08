local option = matches[2]:title()
table.sort(ataxia.settings.lustlist)
if option ~= "List" and ataxiaNDB_Exists(option) then
	if table.contains(ataxia.settings.lustlist, option) then
		for n, p in pairs(ataxia.settings.lustlist) do
			if p == option then
				table.remove(ataxia.settings.lustlist, n)
				ataxiaEcho("Removed "..option.." from whitelist for lust.")
			end
		end
	else
		table.insert(ataxia.settings.lustlist, option)
		ataxiaEcho("Added "..option.." to whitelist for lust.")
	end
elseif option == "List" then
	ataxiaEcho("Current whitelisted people are:")
	cecho("\n  <a_darkcyan>"..table.concat(ataxia.settings.lustlist, ", ")..".")
else
	ataxiaEcho("That person doesn't exist. Honours them if this is wrong.")
end
ataxia_saveSettings(false)