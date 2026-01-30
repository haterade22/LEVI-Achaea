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
    local hasAsthma = ataxia.afflictions.asthma
    local hasWeariness = ataxia.afflictions.weariness
    local hasParalysis = ataxia.afflictions.paralysis
    local hasSlickness = ataxia.afflictions.slickness
    local hasAnorexia = ataxia.afflictions.anorexia
    local hasImpatience = ataxia.afflictions.impatience
    local hasFratricide = ataxia.afflictions.fratricide
    local hasProne = ataxia.afflictions.prone
    local kelpStack = Algedonic.mystack["kelp"] or 0

    -- Ekanelia conditional tracking
    local hasMasochism = ataxia.afflictions.masochism
    local hasClumsiness = ataxia.afflictions.clumsiness
    local hasConfusion = ataxia.afflictions.confusion
    local hasRecklessness = ataxia.afflictions.recklessness
    local hasHypersomnia = ataxia.afflictions.hypersomnia
    local hasScytherus = ataxia.afflictions.scytherus

    -- Defense tracking
    local hasFangbarrier = ataxia.defences and ataxia.defences.fangbarrier

    -- Can we tree? (not paralyzed, arms not both broken, tree off cooldown)
    local canTree = not hasParalysis
        and not (ataxia.afflictions.brokenleftarm and ataxia.afflictions.brokenrightarm)
        and tBals.tree

    -- APPROACHING LOCK: asthma + slickness + (impatience OR anorexia)
    -- Tree NOW before paralysis locks us out
    local approachingLock = hasAsthma and hasSlickness and (hasImpatience or hasAnorexia)

    -- IMPULSE ENABLED: asthma + weariness + no fangbarrier = they can Impulse us
    local impulseEnabled = hasAsthma and hasWeariness and not hasFangbarrier

    -- IMPULSE LOCK THREAT: Impulse enabled + ANY mental = tree IMMEDIATELY
    -- Impulse delivers impatience/anorexia instantly, don't wait for slickness
    local impulseLockThreat = impulseEnabled and (hasImpatience or hasAnorexia)

    if canTree and approachingLock then
        Algedonic.Echo("<red>APPROACHING LOCK - TREE!<white>")
        send("touch tree")
        return
    end

    -- IMPULSE LOCK THREAT: Tree immediately when Impulse has delivered a mental
    -- This triggers BEFORE slickness to prevent the lock from forming
    if canTree and impulseLockThreat then
        Algedonic.Echo("<yellow>IMPULSE LOCK THREAT<white> - tree NOW!")
        send("touch tree")
        return
    end

    -- EARLY TREE: When Impulse enabled + fratricide (relapse danger), tree before damage spirals
    if canTree and impulseEnabled and hasFratricide then
        Algedonic.Echo("<magenta>FRATRICIDE + IMPULSE<white> - tree to stop relapse!")
        send("touch tree")
        return
    end

    -- FANGBARRIER RE-APPLICATION: If fangbarrier stripped and Impulse conditions developing
    -- Re-apply quicksilver BEFORE they can Impulse us (asthma + weariness = Impulse ready)
    -- Must OUTR quicksilver from rift before applying
    if not hasFangbarrier and hasAsthma and hasWeariness and not hasParalysis and not hasSlickness then
        Algedonic.Echo("<cyan>FANGBARRIER DOWN<white> - reapplying quicksilver to block Impulse!")
        send("outr 1 quicksilver;apply quicksilver to skin")
        return
    end

    -- Prone + paralysis + slickness - need to break paralysis to stand
    if hasProne and hasParalysis and hasSlickness then
        send("endure")
        send("curing prioaff paralysis")
        return
    end

    -- FRATRICIDE + SCYTHERUS: CRITICAL PRIORITY - relapse deals 1200 damage per tick
    -- This MUST be cured immediately - moves to high priority before Ekanelia prevention
    if hasFratricide and hasScytherus and not hasParalysis then
        Algedonic.Echo("<red>FRATRICIDE + SCYTHERUS<white> - cure fratricide NOW!")
        send("curing prioaff fratricide")
        return
    end

    -- === EKANELIA PREVENTION ===

    -- MASOCHISM: Blocks 2 Ekanelia transformations (monkshood + curare)
    -- monkshood: asthma + masochism + weariness → impatience (bypasses Impulse!)
    -- curare: hypersomnia + masochism → hypochondria
    if hasMasochism and (hasWeariness or hasHypersomnia) then
        Algedonic.Echo("Clearing <cyan>masochism<white> to block Ekanelia!")
        send("curing prioaff masochism")
        return
    end

    -- CLUMSINESS + WEARINESS: Enables kalmia → asthma + slickness
    -- Single bite gives BOTH lock afflictions - very dangerous
    if hasClumsiness and hasWeariness then
        Algedonic.Echo("Blocking <yellow>Ekanelia kalmia<white> setup!")
        send("curing prioaff clumsiness")
        return
    end

    -- CONFUSION + RECKLESSNESS: Makes loki PREDICTABLE
    -- Bite gives guaranteed nausea + paralysis instead of random
    if hasConfusion and hasRecklessness then
        Algedonic.Echo("Blocking <magenta>Ekanelia loki<white> setup!")
        send("curing prioaff recklessness")
        return
    end

    -- IMPULSE PREVENTION: Asthma + Weariness = impulse can deliver mentals
    -- Cure asthma (kelp) to break the impulse requirement
    if hasAsthma and hasWeariness and not hasParalysis then
        if kelpStack >= 2 then
            Algedonic.Echo("Clearing <green>asthma<white> to prevent impulse!")
            send("curing prioaff asthma")
        else
            -- Low kelp stack, try weariness instead (also kelp, but system picks)
            send("curing prioaff weariness")
        end
        return
    end

    -- FRATRICIDE HANDLING: When Impulse is enabled, fratricide causes relapse
    -- Cure fratricide EARLY when asthma + weariness present (before they spam Impulse)
    if hasFratricide and impulseEnabled then
        Algedonic.Echo("Clearing <magenta>fratricide<white> to prevent impulse relapse!")
        send("curing prioaff fratricide")
        return
    end

    -- PARALYSIS vs SLICKNESS: When asthma blocks smoking, prioritize paralysis
    if hasAsthma and hasParalysis and hasSlickness then
        send("endure")
        send("curing prioaff paralysis")
        return
    end

    -- IMPATIENCE: Clear when present with paralysis or asthma (focus lock setup)
    if hasImpatience and (hasParalysis or hasAsthma) then
        Algedonic.Echo("Clearing <gold>impatience<white> - focus lock developing!")
        send("curing prioaff impatience")
        return
    end

    -- ANOREXIA GATE: Asthma + slickness = anorexia incoming, clear asthma
    if hasAsthma and hasSlickness and not hasAnorexia and not hasParalysis then
        if kelpStack >= 2 then
            send("curing prioaff asthma")
        end
        return
    end

    -- General impatience clearing when not in danger
    if hasImpatience and not hasParalysis then
        send("curing prioaff impatience")
        return
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
    -- Anti-Priest Defense: Counter guilt/spiritburn/tenderskin kill setup
    -- Kill condition: 2+ of these afflictions = approaching Inquisition
    -- Strategy: Shield defensively and prioritize curing lobelia afflictions

    -- Track the three dangerous afflictions
    local hasGuilt = ataxia.afflictions.guilt
    local hasSpiritburn = ataxia.afflictions.spiritburn
    local hasTenderskin = ataxia.afflictions.tenderskin

    -- Count how many of the 3 key afflictions we have
    local dangerCount = 0
    if hasGuilt then dangerCount = dangerCount + 1 end
    if hasSpiritburn then dangerCount = dangerCount + 1 end
    if hasTenderskin then dangerCount = dangerCount + 1 end

    -- Check shield status
    local hasShield = ataxia.defences.shield

    -- EMERGENCY DEFENSIVE MODE: 2+ afflictions = approaching kill condition
    if dangerCount >= 2 then
        -- Shield if not already shielded
        if not hasShield then
            Algedonic.Echo("<red>PRIEST KILL SETUP - SHIELD!<white>")
            send("touch shield")
        end

        -- Prioritize curing while shielded
        -- Priority: guilt (blocks focus) > spiritburn (spirit damage) > tenderskin (damage amp)
        if hasGuilt then
            send("curing prioaff guilt")
        elseif hasSpiritburn then
            send("curing prioaff spiritburn")
        elseif hasTenderskin then
            send("curing prioaff tenderskin")
        end
        return
    end

    -- Standard priority when only 1 or 0 dangerous afflictions
    -- Still cure these afflictions but without forcing shield
    if hasGuilt then
        send("curing prioaff guilt")
    elseif hasSpiritburn then
        send("curing prioaff spiritburn")
    elseif hasTenderskin then
        send("curing prioaff tenderskin")
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
   
