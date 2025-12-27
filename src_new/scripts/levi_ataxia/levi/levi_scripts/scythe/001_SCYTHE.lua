--[[mudlet
type: script
name: SCYTHE
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- MONK
- SCYTHE
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function scythe()

local atk = combatQueue()

stance = stance or "scs"
impatiencemind = impatiencemind or false
battered = battered or false


if tLimbs.RL + ataxiaTables.limbData.tekuraHFP >= 100 and tLimbs.RL < 100  then
 legs_prepped = true
else legs_prepped = false
end


if battered and tAffs.damagedhead then
scythe_them = true
else scythe_them = false

end


if tAffs.prone and tLimbs.H < 100 then
prep_head = true
else prep_head = false
end

if tAffs.prone and tAffs.damagedhead and not epiparty then 
wrench_head = true
else wrench_head = false

end





if tAffs.shield then
need_raze = true
else 
need_raze = false
end




if scythe_them then

atk = atk.."unwield all;dismount;assess "..target..";mind scythe"

end

if epiparty and not impatiencemind and not battered then


atk = atk.."unwield all;dismount;assess "..target..";assess "..target..";mind impatience"

end


if epiparty and impatiencemind then


atk = atk.."unwield all;dismount;assess "..target..";assess "..target..";mind batter"

end

if legs_prepped then

atk = atk.."unwield all;dismount;assess "..target..";assess "..target..";combo "..target.." swk hfp right jbp head;drs"

end

if prep_head then

atk = atk.."unwield all;dismount;assess "..target..";assess "..target..";combo "..target.." axk hfp left pmp;hrs"

end

if wrench_head then

atk = atk.."unwield all;dismount;assess "..target..";assess "..target..";combo "..target.." wrt head blp pmp;drs"


end





if legs_prepped then


send("queue addclear free "..atk)
tempTimer(0.05, [[ send("mind command apply restoration to arms") ]])

elseif prep_head then


send("queue addclear free "..atk)
tempTimer(0.05, [[ send("mind command restore") ]])



else
send("queue addclear free "..atk)


end



end