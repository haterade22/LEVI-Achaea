function infernalpriossoftlockclu()

local atk = combatQueue()

add_dedication = false
need_raze = false
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
  


if tAffs.slickness and tBals.focus and not tAffs.anorexia then
    table.insert(shieldneed,"smash high")


elseif tAffs.anorexia and tAffs.slickness then
    table.insert(shieldneed,"smash high")



elseif treelock  then
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



if not tAffs.paralysis and shieldneed[1] ~= "smash mid" and softlock then
    table.insert(swordneed, "combination "..target.." slice curare")
end


if not tAffs.slickness and tAffs.asthma and tAffs.clumsiness then
     table.insert(swordneed,"combination "..target.." slice gecko")
end


if tAffs.anorexia and not tAffs.stupidity then
   table.insert(swordneed,"combination "..target.." slice aconite")
   end

if tAffs.anorexia and not tAffs.recklessness then
   table.insert(swordneed,"combination "..target.." slice eurypteria")
   end
if tAffs.anorexia and not tAffs.dizziness then
   table.insert(swordneed,"combination "..target.." slice larkspur")
   end

if tAffs.anorexia and not tAffs.shyness then
   table.insert(swordneed,"combination "..target.." slice digitalis")
   end

if not tAffs.anorexia and tAffs.slickness and tBals.focus then
    table.insert(swordneed,"combination "..target.." slice slike")
end

if not tAffs.clumsiness and shieldneed[1] ~= "smash low" then
  table.insert(swordneed,"combination "..target.." slice xentio")
end




if not tAffs.asthma and shieldneed[1] ~= "drive" then
      table.insert(swordneed,"combination "..target.." slice kalmia")
end


if not softlock and not tAffs.haemophilia then
table.insert(swordneed,"wipe longsword;hellforge invest torture;combination "..target.." slice")
end

if not tAffs.nausea then
      table.insert(swordneed,"combination "..target.." slice euphorbia")
end



if not tAffs.addiction then
  table.insert(swordneed,"combination "..target.." slice vardrax")
end




if not softlock and not tAffs.healthleech then
 table.insert(swordneed,"wipe longsword;hellforge invest torment;combination "..target.." slice")
end

   if not tAffs.weariness then
    table.insert(swordneed,"wipe longsword;hellforge invest exploit;combination "..target.." slice")
end



if not softlock and not tAffs.sensitivity then
  table.insert(swordneed,"combination "..target.." slice prefarar")
end





if not tAffs.paralysis and shieldneed[1] ~= "smash mid" then
    table.insert(swordneed,"combination "..target.." slice curare")
end



if not tAffs.asthma and shieldneed[1] ~= "drive" then
  table.insert(swordneed,"combination "..target.." slice kalmia")
end




if tAffs.prone and tAffs.paralysis and tAffs.slickness then
table.insert(swordneed,"combination "..target.." slice epseth")
   end
   
   if softlock and not tAffs.paralysis then
   table.insert(swordneed,"combination "..target.." slice curare")
   end


   

   
if not softlock and not tAffs.haemophilia then
 table.insert(swordneed,"wipe longsword;hellforge invest torture;combination "..target.." slice")
end
  







--ATTACK




if ataxia.afflictions.paralysis and not ataxia.afflictions.prone 
and (tonumber(gmcp.Char.Vitals.hp) >=  tonumber(gmcp.Char.Vitals.maxhp)*.7) 
and (tonumber(gmcp.Char.Vitals.mp) >= tonumber(gmcp.Char.Vitals.maxmp)*.6) and
ataxiaNDB_getClass(target) ~= "Apostate" and ataxiaNDB_getClass(target) ~= "Priest" then

add_dedication = true
else 
add_dedication = false
end



if tAffs.rebounding and not tAffs.shield then

need_raze = true
else
need_raze = false
end

if tAffs.shield and not tAffs.rebounding then

need_raze2 = true
else
need_raze2 = false
end

if ataxia.vitals.class == 4 then
ferocity_full = true
else 
ferocity_full = false
end



if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 30 then
quash_arc = true
else
quash_arc = false
end

if tAffs.shield and tAffs.rebounding then
quash_arc2 = true
else
quash_arc2 = false
end



if quash_arc or quash_arc1 or quash_arc2 then

atk = "stand/wield shield longsword/hellforge invest torment/quash "..target.."/arc/assess "..target

elseif need_raze or need_raze2 then
atk = atk.."wield shield longsword;assess "..target..";combination raze "..target.." "..shieldneed[1]

elseif ferocity_full and tLimbs.RL < 100 and tLimbs.RL >= 93 and tAffs.slickness then
atk = atk.."wield shield longsword;assess "..target..";shieldstrike "..target.." low;hellforge invest "..invest..";combination "..target.." slice right leg slike smash high"

elseif ferocity_full and tLimbs.LL < 100 and tLimbs.LL >= 93 and tAffs.slickness then
atk = atk.."wield shield longsword;assess "..target..";shieldstrike "..target.." low;hellforge invest "..invest..";combination "..target.." slice left leg slike smash high"

elseif tAffs.prone and tLimbs.LL < 100 and tLimbs.LL >= 93 and tAffs.slickness then
atk = atk.."wield shield longsword;assess "..target..";hellforge invest "..invest..";combination "..target.." slice left leg slike smash high"

elseif tAffs.prone and tLimbs.LL < 100 and tLimbs.LL >= 93 and tAffs.slickness then
atk = atk.."wield shield longsword;assess "..target..";hellforge invest "..invest..";combination "..target.." slice left leg slike smash high"


--elseif ferocity_full and not tAffs.sensitivity then

--atk = atk.."wield shield longsword;assess "..target..";shieldstrike "..target.." mid;"..swordneed[1].." "..shieldneed[1]

elseif ferocity_full and not tAffs.slickness and tAffs.asthma and not tBals.tree
 and not tAffs.prone then

atk = atk.."wield shield longsword;assess "..target..";"..swordneed[1].." "..shieldneed[1]..";shieldstrike "..target.." low"

elseif ferocity_full and not tAffs.slickness and tAffs.asthma and tAffs.weariness
 and not tAffs.prone then

atk = atk.."wield shield longsword;assess "..target..";"..swordneed[1].." "..shieldneed[1]..";shieldstrike "..target.." low"




else
atk = atk.."wield shield longsword;assess "..target..";"..swordneed[1].." "..shieldneed[1]

end

if table.contains(ataxia.playersHere, target) then


if quash_arc or quash_arc1 or quash_arc2 then
send("setalias quasharc "..atk)
send("queue addclear eq quasharc")

elseif not engaged then
send("queue addclear free land;"..atk..";engage "..target..";order hyena kill "..target)

elseif ataxia.afflictions.paralysis == true  then

send("queue addclear free dedication;"..atk..";tyranny")

else

send("queue addclear free land;"..atk..";tyranny")

end


end

end