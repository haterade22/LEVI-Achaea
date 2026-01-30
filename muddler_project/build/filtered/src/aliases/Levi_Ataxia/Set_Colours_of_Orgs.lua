local cities = {"Ashtan", "Cyrene", "Eleusis", "Hashan", "Mhaldor", "Targossas", "Rogues", "Enemies"}

local city, colour = "", ""

if table.contains(cities, matches[2]:title()) then
	city = matches[2]:title()
	colour = matches[3]
elseif table.contains(cities, matches[3]:title()) then
	city = matches[3]:title()
	colour = matches[2]
else
	ataxiaEcho("That is not a valid option, please choose from: <green>Ashtan, Cyrene, Eleusis, Enemies, Hashan, Mhaldor, Rogues, or Targossas.")
end

if city ~= "" then
	if table.contains(color_table, colour) then
		ataxiaEcho(city.." will now be highlighted in <"..colour..">"..colour..".")
		if city ~= "Enemies" then
			ataxiaNDB_updateHighlights(city, colour)
		else
			ataxiaNDB_enemyHighlights()
		end
	else
		ataxiaEcho("That is not a valid colour to choose from.")
	end
end