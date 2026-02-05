--[[mudlet
type: script
name: V3 Integration
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Affliction Tracking Core
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[mudlet
type: script
name: Affliction Tracking V3 - Integration
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Combat
- Affliction Tracking V3
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    Affliction Tracking V3 - Integration Layer

    This module provides:
    - Wrapper functions that route to V3/V2/V1 based on settings
    - Verification signal handlers (smoke, fumble, etc.)
    - Probabilistic lock detection
    - Debug/display functions
]]--

-- ============================================
-- WRAPPER FUNCTIONS (Route to correct system)
-- ============================================

-- Main wrapper for herb cure detection
-- Replace targetAte() calls in triggers with this
function targetAteWrapper(herb)
    if affConfigV3 and affConfigV3.enabled then
        onHerbCureV3(herb)
    elseif ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
        targetAteV2(herb)
    else
        if targetAte then targetAte(herb) end
    end
end

-- Wrapper for adding afflictions
function tarAffedWrapper(...)
    if affConfigV3 and affConfigV3.enabled then
        for _, aff in ipairs({...}) do
            if type(aff) == "string" then
                applyAffV3(aff)
            end
        end
    elseif ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
        if tarAffedConfirmed then tarAffedConfirmed(...) end
    else
        if tarAffed then tarAffed(...) end
    end
end

-- Wrapper for removing afflictions
function erAffWrapper(aff)
    if affConfigV3 and affConfigV3.enabled then
        removeAffV3(aff)
    elseif ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
        if removeAffV2 then removeAffV2(aff) end
    else
        if erAff then erAff(aff) end
    end
end

-- Wrapper for checking afflictions
function haveAffWrapper(aff)
    if affConfigV3 and affConfigV3.enabled then
        return haveAffV3(aff)
    elseif ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
        return haveAffV2 and haveAffV2(aff) or false
    else
        return haveAff and haveAff(aff) or false
    end
end

-- ============================================
-- VERIFICATION SIGNAL HANDLERS
-- ============================================

-- Target smoked - proves asthma is ABSENT (can't smoke with asthma)
function onTargetSmokeV3()
    if not affConfigV3 or not affConfigV3.enabled then return end
    collapseAffAbsentV3("asthma")

    -- Also collapse any smoke-curable affs if they smoked successfully
    -- (proves they don't have asthma blocking the smoke)
end

-- Target fumbled - proves clumsiness is PRESENT
function onTargetFumbleV3()
    if not affConfigV3 or not affConfigV3.enabled then return end
    collapseAffPresentV3("clumsiness")
end

-- Target vomited - proves nausea is PRESENT
function onTargetVomitV3()
    if not affConfigV3 or not affConfigV3.enabled then return end
    collapseAffPresentV3("nausea")
end

-- Target slipped on slickness - proves slickness is PRESENT
function onTargetSlickFailV3()
    if not affConfigV3 or not affConfigV3.enabled then return end
    collapseAffPresentV3("slickness")
end

-- Target couldn't act due to paralysis - proves paralysis is PRESENT
function onTargetParalysisBlockV3()
    if not affConfigV3 or not affConfigV3.enabled then return end
    collapseAffPresentV3("paralysis")
end

-- Target stumbled (dizziness) - proves dizziness is PRESENT
function onTargetStumbleV3()
    if not affConfigV3 or not affConfigV3.enabled then return end
    collapseAffPresentV3("dizziness")
end

-- Target had a seizure - proves epilepsy is PRESENT
function onTargetSeizureV3()
    if not affConfigV3 or not affConfigV3.enabled then return end
    collapseAffPresentV3("epilepsy")
end

-- Target acted stupidly - proves stupidity is PRESENT
function onTargetStupidActionV3()
    if not affConfigV3 or not affConfigV3.enabled then return end
    collapseAffPresentV3("stupidity")
end

-- Target fled randomly (paranoia) - proves paranoia is PRESENT
function onTargetParanoiaFleeV3()
    if not affConfigV3 or not affConfigV3.enabled then return end
    collapseAffPresentV3("paranoia")
end

-- Target applied salve successfully - proves slickness is ABSENT
function onTargetApplySalveV3()
    if not affConfigV3 or not affConfigV3.enabled then return end
    collapseAffAbsentV3("slickness")
end

-- Target ate something - proves anorexia is ABSENT
function onTargetAteV3()
    if not affConfigV3 or not affConfigV3.enabled then return end
    collapseAffAbsentV3("anorexia")
end

-- ============================================
-- PROBABILISTIC LOCK DETECTION
-- ============================================

-- Check for locks with probability display
function checkTargetLocksV3()
    if not affConfigV3 or not affConfigV3.enabled then
        -- Fall back to V2 or V1 lock detection
        if checkTargetLocks then checkTargetLocks() end
        return
    end

    -- Calculate lock probabilities
    -- Softlock: asthma + slickness + anorexia (need all 3)
    local softlockAffs = {"anorexia", "asthma", "slickness"}
    local softlockProb = getStateProbabilityV3(softlockAffs)

    -- Hardlock: softlock + impatience
    local hardlockAffs = {"anorexia", "asthma", "slickness", "impatience"}
    local hardlockProb = getStateProbabilityV3(hardlockAffs)

    -- Truelock: hardlock + paralysis
    local truelockAffs = {"anorexia", "asthma", "slickness", "impatience", "paralysis"}
    local truelockProb = getStateProbabilityV3(truelockAffs)

    -- Display based on thresholds
    local threshold = 0.3  -- 30% to show

    if truelockProb >= threshold then
        if truelockProb >= 0.9 then
            cecho("\n<red>[TRUELOCK: " .. math.floor(truelockProb * 100) .. "%]<reset>")
        else
            cecho("\n<orange>[TRUELOCK: " .. math.floor(truelockProb * 100) .. "%]<reset>")
        end
    elseif hardlockProb >= threshold then
        if hardlockProb >= 0.9 then
            cecho("\n<orange>[HARDLOCK: " .. math.floor(hardlockProb * 100) .. "%]<reset>")
        else
            cecho("\n<yellow>[HARDLOCK: " .. math.floor(hardlockProb * 100) .. "%]<reset>")
        end
    elseif softlockProb >= threshold then
        if softlockProb >= 0.9 then
            cecho("\n<yellow>[SOFTLOCK: " .. math.floor(softlockProb * 100) .. "%]<reset>")
        else
            cecho("\n<ansi_yellow>[SOFTLOCK: " .. math.floor(softlockProb * 100) .. "%]<reset>")
        end
    end
end

-- Get detailed lock status
function getLockStatusV3()
    if not affConfigV3 or not affConfigV3.enabled then
        return nil
    end

    return {
        softlock = getStateProbabilityV3({"anorexia", "asthma", "slickness"}),
        hardlock = getStateProbabilityV3({"anorexia", "asthma", "slickness", "impatience"}),
        truelock = getStateProbabilityV3({"anorexia", "asthma", "slickness", "impatience", "paralysis"}),
    }
end

-- ============================================
-- TOGGLE / SETTINGS
-- ============================================

-- Enable V3 tracking
function enableV3()
    affConfigV3.enabled = true
    resetStatesV3()
    if ataxiaEcho then
        ataxiaEcho("[V3] Branching state tracking ENABLED")
    end
end

-- Disable V3 tracking (falls back to V2 or V1)
function disableV3()
    affConfigV3.enabled = false
    if ataxiaEcho then
        ataxiaEcho("[V3] Branching state tracking DISABLED")
    end
end

-- Toggle V3 tracking
function toggleV3()
    if affConfigV3.enabled then
        disableV3()
    else
        enableV3()
    end
end

-- ============================================
-- ALIAS COMMANDS (for user convenience)
-- ============================================

-- These can be called from aliases in Mudlet

-- Show current V3 state
function v3status()
    if not affConfigV3 or not affConfigV3.enabled then
        echo("\nV3 tracking is DISABLED\n")
        return
    end

    showBranchesV3()

    local locks = getLockStatusV3()
    if locks then
        echo("\nLock Probabilities:\n")
        echo(string.format("  Softlock: %.1f%%\n", locks.softlock * 100))
        echo(string.format("  Hardlock: %.1f%%\n", locks.hardlock * 100))
        echo(string.format("  Truelock: %.1f%%\n", locks.truelock * 100))
    end
end

-- Show affliction probabilities
function v3probs()
    if not affConfigV3 or not affConfigV3.enabled then
        echo("\nV3 tracking is DISABLED\n")
        return
    end
    showAffProbsV3()
end

-- ============================================
-- TREE / FOCUS HANDLING
-- ============================================

-- Handle target using tree tattoo (cures random physical aff)
function onTargetTreeV3()
    if not affConfigV3 or not affConfigV3.enabled then return end

    -- Tree cures one random affliction from the tree-curable list
    -- We treat this like an herb cure but with the tree cure list
    local treeCurable = treeCurableAffsV2 or {
        "paralysis", "slickness", "anorexia", "asthma", "sensitivity",
        "clumsiness", "weariness", "epilepsy", "haemophilia", "nausea",
        "dizziness", "shyness", "stupidity", "confusion", "dementia",
        "paranoia", "hallucinations", "impatience", "hypersomnia", "addiction"
    }

    local newStates = {}

    for _, state in ipairs(afflictionStatesV3) do
        local candidates = {}
        for _, aff in ipairs(treeCurable) do
            if state.affs[aff] then
                table.insert(candidates, aff)
            end
        end

        if #candidates == 0 then
            table.insert(newStates, state)
        elseif #candidates == 1 then
            state.affs[candidates[1]] = nil
            table.insert(newStates, state)
        else
            -- Tree cures based on curing priority, but we don't know the target's prio
            -- So we branch into all possibilities
            local probEach = state.prob / #candidates
            for _, aff in ipairs(candidates) do
                local branch = {affs = {}, prob = probEach}
                for k, v in pairs(state.affs) do branch.affs[k] = v end
                branch.affs[aff] = nil
                table.insert(newStates, branch)
            end
        end
    end

    afflictionStatesV3 = newStates
    deduplicateStatesV3()
    pruneStatesV3()
    rebuildCacheV3()
    syncToOldSystemV3()
    updateAffDisplayV3()

    if ataxiaEcho and affConfigV3.debugEcho then
        ataxiaEcho("[V3] Tree used - branched to " .. #afflictionStatesV3 .. " states")
    end
end

-- Handle target using focus (cures random mental aff)
function onTargetFocusV3()
    if not affConfigV3 or not affConfigV3.enabled then return end

    local focusCurable = focusCurableAffsV2 or {
        "impatience", "stupidity", "anorexia", "epilepsy", "masochism",
        "recklessness", "dizziness", "shyness", "confusion", "dementia",
        "paranoia", "hallucinations", "loneliness", "vertigo", "feeble",
        "addiction", "hypersomnia"
    }

    local newStates = {}

    for _, state in ipairs(afflictionStatesV3) do
        local candidates = {}
        for _, aff in ipairs(focusCurable) do
            if state.affs[aff] then
                table.insert(candidates, aff)
            end
        end

        if #candidates == 0 then
            table.insert(newStates, state)
        elseif #candidates == 1 then
            state.affs[candidates[1]] = nil
            table.insert(newStates, state)
        else
            local probEach = state.prob / #candidates
            for _, aff in ipairs(candidates) do
                local branch = {affs = {}, prob = probEach}
                for k, v in pairs(state.affs) do branch.affs[k] = v end
                branch.affs[aff] = nil
                table.insert(newStates, branch)
            end
        end
    end

    afflictionStatesV3 = newStates
    deduplicateStatesV3()
    pruneStatesV3()
    rebuildCacheV3()
    syncToOldSystemV3()
    updateAffDisplayV3()

    if ataxiaEcho and affConfigV3.debugEcho then
        ataxiaEcho("[V3] Focus used - branched to " .. #afflictionStatesV3 .. " states")
    end
end

-- ============================================
-- PASSIVE CURE HANDLING
-- ============================================

-- Pool of afflictions curable by passive abilities (from tSingleRandom/tMultipleRandom)
passiveCurableAffsV3 = {
    "aeon", "anorexia", "pyramides", "flushings", "crushedthroat",
    "sandfever", "paralysis", "asthma", "timeloop", "lethargy",
    "depression", "impatience", "hypersomnia", "retribution", "confusion",
    "darkshade", "healthleech", "hypochondria", "slickness", "manaleech",
    "nausea", "parasite", "shivering", "frozen", "spiritburn",
    "clumsiness", "sensitivity", "scytherus", "tenderskin", "stupidity",
    "haemophilia", "weariness", "hallucinations", "dizziness", "justice",
    "recklessness", "epilepsy", "addiction", "loneliness", "shyness",
    "vertigo", "paranoia", "agoraphobia", "claustrophobia", "generosity",
    "pacifism", "disloyalty", "selarnia",
    "brokenleftleg", "brokenrightleg", "brokenleftarm", "brokenrightarm"
}

-- Handle passive ability curing N random afflictions (branching model)
-- Used by: Passives(1), Alleviate(1), Bloodboil(1), Dragonheal(3), Fool(3),
--          Might(1), Purification(1), Purify(1), Salt(1), Shrugging(1),
--          Slough(1), Eruption(1)
function onPassiveCureV3(numCures)
    if not affConfigV3 or not affConfigV3.enabled then return end
    if not numCures or numCures < 1 then return end

    local pool = passiveCurableAffsV3
    local allCandidates = {}  -- Track all unique candidates across all states/rounds

    for cure = 1, numCures do
        local newStates = {}
        local roundCandidates = {}  -- Track candidates this round

        for _, state in ipairs(afflictionStatesV3) do
            local candidates = {}
            for _, aff in ipairs(pool) do
                if state.affs[aff] then
                    table.insert(candidates, aff)
                    roundCandidates[aff] = true  -- Track for echo
                end
            end

            if #candidates == 0 then
                -- No curable affs in this state - passes through unchanged
                table.insert(newStates, state)
            elseif #candidates == 1 then
                -- Only one option - deterministic cure
                state.affs[candidates[1]] = nil
                table.insert(newStates, state)
            else
                -- Multiple candidates - branch into all possibilities
                local probEach = state.prob / #candidates
                for _, aff in ipairs(candidates) do
                    local branch = {affs = {}, prob = probEach}
                    for k, v in pairs(state.affs) do branch.affs[k] = v end
                    branch.affs[aff] = nil
                    table.insert(newStates, branch)
                end
            end
        end

        -- Merge round candidates into allCandidates
        for aff, _ in pairs(roundCandidates) do
            allCandidates[aff] = true
        end

        afflictionStatesV3 = newStates

        -- Dedup between cure rounds to control state explosion
        if cure < numCures then
            deduplicateStatesV3()
        end
    end

    -- Final cleanup after all cures
    deduplicateStatesV3()
    pruneStatesV3()
    rebuildCacheV3()
    syncToOldSystemV3()
    updateAffDisplayV3()

    -- Enhanced debug echo with candidates
    if ataxiaEcho and affConfigV3.debugEcho then
        local candList = {}
        for aff, _ in pairs(allCandidates) do
            table.insert(candList, aff)
        end

        if #candList == 0 then
            ataxiaEcho("[V3] Passive cure (" .. numCures .. ") - no curable affs tracked")
        elseif #candList == 1 then
            ataxiaEcho("[V3] Passive cure (" .. numCures .. ") - cured: " .. candList[1])
        else
            local candStr = table.concat(candList, ", ")
            ataxiaEcho("[V3] Passive cure (" .. numCures .. ") - candidates: " .. candStr .. " (branched to " .. #afflictionStatesV3 .. " states)")
        end
    end
end

-- ============================================
-- INTEGRATION HELPERS
-- ============================================

-- Check if V3 is the active system
function isV3Active()
    return affConfigV3 and affConfigV3.enabled
end

-- Get the current tracking system name
function getCurrentTrackingSystem()
    if affConfigV3 and affConfigV3.enabled then
        return "V3"
    elseif ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
        return "V2"
    else
        return "V1"
    end
end
