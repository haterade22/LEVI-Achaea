--[[mudlet
type: alias
name: KAI CRIPPLE
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- Monks
- Monk
- Kaido
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^kcr$
command: ''
packageName: ''
]]--

if ataxia.vitals.class >= 41 then 
send("queue addclear free kai cripple " ..target)
end
