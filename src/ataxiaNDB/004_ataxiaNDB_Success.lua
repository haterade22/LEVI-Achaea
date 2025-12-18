-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > Ataxia NDB > Get Information > ataxiaNDB_Success

function ataxiaNDB_Success(_, filepath)
	--Do not mess with if it's not ataxiaNDB information.
	if not filepath:find("ataxiaNDB", 1, true) then return end

	if filepath:find("Online",1,true) then
		ataxiaNDB_SortOnline(filepath)
		return
	end

    local f, s = io.open(filepath)
    if f then s = f:read("*l"); io.close(f) end

	-- didn't get JSON data? 
	if s:find("Internal error", 1, true) or s:find("DOCTYPE html PUBLIC", 1, true) then
		cecho("\n<red>Data Acquisition Failed!") 
		return 
	end

	local t = yajl.to_value(s)
	local cities = {"Ashtan", "Cyrene", "Eleusis", "Hashan", "Mhaldor", "Targossas", "Rogues","Underworld",}
	local name = t.name
	local title = t.fullname
	local house = t.house:title()
	local xp_rank = tonumber(t.xp_rank)
	local city = t.city:title()
	local class = t.class:title()
	local level = tonumber(t.level)
  local pks = tonumber(t.player_kills)

	local tmpCity = (ataxiaNDB_Exists(name) and ataxiaNDB_getCitizenship(name) or "Unknown")
  local isMark, aRank = ataxiaNDB_isMark(name), ataxiaNDB_armyRank(name)

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
			if honoursPerson == nil then ataxiaEcho("<red>WARNING: "..name.."'s city is hidden; will require a manual honours/setting to update it.") end
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
	
	if honoursPerson ~= nil then 
		send("honours "..honoursPerson,false)
		tempTimer(3, [[honoursPerson = nil]])
	else
		raiseEvent("ataxiaNDB Check Highlight", t.name)
	end
  if ataxiaNDB.checking then
    ataxiaNDB_displayWho(name)
  end
end