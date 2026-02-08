local name, colour = matches[2]:title(), matches[3]
ataxiaNDB.special = ataxiaNDB.special or {}

if not ataxiaNDB.players[name] then
	ataxiaEcho("That person is not yet in the database!")
elseif colour == "none" then
	if ataxiaNDB.special[name] then
		ataxiaEcho("Clearing special highlight of "..name.."!")
		ataxiaNDB.special[name] = nil
		killTrigger(ataxiaNDB.highlightTriggers[name])
	else
		ataxiaEcho("That person is already not being highlighted a special colour!")
	end
elseif not color_table[colour] then
	ataxiaEcho("That is not a valid colour to use!")
else
	ataxiaNDB.special[name] = colour
	ataxiaNDB_highlightName(name, "nil")
	ataxiaEcho("Will now highlight "..name.." in <"..colour..">"..colour..".")
end