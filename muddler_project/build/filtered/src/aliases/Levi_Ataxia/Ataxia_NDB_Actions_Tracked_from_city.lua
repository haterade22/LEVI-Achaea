local cities = {"Ashtan", "Cyrene", "Eleusis", "Hashan", "Mhaldor", "Targossas",}

if not table.contains(cities, matches[2]:title()) and matches[2]:title() ~= "None" then
	ataxiaEcho("Invalid city. Please choose from either "..table.concat(cities, ", ").." or none.")
else
	local cl = (matches[2]:title() == "None" and ataxiaNDB.highlighting.Rogues or ataxiaNDB.highlighting[matches[2]:title()])
	ataxiaEcho("Displaying tracked people from <"..cl..">"..matches[2]:title()..":")
	local people = {}
	for i,v in pairs(ataxiaNDB.players) do
		if v.city == matches[2]:title() then
			table.insert(people, v.name)
		end
	end
	table.sort(people)
	
	cecho("\n  <"..cl..">"..table.concat(people, ", ")..".")
	cecho("\n <NavajoWhite>Total: <green>"..#people..".")
end

