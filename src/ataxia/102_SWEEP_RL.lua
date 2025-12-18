-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > MONK > SWEEP RL

function sweeprightleg()

local atk = combatQueue()

if tLimbs.RL < 100 then
need_prep_right_leg = true
else 
need_prep_right_leg = false
end

if tAffs.shield then
need_raze = true
else 
need_raze = false
end



if need_raze then

atk = atk.."unwield all;dismount;assess "..target..";combo "..target.." rhk hfp right hfp right"

end

if need_prep_right_leg then

atk = atk.."unwield all;dismount;assess "..target..";assess "..target..";combo "..target.." swk hfp right hfp right"

end


send("queue addclear free "..atk)

end
