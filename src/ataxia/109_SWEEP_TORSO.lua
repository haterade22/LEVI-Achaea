-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > MONK > SWEEP TORSO

function sweeptorso()

local atk = combatQueue()

if tLimbs.T < 100 then
need_prep_torso = true
else 
need_prep_torso = false
end


if tAffs.shield then
need_raze = true
else 
need_raze = false
end


if need_prep_torso then

atk = atk.."unwield all;dismount;assess "..target..";combo "..target.." swk hkp hkp"

end


send("queue addclear free "..atk)

end
