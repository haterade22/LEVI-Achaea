function dwcprioslimb()
weapon1 = "scimitar405398"
weapon2 = "scimitar405403"


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
  

if (prepped_leftleg and prepped_rightleg) and tAffs.damagedtorso and not tAffs.prone and not tAffs.rebounding and not tAffs.shield then
 table.insert(venoms,"delphinium")
 table.insert(venoms,"delphinium")
end

if (prepped_leftleg or prepped_rightleg) and prepped_head and not tAffs.prone and not tAffs.rebounding and not tAffs.shield then
 table.insert(venoms,"delphinium")
 table.insert(venoms,"delphinium")
end

if tAffs.impatience and not tAffs.anorexia and not tAffs.slickness and tAffs.asthma then
table.insert(venoms,"slike")
table.insert(venoms,"gecko")
end

if tAffs.impatience and not tAffs.anorexia and not tBals.salve then
table.insert(venoms,"slike")
end

if tAffs.slickness and not tAffs.anorexia and not tAffs.stupidity and tAffs.asthma then
  table.insert(venoms,"aconite")
  table.insert(venoms,"slike")
  
  end

if tAffs.anorexia and not tAffs.dizziness then
table.insert(venoms,"larkspur")
end


if tAffs.anorexia and not tAffs.stupidity then
table.insert(venoms,"aconite")
end

if tAffs.anorexia and not tAffs.shyness then
  table.insert(venoms,"digitalis")

end

if tAffs.anorexia and not tAffs.recklessness then
table.insert(venoms,"eurypteria")
end



if not tAffs.paralysis then
  table.insert(venoms,"curare")
end

if not tAffs.nausea then
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

if not tAffs.addiction then
  table.insert(venoms,"vardrax")

end

if not tAffs.sensitivity and tAffs.deaf then

  table.insert(venoms,"prefarar")
  table.insert(venoms,"prefarar")

end

if not tAffs.sensitivity and not tAffs.deaf then

  table.insert(venoms,"prefarar")
 
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



if not tAffs.brokenrightarm then
  table.insert(venoms,"epteth")

end

if not tAffs.brokenleftarm then
  table.insert(venoms,"epteth")

end

if not tAffs.darkshade then
  table.insert(venoms,"darkshade")

end

--ATTACK


if php <= 35 then
use_bisect = true else
use_bisect = false
end

if tAffs.impaled or timpale == true then
disembowel = true
else
disembowel = false
end

if (lb[target].hits["right leg"] + scimdamage >= 100) and (lb[target].hits["right leg"] + axedamage < 100) and targetlimb == "right leg" then

need_raze2 = true
else
need_raze2 = false
end

if (lb[target].hits["right arm"] + scimdamage >= 100) and (lb[target].hits["right arm"] + axedamage < 100) and targetlimb == "right arm" then

need_raze2 = true
else
need_raze2 = false
end

if (lb[target].hits["left leg"] + scimdamage >= 100) and (lb[target].hits["left leg"] + axedamage < 100) and targetlimb == "left leg" then

need_raze3 = true
else
need_raze3 = false
end

if (lb[target].hits["left arm"] + scimdamage >= 100) and (lb[target].hits["left arm"] + axedamage < 100) and targetlimb == "left arm" then

need_raze3 = true
else
need_raze3 = false
end

if tAffs.rebounding or tAffs.shield then

need_raze = true
else
need_raze = false
end

if tAffs.rebounding and tAffs.shield then
need_shieldraze = true
else
need_shieldraze = false
end

if lb[target].hits["left leg"] + scimdamage >= 100 and not tAffs.damagedleftleg then 
prepped_leftleg = true else
prepped_leftleg = false

end

if lb[target].hits["right leg"] + scimdamage >= 100 and not tAffs.damagedrightleg then 
prepped_rightleg = true else
prepped_rightleg = false

end

if lb[target].hits["right arm"] + scimdamage >= 100 and not tAffs.damagedrightarm then 
prepped_rightarm = true else
prepped_rightarm = false

end

if lb[target].hits["left arm"] + scimdamage >= 100 and not tAffs.damagedleftarm then 
prepped_leftarm = true else
prepped_leftarm = false

end

if lb[target].hits["head"] + scimdamage >= 100 and not tAffs.damagedhead then 
prepped_head = true else
prepped_head = false

end

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 50 and ataxia.vitals.class == 4 then
impale_blackout = true
else
impale_blackout = false
end


--Logic for limb target
if not tAffs.damagedtorso then targetlimb = "torso"
elseif not prepped_rightleg then targetlimb = "right leg"
elseif prepped_rightleg and not prepped_leftleg then targetlimb = "left leg"
end

--Bisect
if use_bisect and not tAffs.shield then

atk = atk.."wield shield bastard;assess "..target..";bisect "..target.." curare"

-- Disembowel
elseif disembowel then 

atk = atk..";disembowel "..target

-- Impale
elseif tAffs.prone and tAffs.damagedleftleg then
atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";impale "..target.. ";fury on"

elseif lb[target].hits["left leg"] + scimdamage >= 101 or tAffs.damagedleftleg then
atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";impale "..target.. ";fury on"


-- Raze
elseif need_raze then
atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";razeslash "..target.." "..targetlimb.." "..venoms[1]

elseif need_raze2 then
atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";razeslash "..target.." "..targetlimb.." "..venoms[1]

elseif need_raze3 then
atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";razeslash "..target.." "..targetlimb.." "..venoms[1]


-- Break Right Leg

elseif not tAffs.damagedrightleg and tAffs.nausea and not tAffs.rebounding and not tAffs.shield and prepped_rightleg and prepped_leftleg and not tAffs.prone and tAffs.damagedtorso then

atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.." right leg delphinium delphinium"

-- Break Left Leg Slickness and Paralysis

elseif tAffs.damagedrightleg and not tAffs.rebounding and not tAffs.shield and prepped_leftleg and tAffs.damagedtorso and not tAffs.slickness then

atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.." left leg gecko curare"

elseif tAffs.damagedrightleg and not tAffs.rebounding and not tAffs.shield and prepped_leftleg and tAffs.damagedtorso and tAffs.slickness then

atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.." left leg epteth curare"

elseif tAffs.nausea and (not prepped_leftleg or not prepped_rightleg) then

atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.." "..targetlimb.." "..venoms[2].." "..venoms[1]

elseif tAffs.nausea and not tAffs.damagedtorso then

atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.. " torso "..venoms[2].." "..venoms[1]

else

atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.." "..venoms[2].." "..venoms[1]

end


if not ataxia.settings.paused then


if use_bisect == true then
send("queue addclear free wield bastard;grip;assess "..target..";bisect "..target.." curare;engage " ..target)

elseif not engaged and need_falcon == true then
send("queue addclear free falcon slay " ..target.. ";" ..atk.." ;engage "..target.." ;assess " ..target)
elseif not engaged then
send("queue addclear free " ..atk.." ;engage "..target.." ;assess " ..target)

else

send("queue addclear free "..atk.. ";assess " ..target)


end
end

end