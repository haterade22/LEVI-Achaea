--[[mudlet
type: script
name: BLACKOUT HELL
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- INFERNAL
- I SNB
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function infernalpriosblackout()
if ataxia.afflictions.blackout then

send("queue addclear free touch shield")
else

local atk = combatQueue()

add_dedication = false
need_raze = false
partyrelay = partyrelay or false
strikingHigh = false

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
  



if tAffs.haemophilia then invest = "agony" elseif getMentalAffCount() >= 3 then invest = "punishment" else invest = "agony" end
  
  

--SHIELDNEED

  shieldneed = {}
  
if ferocity_full and not tAffs.blackout then 
  table.insert(shieldneed,"concuss")
   
  
elseif tAffs.prone and not tAffs.blackout then
    table.insert(shieldneed,"concuss")
  

elseif tAffs.slickness and tAffs.asthma then
    table.insert(shieldneed,"smash high")


elseif tAffs.anorexia then
    table.insert(shieldneed,"smash high")



elseif softlock and tAffs.paralysis  then
    table.insert(shieldneed,"smash high")



elseif not tAffs.paralysis then
    table.insert(shieldneed,"smash mid")
    
elseif not tAffs.asthma then
    table.insert(shieldneed,"drive")
    
    
elseif not tAffs.clumsiness then
    table.insert(shieldneed,"smash low")
    

else
    table.insert(shieldneed,"smash high")
end

--SWORDLIST

swordneed = {}

if ferocity_full and not tAffs.blackout and not tAffs.prone and
tBals.tree and tLimbs.RL >= 92.4 and tLimbs.RL < 100 and tLimbs.LL >= 92.4 then
targetlimb = "right leg"
    table.insert(swordneed,"hellforge invest "..invest..";combination "..target.." slice curare")
end

if not tAffs.paralysis and shieldneed[1] ~= "smash mid" and softlock then
    table.insert(swordneed,"hellforge invest "..invest..";combination "..target.." slice curare")
end

if not tAffs.slickness and tAffs.asthma and not tBals.tree then
     table.insert(swordneed,"hellforge invest "..invest..";combination "..target.." slice gecko")
end

if not tAffs.slickness and tAffs.asthma and tAffs.clumsiness and tAffs.weariness then
     table.insert(swordneed,"hellforge invest "..invest..";combination "..target.." slice gecko")
end


if tAffs.anorexia and not tAffs.stupidity then
   table.insert(swordneed,"hellforge invest "..invest..";combination "..target.." slice aconite")
   end

if tAffs.anorexia and not tAffs.recklessness then
   table.insert(swordneed,"hellforge invest "..invest..";combination "..target.." slice eurypteria")
   end
if tAffs.anorexia and not tAffs.dizziness then
   table.insert(swordneed,"hellforge invest "..invest..";combination "..target.." slice larkspur")
   end

if tAffs.anorexia and not tAffs.shyness then
   table.insert(swordneed,"hellforge invest "..invest..";combination "..target.." slice digitalis")
   end

if not tAffs.anorexia and tAffs.slickness then
    table.insert(swordneed,"hellforge invest "..invest..";combination "..target.." slice slike")
end

   
if not tAffs.clumsiness and shieldneed[1] ~= "smash low" then
      table.insert(swordneed,"hellforge invest "..invest..";combination "..target.." slice xentio")
end
   if tAffs.asthma and tAffs.clumsiness and not tAffs.weariness then
    table.insert(swordneed,"wipe longsword441711;hellforge invest exploit;combination "..target.." slice")
end

if not tAffs.paralysis and shieldneed[1] ~= "smash mid" then
    table.insert(swordneed,"hellforge invest "..invest..";combination "..target.." slice curare")
end

if not tAffs.asthma and shieldneed[1] ~= "drive" then
  table.insert(swordneed,"hellforge invest "..invest..";combination "..target.." slice kalmia")
end

  if not tAffs.nausea and not softlock then
  table.insert(swordneed,"hellforge invest "..invest..";combination "..target.." slice euphorbia")
end



if tAffs.prone and tAffs.paralysis and tAffs.slickness then
table.insert(swordneed,"hellforge invest "..invest..";combination "..target.." slice epseth")
   end
   
   if softlock and not tAffs.paralysis then
   table.insert(swordneed,"hellforge invest "..invest..";combination "..target.." slice curare")
   end


   
   if softlock and not tAffs.confusion then
  table.insert(swordneed,"wipe longsword441711;hellforge invest torment;combination "..target.." slice")
   end
   

   

   
if not softlock and not tAffs.haemophilia then
 table.insert(swordneed,"wipe longsword441711;hellforge invest torture;combination "..target.." slice")
end
  

if not softlock and not tAffs.healthleech then
 table.insert(swordneed,"wipe longsword441711;hellforge invest torment;combination "..target.." slice")
end


if not softlock and not tAffs.sensitivity then
  table.insert(swordneed,"hellforge invest "..invest..";combination "..target.." slice prefarar")
end



if not tAffs.addiction then
  table.insert(swordneed,"hellforge invest "..invest..";combination "..target.." slice vardrax")
end






--ATTACK


local atk = combatQueue()


if ataxia.afflictions.paralysis and not ataxia.afflictions.prone 
and (tonumber(gmcp.Char.Vitals.hp) >=  tonumber(gmcp.Char.Vitals.maxhp)*.7) 
and (tonumber(gmcp.Char.Vitals.mp) >= tonumber(gmcp.Char.Vitals.maxmp)*.6) and
(ataxiaNDB_getClass(target) ~= "Apostate" or ataxiaNDB_getClass(target)) ~= "Priest" then

add_dedication = true
else 
add_dedication = false
end



if tAffs.rebounding or tAffs.shield then

need_raze = true
else
need_raze = false
end

if ataxia.vitals.class == 4 then
ferocity_full = true
else 
ferocity_full = false
end

if (tAffs.brokenrightleg or tAffs.damagedrightleg) and (tAffs.brokenleftleg or tAffs.damagedleftleg)
 and (tAffs.brokenleftarm or tAffs.damagedleftarm)  and  (tAffs.brokenrightarm or tAffs.damagedrightarm) then
vivisect = true
else
vivisect = false
end


if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 30 then
quash_arc = true
else
quash_arc = false
end

if quash_arc then

atk = "stand;wield shield longsword441711;assess "..target..";quash "..target..";arc "..target.." curare"

elseif need_raze then
atk = atk.."wield shield longsword441711;assess "..target..";combination " ..target.. " raze " ..shieldneed[1]

elseif vivisect then
atk = atk.."wield shield longsword441711;assess "..target..";vivisect "..target


elseif ferocity_full and not tAffs.prone and not tAffs.blackout then
atk = atk.."wield shield longsword441711;assess "..target..";shieldstrike "..target.." low;"..swordneed[1].." "..shieldneed[1]


elseif ferocity_full and tLimbs.RL < 100 and tLimbs.RL >= 92.4 and tAffs.slickness then
atk = atk.."wield shield longsword441711;assess "..target..";shieldstrike "..target.." low;hellforge invest "..invest..";combination "..target.." slice right leg slike smash high"

elseif ferocity_full and tLimbs.LL < 100 and tLimbs.LL >= 92.4 and tAffs.slickness then
atk = atk.."wield shield longsword441711;assess "..target..";shieldstrike "..target.." low;hellforge invest "..invest..";combination "..target.." slice left leg slike smash high"

elseif tAffs.prone and tLimbs.LL < 100 and tLimbs.LL >= 92.4 and tAffs.slickness then
atk = atk.."wield shield longsword441711;assess "..target..";hellforge invest "..invest..";combination "..target.." slice left leg slike smash high"

elseif tAffs.prone and tLimbs.LL < 100 and tLimbs.LL >= 92.4 and tAffs.slickness then
atk = atk.."wield shield longsword441711;assess "..target..";hellforge invest "..invest..";combination "..target.." slice left leg slike smash high"


elseif ferocity_full and not tAffs.sensitivity then

atk = atk.."wield shield longsword441711;assess "..target..";shieldstrike "..target.." mid;"..swordneed[1].." "..shieldneed[1]


else
atk = atk.."wield shield longsword441711;assess "..target..";"..swordneed[1].." "..shieldneed[1]

end

if partyrelay and ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 40 then send("pt "..target..": Health is at "..ataxiaTemp.lastAssess.."%")
end
if not ataxia.settings.paused then
 if add_dedication then
 send("queue addclear free dedication;"..atk)
elseif quash_arc then
send("setalias quasharc "..atk)
send("queue addclear free quasharc")
elseif not engaged then
send("queue addclear free "..atk..";engage "..target)

else

send("queue addclear free "..atk)

end

end
end
end