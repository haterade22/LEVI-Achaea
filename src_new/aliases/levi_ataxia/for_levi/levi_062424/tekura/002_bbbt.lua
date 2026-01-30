--[[mudlet
type: alias
name: bbbt
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- Monks
- Monk
- Monk
- Tekura
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bb$
command: ''
packageName: ''
]]--

if ataxia.vitals.class >= 10 and ataxia.vitals.stance ~= "Bear" and tAffs.prone then
send("queue addclear free kai transition bear;bbt " ..target)
elseif ataxia.vitals.class <= 9 and tAffs.prone then
send("queue addclear free bbt " ..target)
else
send("queue addclear free bbt " ..target)
end