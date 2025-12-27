--[[mudlet
type: alias
name: DRAGONTHING
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- DRAGON TALISMAN
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^thing$
command: ''
packageName: ''
]]--

if not dragonthing then dragonthing = "claw" end
if dragonthing == "claw" then dragonthing = "bone"
elseif dragonthing == "bone" then dragonthing = "leather"
elseif dragonthing == "leather" then dragonthing = "tooth"
elseif dragonthing == "tooth" then dragonthing = "heart"
elseif dragonthing == "heart" then dragonthing = "scale"
elseif dragonthing == "scale" then dragonthing = "eye"
elseif dragonthing == "eye" then dragonthing = "claw"

end

cecho("\nYOUR DRAGON COLOR IS: "..color.." AND YOU ARE COMBINING "..dragonthing)