--[[mudlet
type: script
name: LeviDWCDisembowel
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- RuneWarden
- DWC RUNIE
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function levidwcheadprep()
weapon1 = "scimitar405398"
weapon2 = "scimitar405403"
local atk = combatQueue()
need_raze = need_raze or false
empowerrunesset = "kena mannaz sleizak"

ataxiaTemp.parriedLimb = ataxiaTemp.parriedLimb or "none"

--Set Damage per DSL and Regular
scimdamage = ataxiaTables.limbData.dwcSlash + ataxiaTables.limbData.dwcSlash

-- For Raze Slash Situations
scim1damage = ataxiaTables.limbData.dwcSlash

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
  



--Get Anti-Active Cure
tstopcuring = getLockingAffliction(target) or nil
--Anti-Tumble - Confusion might not stop it...
ataxiaTemp.tarTumble = ataxiaTemp.tarTumble or false

--VENOMS
--Set Table
  venoms = {}
  
--Venoms 1
if truelock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis then
    table.insert(venoms,"curare") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness then
    table.insert(venoms,"vernalius") 
  --elseif getLockingAffliction(target) == "haemophilia" then
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague then
    table.insert(venoms,"voyria") 
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity then
    table.insert(venoms,"aconite")  
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness then
   table.insert(venoms,"eurypteria") 
  end
elseif hardlock == true and not tAffs.paralysis then
  table.insert(venoms,"curare") 
elseif softlock == true and not tAffs.paralysis then
  table.insert(venoms,"curare") 
elseif tAffs.asthma and tAffs.impatience and not tAffs.anorexia and tAffs.slickness then
  table.insert(venoms,"slike")
elseif tAffs.asthma and tAffs.impatience and tAffs.anorexia and not tAffs.slickness then
  table.insert(venoms,"gecko")
elseif tAffs.asthma and tAffs.impatience and not tAffs.anorexia and not tAffs.slickness then
  table.insert(venoms,"slike")
elseif not tAffs.paralysis then
   table.insert(venoms,"curare")

elseif tAffs.paralysis then
  if tAffs.slickness and tAffs.asthma and tAffs.impatience and not tAffs.anorexia then
    table.insert(venoms,"slike") 
  elseif not tAffs.slickness and tAffs.asthma and tAffs.impatience then
    table.insert(venoms,"gecko") 
   elseif not tAffs.slickness and tAffs.asthma then
    table.insert(venoms,"gecko")
  elseif not tAffs.nausea then
    table.insert(venoms,"vernalius")
  elseif not tAffs.clumsiness then
    table.insert(venoms,"xentio")
  elseif not tAffs.asthma then
    table.insert(venoms,"kalmia")
  elseif not tAffs.weariness then
    table.insert(venoms,"vernalius")
  
  end
end


--Venoms Two
if truelock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis and venoms[1] ~= "curare" then
    table.insert(venoms,"curare") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness and venoms[1] ~= "vernalius" then
    table.insert(venoms,"vernalius")
  --elseif getLockingAffliction(target) == "haemophilia" then
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague and venoms[1] ~= "voyria" then
    table.insert(venoms,"voyria")
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity and venoms[1] ~= "aconite" then
    table.insert(venoms,"aconite")
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness and venoms[1] ~= "eurypteria" then
    table.insert(venoms,"eurypteria")
  end
elseif hardlock == true and not tAffs.paralysis and venoms[1] ~= "curare" then
  table.insert(venoms,"curare")
elseif softlock == true and not tAffs.paralysis and venoms[1] ~= "curare" then
  table.insert(venoms,"curare")
elseif tAffs.asthma and tAffs.impatience and not tAffs.anorexia and not tAffs.slickness and venoms[1] == "slike" then
  table.insert(venoms,"gecko")
elseif tAffs.asthma and tAffs.impatience and not tAffs.anorexia and not tAffs.slickness and venoms[1] == "gecko" then
  table.insert(venoms,"slike")
elseif not tAffs.paralysis and venoms[1] ~= "curare" then
  table.insert(venoms,"curare")
elseif not tAffs.nausea and venoms[1] ~= "vernalius" then
  table.insert(venoms,"vernalius")
elseif tAffs.slickness and tAffs.asthma and tAffs.impatience and not tAffs.anorexia and venoms[1] ~= "slike" then
    table.insert(venoms,"slike")
elseif not tAffs.slickness and tAffs.asthma and tAffs.impatience and venoms[1] ~= "gecko" then
    table.insert(venoms,"gecko") 
elseif not tAffs.slickness and tAffs.asthma and venoms[1] ~= "gecko" then
    table.insert(venoms,"gecko")
elseif tAffs.clumsiness and not tAffs.asthma and venoms[1] ~= "kalmia" then
    table.insert(venoms,"kalmia")
elseif not tAffs.clumsiness and venoms[1] ~= "xentio" then
    table.insert(venoms,"xentio")
elseif not tAffs.weariness and venoms[1] ~= "vernalius" then
    table.insert(venoms,"vernalius")
elseif not tAffs.addiction and venoms[1] ~= "vardrax" then
    table.insert(venoms,"vardrax")
elseif not tAffs.darkshade and venoms[1] ~= "darkshade" then
    table.insert(venoms,"darkshade")
elseif not tAffs.stupidity and venoms[1] ~= "aconite" then
    table.insert(venoms,"aconite")
else
  table.insert(venoms,"prefarar")
end  
  

-- Limb Prep Calc


if lb[target].hits["right leg"] + scimdamage >= 100 and not tAffs.damagedrightleg then
prepped_rightleg = true else
prepped_rightleg = false
end

if lb[target].hits["right leg"] + scim1damage >= 100 and not tAffs.damagedrightleg and tAffs.shield or tAffs.rebounding then
prepped2_rightleg = true else
prepped2_rightleg = false
end

if lb[target].hits["left leg"] + scimdamage >= 100 and not tAffs.damagedleftleg then
prepped_leftleg = true else
prepped_leftleg = false
end

if lb[target].hits["left leg"] + scim1damage >= 100 and not tAffs.damagedleftleg and tAffs.shield or tAffs.rebounding then
prepped2_leftleg = true else
prepped2_leftleg = false
end

if lb[target].hits["left arm"] + scimdamage >= 100 and not tAffs.damagedleftarm then
prepped_leftleg = true else
prepped_leftleg = false
end

if lb[target].hits["left arm"] + scim1damage >= 100 and not tAffs.damagedleftarm and tAffs.shield or tAffs.rebounding then
prepped2_leftarm = true else
prepped2_leftarm = false
end

if lb[target].hits["right arm"] + scimdamage >= 100 and not tAffs.damagedrightarm then
prepped_rightarm = true else
prepped_rightarm = false
end

if lb[target].hits["right arm"] + scim1damage >= 100 and not tAffs.damagedrightarm and tAffs.shield or tAffs.rebounding then
prepped2_rightarm = true else
prepped2_rightarm = false
end

if lb[target].hits["torso"] + scimdamage >= 100 and not tAffs.mildtrauma then
prepped_torso = true else
prepped_torso = false
end

if lb[target].hits["torso"] + scim1damage >= 100 and not tAffs.mildtrauma and tAffs.shield or tAffs.rebounding then
prepped2_torso = true else
prepped2_torso = false
end

if lb[target].hits["head"] + scimdamage >= 100 and not tAffs.damagedhead then
prepped_head = true else
prepped_head = false
end

if lb[target].hits["head"] + scim1damage >= 100 and not tAffs.damagedhead and tAffs.shield or tAffs.rebounding then
prepped2_head = true else
prepped2_head = false
end


  
  
--ATTACK

-- Bisect
if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 35 then
use_bisect = true else
use_bisect = false
end

--Disembowel
if tAffs.impaled then
disembowel = true
else
disembowel = false
end

--Logic for limb target
if not prepped_torso then targetlimb = "torso"
elseif not prepped_rightleg then targetlimb = "right leg"
elseif not prepped_leftleg then targetlimb = "left leg"
end

--Bisect
if use_bisect and not tAffs.shield then

atk = atk.."wield bastard;assess "..target..";bisect "..target.." curare"

-- Disembowel
elseif disembowel then 

atk = atk..";disembowel "..target

-- Raze
elseif tAffs.rebounding and not tAffs.shield then
    if tAffs.nausea then
      if prepped_torso then
        atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";empower priority set " ..empowerrunesset.. ";razeslash "..target.." torso "..venoms[1].. ";assess "..target.. ";contemplate " ..target
      elseif prepped_leftleg then
        atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";empower priority set " ..empowerrunesset.. ";razeslash "..target.." left leg "..venoms[1].. ";assess "..target.. ";contemplate " ..target
      elseif prepped_rightleg then
        atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";empower priority set " ..empowerrunesset.. ";razeslash "..target.." right leg "..venoms[1].. ";assess "..target.. ";contemplate " ..target
      else
        atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";empower priority set " ..empowerrunesset.. ";razeslash "..target.. " "..venoms[1].. ";assess "..target.. ";contemplate " ..target
      end
    else 
      atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";empower priority set " ..empowerrunesset.. ";razeslash "..target.. " " ..venoms[1].. ";assess "..target.. ";contemplate " ..target
    end
    
elseif not tAffs.rebounding and tAffs.shield then
    if tAffs.nausea then
      if prepped_torso then
        atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";empower priority set " ..empowerrunesset.. ";razeslash "..target.." torso "..venoms[1].. ";assess "..target.. ";contemplate " ..target
      elseif prepped_leftleg then
        atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";empower priority set " ..empowerrunesset.. ";razeslash "..target.." left leg "..venoms[1].. ";assess "..target.. ";contemplate " ..target
      elseif prepped_rightleg then
        atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";empower priority set " ..empowerrunesset.. ";razeslash "..target.." right leg "..venoms[1].. ";assess "..target.. ";contemplate " ..target
      else
        atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";empower priority set " ..empowerrunesset.. ";razeslash "..target.. " "..venoms[1].. ";assess "..target.. ";contemplate " ..target
      end
    else 
        atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";empower priority set " ..empowerrunesset.. ";razeslash "..target.. " " ..venoms[1].. ";assess "..target.. ";contemplate " ..target
    end

elseif tAffs.shield and tAffs.rebounding then
  atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";empower priority set " ..empowerrunesset.. ";raze "..target.. ";assess "..target.. ";contemplate " ..target
   
-- Impale
elseif tAffs.prone and tAffs.damagedleftleg and tAffs.damagedrightleg then
  atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";fury on;impale "..target

--Double Break
elseif tAffs.damagedrightleg and prepped_leftleg and tAffs.mildtrauma or lb[target].hits["torso"] >= 100 and tAffs.prone then
  atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.. " left leg "..venoms[2].." "..venoms[1].. ";assess "..target.. ";contemplate " ..target
elseif tAffs.nausea then
  if prepped_rightleg and prepped_leftleg and tAffs.mildtrauma or lb[target].hits["torso"] >= 100 and not tAffs.prone then
  atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.. " right leg delphinium delphinium;assess "..target.. ";contemplate " ..target
  elseif prepped_rightleg and prepped_leftleg and prepped_torso and not tAffs.mildtrauma then
  atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.. " torso "..venoms[2].." "..venoms[1].. ";assess "..target.. ";contemplate " ..target
  --Prep
 elseif prepped_rightleg and prepped_torso and not prepped_leftleg and not prepped2_leftleg then
  atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.. " left leg "..venoms[2].." "..venoms[1].. ";assess "..target.. ";contemplate " ..target
 elseif prepped_leftleg and prepped_torso and not prepped_rightleg and not prepped2_rightleg then
  atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.. " right leg "..venoms[2].." "..venoms[1].. ";assess "..target.. ";contemplate " ..target
 elseif not prepped_torso then
  atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.. " torso "..venoms[2].." "..venoms[1].. ";assess "..target.. ";contemplate " ..target
 elseif not prepped_rightleg then
  atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.. " right leg "..venoms[2].." "..venoms[1].. ";assess "..target.. ";contemplate " ..target
 elseif not prepped_leftleg then
  atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.. " left leg "..venoms[2].." "..venoms[1].. ";assess "..target.. ";contemplate " ..target

 end
else 
  atk = atk.."wield "..weapon1.." "..weapon2..";wipe "..weapon1..";wipe "..weapon2..";assess "..target..";dsl "..target.. " "..venoms[2].." "..venoms[1].. ";assess "..target.. ";contemplate " ..target


end
--Attack
if table.contains(ataxia.playersHere, target) then
if falconattack == true then
  if not engaged then
    send("queue addclear freestand " ..atk.. ";engage " ..target)
  else
    send("queue addclear freestand " ..atk)
  end
elseif falconattack == false then
 if not engaged then
    send("queue addclear freestand " ..atk.. ";falcon slay " ..target.." ;engage " ..target)
  else
    send("queue addclear freestand " ..atk.. ";falcon slay " ..target)
  end
end
else
  expandAlias("nt")
  send("queue addclear freestand " ..atk)

end

--Function End
end



