function depthswalker_damageroute()
--Pick an Attune
tattune = tattune or ""
--Are they Attuned?
ttattune = ttattune or false
-- Pick a scythe Instill
tinstall = tinstill or "degeneration"
Target_Instill = tinstill or "degeneration" --For affliction tracking

-- For timeloop tracking and calling
tloop = tloop or false
tloop2 = tloop2 or false
--Cull logic isn't met
tcull = tcull or false
--Did we distort yet?
depdistort = depdistort or false
--Do I have their shadow?
haveshadow = haveshadow or false
--Envenom List
envenomList = {}

-- Attack
local atk = combatQueue()
--Set Health and Mana, based on Assess
if not php then php = 100 end
if not pm then pm = 100 end
partyrelay = partyrelay or true

--get Age
dep_age = tonumber(string.sub(gmcp.Char.Vitals.charstats[4], 6))
--Is the target locked?
checkTargetLocks()

--Set Dictate Requirements
if pm <= 40 then 
need_dictate = true else
need_dictate = false
end
  --Set all Dictate requirements based on afflictions
if checkAffList({"depression", "retribution", "parasite", "madness"},1) and pm <= 45 then
	need_dictate1 = true
else
  need_dictate1 = false
end
if checkAffList({"depression", "retribution", "parasite", "madness"},2) and pm <= 50 then
	need_dictate2 = true
else
  need_dictate2 = false
end
if checkAffList({"depression", "retribution", "parasite", "madness"},3) and pm <= 55 then
	need_dictate3 = true
else
  need_dictate3 = false
end
if checkAffList({"depression", "retribution", "parasite", "madness"},4) and pm <= 60 then
	need_dictate4 = true
else
  need_dictate4 = false
end

-- If their mana is below dictate threshold then dictate 
if need_dictate == true or need_dictate1 == true or need_dictate2 == true or need_dictate3 == true or need_dictate4 == true then 
  tloop = false
  tloop2 = false
  atk = atk.." shadow dictate "..target

-- If their health is below 35 percent, then cull with TOOROS for damage
elseif php <= 35 then
  tloop = false
  tloop2 = false
  table.insert(envenomList,"curare")
  atk = atk.." shadow attune " ..target.. " to " ..tattune.. " ;intone tooros;chrono assert;shadow cull " ..target.." curare;assess " ..target..";contemplate " ..target

-- We have shadow Lets go Damage
elseif haveshadow == true then
  -- if we have shadow and health less than or at 60
  if php <= 50 and haveshadow == true then
    tloop = false
    tloop2 = false
    table.insert(envenomList,"curare")
    atk = atk.."wield right dagger;shadow mutilate " ..target.. " curare;assess " ..target.. " ;contemplate " ..target
  --If they have clumsiness and weariness and age is below or at 250 than chrono boost for damage
  elseif tAffs.clumsiness and tAffs.weariness and not tAffs.paralysis and dep_age <= 250 then
    tloop2 = true
    tloop = false
     table.insert(envenomList,"timeloop")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with degeneration;chrono assert;chrono loop boost;shadow reap "..target.. ";assess "..target.." ;contemplate "..target
  -- If the above but age over 250 curare for damage
  elseif tAffs.clumsiness and tAffs.weariness and not tAffs.paralysis and dep_age > 250 then
    tloop = false
    tloop2 = false
    tattune = "degeneration"
    table.insert(envenomList,"curare")
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with degeneration;chrono assert;shadow reap "..target.. " curare;assess "..target.." ;contemplate "..target
  -- If not timeloop then timeloop if they have justice or retribution
  elseif not tAffs.timeloop and tAffs.clumsiness or tAffs.weariness and tAffs.justice or tAffs.retribution then
    tloop = true
    table.insert(envenomList,"timeloop")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with degeneration;chrono assert;chrono loop;shadow reap "..target.. " curare;assess "..target.." ;contemplate "..target
  -- If not timeloop and not retribution then get to retribution to stack Bellwort
  elseif not tAffs.timeloop and tAffs.clumsiness or tAffs.weariness and not tAffs.retribution then
    tloop = false
    tloop2 = false
    tattune = "degeneration"
    table.insert(envenomList,"curare")
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with retribution;chrono assert;shadow reap "..target.. " curare;assess "..target.." ;contemplate "..target
  
  -- If not weariness then stick weariness
  elseif not tAffs.weariness and not tAffs.paralysis then
    tloop = false
    tloop2 = false
    table.insert(envenomList,"curare")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with degeneration;chrono assert;shadow reap "..target.. " curare;assess "..target.." ;contemplate "..target
  -- if not clumsiness then stick clumsiness
  elseif not tAffs.clumsiness and not tAffs.paralysis then
    tloop = false
    tloop2 = false
    table.insert(envenomList,"curare")
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with degeneration;chrono assert;shadow reap "..target.. " curare;assess "..target.." ;contemplate "..target
  
  end


--Let's Get Shadow
elseif haveshadow == false then
  -- If we are two away from Shadow, Chrono Loop Boost
  if tAffs.parasite and tAffs.healthleech and not tAffs.manaleech and dep_age <= 250 then
    tloop2 = true
    tloop = false
    table.insert(envenomList,"timeloop")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with leach;chrono assert;chrono loop boost;shadow reap "..target.. ";assess "..target.." ;contemplate "..target
  -- If we dont have enough Age but have asthma and not manaleech
  elseif tAffs.parasite and tAffs.healthleech and not tAffs.manaleech and dep_age > 250 and tAffs.asthma and not tAffs.paralysis then
    tloop = false
    tloop2 = false
    tattune = "degeneration"
    table.insert(envenomList,"curare")
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with leach;chrono assert;shadow reap "..target.. " curare;assess "..target.." ;contemplate "..target
    -- If we dont have enough age and not asthma then
  elseif tAffs.parasite and tAffs.healthleech and not tAffs.manaleech and dep_age > 250 and not tAffs.asthma then
    tloop = false
    tloop2 = false
    table.insert(envenomList,"kalmia")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with leach;chrono assert;shadow reap "..target.. " kalmia;assess "..target.." ;contemplate "..target
    -- If they have parasite but not heathleech and not paralysis
  elseif tAffs.parasite and not tAffs.healthleech and not tAffs.paralysis then
    tloop = false
    tloop2 = false
    tattune = "degeneration"
    table.insert(envenomList,"curare")
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with leach;chrono assert;shadow reap "..target.. " curare;assess "..target.." ;contemplate "..target
    -- If they have weariness and not parasite then
  elseif tAffs.weariness and not tAffs.parasite and not tAffs.paralysis then
    tloop = false
    tloop2 = false
    tattune = "degeneration"
    table.insert(envenomList,"curare")
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with leach;chrono assert;shadow reap "..target.. " curare;assess "..target.." ;contemplate "..target
    -- If they dont have weariness then get to weariness
  elseif not tAffs.weariness and not tAffs.paralysis then
    tloop = false
    tloop2 = false
    tattune = "degeneration"
    table.insert(envenomList,"curare")
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with degeneration;chrono assert;shadow reap "..target.. " curare;assess "..target.." ;contemplate "..target
  else
    tloop = false
    tloop2 = false
    table.insert(envenomList,"kalmia")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with depression;chrono assert;shadow reap "..target.. " curare;assess "..target.." ;contemplate "..target
  end
    

  
  
end



----ATTTTTACKKKKKK
--If the target is here and Shield then raze
if table.contains(ataxia.playersHere, target) and tAffs.shield then
send("wield left scythe20431;wield right dagger;wipe scythe20431;queue addclear free shadow strike "..target..";assess "..target..";contemplate " ..target)
--if the target is here and not shielded then attack
elseif table.contains(ataxia.playersHere, target) then
send("wield left scythe20431;wield right shield;wipe scythe20431;queue addclear free "..atk)
--this is in case the above function is broken
else
expandAlias("nt")
send("wield left scythe20431;wield right shield;wipe scythe20431;queue addclear free "..atk)


  end
end


---------------------------LOCK-------------------------------------------------

function depthswalker_lockroute()
--Pick an Attune
tattune = tattune or ""
--Are they Attuned?
ttattune = false
-- Pick a scythe Instill
tinstall = tinstill or "degeneration"
Target_Instill = tinstill or "degeneration" --For affliction tracking

-- For timeloop tracking and calling
tloop = tloop or false
tloop2 = tloop2 or false
--Cull logic isn't met
tcull = false
--Did we distort yet?
depdistort = depdistort or false
--Do I have their shadow?
haveshadow = haveshadow or false
--Envenom List
envenomList = {}

-- Attack
local atk = combatQueue()
--Set Health and Mana, based on Assess
if not php then php = 100 end
if not pm then pm = 100 end
partyrelay = partyrelay or true

--get Age
dep_age = tonumber(string.sub(gmcp.Char.Vitals.charstats[4], 6))
--Is the target locked?
checkTargetLocks()

--Set Dictate Requirements
if pm <= 40 then 
need_dictate = true else
need_dictate = false
end
  --Set all Dictate requirements based on afflictions
if checkAffList({"depression", "retribution", "parasite", "madness"},1) and pm <= 45 then
	need_dictate1 = true
else
  need_dictate1 = false
end
if checkAffList({"depression", "retribution", "parasite", "madness"},2) and pm <= 50 then
	need_dictate2 = true
else
  need_dictate2 = false
end
if checkAffList({"depression", "retribution", "parasite", "madness"},3) and pm <= 55 then
	need_dictate3 = true
else
  need_dictate3 = false
end
if checkAffList({"depression", "retribution", "parasite", "madness"},4) and pm <= 60 then
	need_dictate4 = true
else
  need_dictate4 = false
end

--Need to Know What Stops Curing
tstopcuring = getLockingAffliction(target) or nil








-- If their mana is below dictate threshold then dictate 
if need_dictate == true or need_dictate1 == true or need_dictate2 == true or need_dictate3 == true or need_dictate4 == true then 
  tloop = false
  tloop2 = false
  atk = atk.." shadow dictate "..target

-- If their health is below 35 percent, then cull with TOOROS for damage
elseif php <= 30 then
  tloop = false
  tloop2 = false
  table.insert(envenomList,"curare")
  atk = atk.." shadow attune " ..target.. " to " ..tattune.. " ;intone tooros;chrono assert;shadow cull " ..target.." curare;assess " ..target..";contemplate " ..target

--Stop Passives 
elseif tstopcuring ~= nil and truelock == true then
  if tstopcuring == "reckless" and not tAffs.recklessness then
    tloop = false
    tloop2 = false
    table.insert(envenomList,"eurypteria")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with madness;chrono assert;shadow reap "..target.. " eurypteria;assess "..target.." ;contemplate "..target
  elseif tstopcuring == "weariness" and not tAffs.weariness then
    tloop = false
    tloop2 = false
    table.insert(envenomList,"xentio")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with degeneration;chrono assert;shadow reap "..target.. " xentio;assess "..target.." ;contemplate "..target
  elseif tstopcuring == "plague" and not tAffs.voyria then
    tloop = false
    tloop2 = false
    table.insert(envenomList,"voyria")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with depression;chrono assert;shadow reap "..target.. " voyria;assess "..target.." ;contemplate "..target
  elseif tstopcuring == "stupid" and not tAffs.stupidity then
    tloop = false
    tloop2 = false
    table.insert(envenomList,"aconite")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with madness;chrono assert;shadow reap "..target.. " aconite;assess "..target.." ;contemplate "..target
  end

-- Last Stage Lock
elseif tAffs.impatience and tAffs.asthma and tAffs.hypochondria and tAffs.nausea and tAffs.depression and tAffs.slickness and tAffs.anorexia and not tAffs.paralysis then
    tloop = false
    tloop2 = false
    table.insert(envenomList,"curare")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with degeneration;chrono assert;shadow reap "..target.. " curare;assess "..target.." ;contemplate "..target
 
elseif tAffs.impatience and tAffs.asthma and tAffs.nausea and tAffs.depression and tAffs.slickness then
    tloop = false
    tloop2 = false
    table.insert(envenomList,"kalmia")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with depression;chrono assert;shadow reap "..target.. " kalmia;assess "..target.." ;contemplate "..target


-- First Stage Lock
elseif tAffs.impatience and tAffs.asthma and tAffs.nausea and tAffs.depression then
    tloop = false
    tloop2 = false
    table.insert(envenomList,"gecko")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with depression;chrono assert;shadow reap "..target.. " gecko;assess "..target.." ;contemplate "..target

--If they have impatience lets rock depression until lock
elseif tAffs.impatience and tAffs.asthma then
    tloop = false
    tloop2 = false
    table.insert(envenomList,"gecko")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with depression;chrono assert;shadow reap "..target.. " gecko;assess "..target.." ;contemplate "..target

elseif tAffs.impatience and not tAffs.asthma then
    tloop = false
    tloop2 = false
    table.insert(envenomList,"kalmia")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with depression;chrono assert;shadow reap "..target.. " kalmia;assess "..target.." ;contemplate "..target

elseif tAffs.impatience then
    tloop = false
    tloop2 = false
    table.insert(envenomList,"gecko")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with depression;chrono assert;shadow reap "..target.. " gecko;assess "..target.." ;contemplate "..target

-- if they have hypochondria lets madness until impatience tick!
elseif tAffs.hypochondria and not tAffs.madness and not tAffs.asthma and tAffs.depression then
    tloop = false
    tloop2 = false
    table.insert(envenomList,"kalmia")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with madness;chrono assert;shadow reap "..target.. " kalmia;assess "..target.." ;contemplate "..target

elseif tAffs.hypochondria and not tAffs.stupidity or tAffs.madness and tAffs.depression then
    tloop = false
    tloop2 = false
    table.insert(envenomList,"aconite")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with madness;chrono assert;shadow reap "..target.. " aconite;assess "..target.." ;contemplate "..target
  
-- progress towards impatience 
elseif not tAffs.hypochondria and not tAffs.asthma and tAffs.timeloop and tAffs.depression then
    tloop = false
    tloop2 = false
    table.insert(envenomList,"kalmia")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with depression;chrono assert;shadow reap "..target.. " kalmia;assess "..target.." ;contemplate "..target

elseif not tAffs.hypochondria and tAffs.asthma and tAffs.timeloop and tAffs.depression and not tAffs.nausea then
    tloop = false
    tloop2 = false
    table.insert(envenomList,"euphorbia")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with depression;chrono assert;shadow reap "..target.. " euphorbia;assess "..target.." ;contemplate "..target



--if depression and not timeloop then go up depression tree with timeloop
elseif tAffs.depression and not tAffs.timeloop and tAffs.nausea then
    tloop = true
    tloop2 = false
    table.insert(envenomList,"timeloop")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with depression;chrono loop;shadow reap "..target.. ";assess "..target.." ;contemplate "..target

elseif not tAffs.depression and tAffs.timeloop and tAffs.clumsines and tAffs.justice or tAffs.retribution and not tAffs.nausea then
    tloop = false
    tloop2 = false
    table.insert(envenomList,"euphorbia")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with depression;chrono assert;shadow reap "..target.. " euphorbia;assess "..target.." ;contemplate "..target

 
--if they have clumsiness but not timeloop and not depression hit them with it
elseif tAffs.clumsiness and not tAffs.timeloop and not tAffs.depression and tAffs.justice or tAffs.retribution then
    tloop = true
    tloop2 = false
    table.insert(envenomList,"timeloop")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with depression;chrono loop;shadow reap "..target.. ";assess "..target.." ;contemplate "..target
 

--if they have clumsiness then go depression 
elseif tAffs.clumsiness and not tAffs.depression and tAffs.justice or tAffs.retribution and not tAffs.asthma then
    tloop = false
    tloop2 = false
    table.insert(envenomList,"kalmia")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with depression;chrono assert;shadow reap "..target.. " kalmia;assess "..target.." ;contemplate "..target
 

--Try sticking clumsiness if they have retribution or timeloop
elseif tAffs.justice and tAffs.retribution or tAffs.timeloop and not tAffs.clumsiness then
    tloop = false
    tloop2 = false
    table.insert(envenomList,"curare")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with degeneration;chrono assert;shadow reap "..target.. " curare;assess "..target.." ;contemplate "..target
  --Try to Stick Timeloop with Retribution
elseif tAffs.justice and not tAffs.retribution and not tAffs.timeloop then
    tloop = true
    tloop2 = false
    table.insert(envenomList,"timeloop")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with retribution;chrono loop;shadow reap "..target.. " ;assess "..target.." ;contemplate "..target
  -- If not justice then stick justice
elseif not tAffs.justice and not tAffs.paralysis and tAffs.clumsiness then
    tloop = false
    tloop2 = false
    table.insert(envenomList,"curare")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with retribution;chrono assert;shadow reap "..target.. " curare;assess "..target.." ;contemplate "..target
else
    tloop = false
    tloop2 = false
    table.insert(envenomList,"curare")
    tattune = "degeneration"
    atk = atk.."shadow attune " ..target.. " to " ..tattune.. " ;shadow instill scythe with degeneration;chrono assert;shadow reap "..target.. " curare;assess "..target.." ;contemplate "..target
end




  




----ATTTTTACKKKKKK
--If the target is here and Shield then raze
if table.contains(ataxia.playersHere, target) and tAffs.shield then
send("wield left scythe20431;wield right dagger;wipe scythe20431;queue addclear free shadow strike "..target..";assess "..target..";contemplate " ..target)
--if the target is here and not shielded then attack
elseif table.contains(ataxia.playersHere, target) then
send("wield left scythe20431;wield right shield;wipe scythe20431;queue addclear free "..atk)
--this is in case the above function is broken
else
expandAlias("nt")
send("wield left scythe20431;wield right shield;wipe scythe20431;queue addclear free "..atk)


  end
end



