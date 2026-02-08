--[[mudlet
type: script
name: Serpent Offense
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
    ============================================================================
    SERPENT OFFENSE SYSTEM
    ============================================================================

    Complete serpent offense with three kill routes and Ekanelia support.

    KILL ROUTES:
    1. Impulse Lock (Primary)
       - Build kelp stack (asthma + weariness) to enable Impulse
       - Flay sileris/fangbarrier to open target
       - Deliver impatience/anorexia via Impulse
       - Complete lock with paralysis + slickness

    2. Hypnosis + Fratricide Combo
       - Hypnotise target, suggest fratricide
       - Snap to apply fratricide
       - Impulse delivers mental affs that RELAPSE after cure!
       - Creates inescapable focus lock

    3. Darkshade DoT
       - Stack ginseng afflictions to protect darkshade
       - Keep darkshade stuck 26+ seconds for kill
       - Add scytherus for bonus damage

    EKANELIA TRANSFORMATIONS (BITE only):
    - kalmia: clumsiness + weariness → asthma + slickness
    - monkshood: asthma + masochism + weariness → disfigurement + impatience
    - curare: hypersomnia + masochism → paralysis + hypochondria
    - loki: confusion + recklessness → nausea + paralysis
    - scytherus: addiction + nausea → scytherus + camus damage

    ALIASES:
    - ek        : Main attack (semi-auto trigger)
    - eklock    : Lock mode
    - ekhyp     : Hypnosis combo mode
    - ekdark    : Darkshade DoT mode
    - ekauto    : Auto-switch mode
    - ekstatus  : Status display
    ============================================================================
]]--

-- =============================================================================
-- INITIALIZATION & CONFIGURATION
-- =============================================================================

-- Initialize namespaces
serpent = serpent or {}
serpent.config = serpent.config or {}
serpent.hypnosis = serpent.hypnosis or {}

-- Configuration Variables
serpOffenseMode = serpOffenseMode or "auto"  -- "lock", "darkshade", "hypnosis", or "auto"
serpStrategy = serpStrategy or "lock"        -- Current active strategy
attackMode = attackMode or "doublestab"      -- "bite" or "doublestab"
ekaneliaReady = ekaneliaReady or {}          -- Ekanelia opportunities detected
impulseReady = false                          -- Impulse delivery state
affTimers = affTimers or {}                   -- Affliction timestamps

-- Configuration options
serpent.config = {
    debug = false,
    echoStrategy = true,
    echoAffs = true,  -- Show target afflictions each attack for debugging
    autoFratricide = true,
}

-- Constants
DARKSHADE_KILL_TIME = 26   -- Seconds darkshade must stick for kill
DARKSHADE_SWITCH_TIME = 15 -- Seconds before switching to darkshade mode
SNAP_DELAY = 4             -- Seconds after hypnotise before snap is ready
COOLDOWN_TIME = 4          -- Seconds cooldown after snapping

-- =============================================================================
-- HYPNOSIS STATE MACHINE
-- =============================================================================

--[[
    Hypnosis State Machine

    Tracks hypnosis state through the combat cycle:
    idle -> hypnotising -> hypnotised -> suggesting -> ready_snap -> snapped -> cooldown

    Key mechanic: Fratricide causes Impulse-delivered mental afflictions to RELAPSE
    after being cured, creating an inescapable focus lock.
]]--

serpent.hypnosis = {
    phase = "idle",            -- idle, hypnotising, hypnotised, suggesting, ready_snap, cooldown
    suggestions = {},          -- Queue of suggestions to deliver
    fratricideApplied = false, -- Fratricide suggestion queued
    fratricideActive = false,  -- Fratricide currently on target
    snapTimer = nil,           -- Timer ID for 4-second SNAP delay
    snapReadyTime = nil,       -- Epoch when snap becomes ready
    hypnoTarget = nil,         -- Target being hypnotised
}

-- Called when we begin hypnotising a target
function serpent.hypnosis.start(tar)
    serpent.hypnosis.phase = "hypnotising"
    serpent.hypnosis.suggestions = {}
    serpent.hypnosis.fratricideApplied = false
    serpent.hypnosis.hypnoTarget = tar or target

    if serpent.config.debug then
        Algedonic.Echo("<cyan>HYPNOSIS: <white>Starting hypnotise on " .. (tar or target))
    end
end

-- Called when target is fully hypnotised
function serpent.hypnosis.onHypnotised()
    serpent.hypnosis.phase = "hypnotised"
    tAffs.hypnotised = true
    tAffs.hypnotising = false

    -- Set timer for when snap will be ready
    serpent.hypnosis.snapReadyTime = getEpoch() + SNAP_DELAY

    Algedonic.Echo("<green>HYPNOSIS: <white>Target hypnotised! Snap ready in " .. SNAP_DELAY .. "s")

    -- Start timer to update phase to ready_snap
    if serpent.hypnosis.snapTimer then
        killTimer(serpent.hypnosis.snapTimer)
    end
    serpent.hypnosis.snapTimer = tempTimer(SNAP_DELAY, function()
        if serpent.hypnosis.phase == "suggesting" or serpent.hypnosis.phase == "hypnotised" then
            serpent.hypnosis.phase = "ready_snap"
            Algedonic.Echo("<yellow>HYPNOSIS: <white>SNAP READY!")
        end
    end)
end

-- Called when a suggestion is applied
function serpent.hypnosis.onSuggested(suggestion)
    serpent.hypnosis.phase = "suggesting"

    -- Track fratricide specifically
    if suggestion and suggestion:lower():find("fratricide") then
        serpent.hypnosis.fratricideApplied = true
        Algedonic.Echo("<magenta>HYPNOSIS: <white>Fratricide queued - mental affs will RELAPSE!")
    end

    table.insert(serpent.hypnosis.suggestions, suggestion)

    if serpent.config.debug then
        Algedonic.Echo("<cyan>HYPNOSIS: <white>Suggested " .. (suggestion or "unknown"))
    end
end

-- Called when snap is triggered
function serpent.hypnosis.onSnapped()
    serpent.hypnosis.phase = "cooldown"
    tAffs.snapped = true
    tAffs.hypnotised = false

    -- If fratricide was suggested, it's now active
    if serpent.hypnosis.fratricideApplied then
        serpent.hypnosis.fratricideActive = true
        tAffs.fratricide = true
        Algedonic.Echo("<red>HYPNOSIS: <white>SNAP! Fratricide ACTIVE - Impulse affs will relapse!")
    else
        Algedonic.Echo("<yellow>HYPNOSIS: <white>SNAP triggered!")
    end

    -- Clear snap timer
    if serpent.hypnosis.snapTimer then
        killTimer(serpent.hypnosis.snapTimer)
        serpent.hypnosis.snapTimer = nil
    end

    -- Start cooldown timer
    tempTimer(COOLDOWN_TIME, function()
        serpent.hypnosis.phase = "idle"
    end)
end

-- Called when target cures fratricide
function serpent.hypnosis.onFratricideCured()
    serpent.hypnosis.fratricideActive = false
    tAffs.fratricide = false
    Algedonic.Echo("<dim_grey>HYPNOSIS: <white>Target cured fratricide")
end

-- Reset hypnosis state (on target change, death, etc.)
function serpent.hypnosis.reset()
    serpent.hypnosis.phase = "idle"
    serpent.hypnosis.suggestions = {}
    serpent.hypnosis.fratricideApplied = false
    serpent.hypnosis.fratricideActive = false
    serpent.hypnosis.hypnoTarget = nil
    serpent.hypnosis.snapReadyTime = nil

    if serpent.hypnosis.snapTimer then
        killTimer(serpent.hypnosis.snapTimer)
        serpent.hypnosis.snapTimer = nil
    end
end

-- Returns the appropriate hypnosis command based on current state
function serpent.hypnosis.getCommand()
    local tar = target or serpent.hypnosis.hypnoTarget

    -- Phase: idle - start hypnosis
    if serpent.hypnosis.phase == "idle" then
        return "hypnotise " .. tar
    end

    -- Phase: hypnotised/suggesting - suggest fratricide if not done
    if (serpent.hypnosis.phase == "hypnotised" or serpent.hypnosis.phase == "suggesting")
       and not serpent.hypnosis.fratricideApplied then
        return "suggest " .. tar .. " fratricide"
    end

    -- Phase: ready_snap - snap!
    if serpent.hypnosis.phase == "ready_snap" then
        return "snap"
    end

    return nil
end

-- Returns true if snap is ready
function serpent.hypnosis.canSnap()
    return serpent.hypnosis.phase == "ready_snap"
end

-- Returns true if hypnosis is in progress
function serpent.hypnosis.isActive()
    return serpent.hypnosis.phase ~= "idle" and serpent.hypnosis.phase ~= "cooldown"
end

-- Returns true if fratricide is active on target
function serpent.hypnosis.hasFratricide()
    return serpent.hypnosis.fratricideActive or tAffs.fratricide
end

-- Returns seconds until snap is ready, or 0 if ready
function serpent.hypnosis.getTimeToSnap()
    if serpent.hypnosis.phase == "ready_snap" then
        return 0
    end
    if serpent.hypnosis.snapReadyTime then
        local remaining = serpent.hypnosis.snapReadyTime - getEpoch()
        return remaining > 0 and remaining or 0
    end
    return -1  -- Not in hypnosis
end

-- Display hypnosis state
function serpent.hypnosis.status()
    cecho("\n<cyan>===== Hypnosis Status =====<reset>\n")
    cecho("<white>Phase: <yellow>" .. serpent.hypnosis.phase .. "<reset>\n")
    cecho("<white>Target: <yellow>" .. (serpent.hypnosis.hypnoTarget or "none") .. "<reset>\n")
    cecho("<white>Fratricide Queued: " ..
        (serpent.hypnosis.fratricideApplied and "<green>YES" or "<red>NO") .. "<reset>\n")
    cecho("<white>Fratricide Active: " ..
        (serpent.hypnosis.fratricideActive and "<green>YES" or "<red>NO") .. "<reset>\n")

    local timeToSnap = serpent.hypnosis.getTimeToSnap()
    if timeToSnap == 0 then
        cecho("<white>Snap: <green>READY!<reset>\n")
    elseif timeToSnap > 0 then
        cecho("<white>Snap Ready In: <yellow>" .. string.format("%.1f", timeToSnap) .. "s<reset>\n")
    else
        cecho("<white>Snap: <dim_grey>Not hypnotising<reset>\n")
    end

    if #serpent.hypnosis.suggestions > 0 then
        cecho("<white>Suggestions: <yellow>")
        for _, sug in ipairs(serpent.hypnosis.suggestions) do
            cecho(sug .. " ")
        end
        cecho("<reset>\n")
    end
    cecho("<cyan>===========================<reset>\n")
end

-- =============================================================================
-- EKANELIA DETECTION
-- =============================================================================

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

-- =============================================================================
-- IMPULSE DETECTION
-- =============================================================================

--[[
    Check if Impulse can deliver mental afflictions
    Requires: asthma + weariness + no fangbarrier/sileris
]]--
function checkImpulseReady()
    impulseReady = tAffs.asthma and tAffs.weariness and not tAffs.fangbarrier and not tAffs.sileris
    return impulseReady
end

-- =============================================================================
-- DARKSHADE TRACKING
-- =============================================================================

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

-- =============================================================================
-- STACK COUNTING
-- =============================================================================

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
    Count kelp stack afflictions
]]--
function countKelpStack()
    local count = 0
    local kelpAffs = {"asthma", "clumsiness", "hypochondria", "sensitivity", "weariness", "healthleech", "parasite"}
    for _, aff in ipairs(kelpAffs) do
        if tAffs[aff] then count = count + 1 end
    end
    return count
end

--[[
    Count bloodroot stack afflictions
]]--
function countBloodrootStack()
    local count = 0
    if tAffs.paralysis then count = count + 1 end
    if tAffs.slickness then count = count + 1 end
    return count
end

-- =============================================================================
-- ADAPTIVE STRATEGY SYSTEM
-- =============================================================================

--[[
    Cure tracking - monitors how quickly target cures different herb types
    This allows us to adapt strategy based on their curing priorities
]]--
serpent.cureTracking = serpent.cureTracking or {
    kelpCures = 0,          -- Times kelp affs were cured recently
    ginsengCures = 0,       -- Times ginseng affs were cured recently
    bloodrootCures = 0,     -- Times bloodroot affs were cured recently
    focusCures = 0,         -- Times they used focus
    lastReset = 0,          -- When we last reset counters
    trackingWindow = 30,    -- Seconds to track cure patterns
}

-- Call this when target cures an affliction (from triggers)
function serpent.trackCure(herbType)
    local now = getEpoch()

    -- Reset counters if tracking window expired
    if now - serpent.cureTracking.lastReset > serpent.cureTracking.trackingWindow then
        serpent.cureTracking.kelpCures = 0
        serpent.cureTracking.ginsengCures = 0
        serpent.cureTracking.bloodrootCures = 0
        serpent.cureTracking.focusCures = 0
        serpent.cureTracking.lastReset = now
    end

    if herbType == "kelp" then
        serpent.cureTracking.kelpCures = serpent.cureTracking.kelpCures + 1
    elseif herbType == "ginseng" then
        serpent.cureTracking.ginsengCures = serpent.cureTracking.ginsengCures + 1
    elseif herbType == "bloodroot" then
        serpent.cureTracking.bloodrootCures = serpent.cureTracking.bloodrootCures + 1
    elseif herbType == "focus" then
        serpent.cureTracking.focusCures = serpent.cureTracking.focusCures + 1
    end
end

--[[
    Determine strategy adaptively based on:
    1. Current affliction state
    2. Lock progress
    3. Impulse readiness
    4. Fratricide state
    5. Darkshade stick time
    6. Target's cure patterns

    This is NOT mode-based - it dynamically picks the best action every attack.
]]--
function determineStrategy()
    local dominated = serpent.assessCombatState()

    -- The strategy is really about WHAT TO PRIORITIZE next
    -- Not a rigid "mode" but adaptive decision making

    -- ===========================================
    -- FINISHING MOVES - Lock is close, finish it
    -- ===========================================

    if truelock then
        serpStrategy = "finish"
        return
    end

    if hardlock and not tAffs.paralysis then
        -- One affliction from true lock - apply paralysis
        serpStrategy = "lock"
        return
    end

    -- ===========================================
    -- IMPULSE OPPORTUNITY - Can deliver mental NOW
    -- ===========================================

    if checkImpulseReady() then
        -- We have asthma + weariness + no fangbarrier
        -- This is our window to deliver impatience/anorexia

        if not tAffs.impatience then
            serpStrategy = "impulse"
            return
        end

        if tAffs.impatience and tAffs.slickness and not tAffs.anorexia then
            -- Have impatience and slickness, deliver anorexia for lock
            serpStrategy = "impulse"
            return
        end

        -- Fratricide active = impulse affs will RELAPSE
        -- This is extremely powerful - keep delivering mental pressure
        if serpent.hypnosis.fratricideActive or tAffs.fratricide then
            serpStrategy = "impulse"
            return
        end
    end

    -- ===========================================
    -- HYPNOSIS MANAGEMENT - Continue if in progress
    -- ===========================================

    if serpent.hypnosis.phase == "ready_snap" then
        serpStrategy = "hypnosis"
        return
    end

    if serpent.hypnosis.isActive() then
        serpStrategy = "hypnosis"
        return
    end

    -- ===========================================
    -- ADAPTIVE STRATEGY - React to target's cure patterns
    -- ===========================================

    local darkshadeStuckTime = 0
    if tAffs.darkshade and affTimers and affTimers.darkshade then
        darkshadeStuckTime = getEpoch() - affTimers.darkshade
    end

    local ginsengCount = countGinsengStack()
    local kelpCount = countKelpStack()

    --[[
        BIDIRECTIONAL ADAPTIVE LOGIC:
        - If they prioritize curing darkshade (ginseng) → push LOCK hard
        - If they prioritize curing lock affs (kelp) → push DARKSHADE to keep it stuck

        The idea: punish their curing priority by pushing the OTHER route.
    ]]--

    -- TARGET IS CURING GINSENG (darkshade) FAST → Push LOCK
    -- They're afraid of darkshade damage, so lock them down!
    if serpent.cureTracking.ginsengCures > serpent.cureTracking.kelpCures + 2 then
        -- They keep curing darkshade - hit them with lock pressure
        if serpent.config.debug then
            Algedonic.Echo("<cyan>ADAPTIVE: <white>Target prioritizing darkshade cure - pushing LOCK")
        end

        -- If we have some lock progress, maintain that route
        if kelpCount >= 1 or tAffs.slickness or tAffs.paralysis then
            serpStrategy = "lock"
            return
        end

        -- Setup for lock if we have nothing
        serpStrategy = "setup_impulse"
        return
    end

    -- TARGET IS CURING KELP (lock affs) FAST → Push DARKSHADE
    -- They're afraid of lock, so punish with DoT!
    if serpent.cureTracking.kelpCures > serpent.cureTracking.ginsengCures + 2 then
        if serpent.config.debug then
            Algedonic.Echo("<cyan>ADAPTIVE: <white>Target prioritizing lock cure - pushing DARKSHADE")
        end

        -- Keep darkshade stuck with higher priority ginseng affs
        if ginsengCount >= 1 or not tAffs.darkshade then
            serpStrategy = "darkshade"
            return
        end
    end

    -- DARKSHADE IS STICKING WELL - protect it and go for DoT kill
    if tAffs.darkshade and darkshadeStuckTime > 10 and ginsengCount >= 2 then
        serpStrategy = "darkshade"
        return
    end

    -- ===========================================
    -- EKANELIA OPPORTUNITY - Conditionals are met
    -- ===========================================

    checkEkaneliaOpportunities()

    -- High-value Ekanelia ready - use it
    if ekaneliaReady.kalmia then
        -- Gets asthma + slickness in one bite!
        serpStrategy = "ekanelia"
        return
    end

    if ekaneliaReady.monkshood then
        -- Gets impatience without needing impulse!
        serpStrategy = "ekanelia"
        return
    end

    if ekaneliaReady.loki then
        -- Predictable paralysis + nausea
        serpStrategy = "ekanelia"
        return
    end

    -- ===========================================
    -- SETUP PHASE - Build toward lock or impulse
    -- ===========================================

    -- Need to build kelp stack for impulse
    if not tAffs.asthma or not tAffs.weariness then
        serpStrategy = "setup_impulse"
        return
    end

    -- Have kelp stack but need to strip fangbarrier
    if (tAffs.sileris or tAffs.fangbarrier) and tAffs.asthma and tAffs.weariness then
        serpStrategy = "strip_fangbarrier"
        return
    end

    -- Softlock achieved but need more pressure
    if softlock then
        serpStrategy = "lock"
        return
    end

    -- Default: Build toward lock
    serpStrategy = "lock"
end

--[[
    Assess overall combat dominance
    Returns a score indicating how well we're doing
]]--
function serpent.assessCombatState()
    local dominated = 0

    -- Lock progress
    if truelock then dominated = dominated + 100 end
    if hardlock then dominated = dominated + 50 end
    if softlock then dominated = dominated + 25 end

    -- Impulse readiness
    if checkImpulseReady() then dominated = dominated + 30 end

    -- Key afflictions
    if tAffs.asthma then dominated = dominated + 10 end
    if tAffs.weariness then dominated = dominated + 10 end
    if tAffs.slickness then dominated = dominated + 15 end
    if tAffs.paralysis then dominated = dominated + 20 end
    if tAffs.impatience then dominated = dominated + 25 end
    if tAffs.anorexia then dominated = dominated + 20 end

    -- Fratricide pressure
    if tAffs.fratricide or serpent.hypnosis.fratricideActive then
        dominated = dominated + 20
    end

    -- Darkshade damage
    if tAffs.darkshade then
        local stuckTime = 0
        if affTimers and affTimers.darkshade then
            stuckTime = getEpoch() - affTimers.darkshade
        end
        dominated = dominated + math.min(stuckTime, 26)
    end

    return dominated
end

-- =============================================================================
-- UNIFIED ADAPTIVE VENOM SELECTION
-- =============================================================================

--[[
    Select venoms based on current strategy and combat state.
    This is a unified function that responds to determineStrategy() output.
]]--
function selectVenoms()
    envenomList = {}
    envenomListTwo = {}
    attackMode = "doublestab"

    -- Check Ekanelia first - if strategy says use it, do it
    -- BUT only if target doesn't have fangbarrier (blocks bite)
    if serpStrategy == "ekanelia" then
        checkEkaneliaOpportunities()

        -- Fangbarrier blocks bite - strip it first with gecko + curare
        if tAffs.fangbarrier or tAffs.sileris then
            Algedonic.Echo("<red>FANGBARRIER UP<white> - stripping with gecko + curare")
            table.insert(envenomList, "gecko")
            table.insert(envenomListTwo, "curare")
            return
        end

        if ekaneliaReady.kalmia then
            attackMode = "bite"
            table.insert(envenomList, "kalmia")
            Algedonic.Echo("<yellow>EKANELIA KALMIA<white> - asthma + slickness!")
            return
        elseif ekaneliaReady.monkshood then
            attackMode = "bite"
            table.insert(envenomList, "monkshood")
            Algedonic.Echo("<yellow>EKANELIA MONKSHOOD<white> - impatience!")
            return
        elseif ekaneliaReady.loki then
            attackMode = "bite"
            table.insert(envenomList, "loki")
            Algedonic.Echo("<yellow>EKANELIA LOKI<white> - nausea + paralysis!")
            return
        elseif ekaneliaReady.curare then
            attackMode = "bite"
            table.insert(envenomList, "curare")
            Algedonic.Echo("<yellow>EKANELIA CURARE<white> - paralysis + hypochondria!")
            return
        elseif ekaneliaReady.scytherus then
            attackMode = "bite"
            table.insert(envenomList, "scytherus")
            Algedonic.Echo("<magenta>EKANELIA SCYTHERUS<white> - camus damage!")
            return
        end
    end

    -- ===========================================
    -- FINISH - True lock achieved, apply voyria or class-specific
    -- ===========================================
    if serpStrategy == "finish" then
        local lockAff = getLockingAffliction(target)
        if lockAff == "weariness" and not tAffs.weariness then
            table.insert(envenomList, "vernalius")
        elseif lockAff == "paralyse" and not tAffs.paralysis then
            table.insert(envenomList, "curare")
        elseif lockAff == "plague" and not tAffs.voyria then
            table.insert(envenomList, "voyria")
        else
            table.insert(envenomList, "voyria")
        end
        buildSecondVenom()
        return
    end

    -- ===========================================
    -- IMPULSE - Impulse is ready, we're delivering mental
    -- Venoms should support the lock while we impulse
    -- ===========================================
    if serpStrategy == "impulse" then
        -- We'll deliver mental via impulse command
        -- Venoms should complete the physical lock
        if not tAffs.slickness then
            table.insert(envenomList, "gecko")
        elseif not tAffs.paralysis then
            table.insert(envenomList, "curare")
        elseif not tAffs.anorexia then
            table.insert(envenomList, "slike")
        else
            -- Lock is solid, add pressure
            table.insert(envenomList, "darkshade")
        end
        buildSecondVenom()
        return
    end

    -- ===========================================
    -- STRIP FANGBARRIER - Need to flay for impulse access
    -- ===========================================
    if serpStrategy == "strip_fangbarrier" then
        -- Attack function will handle the flay
        -- Still select venoms for the flay venom
        if not tAffs.paralysis then
            table.insert(envenomList, "curare")
        elseif not tAffs.slickness then
            table.insert(envenomList, "gecko")
        else
            table.insert(envenomList, "darkshade")
        end
        buildSecondVenom()
        return
    end

    -- ===========================================
    -- SETUP IMPULSE - Build kelp stack (asthma + weariness)
    -- ===========================================
    if serpStrategy == "setup_impulse" then
        -- Priority: Get asthma + weariness for impulse
        -- Also set up Ekanelia kalmia conditionals (clumsiness + weariness)

        if not tAffs.clumsiness and not tAffs.weariness then
            -- Set up both Ekanelia conditionals
            table.insert(envenomList, "xentio")
            table.insert(envenomListTwo, "vernalius")
            return
        elseif not tAffs.weariness then
            table.insert(envenomList, "vernalius")
        elseif not tAffs.asthma then
            table.insert(envenomList, "kalmia")
        elseif not tAffs.clumsiness then
            table.insert(envenomList, "xentio")
        else
            -- Have kelp setup, add bloodroot pressure
            if not tAffs.slickness then
                table.insert(envenomList, "gecko")
            else
                table.insert(envenomList, "curare")
            end
        end
        buildSecondVenom()
        return
    end

    -- ===========================================
    -- HYPNOSIS - Continue hypnosis process
    -- ===========================================
    if serpStrategy == "hypnosis" then
        -- Maintain pressure while hypnosis completes
        if not tAffs.slickness then
            table.insert(envenomList, "gecko")
        elseif not tAffs.paralysis then
            table.insert(envenomList, "curare")
        elseif not tAffs.asthma then
            table.insert(envenomList, "kalmia")
        elseif not tAffs.weariness then
            table.insert(envenomList, "vernalius")
        else
            table.insert(envenomList, "darkshade")
        end
        buildSecondVenom()
        return
    end

    -- ===========================================
    -- DARKSHADE - Protect darkshade with ginseng stack
    -- ===========================================
    if serpStrategy == "darkshade" then
        -- Check for scytherus Ekanelia
        checkEkaneliaOpportunities()
        -- Only use bite if no fangbarrier
        if ekaneliaReady.scytherus and not tAffs.fangbarrier and not tAffs.sileris then
            attackMode = "bite"
            table.insert(envenomList, "scytherus")
            Algedonic.Echo("<magenta>EKANELIA SCYTHERUS<white> - camus damage!")
            return
        end

        -- Build ginseng stack while maintaining some lock pressure
        if not tAffs.darkshade then
            table.insert(envenomList, "darkshade")
        elseif not tAffs.asthma then
            table.insert(envenomList, "kalmia")
        elseif not tAffs.addiction then
            table.insert(envenomList, "vardrax")
        elseif not tAffs.nausea then
            table.insert(envenomList, "euphorbia")
        elseif not tAffs.scytherus then
            table.insert(envenomList, "scytherus")
        elseif not tAffs.paralysis then
            table.insert(envenomList, "curare")
        elseif not tAffs.slickness then
            table.insert(envenomList, "gecko")
        elseif not tAffs.haemophilia then
            table.insert(envenomList, "notechis")
        else
            table.insert(envenomList, "aconite")
        end
        buildSecondVenom()
        return
    end

    -- ===========================================
    -- LOCK (Default) - Standard lock progression
    -- ===========================================

    -- Check for valuable Ekanelia opportunities (only if no fangbarrier)
    checkEkaneliaOpportunities()
    if not tAffs.fangbarrier and not tAffs.sileris then
        if ekaneliaReady.kalmia then
            attackMode = "bite"
            table.insert(envenomList, "kalmia")
            Algedonic.Echo("<yellow>EKANELIA KALMIA<white> - asthma + slickness!")
            return
        elseif ekaneliaReady.monkshood then
            attackMode = "bite"
            table.insert(envenomList, "monkshood")
            Algedonic.Echo("<yellow>EKANELIA MONKSHOOD<white> - impatience!")
            return
        elseif ekaneliaReady.loki then
            attackMode = "bite"
            table.insert(envenomList, "loki")
            Algedonic.Echo("<yellow>EKANELIA LOKI<white> - nausea + paralysis!")
            return
        end
    end

    -- Standard lock progression
    if hardlock and not tAffs.paralysis then
        table.insert(envenomList, "curare")
    elseif softlock and not tAffs.paralysis then
        table.insert(envenomList, "curare")
    -- Build toward softlock
    elseif not tAffs.clumsiness then
        table.insert(envenomList, "xentio")
    elseif not tAffs.weariness then
        table.insert(envenomList, "vernalius")
    elseif not tAffs.asthma then
        table.insert(envenomList, "kalmia")
    elseif not tAffs.slickness then
        table.insert(envenomList, "gecko")
    elseif not tAffs.paralysis then
        table.insert(envenomList, "curare")
    -- Add ginseng pressure
    elseif not tAffs.darkshade then
        table.insert(envenomList, "darkshade")
    elseif not tAffs.addiction then
        table.insert(envenomList, "vardrax")
    elseif not tAffs.nausea then
        table.insert(envenomList, "euphorbia")
    else
        table.insert(envenomList, "aconite")
    end

    buildSecondVenom()
end

-- =============================================================================
-- SECOND VENOM BUILDER
-- =============================================================================

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

-- =============================================================================
-- ATTACK EXECUTION
-- =============================================================================

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
        serp_sendAttack(atk)
        return
    elseif tAffs.rebounding then
        atk = atk .. "wield left dirk;wield right lash;purge;order adder kill " .. target .. ";flay " .. target .. " rebounding " .. (envenomListTwo[1] or "curare")
        serp_sendAttack(atk)
        return
    elseif tAffs.shield then
        atk = atk .. "wield left dirk;wield right lash;purge;order adder kill " .. target .. ";flay " .. target .. " shield " .. (envenomListTwo[1] or "curare")
        serp_sendAttack(atk)
        return
    end

    -- Flay sileris/fangbarrier for Impulse setup
    -- If we have kelp stack ready but target has fangbarrier, strip it!
    if (tAffs.sileris or tAffs.fangbarrier) and tAffs.asthma and tAffs.weariness then
        atk = atk .. "wield left dirk;wield right lash;purge;order adder kill " .. target .. ";flay " .. target .. " sileris " .. (envenomListTwo[1] or "curare")
        Algedonic.Echo("<yellow>FLAY SILERIS<white> - enabling Impulse!")
        serp_sendAttack(atk)
        return
    end

    -- Build hypnosis command if in hypnosis mode
    local hypnoCmd = ""
    if serpStrategy == "hypnosis" and serpent.hypnosis then
        local cmd = serpent.hypnosis.getCommand()
        if cmd then
            hypnoCmd = cmd .. ";"
        end
    end

    -- Check for Impulse opportunity (delivers impatience/anorexia)
    local impulseCmd = ""
    if checkImpulseReady() then
        -- Priority: impatience > anorexia > confusion > amnesia
        if not tAffs.impatience then
            impulseCmd = "impulse " .. target .. " suggest impatience;"
        elseif not tAffs.anorexia and tAffs.slickness then
            -- Only deliver anorexia if slickness is on (blocks salve cure)
            impulseCmd = "impulse " .. target .. " suggest anorexia;"
        elseif not tAffs.confusion then
            impulseCmd = "impulse " .. target .. " suggest confusion;"
        elseif not tAffs.amnesia then
            impulseCmd = "impulse " .. target .. " suggest amnesia;"
        end
    end

    -- Build attack based on mode
    local weaponSetup = "wield left dirk;wield right shield;purge;order adder kill " .. target .. ";"

    -- Safety check: Never bite if fangbarrier is up
    if attackMode == "bite" and (tAffs.fangbarrier or tAffs.sileris) then
        Algedonic.Echo("<red>SAFETY:<white> Fangbarrier blocks bite - switching to doublestab")
        attackMode = "doublestab"
        -- Use gecko + curare to strip fangbarrier
        envenomList[1] = "gecko"
        envenomListTwo[1] = "curare"
    end

    if attackMode == "bite" then
        atk = atk .. weaponSetup .. hypnoCmd .. impulseCmd .. "bite " .. target .. " " .. envenomList[1]
    else
        atk = atk .. weaponSetup .. hypnoCmd .. impulseCmd .. "doublestab " .. target .. " " .. envenomList[1] .. " " .. envenomListTwo[1]
    end

    serp_sendAttack(atk)
end

--[[
    Send the attack if target is present
]]--
function serp_sendAttack(atk)
    if table.contains(ataxia.playersHere, target) then
        send("queue addclear freestand " .. atk)
    else
        Algedonic.Echo("<red>Target not in room!<white>")
    end
end

-- =============================================================================
-- MAIN OFFENSE FUNCTION
-- =============================================================================

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
    elseif serpOffenseMode == "hypnosis" then
        serpStrategy = "hypnosis"
    end

    -- Echo strategy if configured
    if serpent.config.echoStrategy then
        Algedonic.Echo("<dim_grey>Strategy: <white>" .. serpStrategy)
    end

    -- Echo current target afflictions for debugging
    if serpent.config.echoAffs then
        local affStr = ""
        if tAffs.asthma then affStr = affStr .. "<cyan>AST " end
        if tAffs.weariness then affStr = affStr .. "<cyan>WEA " end
        if tAffs.clumsiness then affStr = affStr .. "<cyan>CLU " end
        if tAffs.slickness then affStr = affStr .. "<yellow>SLI " end
        if tAffs.paralysis then affStr = affStr .. "<yellow>PAR " end
        if tAffs.impatience then affStr = affStr .. "<red>IMP " end
        if tAffs.anorexia then affStr = affStr .. "<red>ANO " end
        if tAffs.fangbarrier then affStr = affStr .. "<magenta>FNG " end
        if tAffs.sileris then affStr = affStr .. "<magenta>SIL " end
        if tAffs.darkshade then affStr = affStr .. "<green>DRK " end
        if tAffs.addiction then affStr = affStr .. "<green>ADD " end
        if tAffs.nausea then affStr = affStr .. "<green>NAU " end
        if affStr == "" then affStr = "<dim_grey>none" end
        cecho("<white>[tAffs]: " .. affStr .. "<reset>\n")
    end

    -- Build venom lists using unified adaptive venom selection
    selectVenoms()

    -- Execute attack
    serp_ekanelia_attack()
end

-- =============================================================================
-- MODE SWITCHING FUNCTIONS
-- =============================================================================

function serp_setmode_lock()
    serpOffenseMode = "lock"
    cecho("\n<green>Serpent offense: LOCK mode<reset>\n")
    cecho("<dim_grey>  Priority: Impulse lock via kelp stack + bloodroot competition<reset>\n")
end

function serp_setmode_darkshade()
    serpOffenseMode = "darkshade"
    cecho("\n<magenta>Serpent offense: DARKSHADE mode<reset>\n")
    cecho("<dim_grey>  Priority: Stack ginseng afflictions, keep darkshade 26+ seconds<reset>\n")
end

function serp_setmode_hypnosis()
    serpOffenseMode = "hypnosis"
    -- Reset hypnosis state when entering hypnosis mode
    if serpent.hypnosis and serpent.hypnosis.reset then
        serpent.hypnosis.reset()
    end
    cecho("\n<cyan>Serpent offense: HYPNOSIS COMBO mode<reset>\n")
    cecho("<dim_grey>  Priority: Fratricide -> mental affs RELAPSE after cure!<reset>\n")
end

function serp_setmode_auto()
    serpOffenseMode = "auto"
    cecho("\n<yellow>Serpent offense: AUTO mode<reset>\n")
    cecho("<dim_grey>  Auto-switches between lock, darkshade, and hypnosis<reset>\n")
end

-- =============================================================================
-- STATUS DISPLAY
-- =============================================================================

--[[
    Status display function
]]--
function serp_status()
    local darkshadeTime = 0
    if tAffs.darkshade and affTimers.darkshade then
        darkshadeTime = getEpoch() - affTimers.darkshade
    end

    local ginsengCount = countGinsengStack()

    cecho("\n<cyan>===== Serpent Offense Status =====<reset>\n")
    cecho("<white>Mode: <yellow>" .. serpOffenseMode .. "<reset>\n")
    cecho("<white>Strategy: <yellow>" .. serpStrategy .. "<reset>\n")

    -- Lock status
    checkTargetLocks()
    local lockStr = "<white>Lock Status: "
    if truelock then lockStr = lockStr .. "<red>TRUE LOCK"
    elseif hardlock then lockStr = lockStr .. "<orange>HARD LOCK"
    elseif softlock then lockStr = lockStr .. "<yellow>SOFT LOCK"
    else lockStr = lockStr .. "<dim_grey>None" end
    cecho(lockStr .. "<reset>\n")

    -- Fangbarrier status (blocks bite)
    cecho("<white>Fangbarrier: " .. ((tAffs.fangbarrier or tAffs.sileris) and "<red>UP (blocks bite)" or "<green>DOWN") .. "<reset>\n")

    -- Impulse status
    cecho("<white>Impulse Ready: " .. (checkImpulseReady() and "<green>YES" or "<red>NO"))
    if not checkImpulseReady() then
        local missing = {}
        if not tAffs.asthma then table.insert(missing, "asthma") end
        if not tAffs.weariness then table.insert(missing, "weariness") end
        if tAffs.sileris or tAffs.fangbarrier then table.insert(missing, "flay sileris") end
        if #missing > 0 then
            cecho(" <dim_grey>(need: " .. table.concat(missing, ", ") .. ")")
        end
    end
    cecho("<reset>\n")

    -- Hypnosis status
    if serpent.hypnosis then
        cecho("<white>Hypnosis Phase: <yellow>" .. serpent.hypnosis.phase .. "<reset>\n")
        cecho("<white>Fratricide: ")
        if serpent.hypnosis.fratricideActive or tAffs.fratricide then
            cecho("<green>ACTIVE<reset>\n")
        elseif serpent.hypnosis.fratricideApplied then
            cecho("<yellow>QUEUED<reset>\n")
        else
            cecho("<dim_grey>No<reset>\n")
        end

        local timeToSnap = serpent.hypnosis.getTimeToSnap()
        if timeToSnap == 0 then
            cecho("<white>Snap: <green>READY!<reset>\n")
        elseif timeToSnap > 0 then
            cecho("<white>Snap In: <yellow>" .. string.format("%.1f", timeToSnap) .. "s<reset>\n")
        end
    end

    -- Darkshade tracking
    cecho("<white>Darkshade: " .. (tAffs.darkshade and ("<green>YES<white> (" .. math.floor(darkshadeTime) .. "s/" .. DARKSHADE_KILL_TIME .. "s)") or "<red>NO") .. "<reset>\n")
    cecho("<white>Ginseng Stack: <yellow>" .. ginsengCount .. "/6<reset>\n")
    cecho("<white>Kelp Stack: <yellow>" .. countKelpStack() .. "/7<reset>\n")
    cecho("<white>Bloodroot Stack: <yellow>" .. countBloodrootStack() .. "/2<reset>\n")

    -- Ekanelia opportunities
    checkEkaneliaOpportunities()
    if next(ekaneliaReady) then
        cecho("<white>Ekanelia Ready: ")
        for k, v in pairs(ekaneliaReady) do
            if v then cecho("<yellow>" .. k .. " ") end
        end
        cecho("<reset>\n")
    else
        cecho("<white>Ekanelia Ready: <dim_grey>None<reset>\n")
    end

    -- Cure tracking (adaptive system)
    cecho("<white>------- Adaptive Tracking --------<reset>\n")
    cecho("<white>Kelp Cures: <yellow>" .. serpent.cureTracking.kelpCures .. "<reset>")
    cecho("  <white>Ginseng Cures: <yellow>" .. serpent.cureTracking.ginsengCures .. "<reset>\n")
    cecho("<white>Bloodroot Cures: <yellow>" .. serpent.cureTracking.bloodrootCures .. "<reset>")
    cecho("  <white>Focus: <yellow>" .. serpent.cureTracking.focusCures .. "<reset>\n")

    -- Show what the adaptive system would recommend
    if serpent.cureTracking.ginsengCures > serpent.cureTracking.kelpCures + 2 then
        cecho("<green>ADAPTIVE: <white>Target fears darkshade → pushing LOCK<reset>\n")
    elseif serpent.cureTracking.kelpCures > serpent.cureTracking.ginsengCures + 2 then
        cecho("<magenta>ADAPTIVE: <white>Target fears lock → pushing DARKSHADE<reset>\n")
    else
        cecho("<dim_grey>ADAPTIVE: <white>Balanced curing - standard progression<reset>\n")
    end

    cecho("<cyan>==================================<reset>\n")
end

-- =============================================================================
-- EVENT HANDLERS
-- =============================================================================

-- Reset cure tracking
function serpent.resetCureTracking()
    serpent.cureTracking.kelpCures = 0
    serpent.cureTracking.ginsengCures = 0
    serpent.cureTracking.bloodrootCures = 0
    serpent.cureTracking.focusCures = 0
    serpent.cureTracking.lastReset = getEpoch()
end

-- Register event handlers for target change
if registerAnonymousEventHandler then
    registerAnonymousEventHandler("tar changed", function()
        -- Reset hypnosis state
        if serpent.hypnosis and serpent.hypnosis.reset then
            serpent.hypnosis.reset()
        end
        -- Reset cure tracking for new target
        serpent.resetCureTracking()
    end)
end

-- =============================================================================
-- ALIAS REGISTRATION
-- =============================================================================

-- Kill existing serpent aliases to avoid duplicates
if serpent.aliases then
    for _, aliasId in pairs(serpent.aliases) do
        if killAlias then killAlias(aliasId) end
    end
end
serpent.aliases = {}

-- Register aliases programmatically (no separate alias files needed)
if tempAlias then
    serpent.aliases.ek = tempAlias("^ek$", [[serp_ekanelia_offense()]])
    serpent.aliases.eklock = tempAlias("^eklock$", [[serp_setmode_lock()]])
    serpent.aliases.ekdark = tempAlias("^ekdark$", [[serp_setmode_darkshade()]])
    serpent.aliases.ekhyp = tempAlias("^ekhyp$", [[serp_setmode_hypnosis()]])
    serpent.aliases.ekauto = tempAlias("^ekauto$", [[serp_setmode_auto()]])
    serpent.aliases.ekstatus = tempAlias("^ekstatus$", [[serp_status()]])
    serpent.aliases.ekhypstatus = tempAlias("^ekhypstatus$", [[serpent.hypnosis.status()]])
end

-- =============================================================================
-- TRIGGER REGISTRATION
-- =============================================================================

-- Kill existing serpent triggers to avoid duplicates
if serpent.triggers then
    for _, triggerId in pairs(serpent.triggers) do
        if killTrigger then killTrigger(triggerId) end
    end
end
serpent.triggers = {}

-- Register triggers programmatically (no separate trigger files needed)
if tempRegexTrigger then
    -- Hypnosis Starting
    serpent.triggers.hypnosisStart = tempRegexTrigger(
        "^You prepare yourself to hypnotise your victim, (\\w+)\\.$",
        [[
            tAffs.hypnotising = true
            tAffs.hypnoseal = false
            ataxiaTemp.hypnoseal = false
            if serpent and serpent.hypnosis and serpent.hypnosis.start then
                serpent.hypnosis.start(matches[2])
            end
        ]]
    )

    -- Hypnotised Success
    serpent.triggers.hypnotised = tempRegexTrigger(
        "You fix (\\w+) with an entrancing stare, and smile in satisfaction as you realise that \\w+ mind is yours\\.",
        [[
            tAffs.hypnotising = nil
            tAffs.hypnotised = true
            tAffs.hypnoseal = false
            ataxiaTemp.hypnoseal = false
            if serpent and serpent.hypnosis and serpent.hypnosis.onHypnotised then
                serpent.hypnosis.onHypnotised()
            end
        ]]
    )

    -- Snapped
    serpent.triggers.snapped = tempRegexTrigger(
        "^You snap your fingers in front of (\\w+)\\.$",
        [[
            tAffs.hypnotising = false
            tAffs.hypnotised = false
            tAffs.snapped = true
            tAffs.hypnoseal = false
            ataxiaTemp.hypnoseal = false
            serpentsuggest = false
            tempTimer(3, function() tAffs.snapped = false; ataxiaTemp.suggestions = nil end)
            snapTarget = false
            if serpent and serpent.hypnosis and serpent.hypnosis.onSnapped then
                serpent.hypnosis.onSnapped()
            end
        ]]
    )

    -- Suggest Given
    serpent.triggers.suggestGiven = tempRegexTrigger(
        "^You issue the suggestion, concealing it deep within (\\w+)'s mind\\.$",
        [[
            serpentsuggest = true
            if serpent and serpent.hypnosis and serpent.hypnosis.onSuggested then
                local suggestion = ataxiaTemp.suggestAff or "unknown"
                serpent.hypnosis.onSuggested(suggestion)
            end
        ]]
    )

    -- Suggest Already Present
    serpent.triggers.suggestAlready = tempRegexTrigger(
        "^(\\w+)'s mind is already holding something quite similar to that suggestion\\.$",
        [[
            serpentsuggest = true
        ]]
    )

    -- Fratricide Cured
    serpent.triggers.fratricideCured = tempRegexTrigger(
        "The look of madness fades from (\\w+)'s eyes",
        [[
            if erAff then erAff("fratricide") end
            tAffs.fratricide = false
            if serpent and serpent.hypnosis and serpent.hypnosis.onFratricideCured then
                serpent.hypnosis.onFratricideCured()
            end
        ]]
    )
end

-- =============================================================================
-- INITIALIZATION MESSAGE
-- =============================================================================

Algedonic.Echo("<cyan>Serpent Offense System<white> loaded.")
Algedonic.Echo("<dim_grey>  Commands: ek, eklock, ekhyp, ekdark, ekauto, ekstatus, ekhypstatus<reset>")
