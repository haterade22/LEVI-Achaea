-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > MONK > HEAD

function monkhead()

local atk = combatQueue()

if tLimbs.H < 100 then
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

atk = atk.."unwield all;dismount;assess "..target..";combo "..target.." wwk ucp ucp"

end


send("queue addclear free "..atk)

end
