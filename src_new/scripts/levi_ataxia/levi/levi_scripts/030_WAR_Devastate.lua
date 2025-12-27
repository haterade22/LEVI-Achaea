--[[mudlet
type: script
name: WAR Devastate
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- INFERNAL
- INFERNAL
- TWO HANDED
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function infernaltwohandhammerdev()
			--	ataxia_breakLock()






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



if not prepped_rightleg then
  table.insert(targetlimb,"right leg")
end

if not prepped_leftleg then
  table.insert(targetlimb,"left leg")
end


if not prepped_rightarm then
  table.insert(targetlimb,"right arm")
end

if not prepped_leftarm then
  table.insert(targetlimb,"left arm")
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




























local atk = combatQueue()
--INVESTS

devastated = devastated or false
if precision_hit then bfocus = "precision" 
elseif not tBals.salve then bfocus = "precision" else bfocus = bfocus end

 venoms = {}


if not tAffs.slickness and tAffs.asthma then
  table.insert(venoms,"gecko")

end

if not tAffs.paralysis then
  table.insert(venoms,"curare")

end

if not tAffs.asthma then
  table.insert(venoms,"kalmia")

end








invest = {}



if not tAffs.healthleech then invest = "torment"


elseif not tAffs.haemophilia then invest = "torture"

elseif not tAffs.weariness then invest = "exploit"


elseif getMentalAffCount() >= 4 then invest = "punishment" 

else invest = "torment" end




--ATTACK



if tAffs.impaled then
disembowel = true
else
disembowel = false
end




if tAffs.rebounding then

need_raze = true
else
need_raze = false
end

if tAffs.shield then

need_raze2 = true
else
need_raze2 = false
end




if (tAffs.brokenrightleg or tAffs.damagedrightleg) and (tAffs.brokenleftleg or tAffs.damagedleftleg)
 and (tAffs.brokenleftarm or tAffs.damagedleftarm)  and  (tAffs.brokenrightarm or tAffs.damagedrightarm) then
vivisect = true
else
vivisect = false
end

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 20 then
quash_arc = true
else
quash_arc = false
end




if quash_arc then

atk = "stand/wield shield longsword/assess "..target.."/quash "..target.."/arc curare"

elseif vivisect then
atk = atk.."assess "..target..";wipe "..wield_weapon..";hellforge invest "..invest..";dismount;vivisect "..target..";battlefury perceive "..target

elseif disembowel
then 


atk = atk.."battlefury focus speed;hellforge invest "..invest..";disembowel "..target..";battlefury perceive "..target..";assess "..target

elseif tAffs.prone and devastated then

atk = atk.."wield bastard;wipe bastard;battlefury perceive "..target..";hellforge invest "..invest..";battlefury focus speed;impale "..target..";assess "..target


elseif need_raze or need_raze2 then
bfocus = "speed"
atk = atk.."wield warhammer;wipe warhammer;battlefury perceive "..target..";battlefury focus "..bfocus..";hellforge invest "..invest..";splinter "..target..";assess "..target


elseif can_devastate_legs then

atk = atk.."wield warhammer;wipe warhammer;hellforge invest "..invest..";devastate "..target.." legs;battlefury upset "..target..";assess "..target


elseif tAffs.prone and can_overwhelm then

atk = atk.."wield warhammer;wipe warhammer;hellforge invest "..invest..";battlefury overwhelm "..target..";fury;brain "..target..";assess "..target

elseif leg_prep and not tAffs.prone then

atk = atk.."wield warhammer;wipe warhammer;hellforge invest "..invest..";pulverise "..target.." right leg;battlefury upset "..target..";assess "..target

elseif tAffs.damagedrightleg and tAffs.prone then

atk = atk.."wield warhammer;wipe warhammer;hellforge invest "..invest..";pulverise "..target.." left leg;battlefury upset "..target..";assess "..target

elseif targetlimb[1] == "right leg" or targetlimb[1] == "left leg" or targetlimb[1] == "left arm" or targetlimb[1] == "right arm" then

atk = atk.."wield warhammer;wipe warhammer;battlefury perceive "..target..";battlefury focus speed;hellforge invest "..invest..";pulverise "..target.." "..targetlimb[1]..";assess "..target


elseif    targetlimb[1] == "head"  then

atk = atk.."wield warhammer;wipe warhammer;battlefury perceive "..target..";battlefury focus precision;hellforge invest "..invest..";overhand "..target..";assess "..target


else
atk = atk.."wield warhammer;wipe warhammer;battlefury perceive "..target..";battlefury focus "..bfocus..";hellforge invest "..invest..";slaughter "..target..";battlefury perceive "..target..";assess "..target


end



if table.contains(ataxia.playersHere, target) then

if gmcp.Char.Vitals.bal == "0"
or gmcp.Char.Vitals.eq == "0"
then
send("cq all")
end

if gmcp.Char.Vitals.bal == "1"
and gmcp.Char.Vitals.eq == "1" then

if quash_arc then
send("setalias quasharc "..atk)
send("queue addclear free quasharc")

elseif not engaged then
send("queue addclear free discipline;"..atk..";engage "..target..";tyranny;order hyena kill "..target)

else

send("queue addclear free discipline;"..atk..";tyranny")

end
end

end

end

