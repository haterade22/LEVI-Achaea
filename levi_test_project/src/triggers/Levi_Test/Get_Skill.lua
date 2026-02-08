if not matches[1]:find("To gain further") then
	selectString(matches[2], 1)
	if isAnsiFgColor(16) then
		ataxiaTables.depthswalker.abilities[matches[2]:lower()] = true
	end
end

if updating_terminus_abilities then
	deleteLine()
end