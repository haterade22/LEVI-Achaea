if not autoHarvesting then return end
deleteFull()

bashConsoleEchom("HERB", harvest_in_room[1]:gsub("harvest", "Harvested")..".", "SeaGreen", "a_darkgreen")
table.remove(harvest_in_room, 1)
if harvest_in_room[1] then
	send("queue addclear free "..harvest_in_room[1])
else

  if ataxiaExtraction[gmcp.Room.Info.area] then
    send("queue addclear free extract "..ataxiaExtraction[gmcp.Room.Info.area],false)
  end

  if ataxiaHarvester_manual_harvesting then
    if zgui then
      cecho("bashDisplay", " <green>"..string.char(8))
    else
      ataxiagui.bashConsole:cecho(" <green>"..string.char(8))
    end
  end
end
