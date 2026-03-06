--[[mudlet
type: alias
name: BELLOW TOGGLE
hierarchy:
- Levi_Ataxia
- Classes
- Earth Lord
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