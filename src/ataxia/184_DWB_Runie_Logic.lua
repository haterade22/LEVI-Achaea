-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > RuneWarden > DWB Runie > DWB Runie Logic


DWBWhirlDamage = DWBWhirlDamage or 0
-- isaz tiwaz wunjo
-- tiwaz wunjo sowulu

function dwb_pocketleg()
--When you need a breather
local atk = combatQueue()
getLockingAffliction()
checkTargetLocks()

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
ataxiaTemp.tarTumble = ataxiaTemp.tarTumble or false
tarpreapply = tarpreapply or false
tAffs.bleed = tAffs.bleed or 0
mstardamage = DWBWhirlDamage
flaildamage = DWBWhirlDamage
mstar2damage = DWBWhirlDamage + DWBWhirlDamage
tarlimb = tarlimb or "right arm"
tarlimb2 = tarlimb2 or "none"
ataxiaTemp.parriedLimb = ataxiaTemp.parriedLimb or "none"
wieldweapons = wieldweapons or "morningstars"

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 34 then
use_bisect = true else
use_bisect = false
end

if lb[target].hits["head"] + mstardamage >= 99.9 and not tAffs.damagedhead then 
mprepped_head = true else
mprepped_head = false
end
if lb[target].hits["head"] + flaildamage >= 99.9 and not tAffs.damagedhead then 
fprepped_head = true else
fprepped_head = false
end

if lb[target].hits["torso"] + mstardamage >= 99.9 and not tAffs.damagedtorso then 
mprepped_torso = true else
mprepped_torso = false
end
if lb[target].hits["torso"] + flaildamage >= 99.9 and not tAffs.damagedtorso then 
fprepped_torso = true else
fprepped_torso = false
end

if lb[target].hits["left leg"] + mstardamage >= 99.9 and not tAffs.damagedleftleg then 
mprepped_leftleg = true else
mprepped_leftleg = false
end
if lb[target].hits["left leg"] + flaildamage >= 99.9 and not tAffs.damagedleftleg then 
fprepped_leftleg = true else
fprepped_leftleg = false
end

if lb[target].hits["right leg"] + mstardamage >= 99.9 and not tAffs.damagedrightleg then 
mprepped_rightleg = true else
mprepped_rightleg = false
end
if lb[target].hits["right leg"] + flaildamage >= 99.9 and not tAffs.damagedrightleg then 
fprepped_rightleg = true else
fprepped_rightleg = false
end

if lb[target].hits["right arm"] + mstardamage >= 99.9 and not tAffs.damagedrightarm then 
mprepped_rightarm = true else
mprepped_rightarm = false
end
if lb[target].hits["right arm"] + flaildamage >= 99.9 and not tAffs.damagedrightarm then 
fprepped_rightarm = true else
fprepped_rightarm = false
end

if lb[target].hits["left arm"] + mstardamage >= 99.9 and not tAffs.damagedleftarm then 
mprepped_leftarm = true else
mprepped_leftarm = false
end
if lb[target].hits["left arm"] + flaildamage >= 99.9 and not tAffs.damagedleftarm then 
fprepped_leftarm = true else
fprepped_leftarm = false
end

--Double Whirl Stuff
-----------------
-----------------
if lb[target].hits["head"] + mstar2damage >= 99.9 and not tAffs.damagedhead then 
m2prepped_head = true else
m2prepped_head = false
end
if lb[target].hits["head"] + mstar2damage >= 99.9 and not tAffs.damagedhead then 
f2prepped_head = true else
f2prepped_head = false
end

if lb[target].hits["torso"] + mstar2damage >= 99.9 and not tAffs.damagedtorso then 
m2prepped_torso = true else
m2prepped_torso = false
end
if lb[target].hits["torso"] + mstar2damage >= 99.9 and not tAffs.damagedtorso then 
f2prepped_torso = true else
f2prepped_torso = false
end

if lb[target].hits["left arm"] + mstar2damage >= 99.9 and not tAffs.damagedleftarm then 
m2prepped_leftarm = true else
m2prepped_leftarm = false
end
if lb[target].hits["left arm"] + mstar2damage >= 99.9 and not tAffs.damagedleftarm then 
f2prepped_leftarm = true else
f2prepped_leftarm = false
end

if lb[target].hits["right arm"] + mstar2damage >= 99.9 and not tAffs.damagedrightarm then 
m2prepped_rightarm = true else
m2prepped_rightarm = false
end
if lb[target].hits["right arm"] + mstar2damage >= 99.9 and not tAffs.damagedrightarm then 
f2prepped_rightarm = true else
f2prepped_rightarm = false
end

if lb[target].hits["right leg"] + mstar2damage >= 99.9 and not tAffs.damagedrightleg then 
m2prepped_rightleg = true else
m2prepped_rightleg = false
end
if lb[target].hits["right leg"] + mstar2damage >= 99.9 and not tAffs.damagedrightleg then 
f2prepped_rightleg = true else
f2prepped_rightleg = false
end

if lb[target].hits["left leg"] + mstar2damage >= 99.9 and not tAffs.damagedleftleg then 
m2prepped_leftleg = true else
m2prepped_leftleg = false
end
if lb[target].hits["left leg"] + mstar2damage >= 99.9 and not tAffs.damagedleftleg then 
f2prepped_leftleg = true else
f2prepped_leftleg = false
end


--ATTACKKKKK
 
-- Bisect

if myinstantcath == true then
  atk = atk.." touch shield"
elseif not tAffs.shield and use_bisect == true then
  atk = atk.. "wield bastard;bisect " ..target.. " ;assess " ..target.. " ;sizeup " ..target

-- Pulp

elseif not tAffs.shield and (tAffs.concussion or lb[target].hits["head"] >= 200 or ataxiaTemp.fractures.skullfractures >= 5) and tAffs.prone then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;dismount;pulp " ..target.. ";sizeup " ..target.. " ;assess " ..target

--Raze
elseif tAffs.rebounding or tAffs.shield then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon track " ..target.. ";falcon slay " ..target.. ";fracture " ..target.. " ;assess " ..target.. " ;sizeup " ..target

elseif mprepped_leftleg == true and ataxia.vitals.class >= 3 and ataxiaTemp.parriedLimb ~= "left leg" then
  if mprepped_rightleg == false  then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " left leg expend right leg;assess " ..target
  elseif mprepped_head == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " left leg expend head;assess " ..target
  elseif mprepped_torso == false then
   atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " left leg expend torso;assess " ..target
  end
elseif mprepped_rightleg == true and ataxia.vitals.class >= 3 and ataxiaTemp.parriedLimb ~= "right leg" then
  if mprepped_leftleg == false  then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " right leg expend left leg;assess " ..target
  elseif mprepped_head == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " right leg expend head;assess " ..target
  elseif mprepped_torso == false then
   atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " right leg expend torso;assess " ..target
  end
  else
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " ;assess " ..target

  end

if table.contains(ataxia.playersHere, target) then
	if not engaged then
		send("queue addclear freestand " ..atk.. ";engage " ..target)
	else
	send("queue addclear freestand " ..atk)
	end
end
end


function dwb_skullfractures()
local atk = combatQueue()
getLockingAffliction()
checkTargetLocks()

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
ataxiaTemp.tarTumble = ataxiaTemp.tarTumble or false
tarpreapply = tarpreapply or false
tAffs.bleed = tAffs.bleed or 0
mstardamage = DWBWhirlDamage
flaildamage = DWBWhirlDamage
mstar2damage = DWBWhirlDamage + DWBWhirlDamage
tarlimb = tarlimb or "right arm"
tarlimb2 = tarlimb2 or "none"
ataxiaTemp.parriedLimb = ataxiaTemp.parriedLimb or "none"
wieldweapons = wieldweapons or "morningstars"

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 34 then
use_bisect = true else
use_bisect = false
end

if lb[target].hits["head"] + mstardamage >= 99.9 and not tAffs.damagedhead then 
mprepped_head = true else
mprepped_head = false
end
if lb[target].hits["head"] + flaildamage >= 99.9 and not tAffs.damagedhead then 
fprepped_head = true else
fprepped_head = false
end

if lb[target].hits["torso"] + mstardamage >= 99.9 and not tAffs.damagedtorso then 
mprepped_torso = true else
mprepped_torso = false
end
if lb[target].hits["torso"] + flaildamage >= 99.9 and not tAffs.damagedtorso then 
fprepped_torso = true else
fprepped_torso = false
end

if lb[target].hits["left leg"] + mstardamage >= 99.9 and not tAffs.damagedleftleg then 
mprepped_leftleg = true else
mprepped_leftleg = false
end
if lb[target].hits["left leg"] + flaildamage >= 99.9 and not tAffs.damagedleftleg then 
fprepped_leftleg = true else
fprepped_leftleg = false
end

if lb[target].hits["right leg"] + mstardamage >= 99.9 and not tAffs.damagedrightleg then 
mprepped_rightleg = true else
mprepped_rightleg = false
end
if lb[target].hits["right leg"] + flaildamage >= 99.9 and not tAffs.damagedrightleg then 
fprepped_rightleg = true else
fprepped_rightleg = false
end

if lb[target].hits["right arm"] + mstardamage >= 99.9 and not tAffs.damagedrightarm then 
mprepped_rightarm = true else
mprepped_rightarm = false
end
if lb[target].hits["right arm"] + flaildamage >= 99.9 and not tAffs.damagedrightarm then 
fprepped_rightarm = true else
fprepped_rightarm = false
end

if lb[target].hits["left arm"] + mstardamage >= 99.9 and not tAffs.damagedleftarm then 
mprepped_leftarm = true else
mprepped_leftarm = false
end
if lb[target].hits["left arm"] + flaildamage >= 99.9 and not tAffs.damagedleftarm then 
fprepped_leftarm = true else
fprepped_leftarm = false
end

--Double Whirl Stuff
-----------------
-----------------
if lb[target].hits["head"] + mstar2damage >= 99.9 and not tAffs.damagedhead then 
m2prepped_head = true else
m2prepped_head = false
end
if lb[target].hits["head"] + mstar2damage >= 99.9 and not tAffs.damagedhead then 
f2prepped_head = true else
f2prepped_head = false
end

if lb[target].hits["torso"] + mstar2damage >= 99.9 and not tAffs.damagedtorso then 
m2prepped_torso = true else
m2prepped_torso = false
end
if lb[target].hits["torso"] + mstar2damage >= 99.9 and not tAffs.damagedtorso then 
f2prepped_torso = true else
f2prepped_torso = false
end

if lb[target].hits["left arm"] + mstar2damage >= 99.9 and not tAffs.damagedleftarm then 
m2prepped_leftarm = true else
m2prepped_leftarm = false
end
if lb[target].hits["left arm"] + mstar2damage >= 99.9 and not tAffs.damagedleftarm then 
f2prepped_leftarm = true else
f2prepped_leftarm = false
end

if lb[target].hits["right arm"] + mstar2damage >= 99.9 and not tAffs.damagedrightarm then 
m2prepped_rightarm = true else
m2prepped_rightarm = false
end
if lb[target].hits["right arm"] + mstar2damage >= 99.9 and not tAffs.damagedrightarm then 
f2prepped_rightarm = true else
f2prepped_rightarm = false
end

if lb[target].hits["right leg"] + mstar2damage >= 99.9 and not tAffs.damagedrightleg then 
m2prepped_rightleg = true else
m2prepped_rightleg = false
end
if lb[target].hits["right leg"] + mstar2damage >= 99.9 and not tAffs.damagedrightleg then 
f2prepped_rightleg = true else
f2prepped_rightleg = false
end

if lb[target].hits["left leg"] + mstar2damage >= 99.9 and not tAffs.damagedleftleg then 
m2prepped_leftleg = true else
m2prepped_leftleg = false
end
if lb[target].hits["left leg"] + mstar2damage >= 99.9 and not tAffs.damagedleftleg then 
f2prepped_leftleg = true else
f2prepped_leftleg = false
end


--Priority of Limb
if mprepped_rightleg == false then
tarlimb = "right leg"
elseif mprepped_head == false then
tarlimb = "head"
elseif mprepped_leftleg == false then
tarlimb = "left leg"
end


--ATTACKKKKK
 
-- Bisect

if myinstantcath == true then
  atk = atk.." touch shield"
elseif not tAffs.shield and use_bisect == true then
  atk = atk.. "wield bastard;bisect " ..target.. " ;assess " ..target.. " ;sizeup " ..target

-- Pulp

elseif not tAffs.shield and (tAffs.concussion or lb[target].hits["head"] >= 200 or ataxiaTemp.fractures.skullfractures >= 5) and tAffs.prone then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;dismount;pulp " ..target.. ";sizeup " ..target.. " ;assess " ..target

--Raze
elseif tAffs.rebounding or tAffs.shield then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon track " ..target.. ";falcon slay " ..target.. ";fracture " ..target.. " ;assess " ..target.. " ;sizeup " ..target

-- Skull Fractures --
elseif tAffs.prone and ataxia.vitals.class >= 2 then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " head expend head expend;assess " ..target.." ;sizeup " ..target
elseif tAffs.prone and ataxia.vitals.class < 2 then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target


-- Break Sequence --

--Dont Double Break if they Pre-Apply
elseif tarpreapply == true and ataxiaTemp.parriedLimb ~= "torso" then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " torso torso expend;assess " ..target
elseif tarpreapply == true and ataxiaTemp.parriedLimb ~= "head" then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. ";assess " ..target



--Doublebreak with or without clumsiness (Add Discipline
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and tAffs.numbedleftarm and ataxia.vitals.class == 8 then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. " ;assess " ..target
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "right leg" then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. " ;assess " ..target
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " left leg expend right leg;sizeup " ..target.. " ;assess " ..target

elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and tAffs.numbedleftarm and ataxia.vitals.class == 8 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;discipline;doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "right leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;discipline;doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;discipline;doublewhirl " ..target.. " left leg expend right leg;sizeup " ..target.. ";assess " ..target

 

--Anti Parry
elseif not tAffs.numbedleftarm and ataxiaTemp.parriedLimb ~= "left arm" and ataxiaTemp.parriedLimb == "left leg" or ataxiaTemp.parriedLimb == "right leg" or ataxiaTemp.parriedLimb == "head" then
  if ataxia.vitals.class < 1 then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon track " ..target.. " ;falcon slay " ..target.. ";doublewhirl " ..target.. " right arm right arm;sizeup " ..target.. ";assess " ..target
 
  elseif ataxia.vitals.class >= 2 then
    if ataxiaTemp.parriedLimb ~= "torso" then 
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " torso expend left arm expend;sizeup " ..target.. ";assess " ..target
    elseif m2prepped_rightleg == true and mprepped_leftleg == false and mprepped_rightleg == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend right leg;sizeup " ..target.. ";assess " ..target
    elseif m2prepped_leftleg == true and mprepped_leftleg == false and mprepped_rightleg == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend left leg;sizeup " ..target.. ";assess " ..target
    elseif m2prepped_head == true and mprepped_leftleg == false and mprepped_rightleg == false and mpreppedhead == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend head;sizeup " ..target.. ";assess " ..target
    elseif mprepped_leftleg == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend left leg;sizeup " ..target.. ";assess " ..target
    elseif mprepped_rightleg == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend right leg;sizeup " ..target.. ";assess " ..target
    elseif mprepped_head == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend head;sizeup " ..target.. ";assess " ..target
    else 
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend torso;sizeup " ..target.. ";assess " ..target
  
    end
  end
  
--Prep Head\ Left Leg\ Right Leg


--RIGHT LEG SCENARIOS
elseif m2prepped_rightleg == true and mprepped_head == true and mprepped_rightleg == false and mprepped_leftleg == true then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " left arm right leg;assess " ..target
  --if doublewhirl on left leg is going to break than do one whirl and hit another limb
elseif m2prepped_rightleg == true and mprepped_rightleg == false and mprepped_head == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " head right leg;assess " ..target
elseif m2prepped_rightleg == true and mprepped_rightleg == false and mprepped_leftleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " left left right leg;assess " ..target



--HEAD SCENARIOS
elseif m2prepped_head == true and mprepped_head == false and mprepped_rightleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " head right leg;assess " ..target
elseif m2prepped_head == true and mprepped_head == false and mprepped_leftleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " head left leg;assess " ..target
elseif m2prepped_head == true and mprepped_head == false and mprepped_leftleg == true and mprepped_rightleg == true then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " head left arm;assess " ..target
 
 
 
  --LEFT LEG SCENARIOS
  --if doublewhirl on left leg is going to break than do one whirl and hit another limb
elseif m2prepped_leftleg == true and mprepped_leftleg == false and mprepped_rightleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " left leg right leg;assess " ..target
elseif m2prepped_leftleg == true and mprepped_leftleg == false and mprepped_rightleg == true  and mprepped_head == true then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " left leg left arm;assess " ..target
elseif m2prepped_leftleg == true and mprepped_leftleg == false and mprepped_rightleg == true and mprepped_head == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " left leg head;assess " ..target



elseif mprepped_head == false and m2prepped_head == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " head head;assess " ..target
elseif mprepped_leftleg == false and m2prepped_leftleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " left leg left leg;assess " ..target
elseif mprepped_rightleg == false and m2prepped_rightleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " right leg right leg;assess " ..target
else
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " ;assess " ..target

  end

if table.contains(ataxia.playersHere, target) then
	if not engaged then
		send("queue addclear freestand " ..atk.. ";engage " ..target)
	else
	send("queue addclear freestand " ..atk)
	end
end
end


----------------------------------------------------------------------------------------
function dwb_assaultheadpulpsetup()
local atk = combatQueue()
getLockingAffliction()
checkTargetLocks()

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
ataxiaTemp.tarTumble = ataxiaTemp.tarTumble or false
tarpreapply = tarpreapply or false
tAffs.bleed = tAffs.bleed or 0
mstardamage = DWBWhirlDamage
flaildamage = DWBWhirlDamage
mstar2damage = DWBWhirlDamage + DWBWhirlDamage
tarlimb = tarlimb or "right arm"
tarlimb2 = tarlimb2 or "none"
ataxiaTemp.parriedLimb = ataxiaTemp.parriedLimb or "none"
wieldweapons = wieldweapons or "morningstars"

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 35 then
use_bisect = true else
use_bisect = false
end

if lb[target].hits["head"] + mstardamage >= 99.9 and not tAffs.damagedhead then 
mprepped_head = true else
mprepped_head = false
end
if lb[target].hits["head"] + flaildamage >= 99.9 and not tAffs.damagedhead then 
fprepped_head = true else
fprepped_head = false
end

if lb[target].hits["torso"] + mstardamage >= 99.9 and not tAffs.damagedtorso then 
mprepped_torso = true else
mprepped_torso = false
end
if lb[target].hits["torso"] + flaildamage >= 99.9 and not tAffs.damagedtorso then 
fprepped_torso = true else
fprepped_torso = false
end

if lb[target].hits["left leg"] + mstardamage >= 99.9 and not tAffs.damagedleftleg then 
mprepped_leftleg = true else
mprepped_leftleg = false
end
if lb[target].hits["left leg"] + flaildamage >= 99.9 and not tAffs.damagedleftleg then 
fprepped_leftleg = true else
fprepped_leftleg = false
end

if lb[target].hits["right leg"] + mstardamage >= 99.9 and not tAffs.damagedrightleg then 
mprepped_rightleg = true else
mprepped_rightleg = false
end
if lb[target].hits["right leg"] + flaildamage >= 99.9 and not tAffs.damagedrightleg then 
fprepped_rightleg = true else
fprepped_rightleg = false
end

if lb[target].hits["right arm"] + mstardamage >= 99.9 and not tAffs.damagedrightarm then 
mprepped_rightarm = true else
mprepped_rightarm = false
end
if lb[target].hits["right arm"] + flaildamage >= 99.9 and not tAffs.damagedrightarm then 
fprepped_rightarm = true else
fprepped_rightarm = false
end

if lb[target].hits["left arm"] + mstardamage >= 99.9 and not tAffs.damagedleftarm then 
mprepped_leftarm = true else
mprepped_leftarm = false
end
if lb[target].hits["left arm"] + flaildamage >= 99.9 and not tAffs.damagedleftarm then 
fprepped_leftarm = true else
fprepped_leftarm = false
end

--Double Whirl Stuff
-----------------
-----------------
if lb[target].hits["head"] + mstar2damage >= 99.9 and not tAffs.damagedhead then 
m2prepped_head = true else
m2prepped_head = false
end
if lb[target].hits["head"] + mstar2damage >= 99.9 and not tAffs.damagedhead then 
f2prepped_head = true else
f2prepped_head = false
end

if lb[target].hits["torso"] + mstar2damage >= 99.9 and not tAffs.damagedtorso then 
m2prepped_torso = true else
m2prepped_torso = false
end
if lb[target].hits["torso"] + mstar2damage >= 99.9 and not tAffs.damagedtorso then 
f2prepped_torso = true else
f2prepped_torso = false
end

if lb[target].hits["left arm"] + mstar2damage >= 99.9 and not tAffs.damagedleftarm then 
m2prepped_leftarm = true else
m2prepped_leftarm = false
end
if lb[target].hits["left arm"] + mstar2damage >= 99.9 and not tAffs.damagedleftarm then 
f2prepped_leftarm = true else
f2prepped_leftarm = false
end

if lb[target].hits["right arm"] + mstar2damage >= 99.9 and not tAffs.damagedrightarm then 
m2prepped_rightarm = true else
m2prepped_rightarm = false
end
if lb[target].hits["right arm"] + mstar2damage >= 99.9 and not tAffs.damagedrightarm then 
f2prepped_rightarm = true else
f2prepped_rightarm = false
end

if lb[target].hits["right leg"] + mstar2damage >= 99.9 and not tAffs.damagedrightleg then 
  m2prepped_rightleg = true else
  m2prepped_rightleg = false
end
if lb[target].hits["right leg"] + mstar2damage >= 99.9 and not tAffs.damagedrightleg then 
  f2prepped_rightleg = true else
  f2prepped_rightleg = false
end

if lb[target].hits["left leg"] + mstar2damage >= 99.9 and not tAffs.damagedleftleg then 
  m2prepped_leftleg = true else
  m2prepped_leftleg = false
end
if lb[target].hits["left leg"] + mstar2damage >= 99.9 and not tAffs.damagedleftleg then 
  f2prepped_leftleg = true else
  f2prepped_leftleg = false
end


--Priority of Limb
if mprepped_rightleg == false then
  tarlimb = "right leg"
elseif mprepped_head == false then
  tarlimb = "head"
elseif mprepped_leftleg == false then
  tarlimb = "left leg"
end


--ATTACKKKKK
 
-- Bisect\ if Not Mhaldorian

if myinstantcath == true then
  atk = atk.. "touch shield"
elseif not tAffs.shield and use_bisect == true then
  atk = atk.. "sizeup " ..target.. ";wield bastard;bisect " ..target.. ";assess " ..target
-- Pulp
elseif not tAffs.shield and (tAffs.concussion or lb[target].hits["head"] >= 200 or ataxiaTemp.fractures.skullfractures >= 4) and tAffs.prone then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";pulp " ..target.. ";assess " ..target


--Raze
elseif tAffs.rebounding or tAffs.shield then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon track " ..target.. ";falcon slay " ..target.. ";sizeup " ..target.. ";fracture " ..target.. "  ;assess " ..target

--Assault Head
elseif tAffs.prone and (tAffs.damagedhead or lb[target].hits["head"] >= 100) and ataxia.vitals.class >= 7 then
  atk = atk.. "wield left flail343168;wield right flail408566;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";sizeup " ..target.. ";assault " ..target.. " head;assess " ..target

-- Skull Fractures
elseif tAffs.prone and (tAffs.damagedhead or lb[target].hits["head"] >= 100) and ataxia.vitals.class < 7 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " head head;assess " ..target
elseif tAffs.prone and (tAffs.mildtrauma or lb[target].hits["torso"] >= 100) and ataxia.vitals.class < 7 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " torso torso;assess " ..target


--Beat Head
elseif tAffs.prone and ataxia.vitals.class == 1 and not tAffs.numbedrightarm then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " torso right arm expend;sizeup " ..target.. ";assess " ..target
elseif tAffs.prone and ataxia.vitals.class >= 2 and not tAffs.numbedrightarm then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " torso expend right arm expend;sizeup " ..target.. ";assess " ..target
elseif tAffs.prone and ataxia.vitals.class >= 2 and (lb[target].hits["head"] >= 100 or tAffs.damagedhead) then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " head expend head expend;assess " ..target
elseif tAffs.prone and ataxia.vitals.class < 2 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " head head;assess " ..target


-- Break Sequence
elseif tarpreapply == true then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " torso torso expend;assess " ..target

elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and tAffs.numbedleftarm and ataxia.vitals.class == 8 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "right leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " left leg expend right leg;sizeup " ..target.. ";assess " ..target

elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and tAffs.numbedleftarm and ataxia.vitals.class == 8 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;discipline;doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "right leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;discipline;doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;discipline;doublewhirl " ..target.. " left leg expend right leg;sizeup " ..target.. ";assess " ..target

 
--Anti Parry
elseif not tAffs.numbedleftarm and ataxiaTemp.parriedLimb ~= "left arm" and ataxiaTemp.parriedLimb == "left leg" or ataxiaTemp.parriedLimb == "right leg" or ataxiaTemp.parriedLimb == "head" then
  if ataxia.vitals.class < 1 then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon track " ..target.. " ;falcon slay " ..target.. ";doublewhirl " ..target.. " right arm right arm;sizeup " ..target.. ";assess " ..target
 
  elseif ataxia.vitals.class >= 2 then
    if ataxiaTemp.parriedLimb ~= "torso" then 
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " torso expend left arm expend;sizeup " ..target.. ";assess " ..target
    elseif m2prepped_rightleg == true and mprepped_leftleg == false and mprepped_rightleg == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend right leg;sizeup " ..target.. ";assess " ..target
    elseif m2prepped_leftleg == true and mprepped_leftleg == false and mprepped_rightleg == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend left leg;sizeup " ..target.. ";assess " ..target
    elseif m2prepped_head == true and mprepped_leftleg == false and mprepped_rightleg == false and mpreppedhead == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend head;sizeup " ..target.. ";assess " ..target
    elseif mprepped_leftleg == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend left leg;sizeup " ..target.. ";assess " ..target
    elseif mprepped_rightleg == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend right leg;sizeup " ..target.. ";assess " ..target
    elseif mprepped_head == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend head;sizeup " ..target.. ";assess " ..target
    else 
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend torso;sizeup " ..target.. ";assess " ..target
  
    end
  end

  
--Prep Head\ Left Leg\ Right Leg


--RIGHT LEG SCENARIOS
elseif m2prepped_rightleg == true and mprepped_head == true and mprepped_rightleg == false and mprepped_leftleg == true then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " left arm right leg;assess " ..target
  --if doublewhirl on left leg is going to break than do one whirl and hit another limb
elseif m2prepped_rightleg == true and mprepped_rightleg == false and mprepped_head == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " head right leg;assess " ..target
elseif m2prepped_rightleg == true and mprepped_rightleg == false and mprepped_leftleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " left left right leg;assess " ..target



--HEAD SCENARIOS
elseif m2prepped_head == true and mprepped_head == false and mprepped_rightleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " head right leg;assess " ..target
elseif m2prepped_head == true and mprepped_head == false and mprepped_leftleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " head left leg;assess " ..target
elseif m2prepped_head == true and mprepped_head == false and mprepped_leftleg == true and mprepped_rightleg == true then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " head left arm;assess " ..target
 
 
 
  --LEFT LEG SCENARIOS
  --if doublewhirl on left leg is going to break than do one whirl and hit another limb
elseif m2prepped_leftleg == true and mprepped_leftleg == false and mprepped_rightleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " left leg right leg;assess " ..target
elseif m2prepped_leftleg == true and mprepped_leftleg == false and mprepped_rightleg == true  and mprepped_head == true then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " left leg left arm;assess " ..target
elseif m2prepped_leftleg == true and mprepped_leftleg == false and mprepped_rightleg == true and mprepped_head == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " left leg head;assess " ..target



elseif mprepped_head == false and m2prepped_head == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " head head;assess " ..target
elseif mprepped_leftleg == false and m2prepped_leftleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " left leg left leg;assess " ..target
elseif mprepped_rightleg == false and m2prepped_rightleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " right leg right leg;assess " ..target
else
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " ;assess " ..target

  end

if table.contains(ataxia.playersHere, target) then
	if not engaged then
		send("queue addclear freestand " ..atk.. ";engage " ..target)
	else
	send("queue addclear freestand " ..atk)
	end
end
end





function dwb_torsodamage()
local atk = combatQueue()
getLockingAffliction()
checkTargetLocks()

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
ataxiaTemp.tarTumble = ataxiaTemp.tarTumble or false
tarpreapply = tarpreapply or false
tAffs.bleed = tAffs.bleed or 0
mstardamage = DWBWhirlDamage
flaildamage = DWBWhirlDamage
mstar2damage = DWBWhirlDamage + DWBWhirlDamage
tarlimb = tarlimb or "right arm"
tarlimb2 = tarlimb2 or "none"
ataxiaTemp.parriedLimb = ataxiaTemp.parriedLimb or "none"
wieldweapons = wieldweapons or "morningstars"

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 35 then
use_bisect = true else
use_bisect = false
end

if lb[target].hits["head"] + mstardamage >= 99.9 and not tAffs.damagedhead then 
mprepped_head = true else
mprepped_head = false
end
if lb[target].hits["head"] + flaildamage >= 99.9 and not tAffs.damagedhead then 
fprepped_head = true else
fprepped_head = false
end

if lb[target].hits["torso"] + mstardamage >= 99.9 and not tAffs.damagedtorso then 
mprepped_torso = true else
mprepped_torso = false
end
if lb[target].hits["torso"] + flaildamage >= 99.9 and not tAffs.damagedtorso then 
fprepped_torso = true else
fprepped_torso = false
end

if lb[target].hits["left leg"] + mstardamage >= 99.9 and not tAffs.damagedleftleg then 
mprepped_leftleg = true else
mprepped_leftleg = false
end
if lb[target].hits["left leg"] + flaildamage >= 99.9 and not tAffs.damagedleftleg then 
fprepped_leftleg = true else
fprepped_leftleg = false
end

if lb[target].hits["right leg"] + mstardamage >= 99.9 and not tAffs.damagedrightleg then 
mprepped_rightleg = true else
mprepped_rightleg = false
end
if lb[target].hits["right leg"] + flaildamage >= 99.9 and not tAffs.damagedrightleg then 
fprepped_rightleg = true else
fprepped_rightleg = false
end

if lb[target].hits["right arm"] + mstardamage >= 99.9 and not tAffs.damagedrightarm then 
mprepped_rightarm = true else
mprepped_rightarm = false
end
if lb[target].hits["right arm"] + flaildamage >= 99.9 and not tAffs.damagedrightarm then 
fprepped_rightarm = true else
fprepped_rightarm = false
end

if lb[target].hits["left arm"] + mstardamage >= 99.9 and not tAffs.damagedleftarm then 
mprepped_leftarm = true else
mprepped_leftarm = false
end
if lb[target].hits["left arm"] + flaildamage >= 99.9 and not tAffs.damagedleftarm then 
fprepped_leftarm = true else
fprepped_leftarm = false
end

--Double Whirl Formula
-----------------
-----------------
if lb[target].hits["head"] + mstar2damage >= 99.9 and not tAffs.damagedhead then 
m2prepped_head = true else
m2prepped_head = false
end
if lb[target].hits["head"] + mstar2damage >= 99.9 and not tAffs.damagedhead then 
f2prepped_head = true else
f2prepped_head = false
end

if lb[target].hits["torso"] + mstar2damage >= 99.9 and not tAffs.damagedtorso then 
m2prepped_torso = true else
m2prepped_torso = false
end
if lb[target].hits["torso"] + mstar2damage >= 99.9 and not tAffs.damagedtorso then 
f2prepped_torso = true else
f2prepped_torso = false
end

if lb[target].hits["left arm"] + mstar2damage >= 99.9 and not tAffs.damagedleftarm then 
m2prepped_leftarm = true else
m2prepped_leftarm = false
end
if lb[target].hits["left arm"] + mstar2damage >= 99.9 and not tAffs.damagedleftarm then 
f2prepped_leftarm = true else
f2prepped_leftarm = false
end

if lb[target].hits["right arm"] + mstar2damage >= 99.9 and not tAffs.damagedrightarm then 
m2prepped_rightarm = true else
m2prepped_rightarm = false
end
if lb[target].hits["right arm"] + mstar2damage >= 99.9 and not tAffs.damagedrightarm then 
f2prepped_rightarm = true else
f2prepped_rightarm = false
end

if lb[target].hits["right leg"] + mstar2damage >= 99.9 and not tAffs.damagedrightleg then 
m2prepped_rightleg = true else
m2prepped_rightleg = false
end
if lb[target].hits["right leg"] + mstar2damage >= 99.9 and not tAffs.damagedrightleg then 
f2prepped_rightleg = true else
f2prepped_rightleg = false
end

if lb[target].hits["left leg"] + mstar2damage >= 99.9 and not tAffs.damagedleftleg then 
m2prepped_leftleg = true else
m2prepped_leftleg = false
end
if lb[target].hits["left leg"] + mstar2damage >= 99.9 and not tAffs.damagedleftleg then 
f2prepped_leftleg = true else
f2prepped_leftleg = false
end


--Priority of Limb
if mprepped_leftleg == false then
tarlimb = "left leg"
elseif mprepped_rightleg == false then
tarlimb = "right leg"
else
tarlimb = "torso"
end


--ATTACKKKKK
 
-- Bisect

if myinstantcath == true then
  atk = atk.. "touch shield"
elseif not tAffs.shield and use_bisect == true then
  atk = atk.. "sizeup " ..target.. ";wield bastard;bisect " ..target.. " ;assess " ..target
-- Pulp
elseif not tAffs.shield and (tAffs.concussion or lb[target].hits["head"] >= 200 or ataxiaTemp.fractures.skullfractures >= 5) and tAffs.prone then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";pulp " ..target.. ";assess " ..target

--Raze
elseif tAffs.rebounding or tAffs.shield then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon track " ..target.. " ;falcon slay " ..target.. ";sizeup " ..target.. ";fracture " ..target.. "  ;assess " ..target

--Torso Damage
-- Get rid of Rebounding and Tattoos
--elseif tAffs.prone and ataxia.vitals.class == 1 and not tAffs.numbedrightarm then
  --atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " torso right arm expend;sizeup " ..target.. ";assess " ..target
--elseif tAffs.prone and ataxia.vitals.class >= 2 and not tAffs.numbedrightarm then
  --atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " torso expend right arm expend;sizeup " ..target.. ";assess " ..target
elseif tAffs.prone and ataxia.vitals.class >= 3 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";sizeup " ..target.. ";assault " ..target.. " torso;assess " ..target
elseif ataxia.vitals.class >= 2 and ataxiaTemp.fractures.crackedribs >= 1 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";sizeup " ..target.. ";doublewhirl " ..target.. " torso expend torso expend;assess " ..target
elseif ataxia.vitals.class < 2 and ataxiaTemp.fractures.crackedribs >= 1 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";sizeup " ..target.. ";doublewhirl " ..target.. " torso torso;assess " ..target
elseif ataxia.vitals.class < 2 and tAffs.prone then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";sizeup " ..target.. ";doublewhirl " ..target.. " torso torso;assess " ..target
elseif ataxia.vitals.class < 2 and lb[target].hits["head"]>= 100 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";sizeup " ..target.. ";doublewhirl " ..target.. " torso torso;assess " ..target

--Pre-Apply Counter
elseif tarpreapply == true and ataxiaTemp.parriedLimb ~= "torso" then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " torso expend torso;assess " ..target
elseif tarpreapply == true and ataxiaTemp.parriedLimb ~= "head" then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " head head;assess " ..target

-- Double Break
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and tAffs.numbedleftarm and ataxia.vitals.class == 8 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "right leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " left leg expend right leg;sizeup " ..target.. ";assess " ..target

elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and tAffs.numbedleftarm and ataxia.vitals.class == 8 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;discipline;doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "right leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;discipline;doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;discipline;doublewhirl " ..target.. " left leg expend right leg;sizeup " ..target.. ";assess " ..target

 
--Anti Parry

--Anti Parry
elseif not tAffs.numbedleftarm and ataxiaTemp.parriedLimb ~= "left arm" and ataxiaTemp.parriedLimb == "left leg" or ataxiaTemp.parriedLimb == "right leg" or ataxiaTemp.parriedLimb == "head" then
  if ataxia.vitals.class < 1 then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon track " ..target.. " ;falcon slay " ..target.. ";doublewhirl " ..target.. " right arm right arm;sizeup " ..target.. ";assess " ..target
 
  elseif ataxia.vitals.class >= 2 then
    if ataxiaTemp.parriedLimb ~= "torso" then 
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " torso expend left arm expend;sizeup " ..target.. ";assess " ..target
    elseif m2prepped_rightleg == true and mprepped_leftleg == false and mprepped_rightleg == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend right leg;sizeup " ..target.. ";assess " ..target
    elseif m2prepped_leftleg == true and mprepped_leftleg == false and mprepped_rightleg == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend left leg;sizeup " ..target.. ";assess " ..target
    elseif m2prepped_head == true and mprepped_leftleg == false and mprepped_rightleg == false and mpreppedhead == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend head;sizeup " ..target.. ";assess " ..target
    elseif mprepped_leftleg == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend left leg;sizeup " ..target.. ";assess " ..target
    elseif mprepped_rightleg == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend right leg;sizeup " ..target.. ";assess " ..target
    elseif mprepped_head == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend head;sizeup " ..target.. ";assess " ..target
    else 
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend torso;sizeup " ..target.. ";assess " ..target
  
    end
  end

  
--One Prepped | Now the other
elseif m2prepped_rightleg == true and mprepped_rightleg == false and mprepped_leftleg == true then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " left arm right leg;assess " ..target
elseif m2prepped_rightleg == true and mprepped_rightleg == false and mprepped_leftleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " left leg right leg;assess " ..target

  --if doublewhirl on left leg is going to break than do one whirl and hit another limb
elseif m2prepped_leftleg == true and mprepped_leftleg == false and mprepped_rightleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " left leg right leg;assess " ..target
  --if doublewhirl on left leg is going to break than do one whirl and hit another limb
elseif m2prepped_leftleg == true and mprepped_leftleg == false and mprepped_rightleg == true then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " left leg left arm;assess " ..target


-- Prep
elseif mprepped_leftleg == false and m2prepped_leftleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " left leg left leg;sizeup " ..target.. ";assess " ..target

elseif mprepped_rightleg == false and m2prepped_rightleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " right leg right leg;sizeup " ..target.. ";assess " ..target

else
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " ;sizeup " ..target.. ";assess " ..target

end

if table.contains(ataxia.playersHere, target) then
	if not engaged then
		send("queue addclear freestand " ..atk.. ";engage " ..target)
	else
	send("queue addclear freestand " ..atk)
	end
end
end

function dwb_groupsetup()
local atk = combatQueue()
getLockingAffliction()
checkTargetLocks()

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
ataxiaTemp.tarTumble = ataxiaTemp.tarTumble or false
tarpreapply = tarpreapply or false
tAffs.bleed = tAffs.bleed or 0
mstardamage = DWBWhirlDamage
flaildamage = DWBWhirlDamage
mstar2damage = DWBWhirlDamage + DWBWhirlDamage
tarlimb = tarlimb or "right arm"
tarlimb2 = tarlimb2 or "none"
ataxiaTemp.parriedLimb = ataxiaTemp.parriedLimb or "none"
wieldweapons = wieldweapons or "morningstars"

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 35 then
use_bisect = true else
use_bisect = false
end

if lb[target].hits["head"] + mstardamage >= 99.9 and not tAffs.damagedhead then 
mprepped_head = true else
mprepped_head = false
end
if lb[target].hits["head"] + flaildamage >= 99.9 and not tAffs.damagedhead then 
fprepped_head = true else
fprepped_head = false
end

if lb[target].hits["torso"] + mstardamage >= 99.9 and not tAffs.damagedtorso then 
mprepped_torso = true else
mprepped_torso = false
end
if lb[target].hits["torso"] + flaildamage >= 99.9 and not tAffs.damagedtorso then 
fprepped_torso = true else
fprepped_torso = false
end

if lb[target].hits["left leg"] + mstardamage >= 99.9 and not tAffs.damagedleftleg then 
mprepped_leftleg = true else
mprepped_leftleg = false
end
if lb[target].hits["left leg"] + flaildamage >= 99.9 and not tAffs.damagedleftleg then 
fprepped_leftleg = true else
fprepped_leftleg = false
end

if lb[target].hits["right leg"] + mstardamage >= 99.9 and not tAffs.damagedrightleg then 
mprepped_rightleg = true else
mprepped_rightleg = false
end
if lb[target].hits["right leg"] + flaildamage >= 99.9 and not tAffs.damagedrightleg then 
fprepped_rightleg = true else
fprepped_rightleg = false
end

if lb[target].hits["right arm"] + mstardamage >= 99.9 and not tAffs.damagedrightarm then 
mprepped_rightarm = true else
mprepped_rightarm = false
end
if lb[target].hits["right arm"] + flaildamage >= 99.9 and not tAffs.damagedrightarm then 
fprepped_rightarm = true else
fprepped_rightarm = false
end

if lb[target].hits["left arm"] + mstardamage >= 99.9 and not tAffs.damagedleftarm then 
mprepped_leftarm = true else
mprepped_leftarm = false
end
if lb[target].hits["left arm"] + flaildamage >= 99.9 and not tAffs.damagedleftarm then 
fprepped_leftarm = true else
fprepped_leftarm = false
end

--Double Whirl Formula
-----------------
-----------------
if lb[target].hits["head"] + mstar2damage >= 99.9 and not tAffs.damagedhead then 
m2prepped_head = true else
m2prepped_head = false
end
if lb[target].hits["head"] + mstar2damage >= 99.9 and not tAffs.damagedhead then 
f2prepped_head = true else
f2prepped_head = false
end

if lb[target].hits["torso"] + mstar2damage >= 99.9 and not tAffs.damagedtorso then 
m2prepped_torso = true else
m2prepped_torso = false
end
if lb[target].hits["torso"] + mstar2damage >= 99.9 and not tAffs.damagedtorso then 
f2prepped_torso = true else
f2prepped_torso = false
end

if lb[target].hits["left arm"] + mstar2damage >= 99.9 and not tAffs.damagedleftarm then 
m2prepped_leftarm = true else
m2prepped_leftarm = false
end
if lb[target].hits["left arm"] + mstar2damage >= 99.9 and not tAffs.damagedleftarm then 
f2prepped_leftarm = true else
f2prepped_leftarm = false
end

if lb[target].hits["right arm"] + mstar2damage >= 99.9 and not tAffs.damagedrightarm then 
m2prepped_rightarm = true else
m2prepped_rightarm = false
end
if lb[target].hits["right arm"] + mstar2damage >= 99.9 and not tAffs.damagedrightarm then 
f2prepped_rightarm = true else
f2prepped_rightarm = false
end

if lb[target].hits["right leg"] + mstar2damage >= 99.9 and not tAffs.damagedrightleg then 
m2prepped_rightleg = true else
m2prepped_rightleg = false
end
if lb[target].hits["right leg"] + mstar2damage >= 99.9 and not tAffs.damagedrightleg then 
f2prepped_rightleg = true else
f2prepped_rightleg = false
end

if lb[target].hits["left leg"] + mstar2damage >= 99.9 and not tAffs.damagedleftleg then 
m2prepped_leftleg = true else
m2prepped_leftleg = false
end
if lb[target].hits["left leg"] + mstar2damage >= 99.9 and not tAffs.damagedleftleg then 
f2prepped_leftleg = true else
f2prepped_leftleg = false
end


--Priority of Limb
if mprepped_leftleg == false then
tarlimb = "left leg"
elseif mprepped_rightleg == false then
tarlimb = "right leg"
else
tarlimb = "torso"
end


--ATTACKKKKK
 
-- Bisect
if myinstantcath == true then
  atk = atk.. "touch shield"
elseif not tAffs.shield and use_bisect == true then
  atk = atk.. "sizeup " ..target.. ";wield bastard;bisect " ..target
-- Pulp
elseif not tAffs.shield and (tAffs.concussion or lb[target].hits["head"] >= 200 or ataxiaTemp.fractures.skullfractures >= 5) and tAffs.prone then
  atk = atk.. "wield left flail343168;wield right flail408566;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";sizeup " ..target.. ";pulp " ..target.. ";assess " ..target

--Raze
elseif tAffs.rebounding or tAffs.shield then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon track " ..target.. " ;falcon slay " ..target.. ";fracture " ..target.. "  ;assess " ..target.. ";sizeup " ..target

--Torso Damage
elseif tAffs.prone and ataxia.vitals.class == 1 and not tAffs.numbedrightarm then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " torso right arm expend;sizeup " ..target.. ";assess " ..target
elseif tAffs.prone and ataxia.vitals.class >= 2 and not tAffs.numbedrightarm then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " torso expend right arm expend;sizeup " ..target.. ";assess " ..target
elseif tAffs.prone and ataxia.vitals.class >= 3 then
  atk = atk.. "wield left flail343168;wield right flail408566;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";assault " ..target.. " torso;sizeup " ..target.. ";assess " ..target
elseif ataxia.vitals.class >= 2 and ataxiaTemp.fractures.crackedribs >= 1 then
  atk = atk.. "wield left flail343168;wield right flail408566;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " torso expend torso expend;sizeup " ..target.. ";assess " ..target
elseif ataxia.vitals.class < 2 and ataxiaTemp.fractures.crackedribs >= 1 then
  atk = atk.. "wield left flail343168;wield right flail408566;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
elseif ataxia.vitals.class < 2 and tAffs.prone then
  atk = atk.. "wield left flail343168;wield right flail408566;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target

--Pre-Apply Counter
elseif tarpreapply == true then
  atk = atk.. "wield left flail343168;wield right flail408566;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " torso expend torso ;sizeup " ..target.. ";assess " ..target

-- Double Break
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and tAffs.numbedleftarm and ataxia.vitals.class == 8 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "right leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " left leg expend right leg;sizeup " ..target.. ";assess " ..target

elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and tAffs.numbedleftarm and ataxia.vitals.class == 8 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;discipline;doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "right leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;discipline;doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;discipline;doublewhirl " ..target.. " left leg expend right leg;sizeup " ..target.. ";assess " ..target

 


--Anti Parry
elseif not tAffs.numbedleftarm and ataxiaTemp.parriedLimb ~= "left arm" and ataxiaTemp.parriedLimb == "left leg" or ataxiaTemp.parriedLimb == "right leg" or ataxiaTemp.parriedLimb == "head" then
  if ataxia.vitals.class < 1 then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon track " ..target.. " ;falcon slay " ..target.. ";doublewhirl " ..target.. " right arm right arm;sizeup " ..target.. ";assess " ..target
 
  elseif ataxia.vitals.class >= 2 then
    if ataxiaTemp.parriedLimb ~= "torso" then 
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " torso expend left arm expend;sizeup " ..target.. ";assess " ..target
    elseif m2prepped_rightleg == true and mprepped_leftleg == false and mprepped_rightleg == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend right leg;sizeup " ..target.. ";assess " ..target
    elseif m2prepped_leftleg == true and mprepped_leftleg == false and mprepped_rightleg == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend left leg;sizeup " ..target.. ";assess " ..target
    elseif m2prepped_head == true and mprepped_leftleg == false and mprepped_rightleg == false and mpreppedhead == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend head;sizeup " ..target.. ";assess " ..target
    elseif mprepped_leftleg == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend left leg;sizeup " ..target.. ";assess " ..target
    elseif mprepped_rightleg == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend right leg;sizeup " ..target.. ";assess " ..target
    elseif mprepped_head == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend head;sizeup " ..target.. ";assess " ..target
    else 
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;falcon slay " ..target.. ";doublewhirl " ..target.. " left arm expend torso;sizeup " ..target.. ";assess " ..target
  
    end
  end

  
--One Prepped | Now the other
elseif m2prepped_rightleg == true and mprepped_rightleg == false and mprepped_leftleg == true then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " left arm right leg;assess " ..target
elseif m2prepped_rightleg == true and mprepped_rightleg == false and mprepped_leftleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " left leg right leg;assess " ..target

  --if doublewhirl on left leg is going to break than do one whirl and hit another limb
elseif m2prepped_leftleg == true and mprepped_leftleg == false and mprepped_rightleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " left leg right leg;assess " ..target
  --if doublewhirl on left leg is going to break than do one whirl and hit another limb
elseif m2prepped_leftleg == true and mprepped_leftleg == false and mprepped_rightleg == true then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;sizeup " ..target.. ";doublewhirl " ..target.. " left leg left arm;assess " ..target


-- Prep
elseif mprepped_leftleg == false and m2prepped_leftleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " left leg left leg;sizeup " ..target.. ";assess " ..target

elseif mprepped_rightleg == false and m2prepped_rightleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " right leg right leg;sizeup " ..target.. ";assess " ..target

else
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;empower priority set isaz tiwaz wunjo;doublewhirl " ..target.. " ;sizeup " ..target.. ";assess " ..target

end
  

if table.contains(ataxia.playersHere, target) then
	if not engaged then
		send("queue addclear freestand " ..atk.. ";engage " ..target)
	else
	send("queue addclear freestand " ..atk)
	end
else
expandAlias("nt")
send("queue addclear freestand " ..atk)
end
end

