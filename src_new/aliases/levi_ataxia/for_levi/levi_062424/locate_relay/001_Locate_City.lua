--[[mudlet
type: alias
name: Locate City
hierarchy:
- Levi_Ataxia
- General
- Locate Relay
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^locate (\w+)$
command: ''
packageName: ''
]]--

local cmd = matches[2]:lower()
if cmd == "enemies" or cmd == "world" or cmd == "data" or cmd == "summary" then
  return
end
LocateSystem.start(matches[2])
send("pt Locating " .. string.upper(matches[2]) .. ".....")
