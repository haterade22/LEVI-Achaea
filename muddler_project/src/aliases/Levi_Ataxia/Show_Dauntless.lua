local cityFilter = matches[2] and matches[2]:title() or nil
local members = {}

for player, tab in pairs(ataxiaNDB.players) do
	if tab.dauntless then
		if not cityFilter or tab.city == cityFilter then
			table.insert(members, player)
		end
	end
end

table.sort(members)

local label = cityFilter and ("Tracked Dauntless members from " .. cityFilter) or "All tracked Dauntless members"
ataxiaEcho(label .. " (" .. #members .. "):")

for _, name in ipairs(members) do
	cecho("\n <" .. ataxiaNDB_getColour(name) .. ">" .. name)
end

if #members == 0 then
	cecho("\n <DimGrey>No Dauntless members found.")
end

echo("\n ")
send(" ")
