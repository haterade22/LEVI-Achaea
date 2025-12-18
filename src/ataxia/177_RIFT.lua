-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > RuneWarden > DWC RUNIE > RIFT

function runie_riftlock()


local atk = combatQueue()

add_dedication = false
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
  
if tBals.salve == false and tAffs.addiciton then
 table.insert(venoms,"epteth")
 table.insert(venoms,"epteth")

end


if
(prepped_leftleg and prepped_rightleg) and tAffs.damagedtorso and not tAffs.prone and not tAffs.rebounding and not tAffs.shield then
 table.insert(venoms,"delphinium")
  table.insert(venoms,"delphinium")
end

if
(prepped_leftleg or prepped_rightleg) and prepped_head and not tAffs.prone and not tAffs.rebounding and not tAffs.shield then
 table.insert(venoms,"delphinium")
  table.insert(venoms,"delphinium")
end






if tAffs.slickness and not tAffs.anorexia and tAffs.paralysis and not tAffs.stupid then
  table.insert(venoms,"aconite")
  table.insert(venoms,"slike")
  
  end


  
if tAffs.impatience and not tAffs.anorexia and not tAffs.slickness then
table.insert(venoms,"slike")
table.insert(venoms,"gecko")
end

if tAffs.impatience and not tAffs.anorexia and not tBals.salve then
table.insert(venoms,"slike")
end

if tAffs.damagedhead and not tAffs.stupidity then
  table.insert(venoms,"aconite")
  end
  
  if tAffs.damagedhead and not tAffs.dizziness then
table.insert(venoms,"larkspur")
end



if tAffs.damagedhead and not tAffs.recklessness then
table.insert(venoms,"eurypteria")
end





if tAffs.damagedhead and not tAffs.shyness then
  table.insert(venoms,"digitalis")

end


if not tAffs.paralysis then
  table.insert(venoms,"curare")

end

if not tAffs.addiction then
  table.insert(venoms,"vardrax")

end

if not tAffs.weariness then
  table.insert(venoms,"vernalius")

end






if not tAffs.asthma then
  table.insert(venoms,"kalmia")

end

if not tAffs.clumsiness then
  table.insert(venoms,"xentio")

end



if not tAffs.slickness and tAffs.asthma and venoms[1] == "curare" then

  table.insert(venoms,"gecko")

end

if not tAffs.nausea then
  table.insert(venoms,"euphorbia")

end




if not tAffs.dizziness then
table.insert(venoms,"larkspur")
end


if not tAffs.stupidity then
  table.insert(venoms,"aconite")


end

if not tAffs.recklessness then
table.insert(venoms,"eurypteria")
end





if not tAffs.shyness then
  table.insert(venoms,"digitalis")

end

if not tAffs.sensitivity then

  table.insert(venoms,"prefarar")
  table.insert(venoms,"prefarar")

end







if not tAffs.darkshade then
  table.insert(venoms,"darkshade")

end














--ATTACK



if tAffs.impaled and tLimbs.T >= 100 then
disembowel = true
else
disembowel = false
end

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

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 35 then
use_bisect = true else
use_bisect = false
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

if  tLimbs.H + scimdamage >= 100 and not tAffs.damagedhead then 
prepped_head = true else
prepped_head = false

end

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 50 and ataxia.vitals.class == 4 then
impale_blackout = true
else
impale_blackout = false
end




if use_bisect then

atk = atk.."wield shield longsword;assess "..target..";bisect "..target.." curare"


elseif disembowel then 

atk = atk.."wield scimitar355418 scimitar383498;wipe scimitar383498;wipe scimitar355418;assess "..target..";disembowel "..target



elseif need_raze then
atk = atk.."wield scimitar355418 scimitar383498;wipe scimitar383498;wipe scimitar355418;assess "..target..";razeslash "..target.." "..targetlimb.." "..venoms[1]

elseif need_raze2 then
atk = atk.."wield scimitar355418 scimitar383498;wipe scimitar383498;wipe scimitar355418;assess "..target..";razeslash "..target.." "..targetlimb.." "..venoms[1]

elseif need_raze3 then
atk = atk.."wield scimitar355418 scimitar383498;wipe scimitar383498;wipe scimitar355418;assess "..target..";razeslash "..target.." "..targetlimb.." "..venoms[1]





elseif tAffs.prone and tAffs.damagedtorso and tAffs.damagedrightleg and tAffs.damagedleftleg then
atk = atk.."wield scimitar355418 scimitar383498;wipe scimitar383498;wipe scimitar355418;assess "..target..";impale "..target

elseif tBals.salve == false and tAffs.addiction then
atk = atk.."wield scimitar355418 scimitar383498;wipe scimitar383498;wipe scimitar355418;assess "..target..";dsl "..target.." "..targetlimb.." epteth epteth"


else


atk = atk.."wield scimitar355418 scimitar383498;wipe scimitar383498;wipe scimitar355418;assess "..target..";dsl "..target.." "..targetlimb.." "..venoms[1].." "..venoms[2]

end


if not ataxia.settings.paused then


if not engaged then
send("queue addclear free "..atk..";engage "..target)

else

send("queue addclear free "..atk)


end
end

end