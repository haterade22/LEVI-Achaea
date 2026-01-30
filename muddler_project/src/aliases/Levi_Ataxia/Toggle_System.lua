if not matches[2] then
	ataxiaToggle()
else
	if matches[2] == "on" or matches[2] == "off" then
		ataxiaToggle(matches[2])
	else
		ataxiaEcho("Not a valid option. Please specify either on, or off.")
	end
end