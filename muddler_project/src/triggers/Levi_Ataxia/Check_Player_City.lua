if not ataxiaNDB._honoursPerson then return end
ataxiaNDB.players[ataxiaNDB._honoursPerson].city = matches[3]:title()

getNDBCity = matches[3]

selectString(matches[3], 1)
fg(ataxiaNDB.highlighting[matches[3]])
resetFormat()

raiseEvent("ataxiaNDB Check Highlight", ataxiaNDB._honoursPerson)
