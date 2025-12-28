--[[mudlet
type: script
name: Ekanelia Offense
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Serpent
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    Serpent Ekanelia Offense System

    Two Kill Strategies with Auto-Switching:
    1. True Lock (Primary) - Build toward full affliction lock
    2. Darkshade Kill (Secondary) - Keep darkshade stuck 26 seconds for kill

    Ekanelia Transformations (BITE only):
    - kalmia: clumsiness + weariness → asthma + slickness
    - monkshood: asthma + masochism + weariness → impatience
    - curare: hypersomnia + masochism → paralysis + hypochondria
    - loki: confusion + recklessness → nausea + paralysis
    - scytherus: addiction + nausea → camus damage
]]--

-- Configuration Variables
serpOffenseMode = serpOffenseMode or "auto"  -- "lock", "darkshade", or "auto"
serpStrategy = serpStrategy or "lock"        -- Current active strategy
attackMode = attackMode or "doublestab"      -- "bite" or "doublestab"
ekaneliaReady = ekaneliaReady or {}          -- Ekanelia opportunities detected
impulseReady = false                          -- Impulse delivery state
affTimers = affTimers or {}                   -- Affliction timestamps

-- Constants
DARKSHADE_KILL_TIME = 26  -- Seconds darkshade must stick for kill
DARKSHADE_SWITCH_TIME = 15 -- Seconds before switching to darkshade mode

--[[
    Check for Ekanelia opportunities
    Detects when conditionals are met for BITE transformations
]]--
function checkEkaneliaOpportunities()
    ekaneliaReady = {}

    -- kalmia: clumsiness + weariness → asthma + slickness
    -- Only trigger if we don't already have BOTH asthma and slickness
    if tAffs.clumsiness and tAffs.weariness and not (tAffs.asthma and tAffs.slickness) then
        ekaneliaReady.kalmia = true
    end

    -- monkshood: asthma + masochism + weariness → impatience
    -- Only trigger if we don't already have impatience
    if tAffs.asthma and tAffs.masochism and tAffs.weariness and not tAffs.impatience then
        ekaneliaReady.monkshood = true
    end

    -- curare: hypersomnia + masochism → paralysis + hypochondria
    -- Only trigger if we don't already have paralysis
    if tAffs.hypersomnia and tAffs.masochism and not tAffs.paralysis then
        ekaneliaReady.curare = true
    end

    -- loki: confusion + recklessness → nausea + paralysis
    -- Only trigger if we don't already have paralysis
    if tAffs.confusion and tAffs.recklessness and not tAffs.paralysis then
        ekaneliaReady.loki = true
    end

    -- scytherus: addiction + nausea → camus (damage bonus)
    -- Always ready when conditionals met (damage is always good)
    if tAffs.addiction and tAffs.nausea then
        ekaneliaReady.scytherus = true
    end
end

--[[
    Check if Impulse can deliver mental afflictions
    Requires: asthma + weariness + no fangbarrier/sileris
]]--
function checkImpulseReady()
    -- Impulse requires: asthma + weariness + no fangbarrier
    impulseReady = tAffs.asthma and tAffs.weariness and not tAffs.fangbarrier and not tAffs.sileris
    return impulseReady
end

--[[
    Check darkshade timer for kill condition
]]--
function checkDarkshadeTimer()
    if tAffs.darkshade and affTimers.darkshade then
        local darkshadeStuckTime = getEpoch() - affTimers.darkshade
        if darkshadeStuckTime >= DARKSHADE_KILL_TIME then
            Algedonic.Echo("<magenta>DARKSHADE KILL!<white> " .. math.floor(darkshadeStuckTime) .. "s stuck - target should be dead!")
            return true
        end
        return darkshadeStuckTime
    end
    return 0
end

--[[
    Count ginseng stack afflictions
    Ginseng cures: addiction, darkshade, haemophilia, lethargy, scytherus, nausea
]]--
function countGinsengStack()
    local count = 0
    local ginsengAffs = {"addiction", "darkshade", "haemophilia", "lethargy", "scytherus", "nausea"}
    for _, aff in ipairs(ginsengAffs) do
        if tAffs[aff] then count = count + 1 end
    end
    return count
end

--[[
    Determine which strategy to use based on current state
    Auto-switches between lock and darkshade based on progress
]]--
function determineStrategy()
    local darkshadeStuckTime = 0
    if tAffs.darkshade and affTimers.darkshade then
        darkshadeStuckTime = getEpoch() - affTimers.darkshade
    end

    local ginsengCount = countGinsengStack()

    -- Strategy decision logic
    if tAffs.darkshade and ginsengCount >= 2 and darkshadeStuckTime > DARKSHADE_SWITCH_TIME then
        -- Darkshade is sticking well, protect it
        serpStrategy = "darkshade"
        Algedonic.Echo("<magenta>DARKSHADE MODE<white> - " .. math.floor(darkshadeStuckTime) .. "s stuck, " .. ginsengCount .. " ginseng affs")
    elseif truelock or hardlock then
        -- Approaching lock, finish it
        serpStrategy = "lock"
        Algedonic.Echo("<green>LOCK MODE<white> - approaching lock")
    elseif softlock then
        -- Soft lock achieved, push for hard/true lock
        serpStrategy = "lock"
    else
        -- Default to lock strategy
        serpStrategy = "lock"
    end
end

--[[
    Build venom list for True Lock strategy
    Prioritizes Ekanelia opportunities, then standard lock progression
]]--
function buildLockVenoms()
    envenomList = {}
    envenomListTwo = {}
    attackMode = "doublestab"

    -- Priority 1: Ekanelia opportunities (use BITE for bonus afflictions)
    if ekaneliaReady.kalmia then
        -- kalmia BITE gives asthma + slickness (2 lock affs in 1!)
        attackMode = "bite"
        table.insert(envenomList, "kalmia")
        Algedonic.Echo("<yellow>EKANELIA KALMIA<white> - asthma + slickness!")
        return
    elseif ekaneliaReady.monkshood then
        -- monkshood BITE gives disfigurement + impatience (bypasses Impulse!)
        attackMode = "bite"
        table.insert(envenomList, "monkshood")
        Algedonic.Echo("<yellow>EKANELIA MONKSHOOD<white> - impatience!")
        return
    elseif ekaneliaReady.curare then
        -- curare BITE gives paralysis + hypochondria
        attackMode = "bite"
        table.insert(envenomList, "curare")
        Algedonic.Echo("<yellow>EKANELIA CURARE<white> - paralysis + hypochondria!")
        return
    elseif ekaneliaReady.loki then
        -- loki BITE gives nausea + paralysis (predictable!)
        attackMode = "bite"
        table.insert(envenomList, "loki")
        Algedonic.Echo("<yellow>EKANELIA LOKI<white> - nausea + paralysis!")
        return
    end

    -- Priority 2: Standard lock progression via DST

    -- Lock state checks
    if truelock then
        -- True lock achieved, apply class-specific lock aff
        local lockAff = getLockingAffliction(target)
        if lockAff == "weariness" and not tAffs.weariness then
            table.insert(envenomList, "vernalius")
        elseif lockAff == "paralyse" and not tAffs.paralysis then
            table.insert(envenomList, "curare")
        else
            table.insert(envenomList, "voyria")
        end
    elseif hardlock and not tAffs.paralysis then
        -- Hard lock, need paralysis
        table.insert(envenomList, "curare")
    elseif softlock and not tAffs.paralysis then
        -- Soft lock, need paralysis
        table.insert(envenomList, "curare")
    -- Kelp stack setup (enables Impulse)
    elseif not tAffs.clumsiness then
        table.insert(envenomList, "xentio")
    elseif not tAffs.weariness then
        table.insert(envenomList, "vernalius")
    elseif not tAffs.asthma then
        table.insert(envenomList, "kalmia")
    -- Bloodroot stack (lock completion)
    elseif not tAffs.slickness then
        table.insert(envenomList, "gecko")
    elseif not tAffs.paralysis then
        table.insert(envenomList, "curare")
    -- Ginseng afflictions (darkshade setup + damage)
    elseif not tAffs.darkshade then
        table.insert(envenomList, "darkshade")
    elseif not tAffs.addiction then
        table.insert(envenomList, "vardrax")
    elseif not tAffs.nausea then
        table.insert(envenomList, "euphorbia")
    else
        table.insert(envenomList, "aconite")
    end

    -- Build second venom for DST (different from first)
    if attackMode == "doublestab" then
        buildSecondVenom()
    end
end

--[[
    Build second venom for doublestab (must differ from first)
]]--
function buildSecondVenom()
    local firstVenom = envenomList[1]

    -- Priority chain for second venom
    if not tAffs.paralysis and firstVenom ~= "curare" then
        table.insert(envenomListTwo, "curare")
    elseif not tAffs.slickness and firstVenom ~= "gecko" then
        table.insert(envenomListTwo, "gecko")
    elseif not tAffs.clumsiness and firstVenom ~= "xentio" then
        table.insert(envenomListTwo, "xentio")
    elseif not tAffs.asthma and firstVenom ~= "kalmia" then
        table.insert(envenomListTwo, "kalmia")
    elseif not tAffs.weariness and firstVenom ~= "vernalius" then
        table.insert(envenomListTwo, "vernalius")
    elseif not tAffs.darkshade and firstVenom ~= "darkshade" then
        table.insert(envenomListTwo, "darkshade")
    elseif not tAffs.addiction and firstVenom ~= "vardrax" then
        table.insert(envenomListTwo, "vardrax")
    elseif not tAffs.nausea and firstVenom ~= "euphorbia" then
        table.insert(envenomListTwo, "euphorbia")
    elseif firstVenom ~= "aconite" then
        table.insert(envenomListTwo, "aconite")
    else
        table.insert(envenomListTwo, "sumac")
    end
end

--[[
    Build venom list for Darkshade Kill strategy
    Focuses on ginseng stack while maintaining lock pressure
]]--
function buildDarkshadeVenoms()
    envenomList = {}
    envenomListTwo = {}
    attackMode = "doublestab"

    -- Priority 1: Ekanelia scytherus for camus damage
    if ekaneliaReady.scytherus then
        attackMode = "bite"
        table.insert(envenomList, "scytherus")
        Algedonic.Echo("<magenta>EKANELIA SCYTHERUS<white> - camus damage!")
        return
    end

    -- Priority 2: Maintain lock pressure while building ginseng stack

    -- Lock afflictions (forces other cure priorities)
    if not tAffs.asthma then
        table.insert(envenomList, "kalmia")
    elseif not tAffs.paralysis then
        table.insert(envenomList, "curare")
    elseif not tAffs.slickness then
        table.insert(envenomList, "gecko")
    -- Ginseng stack to protect darkshade
    elseif not tAffs.addiction then
        table.insert(envenomList, "vardrax")
    elseif not tAffs.nausea then
        table.insert(envenomList, "euphorbia")
    elseif not tAffs.scytherus then
        table.insert(envenomList, "scytherus")
    elseif not tAffs.haemophilia then
        table.insert(envenomList, "notechis")
    -- Kelp stack for additional pressure
    elseif not tAffs.clumsiness then
        table.insert(envenomList, "xentio")
    elseif not tAffs.weariness then
        table.insert(envenomList, "vernalius")
    else
        table.insert(envenomList, "aconite")
    end

    -- Build second venom for DST
    if attackMode == "doublestab" then
        buildSecondVenom()
    end
end

--[[
    Execute the attack based on current strategy and venom selection
]]--
function serp_ekanelia_attack()
    if not target or target == "" then
        Algedonic.Echo("<red>No target set!<white>")
        return
    end

    local atk = combatQueue()

    -- Handle defenses first (rebounding, shield)
    if tAffs.rebounding and tAffs.shield then
        atk = atk .. "wield left dirk;wield right lash;purge;order adder kill " .. target .. ";flay " .. target .. " shield " .. (envenomListTwo[1] or "curare")
    elseif tAffs.rebounding then
        atk = atk .. "wield left dirk;wield right lash;purge;order adder kill " .. target .. ";flay " .. target .. " rebounding " .. (envenomListTwo[1] or "curare")
    elseif tAffs.shield then
        atk = atk .. "wield left dirk;wield right lash;purge;order adder kill " .. target .. ";flay " .. target .. " shield " .. (envenomListTwo[1] or "curare")
    else
        -- Check for Impulse opportunity (delivers impatience/anorexia)
        local impulseCmd = ""
        if checkImpulseReady() and not tAffs.impatience then
            impulseCmd = "impulse " .. target .. " suggest impatience;"
        elseif checkImpulseReady() and tAffs.impatience and not tAffs.anorexia then
            impulseCmd = "impulse " .. target .. " suggest anorexia;"
        end

        -- Build attack based on mode
        if attackMode == "bite" then
            atk = atk .. "wield left dirk;wield right shield;purge;order adder kill " .. target .. ";" .. impulseCmd .. "bite " .. target .. " " .. envenomList[1]
        else
            atk = atk .. "wield left dirk;wield right shield;purge;order adder kill " .. target .. ";" .. impulseCmd .. "doublestab " .. target .. " " .. envenomList[1] .. " " .. envenomListTwo[1]
        end
    end

    -- Execute if target is present
    if table.contains(ataxia.playersHere, target) then
        send("queue addclear freestand " .. atk)
    else
        Algedonic.Echo("<red>Target not in room!<white>")
    end
end

--[[
    Main offense function - call this to attack
]]--
function serp_ekanelia_offense()
    -- Initialize state
    tAffs.hypnotising = tAffs.hypnotising or false
    tAffs.hypnotised = tAffs.hypnotised or false
    tAffs.hypnoseal = tAffs.hypnoseal or false
    tAffs.snapped = tAffs.snapped or false

    -- Get target lock status
    checkTargetLocks()

    -- Check for Ekanelia opportunities
    checkEkaneliaOpportunities()

    -- Check darkshade timer
    local darkshadeTime = checkDarkshadeTimer()

    -- Auto-switch strategy based on progress
    if serpOffenseMode == "auto" then
        determineStrategy()
    elseif serpOffenseMode == "lock" then
        serpStrategy = "lock"
    elseif serpOffenseMode == "darkshade" then
        serpStrategy = "darkshade"
    end

    -- Build venom lists based on strategy
    if serpStrategy == "lock" then
        buildLockVenoms()
    else
        buildDarkshadeVenoms()
    end

    -- Execute attack
    serp_ekanelia_attack()
end

--[[
    Mode switching functions
]]--
function serp_setmode_lock()
    serpOffenseMode = "lock"
    cecho("\n<green>Serpent offense: LOCK mode<reset>\n")
end

function serp_setmode_darkshade()
    serpOffenseMode = "darkshade"
    cecho("\n<magenta>Serpent offense: DARKSHADE mode<reset>\n")
end

function serp_setmode_auto()
    serpOffenseMode = "auto"
    cecho("\n<yellow>Serpent offense: AUTO mode<reset>\n")
end

--[[
    Status display function
]]--
function serp_status()
    local darkshadeTime = 0
    if tAffs.darkshade and affTimers.darkshade then
        darkshadeTime = getEpoch() - affTimers.darkshade
    end

    local ginsengCount = countGinsengStack()

    cecho("\n<cyan>===== Serpent Ekanelia Status =====<reset>\n")
    cecho("<white>Mode: <yellow>" .. serpOffenseMode .. "<reset>\n")
    cecho("<white>Strategy: <yellow>" .. serpStrategy .. "<reset>\n")
    cecho("<white>Darkshade: " .. (tAffs.darkshade and ("<green>YES<white> (" .. math.floor(darkshadeTime) .. "s)") or "<red>NO") .. "<reset>\n")
    cecho("<white>Ginseng Stack: <yellow>" .. ginsengCount .. "/6<reset>\n")
    cecho("<white>Impulse Ready: " .. (checkImpulseReady() and "<green>YES" or "<red>NO") .. "<reset>\n")

    -- Ekanelia opportunities
    checkEkaneliaOpportunities()
    if next(ekaneliaReady) then
        cecho("<white>Ekanelia Ready: ")
        for k, v in pairs(ekaneliaReady) do
            if v then cecho("<yellow>" .. k .. " ") end
        end
        cecho("<reset>\n")
    end
    cecho("<cyan>===================================<reset>\n")
end
