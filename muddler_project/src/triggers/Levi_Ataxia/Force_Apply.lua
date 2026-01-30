if multimatches[1][4] == ataxiaTemp.me and ataxiaNDB_getClass(target) == "Shaman" then
	ataxia_boxEcho("You should probably curseward", "yellow")
	send("queue addclear free curseward",false)
elseif multimatches[1][4] == ataxiaTemp.me and ataxiaNDB_getClass(target) == "Jester" then
	ataxia_boxEcho("You should probably shield soon", "yellow")
	send("queue addclear free touch shield",false)
end