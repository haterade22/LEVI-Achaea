--[[mudlet
type: alias
name: BECKON ALL
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- APOSTATE
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^beck$
command: ''
packageName: ''
]]--

if ataxia_isClass("apostate") then
send("queue addclear free demon beckon")
end
if ataxia_isClass("depthswalker") then
send("queue addclear free shadow vortex")
end