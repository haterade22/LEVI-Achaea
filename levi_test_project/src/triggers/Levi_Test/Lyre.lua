local lyreperson = matches[2]

if ataxiaNDB.players[lyreperson].city ~= "Mhaldor" then
send("pt " ..lyreperson.. " LYRED")
end