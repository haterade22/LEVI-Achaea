if not autoExtracting then return end
deleteFull()

bashConsoleEchom("HERB", "Extracted "..ataxiaExtraction[gmcp.Room.Info.area]..".", "SeaGreen", "a_darkgreen")

ataxiaHarvester_harvested()