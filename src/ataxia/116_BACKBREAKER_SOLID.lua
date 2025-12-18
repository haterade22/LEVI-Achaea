-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > MONK > BACKBREAKER > BACKBREAKER SOLID

function backbreakersolid()


local atk = combatQueue()


stance = stance or "scs"


if not tAffs.prone and not bruisedribs
then 
torso_prepped = true
else torso_prepped = false
end

if tLimbs.RL + ataxiaTables.limbData.tekuraHFP >= 100 and tLimbs.RL < 100
and tLimbs.LL + ataxiaTables.limbData.tekuraHFP >= 100 and tLimbs.LL < 100
and bruisedribs then


 legs_prepped = true
else legs_prepped = false
end



if  tAffs.prone then
back_breaker = true
else back_breaker = false

end



if torso_prepped then

atk = atk.."unwield all;dismount;assess "..target..";assess "..target..";wrt "..target.." torso;pmp "..target..";jbp "..target.." head;scs"

end

if legs_prepped then

atk = atk.."unwield all;dismount;assess "..target..";assess "..target..";combo "..target.." swk hfp right hfp left;drs"

end

if back_breaker then
atk = atk.."unwield all;dismount;assess "..target..";assess "..target..";bbt "..target


end

if legs_prepped then


send("queue addclear free "..atk)
tempTimer(0.05, [[ send("mind command apply restoration to arms") ]])
else

send("queue addclear free "..atk)


end
end