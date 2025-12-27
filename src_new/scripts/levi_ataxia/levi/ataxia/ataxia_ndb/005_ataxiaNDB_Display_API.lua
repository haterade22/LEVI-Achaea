--[[mudlet
type: script
name: ataxiaNDB Display API
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

function ataxiaNDB_displayOnlineClass(players)
	local classList = {"Alchemist", "Apostate", "Bard", "Blademaster", "Depthswalker", "Druid", "Infernal", "Jester", "Magi", "Monk", "Occultist",
		"Paladin", "Priest", "Runewarden", "Sentinel", "Serpent", "Shaman", "Sylvan"}
	local classes = {
		Alchemist = {}, Apostate = {}, Bard = {}, Blademaster = {}, Depthswalker = {},
		Druid = {}, Infernal = {}, Jester = {}, Magi = {}, Monk = {}, Occultist = {},
		Paladin = {}, Priest = {}, Runewarden = {}, Sentinel = {}, Serpent = {},
		Shaman = {}, Sylvan = {},
	}

	for _, player in pairs(players) do
		local class = ataxiaNDB.players[player].class
		table.insert(classes[class], player)
	end
	ataxiaEcho("Data acqusition completed and analysed. Showing class count for online players.")

	for _, class in ipairs(classList) do
		cecho("\n <DimGrey>[<NavajoWhite>"..class:title().."<DimGrey>]"..string.rep(" ", 13-string.len(class)).."- <NavajoWhite>"..#classes[class].." tracked people are "..class..".")
	end
	send(" ")
	parsingCity = nil
end

function ataxiaNDB_displayOnlineCity(players)
	local peopleFound = {}

ataxiaEcho("Data acqusition completed and analysed. Showing online players from <"..ataxiaNDB.highlighting[parsingCity:title()]..">"..parsingCity:title()..".")

	for _, person in pairs(players) do
		if ataxiaNDB_isCitizenOf(parsingCity:title(), person) then
			cecho("\n <"..ataxiaNDB.highlighting[parsingCity:title()]..">"..person..string.rep(" ", 13-string.len(person)).."- <NavajoWhite>"..ataxiaNDB_getClass(person))
		end
	end
	send(" ")
	parsingCity = nil
end

function ataxiaNDB_displayOnline(players)
	local onlinePeople = {
		Ashtan = {}, Cyrene = {}, Eleusis = {}, Hashan = {}, Mhaldor = {}, Targossas = {}, Rogues = {}, Untracked = {}, underworld = {},
	}

  
	for _, person in pairs(players) do
		if not ataxiaNDB_Exists(person) then
			table.insert(onlinePeople.Untracked, person)
		elseif ataxiaNDB_getCitizenship(person):lower() == "none" or ataxiaNDB_getCitizenship(person):lower() == "unknown" or ataxiaNDB_getCitizenship(person) == "(hidden)"  or ataxiaNDB_getCitizenship(person) == "Unknown" or ataxiaNDB_getCitizenship(person):lower() == "Unknown" then
			table.insert(onlinePeople.Rogues, person)
		elseif ataxiaNDB_getCitizenship(person):lower() == "underworld" then
      table.insert(onlinePeople.underworld, person)
    else
			table.insert(onlinePeople[ataxiaNDB_getCitizenship(person)], person)
		end
	end

	ataxiaEcho("Data acquisition completed and analysed. List of players online:")
	echo("\n"..table.concat(apiOnlineFound, ", ")..".\nTotal players visible to us: "..#apiOnlineFound..".\n")

	ataxiaEcho(" City affiliations of currently online people:")
	cecho(string.format("\n<%s>[Ashtan]     :<white>(<orange>%d<white>)<%s> %s.", ataxiaNDB.highlighting.Ashtan, #onlinePeople.Ashtan, ataxiaNDB.highlighting.Ashtan, table.concat(onlinePeople.Ashtan, ", ")))
	cecho(string.format("\n<%s>[Cyrene]     :<white>(<orange>%d<white>)<%s> %s.", ataxiaNDB.highlighting.Cyrene, #onlinePeople.Cyrene, ataxiaNDB.highlighting.Cyrene, table.concat(onlinePeople.Cyrene, ", ")))
	cecho(string.format("\n<%s>[Eleusis]    :<white>(<orange>%d<white>)<%s> %s.", ataxiaNDB.highlighting.Eleusis, #onlinePeople.Eleusis, ataxiaNDB.highlighting.Eleusis, table.concat(onlinePeople.Eleusis, ", ")))
	cecho(string.format("\n<%s>[Hashan]     :<white>(<orange>%d<white>)<%s> %s.", ataxiaNDB.highlighting.Hashan, #onlinePeople.Hashan, ataxiaNDB.highlighting.Hashan, table.concat(onlinePeople.Hashan, ", ")))
	cecho(string.format("\n<%s>[Mhaldor]    :<white>(<orange>%d<white>)<%s> %s.", ataxiaNDB.highlighting.Mhaldor, #onlinePeople.Mhaldor, ataxiaNDB.highlighting.Mhaldor, table.concat(onlinePeople.Mhaldor, ", ")))
	cecho(string.format("\n<%s>[Targossas]  :<white>(<orange>%d<white>)<%s> %s.", ataxiaNDB.highlighting.Targossas, #onlinePeople.Targossas, ataxiaNDB.highlighting.Targossas, table.concat(onlinePeople.Targossas, ", ")))
	cecho(string.format("\n<%s>[Rogues]     :<white>(<orange>%d<white>)<%s> %s.", ataxiaNDB.highlighting.Rogues, #onlinePeople.Rogues, ataxiaNDB.highlighting.Rogues, table.concat(onlinePeople.Rogues, ", ")))
  --cecho(string.format("\n<%s>[Underworld]     :<white>(<orange>%d<white>)<%s> %s.",ataxiaNDB.highlighting.underworld, #onlinePeople.underworld, ataxiaNDB.highlighting.underworld, table.concat(onlinePeople.underworld, ", ")))
	echo("\n ")
	send(" ")

end

function ataxiaNDB_displayWho(person)
  ataxiaNDB.checking = nil
  local name = person:title()
  local x, c, u
  if not ataxiaNDB_Exists(name) then
  	ataxiaEcho(name.." is not yet tracked!")
  else
  	x = ataxiaNDB.players[name]
  	c = ataxiaNDB_getColour(name)
  	u = "Checked: "..(x.lastUpdate and x.lastUpdate or "n/a")
  	
  	cecho("\n\n<blue>- <"..c..">"..x.title.." <blue>"..string.rep("-", 70-(string.len(x.title)+3)).."\n")
  	cecho("\n<a_darkcyan> City :   <NavajoWhite>"..x.city..string.rep(" ", 31-string.len(x.city)).."  <a_darkcyan> Level:   <NavajoWhite>"..x.level)
  	cecho("\n<a_darkcyan> House:   <NavajoWhite>"..x.house..string.rep(" ", 31-string.len(x.house)).."  <a_darkcyan> Rank :   <NavajoWhite>"..x.xp_rank)
  	cecho("\n<a_darkcyan> Class:   <NavajoWhite>"..x.class..string.rep(" ", 31-string.len(x.class)).."  <a_darkcyan> Kills:   <NavajoWhite>"..(x.pks or "n/a"))
    if ataxiaNDB_armyRank(name) > 0 then
      cecho("\n<a_darkcyan> Army :   <"..(ataxiaNDB_armyRank(name) > 3 and "red" or "NavajoWhite")..">"..ataxiaNDB_armyRank(name))
    end
    if ataxiaNDB_isMark(name) then
      cecho("\n<a_darkcyan> Mark :   <"..(ataxiaNDB_isMark(name) == "Ivory" and "NavajoWhite" or "purple")..">"..ataxiaNDB_isMark(name))
    end
    echo("\n ")
    if ataxiaNDB.player_Notes[name] and #ataxiaNDB.player_Notes[name] > 0 then
      cecho("\n<a_darkcyan> Notes:")
      for num, note in pairs(ataxiaNDB.player_Notes[name]) do
        cecho("\n  <DarkSlateBlue>"..num..") <reset>"..note)
      end
      echo("\n ")
    end
  	cecho("\n <a_green>"..string.rep(" ", 69-string.len(u))..u)
  	cecho("\n<blue>"..string.rep("-", 70))
  	cecho("\n ")
  	send(" ",false)
  end	
end