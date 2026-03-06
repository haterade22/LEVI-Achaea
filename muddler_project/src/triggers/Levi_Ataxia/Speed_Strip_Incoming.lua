if ataxiaNDB_Exists(target) then
	if ataxiaNDB_getClass(target) == "Jester" then
		ataxia_boxEcho("slowlock incoming - shield now", "yellow")
		send("queue addclear free touch shield",false)
	else
		ataxia_boxEcho("slowlock incoming - curseward now", "yellow")
		send("queue addclear free curseward",false)	
	end
end