-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > MONK > SWEEP LL

function sweepleftleg()

local atk = combatQueue()

if tLimbs.RL < 100 then
need_prep_left_leg = true
else 
need_prep_left_leg = false
end


if tAffs.shield then
need_raze = true
else 
need_raze = false
end


if need_prep_left_leg then

atk = atk.."unwield all;dismount;assess "..target..";assess "..target..";combo "..target.." swk hfp left hfp left"

end


send("queue addclear free "..atk)

end
