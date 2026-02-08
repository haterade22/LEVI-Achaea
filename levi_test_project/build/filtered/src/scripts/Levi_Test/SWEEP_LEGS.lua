function sweeplegs()

local atk = combatQueue()

if tLimbs.RL < 100 and tLimbs.LL < 100 then
need_prep_legs = true
else 
need_prep_legs = false
end


if tAffs.shield then
need_raze = true
else 
need_raze = false
end


if need_raze then

atk = atk.."unwield all;dismount;assess "..target..";combo "..target.." rhk hfp right hfp right"

end

if need_prep_legs then

atk = atk.."unwield all;dismount;assess "..target..";assess "..target..";combo "..target.." swk hfp left hfp right"

end


send("queue addclear free "..atk)

end
