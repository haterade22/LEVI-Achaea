ataxiaNDB.player_Notes = ataxiaNDB.player_Notes or {}
ataxia_Echo("Getting information on <green>"..matches[2]:title().."...")

ataxiaNDB_Acquire(matches[2]:title(),false)
ataxiaNDB.checking = true
