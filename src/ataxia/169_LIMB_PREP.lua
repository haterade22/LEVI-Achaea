-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > INFERNAL > I SNB > LIMB PREP

function dwcprep()

local atk = combatQueue()

add_dedication = false
need_raze = false
partyrelay = partyrelay or false
scimdamage = ataxiaTables.limbData.dwcSlash + ataxiaTables.limbData.dwcSlash
axedamage = scimdamage - 3

if checkAffList({"anorexia", "asthma", "slickness", "bloodfire"},3) then
	local	softlock = true
  else
  softlock = false
	
	end
  




--VENOMS

  venoms = {}
  



if
((prepped_leftleg and prepped_rightleg) or (prepped_leftleg and tAffs.damagedrightleg) or (prepped_rightleg and tAffs.damagedleftleg)) and not tAffs.prone and not tAffs.rebounding and not tAffs.shield then
 table.insert(venoms,"delphinium")
  table.insert(venoms,"delphinium")
end



if (tAffs.damagedrightleg or tAffs.damagedleftleg) and (prepped_rightleg or prepped_leftleg) then
    table.insert(venoms,"epteth")
  table.insert(venoms,"epteth")
  
  elseif tAffs.damagedrightleg and tAffs.damagedleftleg  then
    table.insert(venoms,"epteth")
  table.insert(venoms,"epteth")
  
  
  
  elseif (tAffs.damagedrightleg or tAffs.damagedleftleg) and (prepped_rightarm or prepped_leftarm) then
    table.insert(venoms,"epteth")
  table.insert(venoms,"epseth")
  
   elseif (tAffs.damagedrightleg or tAffs.damagedleftleg) and (tAffs.damagedrightarm or tAffs.damagedleftarm) then
    table.insert(venoms,"epteth")
  table.insert(venoms,"epseth")
  
 elseif (tAffs.damagedrightarm or tAffs.damagedleftarm) and (prepped_rightleg or prepped_leftleg) then
    table.insert(venoms,"epseth")
  table.insert(venoms,"epseth")
  
   elseif tAffs.damagedrightarm and tAffs.damagedleftarm then
    table.insert(venoms,"epseth")
  table.insert(venoms,"epseth")


 
end

if tAffs.slickness and not tAffs.anorexia and tAffs.paralysis and not tAffs.stupid then
  table.insert(venoms,"aconite")
  table.insert(venoms,"slike")
  
  end
  



if not tAffs.paralysis then
  table.insert(venoms,"curare")

end

if not tAffs.nausea then
  table.insert(venoms,"euphorbia")

end





if not tAffs.clumsiness then
  table.insert(venoms,"xentio")

end

if not tAffs.asthma then
  table.insert(venoms,"kalmia")

end

if not tAffs.sensitivity then

  table.insert(venoms,"prefarar")
  table.insert(venoms,"prefarar")

end




if not tAffs.slickness and tAffs.asthma and venoms[1] == "curare" then

  table.insert(venoms,"gecko")

end


if not tAffs.recklessness then
table.insert(venoms,"eurypteria")
end

if not tAffs.dizziness then
table.insert(venoms,"larkspur")
end


if not tAffs.stupidity then
  table.insert(venoms,"aconite")

end

if not tAffs.addiction then

  table.insert(venoms,"vardrax")

end

if not tAffs.darkshade then
  table.insert(venoms,"darkshade")

end





--INVESTS


invest = {}

if venoms[1] ~= "epteth" and venoms[1] ~= "delphinium" and not tAffs.weariness and tAffs.anorexia and tAffs.asthma and tAffs.slickness then invest = "exploit"

elseif venoms[1] ~= "epteth" and venoms[1] ~= "delphinium" and not tAffs.weariness and (venoms[1] == "aconite" or venoms[2] == "aconite") and tAffs.asthma and tAffs.slickness then invest = "exploit"

elseif venoms[1] ~= "epteth" and venoms[1] ~= "delphinium" and tAffs.haemophilia then invest = "agony" 

elseif getMentalAffCount() >= 4 then invest = "punishment" 

else invest = "agony" end
  
  



--ATTACK


local atk = combatQueue()


if ataxia.afflictions.paralysis and not ataxia.afflictions.prone 
and (tonumber(gmcp.Char.Vitals.hp) >=  tonumber(gmcp.Char.Vitals.maxhp)*.5) 
and (tonumber(gmcp.Char.Vitals.mp) >= tonumber(gmcp.Char.Vitals.maxmp)*.6) and
(ataxiaNDB_getClass(target) ~= "Apostate" or ataxiaNDB_getClass(target)) ~= "Priest" then

add_dedication = true
else 
add_dedication = false
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


if (tAffs.brokenrightleg or tAffs.damagedrightleg) and (tAffs.brokenleftleg or tAffs.damagedleftleg)
 and (tAffs.brokenleftarm or tAffs.damagedleftarm)  and  (tAffs.brokenrightarm or tAffs.damagedrightarm) and tAffs.prone then
vivisect = true
else
vivisect = false
end

if tAffs.rebounding and tAffs.shield then
need_shieldraze = true
else
need_shieldraze = false
end

if  tLimbs.LL + scimdamage >= 100 and not tAffs.damagedleftleg then 
prepped_leftleg = true else
prepped_leftleg = false

end

if  tLimbs.RL + scimdamage >= 100 and not tAffs.damagedrightleg then 
prepped_rightleg = true else
prepped_rightleg = false

end

if  tLimbs.RA + scimdamage >= 100 and not tAffs.damagedrightarm then 
prepped_rightarm = true else
prepped_rightarm = false

end

if  tLimbs.LA + scimdamage >= 100 and not tAffs.damagedleftarm then 
prepped_leftarm = true else
prepped_leftarm = false

end

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess > 50 and ataxia.vitals.class == 4 then
ferocity_full = true
else 
ferocity_full = false
end

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 50 and ataxia.vitals.class == 4 then
impale_blackout = true
else
impale_blackout = false
end

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 35 then
quash_arc = true
else
quash_arc = false
end


if quash_arc then

atk = "stand/wield shield longsword441711/assess "..target.."/quash "..target.."/arc "..target.." curare"

elseif vivisect then
atk = atk.."wield scimitar scimitar;wipe scimitar383498;wipe scimitar355418;rampage against "..target..";assess "..target..";hellforge invest "..invest..";dismount;vivisect "..target



elseif need_shieldraze then
atk = "stand/wield shield longsword441711/assess "..target.."/quash "..target.."/arc "..target.." curare"


elseif need_raze then
atk = atk.."wield scimitar scimitar;wipe scimitar383498;wipe scimitar355418;rampage against "..target..";assess "..target..";hellforge invest "..invest..";razeslash "..target.." "..targetlimb.." "..venoms[1]

elseif need_raze2 then
atk = atk.."wield scimitar scimitar;wipe scimitar383498;wipe scimitar355418;rampage against "..target..";assess "..target..";hellforge invest "..invest..";razeslash "..target.." "..targetlimb.." "..venoms[1]

elseif need_raze3 then
atk = atk.."wield scimitar scimitar;wipe scimitar383498;wipe scimitar355418;rampage against "..target..";assess "..target..";hellforge invest "..invest..";razeslash "..target.." "..targetlimb.." "..venoms[1]

--elseif prepped_leftleg and prepped_rightleg and not tAffs.prone then

--atk = atk.."wield battleaxe;rampage against "..target..";assess "..target..";hellforge invest "..invest..";undercut "..target.." "..targetlimb.." "..venoms[1]

--elseif prepped_leftleg and prepped_rightarm and not tAffs.prone then

--atk = atk.."wield battleaxe;rampage against "..target..";assess "..target..";hellforge invest "..invest..";undercut "..target.." left leg "..venoms[1]

--elseif prepped_rightleg and prepped_rightarm and not tAffs.prone then

--atk = atk.."wield battleaxe;rampage against "..target..";assess "..target..";hellforge invest "..invest..";undercut "..target.." right leg "..venoms[1]



elseif (invest == "exploit" or invest == "torture" or invest == "torment") and venoms[1] ~= "epteth" and venoms[1] ~= "delphinium" then

atk = atk.."wield scimitar scimitar;wipe scimitar383498;wipe scimitar355418;rampage against "..target..";assess "..target..";hellforge invest "..invest..";envenom scimitar383498 with "..venoms[1]..";dsl "..target.." "..targetlimb

else
atk = atk.."wield scimitar scimitar;wipe scimitar383498;wipe scimitar355418;rampage against "..target..";assess "..target..";hellforge invest "..invest..";dsl "..target.." "..targetlimb.." "..venoms[1].." "..venoms[2]

end


if not ataxia.settings.paused then

if quash_arc then
send("setalias quasharc "..atk)
send("queue addclear free quasharc")

elseif not engaged then
send("queue addclear free "..atk..";engage "..target..";tyranny")

else

send("queue addclear free "..atk..";tyranny")

end
end


end