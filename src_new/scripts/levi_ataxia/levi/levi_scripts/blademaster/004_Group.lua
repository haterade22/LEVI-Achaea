--[[mudlet
type: script
name: Group
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Blademaster
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--17.0/11.3
function bm_groupfighting()
bmgrouplock()
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
if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 21 then
use_bisect = true else
use_bisect = false
end

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 26 then
use_bisect2 = true else
use_bisect2 = false
end

ataxiaTemp.tarTumble = ataxiaTemp.tarTumble or false
tarpreapply = tarpreapply or false
tAffs.bleed = tAffs.bleed or 0
bmslash1 = bmslash1 or ataxiaTables.limbData.bmSlash
bmslash2 = bmslash2 or ataxiaTables.limbData.bmOffSlash
bmcslash = bmcslash or ataxiaTables.limbData.bmCompass
ataxiaTemp.parriedLimb = ataxiaTemp.parriedLimb or "none"

if lb[target].hits["head"] + bmslash1 >= 100 and not tAffs.damagedhead then 
mprepped_head = true else
mprepped_head = false
end

if lb[target].hits["torso"] + bmslash1 >= 99 and not tAffs.damagedtorso then 
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




if ataxiaNDB.players[target].city == "Mhaldor" and tAffs.bleed >= 600 then
send("say BrokenStarrrrrrr")

elseif ataxiaNDB.players[target].city ~= "Mhaldor" and tAffs.bleed >= 600 then
atk = atk.. "withdraw blade;sheathe sword;brokenstar " ..target

elseif tAffs.impaled and timpaleslash == true then
atk = atk.."bladetwist;assess "..target..";discern " ..target

elseif tAffs.impaled and timpaleslash == false then
atk = atk.. " assess "..target..";impaleslash"


elseif tAffs.prone and lb[target].hits["left leg"] >= 100 and lb[target].hits["right leg"] >= 100 and not tAffs.impaled then
atk = atk.. " assess "..target..";impale " ..target

elseif tAffs.prone and lb[target].hits["left leg"] >= 100 or lb[target].hits["right leg"] >= 100 and not tAffs.impaled then
atk = atk.. " assess "..target..";impale " ..target
else
atk = atk.. "infuse ice;pommelstrike " ..target.. " " ..tstrike.. ";assess " ..target  

end
  
if use_bisect == true then
  send("queue addclear freestand " ..atk)
elseif tAffs.rebounding or tAffs.shield then
  send("queue addclear freestand raze " ..target.. " " ..tstrike.. "assess " ..target)
elseif not engaged then
  send("queue addclear freestand " ..atk.. ";engage " ..target)
else
send("queue addclear freestand " ..atk)

end
end













