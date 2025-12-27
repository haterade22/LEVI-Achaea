--[[mudlet
type: alias
name: JUMPING
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- General
- MOVEMENT
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^mj$
command: ''
packageName: ''
]]--

jumping = jumping or false

if jumping == false then
ataxiaEcho("YOU ARE NOW JUMPING LIKE THE FOOL YOU ARE")
jumping = true

elseif jumping == true then
ataxiaEcho("YOUR SENSES RETURN TO NORMAL. YOU NO LONGER JUMP")
jumping = false

end