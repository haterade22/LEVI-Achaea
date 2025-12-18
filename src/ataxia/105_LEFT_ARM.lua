-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > MONK > LEFT ARM

function leftarm()

local atk = combatQueue()

if tLimbs.LA < 100 then
need_prep_left_arm = true
else 
need_prep_left_arm = false
end

if tAffs.shield then
need_raze = true
else 
need_raze = false
end



if need_prep_left_arm then

atk = atk.."unwield all;dismount;assess "..target..";combo "..target.." swk spp left spp left"

end


send("queue addclear free "..atk)

end
