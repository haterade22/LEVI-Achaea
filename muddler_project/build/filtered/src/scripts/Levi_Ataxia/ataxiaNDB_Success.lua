function ataxiaNDB_Success(_, filepath)
	--Do not mess with if it's not ataxiaNDB information.
	if not filepath:find("ataxiaNDB", 1, true) then return end

	if filepath:find("Online",1,true) then
		ataxiaNDB_SortOnline(filepath)
		return
	end

	local f, err = io.open(filepath)
	if not f then return end
	local s = f:read("*l")
	io.close(f)
	if not s then os.remove(filepath); return end

	-- didn't get JSON data?
	if s:find("Internal error", 1, true) or s:find("DOCTYPE html PUBLIC", 1, true) then
		cecho("\n<red>Data Acquisition Failed!")
		return
	end

	local ok, t = pcall(yajl.to_value, s)
	if not ok or not t then
		cecho("\n<red>Failed to parse player data!")
		os.remove(filepath)
		return
	end

	local cities = {"Ashtan", "Cyrene", "Eleusis", "Hashan", "Mhaldor", "Targossas", "Rogues"}
	local name = t.name
	if not name then os.remove(filepath); return end
	local title = t.fullname or name
	local house = t.house and t.house:title() or "Unknown"
	local xp_rank = tonumber(t.xp_rank) or 0
	local city = t.city and t.city:title() or "Unknown"
	local class = t.class and t.class:title() or "Unknown"
	local level = tonumber(t.level) or 0
	local pks = tonumber(t.player_kills) or 0

	local tmpCity = (ataxiaNDB_Exists(name) and ataxiaNDB_getCitizenship(name) or "Unknown")
	local isMark = ataxiaNDB_isMark(name)
	local aRank = ataxiaNDB_armyRank(name)
	local isDauntless = ataxiaNDB_isDauntless(name)

	ataxiaNDB.players[name] = {
		name = name,
		title = title,
		house = house,
		xp_rank = xp_rank,
		city = city,
		level = level,
		class = class,
		pks = pks,
		lastUpdate = os.date(),
		armyRank = aRank or nil,
		mark = isMark or nil,
		dauntless = isDauntless or nil,
	}
	if house:find("hidden") then
		ataxiaNDB.players[name].house = "Unknown"
	elseif house:find("none") then
		ataxiaNDB.players[name].house = "None"
	else
		ataxiaNDB.players[name].house = house:title()
	end

	if city:find("hidden") then
		if not table.contains(cities, tmpCity) then
			ataxiaNDB.players[name].city = "Unknown"
			if ataxiaNDB._honoursPerson == nil then ataxiaEcho("<red>WARNING: "..name.."'s city is hidden; will require a manual honours/setting to update it.") end
		else
			if tmpCity == "Rogues" then
				ataxiaNDB.players[name].city = "None"
			else
				ataxiaNDB.players[name].city = tmpCity
			end
		end
	elseif city:find("none") or city == "" then
		ataxiaNDB.players[name].city = "None"
	else
		ataxiaNDB.players[name].city = city:title()
	end

	os.remove(filepath)

	if ataxiaNDB._honoursPerson ~= nil then
		send("honours "..ataxiaNDB._honoursPerson,false)
		tempTimer(3, function() ataxiaNDB._honoursPerson = nil end)
	else
		raiseEvent("ataxiaNDB Check Highlight", t.name)
	end
	if ataxiaNDB.checking then
		ataxiaNDB_displayWho(name)
	end
end
