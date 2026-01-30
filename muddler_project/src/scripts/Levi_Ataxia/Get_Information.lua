function ataxiaNDB_GetOnline()
	local path = getMudletHomeDir().."/ataxiaNDB"

	if not lfs.attributes(path) then
		--We'll need a folder to store downloaded data. Don't worry, it won't cause issues.
		lfs.mkdir(path)
		ataxiaEcho("Created folder to store downloaded data at: "..path)
	end  
  
	downloadFile(path .. "/Online.json", "http://api.achaea.com/characters.json")

	ataxiaEcho("One moment while I access the list...")

	ndbWatcher = ndbWatcher or createStopWatch()
	startStopWatch(ndbWatcher)
end

function ataxiaNDB_Acquire(person)

	assert(person)
	local person = person:title()
	local path = getMudletHomeDir().."/ataxiaNDB"

	if not lfs.attributes(path) then
		--We'll need a folder to store downloaded data. Don't worry, it won't cause issues.
		lfs.mkdir(path)
		ataxiaEcho("Created folder to store downloaded data at: "..path)
	end
	
	downloadFile(path .. "/"..person..".json", "http://api.achaea.com/characters/"..person..".json")

end

function ataxiaNDB_NameList(names)
	--Parse list to see who isn't tracked.
	for _, name in pairs(names) do
		if not ataxiaNDB_Exists(name) and not table.contains(ataxiaNDB.divine, name) then
			ataxiaNDB_Acquire(name)
		end
	end
	ataxiaEcho("Database has been fully updated, thank you.")
end