--[[mudlet
type: script
name: ataxiaNDB API
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Ataxia NDB
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function ataxiaNDB_isMark(name)
  if not ataxiaNDB_Exists(name) then return false end
  return ataxiaNDB.players[name:title()].mark or false
end

function ataxiaNDB_armyRank(name)
  if not ataxiaNDB_Exists(name) then return 0 end
  return ataxiaNDB.players[name:title()].armyRank or 0
end

function ataxiaNDB_isDauntless(name)
  if not ataxiaNDB_Exists(name) then return false end
  return ataxiaNDB.players[name:title()].dauntless or false
end

function ataxiaNDB_isEnemy(name)
  return table.contains(ataxiaNDB.cityEnemies, name)
end

function ataxiaNDB_getHouse(name)
  if not ataxiaNDB_Exists(name) then return "Unknown" end
  return ataxiaNDB.players[name:title()].house
end

function ataxiaNDB_getColour(name)
  if not ataxiaNDB_Exists(name) then return "white" end
  local cit = ataxiaNDB_getCitizenship(name)
  if cit == "Unknown" or cit == "Rogues" then
    return ataxiaNDB.highlighting.Rogues
  else
    return ataxiaNDB.highlighting[cit] or ataxiaNDB.highlighting.Rogues
  end
end

function ataxiaNDB_getClass(name)
  if not ataxiaNDB_Exists(name) then return "Unknown" end
  return ataxiaNDB.players[name:title()].class
end

function ataxiaNDB_Exists(name)
  if not name then return false end
  return ataxiaNDB.players[name:title()] ~= nil
end

function ataxiaNDB_isCitizenOf(city, name)
  if not ataxiaNDB_Exists(name) then
    ataxiaEcho("That person's information has not yet been gathered.")
    return false
  end
  return ataxiaNDB.players[name:title()].city == city:title()
end

function ataxiaNDB_getCitizenship(name)
  if not ataxiaNDB_Exists(name) then return "Unknown" end
  local city = ataxiaNDB.players[name:title()].city
  if not city then return "Unknown" end
  local cityLower = city:lower()
  if cityLower == "none" or cityLower == "(hidden)" then
    return "Rogues"
  else
    return city
  end
end

function ataxiaNDB_Remove(name)
  local person = name:title()
  if ataxiaNDB_Exists(person) then
    ataxiaNDB.players[person] = nil
    if ataxiaNDB.highlightTriggers and ataxiaNDB.highlightTriggers[person] then
      killTrigger(ataxiaNDB.highlightTriggers[person])
      ataxiaNDB.highlightTriggers[person] = nil
    end
    ataxiaEcho(person.." has been removed from the database.")
  else
    ataxiaEcho(person.." is not in the database, anyway.")
  end
end

function ataxiaNDB_SortOnline(filepath)
  local f = io.open(filepath, "r")
  if not f then
    cecho("\n<red>Data Acquisition Failed - could not open file!")
    return
  end
  local s = f:read("*l")
  io.close(f)
  if not s then os.remove(filepath); return end

  if s:find("Internal error", 1, true) or s:find("DOCTYPE html PUBLIC", 1, true) then
    cecho("\n<red>Data Acquisition Failed!")
    os.remove(filepath)
    return
  end

  local ok, t = pcall(yajl.to_value, s)
  if not ok or not t then
    cecho("\n<red>Failed to parse online data!")
    os.remove(filepath)
    return
  end

  local onlineSet = {}
  ataxiaNDB._onlineFound = {}
  local apiNeedUpdate = {}

  for ind, tab in pairs(t.characters) do
    if not tab.name:find("masked") and not ataxiaNDB.divine[tab.name] then
      if not onlineSet[tab.name] then
        onlineSet[tab.name] = true
        table.insert(ataxiaNDB._onlineFound, tab.name)
      end
    end
  end

  for ind, tab in pairs(gmcp.Comm.Channel.Players) do
    if not onlineSet[tab.name] and not tab.name:find("masked") and not ataxiaNDB.divine[tab.name] then
      onlineSet[tab.name] = true
      table.insert(ataxiaNDB._onlineFound, tab.name)
    end
  end

  os.remove(filepath)
  table.sort(ataxiaNDB._onlineFound)

  local count = 0
  for index, name in pairs(ataxiaNDB._onlineFound) do
    if not ataxiaNDB_Exists(name) and not ataxiaNDB.divine[name]
      and not ataxiaNDB_isBlacklisted(name) then
      count = count + 1
      table.insert(apiNeedUpdate, name)
    end
  end

  if count > 0 then
    ataxiaEcho(count.." new names identified, grabbing their info.")
    cecho("\n<a_darkgrey> - "..table.concat(apiNeedUpdate, ", ")..".")
    ataxiaNDB_NameList(apiNeedUpdate)
  else
    if ataxiaNDB._parsingCity then
      if ataxiaNDB._parsingCity:lower() == "classes" then
        ataxiaNDB_displayOnlineClass(ataxiaNDB._onlineFound)
      else
        ataxiaNDB_displayOnlineCity(ataxiaNDB._onlineFound)
      end
    else
      ataxiaNDB_displayOnline(ataxiaNDB._onlineFound)
    end
  end
end
