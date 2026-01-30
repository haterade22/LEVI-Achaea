ataxiaTemp.alertness = ataxiaTemp.alertness or {}
local person, dir = matches[2], matches[4]

if dir == "location" then dir = "here" end

--if matches[4] == "location" and (ataxiaNDB.players[matches[2]].city ~= "None" or ataxiaNDB.players[matches[2]].city ~= "Unknown" or ataxiaNDB.players[matches[2]].city ~= "Undercity") then
--send("queue addclear free soulbleed shackle living")
--end

ataxiaTemp.alertness[dir] = ataxiaTemp.alertness[dir] or {}
if not table.contains(ataxiaTemp.alertness[dir], person) then
  table.insert(ataxiaTemp.alertness[dir], person)
end
table.sort(ataxiaTemp.alertness[dir])

deleteLine()

if beckonmode then 
send("cq all;demon beckon "..person)
end