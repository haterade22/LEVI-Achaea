-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > MONK > RIGHT ARM

function rightarm()

local atk = combatQueue()

if tLimbs.RA < 100 then
need_prep_right_arm = true
else 
need_prep_right_arm = false
end

if tAffs.shield then
need_raze = true
else 
need_raze = false
end



if need_prep_right_arm then

atk = atk.."unwield all;dismount;assess "..target..";combo "..target.." swk spp right spp right"

end


send("queue addclear free "..atk)

end
