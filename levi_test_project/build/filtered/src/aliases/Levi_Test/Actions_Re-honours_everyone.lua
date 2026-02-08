local count = 0
ataxiaEcho("Updating everyone who's currently in the database.")
for i,v in pairs(ataxiaNDB.players) do
	count = count + 1
	ataxiaNDB_Acquire(v.name:title(),false)
end
ataxiaEcho("Update complete. Total of "..count.." people have been re-checked.")