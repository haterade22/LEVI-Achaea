local remove = {}
local cat, num = matches[2], tonumber(matches[3])

for i,v in pairs(ataxiaNDB.players) do
	if cat == "rank" then
		if v.xp_rank == nil or v.xp_rank == 0 or v.xp_rank > num then
			table.insert(remove, v.name)
			ataxiaNDB.players[v.name] = nil
		end
	else
		if not v.level or v.level < num then
			table.insert(remove, v.name)
			ataxiaNDB.players[v.name] = nil
		end		
	end
end
table.sort(remove)

ataxiaEcho("Removed a total of <green>"..#remove.."<NavajoWhite> unranked people from the database:\n - "..
	table.concat(remove, ", ")..".")
send(" ")
