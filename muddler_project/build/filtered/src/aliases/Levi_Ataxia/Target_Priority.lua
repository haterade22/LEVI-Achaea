if not tprio then ataxiaEcho("Target Priority system not loaded.") return end
local input = matches[2]:gsub(",", "")
local names = input:split(" ")
tprio.addGroup(names)
