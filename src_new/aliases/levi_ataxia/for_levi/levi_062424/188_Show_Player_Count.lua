--[[mudlet
type: alias
name: Show Player Count
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Ataxia NDB
- Actions
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^an citymembers$
command: ''
packageName: ''
]]--

local cities = {
	Ashtan = {},
	Cyrene = {},
	Eleusis = {},
	Hashan = {},
	Mhaldor = {},
	Targossas = {},
	None = {},
}

for player, tab in pairs(ataxiaNDB.players) do
	if cities[tab.city] then
		table.insert(cities[tab.city], player)
	else
		table.insert(cities.None, player)
	end
end

ataxiaEcho("Displaying count of currently tracked players in each city.")
for city, tab in pairs(cities) do
	cecho("\n"..city..":"..string.rep(" ", 15-string.len(city))..#cities[city])
end

send(" ")