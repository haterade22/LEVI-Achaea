function dwcpriosbasicinfernallimbvivi()


scimdamage = ataxiaTables.limbData.dwcSlash + ataxiaTables.limbData.dwcSlash
axedamage = scimdamage - 3


limdamage = scimdamage



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

if  tLimbs.T + limdamage >= 200 and tLimbs.T < 100 then 
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

if arm_prep and prepped_leftleg then
prep_arm_ll = true
else
prep_arm_ll = false
end

if arm_prep and prepped_rightleg then
prep_arm_rl = true
else
prep_arm_rl = false
end


if prepped_rightarm and prepped_leftleg then
prep_ra_ll = true
else prep_ra_ll = false
end

if prepped_rightarm and prepped_rightleg then
prep_ra_rl = true
else prep_ra_rl = false
end

if prepped_leftarm and prepped_rightleg then
prep_la_rl = true
else prep_la_rl = false
end

if prepped_leftarm and prepped_leftleg then
prep_la_ll = true
else prep_la_ll = false
end


targetlimb = {}



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







if ataxiaTemp.parriedLimb == targetlimb[1] and not tAffs.prone then 
targetlimb[1] = targetlimb[2]

end

dwcpriosbasicinfernalvivi()
end

function dwcpriosbasicinfernalvivi()
weapon1 = "scimitar266559"
weapon2 = "scimitar269323"
local atk = combatQueue()


need_raze = false
partyrelay = partyrelay or true
scimdamage = ataxiaTables.limbData.dwcSlash + ataxiaTables.limbData.dwcSlash
axedamage = scimdamage - 3

if checkAffList({"anorexia", "asthma", "slickness", "bloodfire"},3) then
	local	softlock = true
  else
  softlock = false
	
	end
  




--VENOMS

   venoms = {}
  
if not tAffs.damagedrightleg and (tAffs.brokenleftleg or tAffs.damagedleftleg) and 
not tAffs.damagedrightarm and (tAffs.brokenleftarm or tAffs.damagedleftarm) then
 table.insert(venoms,"epteth")
  table.insert(venoms,"epseth")
end

if  not tAffs.damagedleftleg and (tAffs.brokenrightleg or tAffs.damagedrightleg) and 
not tAffs.damagedrightarm and (tAffs.brokenleftarm or tAffs.damagedleftarm) then
 table.insert(venoms,"epteth")
  table.insert(venoms,"epseth")
end

if  not tAffs.damagedleftleg and (tAffs.brokenrightleg or tAffs.damagedrightleg) and 
not tAffs.damagedleftarm and (tAffs.brokenrightarm or tAffs.damagedrightarm) then
 table.insert(venoms,"epteth")
  table.insert(venoms,"epseth")
end

if  not tAffs.damagedrightleg and (tAffs.brokenleftleg or tAffs.damagedleftleg) and 
not tAffs.damagedleftarm and (tAffs.brokenrightarm or tAffs.damagedrightarm) then
 table.insert(venoms,"epteth")
  table.insert(venoms,"epseth")
end

if tAffs.damagedleftarm and tAffs.damagedrightarm and (tAffs.damagedleftleg or tAffs.damagedrightleg) then
 table.insert(venoms,"epteth")
  table.insert(venoms,"epseth")
end

if
leg_prep and not tAffs.prone and not tAffs.rebounding and not tAffs.shield and tAffs.nausea then
 table.insert(venoms,"delphinium")
  table.insert(venoms,"delphinium")
  vivi_legs = true
  else
  vivi_legs = false
end

if
prepped_leftleg and not tAffs.prone and not tAffs.rebounding and not tAffs.shield and prepped_rightarm and prepped_leftarm then
 table.insert(venoms,"delphinium")
  table.insert(venoms,"delphinium")
  vivi_arms2 = true
  else
  vivi_arms2 = false
end

if
prepped_rightleg and not tAffs.prone and not tAffs.rebounding and not tAffs.shield and prepped_rightarm and prepped_leftarmm then
 table.insert(venoms,"delphinium")
  table.insert(venoms,"delphinium")
  vivi_arms3 = true
  else
  vivi_arms3 = false
end

if
prepped_leftleg and not tAffs.prone and not tAffs.rebounding and not tAffs.shield and tAffs.damagedrightarm and tAffs.damagedleftarm then
 table.insert(venoms,"delphinium")
  table.insert(venoms,"delphinium")
  vivi_legs2 = true
  else
  vivi_legs2 = false
end

if
prepped_rightleg and not tAffs.prone and not tAffs.rebounding and not tAffs.shield and tAffs.damagedrightarm and tAffs.damagedleftarm then
 table.insert(venoms,"delphinium")
  table.insert(venoms,"delphinium")
  vivi_legs3 = true
  else
  vivi_legs3 = false
end

if
arm_prep and not tAffs.rebounding and not tAffs.shield then

  vivi_arms = true
  else
  vivi_arms = false
end



if tAffs.slickness and not tAffs.anorexia and not tAffs.rebounding then
  table.insert(venoms,"slike")
  
  end

  
if tAffs.impatience and not tAffs.anorexia and not tAffs.slickness and tAffs.asthma then
table.insert(venoms,"slike")
table.insert(venoms,"gecko")
end

if tAffs.impatience and not tAffs.anorexia and not tBals.salve then
table.insert(venoms,"slike")
end

if venoms[1] == "slike" and not tAffs.stupidity then 
  table.insert(venoms,"aconite")
  end



if tAffs.anorexia and not tAffs.recklessness then
table.insert(venoms,"eurypteria")
end



  
  if tAffs.anorexia and not tAffs.dizziness then
table.insert(venoms,"larkspur")
end





if tAffs.anorexia and not tAffs.shyness then
  table.insert(venoms,"digitalis")

end



if not tAffs.paralysis and not tAffs.slickness then
  table.insert(venoms,"curare")

end


if not tAffs.slickness and tAffs.asthma then

  table.insert(venoms,"gecko")

end




if not tAffs.clumsiness then
  table.insert(venoms,"xentio")

end

if not tAffs.nausea then
  table.insert(venoms,"euphorbia")

end

if not tAffs.asthma then
  table.insert(venoms,"kalmia")

end




if not tAffs.weariness then
  table.insert(venoms,"vernalius")

end



if not tAffs.addiction then
  table.insert(venoms,"vardrax")

end







if not tAffs.sensitivity then

  table.insert(venoms,"prefarar")
  table.insert(venoms,"prefarar")

end





if not tAffs.darkshade then
  table.insert(venoms,"darkshade")

end




if tAffs.prone and vivi_legs and not tAffs.brokenrightarm and not tAffs.brokenleftarm then
  table.insert(venoms,"epteth")
  table.insert(venoms,"epteth")

end

if tAffs.prone and tAffs.damagedrightleg and tAffs.damagedleftleg and not tAffs.brokenrightarm and not tAffs.brokenleftarm then
  table.insert(venoms,"epteth")
  table.insert(venoms,"epteth")

end

if  tAffs.damagedrightarm and tAffs.damagedleftarm and not tAffs.brokenrightleg and not tAffs.brokenleftleg
 then
  table.insert(venoms,"epteth")
  table.insert(venoms,"epteth")

end

if tAffs.prone and vivi_arms and not tAffs.brokenrightleg and not tAffs.brokenleftleg then
  table.insert(venoms,"epseth")
  table.insert(venoms,"epseth")

end

if tAffs.damagedrightarm and tAffs.damagedleftarm then
  table.insert(venoms,"epseth")
  table.insert(venoms,"epseth")

end



if tAffs.asthma and not tAffs.disloyalty then
 table.insert(venoms,"monkshood")

end


if not tAffs.recklessness then
table.insert(venoms,"eurypteria")
end


if not tAffs.stupidity then
  table.insert(venoms,"aconite")


end

if not tAffs.dizziness then
table.insert(venoms,"larkspur")
end


if not tAffs.shyness then
  table.insert(venoms,"digitalis")

end








--ATTACK



if tAffs.impaled and tLimbs.T >= 100 then
disembowel = true
else
disembowel = false
end



if (tLimbs.RL + scimdamage >= 100) and (tLimbs.RL + axedamage < 100) and targetlimb == "right leg" then

need_raze2 = true
else
need_raze2 = false
end

if (tLimbs.RA + scimdamage >= 100) and (tLimbs.RA + axedamage < 100) and targetlimb == "right arm" then

need_raze2 = true
else
need_raze2 = false
end

if (tLimbs.LL + scimdamage >= 100) and (tLimbs.LL + axedamage < 100) and targetlimb == "left leg" then

need_raze3 = true
else
need_raze3 = false
end

if (tLimbs.LA + scimdamage >= 100) and (tLimbs.LA + axedamage < 100) and targetlimb == "left arm" then

need_raze3 = true
else
need_raze3 = false
end

if tAffs.rebounding or tAffs.shield then

need_raze = true
else
need_raze = false
end

if (ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 35 and not tAffs.shield) then
need_quash = true else
need_quash = false
end


if tAffs.rebounding and tAffs.shield then
need_shieldraze = true
else
need_shieldraze = false
end




if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 50 and ataxia.vitals.class == 4 then
impale_blackout = true
else
impale_blackout = false
end


if (tAffs.brokenrightleg or tAffs.damagedrightleg) and (tAffs.brokenleftleg or tAffs.damagedleftleg)
 and (tAffs.brokenleftarm or tAffs.damagedleftarm)  and  (tAffs.brokenrightarm or tAffs.damagedrightarm) then
need_vivisect = true
else
need_vivisect = false
end

--ataxiaNDB.players[target].city ~= "Mhaldor"

if need_vivisect  then
atk = atk.."dismount;vivisect "..target

--elseif need_vivisect and ataxiaNDB.players[target].city == "Mhaldor" then
--atk = send("say DOOMED!")


elseif need_quash then

atk = "stand/wield shield longsword/assess "..target.."/quash "..target.."/arc curare"


elseif disembowel then 

atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";disembowel "..target



elseif need_raze then
atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";razeslash "..target.."  "..targetlimb[1].." "..venoms[1]

elseif need_raze2 then
atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";razeslash "..target.."  "..targetlimb[1].." "..venoms[1]

elseif need_raze3 then
atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";razeslash "..target.."  "..targetlimb[1].." "..venoms[1]


if venoms[1] == "curare" then
venoms[1] = venoms[2]
venoms[2] = "curare"
end




elseif tAffs.prone and tAffs.damagedtorso and tAffs.damagedrightleg and tAffs.damagedleftleg then
atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";assess "..target..";impale "..target

elseif not tAffs.rebounding and not tAffs.shield and tAffs.prone and prepped_leftleg then
targetlimb = "left leg"


atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.." "..targetlimb.." epteth epteth"

elseif not tAffs.rebounding and not tAffs.shield and tAffs.prone and prepped_rightleg then
targetlimb = "right leg"


atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.." "..targetlimb.." epteth epteth"


elseif vivi_legs then
targetlimb = "right leg"

atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.." "..targetlimb.."  "..venoms[1].." "..venoms[2]

elseif vivi_legs2 then
targetlimb = "left leg"

atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.." "..targetlimb.."  "..venoms[1].." "..venoms[2]

elseif vivi_legs3 then
targetlimb = "right leg"

atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.." "..targetlimb.."  "..venoms[1].." "..venoms[2]

elseif vivi_arms2 then
targetlimb = "left leg"

atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.." "..targetlimb.."  "..venoms[1].." "..venoms[2]

elseif vivi_arms3 then
targetlimb = "right leg"

atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.." "..targetlimb.."  "..venoms[1].." "..venoms[2]




elseif tAffs.damagedrightarm and prepped_leftarm then
targetlimb = "left arm"

atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.." "..targetlimb.." epseth epseth"


elseif vivi_arms then
targetlimb = "right arm"

atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.." "..targetlimb.."  "..venoms[1].." "..venoms[2]

elseif tAffs.damagedleftarm and prepped_leftleg then
targetlimb = "left leg"

atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.." "..targetlimb.."  "..venoms[1].." "..venoms[2]


elseif arm_prep and prepped_leftleg then
targetlimb = "left leg"

atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.." "..targetlimb.."  "..venoms[1].." "..venoms[2]

elseif arm_prep and prepped_rightleg then
targetlimb = "right leg"

atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.." "..targetlimb.."  "..venoms[1].." "..venoms[2]

--elseif not tAffs.nausea then

--atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.." "..venoms[1].." "..venoms[2]

else

atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.." "..targetlimb[1].." "..venoms[1].." "..venoms[2]

end


if not ataxia.afflictions.aeon then
if table.contains(ataxia.playersHere, target) then

if need_quash then
send("setalias quasharc "..atk)
send("queue addclear free quasharc")

elseif not engaged then
send("queue addclear free "..atk..";engage "..target..";tyranny;order hyena kill "..target)

else

send("queue addclear free "..atk..";tyranny")


end

end
end

end