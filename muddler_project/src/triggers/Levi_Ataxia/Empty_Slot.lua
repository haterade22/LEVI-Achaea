local slot = matches[2]:lower()
slot = slot:title()
for i,v in pairs(tattoosOnMe) do
	if i == slot then
		if #tattoosOnMe[i][1] == 0 then
			tattoosOnMe[i][1] = "empty"
		else
			tattoosOnMe[i][2] = "empty"
		end
		break
	end
end
deleteLine()