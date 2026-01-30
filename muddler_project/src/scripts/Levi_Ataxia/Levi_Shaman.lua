function levishamanlock()
--Get Targets Anti Active Cure
getLockingAffliction()

--Get Target Lock Status
checkTargetLocks()

--tBals.plant
--tBals.tree
--tAffs.hypnoseal
--snapTarget
--tAffs.snapped
--tAffs.hypnotising

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

--Define Tzantza
if checkAffList({"agoraphobia", "confusion", "claustrophobia",  "amnesia", "dementia", "impatience", "dizziness","paranoia", "stupidity", "addiction",  "epilepsy", "dementia", "vertigo ", "masochism","recklessness"},4) then
  tAffs.tzanstack = true
else
  tAffs.tzanstack = false
end    
     
if checkAffList({"agoraphobia", "confusion", "claustrophobia",  "amnesia", "dementia", "impatience", "dizziness","paranoia", "stupidity", "addiction",  "epilepsy", "dementia", "vertigo ", "masochism","recklessness"},5) then
  tAffs.tzanstack2 = true
else
  tAffs.tzanstack2 = false
end        

if checkAffList({"agoraphobia", "confusion", "claustrophobia",  "amnesia", "dementia", "impatience", "dizziness","paranoia", "stupidity", "addiction",  "epilepsy", "dementia", "vertigo ", "masochism","recklessness"},6) then
  tAffs.tzanstackinstant = true
else
  tAffs.tzanstackinstant = false
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

envenomList = {}

if tAffs.curseward then
  table.insert(envenomList,"breach") 
elseif truelock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis then
    table.insert(envenomList,"paralyse") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness then
    table.insert(envenomList,"weariness") 
  elseif getLockingAffliction(target) == "haemophilia" then
	  table.insert(envenomList,"haemophilia") 
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague then
    table.insert(envenomList,"plague") 
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity then
    table.insert(envenomList,"stupid")  
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness then
    table.insert(envenomList,"reckless")
  else
    table.insert(envenomList,"plague")   
  end
elseif hardlock == true and not tAffs.paralysis then
  table.insert(envenomList,"paralyse") 
elseif softlock == true and not tAffs.paralysis then
  table.insert(envenomList,"paralyse") 
elseif tAffs.asthma and tAffs.impatience and not tAffs.anorexia and tAffs.slickness then
  table.insert(envenomList,"anorexia")
elseif tAffs.asthma and tAffs.impatience and tAffs.anorexia and not tAffs.slickness then
  table.insert(envenomList,"gecko")
elseif tAffs.asthma and tAffs.impatience and not tAffs.anorexia and not tAffs.slickness then
  table.insert(envenomList,"anorexia")
elseif tAffs.slickness and tAffs.asthma and tAffs.impatience and not tAffs.anorexia then
  table.insert(envenomList,"anorexia") 
elseif not tAffs.slickness and tAffs.asthma and tAffs.impatience then
  table.insert(envenomList,"gecko") 
elseif not tAffs.slickness and tAffs.asthma then
  table.insert(envenomList,"gecko")
elseif ataxiaNDB_getClass(target) == "Priest" or ataxiaNDB_getClass(target) == "Occultist" or ataxiaNDB_getClass(target) == "Pariah" then
  if not tAffs.weariness then
    table.insert(envenomList,"weariness")
  elseif not tAffs.asthma then
    table.insert(envenomList,"asthma")
  elseif not tAffs.nausea then
    table.insert(envenomList,"vomiting")
  elseif not tAffs.darkshade then
    table.insert(envenomList,"darkshade")
  elseif not tAffs.addiction then
    table.insert(envenomList,"addiction")
  else
    table.insert(envenomList,"stupid")
  end
elseif not tAffs.clumsiness then
  table.insert(envenomList,"clumsy")
elseif not tAffs.impatience then
  table.insert(envenomList,"impatience")
elseif not tAffs.asthma then
  table.insert(envenomList,"asthma")
elseif not tAffs.weariness then
  table.insert(envenomList,"weariness")
elseif not tAffs.nausea then
  table.insert(envenomList,"vomiting")
elseif not tAffs.addiction then
  table.insert(envenomList,"addiction")
else
  table.insert(envenomList,"stupid")
end



--Set Venom Two Table
envenomListTwo = {}

if truelock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis and envenomList[1] ~= "paralyse" then
    table.insert(envenomListTwo,"paralyse") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness and envenomList[1] ~= "weariness" then
    table.insert(envenomListTwo,"weariness") 
  elseif getLockingAffliction(target) == "haemophilia" and not tAffs.haemophilia and envenomList[1] ~= "haemophilia" then
	table.insert(envenomList,"haemophilia") 
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague and envenomList[1] ~= "plague" then
    table.insert(envenomListTwo,"plague") 
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity and envenomList[1] ~= "stupid" then
    table.insert(envenomListTwo,"stupid")  
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness and envenomList[1] ~= "reckless" then
   table.insert(envenomListTwo,"reckless") 
  end
elseif hardlock == true and not tAffs.paralysis and envenomList[1] ~= "paralyse" then
  table.insert(envenomListTwo,"paralyse") 
elseif softlock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis and envenomList[1] ~= "paralyse" then
    table.insert(envenomListTwo,"paralyse") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness and envenomList[1] ~= "weariness" then
    table.insert(envenomListTwo,"weariness") 
  elseif getLockingAffliction(target) == "haemophilia" and not tAffs.haemophilia and envenomList[1] ~= "haemophilia" then
	table.insert(envenomList,"haemophilia") 
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague and envenomList[1] ~= "plague" then
    table.insert(envenomListTwo,"plague") 
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity and envenomList[1] ~= "stupid" then
    table.insert(envenomListTwo,"stupid")  
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness and envenomList[1] ~= "reckless" then
   table.insert(envenomListTwo,"reckless") 
  end
elseif softlock == true and not tAffs.paralysis and envenomList[1] ~= "paralyse" then
  table.insert(envenomListTwo,"paralyse")
elseif tAffs.asthma and tAffs.impatience and not tAffs.anorexia and tAffs.slickness and envenomList[1] ~= "anorexia" then
  table.insert(envenomListTwo,"anorexia")
elseif tAffs.asthma and tAffs.impatience and tAffs.anorexia and not tAffs.slickness and envenomList[1] ~= "gecko" then
  table.insert(envenomListTwo,"gecko")
elseif tAffs.asthma and tAffs.impatience and not tAffs.anorexia and not tAffs.slickness and envenomList[1] ~= "anorexia" then
  table.insert(envenomListTwo,"anorexia")
elseif tAffs.slickness and tAffs.asthma and tAffs.impatience and not tAffs.anorexia and envenomList[1] ~= "anorexia" then
  table.insert(envenomListTwo,"anorexia") 
elseif not tAffs.slickness and tAffs.asthma and tAffs.impatience and envenomList[1] ~= "gecko" then
  table.insert(envenomListTwo,"gecko") 
elseif not tAffs.slickness and tAffs.asthma and envenomList[1] ~= "gecko" then
  table.insert(envenomListTwo,"gecko")
elseif tAffs.prone and not tAffs.slickness and envenomList[1] ~= "gecko" then
  table.insert(envenomListTwo,"gecko")
elseif not tAffs.paralysis and envenomList[1] ~= "paralyse" then
  table.insert(envenomListTwo,"paralyse")
elseif not tAffs.asthma and envenomList[1] ~= "asthma" then
  table.insert(envenomListTwo,"asthma")
elseif not tAffs.weariness and envenomList[1] ~= "weariness" then
  table.insert(envenomListTwo,"weariness")
elseif not tAffs.clumsiness and envenomList[1] ~= "clumsy" then
  table.insert(envenomListTwo,"clumsy")
elseif not tAffs.nausea and envenomList[1] ~= "euphorbia" then
  table.insert(envenomListTwo,"euphorbia")
elseif not tAffs.addiction and envenomList[1] ~= "addiction" then
  table.insert(envenomListTwo,"addiction")
elseif envenomList[1] ~= "stupid" then
  table.insert(envenomListTwo,"stupid")
end

if ataxiaTemp.canJinx == true then
atk = atk.."wield left shield;wield right doll {"..target.."};vodun status;jinx " ..envenomList[1].. " " ..envenomListTwo[1].. " " ..target
end

end













