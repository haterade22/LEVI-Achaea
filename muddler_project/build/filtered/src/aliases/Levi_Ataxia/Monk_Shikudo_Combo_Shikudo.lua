if stances[stance]["transition"][matches[5]] then transition = stances[stance]["transition"][matches[5]] end
local atkstring
if stance == "rain" and matches[2] ~= "r" then
	atkstring = stances[stance]["kick"][matches[2]].." "..stances[stance]["strike"][matches[3]].." "..stances[stance]["strike"][matches[4]]
else
	atkstring = stances[stance]["strike"][matches[2]].." "..stances[stance]["kick"][matches[3]].." "..stances[stance]["strike"][matches[4]]
end
if stance == "rain" and matches[2] ~= "r" then
	side = stances[stance]["kick"][matches[2]]:gsub("frontkick%s", "")
end
send("clearqueue all")
sendAll("queue add eqbal stand|stand|dismount|wield staff|order loyals follow me|order loyals kill "..target.."|combo "..target.." "..atkstring)
