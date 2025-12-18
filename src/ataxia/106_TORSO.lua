-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > MONK > TORSO

function monktorso()

local atk = combatQueue()

if tLimbs.T < 200 then
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

atk = atk.."unwield all;dismount;assess "..target..";combo "..target.." sdk hkp hkp;hrs"

end


send("queue addclear free "..atk)

end
