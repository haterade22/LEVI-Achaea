-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > INFERNAL > I SNB > Damage Into Lock

function infernalpriosdamage()
if ataxia.afflictions.blackout then
send("queue addclear free touch shield")
else
envenomList = {}
local atk = combatQueue()

add_dedication = false
need_raze = false
partyrelay = partyrelay or false
strikingHigh = false
need_falcon = true


-- Check for Lock
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

  
if checkAffList({"anorexia", "asthma", "slickness", "paralysis", "impatience"},5) then
	local	truelock = true
  else
  truelock = false
	
	end

-- Invest
-- Punishment = Scales off Mentals
-- Torture = Haemophilia and if attack breaks limb more bleeding
-- Exploit = Weariness and Paranoia
-- Agony = Strikes a target bleeding 200 , cures affliction - Can be used with venoms, persists on blade have to remove 
-- torment = healthleech then confusion

if not tAffs.healthleech then invest = "torment" elseif getMentalAffCount() >= 3 then invest = "punishment" else invest = "agony" end
  
  

--SHIELDNEED/Shield Attack

  shieldneed = {}

if tAffs.prone and not tAffs.blackout and ferocity_full then
    table.insert(shieldneed,"concuss")
  

elseif tAffs.slickness and tAffs.asthma then
    table.insert(shieldneed,"smash high")


elseif tAffs.anorexia then
    table.insert(shieldneed,"smash high")


elseif softlock and tAffs.paralysis  then
    table.insert(shieldneed,"smash high")

elseif not tAffs.paralysis then
    table.insert(shieldneed,"smash mid")
    
elseif not tAffs.asthma then
    table.insert(shieldneed,"drive")
    
elseif tAffs.impatience and tAffs.paralysis then
     table.insert(shieldneed,"smash high")

elseif not tAffs.clumsiness then
    table.insert(shieldneed,"smash low")
    
else
    table.insert(shieldneed,"smash high")
end

--SWORDLIST


 

swordneed = {}

if truelock == true and not tAffs.voyria then
 invest = "punishment"
table.insert(envenomList,"voyria")
end

if tAffs.impatience and not tAffs.anorexia and not tBals.salve then
 invest = "agony"
table.insert(envenomList,"slike")
end

if tAffs.impatience and not tAffs.anorexia and tAffs.slickness then
  invest = "agony"
 table.insert(envenomList,"slike")
end

if tAffs.impatience and not tAffs.slickness and tAffs.asthma then
 invest = "agony"
table.insert(envenomList,"gecko")
end


if not tAffs.paralysis and shieldneed[1] ~= "smash mid" and softlock then
     invest = "agony"
    table.insert(envenomList,"curare")
end


if tAffs.anorexia and not tAffs.stupidity then
    invest = "agony"
   table.insert(envenomList,"aconite")
   end

if tAffs.anorexia and not tAffs.recklessness then
    invest = "agony"
   table.insert(envenomList,"eurypteria")
   end
if tAffs.anorexia and not tAffs.dizziness then
    invest = "agony"
   table.insert(envenomList,"larkspur")
   end

if tAffs.anorexia and not tAffs.shyness then
    invest = "agony"
   table.insert(envenomList,"digitalis")
   end

if not tAffs.anorexia and tAffs.slickness then
     invest = "agony"
    table.insert(envenomList,"slike")
end

if not tAffs.slickness and tAffs.asthma  then
     invest = "agony"
     table.insert(envenomList,"gecko")
end
   
if tAffs.healthleech and tAffs.clumsiness and not tAffs.asthma and shieldneed[1] ~= "drive" then
     invest = "agony"
    table.insert(envenomList,"kalmia")
end


if tAffs.healthleech and not tAffs.clumsiness and shieldneed[1] ~= "smash low" then
     invest = "agony"
    table.insert(envenomList,"xentio")
end

if not tAffs.haemophilia then
invest = "torture"
table.insert(envenomList,"torture")
end
  
if not tAffs.sensitivity and tAffs.healthleech then
   invest = "agony"
  table.insert(envenomList,"prefarar")
end

if not tAffs.haemophilia then
invest = "torture"
table.insert(envenomList,"torture")
end

if not tAffs.healthleech then
 invest = "torment"
 table.insert(envenomList,"healthleech")
end


if tAffs.asthma and tAffs.clumsiness and not tAffs.weariness then
    invest = "exploit"
    table.insert(envenomList,"exploit")
end

if not tAffs.paralysis and shieldneed[1] ~= "smash mid" then
    invest = "agony"
    table.insert(envenomList,"curare")
end

if not tAffs.asthma and shieldneed[1] ~= "drive" then
   invest = "agony"
  table.insert(envenomList,"kalmia")
end


if not tAffs.nausea then
  invest = "agony"
  table.insert(envenomList,"euphorbia")
end


if softlock and not tAffs.paralysis and shieldneed[1] ~= "smash mid" then
   invest = "agony"
   table.insert(envenomList,"curare")
   end

if softlock and not tAffs.confusion then
   invest = "agony"
  table.insert(envenomList,"torment")
   end
   

if not tAffs.haemophilia then
invest = "torture"
table.insert(envenomList,"torture")
end
  
if not tAffs.addiction then
   invest = "agony"
  table.insert(envenomList,"vardrax")
end






--ATTACK


local atk = combatQueue()


if ataxia.afflictions.paralysis and not ataxia.afflictions.prone 
and (tonumber(gmcp.Char.Vitals.hp) >=  tonumber(gmcp.Char.Vitals.maxhp)*.7) 
and (tonumber(gmcp.Char.Vitals.mp) >= tonumber(gmcp.Char.Vitals.maxmp)*.6) and
(ataxiaNDB_getClass(target) ~= "Apostate" or ataxiaNDB_getClass(target)) ~= "Priest" then

add_dedication = true
else 
add_dedication = false
end



if tAffs.rebounding or tAffs.shield then

need_raze = true
else
need_raze = false
end

if ataxia.vitals.class == 4 then
ferocity_full = true
else 
ferocity_full = false
end

if (tAffs.brokenrightleg or tAffs.damagedrightleg) and (tAffs.brokenleftleg or tAffs.damagedleftleg)
 and (tAffs.brokenleftarm or tAffs.damagedleftarm)  and  (tAffs.brokenrightarm or tAffs.damagedrightarm) then
vivisect = true
else
vivisect = false
end


if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 30 then
quash_arc = true
else
quash_arc = false
end

if php <= 30 then
quash_arc = true
else
quash_arc = false
end

if php <= 32 and tAffs.sensitivity then
quash_arc = true
else
quash_arc = false
end

if quash_arc then

atk = "stand;wield shield longsword441711;assess "..target..";quash "..target..";arc "..target.." curare"

elseif need_raze then
atk = atk.."wield shield longsword441711;assess "..target..";combination " ..target.. " raze " ..shieldneed[1]

elseif vivisect then
atk = atk.."wield shield longsword441711;assess "..target..";vivisect "..target


elseif ferocity_full and not tAffs.prone and not tAffs.slickness and not tAffs.paralysis and tAffs.asthma then
atk = atk.."wield shield longsword441711;assess "..target..";combination " ..target.. " slice gecko smash mid;shieldstrike "..target.." low"

elseif ferocity_full and not tAffs.prone and tAffs.slickness and not tAffs.paralysis and tAffs.asthma then
atk = atk.."wield shield longsword441711;assess "..target..";combination " ..target.. " slice slike smash mid;shieldstrike "..target.." low"

elseif ferocity_full and not tAffs.prone and not tAffs.slickness and tAffs.paralysis and tAffs.asthma then
atk = atk.."wield shield longsword441711;assess "..target..";combination " ..target.. " slice gecko smash high;shieldstrike "..target.." low"



elseif ferocity_full and tLimbs.RL < 100 and tLimbs.RL >= 92.4 and tAffs.slickness then
atk = atk.."wield shield longsword441711;assess "..target..";shieldstrike "..target.." low;combination "..target.." slice right leg slike smash high"

elseif ferocity_full and tLimbs.LL < 100 and tLimbs.LL >= 92.4 and tAffs.slickness then
atk = atk.."wield shield longsword441711;assess "..target..";shieldstrike "..target.." low;combination "..target.." slice left leg slike smash high"

elseif tAffs.prone and tLimbs.LL < 100 and tLimbs.LL >= 92.4 and tAffs.slickness then
atk = atk.."wield shield longsword441711;assess "..target..";combination "..target.." slice left leg slike smash high"

elseif tAffs.prone and tLimbs.LL < 100 and tLimbs.LL >= 92.4 and tAffs.slickness then
atk = atk.."wield shield longsword441711;assess "..target..";combination "..target.." slice left leg slike smash high"


elseif ferocity_full and not tAffs.sensitivity then

atk = atk.."wield shield longsword441711;assess "..target..";hellforge invest agony;shieldstrike "..target.." mid;combination " ..target.. " slice " ..envenomList[1].. " " ..shieldneed[1]



-- Punishment = Scales off Mentals
-- Torture = Haemophilia and if attack breaks limb more bleeding
-- Exploit = Weariness and Paranoia
-- Agony = Strikes a target bleeding 200 , cures affliction - Can be used with venoms, persists on blade have to remove 
-- torment = healthleech then confusion
elseif invest == "punishment" then
atk = atk.."wield shield longsword441711;assess "..target..";hellforge invest punishment;combination " ..target.. " slice " ..shieldneed[1]
elseif invest == "torture" then
atk = atk.."wield shield longsword441711;assess "..target..";hellforge invest torture;combination " ..target.. " slice " ..shieldneed[1]
elseif invest == "exploit" then
atk = atk.."wield shield longsword441711;assess "..target..";hellforge invest exploit;combination " ..target.. " slice " ..shieldneed[1]
elseif invest == "torment" then
atk = atk.."wield shield longsword441711;assess "..target..";hellforge invest torment;combination " ..target.. " slice " ..shieldneed[1]

elseif invest == "agony" then
atk = atk.."wield shield longsword441711;assess "..target..";hellforge invest agony;combination " ..target.. " slice " ..envenomList[1].. " " ..shieldneed[1]


else
atk = atk.."wield shield longsword441711;assess "..target..";combination " ..target.. " slice "  ..envenomList[1].. " "..shieldneed[1]


end

if partyrelay and ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 40 then send("pt "..target..": Health is at "..ataxiaTemp.lastAssess.."%")
end
if not ataxia.settings.paused then

if add_dedication then
 send("queue addclear free dedication;"..atk)
elseif quash_arc then
send("setalias quasharc "..atk)
send("queue addclear free quasharc")
elseif not engaged then
send("queue addclear free stand;hyena slay " ..target.. ";" ..atk.. ";engage "..target)
elseif invest == "agony" then
send("queue addclear free stand;hyena slay " ..target.. ";" ..atk)
else
send("queue addclear free "..atk)

end

end
end
end