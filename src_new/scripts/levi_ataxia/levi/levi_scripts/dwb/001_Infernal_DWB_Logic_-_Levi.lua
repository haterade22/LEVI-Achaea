--[[mudlet
type: script
name: Infernal DWB Logic - Levi
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- INFERNAL
- DWB
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

DWBWhirlDamage = DWBWhirlDamage or 0

function infernaldwbviviprio()

toppression = toppression or "exploit"

if mprepped_leftleg == true and mprepped_rightleg == true and mprepped_leftarm == true and mprepped_rightarm == true and mprepped_head == true then
toppression = "torture"
elseif mprepped_leftleg == true and mprepped_rightleg == true and mprepped_leftarm == true and mprepped_rightarm == true then
toppression = "torture"
elseif mprepped_leftarm == true and mprepped_rightarm == true then
toppression = "torture"
elseif mprepped_leftleg == true and mprepped_rightleg == true then
toppression = "torture"

elseif tAffs.haemophilia and tAffs.healthleech then
toppression = "exploit"
elseif tAffs.healthleech and not tAffs.haemophilia then
toppression = "torture"
elseif not tAffs.healthleech and tAffs.weariness then
toppression = "torment"
elseif not tAffs.weariness then 
toppression = "exploit"
end

end



function idwb_pocketleg()
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


function idwb_skullfractures()
infernaldwbviviprio()
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
flail2damage = DWBWhirlDamage + DWBWhirlDamage

tarlimb = tarlimb or "right arm"
tarlimb2 = tarlimb2 or "none"
if ataxiaTemp.parriedLimb == nil then ataxiaTemp.parriedLimb = "none" end
ataxiaTemp.parriedLimb = ataxiaTemp.parriedLimb or "none"
wieldweapons = wieldweapons or "morningstars"

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 30 then
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
if lb[target].hits["head"] + flail2damage >= 99.9 and not tAffs.damagedhead then 
f2prepped_head = true else
f2prepped_head = false
end

if lb[target].hits["torso"] + mstar2damage >= 99.9 and not tAffs.damagedtorso then 
m2prepped_torso = true else
m2prepped_torso = false
end
if lb[target].hits["torso"] + flail2damage >= 99.9 and not tAffs.damagedtorso then 
f2prepped_torso = true else
f2prepped_torso = false
end

if lb[target].hits["left arm"] + mstar2damage >= 99.9 and not tAffs.damagedleftarm then 
m2prepped_leftarm = true else
m2prepped_leftarm = false
end
if lb[target].hits["left arm"] + flail2damage >= 99.9 and not tAffs.damagedleftarm then 
f2prepped_leftarm = true else
f2prepped_leftarm = false
end

if lb[target].hits["right arm"] + mstar2damage >= 99.9 and not tAffs.damagedrightarm then 
m2prepped_rightarm = true else
m2prepped_rightarm = false
end
if lb[target].hits["right arm"] + flail2damage >= 99.9 and not tAffs.damagedrightarm then 
f2prepped_rightarm = true else
f2prepped_rightarm = false
end

if lb[target].hits["right leg"] + mstar2damage >= 99.9 and not tAffs.damagedrightleg then 
m2prepped_rightleg = true else
m2prepped_rightleg = false
end
if lb[target].hits["right leg"] + flail2damage >= 99.9 and not tAffs.damagedrightleg then 
f2prepped_rightleg = true else
f2prepped_rightleg = false
end

if lb[target].hits["left leg"] + mstar2damage >= 99.9 and not tAffs.damagedleftleg then 
m2prepped_leftleg = true else
m2prepped_leftleg = false
end
if lb[target].hits["left leg"] + flail2damage >= 99.9 and not tAffs.damagedleftleg then 
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

if (tAffs.damagedleftleg or tAffs.brokenleftleg and tAffs.damagedrightleg or tAffs.brokenrightleg and tAffs.damagedleftarm or tAffs.brokenleftarm and tAffs.damagedrightarm or tAffs.brokenrightarm) then
tvivsect = true
else 
tvivisect = false
end

--ATTACKKKKK
 
-- Bisect

if myinstantcath == true then
  atk = atk.." touch shield"

-- Vivisect --
elseif tvivisect == true and ataxiaNDB.players[target].city ~= "Mhaldor" then
  atk = atk.. "dismount;vivisect " ..target
elseif tvivisect == true and ataxiaNDB.players[target].city == "Mhaldor" then
  send("say Vivisect")

elseif use_bisect == true then
  atk = atk.. "wield bastard;quash " ..target.. ";arc;sizeup " ..target.. ";assess " ..target

-- Pulp

elseif not tAffs.shield and (tAffs.concussion or lb[target].hits["head"] >= 200 or ataxiaTemp.fractures.skullfractures >= 5) and tAffs.prone then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";pulp " ..target.. " ;engage " ..target.. ";sizeup " ..target.. " ;assess " ..target

--Raze
elseif tAffs.rebounding or tAffs.shield then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena track " ..target.. ";hyena slay " ..target.. ";fracture " ..target.. " ;assess " ..target.. " ;sizeup " ..target

-- Skull Fractures --
elseif tAffs.prone and ataxia.vitals.class >= 2 then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head expend head expend;assess " ..target.." ;sizeup " ..target
elseif tAffs.prone and ataxia.vitals.class < 2 then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target


-- Break Sequence --

--Dont Double Break if they Pre-Apply
elseif tarpreapply == true then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " torso torso expend;assess " ..target.. " ;engage " ..target

--Doublebreak with or without clumsiness (Add Discipline)
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and tAffs.numbedleftarm and ataxia.vitals.class == 8 then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target.. " ;engage " ..target
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "right leg" then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target.. " ;engage " ..target
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left leg expend right leg;sizeup " ..target.. ";assess " ..target.. " ;engage " ..target

elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and tAffs.numbedleftarm and ataxia.vitals.class == 8 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";discipline;doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "right leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";discipline;doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";discipline;doublewhirl " ..target.. " left leg expend right leg;sizeup " ..target.. ";assess " ..target

 

--Anti Parry
elseif not tAffs.numbedleftarm and ataxiaTemp.parriedLimb ~= "left arm" and ataxiaTemp.parriedLimb == "left leg" or ataxiaTemp.parriedLimb == "right leg" or ataxiaTemp.parriedLimb == "head" then
  if ataxia.vitals.class < 1 then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena track " ..target.. " ;hyena slay " ..target.. ";doublewhirl " ..target.. " left arm left arm;sizeup " ..target.. ";assess " ..target
 
  elseif ataxia.vitals.class > 1 then
    if m2prepped_rightleg == true and mprepped_leftleg == false and mprepped_rightleg == false then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend right leg;sizeup " ..target.. ";assess " ..target
    elseif m2prepped_leftleg == true and mprepped_leftleg == false and mprepped_rightleg == false then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend left leg;sizeup " ..target.. ";assess " ..target
    elseif m2prepped_head == true and mprepped_leftleg == false and mprepped_rightleg == false and mpreppedhead == false then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend head;sizeup " ..target.. ";assess " ..target
    elseif mprepped_leftleg == false then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend left leg;sizeup " ..target.. ";assess " ..target
    elseif mprepped_rightleg == false then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend right leg;sizeup " ..target.. ";assess " ..target
    elseif mprepped_head == false then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend head;sizeup " ..target.. ";assess " ..target
    else 
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend torso;sizeup " ..target.. ";assess " ..target
  
    end
  end
  
--Prep Head\ Left Leg\ Right Leg
elseif m2prepped_rightleg == true and mprepped_head == true and mprepped_rightleg == false and mprepped_leftleg == true then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " torso right leg;assess " ..target
  --if doublewhirl on left leg is going to break than do one whirl and hit another limb
elseif m2prepped_leftleg == true and mprepped_leftleg == false and mprepped_rightleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " left leg right leg;assess " ..target

elseif m2prepped_head == true and mprepped_head == false and mprepped_rightleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " head right leg;assess " ..target
  --if doublewhirl on left leg is going to break than do one whirl and hit another limb
elseif m2prepped_leftleg == true and mprepped_leftleg == false and mprepped_rightleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " left leg right leg;assess " ..target

elseif mprepped_head == false and m2prepped_head == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
elseif mprepped_leftleg == false and m2prepped_leftleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left leg left leg;sizeup " ..target.. ";assess " ..target
elseif mprepped_rightleg == false and m2prepped_rightleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right leg right leg;sizeup " ..target.. ";assess " ..target
else
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " ;sizeup " ..target.. ";assess " ..target
end

if table.contains(ataxia.playersHere, target) then
if falconattack == true then
  if not engaged then
    send("queue addclear freestand " ..atk.. ";engage " ..target)
  else
    send("queue addclear freestand " ..atk)
  end
elseif falconattack == false then
 if not engaged then
    send("queue addclear freestand " ..atk.. ";hyena slay " ..target.." ;engage " ..target)
  else
    send("queue addclear freestand " ..atk.. ";hyena slay " ..target)
  end
end
else
  expandAlias("nt")
  send("queue addclear freestand " ..atk)

end
end



----------------------------------------------------------------------------------------
function idwb_assaultheadpulpsetup()
infernaldwbviviprio()
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
flail2damage = DWBWhirlDamage + DWBWhirlDamage

tarlimb = tarlimb or "right arm"
tarlimb2 = tarlimb2 or "none"
if ataxiaTemp.parriedLimb == nil then ataxiaTemp.parriedLimb = "none" end
ataxiaTemp.parriedLimb = ataxiaTemp.parriedLimb or "none"
wieldweapons = wieldweapons or "morningstars"

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 30 then
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
if lb[target].hits["head"] + flail2damage >= 99.9 and not tAffs.damagedhead then 
f2prepped_head = true else
f2prepped_head = false
end

if lb[target].hits["torso"] + mstar2damage >= 99.9 and not tAffs.damagedtorso then 
m2prepped_torso = true else
m2prepped_torso = false
end
if lb[target].hits["torso"] + flail2damage >= 99.9 and not tAffs.damagedtorso then 
f2prepped_torso = true else
f2prepped_torso = false
end

if lb[target].hits["left arm"] + mstar2damage >= 99.9 and not tAffs.damagedleftarm then 
m2prepped_leftarm = true else
m2prepped_leftarm = false
end
if lb[target].hits["left arm"] + flail2damage >= 99.9 and not tAffs.damagedleftarm then 
f2prepped_leftarm = true else
f2prepped_leftarm = false
end

if lb[target].hits["right arm"] + mstar2damage >= 99.9 and not tAffs.damagedrightarm then 
m2prepped_rightarm = true else
m2prepped_rightarm = false
end
if lb[target].hits["right arm"] + flail2damage >= 99.9 and not tAffs.damagedrightarm then 
f2prepped_rightarm = true else
f2prepped_rightarm = false
end

if lb[target].hits["right leg"] + mstar2damage >= 99.9 and not tAffs.damagedrightleg then 
m2prepped_rightleg = true else
m2prepped_rightleg = false
end
if lb[target].hits["right leg"] + flail2damage >= 99.9 and not tAffs.damagedrightleg then 
f2prepped_rightleg = true else
f2prepped_rightleg = false
end

if lb[target].hits["left leg"] + mstar2damage >= 99.9 and not tAffs.damagedleftleg then 
m2prepped_leftleg = true else
m2prepped_leftleg = false
end
if lb[target].hits["left leg"] + flail2damage >= 99.9 and not tAffs.damagedleftleg then 
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

if (tAffs.damagedleftleg or tAffs.brokenleftleg and tAffs.damagedrightleg or tAffs.brokenrightleg and tAffs.damagedleftarm or tAffs.brokenleftarm and tAffs.damagedrightarm or tAffs.brokenrightarm) then
tvivsect = true
else 
tvivisect = false
end

--ATTACKKKKK
 
-- Bisect

if myinstantcath == true then
  atk = atk.." touch shield"

-- Vivisect --
elseif tvivisect == true and ataxiaNDB.players[target].city ~= "Mhaldor" then
  atk = atk.. "dismount;vivisect " ..target
elseif tvivisect == true and ataxiaNDB.players[target].city == "Mhaldor" then
  send("say Vivisect")

elseif use_bisect == true then
  atk = atk.. "wield bastard;quash " ..target.. ";arc;sizeup " ..target.. ";assess " ..target

-- Pulp
elseif not tAffs.shield and (tAffs.concussion or lb[target].hits["head"] >= 200 or ataxiaTemp.fractures.skullfractures >= 4) and ataxiaNDB.players[target].city ~= "Mhaldor" and tAffs.prone then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";pulp " ..target.. ";assess " ..target


--Raze
elseif tAffs.rebounding or tAffs.shield then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena track " ..target.. ";hyena slay " ..target.. ";sizeup " ..target.. ";fracture " ..target.. " ;engage " ..target.. " ;assess " ..target

--Assault Head
elseif tAffs.prone and (tAffs.damagedhead or lb[target].hits["head"] >= 100) and ataxia.vitals.class >= 7 then
  atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";sizeup " ..target.. ";assault " ..target.. " head;assess " ..target
elseif tAffs.prone and mprepped_head == true and ataxia.vitals.class < 7 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " head head;assess " ..target
  
-- Skull Fractures
elseif tAffs.prone and (tAffs.damagedhead or lb[target].hits["head"] >= 100) and ataxia.vitals.class < 7 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " head head;assess " ..target
elseif tAffs.prone and (tAffs.mildtrauma or lb[target].hits["torso"] >= 100) and ataxia.vitals.class < 7 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " torso torso;assess " ..target


--Beat Head

elseif tAffs.prone and ataxia.vitals.class >= 2 and (lb[target].hits["head"] >= 100 or tAffs.damagedhead) or mprepped_head == true then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " head expend head expend;assess " ..target
elseif tAffs.prone and ataxia.vitals.class < 2 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " head head;assess " ..target



-- Break Sequence
elseif tarpreapply == true then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " torso torso expend;assess " ..target

elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and tAffs.numbedleftarm and ataxia.vitals.class == 8 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "right leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left leg expend right leg;sizeup " ..target.. ";assess " ..target

elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and tAffs.numbedleftarm and ataxia.vitals.class == 8 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";discipline;doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "right leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";discipline;doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";discipline;doublewhirl " ..target.. " left leg expend right leg;sizeup " ..target.. ";assess " ..target

 
--Anti Parry
elseif not tAffs.numbedleftarm and ataxiaTemp.parriedLimb ~= "left arm" and ataxiaTemp.parriedLimb == "left leg" or ataxiaTemp.parriedLimb == "right leg" or ataxiaTemp.parriedLimb == "head" then
  if ataxia.vitals.class < 1 then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena track " ..target.. " ;hyena slay " ..target.. ";doublewhirl " ..target.. " left arm left arm;sizeup " ..target.. ";assess " ..target
 
  elseif ataxia.vitals.class > 1 then
    if m2prepped_rightleg == true and mprepped_leftleg == false and mprepped_rightleg == false then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend right leg;sizeup " ..target.. ";assess " ..target
    elseif m2prepped_leftleg == true and mprepped_leftleg == false and mprepped_rightleg == false then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend left leg;sizeup " ..target.. ";assess " ..target
    elseif m2prepped_head == true and mprepped_leftleg == false and mprepped_rightleg == false and mpreppedhead == false then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend head;sizeup " ..target.. ";assess " ..target
    elseif mprepped_leftleg == false then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend left leg;sizeup " ..target.. ";assess " ..target
    elseif mprepped_rightleg == false then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend right leg;sizeup " ..target.. ";assess " ..target
    elseif mprepped_head == false then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend head;sizeup " ..target.. ";assess " ..target
    else 
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend torso;sizeup " ..target.. ";assess " ..target
  
    end
  end
  
--Prep Head\ Left Leg\ Right Leg
  --If doublewhirl on head is going to break than do one whirl and hit another limb
elseif m2prepped_rightleg == true and mprepped_head == true and mprepped_rightleg == false and mprepped_leftleg == true then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso right leg;sizeup " ..target.. ";assess " ..target
  --if doublewhirl on left leg is going to break than do one whirl and hit another limb
elseif m2prepped_leftleg == true and mprepped_leftleg == false and mprepped_rightleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left leg right leg;sizeup " ..target.. ";assess " ..target

elseif m2prepped_head == true and mprepped_head == false and mprepped_rightleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head right leg;sizeup " ..target.. ";assess " ..target
  --if doublewhirl on left leg is going to break than do one whirl and hit another limb
elseif m2prepped_leftleg == true and mprepped_leftleg == false and mprepped_rightleg == true then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left leg left arm;sizeup " ..target.. ";assess " ..target

elseif mprepped_head == false and m2prepped_head == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
elseif mprepped_leftleg == false and m2prepped_leftleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left leg left leg;sizeup " ..target.. ";assess " ..target
elseif mprepped_rightleg == false and m2prepped_rightleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right leg right leg;sizeup " ..target.. ";assess " ..target
else
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " ;sizeup " ..target.. ";assess " ..target
end


if table.contains(ataxia.playersHere, target) then
if falconattack == true then
  if not engaged then
    send("queue addclear freestand " ..atk.. ";engage " ..target)
  else
    send("queue addclear freestand " ..atk)
  end
elseif falconattack == false then
 if not engaged then
    send("queue addclear freestand " ..atk.. ";hyena slay " ..target.." ;engage " ..target)
  else
    send("queue addclear freestand " ..atk.. ";hyena slay " ..target)
  end
end
else
  expandAlias("nt")
  send("queue addclear freestand " ..atk)

end
end



function idwb_torsodamage()
infernaldwbviviprio()
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
flail2damage = DWBWhirlDamage + DWBWhirlDamage

tarlimb = tarlimb or "right arm"
tarlimb2 = tarlimb2 or "none"
if ataxiaTemp.parriedLimb == nil then ataxiaTemp.parriedLimb = "none" end
ataxiaTemp.parriedLimb = ataxiaTemp.parriedLimb or "none"
wieldweapons = wieldweapons or "morningstars"

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 30 then
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
if lb[target].hits["head"] + flail2damage >= 99.9 and not tAffs.damagedhead then 
f2prepped_head = true else
f2prepped_head = false
end

if lb[target].hits["torso"] + mstar2damage >= 99.9 and not tAffs.damagedtorso then 
m2prepped_torso = true else
m2prepped_torso = false
end
if lb[target].hits["torso"] + flail2damage >= 99.9 and not tAffs.damagedtorso then 
f2prepped_torso = true else
f2prepped_torso = false
end

if lb[target].hits["left arm"] + mstar2damage >= 99.9 and not tAffs.damagedleftarm then 
m2prepped_leftarm = true else
m2prepped_leftarm = false
end
if lb[target].hits["left arm"] + flail2damage >= 99.9 and not tAffs.damagedleftarm then 
f2prepped_leftarm = true else
f2prepped_leftarm = false
end

if lb[target].hits["right arm"] + mstar2damage >= 99.9 and not tAffs.damagedrightarm then 
m2prepped_rightarm = true else
m2prepped_rightarm = false
end
if lb[target].hits["right arm"] + flail2damage >= 99.9 and not tAffs.damagedrightarm then 
f2prepped_rightarm = true else
f2prepped_rightarm = false
end

if lb[target].hits["right leg"] + mstar2damage >= 99.9 and not tAffs.damagedrightleg then 
m2prepped_rightleg = true else
m2prepped_rightleg = false
end
if lb[target].hits["right leg"] + flail2damage >= 99.9 and not tAffs.damagedrightleg then 
f2prepped_rightleg = true else
f2prepped_rightleg = false
end

if lb[target].hits["left leg"] + mstar2damage >= 99.9 and not tAffs.damagedleftleg then 
m2prepped_leftleg = true else
m2prepped_leftleg = false
end
if lb[target].hits["left leg"] + flail2damage >= 99.9 and not tAffs.damagedleftleg then 
f2prepped_leftleg = true else
f2prepped_leftleg = false
end


if (tAffs.damagedleftleg or tAffs.brokenleftleg and tAffs.damagedrightleg or tAffs.brokenrightleg and tAffs.damagedleftarm or tAffs.brokenleftarm and tAffs.damagedrightarm or tAffs.brokenrightarm) then
tvivsect = true
else 
tvivisect = false
end

--ATTACKKKKK
 
-- Bisect

if myinstantcath == true then
  atk = atk.." touch shield"

-- Vivisect --
elseif tvivisect == true and ataxiaNDB.players[target].city ~= "Mhaldor" then
  atk = atk.. "dismount;vivisect " ..target
elseif tvivisect == true and ataxiaNDB.players[target].city == "Mhaldor" then
  send("say Vivisect")

elseif use_bisect == true then
  atk = atk.. "wield bastard;quash " ..target.. ";arc;sizeup " ..target.. ";assess " ..target

-- Pulp
elseif not tAffs.shield and (tAffs.concussion or lb[target].hits["head"] >= 200 or ataxiaTemp.fractures.skullfractures >= 5) and tAffs.prone then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";pulp " ..target.. ";assess " ..target

--Raze
elseif tAffs.rebounding or tAffs.shield then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena track " ..target.. " ;hyena slay " ..target.. ";sizeup " ..target.. ";fracture " ..target.. " ;engage " ..target.. " ;assess " ..target

--Torso Damage
elseif tAffs.prone and ataxia.vitals.class >= 3 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";sizeup " ..target.. ";assault " ..target.. " torso;assess " ..target
elseif ataxia.vitals.class >= 2 and ataxiaTemp.fractures.crackedribs >= 1 and ataxiaTemp.parriedLimb ~= "torso" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";sizeup " ..target.. ";doublewhirl " ..target.. " torso expend torso expend;assess " ..target
elseif ataxia.vitals.class < 2 and ataxiaTemp.fractures.crackedribs >= 1 and ataxiaTemp.parriedLimb ~= "torso" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";sizeup " ..target.. ";doublewhirl " ..target.. " torso torso;assess " ..target
elseif ataxia.vitals.class < 2 and tAffs.prone then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";sizeup " ..target.. ";doublewhirl " ..target.. " torso torso;assess " ..target
elseif ataxia.vitals.class < 2 and lb[target].hits["head"]>= 100 and ataxiaTemp.parriedLimb ~= "torso" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";sizeup " ..target.. ";doublewhirl " ..target.. " torso torso;assess " ..target

--Pre-Apply Counter
elseif tarpreapply == true then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " torso expend torso ;assess " ..target

-- Double Break
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and tAffs.numbedleftarm and ataxia.vitals.class == 8 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "right leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left leg expend right leg;sizeup " ..target.. ";assess " ..target

elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and tAffs.numbedleftarm and ataxia.vitals.class == 8 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";discipline;doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "right leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";discipline;doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";discipline;doublewhirl " ..target.. " left leg expend right leg;sizeup " ..target.. ";assess " ..target

 
--Anti Parry

elseif not tAffs.numbedleftarm and ataxiaTemp.parriedLimb ~= "left arm" and ataxiaTemp.parriedLimb == "left leg" or ataxiaTemp.parriedLimb == "right leg" or ataxiaTemp.parriedLimb == "torso" then
  if ataxia.vitals.class < 1 then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena track " ..target.. " ;hyena slay " ..target.. ";doublewhirl " ..target.. " left arm left arm;sizeup " ..target.. ";assess " ..target
 
  elseif ataxia.vitals.class > 1 then
    if m2prepped_rightleg == true and mprepped_leftleg == false and mprepped_rightleg == false then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend right leg;sizeup " ..target.. ";assess " ..target
    elseif m2prepped_leftleg == true and mprepped_leftleg == false and mprepped_rightleg == false then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend left leg;sizeup " ..target.. ";assess " ..target
    elseif m2prepped_head == true and mprepped_leftleg == false and mprepped_rightleg == false and mpreppedhead == false then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend head;sizeup " ..target.. ";assess " ..target
    elseif mprepped_leftleg == false then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend left leg;sizeup " ..target.. ";assess " ..target
    elseif mprepped_rightleg == false then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend right leg;sizeup " ..target.. ";assess " ..target
    else 
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend torso;sizeup " ..target.. ";assess " ..target
  
    end
  end
  
--One Prepped | Now the other
elseif m2prepped_rightleg == true and mprepped_rightleg == false and mprepped_leftleg == true then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " left arm right leg;assess " ..target
  --if doublewhirl on left leg is going to break than do one whirl and hit another limb
elseif m2prepped_leftleg == true and mprepped_leftleg == false and mprepped_rightleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " left leg right leg;assess " ..target
elseif m2prepped_leftleg == true and mprepped_leftleg == false and mprepped_rightleg == true then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " left leg left arm;assess " ..target


-- Prep
elseif mprepped_leftleg == false and m2prepped_leftleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left leg left leg;sizeup " ..target.. ";assess " ..target

elseif mprepped_rightleg == false and m2prepped_rightleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right leg right leg;sizeup " ..target.. ";assess " ..target

else
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " ;sizeup " ..target.. ";assess " ..target

end

if table.contains(ataxia.playersHere, target) then
if falconattack == true then
  if not engaged then
    send("queue addclear freestand " ..atk.. ";engage " ..target)
  else
    send("queue addclear freestand " ..atk)
  end
elseif falconattack == false then
 if not engaged then
    send("queue addclear freestand " ..atk.. ";hyena slay " ..target.." ;engage " ..target)
  else
    send("queue addclear freestand " ..atk.. ";hyena slay " ..target)
  end
end
else
  expandAlias("nt")
  send("queue addclear freestand " ..atk)

end
end


-------------USE BELOW FOR GROUP COMBAT and TO MELT MOFOS--------------------
function idwb_damageroute()
infernaldwbviviprio()
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
flail2damage = DWBWhirlDamage + DWBWhirlDamage

tarlimb = tarlimb or "right arm"
tarlimb2 = tarlimb2 or "none"
if ataxiaTemp.parriedLimb == nil then ataxiaTemp.parriedLimb = "none" end
ataxiaTemp.parriedLimb = ataxiaTemp.parriedLimb or "none"
wieldweapons = wieldweapons or "morningstars"

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 30 then
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
if lb[target].hits["head"] + flail2damage >= 99.9 and not tAffs.damagedhead then 
f2prepped_head = true else
f2prepped_head = false
end

if lb[target].hits["torso"] + mstar2damage >= 99.9 and not tAffs.damagedtorso then 
m2prepped_torso = true else
m2prepped_torso = false
end
if lb[target].hits["torso"] + flail2damage >= 99.9 and not tAffs.damagedtorso then 
f2prepped_torso = true else
f2prepped_torso = false
end

if lb[target].hits["left arm"] + mstar2damage >= 99.9 and not tAffs.damagedleftarm then 
m2prepped_leftarm = true else
m2prepped_leftarm = false
end
if lb[target].hits["left arm"] + flail2damage >= 99.9 and not tAffs.damagedleftarm then 
f2prepped_leftarm = true else
f2prepped_leftarm = false
end

if lb[target].hits["right arm"] + mstar2damage >= 99.9 and not tAffs.damagedrightarm then 
m2prepped_rightarm = true else
m2prepped_rightarm = false
end
if lb[target].hits["right arm"] + flail2damage >= 99.9 and not tAffs.damagedrightarm then 
f2prepped_rightarm = true else
f2prepped_rightarm = false
end

if lb[target].hits["right leg"] + mstar2damage >= 99.9 and not tAffs.damagedrightleg then 
m2prepped_rightleg = true else
m2prepped_rightleg = false
end
if lb[target].hits["right leg"] + flail2damage >= 99.9 and not tAffs.damagedrightleg then 
f2prepped_rightleg = true else
f2prepped_rightleg = false
end

if lb[target].hits["left leg"] + mstar2damage >= 99.9 and not tAffs.damagedleftleg then 
m2prepped_leftleg = true else
m2prepped_leftleg = false
end
if lb[target].hits["left leg"] + flail2damage >= 99.9 and not tAffs.damagedleftleg then 
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

if (tAffs.damagedleftleg or tAffs.brokenleftleg and tAffs.damagedrightleg or tAffs.brokenrightleg and tAffs.damagedleftarm or tAffs.brokenleftarm and tAffs.damagedrightarm or tAffs.brokenrightarm) then
tvivsect = true
else 
tvivisect = false
end

--ATTACKKKKK
 
-- Bisect

if myinstantcath == true then
  atk = atk.." touch shield"

-- Vivisect --
elseif tvivisect == true and ataxiaNDB.players[target].city ~= "Mhaldor" then
  atk = atk.. "dismount;vivisect " ..target
elseif tvivisect == true and ataxiaNDB.players[target].city == "Mhaldor" then
  send("say Vivisect")

elseif use_bisect == true then
  atk = atk.. "wield bastard;quash " ..target.. ";arc;sizeup " ..target.. ";assess " ..target


--elseif not tAffs.shield and use_bisect == true and ataxiaNDB.players[target].city == "Mhaldor" then
  --send("say QUASH ARC")

-- Pulp

elseif not tAffs.shield and (tAffs.concussion or lb[target].hits["head"] >= 200 or ataxiaTemp.fractures.skullfractures >= 5) and tAffs.prone then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";pulp " ..target.. " ;engage " ..target.. ";sizeup " ..target.. " ;assess " ..target

--Raze
elseif tAffs.rebounding or tAffs.shield then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena track " ..target.. ";hyena slay " ..target.. ";fracture " ..target.. " ;assess " ..target.. " ;sizeup " ..target

-- Skull Fractures --
elseif tAffs.prone and ataxia.vitals.class >= 2 then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head expend head expend;assess " ..target.." ;sizeup " ..target
elseif tAffs.prone and ataxia.vitals.class < 2 then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
 
--Anti Parry
elseif not tAffs.numbedleftarm and ataxiaTemp.parriedLimb ~= "left arm" and ataxiaTemp.parriedLimb == "left leg" or ataxiaTemp.parriedLimb == "right leg" or ataxiaTemp.parriedLimb == "head" or ataxiaTemp.parriedLimb == "torso" or ataxiaTemp.parriedLimb == "right arm" then
  if ataxia.vitals.class < 1 then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena track " ..target.. " ;hyena slay " ..target.. ";doublewhirl " ..target.. " left arm left arm;sizeup " ..target.. ";assess " ..target
 
  elseif ataxia.vitals.class > 1 then
    if mprepped_head == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend head;sizeup " ..target.. ";assess " ..target
    else 
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend torso;sizeup " ..target.. ";assess " ..target
    end
  end
  
  --If we have above 4 momentum, prone and hit head with flails to give skull fractures
elseif ataxia.vitals.class >= 4 then  
  if ataxiaTemp.parriedLimb ~= "right leg" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right flail408566;hellforge invest torment;doublewhirl " ..target.. " right leg expend head expend;sizeup " ..target.. ";assess " ..target  
  elseif ataxiaTemp.parriedLimb ~= "left leg" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right flail408566;hellforge invest torment;doublewhirl " ..target.. " left leg expend head expend;sizeup " ..target.. ";assess " ..target  
  end
  
  --If we have above 2 momentum, use flails 
elseif ataxia.vitals.class >= 2 then
  if ataxiaTemp.parriedLimb ~= "left arm" or tAffs.numbedleftarm then
    if ataxiaTemp.fractures.skullfractures >= 2 and ataxiaTemp.fractures.crackedribs >= 2 and ataxiaTemp.fractures.wristfractures >= 2 and tAffs.clumsiness then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm expend head expend;sizeup " ..target.. ";assess " ..target
    elseif ataxiaTemp.fractures.skullfractures >= 2 and ataxiaTemp.fractures.crackedribs >= 2 and ataxiaTemp.fractures.wristfractures >= 2 then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm expend left leg expend;sizeup " ..target.. ";assess " ..target
    elseif ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.skullfractures >= 1 and ataxiaTemp.fractures.crackedribs >= 1 then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm expend head expend;sizeup " ..target.. ";assess " ..target  
    elseif ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.crackedribs >= 1 and ataxiaTemp.fractures.skullfractures < 1 then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm expend head expend;sizeup " ..target.. ";assess " ..target  
    elseif ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.crackedribs < 2 then
      atk = atk.. "wield left flail343168;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm expend torso expend;sizeup " ..target.. ";assess " ..target  
    elseif ataxiaTemp.fractures.wristfractures < 1 then
      atk = atk.. "wield left flail343168;wield right morningstar511735;hellforge invest exploit;doublewhirl " ..target.. " left arm expend right arm expend;sizeup " ..target.. ";assess " ..target  
    elseif not tAffs.clumsiness then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm expend right leg expend;sizeup " ..target.. ";assess " ..target
    end
  elseif ataxiaTemp.parriedLimb ~= "right arm" or tAffs.numbedleftarm then
    if ataxiaTemp.fractures.skullfractures >= 2 and ataxiaTemp.fractures.crackedribs >= 2 and ataxiaTemp.fractures.wristfractures >= 2 and tAffs.clumsiness then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm expend head expend;sizeup " ..target.. ";assess " ..target
    elseif ataxiaTemp.fractures.skullfractures >= 2 and ataxiaTemp.fractures.crackedribs >= 2 and ataxiaTemp.fractures.wristfractures >= 2 then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm expend left leg expend;sizeup " ..target.. ";assess " ..target
    elseif ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.skullfractures >= 1 and ataxiaTemp.fractures.crackedribs >= 1 then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm expend head expend;sizeup " ..target.. ";assess " ..target  
    elseif ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.crackedribs >= 1 and ataxiaTemp.fractures.skullfractures < 1 then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm expend head expend;sizeup " ..target.. ";assess " ..target  
    elseif ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.crackedribs < 2 then
      atk = atk.. "wield left flail343168;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm expend torso expend;sizeup " ..target.. ";assess " ..target  
    elseif ataxiaTemp.fractures.wristfractures < 1 then
      atk = atk.. "wield left flail343168;wield right morningstar511735;hellforge invest exploit;doublewhirl " ..target.. " right arm expend right arm expend;sizeup " ..target.. ";assess " ..target  
    elseif not tAffs.clumsiness then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm expend right leg expend;sizeup " ..target.. ";assess " ..target
    end
  
  
  end
  
  --If we have less than 2 momentum, get momentum
elseif ataxia.vitals.class < 2 then
  if ataxiaTemp.fractures.skullfractures <= 1 and tAffs.damagedhead and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
  elseif ataxiaTemp.fractures.crackedribs <= 1 and tAffs.mildtrauma and tAffs.paralysis and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
  elseif tAffs.damagedhead and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
  elseif tAffs.mildtrauma and ataxiaTemp.fractures.crackedribs < 4 and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
  elseif tAffs.damagedrightarm and ataxiaTemp.parriedLimb ~= "right arm" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm right arm;sizeup " ..target.. ";assess " ..target
  elseif tAffs.damagedleftarm and ataxiaTemp.parriedLimb ~= "left arm" or tAffs.numbedleftarm then 
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm left arm;sizeup " ..target.. ";assess " ..target
  elseif mprepped_torso == false and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
  elseif m2prepped_head == false and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
  elseif mprepped_rightleg == false and mprepped_leftleg == false and ataxiaTemp.parriedLimb ~= "left leg" or tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "right leg" then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left leg right leg;sizeup " ..target.. ";assess " ..target
  end
end

if table.contains(ataxia.playersHere, target) then
if falconattack == true then
  if not engaged then
    send("queue addclear freestand " ..atk.. ";engage " ..target)
  else
    send("queue addclear freestand " ..atk)
  end
elseif falconattack == false then
 if not engaged then
    send("queue addclear freestand " ..atk.. ";hyena slay " ..target.." ;engage " ..target)
  else
    send("queue addclear freestand " ..atk.. ";hyena slay " ..target)
  end
end
else
  expandAlias("nt")
  send("queue addclear freestand " ..atk)

end
end





function idwb_viviroute()
infernaldwbviviprio()
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
MDWBWhirlDamage = MDWBWhirlDamage or 14
FDWBWhirlDamage = FDWBWhirlDamage or 20

ataxiaTemp.tarTumble = ataxiaTemp.tarTumble or false
tarpreapply = tarpreapply or false
tAffs.bleed = tAffs.bleed or 0
mstardamage = MDWBWhirlDamage
flaildamage = FDWBWhirlDamage
mstar2damage = MDWBWhirlDamage + MDWBWhirlDamage
flail2damage = FDWBWhirlDamage + FDWBWhirlDamage

tarlimb = tarlimb or "right arm"
tarlimb2 = tarlimb2 or "none"
if ataxiaTemp.parriedLimb == nil then ataxiaTemp.parriedLimb = "none" end
ataxiaTemp.parriedLimb = ataxiaTemp.parriedLimb or "none"
wieldweapons = wieldweapons or "morningstars"

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 30 then
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
if lb[target].hits["head"] + flail2damage >= 99.9 and not tAffs.damagedhead then 
f2prepped_head = true else
f2prepped_head = false
end

if lb[target].hits["torso"] + mstar2damage >= 99.9 and not tAffs.damagedtorso then 
m2prepped_torso = true else
m2prepped_torso = false
end
if lb[target].hits["torso"] + flail2damage >= 99.9 and not tAffs.damagedtorso then 
f2prepped_torso = true else
f2prepped_torso = false
end

if lb[target].hits["left arm"] + mstar2damage >= 99.9 and not tAffs.damagedleftarm then 
m2prepped_leftarm = true else
m2prepped_leftarm = false
end
if lb[target].hits["left arm"] + flail2damage >= 99.9 and not tAffs.damagedleftarm then 
f2prepped_leftarm = true else
f2prepped_leftarm = false
end

if lb[target].hits["right arm"] + mstar2damage >= 99.9 and not tAffs.damagedrightarm then 
m2prepped_rightarm = true else
m2prepped_rightarm = false
end
if lb[target].hits["right arm"] + flail2damage >= 99.9 and not tAffs.damagedrightarm then 
f2prepped_rightarm = true else
f2prepped_rightarm = false
end

if lb[target].hits["right leg"] + mstar2damage >= 99.9 and not tAffs.damagedrightleg then 
m2prepped_rightleg = true else
m2prepped_rightleg = false
end
if lb[target].hits["right leg"] + flail2damage >= 99.9 and not tAffs.damagedrightleg then 
f2prepped_rightleg = true else
f2prepped_rightleg = false
end

if lb[target].hits["left leg"] + mstar2damage >= 99.9 and not tAffs.damagedleftleg then 
m2prepped_leftleg = true else
m2prepped_leftleg = false
end
if lb[target].hits["left leg"] + flail2damage >= 99.9 and not tAffs.damagedleftleg then 
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
elseif use_bisect == true then
  atk = atk.. "wield bastard;quash " ..target.. ";arc;assess " ..target.. " ;sizeup " ..target


-- Vivisect --
elseif tvivisect == true and ataxiaNDB.players[target].city ~= "Mhaldor" then
  atk = atk.. "dismount;vivisect " ..target
elseif tvivisect == true and ataxiaNDB.players[target].city == "Mhaldor" then
  send("say Vivisect")


-- Pulp
elseif not tAffs.shield and (tAffs.concussion or lb[target].hits["head"] >= 200 or ataxiaTemp.fractures.skullfractures >= 5) and tAffs.prone then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";pulp " ..target.. " ;sizeup " ..target.. " ;assess " ..target

--Raze
elseif tAffs.rebounding or tAffs.shield then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena track " ..target.. ";hyena slay " ..target.. ";fracture " ..target.. " ;assess " ..target.. " ;sizeup " ..target

-- Vivisect --
elseif (tAffs.damagedleftleg or tAffs.brokenleftleg and tAffs.damagedrightleg or tAffs.brokenrightleg and tAffs.damagedleftarm or tAffs.brokenleftarm and tAffs.damagedrightarm or tAffs.brokenrightarm) and ataxiaNDB.players[target].city ~= "Mhaldor" then
  atk = atk.. "dismount;vivisect " ..target
elseif (tAffs.damagedleftleg or tAffs.brokenleftleg and tAffs.damagedrightleg or tAffs.brokenrightleg and tAffs.damagedleftarm or tAffs.brokenleftarm and tAffs.damagedrightarm or tAffs.brokenrightarm) and ataxiaNDB.players[target].city == "Mhaldor" then
  send("say Vivisect")
  
  
--4 Break
-- Break Sequence
  -- If target preapplied - don't break
elseif tarpreapply == true then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " torso torso expend;assess " ..target

  --Break Head
elseif mprepped_leftleg == true and mprepped_rightleg == true and mprepped_leftarm == true and mprepped_rightarm == true and mprepped_head == true and ataxiaTemp.parriedLimb ~= "head" and ataxia.vitals.class >= 5 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";discipline;doublewhirl " ..target.. " head expend head;sizeup " ..target.. ";assess " ..target
elseif mprepped_leftleg == true and mprepped_rightleg == true and mprepped_leftarm == true and mprepped_rightarm == true and mprepped_head == true and ataxiaTemp.parriedLimb ~= "head" and ataxia.vitals.class <= 3 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";discipline;doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target

  --If not clumsiness don't use discipline
   
    -- Broken Legs -- Break Arms
elseif not ataxia.afflictions.clumsiness and mprepped_leftarm == true and mprepped_rightarm == true and tAffs.numbedleftarm and (tAffs.damagedrightleg or lb[target].hits["right leg"] >= 100) or (tAffs.damagedleftleg or lb[target].hits["left leg"] >= 100) and tAffs.prone then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm left arm;sizeup " ..target.. ";assess " ..target
elseif not ataxia.afflictions.clumsiness and mprepped_leftarm == true and mprepped_rightarm == true and (tAffs.damagedrightleg or lb[target].hits["right leg"] >= 100) or (tAffs.damagedleftleg or lb[target].hits["left leg"] >= 100) and tAffs.prone then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm left arm;sizeup " ..target.. ";assess " ..target

 -- Leg and Arm Prepped - Leg Prone
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and mprepped_leftarm == true and mprepped_rightarm == true and tAffs.numbedleftarm and ataxia.vitals.class >= 3 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and mprepped_leftarm == true and mprepped_rightarm == true and ataxia.vitals.class >= 3 and ataxiaTemp.parriedLimb ~= "right leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and mprepped_leftarm == true and mprepped_rightarm == true and ataxia.vitals.class >= 3 and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left leg expend right leg;sizeup " ..target.. ";assess " ..target

    --We need more momentum to prone with Stars
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and mprepped_leftarm == true and mprepped_rightarm == true and ataxia.vitals.class < 3 and ataxiaTemp.parriedLimb ~= "torso" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target

----------------
--If clumsiness use discipline
  -- Break Arms if Legs are broke
elseif ataxia.afflictions.clumsiness and mprepped_leftarm == true and mprepped_rightarm == true and tAffs.numbedleftarm and tAffs.damagedrightleg and tAffs.damagedleftleg then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";discipline;doublewhirl " ..target.. " right arm left arm;sizeup " ..target.. ";assess " ..target
elseif ataxia.afflictions.clumsiness and mprepped_leftarm == true and mprepped_rightarm == true and tAffs.damagedrightleg and tAffs.damagedleftleg then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";discipline;doublewhirl " ..target.. " right arm left arm;sizeup " ..target.. ";assess " ..target

  -- Leg and Arm Prepped - Leg Prone
elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and mprepped_leftarm == true and mprepped_rightarm == true and tAffs.numbedleftarm and ataxia.vitals.class >= 3 then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";discipline;doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and mprepped_leftarm == true and mprepped_rightarm == true and ataxia.vitals.class >= 3 and ataxiaTemp.parriedLimb ~= "right leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";discipline;doublewhirl " ..target.. " right leg expend left leg;sizeup " ..target.. ";assess " ..target
elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and mprepped_leftarm == true and mprepped_rightarm == true and ataxia.vitals.class >= 3 and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";discipline;doublewhirl " ..target.. " left leg expend right leg;sizeup " ..target.. ";assess " ..target
    --We need more momentum to prone with Stars
elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and mprepped_rightleg == true and mprepped_leftarm == true and mprepped_rightarm == true and ataxia.vitals.class < 3 and ataxiaTemp.parriedLimb ~= "torso" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";discipline;doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target

  
 
--Anti Parry
elseif not tAffs.numbedleftarm and ataxiaTemp.parriedLimb ~= "left arm" and ataxiaTemp.parriedLimb == "left leg" or ataxiaTemp.parriedLimb == "right leg" or ataxiaTemp.parriedLimb == "right arm" and m2prepped_leftarm == false and mprepped_leftarm == false then
  if ataxia.vitals.class < 1 and ataxiaTemp.parriedLimb ~= "torso" then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
  elseif ataxia.vitals.class < 1 and ataxiaTemp.parriedLimb == "torso" then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. ";sizeup " ..target.. ";assess " ..target
  elseif ataxia.vitals.class > 1 then
    if mprepped_head == false then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend head;sizeup " ..target.. ";assess " ..target
    elseif mprepped_rightleg == false then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend right leg;sizeup " ..target.. ";assess " ..target
    elseif mprepped_leftleg == false then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend left leg;sizeup " ..target.. ";assess " ..target
    elseif mprepped_rightarm == false then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend right arm;sizeup " ..target.. ";assess " ..target
    elseif mprepped_leftarm == false then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend left arm;sizeup " ..target.. ";assess " ..target
    else
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend torso;sizeup " ..target.. ";assess " ..target
  
    end  
  end

-- 4 Prep
--Prep Head\ Left Leg\ Right Leg \ Right arm \ Left Arm
elseif m2prepped_leftarm == true and mprepped_leftleg == true and mprepped_rightleg == true and mprepped_rightarm == true and mprepped_head == true then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " left arm torso;assess " ..target
elseif m2prepped_rightarm == true and mprepped_leftleg == true and mprepped_rightleg == true and mprepped_rightarm == false and mprepped_leftarm == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " right arm left arm;assess " ..target
elseif m2prepped_rightleg == true and mprepped_head == true and mprepped_rightleg == false and mprepped_leftleg == true and mprepped_rightarm == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " right arm right leg;assess " ..target
elseif m2prepped_leftleg == true and mprepped_leftleg == false and mprepped_rightleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " left leg right leg;assess " ..target
elseif m2prepped_head == true and mprepped_head == false and mprepped_rightleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " head right leg;assess " ..target



-- 5 Prep
elseif mprepped_head == false and m2prepped_head == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " head head;assess " ..target
elseif mprepped_leftleg == false and m2prepped_leftleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " left leg left leg;assess " ..target
elseif mprepped_rightleg == false and m2prepped_rightleg == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " right leg right leg;assess " ..target
elseif mprepped_rightarm == false and m2prepped_rightarm == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " right arm right arm;assess " ..target
elseif mprepped_leftarm == false and m2prepped_leftarm == false then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " left arm left arm;assess " ..target


else
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " ;assess " ..target

end

if table.contains(ataxia.playersHere, target) then
if falconattack == true then
  if not engaged then
    send("queue addclear freestand " ..atk.. ";engage " ..target)
  else
    send("queue addclear freestand " ..atk)
  end
elseif falconattack == false then
 if not engaged then
    send("queue addclear freestand " ..atk.. ";hyena slay " ..target.." ;engage " ..target)
  else
    send("queue addclear freestand " ..atk.. ";hyena slay " ..target)
  end
end
else
  expandAlias("nt")
  send("queue addclear freestand " ..atk)

end
end

---Ideal
-------------USE BELOW FOR GROUP COMBAT and TO MELT MOFOS--------------------
function idwb_damageroute2()
infernaldwbviviprio()
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
flail2damage = DWBWhirlDamage + DWBWhirlDamage

tarlimb = tarlimb or "right arm"
tarlimb2 = tarlimb2 or "none"
if ataxiaTemp.parriedLimb == nil then ataxiaTemp.parriedLimb = "none" end
ataxiaTemp.parriedLimb = ataxiaTemp.parriedLimb or "none"
wieldweapons = wieldweapons or "morningstars"

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 30 then
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
if lb[target].hits["head"] + flail2damage >= 99.9 and not tAffs.damagedhead then 
f2prepped_head = true else
f2prepped_head = false
end

if lb[target].hits["torso"] + mstar2damage >= 99.9 and not tAffs.damagedtorso then 
m2prepped_torso = true else
m2prepped_torso = false
end
if lb[target].hits["torso"] + flail2damage >= 99.9 and not tAffs.damagedtorso then 
f2prepped_torso = true else
f2prepped_torso = false
end

if lb[target].hits["left arm"] + mstar2damage >= 99.9 and not tAffs.damagedleftarm then 
m2prepped_leftarm = true else
m2prepped_leftarm = false
end
if lb[target].hits["left arm"] + flail2damage >= 99.9 and not tAffs.damagedleftarm then 
f2prepped_leftarm = true else
f2prepped_leftarm = false
end

if lb[target].hits["right arm"] + mstar2damage >= 99.9 and not tAffs.damagedrightarm then 
m2prepped_rightarm = true else
m2prepped_rightarm = false
end
if lb[target].hits["right arm"] + flail2damage >= 99.9 and not tAffs.damagedrightarm then 
f2prepped_rightarm = true else
f2prepped_rightarm = false
end

if lb[target].hits["right leg"] + mstar2damage >= 99.9 and not tAffs.damagedrightleg then 
m2prepped_rightleg = true else
m2prepped_rightleg = false
end
if lb[target].hits["right leg"] + flail2damage >= 99.9 and not tAffs.damagedrightleg then 
f2prepped_rightleg = true else
f2prepped_rightleg = false
end

if lb[target].hits["left leg"] + mstar2damage >= 99.9 and not tAffs.damagedleftleg then 
m2prepped_leftleg = true else
m2prepped_leftleg = false
end
if lb[target].hits["left leg"] + flail2damage >= 99.9 and not tAffs.damagedleftleg then 
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

if (tAffs.damagedleftleg or tAffs.brokenleftleg and tAffs.damagedrightleg or tAffs.brokenrightleg and tAffs.damagedleftarm or tAffs.brokenleftarm and tAffs.damagedrightarm or tAffs.brokenrightarm) then
tvivsect = true
else 
tvivisect = false
end

--ATTACKKKKK
 
-- Bisect

if myinstantcath == true then
  atk = atk.." touch shield"

-- Vivisect --
elseif tvivisect == true and ataxiaNDB.players[target].city ~= "Mhaldor" then
  atk = atk.. "dismount;vivisect " ..target
elseif tvivisect == true and ataxiaNDB.players[target].city == "Mhaldor" then
  send("say Vivisect")

elseif use_bisect == true then
  atk = atk.. "wield bastard;quash " ..target.. ";arc;sizeup " ..target.. ";assess " ..target




-- Pulp

elseif not tAffs.shield and (tAffs.concussion or lb[target].hits["head"] >= 200 or ataxiaTemp.fractures.skullfractures >= 5) and tAffs.prone then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";pulp " ..target.. " ;engage " ..target.. ";sizeup " ..target.. " ;assess " ..target

--Raze
elseif tAffs.rebounding or tAffs.shield then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena track " ..target.. ";hyena slay " ..target.. ";fracture " ..target.. " ;assess " ..target.. " ;sizeup " ..target

-- Skull Fractures --
elseif tAffs.prone and ataxia.vitals.class >= 2 then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head expend head expend;assess " ..target.." ;sizeup " ..target
elseif tAffs.prone and ataxia.vitals.class < 2 then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
 
--Anti Parry
elseif not tAffs.numbedleftarm and ataxiaTemp.parriedLimb ~= "left arm" and ataxiaTemp.parriedLimb == "left leg" or ataxiaTemp.parriedLimb == "right leg" or ataxiaTemp.parriedLimb == "head" or ataxiaTemp.parriedLimb == "torso" or ataxiaTemp.parriedLimb == "right arm" then
  if ataxia.vitals.class < 1 then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena track " ..target.. " ;hyena slay " ..target.. ";doublewhirl " ..target.. " left arm left arm;sizeup " ..target.. ";assess " ..target
 
  elseif ataxia.vitals.class > 1 then
    if mprepped_head == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend head;sizeup " ..target.. ";assess " ..target
    else 
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend torso;sizeup " ..target.. ";assess " ..target
    end
  end
  
  --If we have above 4 momentum, prone and hit head with flails to give skull fractures
elseif ataxia.vitals.class >= 4 then  
  if ataxiaTemp.parriedLimb ~= "right leg" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right flail408566;hellforge invest torment;doublewhirl " ..target.. " right leg expend head expend;sizeup " ..target.. ";assess " ..target  
  elseif ataxiaTemp.parriedLimb ~= "left leg" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right flail408566;hellforge invest torment;doublewhirl " ..target.. " left leg expend head expend;sizeup " ..target.. ";assess " ..target  
  end
  
  --If we have above 2 momentum, use flails 
elseif ataxia.vitals.class >= 2 then
  if ataxiaTemp.parriedLimb ~= "left arm" or tAffs.numbedleftarm then
    if ataxiaTemp.fractures.skullfractures >= 2 and ataxiaTemp.fractures.crackedribs >= 2 and ataxiaTemp.fractures.wristfractures >= 2 and tAffs.clumsiness then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm expend head expend;sizeup " ..target.. ";assess " ..target
    elseif ataxiaTemp.fractures.skullfractures >= 2 and ataxiaTemp.fractures.crackedribs >= 2 and ataxiaTemp.fractures.wristfractures >= 2 then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm expend left leg expend;sizeup " ..target.. ";assess " ..target
    elseif ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.skullfractures >= 1 and ataxiaTemp.fractures.crackedribs >= 1 then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm expend head expend;sizeup " ..target.. ";assess " ..target  
    elseif ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.crackedribs >= 1 and ataxiaTemp.fractures.skullfractures < 1 then
      if ataxiaTemp.fractures.skullfractures <= 1 and tAffs.damagedhead and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
      elseif ataxiaTemp.fractures.crackedribs <= 1 and tAffs.mildtrauma and tAffs.paralysis and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
      elseif tAffs.damagedhead and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
      elseif tAffs.mildtrauma and ataxiaTemp.fractures.crackedribs < 4 and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
      elseif tAffs.damagedrightarm and ataxiaTemp.parriedLimb ~= "right arm" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm right arm;sizeup " ..target.. ";assess " ..target
      elseif tAffs.damagedleftarm and ataxiaTemp.parriedLimb ~= "left arm" or tAffs.numbedleftarm then 
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm left arm;sizeup " ..target.. ";assess " ..target
      elseif mprepped_torso == false and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
      elseif m2prepped_head == false and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
      elseif mprepped_rightleg == false and mprepped_leftleg == false and ataxiaTemp.parriedLimb ~= "left leg" or tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "right leg" then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left leg right leg;sizeup " ..target.. ";assess " ..target
      end
    elseif ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.crackedribs < 2 then
      atk = atk.. "wield left flail343168;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm expend torso expend;sizeup " ..target.. ";assess " ..target  
    elseif ataxiaTemp.fractures.wristfractures < 1 then
      atk = atk.. "wield left flail343168;wield right morningstar511735;hellforge invest exploit;doublewhirl " ..target.. " left arm expend right arm expend;sizeup " ..target.. ";assess " ..target  
    elseif not tAffs.clumsiness then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm expend right leg expend;sizeup " ..target.. ";assess " ..target
    end
  elseif ataxiaTemp.parriedLimb ~= "right arm" or tAffs.numbedleftarm then
    if ataxiaTemp.fractures.skullfractures >= 2 and ataxiaTemp.fractures.crackedribs >= 2 and ataxiaTemp.fractures.wristfractures >= 2 and tAffs.clumsiness then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm expend head expend;sizeup " ..target.. ";assess " ..target
    elseif ataxiaTemp.fractures.skullfractures >= 2 and ataxiaTemp.fractures.crackedribs >= 2 and ataxiaTemp.fractures.wristfractures >= 2 then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm expend left leg expend;sizeup " ..target.. ";assess " ..target
    elseif ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.skullfractures >= 1 and ataxiaTemp.fractures.crackedribs >= 1 then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm expend head expend;sizeup " ..target.. ";assess " ..target  
    elseif ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.crackedribs >= 1 and ataxiaTemp.fractures.skullfractures < 1 then
      if ataxiaTemp.fractures.skullfractures <= 1 and tAffs.damagedhead and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
      elseif ataxiaTemp.fractures.crackedribs <= 1 and tAffs.mildtrauma and tAffs.paralysis and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
      elseif tAffs.damagedhead and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
      elseif tAffs.mildtrauma and ataxiaTemp.fractures.crackedribs < 4 and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
      elseif tAffs.damagedrightarm and ataxiaTemp.parriedLimb ~= "right arm" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm right arm;sizeup " ..target.. ";assess " ..target
      elseif tAffs.damagedleftarm and ataxiaTemp.parriedLimb ~= "left arm" or tAffs.numbedleftarm then 
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm left arm;sizeup " ..target.. ";assess " ..target
      elseif mprepped_torso == false and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
      elseif m2prepped_head == false and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
      elseif mprepped_rightleg == false and mprepped_leftleg == false and ataxiaTemp.parriedLimb ~= "left leg" or tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "right leg" then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left leg right leg;sizeup " ..target.. ";assess " ..target
      end
    elseif ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.crackedribs < 2 then
      atk = atk.. "wield left flail343168;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm expend torso expend;sizeup " ..target.. ";assess " ..target  
    elseif ataxiaTemp.fractures.wristfractures < 1 then
      atk = atk.. "wield left flail343168;wield right morningstar511735;hellforge invest exploit;doublewhirl " ..target.. " right arm expend right arm expend;sizeup " ..target.. ";assess " ..target  
    elseif not tAffs.clumsiness then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm expend right leg expend;sizeup " ..target.. ";assess " ..target
    end
  
  
  end
  
  --If we have less than 2 momentum, get momentum
elseif ataxia.vitals.class < 2 then
  if ataxiaTemp.fractures.skullfractures <= 1 and tAffs.damagedhead and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
  elseif ataxiaTemp.fractures.crackedribs <= 1 and tAffs.mildtrauma and tAffs.paralysis and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
  elseif tAffs.damagedhead and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
  elseif tAffs.mildtrauma and ataxiaTemp.fractures.crackedribs < 4 and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
  elseif tAffs.damagedrightarm and ataxiaTemp.parriedLimb ~= "right arm" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm right arm;sizeup " ..target.. ";assess " ..target
  elseif tAffs.damagedleftarm and ataxiaTemp.parriedLimb ~= "left arm" or tAffs.numbedleftarm then 
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm left arm;sizeup " ..target.. ";assess " ..target
  elseif mprepped_torso == false and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
  elseif m2prepped_head == false and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
  elseif mprepped_rightleg == false and mprepped_leftleg == false and ataxiaTemp.parriedLimb ~= "left leg" or tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "right leg" then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left leg right leg;sizeup " ..target.. ";assess " ..target
  end
end

if table.contains(ataxia.playersHere, target) then
if falconattack == true then
  if not engaged then
    send("queue addclear freestand " ..atk.. ";engage " ..target)
  else
    send("queue addclear freestand " ..atk)
  end
elseif falconattack == false then
 if not engaged then
    send("queue addclear freestand " ..atk.. ";hyena slay " ..target.." ;engage " ..target)
  else
    send("queue addclear freestand " ..atk.. ";hyena slay " ..target)
  end
end
else
  expandAlias("nt")
  send("queue addclear freestand " ..atk)

end
end




---Not Ideal yet...
-------------BREAK ONE LEB/PRONE/SKULL FRACTURES/FLAIL WRIST/CRACKED RIBS AND DAMAGAEEEEEEEEEEEEEEEEEEEEEEEEE-------------------
function idwb_damageroute3()
infernaldwbviviprio()
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
flail2damage = DWBWhirlDamage + DWBWhirlDamage

tarlimb = tarlimb or "right arm"
tarlimb2 = tarlimb2 or "none"
if ataxiaTemp.parriedLimb == nil then ataxiaTemp.parriedLimb = "none" end
ataxiaTemp.parriedLimb = ataxiaTemp.parriedLimb or "none"
wieldweapons = wieldweapons or "morningstars"

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 30 then
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
if lb[target].hits["head"] + flail2damage >= 99.9 and not tAffs.damagedhead then 
f2prepped_head = true else
f2prepped_head = false
end

if lb[target].hits["torso"] + mstar2damage >= 99.9 and not tAffs.damagedtorso then 
m2prepped_torso = true else
m2prepped_torso = false
end
if lb[target].hits["torso"] + flail2damage >= 99.9 and not tAffs.damagedtorso then 
f2prepped_torso = true else
f2prepped_torso = false
end

if lb[target].hits["left arm"] + mstar2damage >= 99.9 and not tAffs.damagedleftarm then 
m2prepped_leftarm = true else
m2prepped_leftarm = false
end
if lb[target].hits["left arm"] + flail2damage >= 99.9 and not tAffs.damagedleftarm then 
f2prepped_leftarm = true else
f2prepped_leftarm = false
end

if lb[target].hits["right arm"] + mstar2damage >= 99.9 and not tAffs.damagedrightarm then 
m2prepped_rightarm = true else
m2prepped_rightarm = false
end
if lb[target].hits["right arm"] + flail2damage >= 99.9 and not tAffs.damagedrightarm then 
f2prepped_rightarm = true else
f2prepped_rightarm = false
end

if lb[target].hits["right leg"] + mstar2damage >= 99.9 and not tAffs.damagedrightleg then 
m2prepped_rightleg = true else
m2prepped_rightleg = false
end
if lb[target].hits["right leg"] + flail2damage >= 99.9 and not tAffs.damagedrightleg then 
f2prepped_rightleg = true else
f2prepped_rightleg = false
end

if lb[target].hits["left leg"] + mstar2damage >= 99.9 and not tAffs.damagedleftleg then 
m2prepped_leftleg = true else
m2prepped_leftleg = false
end
if lb[target].hits["left leg"] + flail2damage >= 99.9 and not tAffs.damagedleftleg then 
f2prepped_leftleg = true else
f2prepped_leftleg = false
end

---Vivisect Condition
if (tAffs.damagedleftleg or tAffs.brokenleftleg and tAffs.damagedrightleg or tAffs.brokenrightleg and tAffs.damagedleftarm or tAffs.brokenleftarm and tAffs.damagedrightarm or tAffs.brokenrightarm) then
tvivsect = true
else 
tvivisect = false
end

--ATTACKKKKK
 
-- Bisect

if myinstantcath == true then
  atk = atk.." touch shield"

-- Vivisect --
elseif tvivisect == true and ataxiaNDB.players[target].city ~= "Mhaldor" then
  atk = atk.. "dismount;vivisect " ..target
elseif tvivisect == true and ataxiaNDB.players[target].city == "Mhaldor" then
  send("say Vivisect")

--QUASH
elseif use_bisect == true then
  atk = atk.. " wield bastard;quash " ..target.. ";arc;sizeup " ..target.. ";assess " ..target




-- Pulp

elseif (tAffs.concussion or lb[target].hits["head"] >= 200 or ataxiaTemp.fractures.skullfractures >= 5) and tAffs.prone then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";pulp " ..target.. " ;engage " ..target.. ";sizeup " ..target.. " ;assess " ..target

--Raze
elseif tAffs.rebounding or tAffs.shield then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena track " ..target.. ";hyena slay " ..target.. ";fracture " ..target.. " ;assess " ..target.. " ;sizeup " ..target

-- Skull Fractures if Prone --
elseif tAffs.prone and ataxia.vitals.class >= 2 then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest torment;doublewhirl " ..target.. " head expend head expend;assess " ..target.." ;sizeup " ..target
elseif tAffs.prone and ataxia.vitals.class < 2 then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target

-- Break Sequence --

--Dont Double Break if they Pre-Apply
elseif tarpreapply == true then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";sizeup " ..target.. ";doublewhirl " ..target.. " torso torso expend;assess " ..target

--Doublebreak with or without clumsiness (Add Discipline)
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and tAffs.numbedleftarm and ataxia.vitals.class == 8 then
  atk = atk.. " wield left morningstar511732;wield right flail408566;hellforge invest torment;doublewhirl " ..target.. " left leg expend head expend;sizeup " ..target.. ";assess " ..target
elseif not ataxia.afflictions.clumsiness and mprepped_leftleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.. " wield left morningstar511732;wield right flail408566;hellforge invest torment;doublewhirl " ..target.. " left leg expend head expend;sizeup " ..target.. ";assess " ..target

elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and tAffs.numbedleftarm and ataxia.vitals.class == 8 then
  atk = atk.. " wield left morningstar511732;wield right flail408566;hellforge invest torment;discipline;doublewhirl " ..target.. " left leg expend head expend;sizeup " ..target.. ";assess " ..target
elseif ataxia.afflictions.clumsiness and mprepped_leftleg == true and ataxia.vitals.class >= 4 and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.. " wield left morningstar511732;wield right flail408566;hellforge invest torment;discipline;doublewhirl " ..target.. " left leg expend head expend;sizeup " ..target.. ";assess " ..target
--Doublebreak within Doublewhirl of Stars
elseif not ataxia.afflictions.clumsiness and m2prepped_leftleg == true and tAffs.numbedleftarm and ataxia.vitals.class == 8 then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left leg left leg expend;sizeup " ..target.. ";assess " ..target
elseif not ataxia.afflictions.clumsiness and m2prepped_leftleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left leg left leg expend;sizeup " ..target.. ";assess " ..target

elseif ataxia.afflictions.clumsiness and m2prepped_leftleg == true and tAffs.numbedleftarm and ataxia.vitals.class == 8 then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";discipline;doublewhirl " ..target.. " left leg left leg expend;sizeup " ..target.. ";assess " ..target
elseif ataxia.afflictions.clumsiness and m2prepped_leftleg == true and ataxia.vitals.class == 8 and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";discipline;doublewhirl " ..target.. " left leg left leg expend;sizeup " ..target.. ";assess " ..target





--Anti Parry
elseif not tAffs.numbedleftarm and ataxiaTemp.parriedLimb ~= "left arm" and ataxiaTemp.parriedLimb == "left leg" or ataxiaTemp.parriedLimb == "right leg" or ataxiaTemp.parriedLimb == "head" or ataxiaTemp.parriedLimb == "torso" or ataxiaTemp.parriedLimb == "right arm" then
  if ataxia.vitals.class < 1 then
    atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena track " ..target.. " ;hyena slay " ..target.. ";doublewhirl " ..target.. " left arm left arm;sizeup " ..target.. ";assess " ..target
 
  elseif ataxia.vitals.class >= 1 then
    if mprepped_head == false then
      atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend head;sizeup " ..target.. ";assess " ..target
    else 
      atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend torso;sizeup " ..target.. ";assess " ..target
    end
  end

-- Prep Left Leg

elseif mprepped_leftleg == true or m2prepped_leftleg == true and ataxia.vitals.class < 4 and ataxiaTemp.parriedLimb ~= "right leg" then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right leg right leg;sizeup " ..target.. ";assess " ..target

elseif ataxiaTemp.fractures.skullfractures < 1 and ataxiaTemp.fractures.wristfractures < 1 and ataxiaTemp.fractures.crackedribs < 1 then
  if mprepped_leftleg == true or m2prepped_leftleg == true and ataxia.vitals.class < 8 and ataxiaTemp.parriedLimb ~= "head" then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
  elseif mprepped_leftleg == true or m2prepped_leftleg == true and ataxia.vitals.class < 8 and ataxiaTemp.parriedLimb ~= "torso" then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
  elseif mprepped_leftleg == false and m2prepped_leftleg == false then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left leg left leg;sizeup " ..target.. ";assess " ..target
  end
   

  
  --If we have above 2 momentum, use flails 
elseif ataxia.vitals.class >= 2 and mprepped_leftleg == false and m2prepped_leftleg == false then
  if ataxiaTemp.parriedLimb ~= "left arm" or tAffs.numbedleftarm then
     if ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.skullfractures >= 1 and ataxiaTemp.fractures.crackedribs >= 1 then
      atk = atk.. " wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm expend left leg expend;sizeup " ..target.. ";assess " ..target  
     elseif ataxiaTemp.fractures.skullfractures >= 2 and ataxiaTemp.fractures.crackedribs < 1 and ataxiaTemp.fractures.wristfractures >= 1 then
      atk = atk.. "wield left flail343168;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm expend torso expend;sizeup " ..target.. ";assess " ..target  
     elseif ataxiaTemp.fractures.skullfractures >= 2 and ataxiaTemp.fractures.crackedribs < 1 and ataxiaTemp.fractures.wristfractures < 1 then
      atk = atk.. "wield left flail343168;wield right morningstar511735;hellforge invest exploit;doublewhirl " ..target.. " left arm expend right arm expend;sizeup " ..target.. ";assess " ..target  
 
    
    elseif ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.crackedribs >= 1 and ataxiaTemp.fractures.skullfractures < 1 then
      if ataxiaTemp.fractures.skullfractures <= 1 and tAffs.damagedhead and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
        atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
      elseif ataxiaTemp.fractures.crackedribs <= 1 and tAffs.mildtrauma and tAffs.paralysis and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
        atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
      elseif tAffs.damagedhead and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
      elseif tAffs.mildtrauma and ataxiaTemp.fractures.crackedribs < 4 and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
      elseif tAffs.damagedrightarm and ataxiaTemp.parriedLimb ~= "right arm" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm right arm;sizeup " ..target.. ";assess " ..target
      elseif tAffs.damagedleftarm and ataxiaTemp.parriedLimb ~= "left arm" or tAffs.numbedleftarm then 
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm left arm;sizeup " ..target.. ";assess " ..target
      elseif mprepped_torso == false and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
      elseif m2prepped_head == false and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
      elseif mprepped_rightleg == false and mprepped_leftleg == false and ataxiaTemp.parriedLimb ~= "left leg" or tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "right leg" then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left leg right leg;sizeup " ..target.. ";assess " ..target
      end
    elseif ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.crackedribs < 2 then
      atk = atk.. "wield left flail343168;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm expend torso expend;sizeup " ..target.. ";assess " ..target  
    elseif ataxiaTemp.fractures.wristfractures < 1 then
      atk = atk.. "wield left flail343168;wield right morningstar511735;hellforge invest exploit;doublewhirl " ..target.. " left arm expend right arm expend;sizeup " ..target.. ";assess " ..target  
    elseif not tAffs.clumsiness then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm expend right leg expend;sizeup " ..target.. ";assess " ..target
    end
  elseif ataxiaTemp.parriedLimb ~= "right arm" or tAffs.numbedleftarm then
     if ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.skullfractures >= 1 and ataxiaTemp.fractures.crackedribs >= 1 then
      atk = atk.. " wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm expend left leg expend;sizeup " ..target.. ";assess " ..target  
     elseif ataxiaTemp.fractures.skullfractures >= 2 and ataxiaTemp.fractures.crackedribs < 1 and ataxiaTemp.fractures.wristfractures >= 1 then
      atk = atk.. "wield left flail343168;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm expend torso expend;sizeup " ..target.. ";assess " ..target  
     elseif ataxiaTemp.fractures.skullfractures >= 2 and ataxiaTemp.fractures.crackedribs < 1 and ataxiaTemp.fractures.wristfractures < 1 then
      atk = atk.. "wield left flail343168;wield right morningstar511735;hellforge invest exploit;doublewhirl " ..target.. " right arm expend right arm expend;sizeup " ..target.. ";assess " ..target  
 
    
    
    elseif ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.crackedribs >= 1 and ataxiaTemp.fractures.skullfractures < 1 then
      if ataxiaTemp.fractures.skullfractures <= 1 and tAffs.damagedhead and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
      elseif ataxiaTemp.fractures.crackedribs <= 1 and tAffs.mildtrauma and tAffs.paralysis and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
      elseif tAffs.damagedhead and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
      elseif tAffs.mildtrauma and ataxiaTemp.fractures.crackedribs < 4 and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
      elseif tAffs.damagedrightarm and ataxiaTemp.parriedLimb ~= "right arm" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm right arm;sizeup " ..target.. ";assess " ..target
      elseif tAffs.damagedleftarm and ataxiaTemp.parriedLimb ~= "left arm" or tAffs.numbedleftarm then 
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm left arm;sizeup " ..target.. ";assess " ..target
      elseif mprepped_torso == false and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
      elseif m2prepped_head == false and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
      elseif mprepped_rightleg == false and mprepped_leftleg == false and ataxiaTemp.parriedLimb ~= "left leg" or tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "right leg" then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left leg right leg;sizeup " ..target.. ";assess " ..target
      end
    elseif ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.crackedribs < 2 then
      atk = atk.. "wield left flail343168;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm expend torso expend;sizeup " ..target.. ";assess " ..target  
    elseif ataxiaTemp.fractures.wristfractures < 1 then
      atk = atk.. "wield left flail343168;wield right morningstar511735;hellforge invest exploit;doublewhirl " ..target.. " right arm expend right arm expend;sizeup " ..target.. ";assess " ..target  
    elseif not tAffs.clumsiness then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm expend right leg expend;sizeup " ..target.. ";assess " ..target
    end
  
  
  end
  
  --If we have less than 2 momentum, get momentum
elseif ataxia.vitals.class < 2 then
  if ataxiaTemp.fractures.skullfractures <= 1 and tAffs.damagedhead and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
  elseif ataxiaTemp.fractures.crackedribs <= 1 and tAffs.mildtrauma and tAffs.paralysis and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
  elseif tAffs.damagedhead and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
  elseif tAffs.mildtrauma and ataxiaTemp.fractures.crackedribs < 4 and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
  elseif tAffs.damagedrightarm and ataxiaTemp.parriedLimb ~= "right arm" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm right arm;sizeup " ..target.. ";assess " ..target
  elseif tAffs.damagedleftarm and ataxiaTemp.parriedLimb ~= "left arm" or tAffs.numbedleftarm then 
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm left arm;sizeup " ..target.. ";assess " ..target
  elseif mprepped_torso == false and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
  elseif m2prepped_head == false and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
  elseif mprepped_rightleg == false and mprepped_leftleg == false and ataxiaTemp.parriedLimb ~= "left leg" or tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "right leg" then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left leg right leg;sizeup " ..target.. ";assess " ..target
  end
end

if table.contains(ataxia.playersHere, target) then
if falconattack == true then
  if not engaged then
    send("queue addclear freestand " ..atk.. ";engage " ..target)
  else
    send("queue addclear freestand " ..atk)
  end
elseif falconattack == false then
 if not engaged then
    send("queue addclear freestand " ..atk.. ";hyena slay " ..target.." ;engage " ..target)
  else
    send("queue addclear freestand " ..atk.. ";hyena slay " ..target)
  end
end
else
  expandAlias("nt")
  send("queue addclear freestand " ..atk)

end
end




function idwb_proficydamage()
infernaldwbviviprio()
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
flail2damage = DWBWhirlDamage + DWBWhirlDamage

tarlimb = tarlimb or "right arm"
tarlimb2 = tarlimb2 or "none"
if ataxiaTemp.parriedLimb == nil then ataxiaTemp.parriedLimb = "none" end
ataxiaTemp.parriedLimb = ataxiaTemp.parriedLimb or "none"
wieldweapons = wieldweapons or "morningstars"

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 30 then
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
if lb[target].hits["head"] + flail2damage >= 99.9 and not tAffs.damagedhead then 
f2prepped_head = true else
f2prepped_head = false
end

if lb[target].hits["torso"] + mstar2damage >= 99.9 and not tAffs.damagedtorso then 
m2prepped_torso = true else
m2prepped_torso = false
end
if lb[target].hits["torso"] + flail2damage >= 99.9 and not tAffs.damagedtorso then 
f2prepped_torso = true else
f2prepped_torso = false
end

if lb[target].hits["left arm"] + mstar2damage >= 99.9 and not tAffs.damagedleftarm then 
m2prepped_leftarm = true else
m2prepped_leftarm = false
end
if lb[target].hits["left arm"] + flail2damage >= 99.9 and not tAffs.damagedleftarm then 
f2prepped_leftarm = true else
f2prepped_leftarm = false
end

if lb[target].hits["right arm"] + mstar2damage >= 99.9 and not tAffs.damagedrightarm then 
m2prepped_rightarm = true else
m2prepped_rightarm = false
end
if lb[target].hits["right arm"] + flail2damage >= 99.9 and not tAffs.damagedrightarm then 
f2prepped_rightarm = true else
f2prepped_rightarm = false
end

if lb[target].hits["right leg"] + mstar2damage >= 99.9 and not tAffs.damagedrightleg then 
m2prepped_rightleg = true else
m2prepped_rightleg = false
end
if lb[target].hits["right leg"] + flail2damage >= 99.9 and not tAffs.damagedrightleg then 
f2prepped_rightleg = true else
f2prepped_rightleg = false
end

if lb[target].hits["left leg"] + mstar2damage >= 99.9 and not tAffs.damagedleftleg then 
m2prepped_leftleg = true else
m2prepped_leftleg = false
end
if lb[target].hits["left leg"] + flail2damage >= 99.9 and not tAffs.damagedleftleg then 
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

if (tAffs.damagedleftleg or tAffs.brokenleftleg and tAffs.damagedrightleg or tAffs.brokenrightleg and tAffs.damagedleftarm or tAffs.brokenleftarm and tAffs.damagedrightarm or tAffs.brokenrightarm) then
tvivsect = true
else 
tvivisect = false
end

--ATTACKKKKK
 
-- Bisect

if myinstantcath == true then
  atk = atk.." touch shield"

-- Vivisect --
elseif tvivisect == true and ataxiaNDB.players[target].city ~= "Mhaldor" then
  atk = atk.. "dismount;vivisect " ..target
elseif tvivisect == true and ataxiaNDB.players[target].city == "Mhaldor" then
  send("say Vivisect")

elseif use_bisect == true then
  atk = atk.. "wield bastard;quash " ..target.. ";arc;sizeup " ..target.. ";assess " ..target




-- Pulp

elseif not tAffs.shield and (tAffs.concussion or lb[target].hits["head"] >= 200 or ataxiaTemp.fractures.skullfractures >= 5) and tAffs.prone then
  atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";pulp " ..target.. " ;engage " ..target.. ";sizeup " ..target.. " ;assess " ..target

--Raze
elseif tAffs.rebounding or tAffs.shield then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena track " ..target.. ";hyena slay " ..target.. ";fracture " ..target.. " ;assess " ..target.. " ;sizeup " ..target

-- Skull Fractures --
elseif tAffs.prone and ataxia.vitals.class >= 2 then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head expend head expend;assess " ..target.." ;sizeup " ..target
elseif tAffs.prone and ataxia.vitals.class < 2 then
  atk = atk.. " wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
 
--Anti Parry
elseif not tAffs.numbedleftarm and ataxiaTemp.parriedLimb ~= "left arm" and ataxiaTemp.parriedLimb == "left leg" or ataxiaTemp.parriedLimb == "right leg" or ataxiaTemp.parriedLimb == "head" or ataxiaTemp.parriedLimb == "torso" or ataxiaTemp.parriedLimb == "right arm" then
  if ataxia.vitals.class < 1 then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena track " ..target.. " ;hyena slay " ..target.. ";doublewhirl " ..target.. " left arm left arm;sizeup " ..target.. ";assess " ..target
 
  elseif ataxia.vitals.class > 1 then
    if mprepped_head == false then
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend head;sizeup " ..target.. ";assess " ..target
    else 
      atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";hyena slay " ..target.. ";doublewhirl " ..target.. " left arm expend torso;sizeup " ..target.. ";assess " ..target
    end
  end
  
  --If we have above 4 momentum, prone and hit head with flails to give skull fractures
elseif ataxia.vitals.class >= 4 then  
  if ataxiaTemp.parriedLimb ~= "right leg" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right flail408566;hellforge invest torment;doublewhirl " ..target.. " right leg expend head expend;sizeup " ..target.. ";assess " ..target  
  elseif ataxiaTemp.parriedLimb ~= "left leg" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right flail408566;hellforge invest torment;doublewhirl " ..target.. " left leg expend head expend;sizeup " ..target.. ";assess " ..target  
  end
  
  --If we have above 2 momentum, use flails 
elseif ataxia.vitals.class >= 2 then
  if ataxiaTemp.parriedLimb ~= "left arm" or tAffs.numbedleftarm then
    if ataxiaTemp.fractures.skullfractures >= 2 and ataxiaTemp.fractures.crackedribs >= 2 and ataxiaTemp.fractures.wristfractures >= 2 and tAffs.clumsiness then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm expend head expend;sizeup " ..target.. ";assess " ..target
    elseif ataxiaTemp.fractures.skullfractures >= 2 and ataxiaTemp.fractures.crackedribs >= 2 and ataxiaTemp.fractures.wristfractures >= 2 then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm expend left leg expend;sizeup " ..target.. ";assess " ..target
    elseif ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.skullfractures >= 1 and ataxiaTemp.fractures.crackedribs >= 1 then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm expend head expend;sizeup " ..target.. ";assess " ..target  
    elseif ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.crackedribs >= 1 and ataxiaTemp.fractures.skullfractures < 1 then
      if ataxiaTemp.fractures.skullfractures <= 1 and tAffs.damagedhead and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
      elseif ataxiaTemp.fractures.crackedribs <= 1 and tAffs.mildtrauma and tAffs.paralysis and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
      elseif tAffs.damagedhead and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
      elseif tAffs.mildtrauma and ataxiaTemp.fractures.crackedribs < 4 and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
      elseif tAffs.damagedrightarm and ataxiaTemp.parriedLimb ~= "right arm" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm right arm;sizeup " ..target.. ";assess " ..target
      elseif tAffs.damagedleftarm and ataxiaTemp.parriedLimb ~= "left arm" or tAffs.numbedleftarm then 
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm left arm;sizeup " ..target.. ";assess " ..target
      elseif mprepped_torso == false and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
      elseif m2prepped_head == false and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
      elseif mprepped_rightleg == false and mprepped_leftleg == false and ataxiaTemp.parriedLimb ~= "left leg" or tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "right leg" then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left leg right leg;sizeup " ..target.. ";assess " ..target
      end
    elseif ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.crackedribs < 2 then
      atk = atk.. "wield left flail343168;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm expend torso expend;sizeup " ..target.. ";assess " ..target  
    elseif ataxiaTemp.fractures.wristfractures < 1 then
      atk = atk.. "wield left flail343168;wield right morningstar511735;hellforge invest exploit;doublewhirl " ..target.. " left arm expend right arm expend;sizeup " ..target.. ";assess " ..target  
    elseif not tAffs.clumsiness then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm expend right leg expend;sizeup " ..target.. ";assess " ..target
    end
  elseif ataxiaTemp.parriedLimb ~= "right arm" or tAffs.numbedleftarm then
    if ataxiaTemp.fractures.skullfractures >= 2 and ataxiaTemp.fractures.crackedribs >= 2 and ataxiaTemp.fractures.wristfractures >= 2 and tAffs.clumsiness then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm expend head expend;sizeup " ..target.. ";assess " ..target
    elseif ataxiaTemp.fractures.skullfractures >= 2 and ataxiaTemp.fractures.crackedribs >= 2 and ataxiaTemp.fractures.wristfractures >= 2 then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm expend left leg expend;sizeup " ..target.. ";assess " ..target
    elseif ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.skullfractures >= 1 and ataxiaTemp.fractures.crackedribs >= 1 then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm expend head expend;sizeup " ..target.. ";assess " ..target  
    elseif ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.crackedribs >= 1 and ataxiaTemp.fractures.skullfractures < 1 then
      if ataxiaTemp.fractures.skullfractures <= 1 and tAffs.damagedhead and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
      elseif ataxiaTemp.fractures.crackedribs <= 1 and tAffs.mildtrauma and tAffs.paralysis and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
      elseif tAffs.damagedhead and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
      elseif tAffs.mildtrauma and ataxiaTemp.fractures.crackedribs < 4 and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
      elseif tAffs.damagedrightarm and ataxiaTemp.parriedLimb ~= "right arm" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm right arm;sizeup " ..target.. ";assess " ..target
      elseif tAffs.damagedleftarm and ataxiaTemp.parriedLimb ~= "left arm" or tAffs.numbedleftarm then 
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm left arm;sizeup " ..target.. ";assess " ..target
      elseif mprepped_torso == false and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
      elseif m2prepped_head == false and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
      elseif mprepped_rightleg == false and mprepped_leftleg == false and ataxiaTemp.parriedLimb ~= "left leg" or tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "right leg" then
        atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left leg right leg;sizeup " ..target.. ";assess " ..target
      end
    elseif ataxiaTemp.fractures.wristfractures >= 1 and ataxiaTemp.fractures.crackedribs < 2 then
      atk = atk.. "wield left flail343168;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm expend torso expend;sizeup " ..target.. ";assess " ..target  
    elseif ataxiaTemp.fractures.wristfractures < 1 then
      atk = atk.. "wield left flail343168;wield right morningstar511735;hellforge invest exploit;doublewhirl " ..target.. " right arm expend right arm expend;sizeup " ..target.. ";assess " ..target  
    elseif not tAffs.clumsiness then
      atk = atk.. "wield left flail343168;wield right flail408566;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm expend right leg expend;sizeup " ..target.. ";assess " ..target
    end
  
  
  end
  
  --If we have less than 2 momentum, get momentum
elseif ataxia.vitals.class < 2 then
  if ataxiaTemp.fractures.skullfractures <= 1 and tAffs.damagedhead and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
  elseif ataxiaTemp.fractures.crackedribs <= 1 and tAffs.mildtrauma and tAffs.paralysis and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
  elseif tAffs.damagedhead and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
  elseif tAffs.mildtrauma and ataxiaTemp.fractures.crackedribs < 4 and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
  elseif tAffs.damagedrightarm and ataxiaTemp.parriedLimb ~= "right arm" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " right arm right arm;sizeup " ..target.. ";assess " ..target
  elseif tAffs.damagedleftarm and ataxiaTemp.parriedLimb ~= "left arm" or tAffs.numbedleftarm then 
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left arm left arm;sizeup " ..target.. ";assess " ..target
  elseif mprepped_torso == false and ataxiaTemp.parriedLimb ~= "torso" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " torso torso;sizeup " ..target.. ";assess " ..target
  elseif m2prepped_head == false and ataxiaTemp.parriedLimb ~= "head" or tAffs.numbedleftarm then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " head head;sizeup " ..target.. ";assess " ..target
  elseif mprepped_rightleg == false and mprepped_leftleg == false and ataxiaTemp.parriedLimb ~= "left leg" or tAffs.numbedleftarm or ataxiaTemp.parriedLimb ~= "right leg" then
    atk = atk.. "wield left morningstar511732;wield right morningstar511735;hellforge invest " ..toppression.. ";doublewhirl " ..target.. " left leg right leg;sizeup " ..target.. ";assess " ..target
  end
end

if table.contains(ataxia.playersHere, target) then
if falconattack == true then
  if not engaged then
    send("queue addclear freestand " ..atk.. ";engage " ..target)
  else
    send("queue addclear freestand " ..atk)
  end
elseif falconattack == false then
 if not engaged then
    send("queue addclear freestand " ..atk.. ";hyena slay " ..target.." ;engage " ..target)
  else
    send("queue addclear freestand " ..atk.. ";hyena slay " ..target)
  end
end
else
  expandAlias("nt")
  send("queue addclear freestand " ..atk)

end
end