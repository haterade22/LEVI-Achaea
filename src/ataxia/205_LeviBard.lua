-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > Bard > LeviBard

function levibardone()
local atk = combatQueue()
local sp = ataxia.settings.separator

bardtempostance = bardtempostance or "none"
bardsunset = bardsunset or false
bardsunrise = bardsunrise or false
bladefinale = bladefinale or false
bardtemposequence = bardtemposequence or 0

--Get Targets Anti Active Cure
getLockingAffliction()

--Get Target Lock Status
checkTargetLocks()

--Rapier Damage Capture
rapierdamage = ataxiaTables.limbData.bardRapier

if checkAffList({"paralysis", "asthma", "weariness",  "clumsiness", "impatience", "addiction", "nausea","generosity", "heathleech", "confusion", "recklessness", "diminished", "haemophilia", "sensitivity"},3) then
  bardflick = true
else
  bardflick = false
end

--Prep Function
if lb[target].hits["head"] + rapierdamage >= 100 and not tAffs.damagedhead then 
bprepped_head = true else
bprepped_head = false
end
if lb[target].hits["torso"] + rapierdamage >= 100 and not tAffs.mildtrauma then 
bprepped_torso = true else
bprepped_torso = false
end
if lb[target].hits["left leg"] + rapierdamage >= 100 and not tAffs.damagedleftleg then 
bprepped_leftleg = true else
bprepped_leftleg = false
end
if lb[target].hits["right leg"] + rapierdamage >= 100 and not tAffs.damagedrightleg then 
bprepped_rightleg = true else
bprepped_rightleg = false
end
if lb[target].hits["right arm"] + rapierdamage >= 100 and not tAffs.damagedrightarm then 
bprepped_rightarm = true else
bprepped_rightarm = false
end
if lb[target].hits["left arm"] + rapierdamage >= 100 and not tAffs.damagedleftarm then 
bprepped_leftarm = true else
bprepped_leftarm = false
end




envenomList = {}
bardrefrain = {}
if not tAffs.paralysis then
  table.insert(bardrefrain,"paean")
elseif not tAffs.asthma then
  table.insert(bardrefrain,"ode")
elseif not tAffs.slickness then
  table.insert(bardrefrain,"ghazal")
elseif not tAffs.lethargy then
  table.insert(bardrefrain,"elegy")
elseif not tAffs.sensitivity then
  table.insert(bardrefrain,"prosodion")
elseif not tAffs.dizziness then
  table.insert(bardrefrain,"bhajan")
elseif not tAffs.addiction then
  table.insert(bardrefrain,"gusheh")
else 
  table.insert(bardrefrain,"paean")
end 

if tAffs.shield or tAffs.rebounding then
  atk = atk.."blade punctuate " ..target.. " " ..bardrefrain[1]
elseif bladefinale == true then
  atk = atk.."blade flick " ..target.. ";finale " ..target
elseif bardsunset == true then
  atk = atk.."wield right fang;wipe fang;envenom fang with slike;jab " ..target
elseif bprepped_head == true and bprepped_leftarm == true and (tAffs.mildtramua and tAffs.damagedleftleg) or bardsunrise == true then
  atk = atk.."blade sunset " ..target.. " left paean"
elseif bprepped_head == true and bprepped_rightarm == true and (tAffs.mildtramua and tAffs.damagedrightleg) or bardsunrise == true then
  atk = atk.."blade sunset " ..target.. " right paean"

elseif bprepped_head == true and bprepped_rightarm == true and bprepped_torso == true and bprepped_leftleg == true then
  atk = atk.."blade sunrise " ..target.. " left " ..bardrefrain[1]
elseif bprepped_head == true and bprepped_leftarm == true and bprepped_torso == true and bprepped_leftleg == true then
  atk = atk.."blade sunrise " ..target.. " left " ..bardrefrain[1]
elseif bprepped_head == true and bprepped_rightarm == true and bprepped_torso == true and bprepped_rightleg == true then
  atk = atk.."blade sunrise " ..target.. " right " ..bardrefrain[1]
elseif bprepped_head == true and bprepped_leftarm == true and bprepped_torso == true and bprepped_rightleg == true then
  atk = atk.."blade sunrise " ..target.. " right " ..bardrefrain[1]

elseif tAffs.crescendo == 0 or tAffs.crescendo == false then
  atk = atk.."blade flick " ..target.. " " ..bardrefrain[1] 
  
elseif bprepped_head == true and bprepped_rightarm == true and bprepped_torso == true and bprepped_leftleg == false then
  atk = atk.."blade heelsnap " ..target.. " left " ..bardrefrain[1]
elseif bprepped_head == true and bprepped_leftarm == true and bprepped_torso == true and bprepped_leftleg == false then
  atk = atk.."blade heelsnap " ..target.. " left " ..bardrefrain[1]
elseif bprepped_head == true and bprepped_rightarm == true and bprepped_torso == true and bprepped_rightleg == false then
  atk = atk.."blade heelsnap " ..target.. " right " ..bardrefrain[1]
elseif bprepped_head == true and bprepped_leftarm == true and bprepped_torso == true and bprepped_rightleg == false then
  atk = atk.."blade heelsnap " ..target.. " right " ..bardrefrain[1]

elseif bprepped_head == true and bprepped_leftarm == true and bprepped_torso == false then
  atk = atk.."blade jab " ..target.. " torso " ..bardrefrain[1]
elseif bprepped_head == true and bprepped_rightarm == true and bprepped_torso == false then
  atk = atk.."blade jab " ..target.. " torso " ..bardrefrain[1]
  
 
elseif bprepped_head == true and bprepped_leftarm == false then
  atk = atk.."blade highsun " ..target.. " left arm " ..bardrefrain[1]
elseif bprepped_head == true and bprepped_rightarm == false then
  atk = atk.."blade highsun " ..target.. " right arm " ..bardrefrain[1]
  
elseif tAffs.crescendo == 0 or tAffs.crescendo == false then
  atk = atk.."blade flick " ..target.. " " ..bardrefrain[1]
elseif bprepped_head == false and not tAffs.damagedhead then
  atk = atk.."blade highsun " ..target.. " head " ..bardrefrain[1]
elseif bprepped_leftarm == false and not tAffs.damagedleftarm then
  atk = atk.."blade highsun " ..target.. " left arm " ..bardrefrain[1]
elseif bprepped_rightarm == false and not tAffs.damagedrightarm then
  atk = atk.."blade highsun " ..target.. " right arm " ..bardrefrain[1]
elseif bprepped_torso == false and not tAffs.mildtraumna then 
  atk = atk.."blade jab " ..target.. " torso " ..bardrefrain[1]
elseif bprepped_leftleg == false and not tAffs.damagedleftleg then
  atk = atk.."blade heelsnap " ..target.. " left " ..bardrefrain[1]
elseif bprepped_rightleg == false and not tAffs.damagedrightleg then 
  atk = atk.."blade heelsnap " ..target.. " left " ..bardrefrain[1]
end
  
 
if bardsunset == false then
send("queue addclearfull freestand wield left lyre;wield right rapier;" ..atk)
elseif bardsunset == true then
table.insert(envenomList,"slike")
send("queue addclearfull freestand " ..atk)
end

--End Function  
end


function levibardtwo()
local atk = combatQueue()
local sp = ataxia.settings.separator


bardtempostance = bardtempostance or "none"
bardsunset = bardsunset or false
bardsunrise = bardsunrise or false
bladefinale = bladefinale or false
bardtemposequence = bardtemposequence or 0

--Get Targets Anti Active Cure
getLockingAffliction()

--Get Target Lock Status
checkTargetLocks()

--Rapier Damage Capture
rapierdamage = ataxiaTables.limbData.bardRapier

if checkAffList({"paralysis", "asthma", "weariness",  "clumsiness", "impatience", "addiction", "nausea","generosity", "heathleech", "confusion", "recklessness", "diminished", "haemophilia", "sensitivity"},3) then
  bardflick = true
else
  bardflick = false
end

--Prep Function
if lb[target].hits["head"] + rapierdamage >= 100 and not tAffs.damagedhead then 
bprepped_head = true else
bprepped_head = false
end
if lb[target].hits["torso"] + rapierdamage >= 100 and not tAffs.mildtrauma then 
bprepped_torso = true else
bprepped_torso = false
end
if lb[target].hits["left leg"] + rapierdamage >= 100 and not tAffs.damagedleftleg then 
bprepped_leftleg = true else
bprepped_leftleg = false
end
if lb[target].hits["right leg"] + rapierdamage >= 100 and not tAffs.damagedrightleg then 
bprepped_rightleg = true else
bprepped_rightleg = false
end
if lb[target].hits["right arm"] + rapierdamage >= 100 and not tAffs.damagedrightarm then 
bprepped_rightarm = true else
bprepped_rightarm = false
end
if lb[target].hits["left arm"] + rapierdamage >= 100 and not tAffs.damagedleftarm then 
bprepped_leftarm = true else
bprepped_leftarm = false
end




envenomList = {}
bardrefrain = {}
if not tAffs.paralysis then
  table.insert(bardrefrain,"paean")
elseif not tAffs.asthma then
  table.insert(bardrefrain,"ode")
elseif not tAffs.slickness then
  table.insert(bardrefrain,"ghazal")
elseif not tAffs.lethargy then
  table.insert(bardrefrain,"elegy")
elseif not tAffs.sensitivity then
  table.insert(bardrefrain,"prosodion")
elseif not tAffs.dizziness then
  table.insert(bardrefrain,"bhajan")
elseif not tAffs.addiction then
  table.insert(bardrefrain,"gusheh")
else 
  table.insert(bardrefrain,"paean")
end 

if tAffs.shield or tAffs.rebounding then
  atk = atk.."blade punctuate " ..target.. " " ..bardrefrain[1]

  
elseif bprepped_torso == true and bardsunset == true and bardtempo == "back" then
  atk = atk.."blade jab " ..target.. " torso " ..bardrefrain[1]

elseif bprepped_head == true and bprepped_rightarm == true and bprepped_torso == true then
  if bardtempo == "back" and (bardtempostance == "Adagio" and bardtemposequence <= 1) or (bardtempostance == "Moderato" and bardtemposequence == 0) then 
    atk = atk.."blade sunset " ..target.. " right bhajan"
  elseif bardtempo == "side" and (bardtempostance == "Adagio" and bardtemposequence == 3) or (bardtempostance == "Moderato" and bardtemposequence == 1) or (bardtempostance == "Allegro" and bardtemposequence == 0) then 
    atk = atk.."blade sunset " ..target.. " right bhajan"
  else
    atk = atk.."blade flick " ..target.. " " ..bardrefrain[1]
  end
elseif bprepped_head == true and bprepped_leftarm == true and bprepped_torso == true  then
  if bardtempo == "back" and (bardtempostance == "Adagio" and bardtemposequence <= 1) or (bardtempostance == "Moderato" and bardtemposequence == 0) then 
    atk = atk.."blade sunset " ..target.. " left bhajan"
  elseif bardtempo == "side" and (bardtempostance == "Adagio" and bardtemposequence == 3) or (bardtempostance == "Moderato" and bardtemposequence == 1) or (bardtempostance == "Allegro" and bardtemposequence == 0) then 
    atk = atk.."blade sunset " ..target.. " left bhajan"
  else
    atk = atk.."blade flick " ..target.. " " ..bardrefrain[1]
  end
elseif bladefinale == true then
  atk = atk..";finale " ..target

elseif bprepped_head == true and bprepped_leftarm == true and bprepped_torso == false then
  atk = atk.."blade jab " ..target.. " torso " ..bardrefrain[1]
elseif bprepped_head == true and bprepped_rightarm == true and bprepped_torso == false then
  atk = atk.."blade jab " ..target.. " torso " ..bardrefrain[1]
  
 
elseif bprepped_head == true and bprepped_leftarm == false then
  atk = atk.."blade highsun " ..target.. " left arm " ..bardrefrain[1]
elseif bprepped_head == true and bprepped_rightarm == false then
  atk = atk.."blade highsun " ..target.. " right arm " ..bardrefrain[1]

elseif tAffs.crescendo == 0 or tAffs.crescendo == false then
  atk = atk.."blade flick " ..target.. " " ..bardrefrain[1]
elseif bprepped_head == false and not tAffs.damagedhead then
  atk = atk.."blade highsun " ..target.. " head " ..bardrefrain[1]
elseif bprepped_leftarm == false and not tAffs.damagedleftarm then
  atk = atk.."blade highsun " ..target.. " left arm " ..bardrefrain[1]
elseif bprepped_rightarm == false and not tAffs.damagedrightarm then
  atk = atk.."blade highsun " ..target.. " right arm " ..bardrefrain[1]
elseif bprepped_torso == false and not tAffs.mildtraumna then 
  atk = atk.."blade jab " ..target.. " torso " ..bardrefrain[1]
end
  
 
send("queue addclearfull freestand wield left lyre;wield right rapier;" ..atk)



--End Function  
end