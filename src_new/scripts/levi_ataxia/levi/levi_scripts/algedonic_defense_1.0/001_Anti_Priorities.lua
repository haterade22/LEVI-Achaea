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

-- mystack is bootstrapped in _groups.yaml with SEVEN herbs while whatcures lists EIGHT --
-- ["pear"] = {"pressure"} has no counter. That divergence was invisible while the suffixed
-- name (`pressure3`) matched nothing; passing BASE names made it a crash. Sync the two here
-- rather than in the YAML so any future herb added to one is picked up automatically.
function Algedonic.SyncStackKeys()
  Algedonic.mystack = Algedonic.mystack or {}
  for herb in pairs(Algedonic.whatcures or {}) do
    Algedonic.mystack[herb] = Algedonic.mystack[herb] or 0
  end
end

-- How many afflictions currently contend for this herb? NINE call sites compared
-- `Algedonic.mystack["<herb>"]` against a number with no nil guard, and mystack is
-- bootstrapped only by the inline init in _groups.yaml -- so a herb present in whatcures but
-- not in that literal (["pear"] was exactly that) threw on comparison rather than reading 0.
function Algedonic.stackOf(herb)
  return (Algedonic.mystack and Algedonic.mystack[herb]) or 0
end

function Algedonic.Stack_My_Affs(adding, aff)
  Algedonic.SyncStackKeys()
  local stack = "default"
  for i, j in pairs(Algedonic.whatcures or {}) do
    if table.contains(j, aff) then
      stack = i
      break
    end
  end
  if stack == "default" then return end
  -- `or 0`: whatcures carries a ["pear"] = {"pressure"} entry that mystack has no key for,
  -- so this threw on every pressure gain the moment v4.7.274 started passing BASE names
  -- (the old suffixed `pressure3` matched nothing and returned above). Any future herb
  -- added to one table and not the other now self-heals instead of erroring.
  --
  -- Floored at 0: these are DERIVED counts. A cure with no matching gain -- an affliction
  -- applied before the system loaded, or anything the full Char.Afflictions.List rebuild
  -- did not see -- would otherwise walk them negative, which silently satisfies every
  -- `mystack[x] <= 1` test that reads them.
  if adding == true then
    Algedonic.mystack[stack] = (Algedonic.mystack[stack] or 0) + 1
  else
    Algedonic.mystack[stack] = math.max(0, (Algedonic.mystack[stack] or 0) - 1)
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
      -- The whole family, not just the base. A bare write sets the BASE, which the static
      -- burning4/burning5 overrides beat -- so raising only the base leaves the two most
      -- dangerous levels LESS urgent than the three below them.
      ataxia_setAffPrio("burning", 1)
      ataxia_setAffPrio("burning4", 1)
      ataxia_setAffPrio("burning5", 1)
    elseif aff == "hypothermia" then
      ataxia_sendCuringPriority("curing priority shivering 20;curing priority frozen 20", false)
    end
    if affed("frozen") or (affed("shivering") and ataxia_getPrio("frozen") ~= 2) then
      ataxia_sendCuringPriority("curing priority frozen 2;curing priority shivering 2;curing priority defence insulation 2", false)
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
  -- Ahead of the prioritySwaps guard: AntiPaladin is a CLASS handler, not a toggleable
  -- swap, so its escalation must be undone whether or not the swap table exists.
  if Algedonic.RestorePaladin then Algedonic.RestorePaladin() end
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
        ataxia_sendCuringPriority("curing priority frozen 2;curing priority shivering 2;curing priority defence insulation 2", false)
      else
        if ataxia_getPrio("frozen") ~= ataxia_defaultPrioAff("frozen") then ataxia_restorePrio("frozen") end
        if ataxia_getPrio("shivering") ~= ataxia_defaultPrioAff("shivering") then
          ataxia_restorePrio("shivering")
          ataxia_sendCuringPriority("curing priority defence insulation 20", false)
        end
      end
    elseif aff == "dehydrated" then
      -- Restores the same three names ApplySwaps raises. The old line also forced
      -- `ataxia.afflictions.burning = 1` -- a client-state lie that was harmless only while
      -- the decoder never produced a real burn level, and would now clobber the reading
      -- checkDamnationThreat depends on.
      for _, b in ipairs({"burning", "burning4", "burning5"}) do
        if ataxia_getPrio(b) ~= ataxia_defaultPrioAff(b) then ataxia_restorePrio(b) end
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
  -- (x or 0): these are numbers only once a stack has been seen, so a bare `>= 6` threw
  -- whenever the humour was absent. Pre-existing, but the decoder fix is what finally gives
  -- this handler live data to run on.
  elseif (ataxia.afflictions.temperedphlegmatic or 0) >= 6 and ataxia.afflictions.impatience then
    Algedonic.Echo("Clearing free <red>YOUR ABOUT TO GET LOCKED - WEARINESS LETHARGY ANOREXIA SLICKNESS INCOMMING <white>.")
    send("curing prioaff impatience")
  elseif (ataxia.afflictions.temperedphlegmatic or 0) >= 6 and not ataxia.afflictions.impatience and ataxia.afflictions.asthma then
    send("curing prioaff asthma")
  elseif not ataxia.afflictions.paralysis then
    if Algedonic.stackOf("goldenseal") == 1 and ataxia.afflictions.impatience then
      send("curing prioaff impatience")
    elseif Algedonic.stackOf("goldenseal") >= 2 and ataxia.afflictions.impatience and ataxia.afflictions.asthma then
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
      elseif Algedonic.stackOf("kelp") >= 3 and ataxia.afflictions.asthma and not ataxia.afflictions.paralysis then
        Algedonic.Echo("Digging for <green>asthma<white>! Be ready to hit <orange>FITNESS!")
        send("curing prioaff asthma")
      elseif ataxia.afflictions.asthma and ataxia.afflictions.manaleech then
        send("curing prioaff asthma")  
        
      end
    

end
function Algedonic.AntiBard()
      -- (x or 0) for the same reason as AntiAlchemist: an absent crescendo threw here.
      if (ataxia.afflictions.crescendo or 0) >= 4 then
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
  elseif ataxia.afflictions.fulminated and ataxia.afflictions.paralysis and Algedonic.stackOf("goldenseal") >= 1 then
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
    if Algedonic.stackOf("kelp") <= 1 then
      send("curing prioaff rebbies")
    elseif Algedonic.stackOf("ginseng") <= 1 then
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

-- The genuine rift lock, as ataxia_promptLocks() defines it: asthma + slickness/bloodfire +
-- BOTH arms out. That is the state in which you cannot outrift, and shielding is the correct
-- panic response. A single damaged arm is not it.
local function sentinelRiftLocked()
  local a = ataxia.afflictions
  local leftOut  = a.damagedleftarm  or a.mangledleftarm  or a.brokenleftarm
  local rightOut = a.damagedrightarm or a.mangledrightarm or a.brokenrightarm
  return (a.asthma and (a.slickness or a.bloodfire) and leftOut and rightOut) and true or false
end

-- SKULLBASH needs PRONE **and** a BROKEN HEAD -- both, simultaneously (user-confirmed game
-- mechanic, 2026-08-19). That single fact explains the whole Sentinel endgame:
--
--   * TRIP does double duty -- it prones us AND breaks the leg, so one action supplies half
--     the kill condition and removes our ability to stand out of the other half.
--   * The affliction lock is not a parallel win condition. It exists to make BOTH conditions
--     uncurable at once: prone cannot be stood out of (broken leg + weariness) and the head
--     cannot be restored (anorexia/slickness block the salve). In the death log the true lock
--     landed at 09:59:55.789 -- BEFORE the leg break (09:59:58) and the head break (10:00:02).
--   * He parked both limbs at 1-hit-from-break for 19s and 8s respectively and cashed them
--     only once the lock was up, because restoration is ~4s and heals ONE limb.
--
-- Therefore the alarm that matters is the CONJUNCTION, and the counter is to break EITHER leg
-- of it: restore the head, or stand. Warning on a broken head alone fires constantly against
-- any limb class and trains you to ignore it.
local function sentinelLimbWarn()
  if not ataxia_selfLimbBroken then return end
  local headBroken = ataxia_selfLimbBroken("head")
  local prone = ataxia.afflictions and ataxia.afflictions.prone

  if headBroken and prone then
    ataxia_boxEcho("SKULLBASH RANGE - HEAD BROKEN + PRONE - STAND OR RESTORE HEAD NOW", "a_darkred")
  elseif headBroken then
    ataxia_boxEcho("HEAD BROKEN - DO NOT GO PRONE - SKULLBASH KILLS", "a_darkred")
  elseif prone and ataxia_selfHitsToBreak and ataxia_selfHitsToBreak("head") <= 1 then
    -- The head is one hit away and we are already prone: he only needs the throw.
    ataxia_boxEcho("PRONE + HEAD 1 HIT FROM BREAK - STAND NOW", "a_darkred")
  end
end

function Algedonic.AntiSentinel()
if ataxia.afflictions.slickness and ataxia.afflictions.paralysis and not ataxia.afflictions.asthma then
  send("endure")
  send("curing prioaff paralysis")
-- v4.7.275: was `tAffs.prone` -- the TARGET's prone -- inside a branch that is entirely about
-- OUR curing. It was therefore never true in a 1v1, which gated off the kelp-stack handling
-- below: the one piece of code that addresses a Sentinel overloading the herb balance.
elseif ataxia.afflictions.prone then
  if ataxia.afflictions.asthma and Algedonic.stackOf("kelp") >= 3 then
    send("curing prioaff asthma")
  elseif ataxia.afflictions.impatience then
    send("curing prioaff impatience")
  end
--Prevent Getting Asthma from Badger
elseif ataxia.vitals.bleed >= 150 then
    send("curing prioaff haemophilia")
end

-- HEALTHLEECH (v4.7.275). 14,056 damage across 12 unblockable ticks in the 2026-08-19 log --
-- 16.5% of everything we took -- and it was NEVER cured, because it sits at priority 9 behind a
-- four-way tie at 7 on the same herb. The fox applies it on a free companion action, so it comes
-- straight back; the point is to make SSC spend one herb on it when it is the biggest single
-- source of incoming damage. Sensitivity first when both are up: it amplified every tick by 31%
-- (1,062 -> 1,390 the moment it landed), so curing it is worth more than curing the leech alone.
-- SENSITIVITY is a MEASURED +33% damage multiplier (v4.7.276): wolf bite 1,113 -> 1,480
-- (+33.0%) and healthleech tick 1,062 -> 1,390 (+30.9%) in the same log, two independent
-- sources. It multiplies EVERYTHING he and his animals do, so it outranks the leech itself --
-- and it is worth prioritising on its own, not only when healthleech happens to be up too.
if ataxia.afflictions.sensitivity then
  send("curing prioaff sensitivity")
elseif ataxia.afflictions.healthleech then
  send("curing prioaff healthleech")
end

-- RIFT LOCK / limb kill watch.
--
-- v4.7.275 -- what this block used to be, and why every line of it changed:
--
--   if ataxia.afflictions.damagedleftarm or ataxia.afflictions.damagedrightarm and not ...prone then
--       expandAlias("goto 11090")
--       preventriftlock = true
--       ataxia_boxEcho("TOUCH SHIELD TOUCH SHIELD - RIFT LOCK - RIFT LOCK -", "a_darkred")
--   end
--
-- Algedonic.Prioritize() runs on every affliction GAIN AND LOSS, and paralysis cycled 24 times
-- in that fight, so this fired ~20 times. The results, all visible in the log:
--
--   * `A or B and not C` parses as `A or (B and not C)` -- a damaged LEFT arm triggered it
--     regardless of prone. It also fired on a single damaged arm, which is not a rift lock.
--   * `goto 11090` is a hardcoded room id the mapper could not route to from the caverns:
--     "(mapper): Don't know how to get there (11090) from here :(" -- NINE times. A silent
--     no-op that reads like an escape plan. Auto-walking mid-fight on a hardcoded id is now
--     gone entirely; the user gets told to run instead.
--   * `preventriftlock` makes combatQueue() send `cq all;touch shield` on EVERY dispatch. We
--     shielded six times and a lemming stripped it within ~2s every single time, and each
--     `cq all` cleared our own attack queue. Six balances spent to block ourselves.
--
-- Now: the real rift-lock condition only, once per engagement, with no movement.
-- SKULLBASH EMERGENCY (v4.7.276). Confirmed condition: PRONE **and** BROKEN HEAD, together.
-- Both halves are individually cheap to cure, so the correct response is to attack whichever
-- one SSC can actually reach right now -- not to pick one and hope. `curing prioaff` is a
-- TEMPORARY prioritisation and does not write stored priorities, so this is safe to spam
-- (see memory/curing.md on the curingset write hazard).
if ataxia_selfLimbBroken and ataxia_selfLimbBroken("head") and ataxia.afflictions.prone then
  send("curing prioaff prone")
  send("curing prioaff damagedhead")
end

-- RIFT LOCK.
--
-- v4.7.276: this no longer sets `preventriftlock`, i.e. it no longer drives `touch shield`.
-- Shielding a Sentinel is a losing trade TWICE over and the 2026-08-19 log proves it:
--   * `ENRAGE LEMMING` (Woodlore) strips SHIELD before REBOUNDING and costs him NO BALANCE.
--     He stripped six of our shields, each within ~2 seconds of it going up.
--   * `RIVE` (Skirmishing, 2.25s) shatters a shield outright.
-- Every shield we raised cost a balance and bought about two seconds, and each one also fired
-- `cq all` through combatQueue(), clearing our own attack queue. Warn instead; the human can
-- still shield if they judge it worth it.
if sentinelRiftLocked() then
  if not Algedonic.sentinelRiftWarned then
    Algedonic.sentinelRiftWarned = true
    ataxia_boxEcho("RIFT LOCKED - BOTH ARMS OUT - RUN (shield gets lemming-stripped in ~2s)", "a_darkred")
  end
else
  Algedonic.sentinelRiftWarned = false
end

sentinelLimbWarn()
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
  if Algedonic.stackOf("goldenseal") >= 3 and not ataxia.afflictions.paralysis then
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
  elseif Algedonic.stackOf("kelp") >= 3 and ataxia.afflictions.asthma and not ataxia.afflictions.impatience and not ataxia.afflictions.paralysis then
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
  -- `horror (5)` -- parenthesised, with a space -- is not a form the game accepts anywhere
  -- else, and a rejected curing command is completely silent. `horror5` is the token the
  -- server itself uses in CURING PRIORITY LIST, so it is a real affliction name; whether
  -- PRIOAFF takes the suffixed form is still unverified. This branch was doubly dead until
  -- now: ataxia.afflictions.horror was never a number either.
  if (ataxia.afflictions.horror or 0) == 5 then
  send("curing prioaff horror5")
  elseif (ataxia.afflictions.horror or 0) == 4 then
  send("curing prioaff horror4")
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
  local kelpStack = Algedonic.stackOf("kelp") or 0

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
