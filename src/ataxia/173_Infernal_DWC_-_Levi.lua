-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > INFERNAL > DWC > Infernal DWC - Levi

function infernaldwckelpstacklevi()
--Set Weapons
weapon1 = "scimitar405403"
weapon2 = "scimitar405398"
ataxiaTemp.hitCount = 0



-- Set Varables
dwcslashdmg = ataxiaTables.limbData.dwcSlash
dwcslash2dmg = tonumber(ataxiaTables.limbData.dwcSlash) + tonumber(ataxiaTables.limbData.dwcSlash)

--Get Targets Anti Active Cure
getLockingAffliction()

--Get Target Lock Status
checkTargetLocks()

--tBals.plant
--tBals.tree


--Tree lock because I am too lazy to put into checkTargetLocks function
if checkAffList({"anorexia", "asthma", "slickness", "paralysis"},4) then
  local	treelock = true
else
  treelock = false
end

--Define Kelp Stack
if checkAffList({"hypochondria", "parasite", "weariness",  "asthma", "healthleech", "clumsiness", "sensitivity"},3) then
  tAffs.kelpstack = true
else
  tAffs.kelpstack = false
end

--Get Anti-Active Cure
tstopcuring = getLockingAffliction(target) or nil
--Anti-Tumble - Confusion might not stop it...
ataxiaTemp.tarTumble = ataxiaTemp.tarTumble or false


--Set Quash
if php <= 35 then
need_quash = true
elseif php <= 45 and tAffs.sensitivity and tAffs.healthleech then
need_quash = true
else need_quash = false end

--Set First Venom Table
envenomList = {}

if truelock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis then
    table.insert(envenomList,"curare") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness then
    table.insert(envenomList,"exploit") 
  elseif getLockingAffliction(target) == "haemophilia" then
    table.insert(envenomList,"torture")
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague then
    table.insert(envenomList,"voyria") 
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity then
    table.insert(envenomList,"aconite")  
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness then
    table.insert(envenomList,"eurypteria")
  else
    table.insert(envenomList,"voyria")   
  end
elseif hardlock == true and not tAffs.paralysis then
  table.insert(envenomList,"curare")
elseif tvenomsleep == true then
  table.insert(envenomList,"delphinium")
elseif tvenomvivisectarms == true then
  table.insert(envenomList,"epteth")
elseif tvenomvivisectarms2 == true then
  table.insert(envenomList,"epteth")
elseif softlock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis then
    table.insert(envenomList,"curare") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness then
    table.insert(envenomList,"exploit") 
  elseif getLockingAffliction(target) == "haemophilia" then
    table.insert(envenomList,"torture")
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague then
    table.insert(envenomList,"voyria") 
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity then
    table.insert(envenomList,"aconite")  
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness then
    table.insert(envenomList,"eurypteria")
  else
    table.insert(envenomList,"voyria")   
  end
elseif softlock == true and not tAffs.paralysis then
  table.insert(envenomList,"curare") 
elseif tAffs.asthma and tAffs.impatience and not tAffs.anorexia and tAffs.slickness then
  table.insert(envenomList,"slike")
elseif tAffs.asthma and tAffs.impatience and tAffs.anorexia and not tAffs.slickness then
  table.insert(envenomList,"gecko")
elseif tAffs.asthma and tAffs.impatience and not tAffs.anorexia and not tAffs.slickness then
  table.insert(envenomList,"slike")
elseif tAffs.slickness and tAffs.asthma and tAffs.impatience and not tAffs.anorexia then
  table.insert(envenomList,"slike")
elseif not tAffs.slickness and tAffs.asthma and tAffs.impatience then
  table.insert(envenomList,"gecko") 
elseif tAffs.slickness or tAffs.paralysis and tAffs.asthma then 
  table.insert(envenomList,"slike")
elseif not tAffs.slickness and tAffs.asthma then
  table.insert(envenomList,"gecko")
--These Classes are impacted by Weariness not Clumsiness
elseif ataxiaNDB_getClass(target) == "Priest" or ataxiaNDB_getClass(target) == "Occultist" or ataxiaNDB_getClass(target) == "Pariah" then
  if not tAffs.weariness then
    table.insert(envenomList,"exploit")
  elseif not tAffs.healthleech then
    table.insert(envenomList,"torment")
  elseif not tAffs.sensitivity then
    table.insert(envenomList,"prefarar")
  elseif not tAffs.asthma then
    table.insert(envenomList,"kalmia")
  elseif not tAffs.nausea then
    table.insert(envenomList,"euphorbia")
  elseif not tAffs.darkshade then
    table.insert(envenomList,"darkshade")
  elseif not tAffs.addiction then
    table.insert(envenomList,"vardrax")

  else
    table.insert(envenomList,"aconite")
  end
elseif not tAffs.clumsiness then
  table.insert(envenomList,"xentio")
elseif not tAffs.sensitivity then
  table.insert(envenomList,"prefarar")
elseif not tAffs.healthleech then
  table.insert(envenomList,"torment")
elseif not tAffs.asthma then
  table.insert(envenomList,"kalmia")
elseif not tAffs.nausea then
  table.insert(envenomList,"euphorbia")
elseif not tAffs.darkshade then
  table.insert(envenomList,"darkshade")
elseif not tAffs.addiction then
  table.insert(envenomList,"vardrax")
else
  table.insert(envenomList,"aconite")
end


--Set Venom Two Table
envenomListTwo = {}

if truelock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis and envenomList[1] ~= "curare" then
    table.insert(envenomListTwo,"curare") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness and envenomList[1] ~= "vernalius" then
    table.insert(envenomListTwo,"vernalius") 
  elseif getLockingAffliction(target) == "haemophilia" then
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague and envenomList[1] ~= "voyria" then
    table.insert(envenomListTwo,"voyria") 
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity and envenomList[1] ~= "aconite" then
    table.insert(envenomListTwo,"aconite")  
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness and envenomList[1] ~= "eurypteria" then
    table.insert(envenomListTwo,"eurypteria") 
  end
elseif hardlock == true and not tAffs.paralysis and envenomList[1] ~= "curare" then
  table.insert(envenomListTwo,"curare") 
elseif tvenomsleep == true then
  table.insert(envenomListTwo,"delphinium")
elseif tvenomvivisectarms == true then
  table.insert(envenomListTwo,"epteth")
elseif tvenomvivisectarms2 == true then
  table.insert(envenomList,"epseth")
elseif softlock == true and not tAffs.paralysis and envenomList[1] ~= "curare" then
  table.insert(envenomListTwo,"curare")
elseif tAffs.asthma and tAffs.impatience and not tAffs.anorexia and tAffs.slickness and envenomList[1] ~= "slike" then
  table.insert(envenomListTwo,"slike")
elseif tAffs.asthma and tAffs.impatience and tAffs.anorexia and not tAffs.slickness and envenomList[1] ~= "gecko" then
  table.insert(envenomListTwo,"gecko")
elseif tAffs.asthma and tAffs.impatience and not tAffs.anorexia and not tAffs.slickness and envenomList[1] ~= "slike" then
  table.insert(envenomListTwo,"slike")
elseif tAffs.slickness and tAffs.asthma and tAffs.impatience and not tAffs.anorexia and envenomList[1] ~= "slike" then
  table.insert(envenomListTwo,"slike") 
elseif not tAffs.slickness and tAffs.asthma and tAffs.impatience and envenomList[1] ~= "gecko" then
  table.insert(envenomListTwo,"gecko") 
elseif not tAffs.slickness and tAffs.asthma and envenomList[1] ~= "gecko" then
  table.insert(envenomListTwo,"gecko")
elseif tAffs.prone and not tAffs.slickness and envenomList[1] ~= "gecko" then
  table.insert(envenomListTwo,"gecko")
elseif not tAffs.paralysis and envenomList[1] ~= "curare" then
  table.insert(envenomListTwo,"curare")
elseif ataxiaNDB_getClass(target) == "Priest" or ataxiaNDB_getClass(target) == "Occultist" or ataxiaNDB_getClass(target) == "Pariah" then
  if not tAffs.weariness and envenomList[1] ~= "exploit" then
    table.insert(envenomListTwo,"exploit")
  elseif not tAffs.nausea and envenomList[1] ~= "euphorbia" then
    table.insert(envenomListTwo,"euphorbia")
  elseif not tAffs.healthleech and envenomList[1] ~= "torment" then
    table.insert(envenomListTwo,"torment")
  elseif not tAffs.haemophilia and envenomList[1] ~= "torture" then
    table.insert(envenomListTwo,"torture")
  elseif not tAffs.asthma and envenomList[1] ~= "kalmia" then
    table.insert(envenomListTwo,"kalmia")
  elseif not tAffs.sensitivity and envenomList[1] ~= "prefarar" then
    table.insert(envenomListTwo,"prefarar")
  elseif not tAffs.darkshade and envenomList[1] ~= "darkshade" then
    table.insert(envenomListTwo,"darkshade")
  elseif not tAffs.addiction and envenomList[1] ~= "vardrax" then
    table.insert(envenomListTwo,"vardrax")
  else
    table.insert(envenomListTwo,"larkspur")
  end
elseif not tAffs.nausea and envenomList[1] ~= "euphorbia" then
  table.insert(envenomListTwo,"euphorbia")
elseif not tAffs.clumsiness and envenomList[1] ~= "xentio" then
  table.insert(envenomListTwo,"xentio")
elseif not tAffs.healthleech and envenomList[1] ~= "torment" then
  table.insert(envenomListTwo,"torment")
elseif not tAffs.haemophilia and envenomList[1] ~= "torture" then
  table.insert(envenomListTwo,"torture")
elseif not tAffs.asthma and envenomList[1] ~= "kalmia" then
  table.insert(envenomListTwo,"kalmia")
elseif not tAffs.weariness and envenomList[1] ~= "exploit" then
  table.insert(envenomListTwo,"exploit")
elseif not tAffs.darkshade and envenomList[1] ~= "darkshade" then
  table.insert(envenomListTwo,"darkshade")
elseif not tAffs.addiction and envenomList[1] ~= "vardrax" then
  table.insert(envenomListTwo,"vardrax")
elseif envenomList[1] ~= "aconite" then
  table.insert(envenomListTwo,"aconite")
end

infernaldwckelpstackattacklevi()
end

function infernaldwckelpstackattacklevi()
if not php then php = 100 end
if not pm then pm = 100 end
partyrelay = partyrelay or true
local atk = combatQueue()

if need_quash then
  atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";quash " ..target.. ";arc " ..target
elseif tAffs.shield and tAffs.rebounding then
  atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";raze " ..target
elseif tAffs.shield then
  atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";rsl " ..target.. " " ..envenomList[1]
elseif tAffs.rebounding then
  atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";rsl " ..target.. " " ..envenomList[1]
elseif envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
  atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " " ..envenomListTwo[1]
elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
  atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " " ..envenomList[1]
else
  atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " " ..envenomList[1].. " " ..envenomListTwo[1]
end

if table.contains(ataxia.playersHere, target) then
  if falconattack == true then
   if not engaged then
    send("queue addclear freestand " ..atk.. ";engage " ..target..";assess " ..target..";assess " ..target)
   else
    send("queue addclear freestand " ..atk..";assess " ..target..";assess " ..target)
   end
  elseif falconattack == false then
    if not engaged then
      send("queue addclear freestand " ..atk.. ";hyena slay " ..target.." ;engage " ..target..";assess " ..target..";assess " ..target)
    else
      send("queue addclear freestand " ..atk.. ";hyena slay " ..target..";assess " ..target..";assess " ..target)
    end
   end
else
  send("queue addclear freestand lunge " ..target..";assess " ..target)

end

end

function infernaldwcvivi3limblevitest()
--Set Weapons
weapon1 = "scimitar405398"
weapon2 = "scimitar405403"

ataxiaTemp.hitCount = 0

--Get Targets Anti Active Cure
getLockingAffliction()

--Get Target Lock Status
checkTargetLocks()

--tBals.plant
--tBals.tree
tvenomvivisectarms = false
tvenomvivisectarms2 = false
tvenomsleep = false
tvivisect = false

--Tree lock because I am too lazy to put into checkTargetLocks function
if checkAffList({"anorexia", "asthma", "slickness", "paralysis"},4) then
  local	treelock = true
else
  treelock = false
end

--Define Kelp Stack
if checkAffList({"hypochondria", "parasite", "weariness",  "asthma", "healthleech", "clumsiness", "sensitivity"},3) then
  tAffs.kelpstack = true
else
  tAffs.kelpstack = false
end

--Get Anti-Active Cure
tstopcuring = getLockingAffliction(target) or nil
--Anti-Tumble - Confusion might not stop it...
ataxiaTemp.tarTumble = ataxiaTemp.tarTumble or false


--Set Variables
mylimbattackpercentage = tonumber(ataxiaTables.limbData.dwcSlash)
-- Set Varables
dwcslashdmg = ataxiaTables.limbData.dwcSlash
dwcslash2dmg = tonumber(ataxiaTables.limbData.dwcSlash) + tonumber(ataxiaTables.limbData.dwcSlash)

--Prep Function
if lb[target].hits["head"] + dwcslashdmg >= 100 and not tAffs.damagedhead then 
dprepped_head = true else
dprepped_head = false
end
if lb[target].hits["head"] + dwcslash2dmg >= 100 and not tAffs.damagedhead then 
d2prepped_head = true else
d2prepped_head = false
end

if lb[target].hits["torso"] + dwcslashdmg >= 100 and not tAffs.mildtrauma then 
dprepped_torso = true else
dprepped_torso = false
end
if lb[target].hits["torso"] + dwcslash2dmg >= 100 and not tAffs.mildtrauma then 
d2prepped_torso = true else
d2prepped_torso = false
end

if lb[target].hits["left leg"] + dwcslashdmg >= 100 and not tAffs.damagedleftleg then 
dprepped_leftleg = true else
dprepped_leftleg = false
end
if lb[target].hits["left leg"] + dwcslash2dmg >= 100 and not tAffs.damagedleftleg then 
d2prepped_leftleg = true else
d2prepped_leftleg = false
end

if lb[target].hits["right leg"] + dwcslashdmg >= 100 and not tAffs.damagedrightleg then 
dprepped_rightleg = true else
dprepped_rightleg = false
end

if lb[target].hits["right leg"] + dwcslash2dmg >= 100 and not tAffs.damagedrightleg then 
d2prepped_rightleg = true 
else
d2prepped_rightleg = false
end

if lb[target].hits["right arm"] + dwcslashdmg >= 100 and not tAffs.damagedrightarm then 
dprepped_rightarm = true else
dprepped_rightarm = false
end
if lb[target].hits["right arm"] + dwcslash2dmg >= 100 and not tAffs.damagedrightarm then 
d2prepped_rightarm = true else
d2prepped_rightarm = false
end

if lb[target].hits["left arm"] + dwcslashdmg >= 100 and not tAffs.damagedleftarm then 
dprepped_leftarm = true else
dprepped_leftarm = false
end
if lb[target].hits["left arm"] + dwcslash2dmg >= 100 and not tAffs.damagedleftarm then 
d2prepped_leftarm = true else
d2prepped_leftarm = false
end

--Limbs
if d2prepped_rightleg == true and d2prepped_leftleg == true and not tAffs.damagedleftleg or tAffs.damagedrightleg then
tvenomsleep = true
end

if tAffs.damagedrightleg and tAffs.prone and d2prepped_leftleg == true then
tvenomvivisectarms = true
tvenomsleep = false
tvenomvivisectarms2 = false
end

if tAffs.damagedleftleg and tAffs.prone and d2prepped_rightleg == true then
tvenomvivisectarms = true
tvenomvivisectarms2 = false
tvenomsleep = false
end

if tAffs.damagedleftleg and tAffs.prone and tAffs.damagedrightleg then
tvenomvivisectarms = true
tvenomvivisectarms2 = false
tvenomsleep = false
end



if tAffs.damagedleftleg or tAffs.brokenleftleg and tAffs.damagedrightleg or tAffs.brokenrightleg and tAffs.damagedrightarm or tAffs.brokenrightarm and tAffs.damagedleftarm or tAffs.brokenleftarm then
tvivisect = true
else
tvivisect = false
end


--Set Quash
if php <= 35 then
need_quash = true
elseif php <= 40 and tAffs.sensitivity and tAffs.healthleech then
need_quash = true
else need_quash = false end

--Set First Venom Table
envenomList = {}

if truelock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis then
    table.insert(envenomList,"curare") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness then
    table.insert(envenomList,"exploit") 
  elseif getLockingAffliction(target) == "haemophilia" then
    table.insert(envenomList,"torture")
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague then
    table.insert(envenomList,"voyria") 
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity then
    table.insert(envenomList,"aconite")  
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness then
    table.insert(envenomList,"eurypteria")
  else
    table.insert(envenomList,"voyria")   
  end
elseif hardlock == true and not tAffs.paralysis then
  table.insert(envenomList,"curare")
elseif tvenomsleep == true then
  table.insert(envenomList,"delphinium")
elseif tvenomvivisectarms == true then
  table.insert(envenomList,"epteth")
elseif tvenomvivisectarms2 == true then
  table.insert(envenomList,"epteth")
elseif softlock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis then
    table.insert(envenomList,"curare") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness then
    table.insert(envenomList,"exploit") 
  elseif getLockingAffliction(target) == "haemophilia" then
    table.insert(envenomList,"torture")
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague then
    table.insert(envenomList,"voyria") 
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity then
    table.insert(envenomList,"aconite")  
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness then
    table.insert(envenomList,"eurypteria")
  else
    table.insert(envenomList,"voyria")   
  end
elseif softlock == true and not tAffs.paralysis then
  table.insert(envenomList,"curare") 
elseif tAffs.asthma and tAffs.impatience and not tAffs.anorexia and tAffs.slickness then
  table.insert(envenomList,"slike")
elseif tAffs.asthma and tAffs.impatience and tAffs.anorexia and not tAffs.slickness then
  table.insert(envenomList,"gecko")
elseif tAffs.asthma and tAffs.impatience and not tAffs.anorexia and not tAffs.slickness then
  table.insert(envenomList,"slike")
elseif tAffs.slickness and tAffs.asthma and tAffs.impatience and not tAffs.anorexia then
  table.insert(envenomList,"slike")
elseif not tAffs.slickness and tAffs.asthma and tAffs.impatience then
  table.insert(envenomList,"gecko") 
elseif tAffs.slickness or tAffs.paralysis and tAffs.asthma then 
  table.insert(envenomList,"slike")
elseif not tAffs.slickness and tAffs.asthma then
  table.insert(envenomList,"gecko")
--These Classes are impacted by Weariness not Clumsiness
elseif ataxiaNDB_getClass(target) == "Priest" or ataxiaNDB_getClass(target) == "Occultist" or ataxiaNDB_getClass(target) == "Pariah" then
  if not tAffs.weariness then
    table.insert(envenomList,"exploit")
  elseif not tAffs.healthleech then
    table.insert(envenomList,"torment")
  elseif not tAffs.nausea then
    table.insert(envenomList,"euphorbia")
  elseif not tAffs.asthma then
    table.insert(envenomList,"kalmia")
  elseif not tAffs.sensitivity then
    table.insert(envenomList,"prefarar")
  elseif not tAffs.darkshade then
    table.insert(envenomList,"darkshade")
  elseif not tAffs.addiction then
    table.insert(envenomList,"vardrax")
  else
    table.insert(envenomList,"aconite")
  end
elseif not tAffs.clumsiness then
  table.insert(envenomList,"xentio")
elseif not tAffs.healthleech then
  table.insert(envenomList,"torment")
elseif not tAffs.nausea then
  table.insert(envenomList,"euphorbia")
elseif not tAffs.asthma then
  table.insert(envenomList,"kalmia")
elseif not tAffs.sensitivity then
  table.insert(envenomList,"prefarar")
elseif not tAffs.darkshade then
  table.insert(envenomList,"darkshade")
elseif not tAffs.addiction then
  table.insert(envenomList,"vardrax")
else
  table.insert(envenomList,"aconite")
end


--Set Venom Two Table
envenomListTwo = {}

if truelock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis and envenomList[1] ~= "curare" then
    table.insert(envenomListTwo,"curare") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness and envenomList[1] ~= "vernalius" then
    table.insert(envenomListTwo,"vernalius") 
  elseif getLockingAffliction(target) == "haemophilia" then
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague and envenomList[1] ~= "voyria" then
    table.insert(envenomListTwo,"voyria") 
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity and envenomList[1] ~= "aconite" then
    table.insert(envenomListTwo,"aconite")  
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness and envenomList[1] ~= "eurypteria" then
    table.insert(envenomListTwo,"eurypteria") 
  end
elseif hardlock == true and not tAffs.paralysis and envenomList[1] ~= "curare" then
  table.insert(envenomListTwo,"curare") 
elseif tvenomsleep == true then
  table.insert(envenomListTwo,"delphinium")
elseif tvenomvivisectarms == true then
  table.insert(envenomListTwo,"epteth")
elseif tvenomvivisectarms2 == true then
  table.insert(envenomList,"epseth")
elseif softlock == true and not tAffs.paralysis and envenomList[1] ~= "curare" then
  table.insert(envenomListTwo,"curare")
elseif tAffs.asthma and tAffs.impatience and not tAffs.anorexia and tAffs.slickness and envenomList[1] ~= "slike" then
  table.insert(envenomListTwo,"slike")
elseif tAffs.asthma and tAffs.impatience and tAffs.anorexia and not tAffs.slickness and envenomList[1] ~= "gecko" then
  table.insert(envenomListTwo,"gecko")
elseif tAffs.asthma and tAffs.impatience and not tAffs.anorexia and not tAffs.slickness and envenomList[1] ~= "slike" then
  table.insert(envenomListTwo,"slike")
elseif tAffs.slickness and tAffs.asthma and tAffs.impatience and not tAffs.anorexia and envenomList[1] ~= "slike" then
  table.insert(envenomListTwo,"slike") 
elseif not tAffs.slickness and tAffs.asthma and tAffs.impatience and envenomList[1] ~= "gecko" then
  table.insert(envenomListTwo,"gecko") 
elseif not tAffs.slickness and tAffs.asthma and envenomList[1] ~= "gecko" then
  table.insert(envenomListTwo,"gecko")
elseif tAffs.prone and not tAffs.slickness and envenomList[1] ~= "gecko" then
  table.insert(envenomListTwo,"gecko")
elseif not tAffs.paralysis and envenomList[1] ~= "curare" then
  table.insert(envenomListTwo,"curare")
elseif ataxiaNDB_getClass(target) == "Priest" or ataxiaNDB_getClass(target) == "Occultist" or ataxiaNDB_getClass(target) == "Pariah" then
  if not tAffs.weariness and envenomList[1] ~= "exploit" then
    table.insert(envenomListTwo,"exploit")
  elseif not tAffs.nausea and envenomList[1] ~= "euphorbia" then
    table.insert(envenomListTwo,"euphorbia")
  elseif not tAffs.healthleech and envenomList[1] ~= "torment" then
    table.insert(envenomListTwo,"torment")
  elseif not tAffs.haemophilia and envenomList[1] ~= "torture" then
    table.insert(envenomListTwo,"torture")
  elseif not tAffs.asthma and envenomList[1] ~= "kalmia" then
    table.insert(envenomListTwo,"kalmia")
  elseif not tAffs.sensitivity and envenomList[1] ~= "prefarar" then
    table.insert(envenomListTwo,"prefarar")
  elseif not tAffs.darkshade and envenomList[1] ~= "darkshade" then
    table.insert(envenomListTwo,"darkshade")
  elseif not tAffs.addiction and envenomList[1] ~= "vardrax" then
    table.insert(envenomListTwo,"vardrax")
  else
    table.insert(envenomListTwo,"larkspur")
  end
elseif not tAffs.nausea and envenomList[1] ~= "euphorbia" then
  table.insert(envenomListTwo,"euphorbia")
elseif not tAffs.clumsiness and envenomList[1] ~= "xentio" then
  table.insert(envenomListTwo,"xentio")
elseif not tAffs.healthleech and envenomList[1] ~= "torment" then
  table.insert(envenomListTwo,"torment")
elseif not tAffs.haemophilia and envenomList[1] ~= "torture" then
  table.insert(envenomListTwo,"torture")
elseif not tAffs.asthma and envenomList[1] ~= "kalmia" then
  table.insert(envenomListTwo,"kalmia")
elseif not tAffs.weariness and envenomList[1] ~= "exploit" then
  table.insert(envenomListTwo,"exploit")
elseif not tAffs.darkshade and envenomList[1] ~= "darkshade" then
  table.insert(envenomListTwo,"darkshade")
elseif not tAffs.addiction and envenomList[1] ~= "vardrax" then
  table.insert(envenomListTwo,"vardrax")
elseif envenomList[1] ~= "aconite" then
  table.insert(envenomListTwo,"aconite")
end




if not php then php = 100 end
if not pm then pm = 100 end
partyrelay = partyrelay or true
local atk = combatQueue()

if tvivisect == true then
 atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dismount;vivisect " ..target
elseif tvivisect == true and ataxiaNDB.players[target].city == "Mhaldor" then
 atk = atk..";say Vivisect"

elseif need_quash then
  atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";quash " ..target.. ";arc " ..target
elseif tAffs.shield and tAffs.rebounding then
  atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";raze " ..target
elseif tAffs.shield then
  atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";rsl " ..target.. " " ..envenomList[1]
elseif tAffs.rebounding then
  atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";rsl " ..target.. " " ..envenomList[1]
--Prep
elseif tAffs.damagedleftleg or tAffs.brokenleftleg and tAffs.damagedrightleg or tAffs.brokenrightleg and d2prepped_leftarm == true and tAffs.prone then
  if envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " left arm " ..envenomListTwo[1]
  elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " left arm " ..envenomList[1]
  else
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " left arm " ..envenomList[1].. " " ..envenomListTwo[1]
  end

elseif tAffs.damagedleftleg or tAffs.brokenleftleg and tAffs.damagedrightleg or tAffs.brokenrightleg and d2prepped_rightarm == true and tAffs.prone then
  if envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " right arm " ..envenomListTwo[1]
  elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " right arm " ..envenomList[1]
  else
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " right arm " ..envenomList[1].. " " ..envenomListTwo[1]
  end
elseif d2prepped_leftleg == true and tAffs.damagedrightleg and d2prepped_rightarm == true or d2prepped_leftarm == true and tAffs.prone then
  if envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " left leg " ..envenomListTwo[1]
  elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " left leg " ..envenomList[1]
  else
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " left leg " ..envenomList[1].. " " ..envenomListTwo[1]
  end
elseif d2prepped_rightleg == true and tAffs.damagedleftleg and d2prepped_rightarm == true or d2prepped_leftarm == true and tAffs.prone then
  if envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " right leg " ..envenomListTwo[1]
  elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " right leg " ..envenomList[1]
  else
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " right leg " ..envenomList[1].. " " ..envenomListTwo[1]
  end
elseif d2prepped_rightleg == true and d2prepped_leftleg == true and d2prepped_rightarm == true or d2prepped_leftarm == true and (tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "right leg" or tAffs.nausea) then
  if envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " right leg " ..envenomListTwo[1]
  elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " right leg " ..envenomList[1]
  else
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " right leg " ..envenomList[1].. " " ..envenomListTwo[1]
  end
elseif d2prepped_rightleg == true and d2prepped_leftleg == true and d2prepped_rightarm == true or d2prepped_leftarm == true and (tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "left leg" or tAffs.nausea) then
  if envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " left leg " ..envenomListTwo[1]
  elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " left leg " ..envenomList[1]
  else
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " left leg " ..envenomList[1].. " " ..envenomListTwo[1]
  end
elseif d2prepped_rightleg == true and d2prepped_leftleg == true and d2prepped_rightarm == false and (tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "right arm" or tAffs.nausea) then
  if envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " right arm " ..envenomListTwo[1]
  elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " right arm " ..envenomList[1]
  else
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " right arm " ..envenomList[1].. " " ..envenomListTwo[1]
  end
elseif d2prepped_rightleg == true and d2prepped_leftleg == false and (tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "left leg" or tAffs.nausea) then
  if envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " left leg " ..envenomListTwo[1]
  elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " left leg " ..envenomList[1]
  else
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " left leg " ..envenomList[1].. " " ..envenomListTwo[1]
  end
elseif d2prepped_rightleg == false and d2prepped_leftleg == true and (tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "right leg" or tAffs.nausea) then
  if envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " right leg " ..envenomListTwo[1]
  elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " right leg " ..envenomList[1]
  else
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " right leg " ..envenomList[1].. " " ..envenomListTwo[1]
  end
elseif d2prepped_rightleg == false and not tAffs.damagedrightleg and (tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "right leg" or tAffs.nausea) then
  if envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " right leg " ..envenomListTwo[1]
  elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " right leg " ..envenomList[1]
  else
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " right leg " ..envenomList[1].. " " ..envenomListTwo[1]
  end
elseif not d2prepped_leftleg and not tAffs.damagedleftleg and (tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "left leg" or tAffs.nausea)  then
  if envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " left leg " ..envenomListTwo[1]
  elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " left leg " ..envenomList[1]
  else
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " left leg " ..envenomList[1].. " " ..envenomListTwo[1]
  end
elseif not d2prepped_rightarm and not tAffs.damagedrightarm and (tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "right arm" or tAffs.nausea)  then
  if envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " right arm " ..envenomListTwo[1]
  elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " right arm " ..envenomList[1]
  else
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " right arm " ..envenomList[1].. " " ..envenomListTwo[1]
  end
elseif not d2prepped_leftarm and not tAffs.damagedleftarm and (tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "left arm" or tAffs.nausea)  then
   if envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " left arm " ..envenomListTwo[1]
  elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " left arm " ..envenomList[1]
  else
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " left arm " ..envenomList[1].. " " ..envenomListTwo[1]
  end
else 
  atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " " ..envenomList[1].. " " ..envenomListTwo[1]

end

--ATTACK
if table.contains(ataxia.playersHere, target) then
  if falconattack == true then
   if not engaged then
    send("queue addclear freestand " ..atk.. ";engage " ..target..";assess " ..target)
   else
    send("queue addclear freestand " ..atk..";assess " ..target)
   end
  elseif falconattack == false then
    if not engaged then
      send("queue addclear freestand " ..atk.. ";hyena slay " ..target.." ;engage " ..target..";assess " ..target)
    else
      send("queue addclear freestand " ..atk.. ";hyena slay " ..target..";assess " ..target)
    end
   end
else
  send("queue addclear freestand lunge " ..target..";assess " ..target)

end

end



function infernaldwcvivi2limblevitest()
--Set Weapons
weapon1 = "scimitar405398"
weapon2 = "scimitar405403"

--Get Targets Anti Active Cure
getLockingAffliction()

--Get Target Lock Status
checkTargetLocks()

--tBals.plant
--tBals.tree
tvenomvivisectarms = false
tvenomvivisectarms2 = false
tvenomsleep = false
tvivisect = false

--Tree lock because I am too lazy to put into checkTargetLocks function
if checkAffList({"anorexia", "asthma", "slickness", "paralysis"},4) then
  local	treelock = true
else
  treelock = false
end

--Define Kelp Stack
if checkAffList({"hypochondria", "parasite", "weariness",  "asthma", "healthleech", "clumsiness", "sensitivity"},3) then
  tAffs.kelpstack = true
else
  tAffs.kelpstack = false
end

--Get Anti-Active Cure
tstopcuring = getLockingAffliction(target) or nil
--Anti-Tumble - Confusion might not stop it...
ataxiaTemp.tarTumble = ataxiaTemp.tarTumble or false


--Set Variables
mylimbattackpercentage = tonumber(ataxiaTables.limbData.dwcSlash)
-- Set Varables
dwcslashdmg = ataxiaTables.limbData.dwcSlash
dwcslash2dmg = tonumber(ataxiaTables.limbData.dwcSlash) + tonumber(ataxiaTables.limbData.dwcSlash)

--Prep Function
if lb[target].hits["head"] + dwcslashdmg >= 100 and not tAffs.damagedhead then 
dprepped_head = true else
dprepped_head = false
end
if lb[target].hits["head"] + dwcslash2dmg >= 100 and not tAffs.damagedhead then 
d2prepped_head = true else
d2prepped_head = false
end

if lb[target].hits["torso"] + dwcslashdmg >= 100 and not tAffs.mildtrauma then 
dprepped_torso = true else
dprepped_torso = false
end
if lb[target].hits["torso"] + dwcslash2dmg >= 100 and not tAffs.mildtrauma then 
d2prepped_torso = true else
d2prepped_torso = false
end

if lb[target].hits["left leg"] + dwcslashdmg >= 100 and not tAffs.damagedleftleg then 
dprepped_leftleg = true else
dprepped_leftleg = false
end
if lb[target].hits["left leg"] + dwcslash2dmg >= 100 and not tAffs.damagedleftleg then 
d2prepped_leftleg = true else
d2prepped_leftleg = false
end

if lb[target].hits["right leg"] + dwcslashdmg >= 100 and not tAffs.damagedrightleg then 
dprepped_rightleg = true else
dprepped_rightleg = false
end

if lb[target].hits["right leg"] + dwcslash2dmg >= 100 and not tAffs.damagedrightleg then 
d2prepped_rightleg = true 
else
d2prepped_rightleg = false
end

if lb[target].hits["right arm"] + dwcslashdmg >= 100 and not tAffs.damagedrightarm then 
dprepped_rightarm = true else
dprepped_rightarm = false
end
if lb[target].hits["right arm"] + dwcslash2dmg >= 100 and not tAffs.damagedrightarm then 
d2prepped_rightarm = true else
d2prepped_rightarm = false
end

if lb[target].hits["left arm"] + dwcslashdmg >= 100 and not tAffs.damagedleftarm then 
dprepped_leftarm = true else
dprepped_leftarm = false
end
if lb[target].hits["left arm"] + dwcslash2dmg >= 100 and not tAffs.damagedleftarm then 
d2prepped_leftarm = true else
d2prepped_leftarm = false
end

--Limbs
if d2prepped_rightleg == true and d2prepped_leftleg == true and not tAffs.damagedleftleg or tAffs.damagedrightleg then
tvenomsleep = true
end

if tAffs.damagedrightleg and tAffs.prone and d2prepped_leftleg == true then
tvenomvivisectarms = true
tvenomsleep = false
tvenomvivisectarms2 = false
end

if tAffs.damagedleftleg and tAffs.prone and d2prepped_rightleg == true then
tvenomvivisectarms = true
tvenomvivisectarms2 = false
tvenomsleep = false
end

if tAffs.damagedleftleg and tAffs.prone and tAffs.damagedrightleg then
tvenomvivisectarms = true
tvenomvivisectarms2 = false
tvenomsleep = false
end



if tAffs.damagedleftleg or tAffs.brokenleftleg and tAffs.damagedrightleg or tAffs.brokenrightleg and tAffs.damagedrightarm or tAffs.brokenrightarm and tAffs.damagedleftarm or tAffs.brokenleftarm then
tvivisect = true
else
tvivisect = false
end

--Set Quash
if php <= 35 then
need_quash = true
elseif php <= 40 and tAffs.sensitivity and tAffs.healthleech then
need_quash = true
else need_quash = false end

--Set First Venom Table
envenomList = {}

if truelock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis then
    table.insert(envenomList,"curare") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness then
    table.insert(envenomList,"exploit") 
  elseif getLockingAffliction(target) == "haemophilia" then
    table.insert(envenomList,"torture")
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague then
    table.insert(envenomList,"voyria") 
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity then
    table.insert(envenomList,"aconite")  
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness then
    table.insert(envenomList,"eurypteria")
  else
    table.insert(envenomList,"voyria")   
  end
elseif hardlock == true and not tAffs.paralysis then
  table.insert(envenomList,"curare")
elseif tvenomsleep == true then
  table.insert(envenomList,"delphinium")
elseif tvenomvivisectarms == true then
  table.insert(envenomList,"epteth")
elseif tvenomvivisectarms2 == true then
  table.insert(envenomList,"epteth")
elseif softlock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis then
    table.insert(envenomList,"curare") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness then
    table.insert(envenomList,"exploit") 
  elseif getLockingAffliction(target) == "haemophilia" then
    table.insert(envenomList,"torture")
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague then
    table.insert(envenomList,"voyria") 
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity then
    table.insert(envenomList,"aconite")  
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness then
    table.insert(envenomList,"eurypteria")
  else
    table.insert(envenomList,"voyria")   
  end
elseif softlock == true and not tAffs.paralysis then
  table.insert(envenomList,"curare") 
elseif tAffs.asthma and tAffs.impatience and not tAffs.anorexia and tAffs.slickness then
  table.insert(envenomList,"slike")
elseif tAffs.asthma and tAffs.impatience and tAffs.anorexia and not tAffs.slickness then
  table.insert(envenomList,"gecko")
elseif tAffs.asthma and tAffs.impatience and not tAffs.anorexia and not tAffs.slickness then
  table.insert(envenomList,"slike")
elseif tAffs.slickness and tAffs.asthma and tAffs.impatience and not tAffs.anorexia then
  table.insert(envenomList,"slike")
elseif not tAffs.slickness and tAffs.asthma and tAffs.impatience then
  table.insert(envenomList,"gecko") 
elseif tAffs.slickness or tAffs.paralysis and tAffs.asthma then 
  table.insert(envenomList,"slike")
elseif not tAffs.slickness and tAffs.asthma then
  table.insert(envenomList,"gecko")
--These Classes are impacted by Weariness not Clumsiness
elseif ataxiaNDB_getClass(target) == "Priest" or ataxiaNDB_getClass(target) == "Occultist" or ataxiaNDB_getClass(target) == "Pariah" then
  if not tAffs.weariness then
    table.insert(envenomList,"exploit")
  elseif not tAffs.healthleech then
    table.insert(envenomList,"torment")
  elseif not tAffs.nausea then
    table.insert(envenomList,"euphorbia")
  elseif not tAffs.asthma then
    table.insert(envenomList,"kalmia")
  elseif not tAffs.sensitivity then
    table.insert(envenomList,"prefarar")
  elseif not tAffs.darkshade then
    table.insert(envenomList,"darkshade")
  elseif not tAffs.addiction then
    table.insert(envenomList,"vardrax")
  else
    table.insert(envenomList,"aconite")
  end
elseif not tAffs.nausea then
  table.insert(envenomList,"euphorbia")
elseif not tAffs.clumsiness then
  table.insert(envenomList,"xentio")
elseif not tAffs.sensitivity then
    table.insert(envenomList,"prefarar")
elseif not tAffs.healthleech then
  table.insert(envenomList,"torment")
elseif not tAffs.asthma then
  table.insert(envenomList,"kalmia")
elseif not tAffs.darkshade then
  table.insert(envenomList,"darkshade")
elseif not tAffs.addiction then
  table.insert(envenomList,"vardrax")
else
  table.insert(envenomList,"aconite")
end


--Set Venom Two Table
envenomListTwo = {}

if truelock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis and envenomList[1] ~= "curare" then
    table.insert(envenomListTwo,"curare") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness and envenomList[1] ~= "vernalius" then
    table.insert(envenomListTwo,"vernalius") 
  elseif getLockingAffliction(target) == "haemophilia" then
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague and envenomList[1] ~= "voyria" then
    table.insert(envenomListTwo,"voyria") 
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity and envenomList[1] ~= "aconite" then
    table.insert(envenomListTwo,"aconite")  
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness and envenomList[1] ~= "eurypteria" then
    table.insert(envenomListTwo,"eurypteria") 
  end
elseif hardlock == true and not tAffs.paralysis and envenomList[1] ~= "curare" then
  table.insert(envenomListTwo,"curare") 
elseif tvenomsleep == true then
  table.insert(envenomListTwo,"delphinium")
elseif tvenomvivisectarms == true then
  table.insert(envenomListTwo,"epteth")
elseif tvenomvivisectarms2 == true then
  table.insert(envenomList,"epseth")
elseif softlock == true and not tAffs.paralysis and envenomList[1] ~= "curare" then
  table.insert(envenomListTwo,"curare")
elseif tAffs.asthma and tAffs.impatience and not tAffs.anorexia and tAffs.slickness and envenomList[1] ~= "slike" then
  table.insert(envenomListTwo,"slike")
elseif tAffs.asthma and tAffs.impatience and tAffs.anorexia and not tAffs.slickness and envenomList[1] ~= "gecko" then
  table.insert(envenomListTwo,"gecko")
elseif tAffs.asthma and tAffs.impatience and not tAffs.anorexia and not tAffs.slickness and envenomList[1] ~= "slike" then
  table.insert(envenomListTwo,"slike")
elseif tAffs.slickness and tAffs.asthma and tAffs.impatience and not tAffs.anorexia and envenomList[1] ~= "slike" then
  table.insert(envenomListTwo,"slike") 
elseif not tAffs.slickness and tAffs.asthma and tAffs.impatience and envenomList[1] ~= "gecko" then
  table.insert(envenomListTwo,"gecko") 
elseif not tAffs.slickness and tAffs.asthma and envenomList[1] ~= "gecko" then
  table.insert(envenomListTwo,"gecko")
elseif tAffs.prone and not tAffs.slickness and envenomList[1] ~= "gecko" then
  table.insert(envenomListTwo,"gecko")
elseif not tAffs.paralysis and envenomList[1] ~= "curare" then
  table.insert(envenomListTwo,"curare")
elseif ataxiaNDB_getClass(target) == "Priest" or ataxiaNDB_getClass(target) == "Occultist" or ataxiaNDB_getClass(target) == "Pariah" then
  if not tAffs.weariness and envenomList[1] ~= "exploit" then
    table.insert(envenomListTwo,"exploit")
  elseif not tAffs.nausea and envenomList[1] ~= "euphorbia" then
    table.insert(envenomListTwo,"euphorbia")
  elseif not tAffs.healthleech and envenomList[1] ~= "torment" then
    table.insert(envenomListTwo,"torment")
  elseif not tAffs.haemophilia and envenomList[1] ~= "torture" then
    table.insert(envenomListTwo,"torture")
  elseif not tAffs.asthma and envenomList[1] ~= "kalmia" then
    table.insert(envenomListTwo,"kalmia")
  elseif not tAffs.sensitivity and envenomList[1] ~= "prefarar" then
    table.insert(envenomListTwo,"prefarar")
  elseif not tAffs.darkshade and envenomList[1] ~= "darkshade" then
    table.insert(envenomListTwo,"darkshade")
  elseif not tAffs.addiction and envenomList[1] ~= "vardrax" then
    table.insert(envenomListTwo,"vardrax")
  else
    table.insert(envenomListTwo,"larkspur")
  end
elseif not tAffs.nausea and envenomList[1] ~= "euphorbia" then
  table.insert(envenomListTwo,"euphorbia")
elseif not tAffs.clumsiness and envenomList[1] ~= "xentio" then
  table.insert(envenomListTwo,"xentio")
elseif not tAffs.sensitivity and envenomList[1] ~= "prefarar" then
    table.insert(envenomListTwo,"prefarar")
elseif not tAffs.healthleech and envenomList[1] ~= "torment" then
  table.insert(envenomListTwo,"torment")
elseif not tAffs.haemophilia and envenomList[1] ~= "torture" then
  table.insert(envenomListTwo,"torture")
elseif not tAffs.asthma and envenomList[1] ~= "kalmia" then
  table.insert(envenomListTwo,"kalmia")
elseif not tAffs.weariness and envenomList[1] ~= "exploit" then
  table.insert(envenomListTwo,"exploit")
elseif not tAffs.darkshade and envenomList[1] ~= "darkshade" then
  table.insert(envenomListTwo,"darkshade")
elseif not tAffs.addiction and envenomList[1] ~= "vardrax" then
  table.insert(envenomListTwo,"vardrax")
elseif envenomList[1] ~= "aconite" then
  table.insert(envenomListTwo,"aconite")
end
  infernaldwcvivi2limblevitestattack()
end

function infernaldwcvivi2limblevitestattack()

if not php then php = 100 end
if not pm then pm = 100 end
partyrelay = partyrelay or true
local atk = combatQueue()
ataxiaTemp.hitCount = 0

if tvivisect == true and ataxiaNDB.players[target].city ~= "Mhaldor" then
 atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dismount;vivisect " ..target


elseif need_quash then
  atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";quash " ..target.. ";arc " ..target
elseif tAffs.shield and tAffs.rebounding then
  atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";raze " ..target
elseif tAffs.shield then
  atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";rsl " ..target.. " " ..envenomList[1]
elseif tAffs.rebounding then
  atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";rsl " ..target.. " " ..envenomList[1]

--Prep
elseif d2prepped_rightleg == true and tAffs.damagedleftleg and tAffs.prone then
  if envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " right leg " ..envenomListTwo[1]
  elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " right leg " ..envenomList[1]
  else
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " right leg " ..envenomList[1].. " " ..envenomListTwo[1]
  end
elseif d2prepped_leftleg == true and tAffs.damagedrightleg and tAffs.prone then
  if envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " left leg " ..envenomListTwo[1]
  elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " left leg " ..envenomList[1]
  else
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " left leg " ..envenomList[1].. " " ..envenomListTwo[1]
  end
elseif d2prepped_rightleg == true and d2prepped_leftleg == true and (tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "right leg" or tAffs.nausea) then
  if envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " right leg " ..envenomListTwo[1]
  elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " right leg " ..envenomList[1]
  else
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " right leg " ..envenomList[1].. " " ..envenomListTwo[1]
  end
elseif d2prepped_rightleg == true and d2prepped_leftleg == true and (tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "left leg" or tAffs.nausea) then
  if envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " left leg " ..envenomListTwo[1]
  elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " left leg " ..envenomList[1]
  else
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " left leg " ..envenomList[1].. " " ..envenomListTwo[1]
  end

elseif d2prepped_rightleg == true and d2prepped_leftleg == false and (tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "left leg" or tAffs.nausea) then
  if envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " left leg " ..envenomListTwo[1]
  elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " left leg " ..envenomList[1]
  else
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " left leg " ..envenomList[1].. " " ..envenomListTwo[1]
  end
elseif d2prepped_rightleg == false and d2prepped_leftleg == true and (tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "right leg" or tAffs.nausea) then
  if envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " right leg " ..envenomListTwo[1]
  elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " right leg " ..envenomList[1]
  else
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " right leg " ..envenomList[1].. " " ..envenomListTwo[1]
  end
elseif d2prepped_rightleg == false and not tAffs.damagedrightleg and (tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "right leg" or tAffs.nausea) then
  if envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " right leg " ..envenomListTwo[1]
  elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " right leg " ..envenomList[1]
  else
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " right leg " ..envenomList[1].. " " ..envenomListTwo[1]
  end
elseif not d2prepped_leftleg and not tAffs.damagedleftleg and (tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "left leg" or tAffs.nausea)  then
  if envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " left leg " ..envenomListTwo[1]
  elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " left leg " ..envenomList[1]
  else
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " left leg " ..envenomList[1].. " " ..envenomListTwo[1]
  end
elseif not d2prepped_torso and not tAffs.mildtrauma and (tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "torso" or tAffs.nausea)  then
  if envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " torso " ..envenomListTwo[1]
  elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " torso " ..envenomList[1]
  else
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " torso " ..envenomList[1].. " " ..envenomListTwo[1]
  end
elseif not d2prepped_rightarm and not tAffs.damagedrightarm and (tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "right arm" or tAffs.nausea)  then
  if envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " right arm " ..envenomListTwo[1]
  elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " right arm " ..envenomList[1]
  else
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " right arm " ..envenomList[1].. " " ..envenomListTwo[1]
  end
elseif not d2prepped_leftarm and not tAffs.damagedleftarm and (tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "left arm" or tAffs.nausea)  then
   if envenomList[1] == "exploit" or envenomList[1] == "torture" or envenomList[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomList[1]..";dsl " ..target.. " left arm " ..envenomListTwo[1]
  elseif envenomListTwo[1] == "exploit" or envenomListTwo[1] == "torture" or envenomListTwo[1] == "torment" then
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";hellforge invest " ..envenomListTwo[1]..";dsl " ..target.. " left arm " ..envenomList[1]
  else
    atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " left arm " ..envenomList[1].. " " ..envenomListTwo[1]
  end
else 
  atk = atk.. "wield left "..weapon1..";wield right "..weapon2.. ";wipe " ..weapon1.. ";wipe " ..weapon2.. ";dsl " ..target.. " " ..envenomList[1].. " " ..envenomListTwo[1]

end

--ATTACK
if table.contains(ataxia.playersHere, target) then
  if falconattack == true then
   if not engaged then
    send("queue addclear freestand " ..atk.. ";engage " ..target..";assess " ..target)
   else
    send("queue addclear freestand " ..atk..";assess " ..target)
   end
  elseif falconattack == false then
    if not engaged then
      send("queue addclear freestand " ..atk.. ";hyena slay " ..target.." ;engage " ..target..";assess " ..target)
    else
      send("queue addclear freestand " ..atk.. ";hyena slay " ..target..";assess " ..target)
    end
   end
else
  send("queue addclear freestand lunge " ..target)

end

end


