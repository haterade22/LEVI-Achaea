function ataxiaNDB_GetOnline()
	local path = getMudletHomeDir().."/ataxiaNDB"

	if not lfs.attributes(path) then
		lfs.mkdir(path)
		ataxiaEcho("Created folder to store downloaded data at: "..path)
	end

	downloadFile(path .. "/Online.json", "http://api.achaea.com/characters.json")

	ataxiaEcho("One moment while I access the list...")

	ataxiaNDB._watcher = ataxiaNDB._watcher or createStopWatch()
	startStopWatch(ataxiaNDB._watcher)
end

function ataxiaNDB_Acquire(person)

	assert(person)
	local person = person:title()

	-- Skip known non-players
	if ataxiaNDB_isBlacklisted(person) then return end

	local path = getMudletHomeDir().."/ataxiaNDB"

	if not lfs.attributes(path) then
		lfs.mkdir(path)
		ataxiaEcho("Created folder to store downloaded data at: "..path)
	end

	downloadFile(path .. "/"..person..".json", "http://api.achaea.com/characters/"..person..".json")

end

function ataxiaNDB_NameList(names)
	--Parse list to see who isn't tracked.
	for _, name in pairs(names) do
		if not ataxiaNDB_Exists(name) and not ataxiaNDB.divine[name]
			and not ataxiaNDB_isBlacklisted(name) then
			ataxiaNDB_Acquire(name)
		end
	end
	ataxiaEcho("Database has been fully updated, thank you.")
end
