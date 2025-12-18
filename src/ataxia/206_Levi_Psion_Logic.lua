-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > Psion > Levi Psion Logic

function levipsionmind()
local atk = combatQueue()
local sp = ataxia.settings.separator
php = php or 100
pm = pm or 100
tAffs.criticalspirit = tAffs.criticalspirit or false
tAffs.criticalmind = tAffs.criticalmind or false
tAffs.criticalbody = tAffs.criticalbody or false
pdeconstruct = pdeconstruct or false
psionweaves = ataxiaTables.limbData.psionweaves
psionweaves2 = ataxiaTables.limbData.psionweaves + ataxiaTables.limbData.psionweaves
lightbind = lightbind or false

--Get Targets Anti Active Cure
getLockingAffliction()

--Get Target Lock Status
checkTargetLocks()

--Check for Psi Blast Criteria
if checkAffList({"impatience", "stupidity", "blackout", "dizziness", "epilepsy", "unweavingmind" },3) then
  tpsiblast = true
else
  tpsiblast = false
end

-- Set Invert
mindinvert = mindinvert or false
bodyinvert = bodyinvert or false
spiritinvert = spiritinvert or false
inverted = inverted or false


--Deconstruct
if tAffs.criticalspirit == true and tAffs.criticalbody == true and tAffs.criticalmind == true then
pdeconstruct = true
elseif tAffs.criticalbody == true and tAffs.criticalmind == true then
pdeconstruct = true
elseif tAffs.criticalbody == true and tAffs.criticalspirit == true then
pdeconstruct = true
elseif tAffs.criticalspirit == true and tAffs.criticalmind == true then
pdeconstruct = true
end




--Prep Limb

if lb[target].hits["head"] + psionweaves2 >= 100 then
  pprepped2_head = true
else
  pprepped2_head = false
end

if lb[target].hits["head"] + psionweaves >= 100 then
  pprepped_head = true
else 
  pprepped_head = false
end
if lb[target].hits["left arm"] + psionweaves >= 100 then
  pprepped_leftarm = true
else 
  pprepped_leftarm = false
end
if lb[target].hits["right arm"] + psionweaves >= 100 then
  pprepped_rightarm = true
else 
  pprepped_rightarm = false
end
if lb[target].hits["right leg"] + psionweaves >= 100 then
  pprepped_rightleg = true
else 
  pprepped_rightleg = false
end
if lb[target].hits["left leg"] + psionweaves >= 100 then
  pprepped_leftleg = true
else 
  pprepped_leftleg = false
end

--Table for Prepare
psionprepare = {}
if tAffs.mindravaged and not tAffs.haemophilia then
  table.insert(psionprepare,"laceration")
elseif not tAffs.paralysis then
  table.insert(psionprepare,"disruption")
elseif not tAffs.haemophilia then
  table.insert(psionprepare,"laceration")
elseif not tAffs.asthma then
  table.insert(psionprepare,"vapours")
else
  table.insert(psionprepare,"rattle")
end


--Table for Weave
--overhand - if prone then impatient . if head broken impatience, if not prone, stupidity, 
--Backhand -- stupdity/dizziness - if prone , knock focus balance
--puncture -- weariness - arm
--sever - clumsiness - arm
--deathblow - asthma - head - prone - bleeding
--hamstring - legs - prone if broken legs


psionweave = {}
if not tAffs.mindravaged then --1
  if pdeconstruct == true then --2
     table.insert(psionweave,"deconstruct")
  elseif tAffs.damagedhead and not tAffs.impatience then
    table.insert(psionweave,"overhand")
  elseif pprepped_head == true and not tAffs.damagedhead and not tAffs.impatience then
    table.insert(psionweave,"overhand")
  elseif pprepped_head == true and not tAffs.damagedhead and tAffs.impatience and not tAffs.stupidity or not tAffs.dizziness then
    table.insert(psionweave,"backhand")
  elseif pprepped_head == true and not tAffs.damagedhead and tAffs.impatience and tAffs.stupidity and tAffs.dizziness and not tAffs.asthma and psionprepare[1] ~= "vapours"  then
    table.insert(psionweave,"deathblow")
  elseif pprepped2_head == true and not tAffs.asthma then
    table.insert(psionweave,"deathblow")
  elseif not tAffs.impatience and tAffs.prone then
    table.insert(psionweave,"overhand")
  elseif tAffs.impatience and tAffs.prone and not tAffs.stupidity or not tAffs.dizziness then
    table.insert(psionweave,"backhand")
  elseif tAffs.impatience and not tAffs.stupidity or not tAffs.dizziness then
    table.insert(psionweave,"backhand")
  elseif tAffs.unweavingmind and tAffs.unweavingbody and not tAffs.unweavingspirit and tAffs.asthma then
    table.insert(psionweave,"unweave spirit")
  elseif tAffs.unweavingmind and tAffs.unweavingbody then
    if ataxiaNDB_getClass(target) == "Priest" or ataxiaNDB_getClass(target) == "Occultist" or ataxiaNDB_getClass(target) == "Pariah" then --3
      if not tAffs.weariness then --4
        table.insert(psionweave,"puncture")
      elseif not tAffs.clumsiness then
        table.insert(psionweave,"sever")
      elseif not tAffs.asthma and psionprepare[1] ~= "vapours" then
        table.insert(psionweave,"deathblow")
      end -- End 4
    elseif ataxiaNDB_getClass(target) ~= "Priest" or ataxiaNDB_getClass(target) ~= "Occultist" or ataxiaNDB_getClass(target) ~= "Pariah" then--3
      if not tAffs.clumsiness then --5
        table.insert(psionweave,"sever")
      elseif not tAffs.weariness then
        table.insert(psionweave,"puncture")
      elseif not tAffs.asthma and psionprepare[1] ~= "vapours" then
        table.insert(psionweave,"deathblow")
      end -- End 5
    end -- End 3
  elseif not tAffs.unweavingbody then
    table.insert(psionweave,"unweave body")
  elseif not tAffs.unweavingmind then
    table.insert(psionweave,"unweave mind")
  else
    table.insert(psionweave,"unweave mind")
  end -- End 2
elseif tAffs.mindravaged then
   if pdeconstruct == true then -- 6
     table.insert(psionweave,"deconstruct")
  elseif tAffs.damagedhead and not tAffs.impatience then
    table.insert(psionweave,"overhand")
  elseif pprepped_head == true and not tAffs.damagedhead and not tAffs.impatience then
    table.insert(psionweave,"overhand")
  elseif pprepped_head == true and not tAffs.damagedhead and tAffs.impatience and not tAffs.stupidity or not tAffs.dizziness then
    table.insert(psionweave,"backhand")
  elseif pprepped_head == true and not tAffs.damagedhead and tAffs.impatience and tAffs.stupidity and tAffs.dizziness and not tAffs.asthma and psionprepare[1] ~= "vapours"  then
    table.insert(psionweave,"deathblow")
  elseif not tAffs.impatience and tAffs.prone then
    table.insert(psionweave,"overhand")
  elseif tAffs.impatience and tAffs.prone and not tAffs.stupidity or not tAffs.dizziness then
    table.insert(psionweave,"backhand")
 
  elseif tAffs.unweavingmind and tAffs.unweavingbody then
    if ataxiaNDB_getClass(target) == "Priest" or ataxiaNDB_getClass(target) == "Occultist" or ataxiaNDB_getClass(target) == "Pariah" then --7
      if not tAffs.weariness then --8
        table.insert(psionweave,"puncture")
      elseif not tAffs.clumsiness then
        table.insert(psionweave,"sever")
      elseif not tAffs.asthma and psionprepare[1] ~= "vapours" then
        table.insert(psionweave,"deathblow")
      end -- End 8
    elseif ataxiaNDB_getClass(target) ~= "Priest" or ataxiaNDB_getClass(target) ~= "Occultist" or ataxiaNDB_getClass(target) ~= "Pariah" then
      if not tAffs.clumsiness then -- 9
        table.insert(psionweave,"sever")
      elseif not tAffs.weariness then
        table.insert(psionweave,"puncture")
      elseif not tAffs.asthma and psionprepare[1] ~= "vapours" then
        table.insert(psionweave,"deathblow")
      end -- End 9
    end -- End 7
  elseif tAffs.unweavingmind and not tAffs.unweavingbody then
    table.insert(psionweave,"unweave body")
  elseif not tAffs.unweavingmind then
    table.insert(psionweave,"unweave mind")
  else
    table.insert(psionweave,"unweave mind")
  end -- End 6
end -- End 0

--Table Transcend
psiontranscend = {}
if pm <= 30 then
  table.insert(psiontranscend,"excise")
elseif tpsiblast == true and not tAffs.mindravaged then
  table.insert(psiontranscend,"blast")
elseif not tAffs.muddled then
  table.insert(psiontranscend,"muddle")
else
  table.insert(psiontranscend,"shatter")
end

---ATTACK LOGIC---
if tAffs.shield then
  atk = atk.."psi transcend " ..psiontranscend[1].. " " ..target.. ";weave prepare " ..psionprepare[1]..";weave cleave " ..target
elseif pm <= 30  then 
  atk = atk.."psi transcend " ..psiontranscend[1].. " " ..target.. ";psi excise " ..target
elseif psionweave[1] == "unweave mind" then
  atk = atk.."psi transcend " ..psiontranscend[1].. " " ..target.. ";weave prepare " ..psionprepare[1]..";weave unweave " ..target.. " mind"
elseif psionweave[1] == "unweave body" then
  atk = atk.."psi transcend " ..psiontranscend[1].. " " ..target.. ";weave prepare " ..psionprepare[1]..";weave unweave " ..target.. " body"
elseif psionweave[1] == "unweave spirit" then
  atk = atk.."psi transcend " ..psiontranscend[1].. " " ..target.. ";weave prepare " ..psionprepare[1]..";weave unweave " ..target.. " spirit"
else
 atk = atk.."psi transcend " ..psiontranscend[1].. " " ..target.. ";weave prepare " ..psionprepare[1]..";weave " ..psionweave[1].. " " ..target
end

-- ATTACK--
if lightbind == true then
send("queue addclearfull freestand wield right shield; " ..atk..";assess " ..target..";contemplate " ..target)
elseif lightbind == false then
send("queue addclearfull freestand wield right shield; " ..atk.." ;enact lightbind " ..target.. ";assess " ..target..";contemplate " ..target)
end
--LOS Destruction

--enact wrath - eq speed up and rupture - below half health


--enact rupture - 4 attacks bleeding


--enact wavesurge

-- PSI TRANSCEND



--End Function
end 


function levipsionflurry()
local atk = combatQueue()
local sp = ataxia.settings.separator
php = php or 100
pm = pm or 100
tAffs.criticalspirit = tAffs.criticalspirit or false
tAffs.criticalmind = tAffs.criticalmind or false
tAffs.criticalbody = tAffs.criticalbody or false
pdeconstruct = pdeconstruct or false
psionweaves = ataxiaTables.limbData.psionweaves

--Get Targets Anti Active Cure
getLockingAffliction()

--Get Target Lock Status
checkTargetLocks()


-- Set Invert
mindinvert = mindinvert or false
bodyinvert = bodyinvert or false
spiritinvert = spiritinvert or false
inverted = inverted or false


--Check for Psi Blast Criteria
if checkAffList({"impatience", "stupidity", "blackout", "dizziness", "epilepsy", "unweavingmind" },3) then
  tpsiblast = true
else
  tpsiblast = false
end

--Deconstruct
if tAffs.criticalspirit == true and tAffs.criticalbody == true and tAffs.criticalmind == true then
pdeconstruct = true
elseif tAffs.criticalbody == true and tAffs.criticalmind == true then
pdeconstruct = true
elseif tAffs.criticalbody == true and tAffs.criticalspirit == true then
pdeconstruct = true
elseif tAffs.criticalspirit == true and tAffs.criticalmind == true then
pdeconstruct = true
end




--Prep Limb

if lb[target].hits["head"] + psionweaves >= 100 then
  pprepped_head = true
else 
  pprepped_head = false
end
if lb[target].hits["left arm"] + psionweaves >= 100 then
  pprepped_leftarm = true
else 
  pprepped_leftarm = false
end
if lb[target].hits["right arm"] + psionweaves >= 100 then
  pprepped_rightarm = true
else 
  pprepped_rightarm = false
end
if lb[target].hits["right leg"] + psionweaves >= 100 then
  pprepped_rightleg = true
else 
  pprepped_rightleg = false
end
if lb[target].hits["left leg"] + psionweaves >= 100 then
  pprepped_leftleg = true
else 
  pprepped_leftleg = false
end

--Table for Prepare
psionprepare = {}
if tAffs.mindravaged and not tAffs.haemophilia then
  table.insert(psionprepare,"laceration")
elseif tAffs.impatience and not tAffs.epilepsy then
  table.insert(psionprepare,"rattle")
elseif not tAffs.paralysis then
  table.insert(psionprepare,"disruption")
elseif not tAffs.haemophilia then
  table.insert(psionprepare,"laceration")
elseif not tAffs.asthma then
  table.insert(psionprepare,"vapours")
else
  table.insert(psionprepare,"rattle")
end


--Table for Weave
--overhand - if prone then impatient . if head broken impatience, if not prone, stupidity, 
--Backhand -- stupdity/dizziness - if prone , knock focus balance
--puncture -- weariness - arm
--sever - clumsiness - arm
--deathblow - asthma - head - prone - bleeding
--hamstring - legs - prone if broken legs


psionweave = {}
if not tAffs.mindravaged then --1
  if pdeconstruct == true then --2
     table.insert(psionweave,"deconstruct")
  elseif inverted == true then
    table.insert(psionweave,"flurry")
  elseif tAffs.damagedhead and not tAffs.impatience then
    table.insert(psionweave,"overhand")
  elseif pprepped_head == true and not tAffs.damagedhead and not tAffs.impatience then
    table.insert(psionweave,"overhand")
  elseif pprepped_head == true and not tAffs.damagedhead and tAffs.impatience and tAffs.stupidity and tAffs.dizziness and not tAffs.asthma and psionprepare[1] ~= "vapours"  then
    table.insert(psionweave,"deathblow")
  elseif not tAffs.impatience and tAffs.prone then
    table.insert(psionweave,"overhand")
  elseif tAffs.unweavingmind and tAffs.unweavingbody then
    if ataxiaNDB_getClass(target) == "Priest" or ataxiaNDB_getClass(target) == "Occultist" or ataxiaNDB_getClass(target) == "Pariah" then --3
      if not tAffs.weariness then --4
        table.insert(psionweave,"puncture")
      elseif not tAffs.clumsiness then
        table.insert(psionweave,"sever")
      elseif not tAffs.asthma and psionprepare[1] ~= "vapours" then
        table.insert(psionweave,"deathblow")
      end -- End 4
    elseif ataxiaNDB_getClass(target) ~= "Priest" or ataxiaNDB_getClass(target) ~= "Occultist" or ataxiaNDB_getClass(target) ~= "Pariah" then--3
      if not tAffs.clumsiness then --5
        table.insert(psionweave,"sever")
      elseif not tAffs.asthma and psionprepare[1] ~= "vapours" then
        table.insert(psionweave,"deathblow")
      elseif not tAffs.weariness then
        table.insert(psionweave,"puncture")
      end -- End 5
    end -- End 3
  elseif tAffs.unweavingmind and not tAffs.unweavingbody then
    table.insert(psionweave,"unweave body")
  elseif not tAffs.unweavingmind then
    table.insert(psionweave,"unweave mind")
  else
    table.insert(psionweave,"unweave mind")
  end -- End 2
elseif tAffs.mindravaged then
   if pdeconstruct == true then -- 6
     table.insert(psionweave,"deconstruct")
  elseif inverted == true then
    table.insert(psionweave,"flurry")
  elseif tAffs.damagedhead and not tAffs.impatience then
    table.insert(psionweave,"overhand")
  elseif pprepped_head == true and not tAffs.damagedhead and not tAffs.impatience then
    table.insert(psionweave,"overhand")
  elseif pprepped_head == true and not tAffs.damagedhead and tAffs.impatience and tAffs.stupidity and tAffs.dizziness and not tAffs.asthma and psionprepare[1] ~= "vapours"  then
    table.insert(psionweave,"deathblow")
  elseif not tAffs.impatience and tAffs.prone then
    table.insert(psionweave,"overhand")
elseif tAffs.unweavingbody then
    if ataxiaNDB_getClass(target) == "Priest" or ataxiaNDB_getClass(target) == "Occultist" or ataxiaNDB_getClass(target) == "Pariah" then --7
      if not tAffs.weariness then --8
        table.insert(psionweave,"puncture")
      elseif not tAffs.clumsiness then
        table.insert(psionweave,"sever")
      elseif not tAffs.asthma and psionprepare[1] ~= "vapours" then
        table.insert(psionweave,"deathblow")
      end -- End 8
    elseif ataxiaNDB_getClass(target) ~= "Priest" or ataxiaNDB_getClass(target) ~= "Occultist" or ataxiaNDB_getClass(target) ~= "Pariah" then
      if not tAffs.clumsiness then -- 9
        table.insert(psionweave,"sever")
      elseif not tAffs.asthma and psionprepare[1] ~= "vapours" then
        table.insert(psionweave,"deathblow")
      elseif not tAffs.weariness then
        table.insert(psionweave,"puncture")
      end -- End 9
    end -- End 7
  elseif tAffs.unweavingmind and not tAffs.unweavingbody then
    table.insert(psionweave,"unweave body")
  elseif not tAffs.unweavingmind then
    table.insert(psionweave,"unweave mind")

  end -- End 6
end -- End 0

--Table Transcend
psiontranscend = {}
if pm <= 30 then
  table.insert(psiontranscend,"excise")
elseif tpsiblast == true and not tAffs.mindravaged then
  table.insert(psiontranscend,"blast")
elseif not tAffs.muddled then
  table.insert(psiontranscend,"muddle")
else
  table.insert(psiontranscend,"shatter")
end

---ATTACK LOGIC---
if tAffs.shield then
  atk = atk.."psi transcend " ..psiontranscend[1].. " " ..target.. ";weave prepare " ..psionprepare[1]..";weave cleave " ..target
elseif pm <= 30  then 
  atk = atk.." psi excise " ..target
elseif inverted == true and tAffs.unweavingspirit or tAffs.criticalspirit then
  atk = atk.."psi transcend shatter " ..target.. ";weave prepare " ..psionprepare[1]..";weave flurry " ..target
elseif tAffs.criticalmind and not tAffs.criticalspirit and inverted == false then
  atk = atk.."weave prepare " ..psionprepare[1]..";weave invert " ..target.. " mind spirit"
elseif tAffs.criticalbody and not tAffs.criticalspirit and inverted == false then
  atk = atk.."weave prepare " ..psionprepare[1]..";weave invert " ..target.. " body spirit"

elseif psionweave[1] == "unweave mind" then
  atk = atk.."psi transcend " ..psiontranscend[1].. " " ..target.. ";weave prepare " ..psionprepare[1]..";weave unweave " ..target.. " mind"
elseif psionweave[1] == "unweave body" then
  atk = atk.."psi transcend " ..psiontranscend[1].. " " ..target.. ";weave prepare " ..psionprepare[1]..";weave unweave " ..target.. " body"
elseif psionweave[1] == "unweave spirit" then
  atk = atk.."psi transcend " ..psiontranscend[1].. " " ..target.. ";weave prepare " ..psionprepare[1]..";weave unweave " ..target.. " spirit"
else
 atk = atk.."psi transcend " ..psiontranscend[1].. " " ..target.. ";weave prepare " ..psionprepare[1]..";weave " ..psionweave[1].. " " ..target
end

-- ATTACK--
if lightbind == true then
send("queue addclearfull freestand wield right shield; " ..atk..";assess " ..target..";contemplate " ..target)
elseif lightbind == false then
send("queue addclearfull freestand wield right shield; " ..atk.." ;enact lightbind " ..target..";assess " ..target..";contemplate " ..target)
end
--LOS Destruction
--enact wrath - eq speed up and rupture - below half health
--enact rupture - 4 attacks bleeding
--enact wavesurge

--End Function
end 

function levipsionmind()
local atk = combatQueue()
local sp = ataxia.settings.separator
php = php or 100
pm = pm or 100
tAffs.criticalspirit = tAffs.criticalspirit or false
tAffs.criticalmind = tAffs.criticalmind or false
tAffs.criticalbody = tAffs.criticalbody or false
pdeconstruct = pdeconstruct or false
psionweaves = ataxiaTables.limbData.psionweaves

--Get Targets Anti Active Cure
getLockingAffliction()

--Get Target Lock Status
checkTargetLocks()

--Check for Psi Blast Criteria
if checkAffList({"impatience", "stupidity", "blackout", "dizziness", "epilepsy", "unweavingmind" },3) then
  tpsiblast = true
else
  tpsiblast = false
end

-- Set Invert
mindinvert = mindinvert or false
bodyinvert = bodyinvert or false
spiritinvert = spiritinvert or false
inverted = inverted or false


--Deconstruct
if tAffs.criticalspirit == true and tAffs.criticalbody == true and tAffs.criticalmind == true then
pdeconstruct = true
elseif tAffs.criticalbody == true and tAffs.criticalmind == true then
pdeconstruct = true
elseif tAffs.criticalbody == true and tAffs.criticalspirit == true then
pdeconstruct = true
elseif tAffs.criticalspirit == true and tAffs.criticalmind == true then
pdeconstruct = true
end




--Prep Limb

if lb[target].hits["head"] + psionweaves >= 100 then
  pprepped_head = true
else 
  pprepped_head = false
end
if lb[target].hits["left arm"] + psionweaves >= 100 then
  pprepped_leftarm = true
else 
  pprepped_leftarm = false
end
if lb[target].hits["right arm"] + psionweaves >= 100 then
  pprepped_rightarm = true
else 
  pprepped_rightarm = false
end
if lb[target].hits["right leg"] + psionweaves >= 100 then
  pprepped_rightleg = true
else 
  pprepped_rightleg = false
end
if lb[target].hits["left leg"] + psionweaves >= 100 then
  pprepped_leftleg = true
else 
  pprepped_leftleg = false
end

--Table for Prepare
psionprepare = {}
if tAffs.mindravaged and not tAffs.haemophilia then
  table.insert(psionprepare,"laceration")
elseif not tAffs.paralysis then
  table.insert(psionprepare,"disruption")
elseif not tAffs.haemophilia then
  table.insert(psionprepare,"laceration")
elseif not tAffs.asthma then
  table.insert(psionprepare,"vapours")
else
  table.insert(psionprepare,"rattle")
end


--Table for Weave
--overhand - if prone then impatient . if head broken impatience, if not prone, stupidity, 
--Backhand -- stupdity/dizziness - if prone , knock focus balance
--puncture -- weariness - arm
--sever - clumsiness - arm
--deathblow - asthma - head - prone - bleeding
--hamstring - legs - prone if broken legs


psionweave = {}
if not tAffs.mindravaged then --1
  if pdeconstruct == true then --2
     table.insert(psionweave,"deconstruct")
  elseif tAffs.damagedhead and not tAffs.impatience then
    table.insert(psionweave,"overhand")
  elseif pprepped_head == true and not tAffs.damagedhead and not tAffs.impatience then
    table.insert(psionweave,"overhand")
  elseif pprepped_head == true and not tAffs.damagedhead and tAffs.impatience and not tAffs.stupidity or not tAffs.dizziness then
    table.insert(psionweave,"backhand")
  elseif pprepped_head == true and not tAffs.damagedhead and tAffs.impatience and tAffs.stupidity and tAffs.dizziness and not tAffs.asthma and psionprepare[1] ~= "vapours"  then
    table.insert(psionweave,"deathblow")
  elseif not tAffs.impatience and tAffs.prone then
    table.insert(psionweave,"overhand")
  elseif tAffs.impatience and tAffs.prone and not tAffs.stupidity or not tAffs.dizziness then
    table.insert(psionweave,"backhand")
  elseif tAffs.unweavingmind and tAffs.unweavingbody then
    if ataxiaNDB_getClass(target) == "Priest" or ataxiaNDB_getClass(target) == "Occultist" or ataxiaNDB_getClass(target) == "Pariah" then --3
      if not tAffs.weariness then --4
        table.insert(psionweave,"puncture")
      elseif not tAffs.clumsiness then
        table.insert(psionweave,"sever")
      elseif not tAffs.asthma and psionprepare[1] ~= "vapours" then
        table.insert(psionweave,"deathblow")
      end -- End 4
    elseif ataxiaNDB_getClass(target) ~= "Priest" or ataxiaNDB_getClass(target) ~= "Occultist" or ataxiaNDB_getClass(target) ~= "Pariah" then--3
      if not tAffs.clumsiness then --5
        table.insert(psionweave,"sever")
      elseif not tAffs.weariness then
        table.insert(psionweave,"puncture")
      elseif not tAffs.asthma and psionprepare[1] ~= "vapours" then
        table.insert(psionweave,"deathblow")
      end -- End 5
    end -- End 3
  elseif not tAffs.unweavingbody then
    table.insert(psionweave,"unweave body")
  elseif not tAffs.unweavingmind then
    table.insert(psionweave,"unweave mind")
  else
    table.insert(psionweave,"unweave mind")
  end -- End 2
elseif tAffs.mindravaged then
   if pdeconstruct == true then -- 6
     table.insert(psionweave,"deconstruct")
  elseif tAffs.damagedhead and not tAffs.impatience then
    table.insert(psionweave,"overhand")
  elseif pprepped_head == true and not tAffs.damagedhead and not tAffs.impatience then
    table.insert(psionweave,"overhand")
  elseif pprepped_head == true and not tAffs.damagedhead and tAffs.impatience and not tAffs.stupidity or not tAffs.dizziness then
    table.insert(psionweave,"backhand")
  elseif pprepped_head == true and not tAffs.damagedhead and tAffs.impatience and tAffs.stupidity and tAffs.dizziness and not tAffs.asthma and psionprepare[1] ~= "vapours"  then
    table.insert(psionweave,"deathblow")
  elseif not tAffs.impatience and tAffs.prone then
    table.insert(psionweave,"overhand")
  elseif tAffs.impatience and tAffs.prone and not tAffs.stupidity or not tAffs.dizziness then
    table.insert(psionweave,"backhand")
 
  elseif tAffs.unweavingmind and tAffs.unweavingbody then
    if ataxiaNDB_getClass(target) == "Priest" or ataxiaNDB_getClass(target) == "Occultist" or ataxiaNDB_getClass(target) == "Pariah" then --7
      if not tAffs.weariness then --8
        table.insert(psionweave,"puncture")
      elseif not tAffs.clumsiness then
        table.insert(psionweave,"sever")
      elseif not tAffs.asthma and psionprepare[1] ~= "vapours" then
        table.insert(psionweave,"deathblow")
      end -- End 8
    elseif ataxiaNDB_getClass(target) ~= "Priest" or ataxiaNDB_getClass(target) ~= "Occultist" or ataxiaNDB_getClass(target) ~= "Pariah" then
      if not tAffs.clumsiness then -- 9
        table.insert(psionweave,"sever")
      elseif not tAffs.weariness then
        table.insert(psionweave,"puncture")
      elseif not tAffs.asthma and psionprepare[1] ~= "vapours" then
        table.insert(psionweave,"deathblow")
      end -- End 9
    end -- End 7
  elseif tAffs.unweavingmind and not tAffs.unweavingbody then
    table.insert(psionweave,"unweave body")
  elseif not tAffs.unweavingmind then
    table.insert(psionweave,"unweave mind")
  else
    table.insert(psionweave,"unweave mind")
  end -- End 6
end -- End 0

--Table Transcend
psiontranscend = {}
if pm <= 30 then
  table.insert(psiontranscend,"excise")
elseif tpsiblast == true and not tAffs.mindravaged then
  table.insert(psiontranscend,"blast")
elseif not tAffs.muddled then
  table.insert(psiontranscend,"muddle")
else
  table.insert(psiontranscend,"shatter")
end

---ATTACK LOGIC---
if tAffs.shield then
  atk = atk.."psi transcend " ..psiontranscend[1].. " " ..target.. ";weave prepare " ..psionprepare[1]..";weave cleave " ..target
elseif pm <= 30  then 
  atk = atk.."psi transcend " ..psiontranscend[1].. " " ..target.. ";psi excise " ..target
elseif psionweave[1] == "unweave mind" then
  atk = atk.."psi transcend " ..psiontranscend[1].. " " ..target.. ";weave prepare " ..psionprepare[1]..";weave unweave " ..target.. " mind"
elseif psionweave[1] == "unweave body" then
  atk = atk.."psi transcend " ..psiontranscend[1].. " " ..target.. ";weave prepare " ..psionprepare[1]..";weave unweave " ..target.. " body"
elseif psionweave[1] == "unweave spirit" then
  atk = atk.."psi transcend " ..psiontranscend[1].. " " ..target.. ";weave prepare " ..psionprepare[1]..";weave unweave " ..target.. " spirit"
else
 atk = atk.."psi transcend " ..psiontranscend[1].. " " ..target.. ";weave prepare " ..psionprepare[1]..";weave " ..psionweave[1].. " " ..target
end

-- ATTACK--
if lightbind == true then
send("queue addclearfull freestand wield right shield; " ..atk..";assess " ..target..";contemplate " ..target)
elseif lightbind == false then
send("queue addclearfull freestand wield right shield; " ..atk.." ;enact lightbind " ..target..";assess " ..target..";contemplate " ..target)
end
--LOS Destruction

--enact wrath - eq speed up and rupture - below half health


--enact rupture - 4 attacks bleeding


--enact wavesurge

-- PSI TRANSCEND



--End Function
end 

