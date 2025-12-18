-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > INFERNAL > I SNB > PRIOS WEARINESS

function infernalpriosweariness()
envenomList = {}

local atk = combatQueue()

partyrelay = partyrelay or false
strikingHigh = true

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
  


 

--SHIELDNEED

  shieldneed = {}
  



if not softlock and tAffs.slickness and tAffs.asthma then
    table.insert(shieldneed,"smash high")



elseif treelock then
    table.insert(shieldneed,"smash high")



elseif not tAffs.paralysis then
    table.insert(shieldneed,"smash mid")
    
    elseif not tAffs.clumsiness then
    table.insert(shieldneed,"smash low")
    
    
elseif not tAffs.asthma then
    table.insert(shieldneed,"drive")
    
    


else
    table.insert(shieldneed,"smash high")
end













--SWORDLIST

swordneed = {}

if tAffs.slickness and not tAffs.anorexia then
    table.insert(swordneed,"combination "..target.." slice slike")
    table.insert(envenomList, "slike")
end

if ferocity_full and not tAffs.slickness and tAffs.asthma and not tBals.tree and shieldneed[1] == "smash mid" then
     table.insert(swordneed,"shieldstrike "..target.." low;combination "..target.." slice gecko")
  table.insert(envenomList, "gecko")
end

if (tAffs.prone or ferocity_full) and not tAffs.slickness and tAffs.asthma and tAffs.weariness then
     table.insert(swordneed,"shieldstrike "..target.." low;combination "..target.." slice gecko")
     table.insert(envenomList, "gecko")
end

if  not tAffs.slickness and tAffs.asthma and tAffs.paralysis then
     table.insert(swordneed,"combination "..target.." slice gecko")
     table.insert(envenomList, "gecko")
end

if treelock and not tAffs.stupidity then
   table.insert(swordneed,"combination "..target.." slice aconite")
   table.insert(envenomList, "aconite")
   end

if treelock and not tAffs.recklessness then
   table.insert(swordneed,"combination "..target.." slice eurypteria")
   table.insert(envenomList, "eurypteria")
   end
if treelock and not tAffs.dizziness then
   table.insert(swordneed,"combination "..target.." slice larkspur")
   table.insert(envenomList, "larkspur")
   end

if treelock and not tAffs.shyness then
   table.insert(swordneed,"combination "..target.." slice digitalis")
   table.insert(envenomList, "digitalis")
   end
if treelock and not brokenleftarm then
  table.insert(swordneed,"combination "..target.." slice epteth")
  table.insert(envenomList, "epteth")
   end
if treelock and not brokenrightarm then
  table.insert(swordneed,"combination "..target.." slice epteth")
  table.insert(envenomList, "epteth")
   end

if treelock and not brokenleftleg then
  table.insert(swordneed,"combination "..target.." slice epseth")
  table.insert(envenomList, "epseth")
   end
   
if treelock and not brokenrightleg then
  table.insert(swordneed,"combination "..target.." slice epseth")
  table.insert(envenomList, "epseth")
   end

if not tAffs.paralysis and shieldneed[1] ~= "smash mid" then
    table.insert(swordneed,"combination "..target.." slice curare")
    table.insert(envenomList, "curare")
end

   if  not tAffs.weariness then
    table.insert(swordneed,"combination "..target.." slice vernalius")
    table.insert(envenomList, "vernalius")
end

if not tAffs.asthma and shieldneed[1] ~= "drive" then
    table.insert(swordneed,"combination "..target.." slice kalmia")
    table.insert(envenomList, "kalmia")
end


if not tAffs.clumsiness and shieldneed[1] ~= "smash low" then
    table.insert(swordneed,"combination "..target.." slice xentio")
    table.insert(envenomList, "xentio")
end




  if not tAffs.nausea and not softlock and not tAffs.slickness then
    table.insert(swordneed,"combination "..target.." slice euphorbia")
    table.insert(envenomList, "euphorbia")
end


if not tAffs.darkshade then
    table.insert(swordneed,"combination "..target.." slice darkshade")
    table.insert(envenomList, "darkshade")
end

if not tAffs.addiction then
    table.insert(swordneed,"combination "..target.." slice vardrax")
    table.insert(envenomList, "vardrax")
end




if not softlock and not tAffs.sensitivity then
  table.insert(swordneed,"combination "..target.." slice prefarar")
  table.insert(envenomList, "prefarar")
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


--if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 30 then


if need_raze then
atk = atk.."wield shield longsword441711;assess "..target..";combination " ..target.. " raze " ..shieldneed[1]

elseif ferocity_full and tLimbs.RL < 100 and tLimbs.RL >= 92.4 and not tAffs.slickness and tAffs.asthma and tAffs.weariness then
targetlimb = "right leg"
infernalpriosprep()

elseif ferocity_full and tLimbs.LL < 100 and tLimbs.LL >= 92.4 and not tAffs.slickness and tAffs.asthma and tAffs.weariness then
targetlimb = "left leg"
infernalpriosprep()

elseif not ferocity_full and tLimbs.RL < 100 and tLimbs.RL >= 92.4 and tAffs.slickness then
targetlimb = "right leg"
infernalpriosprep()

elseif not ferocity_full and tLimbs.LL < 100 and tLimbs.LL >= 92.4 and tAffs.slickness then
targetlimb = "left leg"
infernalpriosprep()



elseif ferocity_full and not tAffs.sensitivity and not softlock and not tAffs.asthma and tBals.tree then

atk = atk.."wield shield longsword441711;assess "..target..";shieldstrike "..target.." mid;"..swordneed[1].." "..shieldneed[1]



else
atk = atk.."wield shield longsword441711;assess "..target..";"..swordneed[1].." "..shieldneed[1]

end

if partyrelay and ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 40 then send("pt "..target..": Health is at "..ataxiaTemp.lastAssess.."%")
end
if not ataxia.settings.paused then
 if add_dedication then
 send("queue addclear free dedication;"..atk)
elseif not engaged then
send("queue addclear free "..atk..";engage "..target)

else

send("queue addclear free "..atk)

end
end

end