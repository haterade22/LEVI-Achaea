-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > INFERNAL > Infernal 2H > TWO HANDED > Infernal Two Hand

function infernaltwohand()
tfractureamt = tfractureamt or 0
tfractureloc = tfractureloc or nil
tpriofrac = tpriofrac or "none"
local atk = combatQueue()
twohanddamage = ataxiaTables.limbData.twoHander

--INVESTS

invest = invest or "exploit"
if tAffs.haemophilia and tAffs.healthleech and not tAffs.confusion then
invest = "torment"
elseif tAffs.healthleech and not tAffs.haemophilia then
invest = "torture"
elseif not tAffs.healthleech and tAffs.weariness then
invest = "torment"
elseif not tAffs.weariness then 
invest = "exploit"
else
invest = "exploit"
end

--Venoms
venoms = {}


if not tAffs.paralysis then
  table.insert(venoms,"curare")

end

if not tAffs.nausea then
  table.insert(venoms,"euphorbia")

end

if not tAffs.asthma then
  table.insert(venoms,"kalmia")

end

if not tAffs.clumsiness then
  table.insert(venoms,"xentio")

end

if not tAffs.sensitivity then
  table.insert(venoms,"prefarar")

end


if not tAffs.slickness and tAffs.asthma then
  table.insert(venoms,"gecko")

end





--ATTACK

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 30 then
quash_arc = true
else
quash_arc = false
end

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 40 and tAffs.sensitivity then
quash_arc2 = true
else
quash_arc2 = false
end

if tAffs.impaled then
disembowel = true
else
disembowel = false
end

if tAffs.rebounding or tAffs.shield then
need_raze = true
else
need_raze = false
end

if not tAffs.rebounding and tAffs.shield then
need_shieldraze = true
else
need_shieldraze = false
end


if (tAffs.brokenrightleg or tAffs.damagedrightleg) and (tAffs.brokenleftleg or tAffs.damagedleftleg) and (tAffs.brokenleftarm or tAffs.damagedleftarm)  and  (tAffs.brokenrightarm or tAffs.damagedrightarm) and tAffs.prone then
vivisect = true
else
vivisect = false
end



if lb[target].hits["left leg"] + twohanddamage > 100 and not tAffs.damagedleftleg then 
prepped_leftleg = true else
prepped_leftleg = false

end

if lb[target].hits["right leg"] + twohanddamage > 100 and not tAffs.damagedrightleg then 
prepped_rightleg = true else
prepped_rightleg = false

end

if lb[target].hits["right arm"] + twohanddamage > 100 and not tAffs.damagedrightarm then 
prepped_rightarm = true else
prepped_rightarm = false

end

if lb[target].hits["left arm"] + twohanddamage > 100 and not tAffs.damagedleftarm then 
prepped_leftarm = true else
prepped_leftarm = false
end

-- Target Limb and Battlefury Focus

if disembowel then 

  atk = atk.."wield bastard405364;battlefury perceive "..target..";hellforge invest "..invest..";disembowel "..target..";assess "..target

elseif quash_arc == true or quash_arc2 == true then

  atk = "stand;wield bastard405364;assess "..target..";quash "..target..";arc curare"

elseif vivisect then
  atk = atk.."dismount;vivisect "..target..";assess "..target

elseif need_shieldraze then
  atk = "stand;wield shield bastard;assess "..target..";quash "..target..";arc curare"

elseif need_raze and not tAffs.prone then
  atk = atk.."wield warhammer109410;wipe warhammer109410;battlefury perceive "..target..";battlefury focus speed;hellforge invest "..invest..";splinter "..target..";assess "..target

elseif tAffs.prone then
  atk = atk.."wield bastard405364;wipe bastard405364;battlefury perceive "..target..";hellforge invest "..invest..";impale "..target..";assess "..target

elseif ataxiaTemp.fractures.torntendons == 6 then 
  atk = atk.."wield warhammer109410;wipe warhammer109410;battlefury perceive "..target..";hellforge invest "..invest..";devastate "..target.." legs;battlefury upset "..target..";assess "..target

elseif ataxiaTemp.fractures.torntendons == 5 and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.."wield bastard405364;wipe bastard405364;battlefury perceive "..target.."battlefury focus speed;envenom bastard with " ..venoms[1].. ";hew " ..target.. " left leg;assess " ..target

elseif ataxiaTemp.fractures.torntendons == 5 and ataxiaTemp.parriedLimb ~= "right leg" then
  atk = atk.."wield bastard405364;wipe bastard405364;battlefury perceive "..target.."battlefury focus speed;envenom bastard with " ..venoms[1].. ";hew " ..target.. " right leg;assess " ..target


elseif ataxiaTemp.fractures.torntendons == 4 and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.."wield warhammer109410;wipe warhammer109410;battlefury perceive "..target..";battlefury focus precision;hellforge invest "..invest..";pulverise "..target.. " left leg;assess "..target

elseif ataxiaTemp.fractures.torntendons == 4 and ataxiaTemp.parriedLimb ~= "right leg" then
  atk = atk.."wield warhammer109410;wipe warhammer109410;battlefury perceive "..target..";battlefury focus precision;hellforge invest "..invest..";pulverise "..target.. " right leg;assess "..target


elseif ataxiaTemp.fractures.torntendons == 3 and (ataxiaTemp.fractures.skullfractures >= 1 or ataxiaTemp.fractures.crackedribs >= 1) and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.."wield warhammer109410;wipe warhammer109410;battlefury perceive "..target..";battlefury focus precision;hellforge invest "..invest..";pulverise "..target.. " left leg;assess "..target

elseif ataxiaTemp.fractures.torntendons == 3 and (ataxiaTemp.fractures.skullfractures >= 1 or ataxiaTemp.fractures.crackedribs >= 1) and ataxiaTemp.parriedLimb ~= "right leg" then
  atk = atk.."wield warhammer109410;wipe warhammer109410;battlefury perceive "..target..";battlefury focus precision;hellforge invest "..invest..";pulverise "..target.. " right leg;assess "..target

elseif ataxiaTemp.fractures.torntendons == 2 and (ataxiaTemp.fractures.skullfractures >= 1 or ataxiaTemp.fractures.crackedribs >= 1) and ataxiaTemp.parriedLimb ~= "left leg" then

  atk = atk.."wield bastard405364;wipe bastard405364;battlefury perceive "..target.."battlefury focus speed;envenom bastard with " ..venoms[1].. ";hew " ..target.. " left leg;assess " ..target

elseif ataxiaTemp.fractures.torntendons == 2 and (ataxiaTemp.fractures.skullfractures >= 1 or ataxiaTemp.fractures.crackedribs >= 1) and ataxiaTemp.parriedLimb ~= "right leg" then

  atk = atk.."wield bastard405364;wipe bastard405364;battlefury perceive "..target.."battlefury focus speed;envenom bastard with " ..venoms[1].. ";hew " ..target.. " right leg;assess " ..target

elseif ataxiaTemp.fractures.torntendons < 1 and (ataxiaTemp.fractures.skullfractures >= 1 or ataxiaTemp.fractures.crackedribs >= 1 and ataxiaTemp.fractures.wristfractures >= 1) and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.."wield warhammer109410;wipe warhammer109410;battlefury perceive "..target..";battlefury focus precision;hellforge invest "..invest..";pulverise "..target.. " left leg;assess "..target
elseif ataxiaTemp.fractures.torntendons < 1 and (ataxiaTemp.fractures.skullfractures >= 1 or ataxiaTemp.fractures.crackedribs >= 1 and ataxiaTemp.fractures.wristfractures >= 1) and ataxiaTemp.parriedLimb ~= "right leg" then
  atk = atk.."wield warhammer109410;wipe warhammer109410;battlefury perceive "..target..";battlefury focus precision;hellforge invest "..invest..";pulverise "..target.. " right leg;assess "..target

elseif ataxiaTemp.fractures.skullfractures < 1 and ataxiaTemp.parriedLimb ~= "head" then
  atk = atk.."wield warhammer109410;wipe warhammer109410;battlefury perceive "..target..";battlefury focus precision;hellforge invest "..invest..";overhand "..target.. ";assess "..target

elseif ataxiaTemp.fractures.crackedribs < 1 and ataxiaTemp.parriedLimb ~= "torso" then

  atk = atk.."wield warhammer109410;wipe warhammer109410;battlefury perceive "..target..";battlefury focus precision;hellforge invest "..invest..";underhand "..target.. ";assess "..target

elseif ataxiaTemp.fractures.wristfractures < 1 and ataxiaTemp.parriedLimb ~= "left arm" then

atk = atk.."wield bastard405364;wipe bastard405364;battlefury perceive "..target.."battlefury focus speed;envenom bastard with " ..venoms[1].. ";hew " ..target.. " left arm;assess " ..target

elseif ataxiaTemp.fractures.wristfractures < 1 and ataxiaTemp.parriedLimb ~= "right arm" then

atk = atk.."wield bastard405364;wipe bastard405364;battlefury perceive "..target.."battlefury focus speed;envenom bastard with " ..venoms[1].. ";hew " ..target.. " right arm;assess " ..target




end



if ataxiaNDB_getClass(target) == "Bard" and  ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.torntendons == 0 and ataxiaTemp.parriedLimb ~= "right leg" and ataxiaTemp.parriedLimb ~= "right arm"  then
targetlimb = "right leg" bfocus = "precision"

elseif  ataxiaNDB_getClass(target) == "Bard" and ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.torntendons == 0   and (ataxiaTemp.parriedLimb == "right arm" or ataxiaTemp.parriedLimb == "right leg") then

targetlimb = "left leg" bfocus = "precision"
end



if ataxiaNDB_getClass(target) == "Bard" and ataxiaTemp.fractures.wristfractures == 0  and ataxiaTemp.parriedLimb ~= "right arm" and ataxiaTemp.parriedLimb ~= "right leg" then
targetlimb = "right arm" bfocus = "precision"

elseif ataxiaNDB_getClass(target) == "Bard" and ataxiaTemp.fractures.wristfractures == 0  and (ataxiaTemp.parriedLimb == "right arm" or ataxiaTemp.parriedLimb == "right leg") then

targetlimb = "left arm" bfocus = "precision"
end




--ATTACK
--ATTACK
--ATTACK
--ATTACK







if not ataxia.settings.paused then
  if not engaged then
    send("queue addclear freestand hyena slay "..target.."; "..atk.." ;engage "..target.." ;tyranny")
  else
    send("queue addclear freestand " ..atk.." ;tyranny")
  end

end

end

