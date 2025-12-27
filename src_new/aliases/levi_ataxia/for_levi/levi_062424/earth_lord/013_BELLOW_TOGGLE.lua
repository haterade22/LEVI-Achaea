--[[mudlet
type: alias
name: BELLOW TOGGLE
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- EARTH LORD
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bel$
command: ''
packageName: ''
]]--

if bellow == false then

bellow = true

send("queue addclear free terran bellow")

elseif bellow == true then

bellow = false

send("clearqueue all")


end