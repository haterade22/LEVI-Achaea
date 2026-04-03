--[[mudlet
type: script
name: Anti Priorities
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Algedonic Defense 1.0
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Algedonic Defense 1.0 > Anti Priorities

-- ============================================================================
-- CORE FUNCTIONS (moved from _groups.yaml inline script)
-- ============================================================================

function Algedonic.Stack_My_Affs(adding, aff)
  local stack = "default"
  for i, j in pairs(Algedonic.whatcures) do
    if table.contains(j, aff) then
      stack = i
      break
    end
  end
  if stack == "default" then return end
  if adding == true then
    Algedonic.mystack[stack] = Algedonic.mystack[stack] + 1
  else
    Algedonic.mystack[stack] = Algedonic.mystack[stack] - 1
  end
end

function Algedonic.Echo(thing)
  cecho("\n<light_cyan>[Levi]: <white>"..thing)
end

function Algedonic.Count_My_Affs()
  local count = 0
  for _, v in pairs(ataxia.afflictions) do
    if v then
      count = count + 1
    end
  end
  return count
end

-- ============================================================================
-- DISPATCHER — table-driven, calls class-specific Anti* handler
-- ============================================================================

Algedonic._handlers = {
  Apostate = "AntiApostate",
  Alchemist = "AntiAlchemist",
  Bard = "AntiBard",
  Blademaster = "Blademaster",
  Serpent = "AntiSerpent",
  Shaman = "AntiShaman",
  Magi = "AntiMagi",
  Sylvan = "AntiSylvan",
  Unnameable = "AntiUnnameable",
  Psion = "AntiPsion",
  Priest = "AntiPriest",
  Sentinel = "AntiSentinel",
  Pariah = "AntiPariah",
  Occultist = "AntiOccultist",
  Druid = "AntiDruid",
  Depthswalker = "AntiDepthswalker",
  Airlord = "AntiAirlord",
  Waterlord = "AntiWaterlord",
  Firelord = "AntiFirelord",
  Paladin = "AntiPaladin",
  Infernal = "AntiInfernal",
}

function Algedonic.Prioritize()
  local targetclass = ataxiaNDB_getClass(target)
  local handlerName = Algedonic._handlers[targetclass]
  if handlerName and Algedonic[handlerName] then
    Algedonic[handlerName]()
  end
end

-- ============================================================================
-- GENERIC SWAPS — unified from Priority Swaps (003) + Class Specific (001)
-- All gated by ataxia.prioritySwaps toggles (aconfig prios)
-- ============================================================================

function Algedonic.ApplySwaps(aff)
  if not ataxia.prioritySwaps then ataxia_resetSwaps() end
  local ps = ataxia.prioritySwaps
  local tc = ataxiaNDB_Exists(target) and ataxiaNDB_getClass(target) or nil

  -- scyPara: boost scytherus if paralyzed
  if ps.scyPara and ps.scyPara.active then
    if affed("scytherus") and affed("paralysis") and ataxia_getPrio("scytherus") ~= 2 then
      ataxia_setAffPrio("scytherus", 2)
    end
  end

  -- conDis: boost confusion if disrupted+impatient
  if ps.conDis and ps.conDis.active then
    if affed("confusion") and affed("disrupted") and affed("impatience")
       and not affed("whisperingmadness") and ataxia_getPrio("confusion") ~= 2 then
      ataxia_setAffPrio("confusion", 2)
    end
  end

  -- astImp: impatience prio vs Alchemist/Serpent when para+asthma
  if ps.astImp and ps.astImp.active and tc then
    if affed("paralysis") and affed("asthma")
       and (tc == "Alchemist" or tc == "Serpent")
       and ataxia_getPrio("impatience") ~= 1 then
      ataxia_setAffPrio("impatience", 1)
    end
  end

  -- WATER: boost nausea vs Blademaster
  if ps.WATER and ps.WATER.active and tc then
    if affed("nausea") and (affed("asthma") or affed("weariness"))
       and tc == "Blademaster" then
      ataxia_setAffPrio("nausea", 1)
    end
  end

  -- brSlick: boost slickness when kelp stacked
  if ps.brSlick and ps.brSlick.active then
    if (affed("sensitivity") or affed("clumsiness") or affed("weariness"))
       and affed("asthma") and affed("slickness") and not affed("anorexia")
       and ataxia_getPrio("slickness") ~= 1 then
      ataxia_setAffPrio("slickness", 1)
    end
  end

  -- hypoImp: prio hypochondria over impatience
  if ps.hypoImp and ps.hypoImp.active then
    if (affed("lethargy") or affed("nausea") or affed("addiction"))
       and affed("hypochondria") and ataxia_getPrio("hypochondria") ~= 1 then
      ataxia_setAffPrio("impatience", 4)
      ataxia_setAffPrio("hypochondria", 1)
    end
  end

  -- ravaged: swap sipping priority on mindravaged
  if ps.ravaged and ps.ravaged.active and aff == "mindravaged" then
    if ataxia.settings.priohealth then
      ataxia_sendCuringPriority("curing priority mana", false)
    end
  end

  -- paraAst: prio paralysis when asthma blocks smoking
  if ps.paraAst and ps.paraAst.active then
    if affed("asthma") and affed("paralysis") and affed("slickness") then
      ataxia_setAffPrio("paralysis", 1)
    end
  end

  -- astWear: boost asthma vs Serpent when weariness present
  if ps.astWear and ps.astWear.active and tc then
    if affed("asthma") and affed("weariness") and tc == "Serpent" then
      ataxia_setAffPrio("asthma", 3)
    end
  end

  -- fratLock: boost fratricide when approaching softlock
  if ps.fratLock and ps.fratLock.active then
    if affed("fratricide") and affed("asthma") and affed("slickness") then
      ataxia_setAffPrio("fratricide", 4)
    end
  end

  -- psionBleed: boost haemophilia when bleed >= 125
  if ps.psionBleed and ps.psionBleed.active then
    if affed("haemophilia") and ataxia.vitals.bleed >= 125
       and ataxia_getPrio("haemophilia") > 2 then
      ataxia_setAffPrio("haemophilia", 2)
    end
  end

  -- magi: handle burns/frozen/dehydrated
  if ps.magi and ps.magi.active then
    if (aff == "dehydrated" or (aff == "burning" and affed("dehydrated")))
       and ataxia_getPrio("dehydrated") > 1 then
      ataxia_sendCuringPriority("curing priority burning 1", false)
    elseif aff == "hypothermia" then
      ataxia_sendCuringPriority("curing priority shivering 20;curing priority frozen 20", false)
    end
    if affed("frozen") or (affed("shivering") and ataxia_getPrio("frozen") ~= 2) then
      ataxia_sendCuringPriority("curing priority frozen 2 shivering 2;curing priority defence insulation 2", false)
    end
  end

  -- scaldTimeflux: deprioritize scalded during timeflux (always runs)
  if aff == "timeflux" then
    if ataxia_getPrio("scalded") < 26 and affed("timeflux") then
      ataxia_sendCuringPriority("curing priority scalded 26")
    end
  end
end

-- ============================================================================
-- RESTORE SWAPS — undo persistent prio changes when triggering aff is cured
-- ============================================================================

function Algedonic.RestoreSwaps(aff)
  if not ataxia.prioritySwaps then return end
  local ps = ataxia.prioritySwaps

  -- scyPara restore
  if ps.scyPara and ps.scyPara.active and aff == "scytherus" then
    if ataxia_getPrio("scytherus") ~= ataxia_defaultPrioAff("scytherus") then
      ataxia_restorePrio("scytherus")
    end
  end

  -- conDis restore
  if ps.conDis and ps.conDis.active and aff == "confusion" then
    if ataxia_getPrio("confusion") ~= ataxia_defaultPrioAff("confusion") then
      ataxia_restorePrio("confusion")
    end
  end

  -- astImp restore
  if ps.astImp and ps.astImp.active then
    if not (affed("paralysis") and affed("asthma")) then
      if ataxia_defaultPrioAff("impatience") ~= ataxia_getPrio("impatience") then
        ataxia_restorePrio("impatience")
      end
    end
  end

  -- brSlick restore
  if ps.brSlick and ps.brSlick.active then
    if not affed("asthma") and not (affed("sensitivity") or affed("clumsiness") or affed("weariness")) then
      if ataxia_defaultPrioAff("slickness") ~= ataxia_getPrio("slickness") then
        ataxia_restorePrio("slickness")
      end
    end
  end

  -- hypoImp restore
  if ps.hypoImp and ps.hypoImp.active and aff == "hypochondria" then
    ataxia_restorePrio("hypochondria")
    ataxia_restorePrio("impatience")
  end

  -- ravaged restore
  if ps.ravaged and ps.ravaged.active and aff == "mindravaged" then
    ataxia_sendCuringPriority("curing priority health", false)
  end

  -- paraAst restore
  if ps.paraAst and ps.paraAst.active and (aff == "paralysis" or aff == "asthma") then
    if ataxia_getPrio("paralysis") ~= ataxia_defaultPrioAff("paralysis") then
      ataxia_restorePrio("paralysis")
    end
  end

  -- astWear restore
  if ps.astWear and ps.astWear.active and (aff == "asthma" or aff == "weariness") then
    if ataxia_getPrio("asthma") ~= ataxia_defaultPrioAff("asthma") then
      ataxia_restorePrio("asthma")
    end
  end

  -- fratLock restore
  if ps.fratLock and ps.fratLock.active
     and (aff == "fratricide" or aff == "asthma" or aff == "slickness") then
    if ataxia_getPrio("fratricide") ~= ataxia_defaultPrioAff("fratricide") then
      ataxia_restorePrio("fratricide")
    end
  end

  -- psionBleed restore
  if ps.psionBleed and ps.psionBleed.active and aff == "haemophilia" then
    if ataxia_getPrio("haemophilia") ~= ataxia_defaultPrioAff("haemophilia") then
      ataxia_restorePrio("haemophilia")
    end
  end

  -- magi restore
  if ps.magi and ps.magi.active then
    if aff == "hypothermia" then
      if affed("frozen") or affed("shivering") then
        ataxia_sendCuringPriority("curing priority frozen 2 shivering 2;curing priority defence insulation 2", false)
      else
        if ataxia_getPrio("frozen") ~= ataxia_defaultPrioAff("frozen") then ataxia_restorePrio("frozen") end
        if ataxia_getPrio("shivering") ~= ataxia_defaultPrioAff("shivering") then
          ataxia_restorePrio("shivering")
          ataxia_sendCuringPriority("curing priority defence insulation 20", false)
        end
      end
    elseif aff == "dehydrated" then
      if ataxia_getPrio("burning") ~= ataxia_defaultPrioAff("burning") then
        if ataxia.afflictions.burning then ataxia.afflictions.burning = 1 end
        ataxia_restorePrio("burning")
      end
    end
  end

  -- scaldTimeflux restore (always runs)
  if aff == "timeflux" then
    if ataxia_getPrio("scalded") ~= ataxia_defaultPrioAff("scalded") then
      ataxia_restorePrio("scalded")
    end
  end
end

-- ============================================================================
-- CLASS-SPECIFIC ANTI-PRIORITY FUNCTIONS
-- ============================================================================

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
  ataxia_tryVultureTalon()
end

function Algedonic.AntiDruid()
    --Your conditions here
end
function Algedonic.AntiDepthswalker()

  if ataxia.afflictions.timeloop then
    send("curing prioaff timeloop")
    send("cq all;shield")
  elseif ataxia.afflictions.hypochondria and not ataxia.afflictions.paralysis then
    send("curing prioaff hypochondria")
  end
end

function Algedonic.AntiInfernal()
    -- All four limbs at least level 1 broken = restore immediately
    local leftArmBroken = ataxia.afflictions.brokenleftarm or ataxia.afflictions.damagedleftarm or ataxia.afflictions.mangledleftarm
    local rightArmBroken = ataxia.afflictions.brokenrightarm or ataxia.afflictions.damagedrightarm or ataxia.afflictions.mangledrightarm
    local leftLegBroken = ataxia.afflictions.brokenleftleg or ataxia.afflictions.damagedleftleg or ataxia.afflictions.mangledleftleg
    local rightLegBroken = ataxia.afflictions.brokenrightleg or ataxia.afflictions.damagedrightleg or ataxia.afflictions.mangledrightleg

    if leftArmBroken and rightArmBroken and leftLegBroken and rightLegBroken then
        Algedonic.Echo("<red>ALL LIMBS BROKEN - RESTORE!<white>")
        send("restore")
        return
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
  ataxia_tryVultureTalon()
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
  if ataxia.afflictions.unweavingmind and ataxia.afflictions.unweavingmind >= 2 then
    send("curing prioaff unweavingmind")
  elseif ataxia.afflictions.unweavingbody and ataxia.afflictions.unweavingbody >= 2 then
    send("curing prioaff unweavingbody")
  elseif ataxia.afflictions.unweavingspirit and ataxia.afflictions.asthma and not ataxia.afflictions.paralysis then
    send("curing prioaff asthma")
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
    local hasParalysis = ataxia.afflictions.paralysis
    local hasSlickness = ataxia.afflictions.slickness
    local hasAnorexia = ataxia.afflictions.anorexia
    local hasImpatience = ataxia.afflictions.impatience

    -- Can we tree? (not paralyzed, arms not both broken, tree off cooldown)
    local canTree = not hasParalysis
        and not (ataxia.afflictions.brokenleftarm and ataxia.afflictions.brokenrightarm)
        and tBals.tree

    -- APPROACHING LOCK: asthma + slickness + (impatience OR anorexia)
    -- Tree NOW before paralysis locks us out
    local approachingLock = hasAsthma and hasSlickness and (hasImpatience or hasAnorexia)

    if canTree and approachingLock then
        Algedonic.Echo("<red>APPROACHING LOCK - TREE!<white>")
        send("touch tree")
        return
    end

    -- IMPATIENCE: Cure immediately and shield to block next serpent attack
    if hasImpatience and not hasParalysis then
        send("curing prioaff impatience")
        send("cq all;touch shield")
        Algedonic.Echo("<red>TOUCH SHIELD - IMPATIENCE!<white>")
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
  local hasAsthma = ataxia.afflictions.asthma
  local hasAeon = ataxia.afflictions.aeon
  local hasParalysis = ataxia.afflictions.paralysis
  local hasSlickness = ataxia.afflictions.slickness
  local hasAnorexia = ataxia.afflictions.anorexia
  local hasWhisperingmadness = ataxia.afflictions.whisperingmadness
  local hasImpatience = ataxia.afflictions.impatience
  local hasProne = ataxia.afflictions.prone or tAffs.prone
  local kelpStack = Algedonic.mystack["kelp"] or 0

  -- PRIORITY 1: AEON - Must cure asthma to smoke elm
  if hasAeon and hasAsthma then
    Algedonic.Echo("<red>AEON + ASTHMA - Digging for asthma to smoke elm!<white>")
    send("curing prioaff asthma")
    return
  end

  -- PRIORITY 2: Paralysis + Slickness + Prone = stuck, need endure
  if hasProne and hasParalysis and hasSlickness then
    Algedonic.Echo("<yellow>STUCK - Endure + para priority!<white>")
    send("endure")
    send("curing prioaff paralysis")
    return
  end

  -- PRIORITY 3: Asthma lock developing (asthma + slickness + impatience/anorexia)
  if hasAsthma and hasSlickness and (hasImpatience or hasAnorexia) then
    if kelpStack >= 2 then
      Algedonic.Echo("<orange>LOCK DEVELOPING - Digging for asthma!<white>")
      send("curing prioaff asthma")
    else
      -- Low kelp, try slickness first
      send("curing prioaff slickness")
    end
    return
  end

  -- PRIORITY 4: Asthma alone (blocks smoking elm for aeon cure)
  if hasAsthma and not hasParalysis then
    send("curing prioaff asthma")
    return
  end

  -- PRIORITY 5: Whisperingmadness (from bubonis) - smoke cure
  if hasWhisperingmadness and not hasAsthma and not hasParalysis then
    send("curing prioaff whisperingmadness")
    return
  end

  -- PRIORITY 6: Heavy paralysis spam - enable endure when para + slick
  if hasParalysis and hasSlickness then
    send("endure")
    send("curing prioaff paralysis")
    return
  end
end

function Algedonic.AntiWaterlord()
  local hasParalysis = ataxia.afflictions.paralysis
  local hasAsthma = ataxia.afflictions.asthma
  local hasSlickness = ataxia.afflictions.slickness

  -- EMERGENCY: par + ast + sli = full defensive mode
  -- Clear queue (stop attacking), endure for para, shield for safety
  if hasParalysis and hasAsthma and hasSlickness then
    send("cq all;endure;touch shield")
    send("curing prioaff paralysis")
    return
  end

  -- PRIORITY 1: Haemophilia (ginseng) — prevents severe bleeding for latch kill
  if ataxia.afflictions.haemophilia then
    send("curing prioaff haemophilia")
    return
  end

  -- PRIORITY 2: Weariness (kelp) — blocks Purify passive cure
  if ataxia.afflictions.weariness then
    send("curing prioaff weariness")
    return
  end

  -- PRIORITY 3: Other ginseng affs (latch components + dangerous)
  local ginsengs = {"nausea", "lethargy", "addiction", "darkshade", "scytherus"}
  for _, aff in ipairs(ginsengs) do
    if ataxia.afflictions[aff] then
      send("curing prioaff " .. aff)
      return
    end
  end
end

function Algedonic.AntiFirelord()
  -- TODO: implement fire lord defense priorities
end
