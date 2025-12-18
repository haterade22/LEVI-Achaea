-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > DRAGON > ATTACK LIMB > REND

function dragonrend()
local atk = combatQueue()

if tAff.shield then

   atk = atk.."wield shield;tailsmash "..target
 

else

atk = atk.."wield shield;rend left leg "..target

end

send("queue addclear free "..atk)

end