--[[mudlet
type: script
name: ataxiaNDB_Failed
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
eventHandlers:
- sysDownloadError
]]--

function ataxiaNDB_Failed(_, filepath)
	-- Only handle ataxiaNDB downloads
	if not filepath:find("ataxiaNDB", 1, true) then return end

	local person = filepath:match("/([%w_]+)%.json")

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
	if not table.contains(ataxiaNDB.notPlayers, name) then
		table.insert(ataxiaNDB.notPlayers, name)
		ataxiaEcho(name .. " is not a player, added to ignore list.")
	end
end

function ataxiaNDB_isBlacklisted(name)
	ataxiaNDB.notPlayers = ataxiaNDB.notPlayers or {}
	return table.contains(ataxiaNDB.notPlayers, name) or table.contains(ataxiaNDB.notPlayers, name:title())
end
