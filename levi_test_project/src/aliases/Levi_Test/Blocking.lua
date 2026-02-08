local act = matches[2]
local dirs = {"nw", "n", "ne", "e", "se", "s", "sw", "w", "u", "d", "in", "out"}

if act == "unblock" then
	ataxiaTemp.blocking = nil
	send("unblock",false)
else
	if matches[3] and table.contains(dirs, matches[3]) then
		ataxiaTemp.blocking = matches[3]
		send("block "..ataxiaTemp.blocking,false)
	else
		ataxia_Echo("Invalid direction to block.")
	end
end