--[[mudlet
type: script
name: Branching State Tracker
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
name: Affliction Tracking V3 - Branching State Tracker
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
    Affliction Tracking V3 - Branching State Tracker

    Probability-based affliction tracking using branching states.

    Mental Model:
    - States BRANCH when ambiguous cures happen (splits into possibilities)
    - States COLLAPSE when verification signals arrive (impossible branches eliminated)

    Like quantum superposition - the target's affliction state exists in multiple
    possible branches until "observed" via smoke/fumble/etc.

    Data Structure:
    afflictionStatesV3 = {
        {affs = {asthma=true, paralysis=true}, prob = 0.5},
        {affs = {paralysis=true}, prob = 0.5},
    }

    Toggle: affConfigV3.enabled = true/false
]]--

-- ============================================
-- DATA STRUCTURES
-- ============================================

-- Primary state table: list of possible world states with probabilities
afflictionStatesV3 = afflictionStatesV3 or {
    {affs = {}, prob = 1.0}  -- Start with empty state at 100%
}

-- Configuration
affConfigV3 = affConfigV3 or {
    enabled = false,
    minProbability = 0.01,  -- Prune branches below 1%
    maxStates = 50,         -- Max branches to track
    debugEcho = true,       -- Show debug messages
}

-- Simple boolean tracking for non-branching affs (limbs, prone, stun, etc.)
simpleAffsV3 = simpleAffsV3 or {}

-- Cache for O(1) probability lookups
-- Updated whenever states change via rebuildCacheV3()
affCacheV3 = affCacheV3 or {}

-- Afflictions that use simple tracking (don't contribute to state explosion)
simpleTrackAffsV3 = {
    -- Limb damage
    "brokenleftleg", "brokenrightleg", "brokenleftarm", "brokenrightarm",
    "damagedleftleg", "damagedrightleg", "damagedleftarm", "damagedrightarm",
    "mangledleftleg", "mangledrightleg", "mangledleftarm", "mangledrightarm",
    "mutilatedleftleg", "mutilatedrightleg", "mutilatedleftarm", "mutilatedrightarm",
    -- Status effects
    "prone", "stun", "unconscious", "sleeping",
    -- Defenses/states
    "blindness", "deafness", "rebounding", "shield",
}

-- Convert to lookup table for O(1) checks
local simpleTrackLookup = {}
for _, aff in ipairs(simpleTrackAffsV3) do
    simpleTrackLookup[aff] = true
end

-- V3 cure tables (fallback if curingTable doesn't have an entry)
curingTableV3 = {
    kelp = {"hypochondria", "parasite", "weariness", "asthma", "healthleech", "clumsiness", "sensitivity"},
    ginseng = {"flushings", "lethargy", "haemophilia", "addiction", "nausea", "scytherus", "darkshade"},
    goldenseal = {"depression", "sandfever", "stupidity", "epilepsy", "dizziness", "dissonance", "shyness", "impatience"},
    ash = {"confusion", "hypersomnia", "hallucinations", "paranoia", "dementia", "crescendo"},
    lobelia = {"recklessness", "vertigo", "spiritburn", "tenderskin", "loneliness", "claustrophobia", "masochism", "agoraphobia"},
    bellwort = {"timeloop", "justice", "retribution", "lovers", "peace", "pacified", "generosity", "indifference", "diminished"},
    bloodroot = {"paralysis", "slickness"},
}

-- V3 smoke cure table (priority order)
-- Smoking cures one of these (in order if multiple present)
smokeCureTableV3 = {"aeon", "deadening", "hellsight", "tension", "disloyalty", "manaleech", "slickness"}

-- V3 salve cure tables (by body part)
-- Applying salve always proves slickness absent, then cures one affliction from the list
-- Slickness excluded since it's handled by collapse
salveCureTableV3 = {
    body = {"anorexia", "itching", "bloodfire", "selarnia", "frostbite"},
    skin = {"frozen", "shivering", "nocaloric", "bloodfire", "selarnia", "frostbite"},
    head = {"crushedthroat", "damagedhead", "mangledhead", "blindness", "scalded", "epidermal", "bloodfire"},
    torso = {"hypothermia", "bloodfire", "selarnia", "frostbite"},
    limbs = {"bloodfire"},
}

-- Helper to get curable afflictions for a herb
local function getCurableAffs(herb)
    -- Check main curingTable first
    if curingTable and curingTable[herb] then
        return curingTable[herb]
    end
    -- Fall back to V3 table
    if curingTableV3[herb] then
        return curingTableV3[herb]
    end
    -- Fall back to V2 cure lists
    local v2List = _G[herb .. "CurableAffsV2"]
    if v2List then
        return v2List
    end
    return nil
end

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

-- Shallow copy a table (sufficient for flat affliction sets)
local function copyAffs(affs)
    local copy = {}
    for k, v in pairs(affs) do
        copy[k] = v
    end
    return copy
end

-- Create a unique hash for an affliction set (for deduplication)
function hashAffsV3(affs)
    local sorted = {}
    for aff in pairs(affs) do
        table.insert(sorted, aff)
    end
    table.sort(sorted)
    return table.concat(sorted, "|")
end

-- Echo helper
local function v3Echo(msg)
    if affConfigV3.debugEcho and ataxiaEcho then
        ataxiaEcho("[V3] " .. msg)
    end
end

-- ============================================
-- CORE OPERATIONS
-- ============================================

-- Add affliction to ALL branches (we definitely inflicted it)
function applyAffV3(aff)
    if not affConfigV3.enabled then return end

    -- Check if this is a simple-tracked affliction
    if simpleTrackLookup[aff] then
        simpleAffsV3[aff] = true
        syncToOldSystemV3()
        raiseEvent("tar afflicted", {aff})
        return
    end

    -- Add to all branches
    for _, state in ipairs(afflictionStatesV3) do
        state.affs[aff] = true
    end
    deduplicateStatesV3()
    rebuildCacheV3()
    syncToOldSystemV3()
    raiseEvent("tar afflicted", {aff})
    updateAffDisplayV3()
end

-- Remove affliction from ALL branches (definite cure - we saw the message)
function removeAffV3(aff)
    if not affConfigV3.enabled then return end

    -- Check simple tracking
    if simpleTrackLookup[aff] then
        simpleAffsV3[aff] = nil
        syncToOldSystemV3()
        raiseEvent("target cured aff", aff)
        return
    end

    -- Remove from all branches
    for _, state in ipairs(afflictionStatesV3) do
        state.affs[aff] = nil
    end
    deduplicateStatesV3()
    rebuildCacheV3()
    syncToOldSystemV3()
    raiseEvent("target cured aff", aff)
    updateAffDisplayV3()
end

-- ============================================
-- BRANCHING (Ambiguous Cure Handler)
-- ============================================

-- Handle herb cure - this is where branching happens
function onHerbCureV3(herb)
    if not affConfigV3.enabled then return end

    -- Get the list of afflictions this herb can cure
    local curableAffs = getCurableAffs(herb)
    if not curableAffs then
        v3Echo(herb .. " eaten - no cure table found")
        return
    end

    local newStates = {}
    local branchCount = 0
    local curedAffs = {}  -- Track unique afflictions that were definitely cured
    local branchedAffs = {}  -- Track unique afflictions that were candidates in branching

    for _, state in ipairs(afflictionStatesV3) do
        -- Find which curable afflictions exist in this branch
        local candidates = {}
        for _, aff in ipairs(curableAffs) do
            if state.affs[aff] then
                table.insert(candidates, aff)
            end
        end

        if #candidates == 0 then
            -- No curable affs in this branch - state unchanged
            table.insert(newStates, state)
        elseif #candidates == 1 then
            -- Only one candidate - definitely cured
            state.affs[candidates[1]] = nil
            table.insert(newStates, state)
            curedAffs[candidates[1]] = true  -- Track it, don't echo yet
        else
            -- Multiple candidates - BRANCH into N possibilities
            local probEach = state.prob / #candidates
            for _, aff in ipairs(candidates) do
                local branch = {affs = copyAffs(state.affs), prob = probEach}
                branch.affs[aff] = nil
                table.insert(newStates, branch)
                branchedAffs[aff] = true  -- Track branched candidates
            end
            branchCount = branchCount + #candidates - 1
        end
    end

    afflictionStatesV3 = newStates
    deduplicateStatesV3()
    pruneStatesV3()
    rebuildCacheV3()
    syncToOldSystemV3()
    updateAffDisplayV3()

    -- Print consolidated summary
    local curedList = {}
    for aff, _ in pairs(curedAffs) do
        table.insert(curedList, aff)
    end

    local branchedList = {}
    for aff, _ in pairs(branchedAffs) do
        table.insert(branchedList, aff)
    end

    if branchCount > 0 then
        v3Echo(herb .. " eaten - branched into " .. #afflictionStatesV3 .. " states")
        v3Echo(herb .. " cured: " .. table.concat(branchedList, ", "))
    elseif #curedList > 0 then
        v3Echo(herb .. " cured: " .. table.concat(curedList, ", "))
    end
end

-- Handle smoke cure - similar to herb cure but uses smoke cure table
-- Also proves asthma is absent (can't smoke with asthma)
function onSmokeCureV3()
    if not affConfigV3.enabled then return end

    -- First, prove asthma is absent (can't smoke with asthma)
    collapseAffAbsentV3("asthma")

    -- Get the list of smoke-curable afflictions
    local curableAffs = smokeCureTableV3
    if not curableAffs then
        v3Echo("smoked - no smoke cure table found")
        return
    end

    local newStates = {}
    local branchCount = 0
    local curedAffs = {}  -- Track unique afflictions that were cured

    for _, state in ipairs(afflictionStatesV3) do
        -- Find which smoke-curable afflictions exist in this branch
        local candidates = {}
        for _, aff in ipairs(curableAffs) do
            if state.affs[aff] then
                table.insert(candidates, aff)
            end
        end

        if #candidates == 0 then
            -- No smoke-curable affs in this branch - state unchanged
            table.insert(newStates, state)
        elseif #candidates == 1 then
            -- Only one candidate - definitely cured
            state.affs[candidates[1]] = nil
            table.insert(newStates, state)
            curedAffs[candidates[1]] = true  -- Track it, don't echo yet
        else
            -- Multiple candidates - BRANCH into N possibilities
            local probEach = state.prob / #candidates
            for _, aff in ipairs(candidates) do
                local branch = {affs = copyAffs(state.affs), prob = probEach}
                branch.affs[aff] = nil
                table.insert(newStates, branch)
            end
            branchCount = branchCount + #candidates - 1
        end
    end

    afflictionStatesV3 = newStates
    deduplicateStatesV3()
    pruneStatesV3()
    rebuildCacheV3()
    syncToOldSystemV3()
    updateAffDisplayV3()

    -- Print consolidated summary
    local curedList = {}
    for aff, _ in pairs(curedAffs) do
        table.insert(curedList, aff)
    end

    if branchCount > 0 then
        v3Echo("smoked - branched into " .. #afflictionStatesV3 .. " states")
    elseif #curedList > 0 then
        v3Echo("smoke cured: " .. table.concat(curedList, ", "))
    end
end

-- Handle salve cure - proves slickness absent, then branches for salve-curable affs
-- salveType: "body", "skin", "head", "torso", "limbs"
function onSalveCureV3(salveType)
    if not affConfigV3.enabled then return end

    -- Applying salve proves slickness is absent
    collapseAffAbsentV3("slickness")

    -- Get the cure list for this salve type
    local curableAffs = salveCureTableV3[salveType]
    if not curableAffs then
        v3Echo(salveType .. " salve applied - no cure table found")
        return
    end

    local newStates = {}
    local branchCount = 0
    local curedAffs = {}

    for _, state in ipairs(afflictionStatesV3) do
        -- Find which salve-curable afflictions exist in this branch
        local candidates = {}
        for _, aff in ipairs(curableAffs) do
            if state.affs[aff] then
                table.insert(candidates, aff)
            elseif simpleAffsV3[aff] then
                table.insert(candidates, aff)
            end
        end

        if #candidates == 0 then
            -- No curable affs in this branch - state unchanged
            table.insert(newStates, state)
        elseif #candidates == 1 then
            -- Only one candidate - definitely cured
            if simpleTrackLookup[candidates[1]] then
                simpleAffsV3[candidates[1]] = nil
            else
                state.affs[candidates[1]] = nil
            end
            table.insert(newStates, state)
            curedAffs[candidates[1]] = true
        else
            -- Multiple candidates - BRANCH into N possibilities
            local probEach = state.prob / #candidates
            for _, aff in ipairs(candidates) do
                local branch = {affs = copyAffs(state.affs), prob = probEach}
                if simpleTrackLookup[aff] then
                    -- Simple-tracked affs handled outside branching
                    -- For now, just remove from this branch possibility
                else
                    branch.affs[aff] = nil
                end
                table.insert(newStates, branch)
            end
            branchCount = branchCount + #candidates - 1
        end
    end

    afflictionStatesV3 = newStates
    deduplicateStatesV3()
    pruneStatesV3()
    rebuildCacheV3()
    syncToOldSystemV3()
    updateAffDisplayV3()

    -- Print consolidated summary
    local curedList = {}
    for aff, _ in pairs(curedAffs) do
        table.insert(curedList, aff)
    end

    if branchCount > 0 then
        v3Echo(salveType .. " salve - branched into " .. #afflictionStatesV3 .. " states")
    elseif #curedList > 0 then
        v3Echo(salveType .. " salve cured: " .. table.concat(curedList, ", "))
    end
end

-- ============================================
-- COLLAPSING (Verification Signals)
-- ============================================

-- Collapse branches where affliction is PRESENT (e.g., smoke proves no asthma)
function collapseAffAbsentV3(aff)
    if not affConfigV3.enabled then return end

    local surviving = {}
    local totalProb = 0
    local collapsed = 0

    for _, state in ipairs(afflictionStatesV3) do
        if not state.affs[aff] then
            table.insert(surviving, state)
            totalProb = totalProb + state.prob
        else
            collapsed = collapsed + 1
        end
    end

    -- Renormalize surviving branches
    if totalProb > 0 and #surviving > 0 then
        for _, state in ipairs(surviving) do
            state.prob = state.prob / totalProb
        end
        afflictionStatesV3 = surviving
        rebuildCacheV3()
        syncToOldSystemV3()
        updateAffDisplayV3()

        if collapsed > 0 then
            v3Echo("Collapsed " .. collapsed .. " branches (proved " .. aff .. " absent)")
        end
    elseif totalProb == 0 then
        -- Contradiction! All branches had the affliction, but signal proves it's absent
        -- This means our tracking was wrong - reset to single state without this aff
        v3Echo("WARNING: Contradiction detected for " .. aff .. " - resetting")
        afflictionStatesV3 = {{affs = {}, prob = 1.0}}
        rebuildCacheV3()
        syncToOldSystemV3()
        updateAffDisplayV3()
    end
end

-- Collapse branches where affliction is ABSENT (e.g., fumble proves clumsiness present)
function collapseAffPresentV3(aff)
    if not affConfigV3.enabled then return end

    local surviving = {}
    local totalProb = 0
    local collapsed = 0

    for _, state in ipairs(afflictionStatesV3) do
        if state.affs[aff] then
            table.insert(surviving, state)
            totalProb = totalProb + state.prob
        else
            collapsed = collapsed + 1
        end
    end

    -- Renormalize surviving branches
    if totalProb > 0 and #surviving > 0 then
        for _, state in ipairs(surviving) do
            state.prob = state.prob / totalProb
        end
        afflictionStatesV3 = surviving
        rebuildCacheV3()
        syncToOldSystemV3()
        updateAffDisplayV3()

        if collapsed > 0 then
            v3Echo("Collapsed " .. collapsed .. " branches (proved " .. aff .. " present)")
        end
    elseif totalProb == 0 then
        -- Contradiction! No branches had the affliction, but signal proves it's present
        -- Add it to all surviving states (or create new state)
        v3Echo("WARNING: Contradiction detected for " .. aff .. " - adding to all branches")
        for _, state in ipairs(afflictionStatesV3) do
            state.affs[aff] = true
        end
        rebuildCacheV3()
        syncToOldSystemV3()
        updateAffDisplayV3()
    end
end

-- ============================================
-- QUERIES
-- ============================================

-- Get the probability that target has a specific affliction (O(1) via cache)
function getAffProbabilityV3(aff)
    -- Check simple tracking first
    if simpleAffsV3[aff] then return 1.0 end

    -- O(1) cache lookup
    return affCacheV3[aff] or 0
end

-- Check if target has affliction (with probability threshold)
function haveAffV3(aff, threshold)
    threshold = threshold or 0.3  -- Default: 30% probability
    return getAffProbabilityV3(aff) >= threshold
end

-- Get probability that target has ALL listed afflictions
function getStateProbabilityV3(affList)
    local prob = 0
    for _, state in ipairs(afflictionStatesV3) do
        local hasAll = true
        for _, aff in ipairs(affList) do
            if not state.affs[aff] and not simpleAffsV3[aff] then
                hasAll = false
                break
            end
        end
        if hasAll then
            prob = prob + state.prob
        end
    end
    return prob
end

-- Get the most likely state (highest probability branch)
function getMostLikelyStateV3()
    local best = nil
    local bestProb = 0
    for _, state in ipairs(afflictionStatesV3) do
        if state.prob > bestProb then
            best = state
            bestProb = state.prob
        end
    end
    return best, bestProb
end

-- Get list of all tracked afflictions with their probabilities
function getAllAffProbabilitiesV3()
    local result = {}

    -- Copy from cache (O(n) where n = unique afflictions, not branches)
    for aff, prob in pairs(affCacheV3) do
        result[aff] = prob
    end

    -- Add simple-tracked afflictions
    for aff in pairs(simpleAffsV3) do
        result[aff] = 1.0
    end

    return result
end

-- ============================================
-- HOUSEKEEPING
-- ============================================

-- Merge states with identical affliction sets
function deduplicateStatesV3()
    local map = {}
    local result = {}

    for _, state in ipairs(afflictionStatesV3) do
        local hash = hashAffsV3(state.affs)
        if map[hash] then
            -- Merge: add probabilities
            map[hash].prob = map[hash].prob + state.prob
        else
            map[hash] = state
            table.insert(result, state)
        end
    end

    afflictionStatesV3 = result
end

-- Remove low-probability states and redistribute probability
function pruneStatesV3()
    local kept = {}
    local prunedProb = 0

    for _, state in ipairs(afflictionStatesV3) do
        if state.prob >= affConfigV3.minProbability then
            table.insert(kept, state)
        else
            prunedProb = prunedProb + state.prob
        end
    end

    -- Redistribute pruned probability proportionally
    if prunedProb > 0 and #kept > 0 then
        local scale = 1.0 / (1.0 - prunedProb)
        for _, state in ipairs(kept) do
            state.prob = state.prob * scale
        end
        v3Echo("Pruned " .. (#afflictionStatesV3 - #kept) .. " low-probability branches")
    end

    -- Enforce max states limit
    if #kept > affConfigV3.maxStates then
        table.sort(kept, function(a, b) return a.prob > b.prob end)
        local overflow = {}
        local overflowProb = 0
        for i = affConfigV3.maxStates + 1, #kept do
            overflowProb = overflowProb + kept[i].prob
            table.insert(overflow, kept[i])
        end

        kept = {unpack(kept, 1, affConfigV3.maxStates)}

        -- Redistribute overflow probability
        if overflowProb > 0 then
            local scale = 1.0 / (1.0 - overflowProb)
            for _, state in ipairs(kept) do
                state.prob = state.prob * scale
            end
        end
        v3Echo("Enforced max " .. affConfigV3.maxStates .. " states")
    end

    afflictionStatesV3 = kept

    -- Ensure we always have at least one state
    if #afflictionStatesV3 == 0 then
        afflictionStatesV3 = {{affs = {}, prob = 1.0}}
    end
end

-- Reset to clean slate (e.g., target changed)
function resetStatesV3()
    afflictionStatesV3 = {{affs = {}, prob = 1.0}}
    simpleAffsV3 = {}
    affCacheV3 = {}
    syncToOldSystemV3()
    v3Echo("States reset")
end

-- Rebuild the cache from current states
-- Called after any state-modifying operation for O(1) lookups
function rebuildCacheV3()
    affCacheV3 = {}

    -- Sum probabilities for each affliction across all states
    for _, state in ipairs(afflictionStatesV3) do
        for aff in pairs(state.affs) do
            affCacheV3[aff] = (affCacheV3[aff] or 0) + state.prob
        end
    end
end

-- ============================================
-- BACKWARD COMPATIBILITY
-- ============================================

-- Sync V3 state to old tAffs system for backward compatibility
-- Only SET entries when confident (>= 30%), only CLEAR when essentially absent (< 1%)
-- Intermediate probabilities (1-30%) leave V1/V2 unchanged to prevent desync
function syncToOldSystemV3()
    if not tAffs then return end

    local allProbs = getAllAffProbabilitiesV3()
    for aff, prob in pairs(allProbs) do
        if prob >= 0.3 then
            tAffs[aff] = true
        elseif prob < 0.01 then
            tAffs[aff] = false
        end
    end

    if tAffsV2 and ataxia and ataxia.settings then
        for aff, prob in pairs(allProbs) do
            if prob >= 0.3 then
                tAffsV2[aff] = true
            elseif prob < 0.01 then
                tAffsV2[aff] = nil
            end
        end
    end
end

-- Update affliction display
function updateAffDisplayV3()
    -- Update displays (reuse V2's display logic if available)
    if updateAffDisplayV2 then
        updateAffDisplayV2()
    elseif zgui and zgui.showTarAffs then
        zgui.showTarAffs()
    end
end

-- ============================================
-- DEBUG / DISPLAY
-- ============================================

-- Show current branches (debug)
function showBranchesV3()
    echo("\n=== Affliction Tracking V3 State ===\n")
    echo("Enabled: " .. tostring(affConfigV3.enabled) .. "\n")
    echo("Branches: " .. #afflictionStatesV3 .. "\n\n")

    for i, state in ipairs(afflictionStatesV3) do
        local affs = {}
        for aff in pairs(state.affs) do
            table.insert(affs, aff)
        end
        table.sort(affs)
        local affStr = #affs > 0 and table.concat(affs, ", ") or "(empty)"
        echo(string.format("  %d: {%s} @ %.1f%%\n", i, affStr, state.prob * 100))
    end

    if next(simpleAffsV3) then
        echo("\nSimple-tracked:\n")
        for aff in pairs(simpleAffsV3) do
            echo("  " .. aff .. "\n")
        end
    end
end

-- Show probability summary
function showAffProbsV3()
    echo("\n=== Affliction Probabilities ===\n")
    local probs = getAllAffProbabilitiesV3()
    local sorted = {}
    for aff, prob in pairs(probs) do
        table.insert(sorted, {aff = aff, prob = prob})
    end
    table.sort(sorted, function(a, b) return a.prob > b.prob end)

    for _, entry in ipairs(sorted) do
        echo(string.format("  %s: %.1f%%\n", entry.aff, entry.prob * 100))
    end

    if #sorted == 0 then
        echo("  (no afflictions tracked)\n")
    end
end

-- ============================================
-- EVENT HANDLERS
-- ============================================

-- Reset on target change
registerAnonymousEventHandler("ataxia target changed", function()
    if affConfigV3.enabled then
        resetStatesV3()
    end
end)

-- Sync from old system when afflictions applied via tarAffed()
registerAnonymousEventHandler("tar afflicted", function(event, affList)
    if not affConfigV3.enabled then return end
    if not affList or type(affList) ~= "table" then return end

    for _, aff in pairs(affList) do
        if type(aff) == "string" then
            -- Only add if not already tracked (avoid double-adding)
            if getAffProbabilityV3(aff) < 0.5 then
                applyAffV3(aff)
            end
        end
    end
end)
