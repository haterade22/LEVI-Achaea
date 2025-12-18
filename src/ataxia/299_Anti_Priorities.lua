-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Algedonic Defense 1.0 > Anti Priorities

--These are just examples, some are good, some are bad!

function Algedonic.AntiAirlord()
   if ataxia.afflictions.pressure ~= nil then
    if ataxia.afflictions.pressure >= 3 then
      send("curing prioaff pressure")
    end
   end
end
function Algedonic.AntiAlchemist()
  if ataxia.afflictions.temperedsanguine ~= nil and ataxia.afflictions.temperedsanguine >= 5 then
  Algedonic.Echo("Clearing free <red>YOU SHOULD RUN BEFORE BLEEDING INTO AURIFY<white>.")
  elseif ataxia.afflictions.temperedphlegmatic >= 6 and ataxia.afflictions.impatience then
    Algedonic.Echo("Clearing free <red>YOUR ABOUT TO GET LOCKED - WEARINESS LETHARGY ANOREXIA SLICKNESS INCOMMING <white>.")
    send("curing prioaff impatience")
  elseif ataxia.afflictions.temperedphlegmatic >= 6 and not ataxia.afflictions.impatience and ataxia.afflictions.asthma then
    send("curing prioaff asthma")
  elseif not ataxia.afflictions.paralysis then
    if Algedonic.mystack["goldenseal"] == 1 and ataxia.afflictions.impatience then
      send("curing prioaff impatience")
    elseif Algedonic.mystack["goldenseal"] >= 2 and ataxia.afflictions.impatience and ataxia.afflictions.asthma then
      send("curing prioaff asthma")
    elseif ataxia.afflictions.slickness and ataxia.afflictions.asthma then
      send("curing prioaff asthma")
    end
  end
    --Your conditions here
    --Temperedphlegmatic.
--2 for lethargy, 4 adds anorexia, 6 adds slick, 8 adds weary


end

function Algedonic.AntiApostate()
  
  --Fitness Classes
  local myclass = ataxiaTemp.class
      if ataxia.afflictions.impatience and ataxia.afflictions.paralysis and ataxia.afflictions.anorexia and ataxia.afflictions.slickness and not ataxia.afflictions.asthma then
        send("curing prioaff impatience")
        send("curseward")
      elseif Algedonic.mystack["kelp"] >= 3 and ataxia.afflictions.asthma and not ataxia.afflictions.paralysis then
        Algedonic.Echo("Digging for <green>asthma<white>! Be ready to hit <orange>FITNESS!")
        send("curing prioaff asthma")
      elseif ataxia.afflictions.asthma and ataxia.afflictions.manaleech then
        send("curing prioaff asthma")  
        
      end
    

end
function Algedonic.AntiBard()
      if ataxia.afflictions.crescendo >= 4 then
      send("curing prioaff crescendo")
      end
end


function Algedonic.Blademaster()
end

function Algedonic.AntiDruid()
    --Your conditions here
end
function Algedonic.AntiDepthswalker()

  if ataxia.afflictions.timeloop and not ataxia.afflictions.paralysis then
    send("curing prioaff timeloop")
  elseif ataxia.afflictions.timeloop and ataxia.afflictions.paralysis then
    send("curing prioaff paralysis")
  elseif ataxia.afflictions.hypochondria and not ataxia.afflictions.paralysis then
    send("curing prioaff hypochondria")
  elseif ataxia.afflictions.depression and not ataxia.afflictions.timeloop and not ataxia.afflictions.hypochondria then
    send("curing prioaff depression")

  end
end

function Algedonic.AntiMagi()
  if ataxia.afflictions.fulminated and ataxia.afflictions.slickness and not ataxia.afflictions.anorexia then
    send("focus")
  elseif ataxia.afflictions.fulminated and not ataxia.afflictions.paralysis and not ataxia.afflictions.asthma then
    send("curing prioaff fulminated")
  elseif ataxia.afflictions.fulminated and ataxia.afflictions.paralysis and Algedonic.mystack["goldenseal"] >= 1 then
    send("focus")
  elseif ataxia.afflictions.asthma and not ataxia.afflictions.paralysis then
    send("curing prioaff asthma")
  elseif not ataxia.afflictions.asthma and not ataxia.afflictions.paralysis and ataxia.afflictions.healthleech then
    send("curing prioaff healthleech")
  end
    --Your conditions here
end
  
function Algedonic.AntiPariah()
--Haemo>flushings>Pyramides > sandfever >  > rebbies > mycalium  
  --Stop Lock?-- Lock Is Pyramides/Flushings/Rebbies then they will Sting Sandfever (Impatience)/Trace Jackel for Asthma
  --So generally, it will go swarm latency/scorpion(scytherus), next balance sting(prob pyramides if you don't have it)/serpent(para/voyria this balance)/ blood accelerate, next balance blood accelerate
  if ataxia.afflictions.voyria then
    stoplatency = true
  elseif ataxia.afflictions.pyramides and ataxia.afflictions.flushings and ataxia.afflictions.rebbies then
    if Algedonic.mystack["kelp"] <= 1 then
      send("curing prioaff rebbies")
    elseif Algedonic.mystack["ginseng"] <= 1 then
      send("curing prioaff flushings")
    else
      send("curing prioaff pyramides")
    end
  elseif ataxia.afflictions.sandfever and ataxia.afflictions.asthma then
    send("curing prioaff sandfever")
  --Stop Scourge Kill - Needs Pramides, Scytherus, Haemophilia and Bleed >= 200
  elseif ataxia.vitals.bleed >= 190 and ataxia.afflictions.haemophilia then
    -- Put this in the combatQueue() function that if this is true then shield
    stopscourge = true
    --Need to shield and cure ginseng
    send("curing queue insert 1 ginseng")
    
  elseif ataxia.afflictions.pyramides and ataxia.afflictions.haemophilia and ataxia.vitals.bleed > 140 then
      send("curing prioaff haemophilia")
  --Stop Voyria Kill YOU HAVE TO RUN AT 3 PLAGUES
  elseif not ataxia.afflictions.paralysis and not ataxia.afflictions.haemophilia and ataxia.afflictions.scytherus then
    send("curing prioaff scytherus")
  
  end
end

function Algedonic.AntiPsion()

if ataxia.afflictions.unweavingbody ~= nil and ataxia.afflictions.unweavingmind ~= nil then
  if ataxia.afflictions.unweavingbody >= 2 and ataxia.afflictions.unweavingmind < 2 then
    send("curing prioaff unweavingbody")
  elseif ataxia.afflictions.unweavingbody < 2 and ataxia.afflictions.unweavingmind > 2 then
    send("curing prioaff unweavingmind")
  end
elseif ataxia.afflictions.unweavingspirit ~= nil then
  if ataxia.afflictions.unweavingspirit >= 2 and ataxia.afflictions.asthma then
  send("curing prioaff asthma")
  end
end

end

function Algedonic.AntiSentinel()
if ataxia.afflictions.slickness and ataxia.afflictions.paralysis and not ataxia.afflictions.asthma then
  send("endure")
  send("curing prioaff paralysis")
elseif tAffs.prone then
  if ataxia.afflictions.asthma and Algedonic.mystack["kelp"] >= 3 then
    send("curing prioaff asthma")
  elseif ataxia.afflictions.impatience then
    send("curing prioaff impatience")
  end
--Prevent Getting Asthma from Badger
elseif ataxia.vitals.bleed >= 150 then
    send("curing prioaff haemophilia")
end

if ataxia.afflictions.damagedleftarm or ataxia.afflictions.damagedrightarm and not ataxia.afflictions.prone then
    expandAlias("goto 11090")
    preventriftlock = true
    
    ataxia_boxEcho("TOUCH SHIELD TOUCH SHIELD - RIFT LOCK - RIFT LOCK -", "a_darkred")
end
end


function Algedonic.AntiSerpent()
    --Fitness Classes
local myclass = ataxiaTemp.class

      if ataxia.afflictions.prone and ataxia.afflictions.paralysis and ataxia.afflictions.slickness then
        send("endure")
        send("curing prioaff paralysis")
      elseif ataxia.afflictions.asthma and ataxia.afflictions.impatience and ataxia.afflictions.slickness and ataxia.afflictions.anorexia then
        send("touch tree")
      elseif ataxia.afflictions.impatience then
        Algedonic.Echo("Clearing free <gold>impatience <white>stack.")
        send("curing prioaff impatience")
      end
   


end


function Algedonic.AntiShaman()
local myclass = ataxiaTemp.class
    --Prevent Tza Instant Kill
  if Algedonic.mystack["goldenseal"] >= 3 and not ataxia.afflictions.paralysis then
      if ataxia.afflictions.impatience then
          send("curing prioaff impatience")
   
      elseif not ataxia.afflictions.impatience and ataxia.afflictions.stupidity then
          send("curing prioaff stupidity")
      elseif not ataxia.afflictions.impatience and not ataxia.afflictions.stupidity and ataxia.afflictions.dizziness then
          send("curing prioaff dizziness")
      end
  elseif ataxia.afflictions.impatience and ataxia.afflictions.stupidity and ataxia.afflictions.dizziness and ataxia.afflictions.epilepsy then
    send("curing prioaff impatience")
  elseif ataxia.afflictions.impatience and ataxia.afflictions.stupidity and ataxia.afflictions.dizziness or ataxia.afflictions.epilepsy then
    send("curing prioaff impatience")  
  -- Prevent Lock
  elseif Algedonic.mystack["kelp"] >= 3 and ataxia.afflictions.asthma and not ataxia.afflictions.impatience and not ataxia.afflictions.paralysis then
        send("curing prioaff asthma")
 
  
  
    
  elseif ataxia.afflictions.asthma and ataxia.afflictions.impatience and not ataxia.afflictions.paralysis then
        send("curing prioaff impatience")
  -- Prevent Coag if we can
  elseif ataxia.afflictions.haemophilia and ataxia.vitals.bleed > 100 and not ataxia.afflictions.paralysis then
        send("curing prioaff haemophilia")
    
  end

end


function Algedonic.AntiSylvan()

ataxiaTemp.heartseedMode = true
--Algedonic.Echo("<gold>Sylvan Heartseed Mode is ON <white>.")

end


function Algedonic.AntiUnnameable()
if ataxia.afflictions.damageleftleg or ataxia.afflictions.damagedrightleg or ataxia.afflictions.damagedleftarm or ataxia.afflictions.damagedrightarm or ataxia.afflictions.damagedhead then  
  if ataxia.afflictions.horror == 5 then
  send("curing prioaff horror (5)")
  elseif ataxia.afflictions.horror == 4 then
  send("curing prioaff horror (4)")
    end
  end
end

function Algedonic.AntiPriest()
--Cure Guilty Tenderskin and Spiritburn over everything

--If they inflict Paralysis you will be slow down but they won't win either...
if ataxia.afflictions.guilt then
  send("curing prioaff guilt")
elseif ataxia.afflictions.tenderskin then
  send("curing prioaff tenderskin")
elseif ataxia.afflictions.spiritburn then
  send("curing prioaff spiritburn")
end

end

function Algedonic.AntiOccultist()
  if ataxia.afflictions.asthma and ataxia.afflictions.aeon then
    send("curing prioaff asthma")
  elseif ataxia.afflictions.asthma and not ataxia.afflictions.paralysis then
    send("curing prioaff asthma")
  elseif not ataxia.afflictions.asthma and not ataxia.afflictions.paralysis and ataxia.afflictions.whisperingmadness then
    send("curing prioaff whisperingmadness")
  end
end
   
