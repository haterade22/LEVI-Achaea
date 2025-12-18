-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > Pariah > Pariah Logic

function levipariahlatencytest()
local atk = combatQueue()
local sp = ataxia.settings.separator
local e = ataxia.vitals.epitaph
local plagues = {"mycalium", "rebbies", "sandfever", "flushings", "pyramides" }
local tp = false
taccelerates = taccelerates or 0
--Get Targets Anti Active Cure
getLockingAffliction()

--Get Target Lock Status
checkTargetLocks()

--Define Kelp Stack
if checkAffList({"paralysis", "asthma", "epilepsy",  "clumsiness", "impatience", "addiction", "relapsing"},3) then
  tAffs.logostack = true
else
  tAffs.logostack = false
end
--Define Plague Stack
if checkAffList({"mycalium", "rebbies", "sandfever", "flushings", "pyramides" },2) then
  plaguestackone = true
else
  plaguestackone = false
end

--Define Plague Stack
if checkAffList({"mycalium", "rebbies", "sandfever", "flushings", "pyramides" },3) then
  tlatency = true
else
  tlatency = false
end


--Nest/Scales/Skein/Sun + Burrow/Serpent + Burrow/ Nest/ Scales/ Standfever Sting + Skein/ Rebbies + Sun/Sandfever + Serpent/ Nest/ Flushings Sting + Bear/ Flushing Burrow + Jackal / Flushings Burrow + Serpent / Rebbies + Nest/ Pyramides + Bear / Flushing + Scarab / Latency + Scorpion / Serpent + Accelerate / Nest + Accelerate

logographtrace = {}
if tAffs.shield then
  table.insert(logographtrace,"fissure")
elseif not pariah.lastLogograph then
  table.insert(logographtrace,"serpent")
-- NEST
elseif pariah.lastLogograph == "nest" then
  if tAffs.impatience or tAffs.sandfever then
    table.insert(logographtrace,"bear")
  elseif tAffs.flushings then
    table.insert(logographtrace,"bear")
  elseif tAffs.clumsiness and not tAffs.haemophilia then
    table.insert(logographtrace,"bear")
  elseif not tAffs.impatience then
    table.insert(logographtrace,"scales")
  elseif not tAffs.clumsiness then
    table.insert(logographtrace,"scales")
  end
elseif pariah.lastLogograph == "scales" then
   table.insert(logographtrace,"skein")
--SKEIN
elseif pariah.lastLogograph == "skein" then
  if tAffs.impatience or tAffs.sandfever and not tAffs.epilepsy then
    table.insert(logographtrace,"sun")
  elseif tAffs.flushings and not tAffs.addiction then
    table.insert(logographtrace,"scarab")
  elseif tAffs.addiction then
    table.insert(logographtrace,"sun")
  elseif not tAffs.epilepsy then
    table.insert(logographtrace,"sun")
  else
    table.insert(logographtrace,"scarab")
  end
--SERPENT
elseif pariah.lastLogograph == "serpent" then
  if tAffs.weariness and not tAffs.impatience then
    table.insert(logographtrace,"skein")
  else
   table.insert(logographtrace,"nest")
  end
--BEAR
elseif pariah.lastLogograph == "bear" then
  if not tAffs.asthma then
   table.insert(logographtrace,"jackal")
  elseif tAffs.flushings and not tAffs.addiction then
    table.insert(logographtrace,"scarab")
  else
   table.insert(logographtrace,"jackal")
  end
elseif pariah.lastLogograph == "sun" or pariah.lastLogograph == "scorpion" or pariah.lastLogograph == "jackel" then
   table.insert(logographtrace,"serpent")
else 
  table.insert(logographtrace,"serpent")
end 

myheartbeats = {}

if e == 0 then
  table.insert(myheartbeats, "5")
elseif e == 1 then
  table.insert(myheartbeats, "3")
elseif e == 2 then
  table.insert(myheartbeats, "1")
elseif e >= 3 then
   table.insert(myheartbeats, "0")
end

myswarmsting = {}
if not tAffs.pyramides and not tAffs.burrow then
  table.insert(myswarmsting, "pyramides")
elseif not tAffs.sandfever and not tAffs.impatience then
  table.insert(myswarmsting, "sandfever")
elseif not tAffs.rebbies then
  table.insert(myswarmsting, "rebbies")
elseif not tAffs.flushings then
  table.insert(myswarmsting, "flushings")
elseif not tAffs.mycalium then
  table.insert(myswarmsting, "mycalium")
else
  table.insert(myswarmsting, "mycalium")
end

--Nest/Scales/Skein/Sun + Burrow/Serpent + Burrow/ Nest/ Scales/ Standfever Sting + Skien/ Rebbies + Sun/Sandfever + Paralysis/ Nest/ Flushings Sting + Bear/ Flushing Burrow + Jackal / Flushings Burrow + Serpent / Rebbies + Nest/ Pyramides + Bear / Flushing + Scarab / Latency + Scorpion / Serpent + Accelerate / Nest + Accelerate


--ATTACK
  if haveAff("shield") then
    if tAffs.voyria and taccelerates < 2 then
      atk = atk..";trace fissure " ..target.. ";blood accelerate " ..target
    elseif e >= 2 and pariah.expose then
      atk = atk.."swarm sting " ..myswarmsting[1].. " " ..target.. ";trace fissure " ..target
    elseif e <= 1 then
      atk = atk..";trace fissure " ..target
    end
  elseif not pariah.bladePrepared then
    atk = atk.."crux ensorcell " ..target
  elseif taccelerates >= 2 then
    atk = atk..";trace " ..logographtrace[1].. " " ..target
  elseif tAffs.voyria then
    atk = atk..";trace " ..logographtrace[1].. " " ..target.. ";blood accelerate " ..target
  elseif pariah.latency and not tAffs.voyria and pariah.lastLogograph == "scorpion" then
    atk = atk.."trace serpent " ..target.. ";crux transpose voyria;blood accelerate " ..target
  elseif haveAff("burrow") and tlatency == true and pariah.expose and e >= 4 then
    atk = atk.."swarm latency pyramides;trace scorpion " ..target
  
  elseif e >= 3 and pariah.expose then
        if not haveAff("burrow") then
          atk = atk.."swarm burrow pyramides " ..target.. ";trace " ..logographtrace[1].. " " ..target
        elseif haveAff("burrow") and not pariah.infest then
          atk = atk.."swarm infest pyramides " ..target.. ";trace " ..logographtrace[1].. " " ..target
        else
          atk = atk.."swarm sting " ..myswarmsting[1].. " " ..target.. ";trace " ..logographtrace[1].. " " ..target
        end
  elseif e <= 2 then
    if myheartbeats[1] ~= "0" then
      atk = atk..";trace " ..logographtrace[1].. " " ..target.. " " ..myheartbeats[1].. " heartbeats"
    else
      atk = atk.."swarm sting " ..myswarmsting[1].. " " ..target.. ";trace " ..logographtrace[1].. " " ..target
    end
  end  
  
  
 

send("queue addclearfull freestand wield left knife;unwield right;" ..atk)


--End Function  
end


function levipariahscourgetest()
local atk = combatQueue()
local sp = ataxia.settings.separator
local e = ataxia.vitals.epitaph
local plagues = {"mycalium", "rebbies", "sandfever", "flushings", "pyramides" }
local tp = false
taccelerates = taccelerates or 0
--Get Targets Anti Active Cure
getLockingAffliction()

--Get Target Lock Status
checkTargetLocks()

--Define Kelp Stack
if checkAffList({"paralysis", "asthma", "epilepsy",  "clumsiness", "impatience", "addiction", "relapsing","haemophilia"},3) then
  tAffs.logostack = true
else
  tAffs.logostack = false
end
--Define Plague Stack
if checkAffList({"mycalium", "rebbies", "sandfever", "flushings", "pyramides" },2) then
  plaguestackone = true
else
  plaguestackone = false
end

--Define Plague Stack
if checkAffList({"mycalium", "rebbies", "sandfever", "flushings", "pyramides" },3) then
  tlatency = true
else
  tlatency = false
end


--Nest/Scales/Skein/Sun + Burrow/Serpent + Burrow/ Nest/ Scales/ Standfever Sting + Skein/ Rebbies + Sun/Sandfever + Serpent/ Nest/ Flushings Sting + Bear/ Flushing Burrow + Jackal / Flushings Burrow + Serpent / Rebbies + Nest/ Pyramides + Bear / Flushing + Scarab / Latency + Scorpion / Serpent + Accelerate / Nest + Accelerate

logographtrace = {}
if tAffs.shield then
  table.insert(logographtrace,"fissure")
elseif not pariah.lastLogograph then
  table.insert(logographtrace,"bear")
-- NEST
elseif pariah.lastLogograph == "nest" then
  if tAffs.impatience or tAffs.sandfever then
    table.insert(logographtrace,"bear")
  elseif tAffs.flushings then
    table.insert(logographtrace,"bear")
  elseif tAffs.clumsiness and not tAffs.haemophilia then
    table.insert(logographtrace,"bear")
  elseif not tAffs.haemophilia then
    table.insert(logographtrace,"bear")
  elseif tAffs.haemophilia then
    table.insert(logographtrace,"bear")
  elseif not tAffs.impatience then
    table.insert(logographtrace,"scales")
  elseif not tAffs.clumsiness then
    table.insert(logographtrace,"scales")
  end
elseif pariah.lastLogograph == "scales" then
   table.insert(logographtrace,"skein")
--SKEIN
elseif pariah.lastLogograph == "skein" then
  if tAffs.impatience or tAffs.sandfever and not tAffs.epilepsy then
    table.insert(logographtrace,"sun")
  elseif tAffs.flushings and not tAffs.addiction then
    table.insert(logographtrace,"scarab")
  elseif tAffs.addiction then
    table.insert(logographtrace,"sun")
  elseif not tAffs.epilepsy then
    table.insert(logographtrace,"sun")
  else
    table.insert(logographtrace,"scarab")
  end
--SERPENT
elseif pariah.lastLogograph == "serpent" then
  if tAffs.weariness and not tAffs.impatience then
    table.insert(logographtrace,"skein")
  else
   table.insert(logographtrace,"nest")
  end
--BEAR
elseif pariah.lastLogograph == "bear" then
  if tAffs.flushings and not tAffs.addiction then
    table.insert(logographtrace,"scarab")
  elseif not tAffs.asthma then
   table.insert(logographtrace,"jackal")
  else
   table.insert(logographtrace,"scarab")
  end
elseif pariah.lastLogograph == "sun" or pariah.lastLogograph == "scorpion" or pariah.lastLogograph == "jackel" then
   table.insert(logographtrace,"serpent")
else 
   table.insert(logographtrace,"serpent")
end 

myheartbeats = {}

if e == 0 then
  table.insert(myheartbeats, "5")
elseif e == 1 then
  table.insert(myheartbeats, "3")
elseif e == 2 then
  table.insert(myheartbeats, "1")
elseif e >= 3 then
   table.insert(myheartbeats, "0")
end

myswarmsting = {}
if not tAffs.pyramides and not tAffs.burrow then
  table.insert(myswarmsting, "pyramides")
elseif not tAffs.flushings then
  table.insert(myswarmsting, "flushings")
elseif not tAffs.mycalium then
  table.insert(myswarmsting, "mycalium")
elseif not tAffs.rebbies then
  table.insert(myswarmsting, "rebbies")
elseif not tAffs.sandfever and not tAffs.impatience then
  table.insert(myswarmsting, "sandfever")

else
  table.insert(myswarmsting, "pyramides")
end

--Nest/Scales/Skein/Sun + Burrow/Serpent + Burrow/ Nest/ Scales/ Standfever Sting + Skien/ Rebbies + Sun/Sandfever + Paralysis/ Nest/ Flushings Sting + Bear/ Flushing Burrow + Jackal / Flushings Burrow + Serpent / Rebbies + Nest/ Pyramides + Bear / Flushing + Scarab / Latency + Scorpion / Serpent + Accelerate / Nest + Accelerate


--ATTACK
  if haveAff("shield") then
    if tAffs.voyria and taccelerates < 2 then
      atk = atk..";trace fissure " ..target.. ";blood accelerate " ..target
    elseif e >= 2 and pariah.expose then
      atk = atk.."swarm sting " ..myswarmsting[1].. " " ..target.. ";trace fissure " ..target
    elseif e <= 1 then
      atk = atk..";trace fissure " ..target
    end
  elseif not pariah.bladePrepared then
    atk = atk.."crux ensorcell " ..target
  elseif taccelerates >= 2 then
    atk = atk..";trace " ..logographtrace[1].. " " ..target
  elseif tAffs.voyria then
    atk = atk..";trace " ..logographtrace[1].. " " ..target.. ";blood accelerate " ..target
  elseif pariah.latency and not tAffs.voyria and pariah.lastLogograph == "scorpion" then
    atk = atk.."trace serpent " ..target.. ";crux transpose voyria;blood accelerate " ..target
  elseif tAffs.bleed >= 200 and tAffs.scytherus and tAffs.haemophilia and tAffs.pyramides and haveAff("burrow") then
    atk = atk.."swarm scourge pyramides " ..target.. ";trace " ..logographtrace[1].. " " ..target
  --elseif haveAff("burrow") and tlatency == true and pariah.expose and e >= 4 then
   -- atk = atk.."swarm latency pyramides;trace scorpion " ..target  
  elseif e >= 3 and pariah.expose then
        if not haveAff("burrow") then
          atk = atk.."swarm burrow pyramides " ..target.. ";trace " ..logographtrace[1].. " " ..target
        elseif haveAff("burrow") and tAffs.bleed >= 200 then
          atk = atk.."swarm sting " ..myswarmsting[1].. " " ..target.. ";trace scorpion " ..target
        elseif haveAff("burrow") and not pariah.infest then
          atk = atk.."swarm infest pyramides " ..target.. ";trace " ..logographtrace[1].. " " ..target
        else
          atk = atk.."swarm sting " ..myswarmsting[1].. " " ..target.. ";trace " ..logographtrace[1].. " " ..target
        end
  elseif e <= 2 then
    if myheartbeats[1] ~= "0" then
      atk = atk..";trace " ..logographtrace[1].. " " ..target.. " " ..myheartbeats[1].. " heartbeats"
    else
      atk = atk.."swarm sting " ..myswarmsting[1].. " " ..target.. ";trace " ..logographtrace[1].. " " ..target
    end
  end  
  
  
 

send("queue addclearfull freestand wield left knife;unwield right;" ..atk)


--End Function  
end
