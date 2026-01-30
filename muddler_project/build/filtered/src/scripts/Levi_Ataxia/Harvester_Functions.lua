function ataxiaExtractor_check()
	if (speedWalkCounter < 1 or mmp.paused) then
		if harvested_in_room_stuff() then
			ataxiaBasher_nextRoom()
		else      
      ataxiaExtractor_extract()
      
			if mmp.paused then
				ataxiaHarvester_harvested()
				mmp.pause("off")
			elseif not ataxiaHarvester_manual_extracting and #ataxiaBasher_path > 0 then
				expandAlias("goto "..ataxiaBasher_path[1])
			elseif not ataxiaHarvester_manual_extracting then
				disable_harvester()
			end
		end
	end
end

function ataxiaExtractor_extract()
  ataxiaExtraction = ataxiaExtraction or {}
  local a = gmcp.Room.Info.area 
  if ataxiaExtraction[a] then
    send("extract "..ataxiaExtraction[a],false)
  end
end

function ataxiaHarvester_check()
	if (mmp.speedWalkCounter < 1 or mmp.paused) then
		if #harvest_in_room == 0 and not harvested_in_room_stuff() then
			get_room_harvestables()
		elseif #harvest_in_room > 0 then
			ataxiaHarvester_harvest()
		else
			autoHarvest_rooms = autoHarvest_rooms or {}
			if not table.contains(autoHarvest_rooms, gmcp.Room.Info.num) then table.insert(autoHarvest_rooms, gmcp.Room.Info.num) end
			if mmp.paused then
				ataxiaHarvester_harvested()
				mmp.pause("off")
			elseif not ataxiaHarvester_manual_harvesting and #ataxiaBasher_path > 0 then
				harvest_in_room = {}
				expandAlias("goto "..ataxiaBasher_path[1])
			elseif not ataxiaHarvester_manual_harvesting then
				disable_harvester()
			end
		end
	end
end

function get_room_harvestables()
	harvest_in_room = {}
	ataxiaTemp.riftContents = ataxiaTemp.riftContents or {}
	get_herbHarvestTable()

	if table.contains(env_to_get, gmcp.Room.Info.environment) then
		local herb = ""
		for i,v in pairs(env_to_get[gmcp.Room.Info.environment]) do
			herb = v:gsub("harvest ", "")
			ataxiaTemp.riftContents[herb] = ataxiaTemp.riftContents[herb] or 0
			table.insert(harvest_in_room, v)
		end
		ataxiaHarvester_harvest()
	else
		ataxiaHarvester_harvested()
		ataxiaHarvester_harvester()
		mmp.pause("off")
	end
end

function ataxiaHarvester_harvester()
	if #ataxiaBasher_path > 0 and not ataxiaHarvester_manual_harvesting then
		harvest_in_room = {}
		harvest_goto = ataxiaBasher_path[1]
		expandAlias("goto "..ataxiaBasher_path[1], false)
	elseif not ataxiaHarvester_manual_harvesting then
		disable_harvester()
	end
end

function ataxiaHarvester_harvest()
	if #harvest_in_room > 0 then
		
		if canBals() then
			ataxiaHarvester_harvested()
			send(harvest_in_room[1])
		end
	else
		ataxiaHarvester_harvested()
		ataxiaHarvester_harvester()
	end
end

function harvested_in_room_stuff()
	if not autoHarvest_rooms then autoHarvest_rooms = {} end
	if table.contains(autoHarvest_rooms, gmcp.Room.Info.num) then
		return true
	else
		return false
	end
end

function ataxiaHarvester_harvested()
	if autoHarvesting or autoExtracting then
		autoHarvest_rooms = autoHarvest_rooms or {}
		if not table.contains(autoHarvest_rooms, gmcp.Room.Info.num) then table.insert(autoHarvest_rooms, gmcp.Room.Info.num) end
		if not ataxiaHarvester_manual_harvesting and not ataxiaHarvester_manual_extracting then
			for i,v in pairs(ataxiaBasher_path) do
				if tonumber(gmcp.Room.Info.num) == v then
					table.remove(ataxiaBasher_path, i)
					break
				end
			end
		end
	end
end


function get_herbHarvestTable()
	env_to_get = {
		["Desert"] = {"harvest pear"},
		["Forest"] = {"harvest elm", "harvest echinacea", "harvest ginseng", "harvest lobelia", "harvest myrrh", "harvest ginger"},
		["Freshwater"] = {"harvest kelp"},
		["Garden"] = {"harvest elm", "harvest echinacea", "harvest ginseng", "harvest lobelia", "harvest myrrh", "harvest ginger"},
		["Grasslands"] = {"harvest goldenseal", "harvest slipper",},
		["Hills"] = {"harvest bayberry", "harvest hawthorn"},
		["Jungle"] = {"harvest skullcap", "harvest kola", "harvest kuzu"},
		["Mountains"] = {"harvest valerian"},
		["Natural underground"] = {"harvest bloodroot", "harvest irid"},
		["Ocean"] = {"harvest kelp"},
		["River"] = {"harvest kelp"},
		["Swamp"] = {"harvest ash", "harvest bellwort", "harvest cohosh",},
		["Valley"] = {"harvest sileris"},
	}
end