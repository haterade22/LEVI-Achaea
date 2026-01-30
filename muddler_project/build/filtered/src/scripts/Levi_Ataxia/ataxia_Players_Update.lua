function ataxia_Players_Update(event)
	--Create the table if it's not already there.
	ataxia.playersHere = ataxia.playersHere or {}
	ataxiaBasher.ignore = ataxiaBasher.ignore or {}
   ataxiaBasher_stormhammer()  
	--For QL/Entering a room.
	if event == "gmcp.Room.Players" then
		--Reset the table, then parse the gmcp one to add people that aren't you.
		ataxia.playersHere = {}
		local me = gmcp.Char.Status.name:title()
		for _, tab in pairs(gmcp.Room.Players) do
			if tab.name ~= me then
				table.insert(ataxia.playersHere, tab.name)
				if type(target) == "string" and isTargeted(tab.name) then
					disableTimer("TargetOutOfRoom")
					targetIshere = true
				end
			end
		end
		if type(target) == "string" and not table.contains(ataxia.playersHere, target) then
			enableTimer("TargetOutOfRoom")
			targetIshere = false
		end

		if ataxiaTemp.autoFollow then
			if not table.contains(ataxia.playersHere, ataxiaTemp.autoFollow) then
				ataxiaTemp.following = false
				ataxiaEcho("We've been lost! Checking diag then going back!")
				sendAll("diagnose", "queue addclear freestand walkto "..ataxiaTemp.autoFollow)
			elseif table.contains(ataxia.playersHere, ataxiaTemp.autoFollow) and not ataxiaTemp.following then
				send("follow "..ataxiaTemp.autoFollow)
			end
		end


	--For when someone enters your room.
	elseif event == "gmcp.Room.AddPlayer" then
		local person = gmcp.Room.AddPlayer
		--If the person isn't already in the list, then add them.
		if not table.contains(ataxia.playersHere, person.name) then
			table.insert(ataxia.playersHere, person.name)
			if not table.contains(ataxiaBasher.ignore, person.name) and ataxiaBasher.enabled then
				ataxiaEcho("Someone is here! --- "..person.name)
				ataxiaBasher_alert("Normal")
			end
		end
		if type(target) == "string" and isTargeted(person.name) then
			disableTimer("TargetOutOfRoom")
			targetIshere = true
		end
	--For when someone leaves your room.
	else
		local person = gmcp.Room.RemovePlayer
		table.remove(ataxia.playersHere, table.index_of(ataxia.playersHere, person))

		if type(target) == "string" and isTargeted(person) then
			enableTimer("TargetOutOfRoom")
			targetIshere = false
		end

	end

	--Update the gui with new information.
	ataxia_Update_Players()
end

function ataxia_Update_Players()

  if ataxia.usegui or ataxia.usegui == nil then
    ataxiagui.playersConsole:clear()
    ataxiagui.playersConsole:setFontSize(8)
    ataxiagui.playersConsole:setWrap(25)
  elseif zgui then
    clearUserWindow("roomPlayersDisplay")
  end
  
	if #ataxia.playersHere > 0 then
    if zgui then
		  cecho("roomPlayersDisplay","<orange>"..#ataxia.playersHere.." <NavajoWhite>"..(#ataxia.playersHere == 1 and "other" or "others").." here:")
		  cecho("roomPlayersDisplay","\n<green> "..table.concat(ataxia.playersHere, ", ")..".")    
    else
		  ataxiagui.playersConsole:cecho("<orange>"..#ataxia.playersHere.." <NavajoWhite>"..(#ataxia.playersHere == 1 and "other" or "others").." here:")
		  ataxiagui.playersConsole:cecho("\n<green> "..table.concat(ataxia.playersHere, ", ")..".")
    end
	else
    if zgui then
      cecho("roomPlayersDisplay","\n\n <NavajoWhite>No one but you is standing here... \n\n\n    ...We think...")
    else
		  ataxiagui.playersConsole:cecho("\n\n <NavajoWhite>No one but you is standing here... \n\n\n    ...We think...")
    end
	end
end