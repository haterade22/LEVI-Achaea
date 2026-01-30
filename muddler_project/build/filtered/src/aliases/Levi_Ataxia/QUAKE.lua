local atk = combatQueue()


if shape > 1 and
 ataxiaTemp.parriedLimb == "torso" then
atk = atk.."terran magnet rise;wield shield;assess "..target..";manifest quake;terran powderise "..target.." torso"

elseif shape > 1 and
 ataxiaTemp.parriedLimb == "head" then
atk = atk.."terran magnet rise;wield shield;assess "..target..";manifest quake;terran powderise "..target.." head"

elseif shape > 1 and
 ataxiaTemp.parriedLimb == "right leg" then
atk = atk.."terran magnet rise;wield shield;assess "..target..";manifest quake;terran powderise "..target.." right leg"

elseif shape > 1 and
 ataxiaTemp.parriedLimb == "left leg" then
atk = atk.."terran magnet rise;wield shield;assess "..target..";manifest quake;terran powderise "..target.." left leg"

elseif shape == 4
and ataxiaTemp.parriedLimb == "none" then

atk = atk.."terran magnet rise;wield shield;assess "..target..";manifest quake;terran powderise "..target.." "..targetlimb


elseif shape < 2 then


atk = atk.."terran magnet rise;wield shield;assess "..target..";manifest quake"

end
send("queue addclear free "..atk)
