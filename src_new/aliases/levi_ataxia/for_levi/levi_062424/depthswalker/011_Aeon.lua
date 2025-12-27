--[[mudlet
type: alias
name: Aeon
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- DEPTHSWALKER
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