local slot = matches[2]:lower()
slot = slot:title()
local tat = matches[3]:title()
local cge = matches[4]
local act = matches[5]
for i,v in pairs(tattoosOnMe) do
	if i == slot then
		if tattoosOnMe[i][1] ~= "empty" and #tattoosOnMe[i][1] == 0 then
			tattoosOnMe[i][1] = {tat, cge, act}
		else
			tattoosOnMe[i][2] = {tat, cge, act}
		end
		break
	end
end

if table.contains(crucialTattoos, tat) then
	table.remove(crucialTattoos, table.index_of(crucialTattoos, tat))
end
deleteLine()