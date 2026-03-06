local x = ataxia.settings.roomshorten

if gmcp.Room.Info.name:lower():find(matches[2]:lower()) then
	if (x == "notmanual" and ataxiaBasher.manual ~= true) or (x == "normal") then
		roomDeleting = true
		deleteLine()
	end
end