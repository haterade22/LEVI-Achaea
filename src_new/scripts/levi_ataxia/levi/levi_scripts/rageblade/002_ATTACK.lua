--[[mudlet
type: script
name: ATTACK
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- DRAGON
- RAGEBLADE
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function ragedragon()
local atk = combatQueue()

if tAffs.shield then

   atk = atk.."wield shield rageblade;tailsmash "..target
 

elseif tAffs.rebounding then

   atk = atk.."wield shield rageblade;rend "..target.." "..ragevenom[1]..";dragoncurse "..target.." "..dragoncurse[1].." 1;breathgust "..target
 
 else

atk = atk.."wield shield rageblade;jab "..target.." "..ragevenom[1]..";dragoncurse "..target.." "..dragoncurse[1].." 1"



end
send("queue addclear free "..atk)

end