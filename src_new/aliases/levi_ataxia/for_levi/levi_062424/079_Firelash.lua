--[[mudlet
type: alias
name: Firelash
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- Artefacts
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^fl(i|g|v|t)$
command: ''
packageName: ''
]]--

if matches[2] == "i" then
send("queue addclear free point bracers151113 at icewall")
end
if matches[2] == "g" then
send("queue addclear free point bracers151113 at ground")
end

if matches[2] == "v" then
send("queue addclear free point bracers151113 at vines")
end

if matches[2] == "t" then

send("queue addclear free point bracers151113 at totem")
end