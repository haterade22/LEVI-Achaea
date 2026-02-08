ataxiaNDB.cityEnemies = {}
table.insert(ataxiaNDB.cityEnemies, multimatches[2][2])
for person in multimatches[2][3]:gmatch("[%w'%-]+") do
	table.insert(ataxiaNDB.cityEnemies, person)
end
table.sort(ataxiaNDB.cityEnemies)
ataxiaEcho("Updated city enemies list.")

disableTrigger("City Enemies Capture")