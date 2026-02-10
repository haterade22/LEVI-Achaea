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
    SERPENT OFFENSE SYSTEM (Overhaul)
    ============================================================================

    DSTAB-primary offense with conditional IMPULSE for Ekanelia triggers.

    ATTACK MODES:
    - DSTAB (primary): 2 venoms per round, BAL only. Always works.
    - IMPULSE (conditional): suggestion + bite + Ekanelia (BAL+EQ).
      Only when: no sileris/fangbarrier AND Ekanelia achievable AND eq free.
    - FLAY: strip defense + venom, BAL only.
    - EXECUTE: truelock finish.

    EKANELIA TRANSFORMATIONS (BITE/IMPULSE only):
    - kalmia:    clumsiness + weariness           → slickness
    - aconite:   deadening + dementia              → paranoia
    - monkshood: asthma + masochism + weariness    → impatience
    - curare:    hypersomnia + masochism            → hypochondria
    - voyria:    anorexia + impatience + vertigo    → confusion + disrupted
    - loki:      confusion + recklessness           → nausea + paralysis
    - scytherus: addiction + nausea                 → camus

    SELECTION LOGIC (Lock-First):
    0. Strip rebounding/shield (flay)
    1. Can complete truelock? → deliver missing piece
    2. Can complete hardlock? → deliver missing piece
    3. Can complete softlock? → deliver missing piece
    4. Ekanelia conditionals all met? → free Ekanelia via impulse
    5. One trivial conditional missing? → impulse completes it
    6. Need DSTAB setup? → dstab venoms that set up Ekanelia
    Fallback: general affliction pressure

    ALIASES:
    - ek        : Main attack
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

serpent = serpent or {}
serpent.config = serpent.config or {}
serpent.hypnosis = serpent.hypnosis or {}
serpent.state = serpent.state or {}

-- Combat state
serpOffenseMode = serpOffenseMode or "auto"
serpStrategy = serpStrategy or "lock"
attackMode = attackMode or "dstab"
ekaneliaReady = ekaneliaReady or {}
impulseReady = false
affTimers = affTimers or {}

-- Attack state tracking
serpent.state.attackInFlight = serpent.state.attackInFlight or false
serpent.state.dispelSent = serpent.state.dispelSent or false

-- Suggestion queueing (keybind-driven)
hSuggRequest = hSuggRequest or ""
hSuggActive = hSuggActive or ""

-- Configuration
serpent.config = {
    debug = false,
    echoStrategy = true,
    echoAffs = true,
    autoFratricide = true,
}

-- Constants
DARKSHADE_KILL_TIME = 26
DARKSHADE_SWITCH_TIME = 15
SNAP_DELAY = 4
COOLDOWN_TIME = 4

-- Trivial suggestions (deliverable via IMPULSE)
local TRIVIAL_SUGGESTIONS = {
    "amnesia", "paranoia", "loneliness", "claustrophobia", "stuttering",
    "hallucinations", "dementia", "deadening", "epilepsy", "agoraphobia",
    "masochism", "recklessness", "vertigo", "confusion", "stupidity"
}

-- Venom → affliction mapping
local VENOM_TO_AFF = {
    kalmia = "asthma", vernalius = "weariness", xentio = "clumsiness",
    curare = "paralysis", gecko = "slickness", slike = "anorexia",
    euphorbia = "nausea", vardrax = "addiction", eurypteria = "recklessness",
    aconite = "stupidity", monkshood = "disfigurement", scytherus = "scytherus",
    darkshade = "darkshade", voyria = "voyria", notechis = "haemophilia",
    loki = "random",
}

-- Affliction → venom mapping (for lock completion)
local AFF_TO_VENOM = {
    asthma = "kalmia", weariness = "vernalius", clumsiness = "xentio",
    paralysis = "curare", slickness = "gecko", anorexia = "slike",
    nausea = "euphorbia", addiction = "vardrax", recklessness = "eurypteria",
    stupidity = "aconite", darkshade = "darkshade",
}

-- =============================================================================
-- HYPNOSIS STATE MACHINE
-- =============================================================================

serpent.hypnosis = {
    phase = "idle",
    suggestions = {},
    fratricideApplied = false,
    fratricideActive = false,
    snapTimer = nil,
    snapReadyTime = nil,
    hypnoTarget = nil,
}

function serpent.hypnosis.start(tar)
    serpent.hypnosis.phase = "hypnotising"
    serpent.hypnosis.suggestions = {}
    serpent.hypnosis.fratricideApplied = false
    serpent.hypnosis.hypnoTarget = tar or target

    if serpent.config.debug then
        Algedonic.Echo("<cyan>HYPNOSIS: <white>Starting hypnotise on " .. (tar or target))
    end
end

function serpent.hypnosis.onHypnotised()
    serpent.hypnosis.phase = "hypnotised"
    tAffs.hypnotised = true
    tAffs.hypnotising = false

    serpent.hypnosis.snapReadyTime = getEpoch() + SNAP_DELAY
    Algedonic.Echo("<green>HYPNOSIS: <white>Target hypnotised! Snap ready in " .. SNAP_DELAY .. "s")

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

function serpent.hypnosis.onSuggested(suggestion)
    serpent.hypnosis.phase = "suggesting"

    if suggestion and suggestion:lower():find("fratricide") then
        serpent.hypnosis.fratricideApplied = true
        Algedonic.Echo("<magenta>HYPNOSIS: <white>Fratricide queued - mental affs will RELAPSE!")
    end

    table.insert(serpent.hypnosis.suggestions, suggestion)

    if serpent.config.debug then
        Algedonic.Echo("<cyan>HYPNOSIS: <white>Suggested " .. (suggestion or "unknown"))
    end
end

function serpent.hypnosis.onSnapped()
    serpent.hypnosis.phase = "cooldown"
    tAffs.snapped = true
    tAffs.hypnotised = false

    if serpent.hypnosis.fratricideApplied then
        serpent.hypnosis.fratricideActive = true
        tAffs.fratricide = true
        Algedonic.Echo("<red>HYPNOSIS: <white>SNAP! Fratricide ACTIVE - Impulse affs will relapse!")
    else
        Algedonic.Echo("<yellow>HYPNOSIS: <white>SNAP triggered!")
    end

    if serpent.hypnosis.snapTimer then
        killTimer(serpent.hypnosis.snapTimer)
        serpent.hypnosis.snapTimer = nil
    end

    tempTimer(COOLDOWN_TIME, function()
        serpent.hypnosis.phase = "idle"
    end)
end

function serpent.hypnosis.onFratricideCured()
    serpent.hypnosis.fratricideActive = false
    tAffs.fratricide = false
    Algedonic.Echo("<dim_grey>HYPNOSIS: <white>Target cured fratricide")
end

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

function serpent.hypnosis.getCommand()
    local tar = target or serpent.hypnosis.hypnoTarget

    if serpent.hypnosis.phase == "idle" then
        return "hypnotise " .. tar
    end

    if (serpent.hypnosis.phase == "hypnotised" or serpent.hypnosis.phase == "suggesting")
       and not serpent.hypnosis.fratricideApplied then
        return "suggest " .. tar .. " fratricide"
    end

    if serpent.hypnosis.phase == "ready_snap" then
        return "snap " .. tar
    end

    return nil
end

function serpent.hypnosis.canSnap()
    return serpent.hypnosis.phase == "ready_snap"
end

function serpent.hypnosis.isActive()
    return serpent.hypnosis.phase ~= "idle" and serpent.hypnosis.phase ~= "cooldown"
end

function serpent.hypnosis.hasFratricide()
    return serpent.hypnosis.fratricideActive or tAffs.fratricide
end

function serpent.hypnosis.getTimeToSnap()
    if serpent.hypnosis.phase == "ready_snap" then
        return 0
    end
    if serpent.hypnosis.snapReadyTime then
        local remaining = serpent.hypnosis.snapReadyTime - getEpoch()
        return remaining > 0 and remaining or 0
    end
    return -1
end

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
-- EKANELIA DETECTION & IMPULSE PAIR SELECTION
-- =============================================================================

--[[
    Ekanelia transformation table.
    Each entry: trigger venom, conditional afflictions, result afflictions,
    and which conditionals are trivial suggestions (impulse-deliverable).
]]--
local EKANELIA_TABLE = {
    {
        trigger = "monkshood",
        conditionals = {"asthma", "masochism", "weariness"},
        trivials = {"masochism"},
        result = "impatience",
        priority = 1, -- truelock piece
    },
    {
        trigger = "kalmia",
        conditionals = {"clumsiness", "weariness"},
        trivials = {},
        result = "slickness",
        priority = 2, -- softlock piece
    },
    {
        trigger = "loki",
        conditionals = {"confusion", "recklessness"},
        trivials = {"confusion", "recklessness"},
        result = "nausea + paralysis",
        priority = 3, -- double aff, paralysis blocks tree
    },
    {
        trigger = "curare",
        conditionals = {"hypersomnia", "masochism"},
        trivials = {"masochism"},
        result = "hypochondria",
        priority = 4, -- kelp stack pressure
    },
    {
        trigger = "scytherus",
        conditionals = {"addiction", "nausea"},
        trivials = {},
        result = "camus",
        priority = 5, -- damage pressure
    },
    {
        trigger = "aconite",
        conditionals = {"deadening", "dementia"},
        trivials = {"deadening", "dementia"},
        result = "paranoia",
        priority = 6, -- mental stack
    },
    {
        trigger = "voyria",
        conditionals = {"anorexia", "impatience", "vertigo"},
        trivials = {"vertigo"},
        result = "confusion + disrupted",
        priority = 7, -- needs monkshood chain first
    },
}

--[[
    Check for Ekanelia opportunities.
    Populates ekaneliaReady table with triggers that have ALL conditionals met.
]]--
function checkEkaneliaOpportunities()
    ekaneliaReady = {}

    for _, ek in ipairs(EKANELIA_TABLE) do
        local allMet = true
        for _, cond in ipairs(ek.conditionals) do
            if not haveAff(cond) then
                allMet = false
                break
            end
        end
        if allMet then
            ekaneliaReady[ek.trigger] = true
        end
    end
end

--[[
    Select the best impulse suggestion + venom pair for Ekanelia.
    Returns {suggestion=X, venom=Y} or nil if no Ekanelia achievable.

    Logic:
    1. If ALL conditionals met → return {suggestion=<useful>, venom=<trigger>}
    2. If exactly ONE trivial conditional missing → return {suggestion=<missing>, venom=<trigger>}
    3. Otherwise → nil
]]--
function selectImpulsePair()
    for _, ek in ipairs(EKANELIA_TABLE) do
        local missing = {}
        local missingTrivials = {}

        for _, cond in ipairs(ek.conditionals) do
            if not haveAff(cond) then
                table.insert(missing, cond)
                -- Check if this missing conditional is a trivial suggestion
                for _, t in ipairs(ek.trivials) do
                    if t == cond then
                        table.insert(missingTrivials, cond)
                        break
                    end
                end
            end
        end

        if #missing == 0 then
            -- ALL conditionals met → free Ekanelia
            -- Pick a useful suggestion (not a conditional we already have)
            local suggestion = selectFallbackSuggestion()
            return {suggestion = suggestion, venom = ek.trigger, label = ek.result}
        elseif #missing == 1 and #missingTrivials == 1 then
            -- Exactly one trivial conditional missing → impulse completes it
            return {suggestion = missingTrivials[1], venom = ek.trigger, label = ek.result}
        end
    end

    return nil
end

--[[
    Select a useful fallback suggestion when Ekanelia is free (all conditions met).
    Prioritize suggestions that advance the lock or add pressure.
]]--
function selectFallbackSuggestion()
    -- Priority: suggestions that help the lock
    local priorities = {"stupidity", "epilepsy", "confusion", "recklessness", "amnesia", "masochism", "vertigo"}
    for _, sug in ipairs(priorities) do
        if not haveAff(sug) then
            return sug
        end
    end
    return "stupidity"
end

-- =============================================================================
-- IMPULSE ELIGIBILITY
-- =============================================================================

--[[
    Check if impulse can be used this round.
    Requires: no sileris/fangbarrier on target (bite must land).
    Does NOT check eq availability or Ekanelia — those are checked separately.
]]--
function checkImpulseEligible()
    -- V1 fallback is safe here: stale TRUE just means we use dstab instead (no harm)
    -- haveAff() alone misses fangbarrier when "quicksilver" trigger doesn't fire
    local hasSileris = haveAff("sileris") or (tAffs and tAffs.sileris)
    local hasFangbarrier = haveAff("fangbarrier") or (tAffs and tAffs.fangbarrier)
    impulseReady = not hasSileris and not hasFangbarrier
    return impulseReady
end

-- =============================================================================
-- DARKSHADE TRACKING
-- =============================================================================

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

function countGinsengStack()
    local count = 0
    local ginsengAffs = {"addiction", "darkshade", "haemophilia", "lethargy", "scytherus", "nausea"}
    for _, aff in ipairs(ginsengAffs) do
        if tAffs[aff] then count = count + 1 end
    end
    return count
end

function countKelpStack()
    local count = 0
    local kelpAffs = {"asthma", "clumsiness", "hypochondria", "sensitivity", "weariness", "healthleech", "parasite"}
    for _, aff in ipairs(kelpAffs) do
        if tAffs[aff] then count = count + 1 end
    end
    return count
end

function countBloodrootStack()
    local count = 0
    if tAffs.paralysis then count = count + 1 end
    if tAffs.slickness then count = count + 1 end
    return count
end

-- =============================================================================
-- ADAPTIVE STRATEGY SYSTEM (Lock-First)
-- =============================================================================

serpent.cureTracking = serpent.cureTracking or {
    kelpCures = 0,
    ginsengCures = 0,
    bloodrootCures = 0,
    focusCures = 0,
    lastReset = 0,
    trackingWindow = 6,
}

function serpent.trackCure(herbType)
    local now = getEpoch()

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
    Determine strategy using LOCK-FIRST logic.
    The goal is always lock completion. Ekanelia is a mechanism to get lock pieces.
]]--
function determineStrategy()
    -- ===== FINISHING MOVES =====
    if truelock then
        serpStrategy = "finish"
        return
    end

    -- ===== DARKSHADE FORK: Apply darkshade if not on target (highest priority) =====
    if not tAffs.darkshade then
        serpStrategy = "apply_darkshade"
        return
    end

    -- ===== CAN WE COMPLETE TRUELOCK? =====
    -- Need: paralysis + asthma + anorexia + slickness + impatience
    if hardlock then
        -- Hardlock means: asthma + anorexia + slickness + impatience (missing paralysis)
        if not haveAff("paralysis") then
            serpStrategy = "complete_truelock"
            return
        end
    end

    -- Close to truelock: have most lock pieces, missing 1-2
    local lockPieces = 0
    if haveAff("paralysis") then lockPieces = lockPieces + 1 end
    if haveAff("asthma") then lockPieces = lockPieces + 1 end
    if haveAff("anorexia") then lockPieces = lockPieces + 1 end
    if haveAff("slickness") then lockPieces = lockPieces + 1 end
    if haveAff("impatience") then lockPieces = lockPieces + 1 end

    if lockPieces >= 4 then
        serpStrategy = "complete_truelock"
        return
    end

    -- ===== CAN WE COMPLETE HARDLOCK? =====
    -- Need: asthma + anorexia + slickness + (paralysis or impatience)
    if softlock then
        serpStrategy = "complete_hardlock"
        return
    end

    -- ===== CAN WE COMPLETE SOFTLOCK? =====
    -- Need: asthma + anorexia + slickness
    local softPieces = 0
    if haveAff("asthma") then softPieces = softPieces + 1 end
    if haveAff("anorexia") then softPieces = softPieces + 1 end
    if haveAff("slickness") then softPieces = softPieces + 1 end

    if softPieces >= 2 then
        serpStrategy = "complete_softlock"
        return
    end

    -- ===== HYPNOSIS IN PROGRESS =====
    if serpent.hypnosis.phase == "ready_snap" then
        serpStrategy = "hypnosis"
        return
    end

    if serpent.hypnosis.isActive() then
        serpStrategy = "hypnosis"
        return
    end

    -- ===== CURE ADAPTATION: Darkshade is on, react to cure patterns =====
    -- If target is eating ginseng, stack ginseng to 3 first so they're busy curing it.
    -- If target eats anything else, darkshade stays on — just push lock.
    local ct = serpent.cureTracking
    if ct.ginsengCures > 2 and countGinsengStack() < 3 then
        -- Target eating ginseng + stack not deep enough yet
        if serpent.config.debug then
            Algedonic.Echo("<cyan>ADAPTIVE: <white>Target eating ginseng — stacking (" .. countGinsengStack() .. "/3)")
        end
        serpStrategy = "ginseng_pressure"
        return
    end

    -- Default: push lock (darkshade is on, lock them)
    serpStrategy = "setup_lock"
end

function serpent.assessCombatState()
    local dominated = 0

    if truelock then dominated = dominated + 100 end
    if hardlock then dominated = dominated + 50 end
    if softlock then dominated = dominated + 25 end

    if haveAff("asthma") then dominated = dominated + 10 end
    if haveAff("weariness") then dominated = dominated + 10 end
    if haveAff("slickness") then dominated = dominated + 15 end
    if haveAff("paralysis") then dominated = dominated + 20 end
    if haveAff("impatience") then dominated = dominated + 25 end
    if haveAff("anorexia") then dominated = dominated + 20 end

    if tAffs.fratricide or serpent.hypnosis.fratricideActive then
        dominated = dominated + 20
    end

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
-- VENOM SELECTION (Ekanelia-Aware, Lock-First)
-- =============================================================================

--[[
    Select venoms based on current strategy.
    DSTAB venoms are chosen to:
    1. Complete lock pieces directly
    2. Set up Ekanelia conditionals for future impulse rounds
]]--
function selectVenoms()
    envenomList = {}
    envenomListTwo = {}
    attackMode = "dstab"

    -- ===== FINISH: Truelock achieved =====
    if serpStrategy == "finish" then
        local lockAff = getLockingAffliction(target)
        if lockAff == "weariness" and not haveAff("weariness") then
            table.insert(envenomList, "vernalius")
        elseif lockAff == "paralyse" and not haveAff("paralysis") then
            table.insert(envenomList, "curare")
        else
            table.insert(envenomList, "voyria")
        end
        buildSecondVenom()
        return
    end

    -- ===== COMPLETE TRUELOCK: Missing 1-2 pieces =====
    if serpStrategy == "complete_truelock" then
        -- Deliver missing lock pieces directly via venom
        if not haveAff("paralysis") then
            table.insert(envenomList, "curare")
        elseif not haveAff("impatience") then
            -- Impatience has no venom — must come from Ekanelia monkshood
            -- Set up monkshood conditionals: asthma + masochism(impulse) + weariness
            if not haveAff("weariness") then
                table.insert(envenomList, "vernalius")
            elseif not haveAff("asthma") then
                table.insert(envenomList, "kalmia")
            else
                -- Conditionals are ready for impulse masochism monkshood
                -- Deliver other useful venoms while we wait for impulse round
                table.insert(envenomList, "gecko")
            end
        elseif not haveAff("slickness") then
            table.insert(envenomList, "gecko")
        elseif not haveAff("asthma") then
            table.insert(envenomList, "kalmia")
        elseif not haveAff("anorexia") then
            table.insert(envenomList, "slike")
        else
            table.insert(envenomList, "voyria")
        end
        buildSecondVenom()
        return
    end

    -- ===== COMPLETE HARDLOCK: Softlock + need paralysis/impatience =====
    if serpStrategy == "complete_hardlock" then
        if not haveAff("paralysis") then
            table.insert(envenomList, "curare")
        elseif not haveAff("impatience") then
            -- Set up monkshood Ekanelia conditionals
            if not haveAff("weariness") then
                table.insert(envenomList, "vernalius")
            elseif not haveAff("asthma") then
                table.insert(envenomList, "kalmia")
            else
                table.insert(envenomList, "curare")
            end
        else
            table.insert(envenomList, "curare")
        end
        buildSecondVenom()
        return
    end

    -- ===== COMPLETE SOFTLOCK: Need asthma + anorexia + slickness =====
    if serpStrategy == "complete_softlock" then
        -- Direct venom delivery for softlock pieces
        if not haveAff("asthma") then
            table.insert(envenomList, "kalmia")
        elseif not haveAff("slickness") then
            -- Can we trigger kalmia Ekanelia? (clumsiness + weariness → slickness)
            if haveAff("clumsiness") and haveAff("weariness") then
                -- Ekanelia conditions met - but we need bite for that
                -- Use kalmia venom to get asthma+slickness via Ekanelia
                table.insert(envenomList, "kalmia")
            elseif not haveAff("clumsiness") and not haveAff("weariness") then
                -- Set up kalmia Ekanelia: clumsiness + weariness
                table.insert(envenomList, "xentio")
                table.insert(envenomListTwo, "vernalius")
                return
            elseif not haveAff("clumsiness") then
                table.insert(envenomList, "xentio")
            elseif not haveAff("weariness") then
                table.insert(envenomList, "vernalius")
            else
                table.insert(envenomList, "gecko")
            end
        elseif not haveAff("anorexia") then
            table.insert(envenomList, "slike")
        else
            -- Softlock pieces in place, add pressure
            if not haveAff("paralysis") then
                table.insert(envenomList, "curare")
            else
                table.insert(envenomList, "darkshade")
            end
        end
        buildSecondVenom()
        return
    end

    -- ===== HYPNOSIS: Maintain pressure while hypnosis completes =====
    if serpStrategy == "hypnosis" then
        if not haveAff("slickness") then
            table.insert(envenomList, "gecko")
        elseif not haveAff("paralysis") then
            table.insert(envenomList, "curare")
        elseif not haveAff("asthma") then
            table.insert(envenomList, "kalmia")
        elseif not haveAff("weariness") then
            table.insert(envenomList, "vernalius")
        else
            table.insert(envenomList, "darkshade")
        end
        buildSecondVenom()
        return
    end

    -- ===== APPLY DARKSHADE: Get darkshade on target ASAP =====
    if serpStrategy == "apply_darkshade" then
        table.insert(envenomList, "darkshade")
        buildSecondVenom()
        return
    end

    -- ===== GINSENG PRESSURE: Stack ginseng affs quickly (both venoms) =====
    -- Target is eating ginseng to cure darkshade — stack to 3 ginseng affs
    -- so they spend multiple rounds eating ginseng, then we switch to lock
    if serpStrategy == "ginseng_pressure" then
        if not haveAff("addiction") then
            table.insert(envenomList, "vardrax")
        elseif not haveAff("nausea") then
            table.insert(envenomList, "euphorbia")
        elseif not haveAff("haemophilia") then
            table.insert(envenomList, "notechis")
        elseif not haveAff("scytherus") then
            table.insert(envenomList, "scytherus")
        else
            table.insert(envenomList, "curare")
        end
        buildSecondVenomGinseng()
        return
    end

    -- ===== SETUP LOCK (Default): Build toward lock + set up Ekanelia =====
    -- Priority: paralysis (blocks tree) → clumsiness (Ekanelia setup) → lock pieces

    if not haveAff("paralysis") then
        table.insert(envenomList, "curare")
    elseif not haveAff("clumsiness") then
        table.insert(envenomList, "xentio")
    elseif not haveAff("asthma") and not haveAff("weariness") then
        -- Set up monkshood Ekanelia: asthma + weariness (masochism via impulse)
        table.insert(envenomList, "kalmia")
        table.insert(envenomListTwo, "vernalius")
        return
    elseif not haveAff("asthma") then
        table.insert(envenomList, "kalmia")
    elseif not haveAff("weariness") then
        table.insert(envenomList, "vernalius")
    elseif not haveAff("slickness") then
        table.insert(envenomList, "gecko")
    elseif not haveAff("anorexia") then
        table.insert(envenomList, "slike")
    else
        table.insert(envenomList, "curare")
    end

    buildSecondVenom()
end

--[[
    Build second venom for doublestab (must differ from first).
    Ekanelia-aware: prefers venoms that complete Ekanelia conditionals.
]]--
function buildSecondVenom()
    if #envenomListTwo > 0 then return end

    local firstVenom = envenomList[1]

    -- Priority: clumsiness (Ekanelia setup) → weariness → lock pieces
    if not haveAff("clumsiness") and firstVenom ~= "xentio" then
        table.insert(envenomListTwo, "xentio")
    elseif not haveAff("weariness") and firstVenom ~= "vernalius" then
        table.insert(envenomListTwo, "vernalius")
    elseif not haveAff("paralysis") and firstVenom ~= "curare" then
        table.insert(envenomListTwo, "curare")
    elseif not haveAff("asthma") and firstVenom ~= "kalmia" then
        table.insert(envenomListTwo, "kalmia")
    elseif not haveAff("slickness") and firstVenom ~= "gecko" then
        table.insert(envenomListTwo, "gecko")
    elseif not haveAff("anorexia") and firstVenom ~= "slike" then
        table.insert(envenomListTwo, "slike")
    elseif not haveAff("darkshade") and firstVenom ~= "darkshade" then
        table.insert(envenomListTwo, "darkshade")
    elseif not haveAff("addiction") and firstVenom ~= "vardrax" then
        table.insert(envenomListTwo, "vardrax")
    elseif not haveAff("nausea") and firstVenom ~= "euphorbia" then
        table.insert(envenomListTwo, "euphorbia")
    elseif firstVenom ~= "aconite" then
        table.insert(envenomListTwo, "aconite")
    else
        table.insert(envenomListTwo, "sumac")
    end
end

--[[
    Build second venom prioritizing ginseng afflictions.
    Used by ginseng_pressure and protect_darkshade strategies.
]]--
function buildSecondVenomGinseng()
    if #envenomListTwo > 0 then return end
    local firstVenom = envenomList[1]

    if not tAffs.darkshade and firstVenom ~= "darkshade" then
        table.insert(envenomListTwo, "darkshade")
    elseif not haveAff("addiction") and firstVenom ~= "vardrax" then
        table.insert(envenomListTwo, "vardrax")
    elseif not haveAff("nausea") and firstVenom ~= "euphorbia" then
        table.insert(envenomListTwo, "euphorbia")
    elseif not haveAff("haemophilia") and firstVenom ~= "notechis" then
        table.insert(envenomListTwo, "notechis")
    elseif not haveAff("scytherus") and firstVenom ~= "scytherus" then
        table.insert(envenomListTwo, "scytherus")
    else
        -- All ginseng affs covered, fall back to lock piece
        buildSecondVenom()
    end
end

-- =============================================================================
-- ATTACK EXECUTION
-- =============================================================================

--[[
    Execute the attack based on current strategy and venom selection.

    DSTAB is the primary attack. IMPULSE is conditional on:
    1. No sileris/fangbarrier (bite must land)
    2. Ekanelia conditions met or completable by impulse suggestion
    3. EQ is free (snap/shrug/hypnosis take priority)
]]--
function serp_ekanelia_attack()
    if not target or target == "" then
        Algedonic.Echo("<red>No target set!<white>")
        return
    end

    local sp = ataxia.settings.separator
    local preAtk = combatQueue()

    -- Rebounding/shield check with V1 fallback (GMCP timing gap)
    local hasRebounding = haveAff("rebounding") or (tAffs and tAffs.rebounding)
    local hasShield = haveAff("shield") or (tAffs and tAffs.shield)

    -- Weapon wielding prefixes (single command, game assigns hands)
    local wieldWhip = "wield shield whip" .. sp
    local wieldDirk = "wield shield dirk" .. sp

    -- ===== DEFENSE STRIPPING (Flay) =====
    if hasRebounding or hasShield then
        local defense = hasShield and "shield" or "rebounding"
        local flayVenom = envenomList[1] or "curare"
        local cmd = wieldWhip .. "flay " .. target .. " " .. defense .. " " .. flayVenom

        -- Flay delivers one venom — fix envenom lists for hit triggers
        envenomList = {flayVenom}
        envenomListTwo = {}

        -- Chain eq action if available
        local eqAction = getEqAction()
        if eqAction then
            cmd = cmd .. sp .. eqAction
        end

        serp_sendAttack(preAtk .. cmd)
        return
    end

    -- NOTE: Sileris/fangbarrier does NOT need flaying — dstab works through it.
    -- Only impulse/bite is blocked. checkImpulseEligible() handles this.

    -- ===== EXECUTE (Truelock finish) =====
    if truelock then
        serp_sendAttack(preAtk .. "execute " .. target)
        return
    end

    -- ===== DETERMINE EQ ACTION (priority order) =====
    local eqAction = getEqAction()

    -- ===== CHECK IMPULSE ELIGIBILITY =====
    local useImpulse = false
    local impulsePair = nil

    if not eqAction and checkImpulseEligible() then
        -- EQ is free and no sileris — check if Ekanelia is achievable
        impulsePair = selectImpulsePair()
        if impulsePair then
            useImpulse = true
        end
    end

    -- ===== BUILD ATTACK =====
    local cmd

    if useImpulse and impulsePair then
        -- IMPULSE: suggestion + bite + Ekanelia (bal+eq)
        cmd = wieldDirk .. "impulse " .. target .. " " .. impulsePair.suggestion .. " " .. impulsePair.venom
        Algedonic.Echo("<yellow>IMPULSE " .. impulsePair.suggestion:upper() .. " + " .. impulsePair.venom:upper() .. "<white> → " .. impulsePair.label)

        -- Populate envenomList for hit triggers (impulse bites with the venom)
        envenomList = {}
        table.insert(envenomList, impulsePair.venom)
        envenomListTwo = {}
    elseif eqAction then
        -- DSTAB + eq action
        cmd = wieldDirk .. "dstab " .. target .. " " .. envenomList[1] .. " " .. envenomListTwo[1] .. sp .. eqAction
    else
        -- DSTAB only (no eq action, no impulse)
        cmd = wieldDirk .. "dstab " .. target .. " " .. envenomList[1] .. " " .. envenomListTwo[1]
    end

    -- Handle hSuggRequest override: if keybind requested a specific suggestion
    -- and we're using impulse, swap in the requested suggestion
    if useImpulse and hSuggActive ~= "" and impulsePair then
        cmd = wieldDirk .. "impulse " .. target .. " " .. hSuggActive .. " " .. impulsePair.venom
    end

    serp_sendAttack(preAtk .. cmd)
end

--[[
    Determine the best EQ action for this round.
    Returns the eq command string or nil.
    Priority: snap > shrug > hypnosis step
]]--
function getEqAction()
    -- 1. Snap: asthma on target + snap ready + not yet snapped
    if serpent.hypnosis.canSnap() then
        return "snap " .. target
    end

    -- 2. Shrug: we're near-locked and can self-cure
    -- (Shrugging uses eq to cure an affliction from ourselves)
    if serpent.state.shouldShrug then
        serpent.state.shouldShrug = false
        return "shrugging"
    end

    -- 3. Hypnosis step: active hypnosis chain
    if serpent.hypnosis.isActive() then
        local hypCmd = serpent.hypnosis.getCommand()
        if hypCmd then
            return hypCmd
        end
    end

    return nil
end

--[[
    Send the attack if target is present.
    Wraps with queue and handles dispel + attackInFlight.
]]--
function serp_sendAttack(atk)
    if not table.contains(ataxia.playersHere, target) then
        Algedonic.Echo("<red>Target not in room!<white>")
        return
    end

    local sp = ataxia.settings.separator

    -- Purge residual venom before new attack
    atk = "purge" .. sp .. atk

    -- Prepend dispel if first attack
    if not serpent.state.dispelSent then
        atk = "dispel " .. target .. sp .. atk
        serpent.state.dispelSent = true
    end

    send("queue addclear freestand " .. atk)
    serpent.state.attackInFlight = true
end

-- =============================================================================
-- MAIN OFFENSE FUNCTION
-- =============================================================================

function serp_ekanelia_offense()
    -- Only dispatch when we actually have balance — prevents computing
    -- attack with current state then queuing it for later execution
    -- (by which time game state has changed)
    if gmcp.Char.Vitals.bal ~= "1" then
        return
    end

    -- Guard: don't re-dispatch while off balance
    if serpent.state.attackInFlight then
        return
    end

    -- Sync suggestion queueing
    if hSuggRequest ~= "" and hSuggRequest ~= hSuggActive then
        hSuggActive = hSuggRequest
    end

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

    -- Determine strategy (lock-first)
    if serpOffenseMode == "auto" then
        determineStrategy()
    elseif serpOffenseMode == "lock" then
        serpStrategy = "lock"
    elseif serpOffenseMode == "darkshade" then
        serpStrategy = "darkshade"
    elseif serpOffenseMode == "hypnosis" then
        serpStrategy = "hypnosis"
    end

    -- Echo strategy
    if serpent.config.echoStrategy then
        Algedonic.Echo("<dim_grey>Strategy: <white>" .. serpStrategy)
    end

    -- Echo target afflictions for debugging
    if serpent.config.echoAffs then
        local affStr = ""
        if haveAff("asthma") then affStr = affStr .. "<cyan>AST " end
        if haveAff("weariness") then affStr = affStr .. "<cyan>WEA " end
        if haveAff("clumsiness") then affStr = affStr .. "<cyan>CLU " end
        if haveAff("slickness") then affStr = affStr .. "<yellow>SLI " end
        if haveAff("paralysis") then affStr = affStr .. "<yellow>PAR " end
        if haveAff("impatience") then affStr = affStr .. "<red>IMP " end
        if haveAff("anorexia") then affStr = affStr .. "<red>ANO " end
        if haveAff("masochism") then affStr = affStr .. "<magenta>MAS " end
        if haveAff("confusion") then affStr = affStr .. "<magenta>CON " end
        if haveAff("recklessness") then affStr = affStr .. "<magenta>RCK " end
        if haveAff("sileris") or (tAffs and tAffs.sileris) then affStr = affStr .. "<red>SIL " end
        if haveAff("fangbarrier") or (tAffs and tAffs.fangbarrier) then affStr = affStr .. "<red>FNG " end
        if tAffs.darkshade then affStr = affStr .. "<green>DRK " end
        if haveAff("addiction") then affStr = affStr .. "<green>ADD " end
        if haveAff("nausea") then affStr = affStr .. "<green>NAU " end
        if affStr == "" then affStr = "<dim_grey>none" end
        cecho("<white>[tAffs]: " .. affStr .. "<reset>\n")
    end

    -- Build venom lists
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
    cecho("<dim_grey>  Priority: Lock completion via Ekanelia + venom pressure<reset>\n")
end

function serp_setmode_darkshade()
    serpOffenseMode = "darkshade"
    cecho("\n<magenta>Serpent offense: DARKSHADE mode<reset>\n")
    cecho("<dim_grey>  Priority: Stack ginseng afflictions, keep darkshade 26+ seconds<reset>\n")
end

function serp_setmode_hypnosis()
    serpOffenseMode = "hypnosis"
    if serpent.hypnosis and serpent.hypnosis.reset then
        serpent.hypnosis.reset()
    end
    cecho("\n<cyan>Serpent offense: HYPNOSIS COMBO mode<reset>\n")
    cecho("<dim_grey>  Priority: Fratricide -> mental affs RELAPSE after cure!<reset>\n")
end

function serp_setmode_auto()
    serpOffenseMode = "auto"
    cecho("\n<yellow>Serpent offense: AUTO mode<reset>\n")
    cecho("<dim_grey>  Lock-first with adaptive Ekanelia + darkshade<reset>\n")
end

-- =============================================================================
-- STATUS DISPLAY
-- =============================================================================

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

    -- Sileris/fangbarrier status (V1 fallback — haveAff alone misses fangbarrier)
    local hasSileris = haveAff("sileris") or (tAffs and tAffs.sileris)
    local hasFangbarrier = haveAff("fangbarrier") or (tAffs and tAffs.fangbarrier)
    cecho("<white>Sileris/Fangbarrier: " .. ((hasSileris or hasFangbarrier) and "<red>UP (blocks bite/impulse)" or "<green>DOWN") .. "<reset>\n")

    -- Impulse eligibility
    cecho("<white>Impulse Eligible: " .. (checkImpulseEligible() and "<green>YES" or "<red>NO"))
    if not checkImpulseEligible() then
        local missing = {}
        if hasSileris then table.insert(missing, "sileris") end
        if hasFangbarrier then table.insert(missing, "fangbarrier") end
        if #missing > 0 then
            cecho(" <dim_grey>(blocked: " .. table.concat(missing, ", ") .. ")")
        end
    end
    cecho("<reset>\n")

    -- Ekanelia opportunities
    checkEkaneliaOpportunities()
    local impPair = selectImpulsePair()

    if next(ekaneliaReady) then
        cecho("<white>Ekanelia Ready: ")
        for k, v in pairs(ekaneliaReady) do
            if v then cecho("<yellow>" .. k .. " ") end
        end
        cecho("<reset>\n")
    else
        cecho("<white>Ekanelia Ready: <dim_grey>None<reset>\n")
    end

    if impPair then
        cecho("<white>Impulse Pair: <green>impulse " .. target .. " " .. impPair.suggestion .. " " .. impPair.venom .. " → " .. impPair.label .. "<reset>\n")
    else
        cecho("<white>Impulse Pair: <dim_grey>None available<reset>\n")
    end

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

    -- Cure tracking
    cecho("<white>------- Adaptive Tracking --------<reset>\n")
    cecho("<white>Kelp Cures: <yellow>" .. serpent.cureTracking.kelpCures .. "<reset>")
    cecho("  <white>Ginseng Cures: <yellow>" .. serpent.cureTracking.ginsengCures .. "<reset>\n")
    cecho("<white>Bloodroot Cures: <yellow>" .. serpent.cureTracking.bloodrootCures .. "<reset>")
    cecho("  <white>Focus: <yellow>" .. serpent.cureTracking.focusCures .. "<reset>\n")

    if serpent.cureTracking.ginsengCures > serpent.cureTracking.kelpCures + 2 then
        cecho("<green>ADAPTIVE: <white>Target fears darkshade → pushing LOCK<reset>\n")
    elseif serpent.cureTracking.kelpCures > serpent.cureTracking.ginsengCures + 2 then
        cecho("<magenta>ADAPTIVE: <white>Target fears lock → pushing DARKSHADE<reset>\n")
    else
        cecho("<dim_grey>ADAPTIVE: <white>Balanced curing - standard progression<reset>\n")
    end

    -- Attack in flight
    cecho("<white>Attack In Flight: " .. (serpent.state.attackInFlight and "<yellow>YES" or "<dim_grey>No") .. "<reset>\n")
    cecho("<white>Dispel Sent: " .. (serpent.state.dispelSent and "<green>YES" or "<dim_grey>No") .. "<reset>\n")

    cecho("<cyan>==================================<reset>\n")
end

-- =============================================================================
-- EVENT HANDLERS
-- =============================================================================

function serpent.resetCureTracking()
    serpent.cureTracking.kelpCures = 0
    serpent.cureTracking.ginsengCures = 0
    serpent.cureTracking.bloodrootCures = 0
    serpent.cureTracking.focusCures = 0
    serpent.cureTracking.lastReset = getEpoch()
end

-- Kill existing event handlers to avoid duplicates
if serpent.eventHandlers then
    for _, handlerId in pairs(serpent.eventHandlers) do
        if killAnonymousEventHandler then killAnonymousEventHandler(handlerId) end
    end
end
serpent.eventHandlers = {}

if registerAnonymousEventHandler then
    -- Target change: reset state
    serpent.eventHandlers.tarChanged = registerAnonymousEventHandler("tar changed", function()
        if serpent.hypnosis and serpent.hypnosis.reset then
            serpent.hypnosis.reset()
        end
        serpent.resetCureTracking()
        serpent.state.dispelSent = false
        serpent.state.attackInFlight = false
        hSuggActive = ""
    end)

    -- Balance recovery: clear attackInFlight
    serpent.eventHandlers.balRecovery = registerAnonymousEventHandler("gmcp.Char.Vitals", function()
        if gmcp.Char.Vitals.bal == "1" then
            serpent.state.attackInFlight = false
        end
    end)
end

-- =============================================================================
-- ALIAS REGISTRATION
-- =============================================================================

if serpent.aliases then
    for _, aliasId in pairs(serpent.aliases) do
        if killAlias then killAlias(aliasId) end
    end
end
serpent.aliases = {}

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

if serpent.triggers then
    for _, triggerId in pairs(serpent.triggers) do
        if killTrigger then killTrigger(triggerId) end
    end
end
serpent.triggers = {}

if tempRegexTrigger then
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

    serpent.triggers.suggestAlready = tempRegexTrigger(
        "^(\\w+)'s mind is already holding something quite similar to that suggestion\\.$",
        [[
            serpentsuggest = true
        ]]
    )

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

if Algedonic and Algedonic.Echo then
    Algedonic.Echo("<cyan>Serpent Offense System (Overhaul)<white> loaded.")
    Algedonic.Echo("<dim_grey>  DSTAB-primary, IMPULSE for Ekanelia triggers<reset>")
    Algedonic.Echo("<dim_grey>  Commands: ek, eklock, ekhyp, ekdark, ekauto, ekstatus, ekhypstatus<reset>")
else
    cecho("<cyan>Serpent Offense System (Overhaul)<white> loaded.\n")
end
