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

    V3 is now the sole tracking system. This module provides:
    - Backward-compatible wrapper functions (delegate to V3)
    - Verification signal handlers (smoke, fumble, etc.)
    - Probabilistic lock detection
    - V2 compatibility stubs
    - Debug/display functions
]]--

-- ============================================
-- WRAPPER FUNCTIONS (Backward Compatibility)
-- ============================================

-- Main wrapper for herb cure detection
function targetAteWrapper(herb)
    -- Eating any herb proves no anorexia (erAff now calls removeAffV3 internally)
    erAff("anorexia")
    onHerbCureV3(herb)
end

-- Wrapper for adding afflictions (delegates to tarAffed which calls applyAffV3)
function tarAffedWrapper(...)
    tarAffed(...)
end

-- Wrapper for removing afflictions (delegates to erAff which calls removeAffV3)
function erAffWrapper(aff)
    erAff(aff)
end

-- Wrapper for checking afflictions (delegates to haveAff which calls haveAffV3)
function haveAffWrapper(aff)
    return haveAff(aff)
end

-- ============================================
-- VERIFICATION SIGNAL HANDLERS
-- ============================================

-- Target smoked - proves asthma is ABSENT (can't smoke with asthma)
function onTargetSmokeV3()
    collapseAffAbsentV3("asthma")
end

-- Target fumbled - proves clumsiness is PRESENT
function onTargetFumbleV3()
    collapseAffPresentV3("clumsiness")
end

-- Target vomited - proves nausea is PRESENT
function onTargetVomitV3()
    collapseAffPresentV3("nausea")
end

-- Target slipped on slickness - proves slickness is PRESENT
function onTargetSlickFailV3()
    collapseAffPresentV3("slickness")
end

-- Target couldn't act due to paralysis - proves paralysis is PRESENT
function onTargetParalysisBlockV3()
    collapseAffPresentV3("paralysis")
end

-- Target stumbled (dizziness) - proves dizziness is PRESENT
function onTargetStumbleV3()
    collapseAffPresentV3("dizziness")
end

-- Target had a seizure - proves epilepsy is PRESENT
function onTargetSeizureV3()
    collapseAffPresentV3("epilepsy")
end

-- Target acted stupidly - proves stupidity is PRESENT
function onTargetStupidActionV3()
    collapseAffPresentV3("stupidity")
end

-- Target fled randomly (paranoia) - proves paranoia is PRESENT
function onTargetParanoiaFleeV3()
    collapseAffPresentV3("paranoia")
end

-- Target applied salve successfully - proves slickness is ABSENT
function onTargetApplySalveV3()
    collapseAffAbsentV3("slickness")
end

-- Target ate something - proves anorexia is ABSENT
function onTargetAteV3()
    collapseAffAbsentV3("anorexia")
end

-- Target showed impatience - proves impatience is PRESENT
function onTargetImpatienceV3()
    collapseAffPresentV3("impatience")
end

-- Target showed dementia signs - proves dementia is PRESENT
function onTargetDementiaV3()
    collapseAffPresentV3("dementia")
end

-- Target showed confusion - proves confusion is PRESENT
function onTargetConfusionV3()
    collapseAffPresentV3("confusion")
end

-- ============================================
-- PROBABILISTIC LOCK DETECTION
-- ============================================

-- Check for locks with probability display
function checkTargetLocksV3()
    -- Calculate lock probabilities
    local softlockAffs = {"anorexia", "asthma", "slickness"}
    local softlockProb = getStateProbabilityV3(softlockAffs)

    local hardlockAffs = {"anorexia", "asthma", "slickness", "impatience"}
    local hardlockProb = getStateProbabilityV3(hardlockAffs)

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
            cecho("\n<yellow>[SOFTLOCK: " .. math.floor(softlockProb * 100) .. "%]<reset>")
        end
    end
end

-- Get detailed lock status
function getLockStatusV3()
    return {
        softlock = getStateProbabilityV3({"anorexia", "asthma", "slickness"}),
        hardlock = getStateProbabilityV3({"anorexia", "asthma", "slickness", "impatience"}),
        truelock = getStateProbabilityV3({"anorexia", "asthma", "slickness", "impatience", "paralysis"}),
    }
end

-- ============================================
-- ALIAS COMMANDS (for user convenience)
-- ============================================

-- Show current V3 state
function v3status()
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
    showAffProbsV3()
end

-- ============================================
-- TREE / FOCUS HANDLING
-- ============================================

-- Canonical tree-curable affliction list (was treeCurableAffsV2, now owned by V3)
treeCurableAffsV3 = {
    "paralysis", "slickness", "anorexia", "asthma", "sensitivity",
    "clumsiness", "weariness", "epilepsy", "haemophilia", "nausea",
    "dizziness", "shyness", "stupidity", "confusion", "dementia",
    "paranoia", "hallucinations", "impatience", "hypersomnia", "addiction",
    "darkshade"
}
-- Backward compat alias
treeCurableAffsV2 = treeCurableAffsV3

-- Canonical focus-curable affliction list (was focusCurableAffsV2, now owned by V3)
focusCurableAffsV3 = {
    "impatience", "stupidity", "anorexia", "epilepsy", "masochism",
    "recklessness", "dizziness", "shyness", "confusion", "dementia",
    "paranoia", "hallucinations", "loneliness", "vertigo", "feeble",
    "addiction", "hypersomnia", "stuttering"
}
-- Backward compat alias
focusCurableAffsV2 = focusCurableAffsV3

-- Handle target using tree tattoo (cures random physical aff)
function onTargetTreeV3()
    local treeCurable = treeCurableAffsV3

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
    local focusCurable = focusCurableAffsV3

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
function onPassiveCureV3(numCures)
    if not numCures or numCures < 1 then return end

    local pool = passiveCurableAffsV3
    local allCandidates = {}

    for cure = 1, numCures do
        local newStates = {}
        local roundCandidates = {}

        for _, state in ipairs(afflictionStatesV3) do
            local candidates = {}
            for _, aff in ipairs(pool) do
                if state.affs[aff] then
                    table.insert(candidates, aff)
                    roundCandidates[aff] = true
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

        for aff, _ in pairs(roundCandidates) do
            allCandidates[aff] = true
        end

        afflictionStatesV3 = newStates

        if cure < numCures then
            deduplicateStatesV3()
        end
    end

    deduplicateStatesV3()
    pruneStatesV3()
    rebuildCacheV3()
    syncToOldSystemV3()
    updateAffDisplayV3()

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
-- V2 COMPATIBILITY STUBS
-- Route straggler V2 calls to V3
-- ============================================

function addAffV2(aff) if applyAffV3 then applyAffV3(aff) end end
function removeAffV2(aff) if removeAffV3 then removeAffV3(aff) end end
function haveAffV2(aff) return haveAffV3 and haveAffV3(aff) or false end
function confirmAffV2(aff) if aff and applyAffV3 then applyAffV3(aff) end end
function haveConfirmedAffV2(aff) return haveAffV3 and haveAffV3(aff) or false end
function stackAffV2(aff) if applyAffV3 then applyAffV3(aff) end end
function getStackCountV2(aff) return haveAffV3 and haveAffV3(aff) and 1 or 0 end
function hasMultipleStacksV2(aff) return false end
function targetAteV2(herb) if onHerbCureV3 then onHerbCureV3(herb) end end
function onTargetTreeV2(t) onTargetTreeV3() end
function onTargetFocusV2(t) onTargetFocusV3() end
function resetAffsV2() resetStatesV3() end
function debugAffsV2() showBranchesV3() end
function backtrackCureV2(a) return false end
function clearPendingGuessesV2() end
function updateAffDisplayV2() updateAffDisplayV3() end
function reduceCureTypeAffCertaintyV2() end
function reduceRandomAffCertaintyV2() end
function onBloodrootApplyConfirmV2() end
tAffsV2 = tAffsV2 or {}
tAffStacksV2 = tAffStacksV2 or {}

-- Legacy toggle stubs (V3 is always on)
function isV3Active() return true end
function getCurrentTrackingSystem() return "V3" end
function enableV3() end
function disableV3() end
function toggleV3() end
