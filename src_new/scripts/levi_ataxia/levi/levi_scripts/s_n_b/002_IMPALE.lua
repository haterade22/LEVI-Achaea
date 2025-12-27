--[[mudlet
type: script
name: IMPALE
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- INFERNAL
- INFERNAL
- S n B
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function infernalpriosimpale()

local atk = combatQueue()

add_dedication = false
need_raze = false
partyrelay = partyrelay or false
strikingHigh = false

if checkAffList({"anorexia", "asthma", "slickness", "bloodfire"},3) then
	local	softlock = true
  else
  softlock = false
	
	end
if checkAffList({"anorexia", "asthma", "slickness", "paralysis"},4) then
	local	treelock = true
  else
  treelock = false
	
	end
  

targetlimb = ""
if tAffs.nausea or tAffs.paralysis or tAffs.prone then
if  not torso_prepped then targetlimb = "torso" elseif torso_prepped and not right_leg_prepped then targetlimb = "right leg" 
end end

  
  

--SHIELDNEED

  shieldneed = {}
  


if tAffs.slickness and tBals.focus and not tAffs.anorexia then
    table.insert(shieldneed,"smash high")


elseif tAffs.anorexia and tAffs.slickness then
    table.insert(shieldneed,"smash high")



elseif treelock  then
    table.insert(shieldneed,"smash high")



elseif not tAffs.paralysis then
    table.insert(shieldneed,"smash mid")
    
elseif not tAffs.asthma then
    table.insert(shieldneed,"drive")
    
    
elseif not tAffs.clumsiness then
    table.insert(shieldneed,"smash low")
    

else
    table.insert(shieldneed,"smash high")
end

















--SWORDLIST

swordneed = {}



if not tAffs.paralysis and shieldneed[1] ~= "smash mid" and softlock then
    table.insert(swordneed, "combination "..target.." slice "..targetlimb.." curare")
end

if not tAffs.slickness and tAffs.asthma then
     table.insert(swordneed,"combination "..target.." slice "..targetlimb.." gecko")
end

--if not tAffs.slickness and tAffs.asthma and tAffs.weariness then
--     table.insert(swordneed,"combination "..target.." slice gecko")
--end


if tAffs.anorexia and not tAffs.stupidity then
   table.insert(swordneed,"combination "..target.." slice "..targetlimb.." aconite")
   end

if tAffs.anorexia and not tAffs.recklessness then
   table.insert(swordneed,"combination "..target.." slice "..targetlimb.." eurypteria")
   end
if tAffs.anorexia and not tAffs.dizziness then
   table.insert(swordneed,"combination "..target.." slice "..targetlimb.." larkspur")
   end

if tAffs.anorexia and not tAffs.shyness then
   table.insert(swordneed,"combination "..target.." slice "..targetlimb.." digitalis")
   end

if not tAffs.anorexia and tAffs.slickness and tBals.focus then
    table.insert(swordneed,"combination "..target.." slice "..targetlimb.." slike")
end

if not tAffs.nausea then
      table.insert(swordneed,"combination "..target.." slice euphorbia")
end



if not softlock and not tAffs.healthleech then
 table.insert(swordneed,"wipe longsword;hellforge invest torment;combination "..target.." slice "..targetlimb)
end


if not softlock and not tAffs.haemophilia then
table.insert(swordneed,"wipe longsword;hellforge invest torture;combination "..target.." slice "..targetlimb)
end

if not tAffs.asthma and shieldneed[1] ~= "drive" then
      table.insert(swordneed,"combination "..target.." slice kalmia")
end





   if not tAffs.weariness then
    table.insert(swordneed,"wipe longsword;hellforge invest exploit;combination "..target.." slice "..targetlimb)
end





if not tAffs.addiction then
  table.insert(swordneed,"combination "..target.." slice "..targetlimb.." vardrax")
end






if not softlock and not tAffs.sensitivity then
  table.insert(swordneed,"combination "..target.." slice "..targetlimb.." prefarar")
end





if not tAffs.paralysis and shieldneed[1] ~= "smash mid" then
    table.insert(swordneed,"combination "..target.." slice "..targetlimb.." curare")
end



if not tAffs.asthma and shieldneed[1] ~= "drive" then
  table.insert(swordneed,"combination "..target.." slice "..targetlimb.." kalmia")
end




if tAffs.prone and tAffs.paralysis and tAffs.slickness then
table.insert(swordneed,"combination "..target.." slice "..targetlimb.." epseth")
   end
   
   if softlock and not tAffs.paralysis then
   table.insert(swordneed,"combination "..target.." slice "..targetlimb.." curare")
   end


   

   




--ATTACK




if ataxia.afflictions.paralysis and not ataxia.afflictions.prone 
and (tonumber(gmcp.Char.Vitals.hp) >=  tonumber(gmcp.Char.Vitals.maxhp)*.7) 
and (tonumber(gmcp.Char.Vitals.mp) >= tonumber(gmcp.Char.Vitals.maxmp)*.6) and
ataxiaNDB_getClass(target) ~= "Apostate" and ataxiaNDB_getClass(target) ~= "Priest" then

add_dedication = true
else 
add_dedication = false
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

if ataxia.vitals.class == 4 then
ferocity_full = true
else 
ferocity_full = false
end



if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 30 then
quash_arc = true
else
quash_arc = false
end

if tAffs.shield and tAffs.rebounding then
quash_arc2 = true
else
quash_arc2 = false
end


if tLimbs.RL + ataxiaTables.limbData.snbSlice >= 100 and tLimbs.RL < 100 then 
right_leg_prepped = true
else
right_leg_prepped = false
end

if tLimbs.T + ataxiaTables.limbData.snbSlice >= 100 and tLimbs.T < 100 then 
torso_prepped = true
else
torso_prepped = false
end

if tLimbs.LL + ataxiaTables.limbData.snbSlice >= 100 and tLimbs.LL < 100 then 
left_leg_prepped = true
else
left_leg_prepped = false
end

if tLimbs.H + ataxiaTables.limbData.snbSlice >= 100 and tLimbs.H < 100 then 
head_prepped = true
else
head_prepped = false
end



if ataxia.vitals.class == 4 and tAffs.blackout then
impale_blackout = true
else
impale_blackout = false
end

if tAffs.impaled and tLimbs.T >= 100 then
disembowel = true
else
disembowel = false
end





if disembowel then
atk = atk.."wield longsword shield;disembowel "..target



elseif ferocity_full and (tAffs.damagedrightleg or tAffs.damagedleftleg) and tLimbs.T >= 100 and tAffs.prone then

atk = atk.."wield longsword shield;assess "..target..";shieldstrike "..target.." high;combination "..target.." impale club"

elseif not ferocity_full and (tAffs.damagedrightleg or tAffs.damagedleftleg) and tLimbs.T >= 100 and tAffs.prone then

atk = atk.."wield longsword shield;assess "..target..";combination "..target.." impale club"

elseif quash_arc or quash_arc1 or quash_arc2 then

atk = "stand/wield shield longsword/quash "..target.."/arc curare/assess "..target


elseif need_raze or need_raze2 then
atk = atk.."wield longsword shield;assess "..target..";combination raze "..target.." "..shieldneed[1]


elseif (right_leg_prepped or left_leg_prepped) and not tAffs.prone and not ferocity_full and tLimbs.T >= 100 then

atk = atk.."wield longsword shield;assess "..target..";"..swordneed[1].." trip"

elseif (right_leg_prepped or left_leg_prepped) and not tAffs.prone and ferocity_full and tLimbs.T >= 100 then

atk = atk.."wield longsword shield;assess "..target..";"..swordneed[1].." "..shieldneed[1]..";shieldstrike "..target.." low"

elseif (right_leg_prepped or left_leg_prepped) and not tAffs.prone and ferocity_full and torso_prepped then
targetlimb = "torso"

atk = atk.."wield longsword shield;assess "..target..";"..swordneed[1].." "..shieldneed[1]..";shieldstrike "..target.." low"

elseif (tAffs.damagedrightleg or tAffs.damagedleftleg) and tLimbs.T < 100 and tAffs.prone then
targetlimb = "torso"

atk = atk.."wield longsword shield;assess "..target..";"..swordneed[1].." "..shieldneed[1]


elseif ferocity_full and not tAffs.sensitivity then

atk = atk.."wield shield longsword;assess "..target..";shieldstrike "..target.." mid;"..swordneed[1].." "..shieldneed[1]

elseif tAffs.nausea or tAffs.paralysis or tAffs.prone then

atk = atk.."wield longsword shield;assess "..target..";"..swordneed[1].." "..shieldneed[1]



else
atk = atk.."wield longsword shield;assess "..target..";"..swordneed[1].." "..shieldneed[1]

end

if quash_arc or quash_arc1 or quash_arc2 then
send("setalias quasharc "..atk)
send("queue addclear eq quasharc")

elseif not engaged then
send("queue addclear free "..atk..";engage "..target..";order hyena kill "..target)

elseif ataxia.afflictions.paralysis == true then

send("queue addclear free dedication;"..atk..";tyranny")

else

send("queue addclear free land;"..atk..";tyranny")




end
end