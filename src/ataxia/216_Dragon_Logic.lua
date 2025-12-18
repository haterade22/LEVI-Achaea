-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > DRAGON > Dragon Logic

--07:11:06:721
--07:11:08:707 

function levidragongroup()
local atk = combatQueue()
curses = {}
venoms = {}
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
 
--Target 
dragonrenddamage = ataxiaTables.limbData.dragonRend
 
 
if lb[target].hits["head"] + dragonrenddamage >= 100 and not tAffs.damagedhead then 
mprepped_head = true else
mprepped_head = false
end

if lb[target].hits["torso"] + dragonrenddamage >= 100 and not tAffs.damagedtorso then 
mprepped_torso = true else
mprepped_torso = false
end


if lb[target].hits["left leg"] + dragonrenddamage >= 100 and not tAffs.damagedleftleg then 
mprepped_leftleg = true else
mprepped_leftleg = false
end


if lb[target].hits["right leg"] + dragonrenddamage >= 100 and not tAffs.damagedrightleg then 
mprepped_rightleg = true else
mprepped_rightleg = false
end


if lb[target].hits["right arm"] + dragonrenddamage >= 100 and not tAffs.damagedrightarm then 
mprepped_rightarm = true else
mprepped_rightarm = false
end


if lb[target].hits["left arm"] + dragonrenddamage >= 100 and not tAffs.damagedleftarm then 
mprepped_leftarm = true else
mprepped_leftarm = false
end



--Dragon Curse
if truelock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis then
    table.insert(curses,"paralysis") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness then
    table.insert(curses,"weariness")
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity then
    table.insert(curses,"stupidity")
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness then
    table.insert(curses,"recklessness")
  end
elseif hardlock == true and not tAffs.paralysis then
  table.insert(curses,"paralysis")
elseif softlock == true and not tAffs.paralysis then
  table.insert(curses,"paralysis")
elseif softlock == true and tAffs.paralysis and not tAffs.impatience then
  table.insert(curses,"impatience")
elseif not tAffs.impatience then
  table.insert(curses,"impatience")
elseif tAffs.impatience then
  if not tAffs.paralysis then
   table.insert(curses,"paralysis")
  elseif not tAffs.asthma then
    table.insert(curses,"asthma")
  elseif not tAffs.weariness then
    table.insert(curses,"weariness")
  elseif not tAffs.stupidity then
    table.insert(curses,"stupidity")
  elseif not tAffs.sensitivity then
    table.insert(curses,"sensitivity")
  else
    table.insert(curses,"recklessness")
  
  end
end

--Venom
if truelock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis and curses[1] ~= "paralysis" then
    table.insert(venoms,"curare") 
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness and curses[1] ~= "weariness" then
    table.insert(venoms,"vernalius")
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague then
    table.insert(venoms,"voyria")
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity and curses[1] ~= "stupidity" then
    table.insert(venoms,"aconite")
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness and curses[1] ~= "recklessness" then
    table.insert(venoms,"eurypteria")
  end
elseif hardlock == true and not tAffs.paralysis and curses[1] ~= "paralysis" then
  table.insert(venoms,"curare")
elseif softlock == true and not tAffs.paralysis and curses[1] ~= "paralysis" then
  table.insert(venoms,"curare")
elseif not tAffs.paralysis and curses[1] ~= "paralysis" then
  table.insert(venoms,"curare")
elseif tAffs.slickness and tAffs.asthma and tAffs.impatience and not tAffs.anorexia then
    table.insert(venoms,"slike")
elseif not tAffs.slickness and tAffs.asthma and tAffs.impatience then
    table.insert(venoms,"gecko")
elseif tAffs.impatience and not tAffs.stupidity and curses[1] ~= "stupidity" then
  table.insert(venoms,"aconite")
elseif tAffs.impatience and not tAffs.asthma and curses[1] ~= "asthma" then
    table.insert(venoms,"kalmia")
elseif not tAffs.asthma and curses[1] ~= "asthma" then
    table.insert(venoms,"kalmia")
elseif not tAffs.clumsiness then
    table.insert(venoms,"xentio")
elseif not tAffs.weariness and curses[1] ~= "weariness" then
    table.insert(venoms,"vernalius")
end




--Logic
if tAffs.shield then
	atk = atk.."dragoncurse " ..target.. " "..curses[1].. " 2.4;tailsmash " ..target
elseif tAffs.prone and tAffs.damagedleftleg or tAffs.brokenleftleg or lb[target].hits["left leg"] >= 100 and tAffs.damagedrightleg or tAffs.brokenrightleg or lb[target].hits["right leg"] >= 100 then
  atk = atk.."wield shield;dragoncurse " ..target.. " sensitivity 1;bite " ..target
elseif mprepped_rightleg and tAffs.damagedleftleg or lb[target].hits["left leg"] >= 100 and not tAffs.damagedrightleg then
  atk = atk.."wield shield;dragoncurse " ..target.. " "..curses[1].. " 2.4;rend " ..target.. " right leg " ..venoms[1].. ";breathgust "..target
elseif mprepped_leftleg and tAffs.damagedrightleg or lb[target].hits["right leg"] >= 100 and not tAffs.damagedleftleg then
  atk = atk.."wield shield;dragoncurse " ..target.. " "..curses[1].. " 2.4;rend " ..target.. " left leg " ..venoms[1].. ";breathgust "..target
elseif mprepped_leftleg and mprepped_rightleg and tAffs.mildtrauma or lb[target].hits["torso"] >= 100 and ataxiaTemp.parriedLimb ~= "right leg" then
  atk = atk.."wield shield;dragoncurse " ..target.. " "..curses[1].. " 2.4;rend " ..target.. " right leg " ..venoms[1].. ";breathgust "..target
elseif mprepped_leftleg and mprepped_rightleg and tAffs.mildtrauma or lb[target].hits["torso"] >= 100 and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.."wield shield;dragoncurse " ..target.. " "..curses[1].. " 2.4;rend " ..target.. " left leg " ..venoms[1].. ";breathgust "..target

elseif mprepped_leftleg and mprepped_rightleg and mprepped_torso and ataxiaTemp.parriedLimb ~= "torso" then
  atk = atk.."wield shield;dragoncurse " ..target.. " "..curses[1].. " 2.4;rend " ..target.. " torso " ..venoms[1].. ";breathgust "..target
elseif not mprepped_torso and ataxiaTemp.parriedLimb ~= "torso" then
  atk = atk.."wield shield;dragoncurse " ..target.. " "..curses[1].. " 2.4;rend " ..target.. " torso " ..venoms[1].. ";breathgust "..target
elseif not mprepped_rightleg and ataxiaTemp.parriedLimb ~= "right leg" then
  atk = atk.."wield shield;dragoncurse " ..target.. " "..curses[1].. " 2.4;rend " ..target.. " right leg " ..venoms[1].. ";breathgust "..target
elseif not mprepped_leftleg and ataxiaTemp.parriedLimb ~= "left leg" then
  atk = atk.."wield shield;dragoncurse " ..target.. " "..curses[1].. " 2.4;rend " ..target.. " left leg " ..venoms[1].. ";breathgust "..target
else
  atk = atk.."wield shield;dragoncurse " ..target.. " "..curses[1].. " 2;rend " ..target.. " " ..venoms[1].. ";breathgust "..target
  
end
  
  
--Attack
if not ataxia.afflictions.aeon then
	send("queue addclear freestand " ..atk)
end


end