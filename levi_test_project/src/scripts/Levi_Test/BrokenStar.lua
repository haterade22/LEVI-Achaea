--17.0/11.3
function bm_brokenstarroute()
bmstriking4()
local atk = combatQueue()
getLockingAffliction()
checkTargetLocks()

if checkAffList({"anorexia", "asthma", "slickness", "paralysis"},4) then
	local	treelock = true
else
  treelock = false
end



ataxiaTemp.tarTumble = ataxiaTemp.tarTumble or false
tarpreapply = tarpreapply or false
tAffs.bleed = tAffs.bleed or 0
bmslash1 = ataxiaTables.limbData.bmSlash
bmslash2 = ataxiaTables.limbData.bmOffSlash
bmcslash = ataxiaTables.limbData.bmCompass
ataxiaTemp.parriedLimb = ataxiaTemp.parriedLimb or "none"

if lb[target].hits["head"] + bmslash1 >= 100 and not tAffs.damagedhead then 
mprepped_head = true else
mprepped_head = false
end



if lb[target].hits["torso"] + bmslash1 >= 100 and not tAffs.damagedtorso then 
mprepped_torso = true else
mprepped_torso = false
end


if lb[target].hits["left leg"] + bmslash1 >= 100 and not tAffs.damagedleftleg then 
mprepped_leftleg = true else
mprepped_leftleg = false
end


if lb[target].hits["right leg"] + bmslash1 >= 100 and not tAffs.damagedrightleg then 
mprepped_rightleg = true else
mprepped_rightleg = false
end


if lb[target].hits["right arm"] + bmslash1 >= 100 and not tAffs.damagedrightarm then 
mprepped_rightarm = true else
mprepped_rightarm = false
end


if lb[target].hits["left arm"] + bmslash1 >= 100 and not tAffs.damagedleftarm then 
mprepped_leftarm = true else
mprepped_leftarm = false
end




if ataxiaNDB.players[target].city == "Mhaldor" and tAffs.bleed >= 700 then
send("say BrokenStarrrrrrr")

elseif ataxiaNDB.players[target].city ~= "Mhaldor" and tAffs.bleed >= 700 then
atk = atk.. "withdraw blade;sheathe sword;brokenstar " ..target

elseif tAffs.impaled and timpaleslash == true then
atk = atk.."bladetwist;assess "..target..";discern " ..target

elseif tAffs.impaled and timpaleslash == false then
atk = atk.. " assess "..target..";impaleslash"


elseif tAffs.prone and lb[target].hits["left leg"] >= 100 or tAffs.damagedleftleg and lb[target].hits["right leg"] >= 100 or tAffs.damagedrightleg and not tAffs.impaled then
atk = atk.. " assess "..target..";impale " ..target

elseif tAffs.prone and lb[target].hits["left leg"] >= 100 or tAffs.damagedleftleg or lb[target].hits["right leg"] >= 100 or tAffs.damagedrightleg and not tAffs.impaled then
atk = atk.. " assess "..target..";impale " ..target



--Prep
elseif tAffs.paralysis or tAffs.prone and timpaleslash == false then
  atk = atk.. " assess "..target..";impale " ..target

elseif mprepped_rightleg and mprepped_leftleg and lb[target].hits["torso"] >= 100 or tAffs.mildtrauma and timpaleslash == false then
  atk = atk.. " infuse lightning;assess "..target.. ";pommelstrike " ..target.. " neck;assess " ..target
   

elseif timpaleslash == true then
  if not tAffs.clumsiness then
    if lb[target].hits["torso"] >= 100 or tAffs.mildtrauma and mprepped_rightleg and mprepped_leftleg and tmounted == true then 
      atk = atk.. " infuse lightning;assess "..target.. ";pommelstrike " ..target.. " left knees;assess " ..target
    elseif lb[target].hits["torso"] >= 100 or tAffs.mildtrauma and mprepped_rightleg and mprepped_leftleg and ataxiaTemp.parriedLimb ~= "left leg" or tAffs.airfisted then 
      atk = atk.. " infuse lightning;assess "..target.. ";legslash " ..target.. " left knees;assess " ..target
    elseif lb[target].hits["torso"] >= 100 or tAffs.mildtrauma and mprepped_rightleg and mprepped_leftleg and ataxiaTemp.parriedLimb ~= "right leg" or tAffs.airfisted then 
      atk = atk.. " infuse lightning;assess "..target.. ";legslash " ..target.. " right knees;assess " ..target
    elseif mprepped_rightleg and mprepped_leftleg and mprepped_torso and ataxiaTemp.parriedLimb ~= "torso" or tAffs.airfisted then
      atk = atk.. " infuse lightning;assess "..target.. ";centreslash " ..target.. " up " ..tstrike.. ";assess " ..target
    elseif mprepped_rightleg and not mprepped_leftleg and ataxiaTemp.parriedLimb ~= "left leg" or tAffs.airfisted then
      atk = atk.. " infuse lightning;assess "..target.. ";compassslash " ..target.. " southeast " ..tstrike.. ";assess " ..target
    elseif mprepped_leftleg and not mprepped_rightleg and mprepped_torso and ataxiaTemp.parriedLimb ~= "right leg" or tAffs.airfisted then
      atk = atk.. " infuse lightning;assess "..target.. ";compassslash " ..target.. " southwest " ..tstrike.. ";assess " ..target
    elseif not mprepped_torso and ataxiaTemp.parriedLimb ~= "torso" or tAffs.airfisted then
      atk = atk.. " infuse lightning;assess "..target.. ";centreslash " ..target.. " up " ..tstrike.. ";assess " ..target
    elseif not mprepped_torso and ataxiaTemp.parriedLimb == "torso" and not tAffs.airfisted then
      atk = atk.. " infuse lightning;assess "..target.. ";centreslash " ..target.. " down " ..tstrike.. ";assess " ..target
    elseif not mprepped_rightleg and ataxiaTemp.parriedLimb ~= "right leg" or tAffs.airfisted and not mprepped_leftleg then
      atk = atk.. " infuse lightning;assess "..target.. ";legslash " ..target.. " right " ..tstrike.. " ;assess " ..target
    elseif not mprepped_leftleg and ataxiaTemp.parriedLimb ~= "left leg" or tAffs.airfisted and not mprepped_leftleg then
      atk = atk.. " infuse lightning;assess "..target.. ";legslash " ..target.. " left " ..tstrike.. " ;assess " ..target
    else
      atk = atk.. " infuse lightning;assess "..target.. ";balanceslash " ..target.. " " ..tstrike.. " ;assess " ..target
    end
  
  elseif tAffs.clumsiness then
     if lb[target].hits["torso"] >= 100 or tAffs.mildtrauma and mprepped_rightleg and mprepped_leftleg and tmounted == true then 
      atk = atk.. " infuse ice;assess "..target.. ";pommelstrike " ..target.. " left knees;assess " ..target
    elseif lb[target].hits["torso"] >= 100 or tAffs.mildtrauma and mprepped_rightleg and mprepped_leftleg and ataxiaTemp.parriedLimb ~= "left leg" or tAffs.airfisted then 
      atk = atk.. " infuse ice;assess "..target.. ";legslash " ..target.. " left knees;assess " ..target
    elseif lb[target].hits["torso"] >= 100 or tAffs.mildtrauma and mprepped_rightleg and mprepped_leftleg and ataxiaTemp.parriedLimb ~= "right leg" or tAffs.airfisted then 
      atk = atk.. " infuse ice;assess "..target.. ";legslash " ..target.. " right knees;assess " ..target
    elseif mprepped_rightleg and mprepped_leftleg and mprepped_torso and ataxiaTemp.parriedLimb ~= "torso" or tAffs.airfisted then
      atk = atk.. " infuse ice;assess "..target.. ";centreslash " ..target.. " up " ..tstrike.. ";assess " ..target
    elseif mprepped_rightleg and not mprepped_leftleg and ataxiaTemp.parriedLimb ~= "left leg" or tAffs.airfisted then
      atk = atk.. " infuse ice;assess "..target.. ";compassslash " ..target.. " southeast " ..tstrike.. ";assess " ..target
    elseif mprepped_leftleg and not mprepped_rightleg and mprepped_torso and ataxiaTemp.parriedLimb ~= "right leg" or tAffs.airfisted then
      atk = atk.. " infuse ice;assess "..target.. ";compassslash " ..target.. " southwest " ..tstrike.. ";assess " ..target
    elseif not mprepped_torso and ataxiaTemp.parriedLimb ~= "torso" or tAffs.airfisted then
      atk = atk.. " infuse ice;assess "..target.. ";centreslash " ..target.. " up " ..tstrike.. ";assess " ..target
    elseif not mprepped_torso and ataxiaTemp.parriedLimb == "torso" or not tAffs.airfisted then
      atk = atk.. " infuse ice;assess "..target.. ";centreslash " ..target.. " down " ..tstrike.. ";assess " ..target
    elseif not mprepped_rightleg and ataxiaTemp.parriedLimb ~= "right leg" or tAffs.airfisted and not mprepped_leftleg then
      atk = atk.. " infuse ice;assess "..target.. ";legslash " ..target.. " right " ..tstrike.. " ;assess " ..target
    elseif not mprepped_leftleg and ataxiaTemp.parriedLimb ~= "left leg" or tAffs.airfisted and not mprepped_leftleg then
      atk = atk.. " infuse ice;assess "..target.. ";legslash " ..target.. " left " ..tstrike.. " ;assess " ..target
    else
      atk = atk.. " infuse ice;assess "..target.. ";balanceslash " ..target.. " " ..tstrike.. " ;assess " ..target
    end
  end

elseif timpaleslash == false then
  if not tAffs.clumsiness then
    if lb[target].hits["torso"] >= 100 or tAffs.mildtrauma and mprepped_rightleg and mprepped_leftleg and tmounted == true then 
      atk = atk.. " infuse lightning;assess "..target.. ";pommelstrike " ..target.. " left knees;assess " ..target
    elseif lb[target].hits["torso"] >= 100 or tAffs.mildtrauma and mprepped_rightleg and mprepped_leftleg and ataxiaTemp.parriedLimb ~= "left leg" or tAffs.airfisted then 
      atk = atk.. " infuse lightning;assess "..target.. ";legslash " ..target.. " left knees;assess " ..target
    elseif lb[target].hits["torso"] >= 100 or tAffs.mildtrauma and mprepped_rightleg and mprepped_leftleg and ataxiaTemp.parriedLimb ~= "right leg" or tAffs.airfisted then 
      atk = atk.. " infuse lightning;assess "..target.. ";legslash " ..target.. " right knees;assess " ..target
    elseif mprepped_rightleg and mprepped_leftleg and mprepped_torso and ataxiaTemp.parriedLimb ~= "torso" or tAffs.airfisted then
      atk = atk.. " infuse lightning;assess "..target.. ";centreslash " ..target.. " up " ..tstrike.. ";assess " ..target
    elseif mprepped_rightleg and not mprepped_leftleg and ataxiaTemp.parriedLimb ~= "left leg" or tAffs.airfisted then
      atk = atk.. " infuse lightning;assess "..target.. ";compassslash " ..target.. " southeast " ..tstrike.. ";assess " ..target
    elseif mprepped_leftleg and not mprepped_rightleg and mprepped_torso and ataxiaTemp.parriedLimb ~= "right leg" or tAffs.airfisted then
      atk = atk.. " infuse lightning;assess "..target.. ";compassslash " ..target.. " southwest " ..tstrike.. ";assess " ..target
    elseif not mprepped_torso and ataxiaTemp.parriedLimb ~= "torso" or tAffs.airfisted then
      atk = atk.. " infuse lightning;assess "..target.. ";centreslash " ..target.. " up " ..tstrike.. ";assess " ..target
    elseif not mprepped_torso and ataxiaTemp.parriedLimb == "torso" or not tAffs.airfisted then
      atk = atk.. " infuse lightning;assess "..target.. ";centreslash " ..target.. " down " ..tstrike.. ";assess " ..target
    elseif not mprepped_rightleg and ataxiaTemp.parriedLimb ~= "right leg" or tAffs.airfisted and not mprepped_leftleg then
      atk = atk.. " infuse lightning;assess "..target.. ";legslash " ..target.. " right " ..tstrike.. " ;assess " ..target
    elseif not mprepped_leftleg and ataxiaTemp.parriedLimb ~= "left leg" or tAffs.airfisted and not mprepped_leftleg then
      atk = atk.. " infuse lightning;assess "..target.. ";legslash " ..target.. " left " ..tstrike.. " ;assess " ..target
    else
      atk = atk.. " infuse lightning;assess "..target.. ";balanceslash " ..target.. " " ..tstrike.. " ;assess " ..target
    end
  
  elseif tAffs.clumsiness then
     if lb[target].hits["torso"] >= 100 or tAffs.mildtrauma and mprepped_rightleg and mprepped_leftleg and tmounted == true then 
      atk = atk.. " infuse ice;assess "..target.. ";pommelstrike " ..target.. " left knees;assess " ..target
    elseif lb[target].hits["torso"] >= 100 or tAffs.mildtrauma and mprepped_rightleg and mprepped_leftleg and ataxiaTemp.parriedLimb ~= "left leg" or tAffs.airfisted then 
      atk = atk.. " infuse ice;assess "..target.. ";legslash " ..target.. " left knees;assess " ..target
    elseif lb[target].hits["torso"] >= 100 or tAffs.mildtrauma and mprepped_rightleg and mprepped_leftleg and ataxiaTemp.parriedLimb ~= "right leg" or tAffs.airfisted then 
      atk = atk.. " infuse ice;assess "..target.. ";legslash " ..target.. " right knees;assess " ..target
    elseif mprepped_rightleg and mprepped_leftleg and mprepped_torso and ataxiaTemp.parriedLimb ~= "torso" or tAffs.airfisted then
      atk = atk.. " infuse ice;assess "..target.. ";centreslash " ..target.. " up " ..tstrike.. ";assess " ..target
    elseif mprepped_rightleg and not mprepped_leftleg and ataxiaTemp.parriedLimb ~= "left leg" or tAffs.airfisted then
      atk = atk.. " infuse ice;assess "..target.. ";compassslash " ..target.. " southeast " ..tstrike.. ";assess " ..target
    elseif mprepped_leftleg and not mprepped_rightleg and mprepped_torso and ataxiaTemp.parriedLimb ~= "right leg" or tAffs.airfisted then
      atk = atk.. " infuse ice;assess "..target.. ";compassslash " ..target.. " southwest " ..tstrike.. ";assess " ..target
    elseif not mprepped_torso and ataxiaTemp.parriedLimb ~= "torso" or tAffs.airfisted then
      atk = atk.. " infuse ice;assess "..target.. ";centreslash " ..target.. " up " ..tstrike.. ";assess " ..target
    elseif not mprepped_torso and ataxiaTemp.parriedLimb == "torso" or not tAffs.airfisted then
      atk = atk.. " infuse ice;assess "..target.. ";centreslash " ..target.. " down " ..tstrike.. ";assess " ..target
    elseif not mprepped_rightleg and ataxiaTemp.parriedLimb ~= "right leg" or tAffs.airfisted and not mprepped_leftleg then
      atk = atk.. " infuse ice;assess "..target.. ";legslash " ..target.. " right " ..tstrike.. " ;assess " ..target
    elseif not mprepped_leftleg and ataxiaTemp.parriedLimb ~= "left leg" or tAffs.airfisted and not mprepped_leftleg then
      atk = atk.. " infuse ice;assess "..target.. ";legslash " ..target.. " left " ..tstrike.. " ;assess " ..target
    else
      atk = atk.. " infuse ice;assess "..target.. ";balanceslash " ..target.. " " ..tstrike.. " ;assess " ..target
    end
  end

  
end 
if tAffs.rebounding or tAffs.shield then
  send("queue addclear freestand raze " ..target.. " " ..tstrike.. "assess " ..target)
elseif not engaged then
  send("queue addclear freestand " ..atk.. ";engage " ..target)
else
send("queue addclear freestand " ..atk)

end
end




function bm_brokenstarroute2()
bmstriking4()
local atk = combatQueue()
getLockingAffliction()
checkTargetLocks()

if checkAffList({"anorexia", "asthma", "slickness", "paralysis"},4) then
	local	treelock = true
else
  treelock = false
end

ataxiaTemp.tarTumble = ataxiaTemp.tarTumble or false
tarpreapply = tarpreapply or false
tAffs.bleed = tAffs.bleed or 0
bmslash1 = bmslash1 or ataxiaTables.limbData.bmSlash
bmslash2 = bmslash2 or ataxiaTables.limbData.bmOffSlash
bmcslash = bmcslash or ataxiaTables.limbData.bmCompass
ataxiaTemp.parriedLimb = ataxiaTemp.parriedLimb or "none"

if lb[target].hits["head"] + bmslash1 >= 100 and not tAffs.damagedhead then 
bmprepped_head = true else
bmprepped_head = false
end
if lb[target].hits["head"] + bmslash2 >= 100 and not tAffs.damagedhead then 
bm2prepped_head = true else
bm2prepped_head = false
end
if lb[target].hits.head + bmcslash >= 100 and not tAffs.damagedhead then 
bm3prepped_head = true else
bm3prepped_head = false
end

if lb[target].hits.torso + bmslash1 >= 100 and not tAffs.mildtrauma then 
bmprepped_torso = true else
bmprepped_torso = false
end
if lb[target].hits.torso + bmslash2 >= 100 and not tAffs.mildtrauma then 
bm2prepped_torso = true else
bm2prepped_torso = false
end

if lb[target].hits.torso + bmcslash >= 100 and not tAffs.mildtrauma then 
bm3prepped_torso = true else
bm3prepped_torso = false
end

if lb[target].hits["left arm"] + bmslash1 >= 100 and not tAffs.damagedleftarm then 
bmprepped_leftarm = true else
bmprepped_leftarm = false
end
if lb[target].hits["left arm"] + bmslash2 >= 100 and not tAffs.damagedleftarm then 
bm2prepped_leftarm = true else
bm2prepped_leftarm = false
end
if lb[target].hits["left arm"] + bmcslash >= 100 and not tAffs.damagedleftarm then 
bm3prepped_leftarm = true else
bm3prepped_leftarm = false
end

if lb[target].hits["right arm"] + bmslash1 >= 100 and not tAffs.damagedrightarm then 
bmprepped_rightarm = true else
bmprepped_rightarm = false
end
if lb[target].hits["right arm"] + bmslash2 >= 100 and not tAffs.damagedrightarm then 
bm2prepped_rightarm = true else
bm2prepped_rightarm = false
end
if lb[target].hits["right arm"] + bmcslash >= 100 and not tAffs.damagedrightarm then 
bm3prepped_rightarm = true else
bm3prepped_rightarm = false
end

if lb[target].hits["left leg"] + bmslash1 >= 100 and not tAffs.damagedleftleg then 
bmprepped_leftleg = true else
bmprepped_leftleg = false
end
if lb[target].hits["left leg"] + bmslash2 >= 100 and not tAffs.damagedleftleg then 
bm2prepped_leftleg = true else
bm2prepped_leftleg = false
end
if lb[target].hits["left leg"] + bmcslash >= 100 and not tAffs.damagedleftleg then 
bm3prepped_leftleg = true else
bm3prepped_leftleg = false
end

if lb[target].hits["right leg"] + bmslash1 >= 100 and not tAffs.damagedrightleg then 
bmprepped_rightleg = true else
bmprepped_rightleg = false
end
if lb[target].hits["right leg"] + bmslash2 >= 100 and not tAffs.damagedrightleg then 
bm2prepped_rightleg = true else
bm2prepped_rightleg = false
end
if lb[target].hits["right leg"] + bmcslash >= 100 and not tAffs.damagedrightleg then 
bm3prepped_rightleg = true else
bm3prepped_rightleg = false
end


if ataxiaNDB.players[target].city == "Mhaldor" and tAffs.bleed >= 700 then
send("say BrokenStarrrrrrr")

elseif ataxiaNDB.players[target].city ~= "Mhaldor" and tAffs.bleed >= 700 then
atk = atk.. "withdraw blade;sheathe sword;brokenstar " ..target

elseif tAffs.impaled and timpaleslash == true then
atk = atk.."bladetwist;assess "..target..";discern " ..target

elseif tAffs.impaled and timpaleslash == false then
atk = atk.. " assess "..target..";impaleslash;discern " ..target


elseif tAffs.prone and lb[target].hits["left leg"] >= 100 or tAffs.damagedleftleg and lb[target].hits["right leg"] >= 100 or tAffs.damagedrightleg and not tAffs.impaled then
atk = atk.. " assess "..target..";impale " ..target




--Prep
elseif tAffs.paralysis or tAffs.prone and timpaleslash == false then
  atk = atk.. " assess "..target..";impale " ..target
elseif bmprepped_torso and bmprepped_rightleg and not bm3prepped_leftleg and not bm2prepped_leftleg and (ataxiaTemp.parriedLimb == "left leg" and not tAffs.airfisted) then
  atk = atk.. ";compassslash " ..target.. " southeast " ..tstrike
elseif bmprepped_torso and bmprepped_leftleg and not bm3prepped_rightleg and not bm2prepped_rightleg and (ataxiaTemp.parriedLimb == "right leg" and not tAffs.airfisted) then
  atk = atk.. ";compassslash " ..target.. " southwest " ..tstrike
elseif not bmprepped_torso and (ataxiaTemp.parriedLimb ~= "torso" or tAffs.airfisted) then
  atk = atk.. ";centreslash " ..target.. " up " ..tstrike
elseif not bm2prepped_torso and (ataxiaTemp.parriedLimb == "torso" and not tAffs.airfisted) then
  atk = atk.. ";centreslash " ..target.. " down " ..tstrike
elseif not bmprepped_rightleg and (ataxiaTemp.parriedLimb ~= "right leg" or tAffs.airfisted) then
  atk = atk.. ";legslash " ..target.. " right " ..tstrike
elseif not bmprepped_leftleg and (ataxiaTemp.parriedLimb ~= "left leg" or tAffs.airfisted) then
  atk = atk.. ";legslash " ..target.. " left " ..tstrike
else
  atk = atk.. ";balanceslash " ..target.. " left " ..tstrike





end 
if tAffs.rebounding or tAffs.shield then
  send("queue addclear freestand raze " ..target.. " " ..tstrike)
elseif not engaged then
  send("queue addclear freestand " ..atk.. ";engage " ..target)
else
send("queue addclear freestand " ..atk)

end
end








