--[[mudlet
type: script
name: REND
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- DRAGON
- ATTACK LIMB
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function dragonrend()
local atk = combatQueue()

if tAff.shield then

   atk = atk.."wield shield;tailsmash "..target
 

else

atk = atk.."wield shield;rend left leg "..target

end

send("queue addclear free "..atk)

end