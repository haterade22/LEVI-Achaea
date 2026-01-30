function leviclumsapo()
--Clumsiness Classes


--Get Targets Anti Active Cure
getLockingAffliction()

--Get Target Lock Status
checkTargetLocks()


--Tree lock because I am too lazy to put into checkTargetLocks function
if checkAffList({"anorexia", "asthma", "slickness", "paralysis"},4) then
	local	treelock = true
  else
  treelock = false
	
	end
  
--Set Table
curses = {}

--Get Anti-Active Cure
tstopcuring = getLockingAffliction(target) or nil
--Anti-Tumble - Confusion might not stop it...
ataxiaTemp.tarTumble = ataxiaTemp.tarTumble or false

--Curses 1
if tAffs.curseward  then
  table.insert(curses,"breach")

elseif truelock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis then
    table.insert(curses,"paralysis") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness then
    table.insert(curses,"weariness")
  --elseif getLockingAffliction(target) == "haemophilia" then
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague then
    table.insert(curses,"plague")
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity then
    table.insert(curses,"stupid")
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness then
    table.insert(curses,"reckless")
  elseif getLockingAffliction(target) == "confusion" and not tAffs.confusion then
    table.insert(curses,"confusion")
  end
elseif hardlock == true and not tAffs.paralysis then
  table.insert(curses,"paralysis")
elseif softlock == true and not tAffs.paralysis then
  table.insert(curses,"paralysis")
elseif softlock == true and tAffs.paralysis and not tAffs.impatience then
  table.insert(curses,"impatience")
elseif tAffs.manaleech and tAffs.asthma and tAffs.impatience and not tAffs.anorexia and not tAffs.slickness then
  table.insert(curses,"anorexia")
elseif not tAffs.paralysis then
  table.insert(curses,"paralysis")
elseif tAffs.paralysis then
  if tAffs.slickness and tAffs.asthma and tAffs.impatience and not tAffs.anorexia then
    table.insert(curses,"anorexia")
  elseif tAffs.slickness and tAffs.asthma and not tAffs.impatience then
    table.insert(curses,"impatience")
  elseif not tAffs.slickness and tAffs.asthma and tAffs.impatience and tAffs.manaleech then
    table.insert(curses,"sicken") 
   elseif not tAffs.slickness and tAffs.asthma and tAffs.manaleech then
    table.insert(curses,"sicken")
   elseif tAffs.asthma and not tAffs.manaleech and tAffs.impatience then
    table.insert(curses,"sicken")
  elseif tAffs.asthma and not tAffs.impatience then
    table.insert(curses,"impatience")
  elseif not tAffs.asthma then
    table.insert(curses,"asthma")
  elseif not tAffs.weariness then
    table.insert(curses,"weariness")
  elseif not tAffs.clumsiness then
    table.insert(curses,"clumsiness")
  end
end

--Curses Two
if truelock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis and curses[1] ~= "paralysis" then
    table.insert(curses,"paralysis") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness and curses[1] ~= "weariness" then
    table.insert(curses,"weariness")
  --elseif getLockingAffliction(target) == "haemophilia" then
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague and curses[1] ~= "plague" then
    table.insert(curses,"plague")
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity and curses[1] ~= "stupid" then
    table.insert(curses,"stupid")
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness and curses[1] ~= "reckless" then
    table.insert(curses,"reckless")
  elseif getLockingAffliction(target) == "confusion" and not tAffs.confusion and curses[1] ~= "confusion" then
    table.insert(curses,"confusion")
  end
elseif hardlock == true and not tAffs.paralysis and curses[1] ~= "paralysis" then
  table.insert(curses,"paralysis")
elseif softlock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis then
    table.insert(curses,"paralysis") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness then
    table.insert(curses,"weariness")
  --elseif getLockingAffliction(target) == "haemophilia" then
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague then
    table.insert(curses,"plague")
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity then
    table.insert(curses,"stupid")
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness then
    table.insert(curses,"reckless")
  elseif getLockingAffliction(target) == "confusion" and not tAffs.confusion then
    table.insert(curses,"confusion")
  end
elseif softlock == true and not tAffs.paralysis and curses[1] ~= "paralysis" then
  table.insert(curses,"paralysis")
elseif softlock == true and tAffs.paralysis and not tAffs.impatience and curses[1] ~= "impatience" then
  table.insert(curses,"impatience")
elseif tAffs.manaleech and tAffs.asthma and tAffs.impatience and not tAffs.anorexia and not tAffs.slickness and curses[1] == "anorexia" then
  table.insert(curses,"sicken")
elseif tAffs.manaleech and tAffs.asthma and tAffs.impatience and not tAffs.anorexia and not tAffs.slickness and curses[1] == "sicken" then
  table.insert(curses,"anorexia")
elseif not tAffs.paralysis and curses[1] ~= "paralysis" then
  table.insert(curses,"paralysis")
elseif tAffs.slickness and tAffs.asthma and tAffs.impatience and not tAffs.anorexia and curses[1] ~= "anorexia" then
    table.insert(curses,"anorexia")
elseif tAffs.slickness and tAffs.asthma and not tAffs.impatience and curses[1] ~= "impatience" then
    table.insert(curses,"impatience")
elseif not tAffs.slickness and tAffs.asthma and tAffs.impatience and tAffs.manaleech and curses[1] ~= "sicken" then
    table.insert(curses,"sicken") 
elseif not tAffs.slickness and tAffs.asthma and tAffs.manaleech and curses[1] ~= "sicken" then
    table.insert(curses,"sicken")
elseif maretick and maretick == true and not tAffs.hellsight and tAffs.hypersomnia and not tAffs.dementia and tAffs.asthma and tAffs.impatience then
   table.insert(curses,"dementia")
elseif tAffs.asthma and not tAffs.manaleech and tAffs.impatience then
    table.insert(curses,"sicken")
elseif tAffs.asthma and not tAffs.impatience and curses[1] ~= "impatience" then
    table.insert(curses,"impatience")
elseif tAffs.impatience and not tAffs.stupidity and curses[1] ~= "stupid" then
  table.insert(curses,"stupid")
elseif tAffs.impatience and not tAffs.asthma and curses[1] ~= "asthma" then
    table.insert(curses,"asthma")
elseif tAffs.clumsiness and not tAffs.impatience and curses[1] ~= "impatience" then
    table.insert(curses,"impatience")
elseif not tAffs.clumsiness and curses[1] ~= "clumsy" then
    table.insert(curses,"clumsy")
elseif not tAffs.impatience and curses[1] ~= "impatience" then
    table.insert(curses,"impatience")
elseif not tAffs.asthma and curses[1] ~= "asthma" then
    table.insert(curses,"asthma")
elseif not tAffs.weariness and curses[1] ~= "weariness" then
    table.insert(curses,"weariness")
end

apostate_lockattack()

end


function leviweariapo()
--Weariness Classes


--Get Targets Anti Active Cure
getLockingAffliction()

--Get Target Lock Status
checkTargetLocks()


--Tree lock because I am too lazy to put into checkTargetLocks function
if checkAffList({"anorexia", "asthma", "slickness", "paralysis"},4) then
	local	treelock = true
  else
  treelock = false
	
	end
  
--Set Table
curses = {}

--Get Anti-Active Cure
tstopcuring = getLockingAffliction(target) or nil
--Anti-Tumble - Confusion might not stop it...
ataxiaTemp.tarTumble = ataxiaTemp.tarTumble or false

--Curses 1
if tAffs.curseward then
  table.insert(curses,"breach")
elseif truelock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis then
    table.insert(curses,"paralysis") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness then
    table.insert(curses,"weariness")
  --elseif getLockingAffliction(target) == "haemophilia" then
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague then
    table.insert(curses,"plague")
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity then
    table.insert(curses,"stupid")
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness then
    table.insert(curses,"reckless")
  elseif getLockingAffliction(target) == "confusion" and not tAffs.confusion then
    table.insert(curses,"confusion")
  end
elseif hardlock == true and not tAffs.paralysis then
  table.insert(curses,"paralysis")
elseif softlock == true and not tAffs.paralysis then
  table.insert(curses,"paralysis")
elseif softlock == true and tAffs.paralysis and not tAffs.impatience then
  table.insert(curses,"impatience")
elseif tAffs.manaleech and tAffs.asthma and tAffs.impatience and not tAffs.anorexia and not tAffs.slickness then
  table.insert(curses,"anorexia")
elseif not tAffs.paralysis then
  table.insert(curses,"paralysis")
elseif tAffs.paralysis then
  if tAffs.slickness and tAffs.asthma and tAffs.impatience and not tAffs.anorexia then
    table.insert(curses,"anorexia")
  elseif tAffs.slickness and tAffs.asthma and not tAffs.impatience then
    table.insert(curses,"impatience")
  elseif not tAffs.slickness and tAffs.asthma and tAffs.impatience and tAffs.manaleech then
    table.insert(curses,"sicken") 
   elseif not tAffs.slickness and tAffs.asthma and tAffs.manaleech then
    table.insert(curses,"sicken")
   elseif tAffs.asthma and not tAffs.manaleech and tAffs.impatience then
    table.insert(curses,"sicken")
  elseif tAffs.asthma and not tAffs.impatience then
    table.insert(curses,"impatience")
  elseif not tAffs.asthma then
    table.insert(curses,"asthma")
  elseif not tAffs.weariness then
    table.insert(curses,"weariness")
  elseif not tAffs.clumsiness then
    table.insert(curses,"clumsiness")
  end
end

--Curses Two
if truelock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis and curses[1] ~= "paralysis" then
    table.insert(curses,"paralysis") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness and curses[1] ~= "weariness" then
    table.insert(curses,"weariness")
  --elseif getLockingAffliction(target) == "haemophilia" then
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague and curses[1] ~= "plague" then
    table.insert(curses,"plague")
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity and curses[1] ~= "stupid" then
    table.insert(curses,"stupid")
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness and curses[1] ~= "reckless" then
    table.insert(curses,"reckless")
  elseif getLockingAffliction(target) == "confusion" and not tAffs.confusion and curses[1] ~= "confusion" then
    table.insert(curses,"confusion")
  end
elseif hardlock == true and not tAffs.paralysis and curses[1] ~= "paralysis" then
  table.insert(curses,"paralysis")
elseif softlock == true and not tAffs.paralysis and curses[1] ~= "paralysis" then
  table.insert(curses,"paralysis")
elseif softlock == true and tAffs.paralysis and not tAffs.impatience and curses[1] ~= "impatience" then
  table.insert(curses,"impatience")
elseif tAffs.manaleech and tAffs.asthma and tAffs.impatience and not tAffs.anorexia and not tAffs.slickness and curses[1] == "anorexia" then
  table.insert(curses,"sicken")
elseif tAffs.manaleech and tAffs.asthma and tAffs.impatience and not tAffs.anorexia and not tAffs.slickness and curses[1] == "sicken" then
  table.insert(curses,"anorexia")
elseif not tAffs.paralysis and curses[1] ~= "paralysis" then
  table.insert(curses,"paralysis")
elseif tAffs.slickness and tAffs.asthma and tAffs.impatience and not tAffs.anorexia and curses[1] ~= "anorexia" then
    table.insert(curses,"anorexia")
elseif tAffs.slickness and tAffs.asthma and not tAffs.impatience and curses[1] ~= "impatience" then
    table.insert(curses,"impatience")
elseif not tAffs.slickness and tAffs.asthma and tAffs.impatience and tAffs.manaleech and curses[1] ~= "sicken" then
    table.insert(curses,"sicken") 
elseif not tAffs.slickness and tAffs.asthma and tAffs.manaleech and curses[1] ~= "sicken" then
    table.insert(curses,"sicken")
elseif maretick and maretick == true and not tAffs.hellsight and tAffs.hypersomnia and not tAffs.dementia and tAffs.asthma and tAffs.impatience then
   table.insert(curses,"dementia")
elseif tAffs.asthma and not tAffs.manaleech and tAffs.impatience then
    table.insert(curses,"sicken")
elseif tAffs.asthma and not tAffs.impatience and curses[1] ~= "impatience" then
    table.insert(curses,"impatience")
elseif tAffs.impatience and not tAffs.stupidity and curses[1] ~= "stupid" then
  table.insert(curses,"stupid")
elseif tAffs.impatience and not tAffs.asthma and curses[1] ~= "asthma" then
    table.insert(curses,"asthma")
elseif tAffs.weariness and not tAffs.impatience and curses[1] ~= "impatience" then
    table.insert(curses,"impatience")
elseif not tAffs.weariness and curses[1] ~= "weariness" then
    table.insert(curses,"weariness")
elseif not tAffs.impatience and curses[1] ~= "impatience" then
    table.insert(curses,"impatience")
elseif not tAffs.asthma and curses[1] ~= "asthma" then
    table.insert(curses,"asthma")
elseif not tAffs.clumsiness and curses[1] ~= "clumsy" then
    table.insert(curses,"clumsy")

end

apostate_lockattack()

end

function levisleepapo()
--Get Targets Anti Active Cure
getLockingAffliction()

--Get Target Lock Status
checkTargetLocks()
--Set Curses Table
curses = {}
--Set if Target is tumbling or not
ataxiaTemp.tarTumble = ataxiaTemp.tarTumble or false

--Tree lock because I am too lazy to put into checkTargetLocks function
if checkAffList({"anorexia", "asthma", "slickness", "paralysis"},4) then
	local	treelock = true
  else
  treelock = false
	
	end
 
--Get Anti-Active Cure
tstopcuring = getLockingAffliction(target) or nil

--Curses 1
if tAffs.curseward then
  table.insert(curses,"breach")
elseif truelock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis then
    table.insert(curses,"paralysis") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness then
    table.insert(curses,"weariness")
  --elseif getLockingAffliction(target) == "haemophilia" then
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague then
    table.insert(curses,"plague")
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity then
    table.insert(curses,"stupid")
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness then
    table.insert(curses,"reckless")
  elseif getLockingAffliction(target) == "confusion" and not tAffs.confusion then
    table.insert(curses,"confusion")
  end
elseif hardlock == true and not tAffs.paralysis then
  table.insert(curses,"paralysis")
elseif softlock == true and not tAffs.paralysis then
  table.insert(curses,"paralysis")
elseif softlock == true and tAffs.paralysis and not tAffs.impatience then
  table.insert(curses,"impatience")
elseif tAffs.manaleech and tAffs.asthma and tAffs.impatience and not tAffs.anorexia and not tAffs.slickness then
  table.insert(curses,"anorexia")
elseif tarInsomnia == false and tAffs.hypersomnia and tAffs.impatience and not tAffs.prone then
  table.insert(curses,"sleep")
elseif not tAffs.paralysis then
  table.insert(curses,"paralysis")
elseif tAffs.paralysis then
  if tAffs.slickness and tAffs.asthma and tAffs.impatience and not tAffs.anorexia then
    table.insert(curses,"anorexia")
  elseif tAffs.slickness and tAffs.asthma and not tAffs.impatience then
    table.insert(curses,"impatience")
  elseif not tAffs.slickness and tAffs.asthma and tAffs.impatience and tAffs.manaleech then
    table.insert(curses,"sicken") 
   elseif not tAffs.slickness and tAffs.asthma and tAffs.manaleech then
    table.insert(curses,"sicken")
   elseif tAffs.asthma and not tAffs.manaleech and tAffs.impatience then
    table.insert(curses,"sicken")
  elseif tAffs.asthma and not tAffs.impatience then
    table.insert(curses,"impatience")
  elseif not tAffs.asthma then
    table.insert(curses,"asthma")
  elseif not tAffs.weariness then
    table.insert(curses,"weariness")
  elseif not tAffs.clumsiness then
    table.insert(curses,"clumsiness")
  end
end

--Curses Two
if truelock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis and curses[1] ~= "paralysis" then
    table.insert(curses,"paralysis") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness and curses[1] ~= "weariness" then
    table.insert(curses,"weariness")
  --elseif getLockingAffliction(target) == "haemophilia" then
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague and curses[1] ~= "plague" then
    table.insert(curses,"plague")
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity and curses[1] ~= "stupid" then
    table.insert(curses,"stupid")
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness and curses[1] ~= "reckless" then
    table.insert(curses,"reckless")
  elseif getLockingAffliction(target) == "confusion" and not tAffs.confusion and curses[1] ~= "confusion" then
    table.insert(curses,"confusion")
  end
elseif hardlock == true and not tAffs.paralysis and curses[1] ~= "paralysis" then
  table.insert(curses,"paralysis")
elseif softlock == true and not tAffs.paralysis and curses[1] ~= "paralysis" then
  table.insert(curses,"paralysis")
elseif softlock == true and tAffs.paralysis and not tAffs.impatience and curses[1] ~= "impatience" then
  table.insert(curses,"impatience")
elseif tAffs.manaleech and tAffs.asthma and tAffs.impatience and not tAffs.anorexia and not tAffs.slickness and curses[1] == "anorexia" then
  table.insert(curses,"sicken")
elseif tAffs.manaleech and tAffs.asthma and tAffs.impatience and not tAffs.anorexia and not tAffs.slickness and curses[1] == "sicken" then
  table.insert(curses,"anorexia")
elseif not tAffs.paralysis and curses[1] ~= "paralysis" then
  table.insert(curses,"paralysis")
elseif tAffs.slickness and tAffs.asthma and tAffs.impatience and not tAffs.anorexia and curses[1] ~= "anorexia" then
    table.insert(curses,"anorexia")
elseif tAffs.slickness and tAffs.asthma and not tAffs.impatience and curses[1] ~= "impatience" then
    table.insert(curses,"impatience")
elseif not tAffs.slickness and tAffs.asthma and tAffs.impatience and tAffs.manaleech and curses[1] ~= "sicken" then
    table.insert(curses,"sicken") 
elseif not tAffs.slickness and tAffs.asthma and tAffs.manaleech and curses[1] ~= "sicken" then
    table.insert(curses,"sicken")
elseif tarInsomnia == false and tAffs.hypersomnia and tAffs.impatience and not tAffs.prone then
  table.insert(curses,"sleep")
elseif tAffs.hypersomnia and tarInsomnia == true and tAffs.impatience then
 table.insert(curses,"sleep")
elseif tAffs.asthma and not tAffs.manaleech and tAffs.impatience then
    table.insert(curses,"sicken")
elseif tAffs.asthma and not tAffs.impatience and curses[1] ~= "impatience" then
    table.insert(curses,"impatience")
elseif tAffs.impatience and not tAffs.asthma and curses[1] ~= "asthma" then
    table.insert(curses,"asthma")
elseif tAffs.weariness and not tAffs.impatience and curses[1] ~= "impatience" then
    table.insert(curses,"impatience")
elseif not tAffs.weariness and curses[1] ~= "weariness" then
    table.insert(curses,"weariness")
elseif not tAffs.impatience and curses[1] ~= "impatience" then
    table.insert(curses,"impatience")
elseif not tAffs.asthma and curses[1] ~= "asthma" then
    table.insert(curses,"asthma")
elseif not tAffs.clumsiness and curses[1] ~= "clumsy" then
    table.insert(curses,"clumsy")

end

apostate_sleepattack()
end

--Corrupt Damage Function
function corruptDmg()

--Get Physical Affs
  local physAffs =
    {
      "clumsiness",
      "paralysis",
      "asthma",
      "sensitivity",
      "nausea",
      "stupidity",
      "impatience",
    
    }
--Get Mentals Affs
  local mentalAffs =
    {
      "vertigo",
      "agoraphobia",
      "dizziness",
      "claustrophobia",
      "paranoia",
      "dementia",
      "masochism",
      "recklessness",
      "epilepsy",
      "confusion",
      "anorexia",
      "addiction",
      "weariness",
      
    }
--Get Smoke Affs
  local smokeAffs = {"manaleech", "healthleech"}
  local phys_count = 0
--Identify how many physical Affs they have
  for _, v in pairs(physAffs) do
    if tAffs[v] then
      phys_count = phys_count + 1
    end
  end
  local phys_damage = phys_count * 7
  local mental_count = 0
--Identify how many mental Affs they have
  for _, v in pairs(mentalAffs) do
    if tAffs[v] then
      mental_count = mental_count + 1
    end
  end
  local mental_damage = mental_count * 8
  local smoke_count = 0
--Identify how many smoke Affs they have
  for _, v in pairs(smokeAffs) do
    if tAffs[v] then
      smoke_count = smoke_count + 1
    end
  end
  local smoke_damage = smoke_count * 9
  return smoke_damage + phys_damage + mental_damage
end

--Corruption Kill Logic
function corruptKill()
local atk = combatQueue()
  if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= corruptDmg() then
atk = atk.."stand;wield shield;assess "..target..";demon corrupt "..target
  end
end
 
function cathCorrupt()
local atk = combatQueue()
  if pm - corruptDmg() <= 20 and not tAffs.anorexia and not tAffs.slickness then
atk = atk.."stand;wield shield;assess "..target..";demon corrupt "..target
  end
end



function bloodPact()
  if not apo.pentagram() then
    if bloodTimer then
      if not dsum then
        addToCommand("summon daegger")
      end
      addToCommand(
        "wield daegger shield;demon bloodpact &tar for " ..
        pentagramEnt ..
        "/order loyals kill &tar"
      )
    end
  elseif apo.demon() ~= pentagramEnt then
    if not dsum then
      addToCommand("summon daegger")
    end
    addToCommand("wield daegger shield;dispel pentagram;summon " .. pentagramEnt)
  end
end

--
function bloodworm()
  if not zgui.roomDenizenList then
    return false
  end
  if table.contains(zgui.roomDenizenList, "a frenzied bloodworm") then
      return true
    else

  return false
end
end


function baalzadeen()

  if not zgui.roomDenizenList then
    return false
  end
  if table.contains(zgui.roomDenizenList, "a Baalzadeen") then
      return true
    else

  return false
end
end

--

function apopentagram()
   if not zgui.roomItemList then
    return false
  end

     if table.contains(zgui.roomItemList,"a floating silver pentagram") then
      return true
  
  else
  return false
end
end

function demon()
  if not zgui.roomDenizenList then
    return false
  end

    if table.contains(zgui.roomDenizenList,"a small winged daemonite") then
      return "daemonite"
    elseif table.contains(zgui.roomDenizenList,"a fiendish nightmare") then
      return "nightmare"
    elseif table.contains(zgui.roomDenizenList,"a razor fiend") then
      return "fiend"
    else 

  return ""
end
end

function daemonite()
  if not zgui.roomDenizenList then
    return false
  end
  for id, item in pairs(zgui.roomItemList) do
    if item.name:match("a small winged daemonite") then
      return true
    end
  end
  return false
end

function nightmare()
  if not zgui.roomItemList then
    return false
  end
  for id, item in pairs(roomItems) do
    if item.name:match("zgui.roomItemList") then
      return true
    end
  end
  return false
end

function fiend()
  if not zgui.roomItemList then
    return false
  end
  for id, item in pairs(zgui.roomItemList) do
    if item.name:match("a razor fiend") then
      return true
    end
  end
  return false
end




---------------



function corruptDmg2()
  local physAffs =
    {
      "xentio",
      "paralyse",
      "kalmia",
      "sensitivity",
      "euphorbia",
      "stupidity",
      "impatience",
    }
  local mentalAffs =
    {
      "vertigo",
      "agoraphobia",
      "dizzy",
      "claustrophobia",
      "paranoia",
      "dementia",
      "masochism",
      "eurypteria",
      "epilepsy",
      "confuse",
      "slike",
      "vardrax", --??
      "vernalius", --??
    }
  local smokeAffs = {"manaleech", "healthleech"}
  local phys_count = 0
  for _, v in pairs(physAffs) do
    if tarAff[v] then
      phys_count = phys_count + 1
    end
  end
  local phys_damage = phys_count * 7
  local mental_count = 0
  for _, v in pairs(mentalAffs) do
    if tarAff[v] then
      mental_count = mental_count + 1
    end
  end
  local mental_damage = mental_count * 8
  local smoke_count = 0
  for _, v in pairs(smokeAffs) do
    if tarAff[v] then
      smoke_count = smoke_count + 1
    end
  end
  local smoke_damage = smoke_count * 9
  return smoke_damage + phys_damage + mental_damage
end
 
function corruptKill2()
  if targetHealth <= corruptDmg() then
    addToCommand("demon corrupt &tar/assess &tar")
  end
end
 
function cathCorrupt2()
  if targetMana - corruptDmg() <= 25 and not tarAff["slike"] and not tarAff["gecko"] then
    addToCommand("demon corrupt &tar/assess &tar")
  end
end



function nightmare()

if gmcp.Char.Status.class == "Apostate" and demon() == "nightmare" then

maretick = tempTimer(6.5, [[maretick = false; maretick = true]])
nightmareaff = tempTimer(8.5, [[nightmareaff = false; nightmareaff = true]])

if nightmareaff and tAffs.dementia and tAffs.hypersomnia then 

tarAffed("hellsight")

elseif

nightmareaff and tAffs.hypersomnia and not tAffs.dementia then

 tarAffed("dementia")

end
end





end




