-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > EARTH LORD > RIGHT SIDE

function rightside()
local atk = combatQueue()

if tAffs.shield == true then

atk = atk.."terran magnet rise;wield shield;terran crunch "..target



elseif ataxia.vitals.shaping == 4 and tLimbs.RL < 100
 then
 targetlimb = "right leg"
atk = atk.."terran magnet rise;wield shield;assess "..target..";manifest quake;terran powderise "..target.." "..targetlimb


elseif ataxia.vitals.shaping < 4 and tLimbs.RL < 100 then
targetlimb = "right leg"

atk = atk.."terran magnet rise;wield shield;assess "..target..";terran powderise "..target.." "..targetlimb



end

send("terran magnet rise;queue addclear free "..atk)
end