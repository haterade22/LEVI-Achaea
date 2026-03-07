local cityFilter = matches[2] and matches[2]:title() or nil
local marks = {}
local army = {}
local dauntless = {}

for player, tab in pairs(ataxiaNDB.players) do
	if not cityFilter or tab.city == cityFilter then
		if tab.mark then
			table.insert(marks, {name = player, mark = tab.mark})
		end
		if tab.armyRank and tab.armyRank >= 3 then
			table.insert(army, {name = player, rank = tab.armyRank})
		end
		if tab.dauntless then
			table.insert(dauntless, player)
		end
	end
end

table.sort(marks, function(a, b) return a.name < b.name end)
table.sort(army, function(a, b) return a.rank > b.rank end)
table.sort(dauntless)

local label = cityFilter and ("Threat overview for " .. cityFilter) or "Threat overview (all cities)"
ataxiaEcho(label .. ":")

cecho("\n<red> Marks (" .. #marks .. "):")
if #marks > 0 then
	for _, m in ipairs(marks) do
		local mColour = m.mark == "Ivory" and "NavajoWhite" or "purple"
		cecho("\n   <" .. ataxiaNDB_getColour(m.name) .. ">" .. m.name ..
			string.rep(" ", math.max(0, 16 - string.len(m.name))) ..
			"<" .. mColour .. ">" .. m.mark)
	end
else
	cecho(" <DimGrey>None")
end

cecho("\n<red> Army Rank 3+ (" .. #army .. "):")
if #army > 0 then
	for _, s in ipairs(army) do
		cecho("\n   <" .. ataxiaNDB_getColour(s.name) .. ">" .. s.name ..
			string.rep(" ", math.max(0, 16 - string.len(s.name))) ..
			"<red>Rank " .. s.rank)
	end
else
	cecho(" <DimGrey>None")
end

cecho("\n<red> Dauntless (" .. #dauntless .. "):")
if #dauntless > 0 then
	for _, name in ipairs(dauntless) do
		cecho("\n   <" .. ataxiaNDB_getColour(name) .. ">" .. name)
	end
else
	cecho(" <DimGrey>None")
end

echo("\n ")
send(" ")
