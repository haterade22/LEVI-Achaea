local cityFilter = matches[2] and matches[2]:title() or nil
local ivory = {}
local quisalis = {}

for player, tab in pairs(ataxiaNDB.players) do
	if tab.mark then
		if not cityFilter or tab.city == cityFilter then
			if tab.mark == "Ivory" then
				table.insert(ivory, player)
			elseif tab.mark == "Quisalis" then
				table.insert(quisalis, player)
			end
		end
	end
end

table.sort(ivory)
table.sort(quisalis)

local label = cityFilter and ("Tracked mark members from " .. cityFilter) or "All tracked mark members"
ataxiaEcho(label .. ":")

if #ivory > 0 then
	cecho("\n<NavajoWhite> Ivory Mark (" .. #ivory .. "): ")
	for _, name in ipairs(ivory) do
		cecho("<" .. ataxiaNDB_getColour(name) .. ">" .. name .. " ")
	end
end

if #quisalis > 0 then
	cecho("\n<purple> Quisalis Mark (" .. #quisalis .. "): ")
	for _, name in ipairs(quisalis) do
		cecho("<" .. ataxiaNDB_getColour(name) .. ">" .. name .. " ")
	end
end

if #ivory == 0 and #quisalis == 0 then
	cecho("\n <DimGrey>No mark members found.")
end

echo("\n ")
send(" ")
