function backbreaker()
 

local atk = combatQueue()

stance = stance or "scs"

limbpreptekura()




if tAffs.prone then
back_breaker = true
else back_breaker = false

end

if leftarm_prepped_punch and not rightarm_prepped_punch and puncharm == "spp left" then puncharm = "spp right"
elseif
rightarm_prepped_punch and not leftarm_prepped_punch and puncharm == "spp right" then puncharm = "spp left"
elseif
leftarm_prepped_kick and not rightarm_prepped_kick and kickarm == "mnk left" then kickarm = "mnk right"
elseif
rightarm_prepped_kick and not leftarm_prepped_kick and kickarm == "mnk right" then kickarm = "mnk left"

end

if leftleg_prepped_punch and not rightleg_prepped_punch and punchleg == "hfp left" then punchleg = "hfp right"
elseif
rightleg_prepped_punch and not leftleg_prepped_punch and punchleg == "hfp right" then punchleg = "hfp left"
elseif
leftleg_prepped_kick and not rightleg_prepped_kick and kickleg == "snk left" then kickleg = "snk right"
elseif
rightleg_prepped_kick and not leftleg_prepped_kick and kickleg == "snk right" then kickleg = "snk left"

end




if back_breaker then
stance = "scs"
atk = atk.."unwield all;dismount;assess "..target..";bbt "..target

elseif legs_prepped_punch and tAffs.damagedleftarm and stance == "hrs" and not tAffs.prone then
stance = "scs"

atk = atk.."unwield all;dismount;assess "..target..";combo "..target.." wrt left arm hfp right hfp left;"..stance

elseif legs_prepped_punch and tAffs.damagedrightarm and stance == "hrs" and not tAffs.prone then
stance = "scs"

atk = atk.."unwield all;dismount;assess "..target..";combo "..target.." wrt right arm hfp right hfp left;"..stance

elseif legs_prepped_punch and tAffs.damagedtorso and not tAffs.prone then 
stance = "scs"

atk = atk.."unwield all;dismount;assess "..target..";combo "..target.." swk hfp right hfp left;"..stance

elseif torso_prepped_kick and rightleg_prepped_punch and leftleg_prepped_punch then
stance = "scs"

atk = atk.."unwield all;dismount;assess "..target..";combo "..target.." sdk hfp right hfp left;"..stance

elseif not legs_prepped_punch then
stance = "scs"

atk = atk.."unwield all;dismount;assess "..target..";combo "..target.." "..kickleg.." "..punchleg.." "..punchleg..";"..stance


else
stance = "scs"

atk = atk.."unwield all;dismount;assess "..target..";combo "..target.." "..kickarm.." "..puncharm.." "..puncharm..";"..stance

end


send("queue addclear free "..atk)



end