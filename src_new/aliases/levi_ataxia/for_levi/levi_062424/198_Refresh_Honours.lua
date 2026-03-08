--[[mudlet
type: alias
name: Refresh Honours
hierarchy:
- Levi_Ataxia
- Ataxia
- NDB
- Actions
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^an refresh(?: (\w+)|)$
command: ''
packageName: ''
]]--

local cityFilter = matches[2] and matches[2]:title() or nil
local queue = {}

for _, v in pairs(ataxiaNDB.players) do
	if not cityFilter or v.city == cityFilter or (cityFilter == "Rogues" and v.city == "None") then
		table.insert(queue, v.name)
	end
end

if #queue == 0 then
	ataxiaEcho("No players found" .. (cityFilter and (" in " .. cityFilter) or "") .. ".")
	return
end

table.sort(queue)

ataxiaEcho("Refreshing honours for " .. #queue .. " player(s)" .. (cityFilter and (" from " .. cityFilter) or "") .. ". ETA: ~" .. math.ceil(#queue * 2) .. "s.")

-- Store queue for sequential processing
ataxiaNDB._refreshQueue = queue
ataxiaNDB._refreshIndex = 1
ataxiaNDB._refreshFilter = cityFilter
ataxiaNDB_processRefreshQueue()
