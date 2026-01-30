if not ataxiaNDB then
	ataxiaEcho("Name database not currently loaded.")
else
	parsingQW = true
	peopleOnline = {}
	if matches[2] then
		parsingCity = matches[2]
	end
	sendGMCP("Comm.Channel.Players")
	send(" ")
	ataxiaNDB_GetOnline()
end