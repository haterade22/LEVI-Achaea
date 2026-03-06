--[[mudlet
type: alias
name: Aeon
hierarchy:
- Levi_Ataxia
- Classes
- Depthswalker
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^aeon(b)$
command: ''
packageName: ''
]]--

if matches[2] == "b" then
send("queue addclear free chrono aeon " ..target.. " boost")
else 
send("queue addclear free chrono aeon " ..target)
end