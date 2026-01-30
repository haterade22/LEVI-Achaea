function headpath()
 limbtable() 
local atk = combatQueue()

if tAffs.shield == true then

atk = atk.."terran magnet rise;wield shield;terran crunch "..target

elseif ataxia.vitals.shaping

and tLimbs.H >= 100 and tAffs.prone then


atk = atk.."terran magnet rise;wield shield;assess "..target..";manifest avalanche"


elseif ataxia.vitals.shaping == 4


and tLimbs.RL >= 80
and tLimbs.LL >= 80
and tLimbs.H < 63 then


targetlimb = "head"


atk = atk.."terran magnet rise;wield shield;assess "..target..";manifest quake;terran powderise "..target.." "..targetlimb


elseif ataxia.vitals.shaping < 4


and tLimbs.RL >= 80
and tLimbs.LL >= 80
and tLimbs.H < 63 then

if ataxiaTemp.parriedLimb == "head" then
targetlimb = mytable[math.random(#mytable)]
else 
targetlimb = "head"
end

atk = atk.."terran magnet rise;wield shield;assess "..target..";terran powderise "..target.." "..targetlimb




elseif ataxia.vitals.shaping == 4 and not tAffs.prone


and tLimbs.RL >= 80 and tLimbs.RL < 100
and tLimbs.LL >= 80 and tLimbs.LL < 100
and tLimbs.H > 63 and tLimbs.H < 100 then

if ataxiaTemp.parriedLimb == "right leg" then
targetlimb = "left leg"
else 
targetlimb = "right leg"
end


atk = atk.."terran magnet rise;wield shield;assess "..target..";manifest quake;terran powderise "..target.." "..targetlimb



elseif ataxia.vitals.shaping


and tLimbs.RL >= 100
and tLimbs.LL < 84
and tLimbs.H >= 63 then

if ataxiaTemp.parriedLimb == "left leg" and not tAffs.prone then
targetlimb = mytable[math.random(#mytable)]
else 
targetlimb = "left leg"
end

atk = atk.."terran magnet rise;wield shield;assess "..target..";terran powderise "..target.." "..targetlimb


elseif ataxia.vitals.shaping == 4



and tLimbs.LL >= 100
and tLimbs.H >= 63 then
if ataxiaTemp.parriedLimb == "right leg" and not tAffs.prone then
targetlimb = mytable[math.random(#mytable)]
else 
targetlimb = "head"
end

atk = atk.."terran magnet rise;wield shield;assess "..target..";terran calcify "..target.." head;terran powderise "..target.." "..targetlimb




elseif ataxia.vitals.shaping == 4


and (tLimbs.RL > 84 or tLimbs.LL > 84)
and tLimbs.H >= 63 then

if ataxiaTemp.parriedLimb == "head" then
targetlimb = mytable[math.random(#mytable)]
else 
targetlimb = "head"
end

atk = atk.."terran magnet rise;wield shield;assess "..target..";terran calcify "..target.." head;terran powderise "..target.." "..targetlimb







end

send("terran magnet rise;queue addclear free "..atk)
end