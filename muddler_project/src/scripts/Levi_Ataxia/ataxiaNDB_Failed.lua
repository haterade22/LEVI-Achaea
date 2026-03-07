function ataxiaNDB_Failed(_, filepath)
	-- Only handle ataxiaNDB downloads
	if not filepath:find("ataxiaNDB", 1, true) then return end

	local person = filepath:match("[/\\]([%w_]+)%.json")

	if filepath:match("server replied: Not Found") then
		ataxiaEcho("This person does not exist: " .. (person or "unknown"))
		if person then
			ataxiaNDB_Remove(person)
			os.remove(getMudletHomeDir() .. "/ataxiaNDB/" .. person .. ".json")
			ataxiaNDB_blacklistName(person)
		end
	elseif filepath:match("server replied: Forbidden") then
		-- Forbidden = not a valid player name (item, NPC, etc.)
		if person and person ~= "Online" then
			ataxiaNDB_blacklistName(person)
		end
	else
		ataxiaEcho("Error downloading: " .. filepath)
	end
end

function ataxiaNDB_blacklistName(name)
	ataxiaNDB.notPlayers = ataxiaNDB.notPlayers or {}
	if not ataxiaNDB.notPlayers[name] then
		ataxiaNDB.notPlayers[name] = true
		ataxiaEcho(name .. " is not a player, added to ignore list.")
	end
end

function ataxiaNDB_isBlacklisted(name)
	if not ataxiaNDB.notPlayers then return false end
	return ataxiaNDB.notPlayers[name] or ataxiaNDB.notPlayers[name:title()] or false
end
