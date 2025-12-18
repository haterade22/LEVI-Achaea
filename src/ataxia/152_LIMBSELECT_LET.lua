-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > INFERNAL > INFERNAL > TWO HANDED > LIMBSELECT LET

function limbselectLET()


local prepped_speed = prepped_speed or 25
local prepped_precision = prepped_precision or 12.5

local scimdamage = ataxiaTables.limbData.twoHander or 15
local totalfracs = ataxiaTemp.fractures.skullfractures + ataxiaTemp.fractures.crackedribs + ataxiaTemp.fractures.torntendons + ataxiaTemp.fractures.wristfractures 
if totalfracs >= 1 then bfocus = "speed" else bfocus = "precision" end
if scimdamage < 17 then  prepped_precision = scimdamage end
if scimdamage > 17 then  prepped_speed = scimdamage end





--if bfocus == "speed" then limdamage = prepped_speed elseif bfocus == "precision" then limdamage = prepped_precision end
limdamage = prepped_speed

if  tLimbs.LL + limdamage >= 100 and tLimbs.LL < 100 and not tAffs.damagedleftleg then 
 prepped_leftleg = true else
prepped_leftleg = false

end

if  tLimbs.RL + limdamage >= 100 and tLimbs.RL < 100 then 
 prepped_rightleg = true else
prepped_rightleg = false

end

if  tLimbs.RA + limdamage >= 100 and tLimbs.RA < 100 then 
 prepped_rightarm = true else
prepped_rightarm = false

end

if  tLimbs.LA + limdamage >= 100 and tLimbs.LA < 100 then 
 prepped_leftarm = true else
prepped_leftarm = false

end

if  tLimbs.H + limdamage >= 100 and tLimbs.H < 100 then 
 prepped_head = true else
prepped_head = false

end

if  tLimbs.T + limdamage >= 200 and tLimbs.T < 200 then 
 prepped_torso = true else
prepped_torso = false

end

if prepped_rightarm and prepped_leftarm then
arm_prep = true
else
arm_prep = false
end

if prepped_rightleg and prepped_leftleg then
leg_prep = true
else
leg_prep = false
end

if leg_prep and arm_prep then full_prep = true
else
full_prep = false
end

if ataxiaTemp.fractures.skullfractures >= 3 then
can_overwhelm = true
else can_overwhelm = false
end

if  ataxiaTemp.fractures.torntendons >= 6 or (ataxiaTemp.fractures.torntendons >= 4 and ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 60) then
can_devastate_legs = true else
can_devastate_legs = false 
end

if  ataxiaTemp.fractures.wristfractures >= 4 then
can_devastate_arms = true else
can_devastate_arms = false 
end

targetlimb = {}

if full_prep then
  table.insert(targetlimb,"right leg")
    table.insert(targetlimb,"left leg")

end

if not prepped_rightarm then
  table.insert(targetlimb,"right arm")
end

if not prepped_leftarm then
  table.insert(targetlimb,"left arm")
end

if not prepped_rightleg then
  table.insert(targetlimb,"right leg")
end

if not prepped_leftleg then
  table.insert(targetlimb,"left leg")
end

if not prepped_head then
  table.insert(targetlimb,"head")
end



if not prepped_torso then
  table.insert(targetlimb,"torso")
end



if ataxiaTemp.parriedLimb == targetlimb[1] and not tAffs.prone and targetlimb[2] ~= "torso" then 
targetlimb[1] = targetlimb[2]
elseif 
ataxiaTemp.parriedLimb == targetlimb[1] and not tAffs.prone and targetlimb[2] ~= "torso" then 
targetlimb[1] = targetlimb[3]

end
infernaltwohandhammer()

end