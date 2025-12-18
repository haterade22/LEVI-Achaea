-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > INFERNAL > INFERNAL > S n B > Levi Damage

function isnbdamageroute()
local atk = combatQueue()
getLockingAffliction()
checkTargetLocks()
add_dedication = add_dedication or false
need_raze = need_raze or false
partyrelay = partyrelay or false
strikingHigh = true

invest = invest or nil
saffliction = saffliction or "none"

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

if ataxia.vitals.class == 4 then
ferocity_full = true
else 
ferocity_full = false
end

if tAffs.healthleech and tAffs.sensitivity and ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 50 then
quash_arc1 = true
else
quash_arc1 = false
end

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 30 then
quash_arc = true
else
quash_arc = false
end

if tAffs.shield and tAffs.rebounding and ataxiaTemp.lastAssess <= 30 then
quash_arc2 = true
else
quash_arc2 = false
end


--VIVI
if (tAffs.damagedleftleg or tAffs.brokenleftleg and tAffs.damagedrightleg or tAffs.brokenrightleg and tAffs.damagedleftarm or tAffs.brokenleftarm and tAffs.damagedrightarm or tAffs.brokenrightarm) then
tvivsect = true
else 
tvivisect = false
end


--SHIELD Logic

shieldneed = {}

if hardlock == true then
  table.insert(shieldneed,"smash high")

elseif tAffs.slickness and tBals.focus and not tAffs.anorexia then
  table.insert(shieldneed,"smash high")

elseif tAffs.anorexia and tAffs.slickness then
  table.insert(shieldneed,"smash high")

elseif treelock then
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
envenomList = {}


if tvivisect == true then
    atk = atk.."dismount;vivisect " ..target
elseif quash_arc or quash_arc1 or quash_arc2 then
    atk = atk.."wield shield longsword;dismount;quash " ..target..";arc"
elseif tAffs.rebounding or tAffs.shield then
    atk = atk.."wield shield longsword;assess "..target..";combination raze "..target.." "..shieldneed[1]
    
--True Lock
elseif truelock and tarClassCure(getAff) == "paralysis" and not tAffs.paralysis then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest "..invest..";combination "..target.." slice curare " ..shieldneed[1]
    table.insert(envenomList, "curare")
    saffliction = "paralysis"
elseif truelock and tarClassCure(getAff) == "paralysis" and tAffs.paralysis then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest "..invest..";combination "..target.." slice voyria " ..shieldneed[1]
    table.insert(envenomList, "voyria")
     saffliction = "plague"  
elseif truelock and tarClassCure(getAff) == "weariness" and not tAffs.weariness then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest exploit;combination "..target.." slice " ..shieldneed[1]
    envenomList = {}
    invest = "exploit"
    saffliction = "none"
elseif truelock and tarClassCure(getAff) == "weariness" and tAffs.weariness then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest "..invest..";combination "..target.." slice voyria " ..shieldneed[1]
    table.insert(envenomList, "voyria")
     saffliction = "plague"
elseif truelock and tarClassCure(getAff) == "haemophilia" and not tAffs.haemophilia then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest torture;combination "..target.." slice " ..shieldneed[1]
    envenomList = {}
    invest = "torture"
    saffliction = "none"
elseif truelock and tarClassCure(getAff) == "haemophilia" and tAffs.haemophilia then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest "..invest..";combination "..target.." slice voyria " ..shieldneed[1]
    table.insert(envenomList, "voyria")
     saffliction = "plague"
elseif truelock and tarClassCure(getAff) == "recklessness" and not tAffs.recklessness then
    atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice eurypteria " ..shieldneed[1]
    table.insert(envenomList, "eurypteria") 
     saffliction = "recklessness"
elseif truelock and tarClassCure(getAff) == "recklessness" and tAffs.recklessness then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest "..invest..";combination "..target.." slice voyria " ..shieldneed[1]
    table.insert(envenomList, "voyria")
elseif truelock and tarClassCure(getAff) == "confusion" and not tAffs.confusion and tAffs.healthleech then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest torment;combination "..target.." slice " ..shieldneed[1]
    envenomList = {}
    invest = "torment"
    saffliction = "none"
elseif truelock and tarClassCure(getAff) == "confusion" and tAffs.confusion and tAffs.healthleech then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest "..invest..";combination "..target.." slice voyria " ..shieldneed[1]
    table.insert(envenomList, "voyria")
    saffliction = "plague"
    
elseif truelock and tarClassCure(getAff) == "confusion" and not tAffs.confusion and not tAffs.healthleech then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest torment;combination "..target.." slice " ..shieldneed[1]
    envenomList = {}
    invest = "torment"
    saffliction = "none"
           
--Hardlock
elseif hardlock and not tAffs.paralysis and shieldneed[1] ~= "smash mid" and not tAffs.prone and ataxia.vitals.class == 4 then
    atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice curare " ..shieldneed[1]..";shieldstrike low"
    table.insert(envenomList, "curare")
     saffliction = "paralysis"    
elseif hardlock and not tAffs.paralysis and shieldneed[1] ~= "smash mid" and ataxia.vitals.class == 4 and tAffs.prone then
    atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice curare " ..shieldneed[1]..";shieldstrike high"
    table.insert(envenomList, "curare")  
     saffliction = "paralysis"  
elseif hardlock and not tAffs.paralysis and shieldneed[1] ~= "smash mid" then
    atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice curare " ..shieldneed[1]
    table.insert(envenomList, "curare") 
     saffliction = "paralysis"
elseif hardlock and not tAffs.paralysis and shieldneed[1] == "smash mid" and not tAffs.prone and ataxia.vitals.class == 4 and tarClassCure(getAff) == "weariness" and not tAffs.weariness then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest exploit;combination "..target.." slice " ..shieldneed[1]..";shieldstrike low"
    envenomList = {}
    invest = "exploit"
    saffliction = "none"
elseif hardlock and not tAffs.paralysis and shieldneed[1] == "smash mid" and not tAffs.prone and ataxia.vitals.class == 4 and tarClassCure(getAff) == "haemophilia" and not tAffs.haemophilia then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest torture;combination "..target.." slice " ..shieldneed[1]..";shieldstrike low"
    envenomList = {}
    invest = "torture"
    saffliction = "none"
elseif hardlock and tarClassCure(getAff) == "recklessness" and not tAffs.recklessness and not tAffs.paralysis and shieldneed[1] == "smash mid" and not tAffs.prone and ataxia.vitals.class == 4 then
    atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice eurypteria " ..shieldneed[1]..";shieldstrike low"
    table.insert(envenomList, "eurypteria") 
     saffliction = "recklessness"
elseif hardlock and not tAffs.paralysis and shieldneed[1] == "smash mid" and not tAffs.prone and ataxia.vitals.class == 4 and tarClassCure(getAff) == "confusion" and not tAffs.confusion and tAffs.healthleech then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest torment;combination "..target.." slice " ..shieldneed[1]..";shieldstrike low"
    envenomList = {}
    invest = "torment"
    saffliction = "none"

elseif hardlock and not tAffs.paralysis and shieldneed[1] == "smash mid" and tAffs.prone and ataxia.vitals.class == 4 and tarClassCure(getAff) == "weariness" and not tAffs.weariness then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest exploit;combination "..target.." slice " ..shieldneed[1]..";shieldstrike high"
    envenomList = {}
    invest = "exploit"
    saffliction = "none"
elseif hardlock and not tAffs.paralysis and shieldneed[1] == "smash mid" and tAffs.prone and ataxia.vitals.class == 4 and tarClassCure(getAff) == "haemophilia" and not tAffs.haemophilia then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest torture;combination "..target.." slice " ..shieldneed[1]..";shieldstrike high"
    envenomList = {}
    invest = "torture"
    saffliction = "none"
elseif hardlock and tarClassCure(getAff) == "recklessness" and not tAffs.recklessness and not tAffs.paralysis and shieldneed[1] == "smash mid" and tAffs.prone and ataxia.vitals.class == 4 then
    atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice eurypteria " ..shieldneed[1]..";shieldstrike high"
    table.insert(envenomList, "eurypteria")
     saffliction = "recklessness" 
elseif hardlock and not tAffs.paralysis and shieldneed[1] == "smash mid" and tAffs.prone and ataxia.vitals.class == 4 and tarClassCure(getAff) == "confusion" and not tAffs.confusion and tAffs.healthleech then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest torment;combination "..target.." slice " ..shieldneed[1]..";shieldstrike high"
    envenomList = {}
    invest = "torment"
    saffliction = "none"
    
elseif hardlock and not tAffs.paralysis and shieldneed[1] == "smash mid" and tarClassCure(getAff) == "weariness" and not tAffs.weariness then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest exploit;combination "..target.." slice " ..shieldneed[1]
    envenomList = {}
    invest = "exploit"
    saffliction = "none"
elseif hardlock and not tAffs.paralysis and shieldneed[1] == "smash mid" and tarClassCure(getAff) == "haemophilia" and not tAffs.haemophilia then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest torture;combination "..target.." slice " ..shieldneed[1]
    envenomList = {}
    invest = "torture"
    saffliction = "none"
elseif hardlock and tarClassCure(getAff) == "recklessness" and not tAffs.recklessness and not tAffs.paralysis and shieldneed[1] == "smash mid" then
    atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice eurypteria " ..shieldneed[1]
    table.insert(envenomList, "eurypteria") 
elseif hardlock and not tAffs.paralysis and shieldneed[1] == "smash mid" and tarClassCure(getAff) == "confusion" and not tAffs.confusion and tAffs.healthleech then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest torment;combination "..target.." slice " ..shieldneed[1]
    envenomList = {}
    invest = "torment"
    saffliction = "none"



--Soft Lock
elseif softlock and not tAffs.paralysis and shieldneed[1] ~= "smash mid" and ataxia.vitals.class == 4 and not tAffs.prone then
    atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice curare " ..shieldneed[1]..";shieldstrike low"
    table.insert(envenomList, "curare") 
     saffliction = "paralysis"
elseif softlock and not tAffs.paralysis and shieldneed[1] == "smash mid" and ataxia.vitals.class == 4 and not tAffs.prone and tarClassCure(getAff) == "recklessness" and not tAffs.recklessness then
    atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice eurypteria " ..shieldneed[1]..";shieldstrike low"
    table.insert(envenomList, "eurypteria") 
     saffliction = "recklessness"
elseif softlock and not tAffs.paralysis and shieldneed[1] == "smash mid" and ataxia.vitals.class == 4 and not tAffs.prone and tarClassCure(getAff) == "weariness" and not tAffs.weariness then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest exploit;combination "..target.." slice " ..shieldneed[1]..";shieldstrike low"
    envenomList = {}
    invest = "exploit"
    saffliction = "none"
elseif softlock and not tAffs.paralysis and shieldneed[1] == "smash mid" and ataxia.vitals.class == 4 and not tAffs.prone and tarClassCure(getAff) == "haemophilia" and not tAffs.haemophilia then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest torture;combination "..target.." slice " ..shieldneed[1]..";shieldstrike low"
    envenomList = {}
    invest = "torture"
    saffliction = "none" 

elseif softlock and not tAffs.paralysis and shieldneed[1] ~= "smash mid" and ataxia.vitals.class == 4 and tAffs.prone then
    atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice curare " ..shieldneed[1]..";shieldstrike high"
    table.insert(envenomList, "curare") 
     saffliction = "paralysis"
elseif softlock and not tAffs.paralysis and shieldneed[1] == "smash mid" and ataxia.vitals.class == 4 and tAffs.prone and tarClassCure(getAff) == "recklessness" and not tAffs.recklessness then
    atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice eurypteria " ..shieldneed[1]..";shieldstrike high"
    table.insert(envenomList, "eurypteria") 
     saffliction = "recklessness"
elseif softlock and not tAffs.paralysis and shieldneed[1] == "smash mid" and ataxia.vitals.class == 4 and tAffs.prone and tarClassCure(getAff) == "weariness" and not tAffs.weariness then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest exploit;combination "..target.." slice " ..shieldneed[1]..";shieldstrike high"
    envenomList = {}
    invest = "exploit"
    saffliction = "none"
elseif softlock and not tAffs.paralysis and shieldneed[1] == "smash mid" and ataxia.vitals.class == 4 and tAffs.prone and tarClassCure(getAff) == "haemophilia" and not tAffs.haemophilia then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest torture;combination "..target.." slice " ..shieldneed[1]..";shieldstrike high"
    envenomList = {}
    invest = "torture"
    saffliction = "none"
    
elseif softlock and not tAffs.paralysis and shieldneed[1] ~= "smash mid" then
    atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice curare " ..shieldneed[1]
    table.insert(envenomList, "curare") 
     saffliction = "paralysis"
elseif softlock and not tAffs.paralysis and shieldneed[1] == "smash mid" and tarClassCure(getAff) == "recklessness" and not tAffs.recklessness then
    atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice eurypteria " ..shieldneed[1]
    table.insert(envenomList, "eurypteria") 
     saffliction = "recklessness"
elseif softlock and not tAffs.paralysis and shieldneed[1] == "smash mid" and tarClassCure(getAff) == "weariness" and not tAffs.weariness then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest exploit;combination "..target.." slice " ..shieldneed[1]
    envenomList = {}
    invest = "exploit"
    saffliction = "none"
elseif softlock and not tAffs.paralysis and shieldneed[1] == "smash mid" and tarClassCure(getAff) == "haemophilia" and not tAffs.haemophilia then
    atk = atk.." wield shield longsword;assess "..target..";hellforge invest torture;combination "..target.." slice " ..shieldneed[1]
    envenomList = {}
    invest = "torture"
    saffliction = "none"
         
-- Build to Softlock
elseif tAffs.anorexia and not tAffs.stupidity then
    atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice aconite " ..shieldneed[1]
    table.insert(envenomList, "aconite")
     saffliction = "stupidity"
elseif tAffs.anorexia and not tAffs.recklessness then
 atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice eurypteria " ..shieldneed[1]
    table.insert(envenomList, "eurypteria")
     saffliction = "recklessness"
elseif tAffs.anorexia and not tAffs.dizziness then
 atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice larkspur " ..shieldneed[1]
    table.insert(envenomList, "larkspur")
     saffliction = "dizziness"
elseif tAffs.anorexia and not tAffs.shyness then
 atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice digitalis " ..shieldneed[1]
    table.insert(envenomList, "digitalis")
     saffliction = "shyness"
elseif not tAffs.anorexia and tAffs.slickness and tBals.focus and ataxia.vitals.class == 4 and tAffs.prone then
    atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice slike " ..shieldneed[1]..";shieldstrike high"
    table.insert(envenomList, "slike")
     saffliction = "anorexia"
elseif not tAffs.anorexia and tAffs.slickness and tBals.focus and ataxia.vitals.class == 4 and not tAffs.prone then
    atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice slike " ..shieldneed[1]..";shieldstrike low"
    table.insert(envenomList, "slike")
     saffliction = "anorexia"
elseif not tAffs.anorexia and tAffs.slickness and tBals.focus then
    atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice slike " ..shieldneed[1]
    table.insert(envenomList, "slike")
     saffliction = "anorexia"
elseif not tAffs.anorexia and tAffs.slickness and not tBals.focus then
    atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice slike " ..shieldneed[1]
    table.insert(envenomList, "slike")
     saffliction = "anorexia"
elseif tAffs.asthma and not tAffs.slickness and ataxia.vitals.class == 4 and tAffs.prone then
    atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice gecko " ..shieldneed[1]..";shieldstrike high"
    table.insert(envenomList, "gecko")
     saffliction = "slickness"
elseif tAffs.asthma and not tAffs.slickness and ataxia.vitals.class == 4 and not tAffs.prone then
    atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice gecko " ..shieldneed[1]..";shieldstrike low"
    table.insert(envenomList, "gecko")
     saffliction = "slickness"
elseif tAffs.asthma and not tAffs.slickness then
    atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice gecko " ..shieldneed[1]
    table.insert(envenomList, "gecko")
     saffliction = "slickness"
elseif not tAffs.asthma and shieldneed[1] ~= "drive" and tAffs.clumsiness then
    atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice kalmia " ..shieldneed[1]
    table.insert(envenomList, "kalmia")
     saffliction = "asthma"
elseif not tAffs.clumsiness then
    atk = atk.." wield shield longsword;assess "..target..";combination "..target.." slice xentio " ..shieldneed[1]
    table.insert(envenomList, "xentio")
     saffliction = "clumsiness"

end    
--ATTACK

if table.contains(ataxia.playersHere, target) then
  if not engaged then
    send("queue addclear free land;"..atk..";engage "..target..";order hyena kill "..target)
  elseif ataxia.afflictions.paralysis == true  then
    send("queue addclear free dedication;"..atk..";tyranny")
  else
    send("queue addclear free land;"..atk..";tyranny")
  end
end

end