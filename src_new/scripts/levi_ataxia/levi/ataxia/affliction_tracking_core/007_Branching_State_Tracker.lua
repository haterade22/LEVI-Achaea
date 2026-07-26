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
    enabled = true,
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

-- Burning level tracking (1-5, 0 = not burning)
-- Mending body only cures burning at level 1; higher levels persist through body cure
targetBurningLevelV3 = targetBurningLevelV3 or 0

-- Venom expansion: compound venoms that apply multiple constituent afflictions
-- Note: epseth/epteth removed — they break a SINGLE limb (determined by game
-- output), so limb damage triggers handle them directly, not venom expansion.
local venomExpansionV3 = {
    sicken = {"manaleech", "slickness"},
}

-- Affliction last-confirmed timestamps for staleness pruning
affLastConfirmedV3 = affLastConfirmedV3 or {}

-- Target defense tracking (caloric, rebounding, shield, insomnia, etc.)
targetDefensesV3 = targetDefensesV3 or {}

-- V3 cure tables (fallback if curingTable doesn't have an entry)
curingTableV3 = {
    kelp = {"parasite", "weariness", "asthma", "healthleech", "clumsiness", "sensitivity", "rebbies"},
    ginseng = {"flushings", "lethargy", "haemophilia", "addiction", "nausea", "scytherus", "darkshade"},
    goldenseal = {"depression", "sandfever", "stupidity", "epilepsy", "dizziness", "dissonance", "shyness", "impatience", "fulminated"},
    ash = {"confusion", "hypersomnia", "hallucinations", "paranoia", "dementia", "crescendo"},
    lobelia = {"fratricide", "recklessness", "vertigo", "spiritburn", "tenderskin", "loneliness", "claustrophobia", "masochism", "agoraphobia", "guilt", "horror", "hypochondria"},
    bellwort = {"timeloop", "justice", "retribution", "lovers", "peace", "pacified", "generosity", "indifference", "diminished", "pyre"},
    bloodroot = {"paralysis", "slickness"},
}

-- V3 smoke cure table (priority order)
-- Smoking cures one of these (in order if multiple present)
smokeCureTableV3 = {"aeon", "deadening", "hellsight", "tension", "disloyalty", "manaleech", "slickness", "unweavingspirit"}

-- V3 salve cure tables (by body part)
-- Applying salve always proves slickness absent, then cures one affliction from the list
-- Slickness excluded since it's handled by collapse
salveCureTableV3 = {
    body = {"anorexia", "itching", "burning", "bloodfire", "selarnia", "frostbite"},
    skin = {"frozen", "shivering", "nocaloric", "bloodfire", "selarnia", "frostbite"},
    head = {"crushedthroat", "stuttering", "damagedhead", "mangledhead", "blindness", "scalded", "epidermal", "bloodfire"},
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

-- Compute SSC priority weights for cure candidates
-- SSC cures in strict priority order: first match in cure list is ALWAYS cured first.
-- We model this with a decay: 1st=4, 2nd=2, 3rd+=1, then normalize to sum to 1.0
local function computeCureWeightsV3(numCandidates)
    local weights = {}
    local total = 0
    for i = 1, numCandidates do
        local w
        if i == 1 then w = 4
        elseif i == 2 then w = 2
        else w = 1
        end
        weights[i] = w
        total = total + w
    end
    -- Normalize
    for i = 1, numCandidates do
        weights[i] = weights[i] / total
    end
    return weights
end

-- ============================================
-- CORE OPERATIONS
-- ============================================

-- Add affliction to ALL branches (we definitely inflicted it)
function applyAffV3(aff)
    if not aff then return end

    -- Venom expansion: compound venoms apply all constituent afflictions
    local expansion = expandVenomV3(aff)
    if expansion then
        for _, constituentAff in ipairs(expansion) do
            applyAffV3(constituentAff)
        end
        return
    end

    -- Frozen/caloric/shivering interaction chain
    if aff == "frozen" then
        applyFrozenInteractionV3()
        return
    end

    -- Burning level tracking (increment on each application, cap at 5)
    if aff == "burning" then
        targetBurningLevelV3 = math.min(targetBurningLevelV3 + 1, 5)
    end

    -- Affliction-defense interactions
    if aff == "sensitivity" then setTargetDefenseV3("deafness", false) end
    if aff == "transfixation" then setTargetDefenseV3("blindness", false) end
    if aff == "sleep" then setTargetDefenseV3("insomnia", false) end

    -- Check if this is a simple-tracked affliction
    if simpleTrackLookup[aff] then
        simpleAffsV3[aff] = true
        syncToOldSystemV3()
        return
    end

    -- Add to all branches
    for _, state in ipairs(afflictionStatesV3) do
        state.affs[aff] = true
    end

    -- Update last-confirmed timestamp
    affLastConfirmedV3[aff] = getEpoch()

    deduplicateStatesV3()
    rebuildCacheV3()
    syncToOldSystemV3()
    updateAffDisplayV3()
end

-- Expand compound venoms to constituent afflictions
-- Returns expansion table or nil if not a compound venom
function expandVenomV3(venom)
    return venomExpansionV3[venom]
end

-- Frozen/caloric/shivering interaction chain
-- If target has caloric defense: frozen strips caloric (don't add frozen)
-- If target doesn't have caloric: add shivering first time, frozen second time
function applyFrozenInteractionV3()
    if hasTargetDefenseV3("caloric") then
        -- Frozen strips caloric defense, doesn't actually apply frozen
        setTargetDefenseV3("caloric", false)
        v3Echo("Frozen stripped caloric defense")
        return
    end

    -- No caloric: shivering first, then frozen
    local hasShivering = getAffProbabilityV3("shivering") >= 0.3
    if not hasShivering then
        -- First application without caloric: apply shivering
        for _, state in ipairs(afflictionStatesV3) do
            state.affs["shivering"] = true
        end
        affLastConfirmedV3["shivering"] = getEpoch()
        v3Echo("Applied shivering (no caloric)")
    else
        -- Already shivering: apply frozen
        for _, state in ipairs(afflictionStatesV3) do
            state.affs["frozen"] = true
        end
        affLastConfirmedV3["frozen"] = getEpoch()
        v3Echo("Applied frozen (already shivering)")
    end

    deduplicateStatesV3()
    rebuildCacheV3()
    syncToOldSystemV3()
    updateAffDisplayV3()
end

-- Get current burning level (0-5)
function getBurningLevelV3()
    return targetBurningLevelV3
end

-- Reset burning level to 0
function resetBurningLevelV3()
    targetBurningLevelV3 = 0
end

-- Target defense tracking
function setTargetDefenseV3(defense, active)
    targetDefensesV3[defense] = active and true or nil
    -- Note: rebounding, shield, and curseward are independent defenses in Achaea.
    -- Stripping one does NOT strip the others.
end

function hasTargetDefenseV3(defense)
    return targetDefensesV3[defense] == true
end

function resetTargetDefensesV3()
    targetDefensesV3 = {}
end

-- Remove affliction from ALL branches (definite cure - we saw the message)
function removeAffV3(aff)
    if not aff then return end
    -- Check simple tracking
    if simpleTrackLookup[aff] then
        simpleAffsV3[aff] = nil
        syncToOldSystemV3()
        return
    end

    -- Remove from all branches
    for _, state in ipairs(afflictionStatesV3) do
        state.affs[aff] = nil
    end
    deduplicateStatesV3()
    rebuildCacheV3()
    syncToOldSystemV3()
    updateAffDisplayV3()
end

-- ============================================
-- BRANCHING (Ambiguous Cure Handler)
-- ============================================

-- Handle herb cure - this is where branching happens
function onHerbCureV3(herb)

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
            -- Multiple candidates - BRANCH with SSC priority weighting
            -- SSC cures the first affliction in the cure list that's present,
            -- so the highest priority candidate gets much higher probability
            local weights = computeCureWeightsV3(#candidates)
            for idx, aff in ipairs(candidates) do
                local branch = {affs = copyAffs(state.affs), prob = state.prob * weights[idx]}
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
        -- Start negative confirmation for ambiguous cure
        startNegativeConfirmV3("herb", branchedList)
    elseif #curedList > 0 then
        v3Echo(herb .. " cured: " .. table.concat(curedList, ", "))
        -- Definite cure during neg-confirm window = guess was reasonable
        onCureDuringNegativeConfirmV3()
    end

    -- Track target's herb cure balance
    startCureBalanceV3("herb")
end

-- Handle smoke cure - similar to herb cure but uses smoke cure table
-- Also proves asthma is absent (can't smoke with asthma)
function onSmokeCureV3()

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
    local curedAffs = {}  -- Track unique afflictions that were definitely cured
    local branchedAffs = {}  -- Track unique afflictions that were candidates in branching

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
            curedAffs[candidates[1]] = true
        else
            -- Multiple candidates - BRANCH with SSC priority weighting
            local weights = computeCureWeightsV3(#candidates)
            for i, aff in ipairs(candidates) do
                local branch = {affs = copyAffs(state.affs), prob = state.prob * weights[i]}
                branch.affs[aff] = nil
                table.insert(newStates, branch)
                branchedAffs[aff] = true
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
        v3Echo("smoked - branched into " .. #afflictionStatesV3 .. " states")
        startNegativeConfirmV3("smoke", branchedList)
    elseif #curedList > 0 then
        v3Echo("smoke cured: " .. table.concat(curedList, ", "))
        onCureDuringNegativeConfirmV3()
    end

    -- Track target's pipe smoke balance
    startCureBalanceV3("pipe")
end

-- Handle salve cure - proves slickness absent, then branches for salve-curable affs
-- salveType: "body", "skin", "head", "torso", "limbs"
function onSalveCureV3(salveType)

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
    local branchedAffs = {}

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

        -- SSC anorexia priority: body mending cures anorexia (via epidermal) first
        -- before other mending-body afflictions like burning/itching/selarnia
        if salveType == "body" and #candidates > 1 then
            for _, aff in ipairs(candidates) do
                if aff == "anorexia" then
                    candidates = {"anorexia"}
                    break
                end
            end
        end

        -- Burning level interaction: mending body only cures burning at level 1
        -- At level 2+, burning persists through body cure (remove from candidates)
        if salveType == "body" and targetBurningLevelV3 > 1 then
            local filtered = {}
            for _, aff in ipairs(candidates) do
                if aff ~= "burning" then
                    table.insert(filtered, aff)
                end
            end
            candidates = filtered
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
            -- If burning was cured via body salve, reset burning level
            if candidates[1] == "burning" and salveType == "body" then
                resetBurningLevelV3()
            end
            table.insert(newStates, state)
            curedAffs[candidates[1]] = true
        else
            -- Multiple candidates - BRANCH with SSC priority weighting
            local weights = computeCureWeightsV3(#candidates)
            for idx, aff in ipairs(candidates) do
                local branch = {affs = copyAffs(state.affs), prob = state.prob * weights[idx]}
                if simpleTrackLookup[aff] then
                    -- Simple-tracked affs: remove from simpleAffsV3 in this branch
                    -- (conservative: treat as cured since SSC prioritizes it)
                    simpleAffsV3[aff] = nil
                else
                    branch.affs[aff] = nil
                end
                table.insert(newStates, branch)
                branchedAffs[aff] = true
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
        v3Echo(salveType .. " salve - branched into " .. #afflictionStatesV3 .. " states")
        startNegativeConfirmV3("salve", branchedList)
    elseif #curedList > 0 then
        v3Echo(salveType .. " salve cured: " .. table.concat(curedList, ", "))
        onCureDuringNegativeConfirmV3()
    end

    -- Track target's salve balance (scalded check happens inside)
    startCureBalanceV3("salve")
end

-- ============================================
-- COLLAPSING (Verification Signals)
-- ============================================

-- Collapse branches where affliction is PRESENT (e.g., smoke proves no asthma)
function collapseAffAbsentV3(aff)

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
    resetBurningLevelV3()
    resetAffTimestampsV3()
    resetTargetDefensesV3()
    resetPassiveCooldownsV3()
    if resetCureBalancesV3 then resetCureBalancesV3() end
    if killNegativeConfirmV3 then killNegativeConfirmV3() end
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
-- AFFLICTION DECAY / TIMEOUT
-- ============================================

-- Reset all affliction timestamps
function resetAffTimestampsV3()
    affLastConfirmedV3 = {}
end

-- Prune stale unconfirmed low-probability afflictions
-- Removes afflictions from branches if they haven't been confirmed in 60 seconds
-- AND their probability is below 0.3
-- NOTE: This should be called from a periodic timer (e.g., every 10-15s)
function pruneStaleAffsV3()
    local now = getEpoch()
    local staleThreshold = 60  -- seconds
    local probThreshold = 0.3
    local pruned = {}

    -- Find stale afflictions in the cache
    for aff, prob in pairs(affCacheV3) do
        if prob < probThreshold then
            local lastConfirmed = affLastConfirmedV3[aff]
            if not lastConfirmed or (now - lastConfirmed) > staleThreshold then
                pruned[aff] = true
            end
        end
    end

    if not next(pruned) then return end

    -- Remove stale afflictions from all branches
    for _, state in ipairs(afflictionStatesV3) do
        for aff in pairs(pruned) do
            state.affs[aff] = nil
        end
    end

    -- Clean up timestamps
    for aff in pairs(pruned) do
        affLastConfirmedV3[aff] = nil
    end

    deduplicateStatesV3()
    rebuildCacheV3()
    syncToOldSystemV3()
    updateAffDisplayV3()

    local prunedList = {}
    for aff in pairs(pruned) do
        table.insert(prunedList, aff)
    end
    v3Echo("Pruned stale affs: " .. table.concat(prunedList, ", "))
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

    -- V2 removed: tAffsV2 sync no longer needed (V3 is sole source of truth)
end

-- Update affliction display
function updateAffDisplayV3()
    if zgui and zgui.showTarAffs then
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
-- CURE GROUP COUNTING API
-- ============================================

-- Predefined cure groups for querying across branches
cureGroupsV3 = {
    mending_body = {"anorexia", "itching", "burning", "bloodfire", "selarnia", "frostbite"},
    mending_skin = {"frozen", "shivering", "frostbite"},
    mending_head = {"crushedthroat", "stuttering"},
    mending_arm = {"brokenleftarm", "brokenrightarm"},
    mending_leg = {"brokenleftleg", "brokenrightleg"},
    mending_all = {
        "anorexia", "itching", "burning", "bloodfire", "selarnia", "frostbite",
        "frozen", "shivering",
        "crushedthroat", "stuttering",
        "brokenleftarm", "brokenrightarm", "brokenleftleg", "brokenrightleg",
    },
    herb_kelp = {"clumsiness", "healthleech", "weariness", "asthma", "sensitivity", "parasite"},
    herb_ginseng = {"nausea", "haemophilia", "addiction", "darkshade", "flushings", "lethargy", "scytherus"},
    herb_goldenseal = {"stupidity", "impatience", "depression", "sandfever", "epilepsy", "dizziness", "dissonance", "shyness"},
    herb_lobelia = {"recklessness", "vertigo", "spiritburn", "tenderskin", "loneliness", "claustrophobia", "masochism", "agoraphobia", "hypochondria"},
    herb_ash = {"confusion", "hypersomnia", "hallucinations", "paranoia", "dementia", "crescendo"},
    herb_bellwort = {"timeloop", "justice", "retribution", "lovers", "peace", "pacified", "generosity", "indifference", "diminished"},
    herb_bloodroot = {"paralysis", "slickness"},
    smoke = {"aeon", "deadening", "hellsight", "tension", "disloyalty", "manaleech", "slickness", "unweavingspirit"},
}

-- Count what fraction of branches have >= minCount afflictions from a group
-- groupOrName: string (key into cureGroupsV3) or table of affliction names
-- minCount: minimum number of affs from group to count (default 1)
-- Returns: probability 0.0 to 1.0
function countGroupAffsV3(groupOrName, minCount)
    minCount = minCount or 1

    local affList = groupOrName
    if type(groupOrName) == "string" then
        affList = cureGroupsV3[groupOrName]
        if not affList then
            v3Echo("Unknown cure group: " .. groupOrName)
            return 0
        end
    end

    local totalProb = 0

    for _, state in ipairs(afflictionStatesV3) do
        local count = 0
        for _, aff in ipairs(affList) do
            if state.affs[aff] or simpleAffsV3[aff] then
                count = count + 1
            end
        end
        if count >= minCount then
            totalProb = totalProb + state.prob
        end
    end

    return totalProb
end

-- Get the count of affs from group in the most likely branch
function getMostLikelyGroupAffCountV3(groupOrName)
    local affList = groupOrName
    if type(groupOrName) == "string" then
        affList = cureGroupsV3[groupOrName]
        if not affList then return 0 end
    end

    local best = getMostLikelyStateV3()
    if not best then return 0 end

    local count = 0
    for _, aff in ipairs(affList) do
        if best.affs[aff] or simpleAffsV3[aff] then
            count = count + 1
        end
    end
    return count
end

-- ============================================
-- CURE BALANCE TIMERS
-- ============================================

-- Track when the target can next use each cure type
cureBalancesV3 = cureBalancesV3 or {
    herb = 0,
    pipe = 0,
    salve = 0,
    focus = 0,
    tree = 0,
    restoration = 0,
    writhe = 0,
}

-- Cure balance durations (seconds)
cureBalanceTimingsV3 = {
    herb = 1.3,
    pipe = 1.3,
    salve_normal = 0.8,
    salve_scalded = 1.3,
    focus = 2.2,
    tree = 13.0,
    restoration_normal = 3.8,
    restoration_scalded = 5.8,
    writhe = 1.8,
}

-- Active timers for cleanup
cureBalanceTimerIDsV3 = cureBalanceTimerIDsV3 or {}

-- Per-ability passive cure cooldowns (independent of cure balance timers)
passiveCooldownsV3 = passiveCooldownsV3 or {}

passiveCooldownTimingsV3 = {
    -- 12s cooldowns
    passive_airlord = 12.0,
    passive_healingrite = 12.0,
    passive_syphon = 12.0,
    passive_dagaz = 12.0,
    passive_leech = 12.0,
    passive_accelerate = 12.0,
    passive_alleviate = 12.0,
    passive_bloodboil = 12.0,
    passive_dragonheal = 12.0,
    passive_expunge = 12.0,
    passive_fitness = 12.0,
    passive_might = 12.0,
    passive_purification = 12.0,
    passive_purify = 12.0,
    passive_rage = 12.0,
    passive_salt = 12.0,
    passive_shrugging = 12.0,
    passive_slough = 12.0,
    passive_eruption = 12.0,
    passive_continuation = 12.0,
    passive_root = 12.0,
    passive_priesthealing = 12.0,
    -- 14s cooldowns
    passive_hallelujah = 14.0,
    -- 20s cooldowns
    passive_suntarot = 20.0,
    passive_panacea = 20.0,
    passive_fool = 20.0,
}

function startPassiveCooldownV3(abilityKey)
    local duration = passiveCooldownTimingsV3[abilityKey]
    if not duration then return end
    passiveCooldownsV3[abilityKey] = getEpoch() + duration
end

function canTargetPassiveV3(abilityKey)
    return (passiveCooldownsV3[abilityKey] or 0) <= getEpoch()
end

function getPassiveCooldownTimeV3(abilityKey)
    local remaining = (passiveCooldownsV3[abilityKey] or 0) - getEpoch()
    return math.max(0, remaining)
end

function resetPassiveCooldownsV3()
    passiveCooldownsV3 = {}
end

-- Start a cure balance timer for a specific cure type
function startCureBalanceV3(cureType)
    local duration
    if cureType == "salve" then
        -- Scalded doubles salve balance from 0.8s to 1.3s
        if getAffProbabilityV3 and getAffProbabilityV3("scalded") >= 0.5 then
            duration = cureBalanceTimingsV3.salve_scalded
        else
            duration = cureBalanceTimingsV3.salve_normal
        end
    elseif cureType == "restoration" then
        if getAffProbabilityV3 and getAffProbabilityV3("scalded") >= 0.5 then
            duration = cureBalanceTimingsV3.restoration_scalded
        else
            duration = cureBalanceTimingsV3.restoration_normal
        end
    else
        duration = cureBalanceTimingsV3[cureType]
    end

    if not duration then return end

    cureBalancesV3[cureType] = getEpoch() + duration

    -- Kill old timer if exists
    if cureBalanceTimerIDsV3[cureType] then
        killTimer(cureBalanceTimerIDsV3[cureType])
    end

    cureBalanceTimerIDsV3[cureType] = tempTimer(duration, function()
        cureBalanceTimerIDsV3[cureType] = nil
    end)
end

-- Check if target can use a specific cure type NOW
function canTargetCureV3(cureType)
    return (cureBalancesV3[cureType] or 0) <= getEpoch()
end

-- Get remaining balance time (seconds until cure available)
function getCureBalanceTimeV3(cureType)
    local remaining = (cureBalancesV3[cureType] or 0) - getEpoch()
    return math.max(0, remaining)
end

-- Get all cure balance statuses
function getAllCureBalancesV3()
    return {
        herb = getCureBalanceTimeV3("herb"),
        pipe = getCureBalanceTimeV3("pipe"),
        salve = getCureBalanceTimeV3("salve"),
        focus = getCureBalanceTimeV3("focus"),
        tree = getCureBalanceTimeV3("tree"),
        restoration = getCureBalanceTimeV3("restoration"),
        writhe = getCureBalanceTimeV3("writhe"),
    }
end

-- Reset all cure balances (on target change, death, etc.)
function resetCureBalancesV3()
    for cureType in pairs(cureBalancesV3) do
        cureBalancesV3[cureType] = 0
    end
    for cureType, timerID in pairs(cureBalanceTimerIDsV3) do
        if timerID then killTimer(timerID) end
        cureBalanceTimerIDsV3[cureType] = nil
    end
end

-- ============================================
-- NEGATIVE CONFIRMATION (Backtracking)
-- ============================================

-- Pending guess storage for negative confirmation
-- (not preserved across reload — stale timers cleaned up below)
if lastGuessV3 then
    -- Script reloaded mid-combat: kill orphaned timers
    for _, timerID in pairs(negativeConfirmTimersV3 or {}) do
        if timerID then killTimer(timerID) end
    end
end
lastGuessV3 = nil

-- Active timers for negative confirmation windows
negativeConfirmTimersV3 = negativeConfirmTimersV3 or {}

-- Negative confirmation configuration
affConfigV3.negativeConfirm = affConfigV3.negativeConfirm or {
    enabled = true,
    herbWindow = 1.3,
    smokeWindow = 2.0,
    salveWindow = 2.5,
}

-- Start negative confirmation timer after an ambiguous cure branch
function startNegativeConfirmV3(cureType, candidates)
    if not affConfigV3.negativeConfirm.enabled then return end
    if not candidates or #candidates < 2 then return end

    -- Store guess for negative confirmation
    lastGuessV3 = {
        candidates = candidates,
        cureType = cureType,
        timestamp = getEpoch(),
    }

    -- Determine window based on cure type
    local window = affConfigV3.negativeConfirm.herbWindow
    if cureType == "smoke" then
        window = affConfigV3.negativeConfirm.smokeWindow
    elseif cureType == "salve" then
        window = affConfigV3.negativeConfirm.salveWindow
    end

    local timerKey = cureType .. "_negconf"

    -- Kill old timer if exists
    if negativeConfirmTimersV3[timerKey] then
        killTimer(negativeConfirmTimersV3[timerKey])
    end

    local savedGuess = lastGuessV3
    negativeConfirmTimersV3[timerKey] = tempTimer(window, function()
        onNegativeConfirmExpiredV3(savedGuess)
        negativeConfirmTimersV3[timerKey] = nil
        if lastGuessV3 == savedGuess then
            lastGuessV3 = nil
        end
    end)

    v3Echo("Neg-confirm started: " .. table.concat(candidates, ", ") .. " (" .. window .. "s)")
end

-- Called when target performs another cure during the confirmation window
-- This means our branching was reasonable — kill the timer
function onCureDuringNegativeConfirmV3()
    killNegativeConfirmV3()
end

-- Kill pending negative confirmation (iterates ALL pending timers)
function killNegativeConfirmV3()
    for _, timerID in pairs(negativeConfirmTimersV3) do
        if timerID then killTimer(timerID) end
    end
    negativeConfirmTimersV3 = {}
    lastGuessV3 = nil
end

-- Gating affliction dependencies for intelligent backtracking
-- Only backtrack a gating aff if dependent affs are still tracked in the cache
local gatingDependenciesV3 = {
    -- asthma blocks smoking: only backtrack if smoke-curable affs are tracked
    asthma = {"slickness", "disloyalty", "hellsight", "aeon", "deadening", "tension", "manaleech", "unweavingspirit"},
    -- anorexia blocks eating: only backtrack if herb-curable affs are tracked
    anorexia = function()
        -- Check if any herb-curable aff is tracked
        for _, affList in pairs(curingTableV3) do
            for _, aff in ipairs(affList) do
                if (affCacheV3[aff] or 0) > 0 then return true end
            end
        end
        return false
    end,
    -- slickness blocks applying salves: only backtrack if salve-curable affs are tracked
    slickness = function()
        for _, affList in pairs(salveCureTableV3) do
            for _, aff in ipairs(affList) do
                if (affCacheV3[aff] or 0) > 0 or simpleAffsV3[aff] then return true end
            end
        end
        return false
    end,
}

-- Check if a gating affliction should be backtracked
-- Returns true if the aff should be backtracked, false if it should be skipped
local function shouldBacktrackGatingAffV3(aff)
    local dep = gatingDependenciesV3[aff]
    if not dep then return true end  -- Not a gating aff, always backtrack

    if type(dep) == "function" then
        return dep()
    end

    -- dep is a table of dependent afflictions
    for _, depAff in ipairs(dep) do
        if (affCacheV3[depAff] or 0) > 0 then
            return true  -- Dependent aff exists, backtrack is warranted
        end
    end
    return false  -- No dependent affs, skip backtrack
end

-- Called when negative confirmation window expires (no second cure action)
-- Unfolds the branch: re-adds all candidates with equal probability
function onNegativeConfirmExpiredV3(guess)
    if not guess or not guess.candidates then return end

    v3Echo("Neg-confirm timeout -- unfolding branch for: " .. table.concat(guess.candidates, ", "))

    -- Re-add all candidates across all branches that had them removed
    local newStates = {}

    for _, state in ipairs(afflictionStatesV3) do
        -- Check how many candidates are MISSING from this branch
        local missingCandidates = {}
        for _, aff in ipairs(guess.candidates) do
            if not state.affs[aff] and not simpleAffsV3[aff] then
                table.insert(missingCandidates, aff)
            end
        end

        if #missingCandidates == 0 then
            -- All candidates present -- this branch wasn't affected
            table.insert(newStates, state)
        elseif #missingCandidates == 1 then
            -- Exactly one candidate missing — this is a branch from the guess
            -- Intelligent backtracking: only backtrack gating affs if dependent affs exist
            if shouldBacktrackGatingAffV3(missingCandidates[1]) then
                local unfolded = {affs = copyAffs(state.affs), prob = state.prob}
                unfolded.affs[missingCandidates[1]] = true
                table.insert(newStates, unfolded)
            else
                -- Skip backtrack for this gating aff (no dependent affs)
                table.insert(newStates, state)
                v3Echo("Skipped backtrack for " .. missingCandidates[1] .. " (no dependent affs)")
            end
        else
            -- Multiple missing — keep as-is (not from this guess)
            table.insert(newStates, state)
        end
    end

    afflictionStatesV3 = newStates
    deduplicateStatesV3()
    pruneStatesV3()
    rebuildCacheV3()
    syncToOldSystemV3()
    updateAffDisplayV3()
end

-- ============================================
-- CLASS-SPECIFIC CURE PROCESSING (V3)
-- ============================================

-- Cure specific afflictions deterministically, then N random from pool
-- specificAffs: table of afflictions definitely cured (e.g., {"paralysis"})
-- numRandom: number of additional random afflictions cured (default 0)
function onClassCureV3(specificAffs, numRandom)
    if not specificAffs and not numRandom then return end

    -- Remove specific afflictions deterministically
    -- erAff() handles: tAffs table + removeAffV3() + events + display
    if specificAffs then
        for _, aff in ipairs(specificAffs) do
            erAff(aff)
        end
    end

    -- Handle random cures via existing passive cure handler
    numRandom = numRandom or 0
    if numRandom > 0 then
        if onPassiveCureV3 then
            onPassiveCureV3(numRandom)
        end
    end
end

-- ============================================
-- EVENT HANDLERS
-- ============================================

-- Reset on target change
registerAnonymousEventHandler("changed target", function()
    resetStatesV3()
    resetCureBalancesV3()
    killNegativeConfirmV3()
end)

-- V1→V3 sync listener removed: tarAffed() now calls applyAffV3() directly
