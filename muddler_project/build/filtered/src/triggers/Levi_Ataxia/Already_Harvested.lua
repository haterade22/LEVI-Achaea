if not autoHarvesting then return end
	if harvest_in_room[1] then
		local xxx = harvest_in_room[1]
		deleteFull()
		
		bashConsoleEchom("HERB", "Already done "..harvest_in_room[1]..".", "DimGrey", "DarkSlateBlue")
		
		if #harvest_in_room > 0 and table.contains(harvest_in_room, xxx) then
			table.remove(harvest_in_room, table.index_of(harvest_in_room, xxx))
		end
	end
	if #harvest_in_room == 0 and canBals() then
    
    if ataxiaExtraction[gmcp.Room.Info.area] then
      send("queue addclear free extract "..ataxiaExtraction[gmcp.Room.Info.area],false)
    end
		if ataxiaHarvester_manual_harvesting then
      if zgui then
        cecho("bashDisplay", " <green>"..string.char(8))
      else
        ataxiagui.bashConsole:cecho(" <green>"..string.char(8))
      end
		else
			ataxiaHarvester_check()
		end
	end