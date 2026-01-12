--[[mudlet
type: script
name: Affliction Tracking V2 - Core
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Combat
- Affliction Tracking V2
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    Affliction Tracking V2 - Core Module

    This module provides certainty-based affliction tracking.
    Runs parallel to the old tAffs system with full backward compatibility.

    Toggle: ataxia.settings.useAffTrackingV2 = true/false
]]--

-- Initialize V2 tracking tables
tAffsV2 = tAffsV2 or {}
affTimersV2 = affTimersV2 or {}

-- Initialize settings
ataxia = ataxia or {}
ataxia.settings = ataxia.settings or {}
ataxia.settings.useAffTrackingV2 = ataxia.settings.useAffTrackingV2 or false

--[[
    Certainty Levels (with stacking support):
    Values are multiples of 2 for stacking:
    2 = 1 confirmed instance
    4 = 2 stacked instances
    6 = 3 stacked instances
    etc.

    Odd values indicate uncertainty:
    1 = 1 likely instance (might be cured)
    3 = 2 instances, 1 uncertain
    etc.

    0 = Absent - Never applied or definitely cured
]]--

-- Random cure counter (tracks tree/focus/passive cures)
randomCuresV2 = 0

-- Sync V2 state to old tAffs for backward compatibility
function syncToOldSystem(aff, certainty)
    if not tAffs then return end
    tAffs[aff] = (certainty >= 1)
    if certainty >= 1 then
        if affTimersV2[aff] then
            affTimers[aff] = affTimersV2[aff]
        end
    else
        affTimers[aff] = nil
    end
end

-- Confirm affliction with high certainty (we applied it)
function confirmAffV2(aff)
    if not ataxia.settings.useAffTrackingV2 then return end

    local oldVal = tAffsV2[aff] or 0
    tAffsV2[aff] = 2
    affTimersV2[aff] = getEpoch()
    syncToOldSystem(aff, 2)

    if oldVal < 1 then
        -- Was absent, now confirmed - raise event
        raiseEvent("tar afflicted", {aff})
        if checkTargetLocks then checkTargetLocks() end
    end
    updateAffDisplayV2()
end

-- Reduce certainty (herb eaten that could cure this)
function uncertainAffV2(aff)
    if not ataxia.settings.useAffTrackingV2 then return end

    if tAffsV2[aff] and tAffsV2[aff] > 0 then
        tAffsV2[aff] = tAffsV2[aff] - 1
        syncToOldSystem(aff, tAffsV2[aff])
        if tAffsV2[aff] == 0 then
            affTimersV2[aff] = nil
            raiseEvent("target cured aff", aff)
        end
    end
    updateAffDisplayV2()
end

-- Definitely remove affliction (exact cure seen)
function removeAffV2(aff)
    if not ataxia.settings.useAffTrackingV2 then return end

    if tAffsV2[aff] and tAffsV2[aff] > 0 then
        tAffsV2[aff] = 0
        affTimersV2[aff] = nil
        syncToOldSystem(aff, 0)
        raiseEvent("target cured aff", aff)
    end
    updateAffDisplayV2()
end

-- Check if target has affliction (certainty >= 1)
function haveAffV2(aff)
    if not ataxia.settings.useAffTrackingV2 then
        return haveAff(aff)  -- Fall back to old system
    end
    return tAffsV2[aff] and tAffsV2[aff] >= 1
end

-- Check if affliction is confirmed (certainty >= 2)
function haveConfirmedAffV2(aff)
    if not ataxia.settings.useAffTrackingV2 then
        return haveAff(aff)  -- Fall back to old system
    end
    return tAffsV2[aff] and tAffsV2[aff] >= 2
end

-- ============================================
-- STACK TRACKING (AK-inspired)
-- ============================================

-- Add a stack of an affliction (increment by 2)
function stackAffV2(aff)
    if not ataxia.settings.useAffTrackingV2 then return end

    local oldVal = tAffsV2[aff] or 0
    tAffsV2[aff] = oldVal + 2
    affTimersV2[aff] = getEpoch()
    syncToOldSystem(aff, tAffsV2[aff])

    if oldVal < 1 then
        raiseEvent("tar afflicted", {aff})
        if checkTargetLocks then checkTargetLocks() end
    end
    updateAffDisplayV2()
end

-- Remove one stack of an affliction (decrement by 2)
function unstackAffV2(aff)
    if not ataxia.settings.useAffTrackingV2 then return end

    if tAffsV2[aff] and tAffsV2[aff] >= 2 then
        tAffsV2[aff] = tAffsV2[aff] - 2
        if tAffsV2[aff] < 1 then
            tAffsV2[aff] = 0
            affTimersV2[aff] = nil
            raiseEvent("target cured aff", aff)
        end
        syncToOldSystem(aff, tAffsV2[aff])
    end
    updateAffDisplayV2()
end

-- Get the number of stacks of an affliction
function getStackCountV2(aff)
    if not tAffsV2[aff] then return 0 end
    return math.floor(tAffsV2[aff] / 2)
end

-- Check if affliction has multiple stacks
function hasMultipleStacksV2(aff)
    return getStackCountV2(aff) >= 2
end

-- ============================================
-- CURE TYPE DEFINITIONS
-- ============================================

-- Focus-curable afflictions (mental affs)
focusCurableAffsV2 = {
    "impatience", "stupidity", "anorexia", "epilepsy", "masochism",
    "recklessness", "dizziness", "shyness", "confusion", "dementia",
    "paranoia", "hallucinations", "loneliness", "vertigo", "feeble",
    "addiction", "hypersomnia"
}

-- Kelp/Aurum-curable afflictions
kelpCurableAffsV2 = {
    "asthma", "clumsiness", "hypochondria", "sensitivity", "weariness",
    "healthleech", "parasite"
}

-- Tree-curable afflictions (most physical affs)
treeCurableAffsV2 = {
    "paralysis", "slickness", "anorexia", "asthma", "sensitivity",
    "clumsiness", "weariness", "epilepsy", "haemophilia", "nausea",
    "dizziness", "shyness", "stupidity", "confusion", "dementia",
    "paranoia", "hallucinations", "impatience", "hypersomnia", "addiction"
}

-- Helper: Check if affliction is in a cure list
local function isInCureList(aff, cureList)
    for _, cureAff in ipairs(cureList) do
        if aff == cureAff then return true end
    end
    return false
end

-- Helper: Get tracked afflictions matching a cure type
local function getTrackedAffsOfType(cureList)
    local matched = {}
    for aff, cert in pairs(tAffsV2) do
        if cert and cert >= 1 and isInCureList(aff, cureList) then
            table.insert(matched, aff)
        end
    end
    return matched
end

-- ============================================
-- RANDOM CURE TRACKING (AK-inspired ak.randomaffs)
-- ============================================

-- Add expected random cure (tree/focus queued)
function addRandomCureCounterV2()
    randomCuresV2 = randomCuresV2 + 1
end

-- Handle target using tree tattoo
function onTargetTreeV2(targetName)
    if not ataxia.settings.useAffTrackingV2 then return end

    if randomCuresV2 > 0 then
        -- Expected random cure - decrement counter
        randomCuresV2 = randomCuresV2 - 1
    else
        -- Unexpected tree - reduce certainty of a tree-curable affliction
        reduceCureTypeAffCertaintyV2(treeCurableAffsV2, "tree")
    end
end

-- Handle target using focus
function onTargetFocusV2(targetName)
    if not ataxia.settings.useAffTrackingV2 then return end

    if randomCuresV2 > 0 then
        randomCuresV2 = randomCuresV2 - 1
    else
        -- Focus only cures mental afflictions
        reduceCureTypeAffCertaintyV2(focusCurableAffsV2, "focus")
    end
end

-- Handle target eating kelp/aurum
function onTargetKelpV2(targetName)
    if not ataxia.settings.useAffTrackingV2 then return end
    reduceCureTypeAffCertaintyV2(kelpCurableAffsV2, "kelp")
end

-- Smart cure reduction: If only ONE matching aff, remove it completely
function reduceCureTypeAffCertaintyV2(cureList, cureType)
    local matchedAffs = getTrackedAffsOfType(cureList)

    if #matchedAffs == 0 then
        -- No matching afflictions tracked
        if ataxiaEcho then
            ataxiaEcho("[V2] " .. cureType .. " used but no matching affs tracked")
        end
        return
    elseif #matchedAffs == 1 then
        -- Only ONE matching affliction - remove it completely
        local aff = matchedAffs[1]
        removeAffV2(aff)
        if ataxiaEcho then
            ataxiaEcho("[V2] " .. cureType .. " cured: " .. aff .. " (only option)")
        end
    else
        -- Multiple matching afflictions - reduce certainty of first one
        -- (could be smarter with priority later)
        local aff = matchedAffs[1]
        uncertainAffV2(aff)
        if ataxiaEcho then
            ataxiaEcho("[V2] " .. cureType .. " reduced certainty of: " .. aff)
        end
    end
end

-- Legacy function for generic random cure (tree mainly)
function reduceRandomAffCertaintyV2()
    reduceCureTypeAffCertaintyV2(treeCurableAffsV2, "random")
end

-- Reset random cure counter (on target change)
function resetRandomCuresV2()
    randomCuresV2 = 0
end

-- Update affliction display
function updateAffDisplayV2()
    -- Update V2 tracking window if it exists
    if zgui and zgui.showTarAffsV2 then
        zgui.showTarAffsV2()
    end

    -- Also update legacy displays for backward compatibility
    if ataxiaTemp and ataxiaTemp.showingAffs then
        if displayTargetAffs then displayTargetAffs() end
    elseif zgui and zgui.showTarAffs then
        zgui.showTarAffs()
    end
end

-- Reset V2 when target changes
function resetAffsV2()
    tAffsV2 = {}
    affTimersV2 = {}
end

-- Event handler: Sync from old system when afflictions are applied
-- This catches all tarAffed() calls from existing triggers
registerAnonymousEventHandler("tar afflicted", function(event, affList)
    if not ataxia.settings.useAffTrackingV2 then return end
    if not affList or type(affList) ~= "table" then return end

    for _, aff in pairs(affList) do
        if type(aff) == "string" then
            tAffsV2[aff] = 2
            affTimersV2[aff] = getEpoch()
        end
    end
end)

-- Debug function
function debugAffsV2()
    echo("=== Affliction Tracking V2 State ===\n")
    echo("Enabled: " .. tostring(ataxia.settings.useAffTrackingV2) .. "\n")
    echo("Random Cure Counter: " .. tostring(randomCuresV2) .. "\n")
    echo("\ntAffsV2 (certainty/stacks):\n")
    local hasAffs = false
    for aff, cert in pairs(tAffsV2) do
        if cert and cert > 0 then
            local stacks = getStackCountV2(aff)
            local certStr
            if stacks > 1 then
                certStr = stacks .. " STACKS"
            elseif cert >= 2 then
                certStr = "CONFIRMED"
            else
                certStr = "likely"
            end
            echo("  " .. aff .. " = " .. cert .. " (" .. certStr .. ")\n")
            hasAffs = true
        end
    end
    if not hasAffs then
        echo("  (none)\n")
    end
end
