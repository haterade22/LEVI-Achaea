--[[mudlet
type: alias
name: Show Army
hierarchy:
- Levi_Ataxia
- Ataxia
- NDB
- Actions
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^an army(?: (\w+)|)$'
command: ''
packageName: ''
]]--

local cityFilter = matches[2] and matches[2]:title() or nil
local soldiers = {}

for player, tab in pairs(ataxiaNDB.players) do
	if tab.armyRank and tab.armyRank > 0 then
		if not cityFilter or tab.city == cityFilter then
			table.insert(soldiers, {name = player, rank = tab.armyRank, city = tab.city})
		end
	end
end

table.sort(soldiers, function(a, b) return a.rank > b.rank end)

local label = cityFilter and ("Tracked army members from " .. cityFilter) or "All tracked army members"
ataxiaEcho(label .. " (" .. #soldiers .. "):")

for _, s in ipairs(soldiers) do
	local rankColour = s.rank >= 3 and "red" or "NavajoWhite"
	cecho("\n <" .. ataxiaNDB_getColour(s.name) .. ">" .. s.name ..
		string.rep(" ", math.max(0, 16 - string.len(s.name))) ..
		"<DimGrey>Rank: <" .. rankColour .. ">" .. s.rank ..
		"  <DimGrey>City: <NavajoWhite>" .. s.city)
end

if #soldiers == 0 then
	cecho("\n <DimGrey>No army members found.")
end

echo("\n ")
send(" ")
