function leftleg()

local atk = combatQueue()

if tLimbs.LL < 100 then
need_prep_left_leg = true
else 
need_prep_left_leg = false
end

if tAffs.shield then
need_raze = true
else 
need_raze = false
end



if need_raze then

atk = atk.."unwield all;dismount;assess "..target..";combo "..target.." rhk hfp left hfp left"

end

if need_prep_left_leg then

atk = atk.."unwield all;dismount;assess "..target..";combo "..target.." snk left hfp left hfp left"

end


send("queue addclear free "..atk)

end
