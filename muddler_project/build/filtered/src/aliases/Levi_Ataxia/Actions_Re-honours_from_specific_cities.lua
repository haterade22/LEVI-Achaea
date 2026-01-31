local count = 0
ataxiaEcho("Re-checking everyone matching the '"..matches[2].."' city.")
for i,v in pairs(ataxiaNDB.players) do
  if v.city:lower() == matches[2]:lower() then
	 ataxiaNDB_Acquire(v.name:title(),false)
   count = count + 1
  end
end
ataxiaEcho("Update complete. Total of "..count.." people have been re-checked.")