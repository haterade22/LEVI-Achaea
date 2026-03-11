if not tprio then return end
local input = matches[2]:gsub(",", "")
local names = input:split(" ")
tprio.addGroup(names)
ataxiaEcho("Received target priority from party.")
