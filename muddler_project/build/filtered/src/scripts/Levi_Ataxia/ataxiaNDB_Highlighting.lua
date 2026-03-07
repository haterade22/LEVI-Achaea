function ataxiaNDB_Unhighlight()
	if not ataxiaNDB.highlightTriggers or not next(ataxiaNDB.highlightTriggers) then return end

	for k,v in pairs(ataxiaNDB.highlightTriggers) do
		killTrigger(v)
	end

	ataxiaNDB.highlightTriggers = {}
end

function ataxiaNDB_enemyHighlights()
	ataxiaEcho("Clearing all highlights to prevent errors. One moment, please.")
	ataxiaNDB_Unhighlight()
	tempTimer(2, function() ataxiaEcho("Loading new highlights now."); ataxiaNDB_loadHighlights() end)
end

function ataxiaNDB_loadHighlights()
	ataxiaNDB.highlightTriggers = ataxiaNDB.highlightTriggers or {}

	ataxiaNDB_Unhighlight()

	if ataxiaNDB.highlightNames then
		for index, person in pairs(ataxiaNDB.players) do
			if not person.name then
				ataxiaNDB.players[index] = nil
			else
				ataxiaNDB_highlightName( person.name, person.city )
			end
		end
	elseif ataxiaNDB.special then
		for person, colour in pairs(ataxiaNDB.special) do
			ataxiaNDB_highlightName( person, "nil" )
		end
	end
end

function ataxiaNDB_addHighlight(_, name)

	if not ataxiaNDB.highlightNames then return end
	if not name then return end
	if not ataxiaNDB.players[name] then return end

	ataxiaNDB_highlightName( ataxiaNDB.players[name].name, ataxiaNDB.players[name].city)
end


function ataxiaNDB_updateHighlights(city, colour)

	ataxiaNDB.highlighting[city] = colour

	for name, trig in pairs(ataxiaNDB.highlightTriggers) do
		if ataxiaNDB.players[name].city == city then
			killTrigger(trig)
			if ataxiaNDB.highlightNames then
				ataxiaNDB_highlightName( ataxiaNDB.players[name].name, ataxiaNDB.players[name].city )
			end
		elseif city == "Rogues" or city == "(hidden)" then
			if ataxiaNDB_getCitizenship(name) == "None" then
				killTrigger(trig)
				if ataxiaNDB.highlightNames then
					ataxiaNDB_highlightName( ataxiaNDB.players[name].name, ataxiaNDB.players[name].city )
				end
			end
		end
	end
end


function ataxiaNDB_highlightName(who, city)
	if not who then return end
	--If any highlight available, then clear it.
	if ataxiaNDB.highlightTriggers and ataxiaNDB.highlightTriggers[who] then
		killTrigger(ataxiaNDB.highlightTriggers[who])
	end

	local colour = ataxiaNDB.highlighting.Rogues

	--Get the necessary colour.
		--Check specials first, then enemy list
	if ataxiaNDB.special and ataxiaNDB.special[who] then
		colour = ataxiaNDB.special[who]
	elseif ataxiaNDB.highlightPriority == "enemies" then
		if table.contains(ataxiaNDB.cityEnemies, who) then
			colour = ataxiaNDB.highlighting.Enemies
		else
			if city == "None" or city == "(hidden)" then
				colour = ataxiaNDB.highlighting.Rogues
			else
				colour = ataxiaNDB.highlighting[city] or ataxiaNDB.highlighting.Rogues
			end
		end
	else
		if city == "None" or city == "(hidden)" then
			colour = ataxiaNDB.highlighting.Rogues
		else
			colour = ataxiaNDB.highlighting[city] or ataxiaNDB.highlighting.Rogues
		end
	end

	ataxiaNDB.highlightTriggers = ataxiaNDB.highlightTriggers or {}
	local capturedWho = who
	local capturedColour = colour
	ataxiaNDB.highlightTriggers[who] = tempTrigger(who, function()
		ataxiaNDB_highlight(capturedWho, capturedColour)
	end)
end

function ataxiaNDB_highlight(name, colour)
	local c, k = 1, 1
	while k > 0 do
		k = line:find(name, k)
		if k == nil then return end
		c = c + 1

		if k == line:find("%f[%a]"..name.."%f[%A]", k) then
			if selectString(name, c-1) > -1 then
				if colour then fg(colour) end
				if ataxiaNDB.highlightPriority == "enemies" and table.contains(ataxiaNDB.cityEnemies, name) then
					if ataxiaNDB.enemySettings.bold then setBold(true) end
					if ataxiaNDB.enemySettings.underline then setUnderline(true) end
					if ataxiaNDB.enemySettings.italics then setItalics(true) end
				end
				resetFormat()
			else
				return
			end
    		end
		k = k + 1
	end
end

if ataxiaNDB._highlightHandlerId then
	killAnonymousEventHandler(ataxiaNDB._highlightHandlerId)
end
ataxiaNDB._highlightHandlerId = registerAnonymousEventHandler("ataxiaNDB Check Highlight", "ataxiaNDB_addHighlight")
