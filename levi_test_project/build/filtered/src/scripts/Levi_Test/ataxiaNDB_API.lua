function ataxiaNDB_isMark(name)
  if not ataxiaNDB_Exists(name) then return false end
  if ataxiaNDB.players[name].mark then
    return ataxiaNDB.players[name].mark
  else
    return false
  end
end

function ataxiaNDB_armyRank(name)
  if not ataxiaNDB_Exists(name) then return 0 end
  if ataxiaNDB.players[name].armyRank then
    return ataxiaNDB.players[name].armyRank
  else
    return 0
  end
end

function ataxiaNDB_isEnemy(name)
	if table.contains(ataxiaNDB.cityEnemies, name) then
		return true
	else
		return false
	end
end

function ataxiaNDB_getHouse(name)
  if not ataxiaNDB_Exists(name) then
    return "Unknown"
  else
    return ataxiaNDB.players[name:title()].house 
  end
end

function ataxiaNDB_getColour(name)
	if not ataxiaNDB_Exists(name) then
		return "white"
	else
    if ataxiaNDB_getCitizenship(name) == "Unknown" or ataxiaNDB_getCitizenship(name) == "None" then
      return ataxiaNDB.highlighting.Rogues
    else
    if ataxiaNDB_getCitizenship(name) == "underworld" then
      return ataxiaNDB.highlighting.underworld
    else
		  return ataxiaNDB.highlighting[ataxiaNDB_getCitizenship(name)]
      end   
    end
	end
end
function ataxiaNDB_getClass(name)
	if ataxiaNDB_Exists(name) then
		return ataxiaNDB.players[name:title()].class
    --return ataxiaNDB.players[name].class
	else
		return "Unknown"
	end
end

function ataxiaNDB_Exists(name)
	if not ataxiaNDB.players[name] then
		return false
	else
		return true
	end
end

function ataxiaNDB_isCitizenOf(city, name)
	if ataxiaNDB_Exists(name) then
		return (ataxiaNDB.players[name:title()].city == city:title() and true or false)
	else
		ataxia_Echo("That person's information has not yet been gathered.")
		return false
	end
end

function ataxiaNDB_getCitizenship(name)
	if ataxiaNDB_Exists(name) then
		if ataxiaNDB.players[name].city:lower() == "none" or ataxiaNDB.players[name].city:lower() == "(hidden)" or ataxiaNDB.players[name].city:lower() == "underworld" then
			return "Rogues"
		else
			return ataxiaNDB.players[name].city
		end
	else
		return "Unknown"
	end
end


function ataxiaNDB_Remove(name)
	local person = name:title()
	if ataxiaNDB_Exists(person) then
		ataxiaNDB.players[person] = nil
		--If any highlight available, then clear it.
		if ataxiaNDB.highlightTriggers and ataxiaNDB.highlightTriggers[person] then
			killTrigger(ataxiaNDB.highlightTriggers[person])
		end
		ataxiaEcho(person.." has been removed from the database.")
	else
		ataxiaEcho(person.." is not in the database, anyway.")
	end
end

function ataxiaNDB_SortOnline(filepath)
	local f, s = io.open(filepath)
    if f then s = f:read("*l"); io.close(f) end

	-- didn't get JSON data? 
	if s:find("Internal error", 1, true) or s:find("DOCTYPE html PUBLIC", 1, true) then
		cecho("\n<red>Data Acquisition Failed!") 
		return 
	end

	local t = yajl.to_value(s)

	apiOnlineFound = {}
	apiNeedUpdate = {}
	for ind, tab in pairs(t.characters) do
		if not tab.name:find("masked") and not table.contains(ataxiaNDB.divine, tab.name) then
			table.insert(apiOnlineFound, tab.name)
		end
	end

	for ind, tab in pairs(gmcp.Comm.Channel.Players) do
		if not table.contains(apiOnlineFound, tab.name) and not tab.name:find("masked") and not table.contains(ataxiaNDB.divine, tab.name) then
			table.insert(apiOnlineFound, tab.name)
		end
	end

	os.remove(filepath)
	table.sort(apiOnlineFound)

	--Parse the list to see who needs to be added.
	local count = 0
	for index, name in pairs(apiOnlineFound) do
		if not ataxiaNDB_Exists(name) and not table.contains(ataxiaNDB.divine, name) then
			count = count + 1
			table.insert(apiNeedUpdate, name)
		end
	end

	if count > 0 then
		ataxiaEcho(count.." new names identified, grabbing their info.")
		cecho("\n<a_darkgrey> - "..table.concat(apiNeedUpdate, ", ")..".")
		ataxiaNDB_NameList(apiNeedUpdate)
	else
		if parsingCity then
			if parsingCity:lower() == "classes" then
				ataxiaNDB_displayOnlineClass(apiOnlineFound)
			else
				ataxiaNDB_displayOnlineCity(apiOnlineFound)
			end
		else
			ataxiaNDB_displayOnline(apiOnlineFound)
		end
	end
end