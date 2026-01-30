function sweephead()

local atk = combatQueue()

if tLimbs.H < 200 then
need_prep_head = true
else 
need_prep_head = false
end

if tAffs.shield then
need_raze = true
else 
need_raze = false
end



if need_prep_head then

atk = atk.."unwield all;dismount;assess "..target..";combo "..target.." swk ucp ucp"

end


send("queue addclear free "..atk)

end
