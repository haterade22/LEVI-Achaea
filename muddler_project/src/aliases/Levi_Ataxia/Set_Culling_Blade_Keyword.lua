local key = matches[2]:lower()
ataxiaBasher.targetList[gmcp.Room.Info.area].keyword = key
ataxia_Echo("Set the keyword for denizens in "..gmcp.Room.Info.area.." to "..key..".")
ataxia_saveSettings(false)