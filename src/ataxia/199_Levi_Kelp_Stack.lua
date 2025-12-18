-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > Serpent > Levi Kelp Stack

serpentsuggest = false
incommingsnakeprone = false
snapscenarioone = false
snapscenariotwo = false
function serp_quicklock()
-- Set Varables

snapscenarioone = true
snapscenariotwo = false
tAffs.hypnotising = tAffs.hypnotising or false
tAffs.hypnotised = tAffs.hypnotised or false
tAffs.hypnoseal = tAffs.hypnoseal or false
ataxiaTemp.hypnoseal = ataxiaTemp.hypnoseal or false
tAffs.snapped = tAffs.snapped or false



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
envenomList = {}

if truelock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis then
    table.insert(envenomList,"paralyse") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness then
    table.insert(envenomList,"weariness") 
  --elseif getLockingAffliction(target) == "haemophilia" then
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
  table.insert(envenomList,"curare")
elseif softlock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis then
    table.insert(envenomList,"curare") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness then
    table.insert(envenomList,"vernalius") 
  --elseif getLockingAffliction(target) == "haemophilia" then
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
elseif tAffs.snapped == true and not tAffs.anorexia then
  table.insert(envenomList,"slike")
elseif tAffs.snapped == true and not tAffs.slickness then
  table.insert(envenomList,"gecko")
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
elseif incommingsnakeprone == true and not tAffs.slickness then 
  table.insert(envenomList,"gecko")
elseif not tAffs.slickness and tAffs.asthma then
  table.insert(envenomList,"gecko")
elseif tAffs.prone and not tAffs.slickness then
  table.insert(envenomList,"gecko")
elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness then
  table.insert(envenomList,"vernalius")
elseif not tAffs.clumsiness and getLockingAffliction(target) ~= "weariness" then
  table.insert(envenomList,"xentio")
elseif not tAffs.asthma then
  table.insert(envenomList,"kalmia")
elseif not tAffs.weariness then
  table.insert(envenomList,"vernalius")
elseif not tAffs.darkshade then
  table.insert(envenomList,"darkshade")
elseif not tAffs.nausea then
  table.insert(envenomList,"euphorbia")
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
  --elseif getLockingAffliction(target) == "haemophilia" then
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague and envenomList[1] ~= "voyria" then
    table.insert(envenomListTwo,"voyria") 
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity and envenomList[1] ~= "aconite" then
    table.insert(envenomListTwo,"aconite")  
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness and envenomList[1] ~= "eurypteria" then
   table.insert(envenomListTwo,"eurypteria") 
  end
elseif hardlock == true and not tAffs.paralysis and envenomList[1] ~= "curare" then
  table.insert(envenomListTwo,"curare") 
elseif softlock == true and not tAffs.paralysis and envenomList[1] ~= "curare" then
  table.insert(envenomListTwo,"curare")
elseif tAffs.snapped == true and not tAffs.anorexia and envenomList[1] ~= "slike" then
  table.insert(envenomListTwo,"slike")
elseif tAffs.snapped == true and not tAffs.slickness and envenomList[1] ~= "gecko" then
  table.insert(envenomListTwo,"gecko")
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
elseif incommingsnakeprone == true and not tAffs.slickness and envenomList[1] ~= "gecko" then 
  table.insert(envenomListTwo,"gecko")
elseif not tAffs.slickness and tAffs.asthma and envenomList[1] ~= "gecko" then
  table.insert(envenomListTwo,"gecko")
elseif tAffs.prone and not tAffs.slickness and envenomList[1] ~= "gecko" then
  table.insert(envenomListTwo,"gecko")
elseif not tAffs.paralysis and envenomList[1] ~= "curare" then
  table.insert(envenomListTwo,"curare")
elseif not tAffs.clumsiness and envenomList[1] ~= "xentio" then
  table.insert(envenomListTwo,"xentio")
elseif not tAffs.asthma and envenomList[1] ~= "kalmia" then
  table.insert(envenomListTwo,"kalmia")
elseif not tAffs.weariness and envenomList[1] ~= "vernalius" then
  table.insert(envenomListTwo,"vernalius")
elseif not tAffs.darkshade and envenomList[1] ~= "darkshade" then
  table.insert(envenomListTwo,"darkshade")
elseif not tAffs.nausea and envenomList[1] ~= "euphorbia" then
  table.insert(envenomListTwo,"euphorbia")
elseif not tAffs.addiction and envenomList[1] ~= "vardrax" then
  table.insert(envenomListTwo,"vardrax")
elseif envenomList[1] ~= "aconite" then
  table.insert(envenomListTwo,"aconite")
end




serp_lockattack()

end

function serp_quicklocksnakeprone()
-- Set Varables

tAffs.hypnotising = tAffs.hypnotising or false
tAffs.hypnotised = tAffs.hypnotised or false
tAffs.hypnoseal = tAffs.hypnoseal or false
ataxiaTemp.hypnoseal = ataxiaTemp.hypnoseal or false
tAffs.snapped = tAffs.snapped or false
snapscenarioone = false
snapscenariotwo = true


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
envenomList = {}

if truelock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis then
    table.insert(envenomList,"curare") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness then
    table.insert(envenomList,"vernalius") 
  --elseif getLockingAffliction(target) == "haemophilia" then
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
elseif softlock == true and not tAffs.paralysis then
  table.insert(envenomList,"curare") 
elseif tAffs.snapped == true and not tAffs.anorexia then
  table.insert(envenomList,"slike")
elseif tAffs.snapped == true and not tAffs.slickness then
  table.insert(envenomList,"gecko")
elseif incommingsnakeprone == true and not tAffs.slickness then
  table.insert(envenomList,"gecko")
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
elseif not tAffs.slickness and tAffs.asthma then
  table.insert(envenomList,"gecko")
elseif tAffs.prone and not tAffs.slickness then
  table.insert(envenomList,"gecko")
elseif not tAffs.clumsiness then
  table.insert(envenomList,"xentio")
elseif not tAffs.asthma then
  table.insert(envenomList,"kalmia")
elseif not tAffs.weariness then
  table.insert(envenomList,"vernalius")
elseif not tAffs.darkshade then
  table.insert(envenomList,"darkshade")
elseif not tAffs.nausea then
  table.insert(envenomList,"euphorbia")
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
  --elseif getLockingAffliction(target) == "haemophilia" then
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague and envenomList[1] ~= "voyria" then
    table.insert(envenomListTwo,"voyria") 
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity and envenomList[1] ~= "aconite" then
    table.insert(envenomListTwo,"aconite")  
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness and envenomList[1] ~= "eurypteria" then
   table.insert(envenomListTwo,"eurypteria") 
  end
elseif hardlock == true and not tAffs.paralysis and envenomList[1] ~= "curare" then
  table.insert(envenomListTwo,"curare") 
elseif softlock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis and envenomList[1] ~= "curare" then
    table.insert(envenomListTwo,"curare") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness and envenomList[1] ~= "vernalius" then
    table.insert(envenomListTwo,"vernalius") 
  --elseif getLockingAffliction(target) == "haemophilia" then
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague and envenomList[1] ~= "voyria" then
    table.insert(envenomListTwo,"voyria") 
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity and envenomList[1] ~= "aconite" then
    table.insert(envenomListTwo,"aconite")  
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness and envenomList[1] ~= "eurypteria" then
   table.insert(envenomListTwo,"eurypteria") 
  end
  
elseif softlock == true and not tAffs.paralysis and envenomList[1] ~= "curare" then
  table.insert(envenomListTwo,"curare")
elseif tAffs.snapped == true and not tAffs.anorexia and envenomList[1] ~= "slike" then
  table.insert(envenomListTwo,"slike")
elseif tAffs.snapped == true and not tAffs.slickness and envenomList[1] ~= "gecko" then
  table.insert(envenomListTwo,"gecko")
elseif incommingsnakeprone == true and not tAffs.slickness and envenomList[1] ~= "gecko" then
  table.insert(envenomList,"gecko")
elseif incommingsnakeprone == true and not tAffs.paralysis and envenomList[1] ~= "curare" then
  table.insert(envenomList,"curare")
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
elseif not tAffs.clumsiness and envenomList[1] ~= "xentio" then
  table.insert(envenomListTwo,"xentio")
elseif not tAffs.asthma and envenomList[1] ~= "kalmia" then
  table.insert(envenomListTwo,"kalmia")
elseif not tAffs.weariness and envenomList[1] ~= "vernalius" then
  table.insert(envenomListTwo,"vernalius")
elseif not tAffs.darkshade and envenomList[1] ~= "darkshade" then
  table.insert(envenomListTwo,"darkshade")
elseif not tAffs.nausea and envenomList[1] ~= "euphorbia" then
  table.insert(envenomListTwo,"euphorbia")
elseif not tAffs.addiction and envenomList[1] ~= "vardrax" then
  table.insert(envenomListTwo,"vardrax")
elseif envenomList[1] ~= "aconite" then
  table.insert(envenomListTwo,"aconite")
end





serp_lockattack2()
end

function serp_grouplock()
-- Set Varables

tAffs.hypnotising = tAffs.hypnotising or false
tAffs.hypnotised = tAffs.hypnotised or false
tAffs.hypnoseal = tAffs.hypnoseal or false
ataxiaTemp.hypnoseal = ataxiaTemp.hypnoseal or false
tAffs.snapped = tAffs.snapped or false
snapscenarioone = false
snapscenariotwo = true


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
envenomList = {}

if truelock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis then
    table.insert(envenomList,"curare") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness then
    table.insert(envenomList,"vernalius") 
  --elseif getLockingAffliction(target) == "haemophilia" then
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
elseif not tAffs.slickness and tAffs.asthma then
  table.insert(envenomList,"gecko")
elseif tAffs.prone and not tAffs.slickness then
  table.insert(envenomList,"gecko")
elseif not tAffs.asthma then
  table.insert(envenomList,"kalmia")
elseif not tAffs.darkshade then
  table.insert(envenomList,"darkshade")
elseif not tAffs.weariness then
  table.insert(envenomList,"vernalius")
elseif not tAffs.clumsiness then
  table.insert(envenomList,"xentio")
elseif not tAffs.nausea then
  table.insert(envenomList,"euphorbia")
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
  --elseif getLockingAffliction(target) == "haemophilia" then
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague and envenomList[1] ~= "voyria" then
    table.insert(envenomListTwo,"voyria") 
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity and envenomList[1] ~= "aconite" then
    table.insert(envenomListTwo,"aconite")  
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness and envenomList[1] ~= "eurypteria" then
   table.insert(envenomListTwo,"eurypteria") 
  end
elseif hardlock == true and not tAffs.paralysis and envenomList[1] ~= "curare" then
  table.insert(envenomListTwo,"curare") 
elseif softlock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis and envenomList[1] ~= "curare" then
    table.insert(envenomListTwo,"curare") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness and envenomList[1] ~= "vernalius" then
    table.insert(envenomListTwo,"vernalius") 
  --elseif getLockingAffliction(target) == "haemophilia" then
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague and envenomList[1] ~= "voyria" then
    table.insert(envenomListTwo,"voyria") 
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity and envenomList[1] ~= "aconite" then
    table.insert(envenomListTwo,"aconite")  
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness and envenomList[1] ~= "eurypteria" then
   table.insert(envenomListTwo,"eurypteria") 
  end
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
elseif not tAffs.asthma and envenomList[1] ~= "kalmia" then
  table.insert(envenomListTwo,"kalmia")
elseif not tAffs.weariness and envenomList[1] ~= "vernalius" then
  table.insert(envenomListTwo,"vernalius")
elseif not tAffs.darkshade and envenomList[1] ~= "darkshade" then
  table.insert(envenomListTwo,"darkshade")
elseif not tAffs.clumsiness and envenomList[1] ~= "xentio" then
  table.insert(envenomListTwo,"xentio")
elseif not tAffs.nausea and envenomList[1] ~= "euphorbia" then
  table.insert(envenomListTwo,"euphorbia")
elseif not tAffs.addiction and envenomList[1] ~= "vardrax" then
  table.insert(envenomListTwo,"vardrax")
elseif envenomList[1] ~= "aconite" then
  table.insert(envenomListTwo,"aconite")
end





serp_groupattack()
end












function serp_lockattack()
if not php then php = 100 end
if not pm then pm = 100 end
partyrelay = partyrelay or true



--Set Attacks
local atk = combatQueue()

if tAffs.hypnotised == true and serpentsuggest == true and tAffs.hypnoseal == false then
  atk = atk.. "wield left dirk;wield right shield;purge;order adder kill " ..target..";seal " ..target.. " 1;"
elseif tAffs.rebounding and tAffs.shield then
  atk = atk.. " wield left dirk;wield right lash;purge;order adder kill " ..target..";flay " ..target.. " shield " ..envenomListTwo[1]
elseif tAffs.rebounding then
  atk = atk.. " wield left dirk;wield right lash;purge;order adder kill " ..target..";flay " ..target.. " rebounding " ..envenomListTwo[1]
elseif tAffs.shield then 
  table.insert(envenomListTwo,"curare")
  atk = atk.. "wield left dirk;wield right lash;purge;order adder kill " ..target..";flay " ..target.. " shield " ..envenomListTwo[1]
elseif tAffs.snapped == true then
 atk = atk.. " wield left dirk;wield right shield;purge;order adder kill " ..target..";doublestab " ..target.. " " ..envenomList[1].. " " ..envenomListTwo[1]
elseif tAffs.hypnoseal == true then
  atk = atk.. "wield left dirk;wield right shield;purge;order adder kill " ..target..";doublestab " ..target.. " " ..envenomList[1].. " " ..envenomListTwo[1]
elseif tAffs.hypnotised == true and serpentsuggest == false then
  atk = atk.. "wield left dirk;wield right shield;purge;order adder kill " ..target..";suggest " ..target.. " impatience"
elseif tAffs.hypnotising == true then
  atk = atk.. "wield left dirk;wield right shield;purge;order adder kill " ..target..";doublestab " ..target.. " " ..envenomList[1].. " " ..envenomListTwo[1]
elseif tAffs.hypnotised == false and tAffs.hypnotising == false and tAffs.hypnoseal == false then
  atk = atk.. "wield left dirk;wield right shield;purge;order adder kill " ..target..";hypnotise " ..target.. ";doublestab " ..target.. " " ..envenomList[1].. " " ..envenomListTwo[1]
else
  atk = atk.. " wield left dirk;wield right shield;purge;order adder kill " ..target..";doublestab " ..target.. " " ..envenomList[1].. " " ..envenomListTwo[1]

end


if table.contains(ataxia.playersHere, target) then
send("queue addclear freestand " ..atk)
end

end



function serp_lockattack2()
if not php then php = 100 end
if not pm then pm = 100 end
partyrelay = partyrelay or true

local atk = combatQueue()

if tAffs.hypnotised == true and serpentsuggest == true and tAffs.hypnoseal == false then
  atk = atk.. "wield left dirk;wield right shield;purge;order adder kill " ..target..";seal " ..target.. " 1;"
elseif tAffs.rebounding and tAffs.shield then
   table.insert(envenomListTwo,"curare")
  atk = atk.. " wield left dirk;wield right lash;purge;order adder kill " ..target..";flay " ..target.. " shield " ..envenomListTwo[1]
elseif tAffs.rebounding then
  table.insert(envenomListTwo,"curare")
  atk = atk.. " wield left dirk;wield right lash;purge;order adder kill " ..target..";flay " ..target.. " rebounding " ..envenomListTwo[1]
elseif tAffs.shield then 
   table.insert(envenomListTwo,"curare")
  atk = atk.. "wield left dirk;wield right lash;purge;order adder kill " ..target..";flay " ..target.. " shield " ..envenomListTwo[1]
elseif tAffs.snapped == true then
 atk = atk.. " wield left dirk;wield right shield;purge;order adder kill " ..target..";doublestab " ..target.. " " ..envenomList[1].. " " ..envenomListTwo[1]
elseif incommingsnakeprone == true and not tAffs.slickness and not tAffs.paralysis then
 table.insert(envenomList,"slike")
 table.insert(envenomListTwo,"curare")
  atk = atk.. "wield left dirk;wield right shield;purge;order adder kill " ..target..";doublestab " ..target.. " " ..envenomList[1].. " " ..envenomListTwo[1]
elseif tpinshot == false and tlightwall == false then
  atk = atk.. " remove bow;wield bow;purge;order adder kill " ..target..";pinshot " ..target.. ";conjure lightwall " ..random_direction
elseif tpinshot == false and tlightwall == true then
  atk = atk.. " remove bow;wield bow;purge;order adder kill " ..target..";pinshot " ..target
elseif tAffs.hypnoseal == true then
  atk = atk.. "wield left dirk;wield right shield;purge;order adder kill " ..target..";doublestab " ..target.. " " ..envenomList[1].. " " ..envenomListTwo[1]
elseif tAffs.hypnotised == true and serpentsuggest == false then
  atk = atk.. "wield left dirk;wield right shield;purge;order adder kill " ..target..";suggest " ..target.. " hypochondria;suggest " ..target.. " impatience"
elseif tAffs.hypnotising == true then
  atk = atk.. "wield left dirk;wield right shield;purge;order adder kill " ..target..";doublestab " ..target.. " " ..envenomList[1].. " " ..envenomListTwo[1]
elseif tAffs.hypnotised == false and tAffs.hypnotising == false and tAffs.hypnoseal == false then
  atk = atk.. "wield left dirk;wield right shield;purge;order adder kill " ..target..";hypnotise " ..target.. ";doublestab " ..target.. " " ..envenomList[1].. " " ..envenomListTwo[1]
else
  atk = atk.. " wield left dirk;wield right shield;purge;order adder kill " ..target..";doublestab " ..target.. " " ..envenomList[1].. " " ..envenomListTwo[1]

end

if table.contains(ataxia.playersHere, target) then
send("queue addclear freestand " ..atk)
end

end


function serp_groupattack()
if not php then php = 100 end
if not pm then pm = 100 end
partyrelay = partyrelay or true



--Set Attacks
local atk = combatQueue()

if tAffs.rebounding and tAffs.shield then
  atk = atk.. " wield left dirk;wield right lash;purge;order adder kill " ..target..";flay " ..target.. " shield " ..envenomListTwo[1]
elseif tAffs.rebounding then
  atk = atk.. " wield left dirk;wield right lash;purge;order adder kill " ..target..";flay " ..target.. " rebounding " ..envenomListTwo[1]
elseif tAffs.shield then 
  table.insert(envenomListTwo,"curare")
  atk = atk.. "wield left dirk;wield right lash;purge;order adder kill " ..target..";flay " ..target.. " shield " ..envenomListTwo[1]
else
  atk = atk.. " wield left dirk;wield right shield;purge;order adder kill " ..target..";doublestab " ..target.. " " ..envenomList[1].. " " ..envenomListTwo[1]
end


if table.contains(ataxia.playersHere, target) then
send("queue addclear freestand " ..atk)
end

end

