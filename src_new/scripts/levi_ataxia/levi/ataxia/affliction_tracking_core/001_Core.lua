--[[mudlet
type: script
name: Core
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


--[[
    Affliction Tracking V2 - Core Module

    Binary affliction tracking with separate stack counting.
    Runs parallel to the old tAffs system with full backward compatibility.

    tAffsV2[aff] = true/nil (boolean presence)
    tAffStacksV2[aff] = number (stack count for stackable affs)

    Toggle: ataxia.settings.useAffTrackingV2 = true/false
]]--

-- Initialize V2 tracking tables
tAffsV2 = tAffsV2 or {}
tAffStacksV2 = tAffStacksV2 or {}
affTimersV2 = affTimersV2 or {}

-- Initialize settings
ataxia = ataxia or {}
ataxia.settings = ataxia.settings or {}
ataxia.settings.useAffTrackingV2 = ataxia.settings.useAffTrackingV2 or false

-- Sync V2 state to old tAffs for backward compatibility
function syncToOldSystem(aff, present)
    if not tAffs then return end
    tAffs[aff] = present
    if present then
        if affTimersV2[aff] then
            affTimers[aff] = affTimersV2[aff]
        end
    else
        affTimers[aff] = nil
    end
end

-- Add affliction (binary: sets to true)
function addAffV2(aff)
    if not ataxia.settings.useAffTrackingV2 then return end

    local wasAbsent = not tAffsV2[aff]
    tAffsV2[aff] = true
    affTimersV2[aff] = getEpoch()
    syncToOldSystem(aff, true)

    if wasAbsent then
        raiseEvent("tar afflicted", {aff})
        if checkTargetLocks then checkTargetLocks() end
    end
    updateAffDisplayV2()
end

-- Backward compatibility alias
function confirmAffV2(aff)
    addAffV2(aff)
end

-- tarAffedConfirmed: Used by triggers to mark afflictions as confirmed
-- In binary system, this is the same as tarAffed + V2 sync
function tarAffedConfirmed(...)
    -- Call original tarAffed for V1 compatibility
    if tarAffed then
        tarAffed(...)
    end
    -- Also update V2 if enabled
    if ataxia.settings.useAffTrackingV2 then
        for _, aff in ipairs({...}) do
            if type(aff) == "string" then
                addAffV2(aff)
            end
        end
    end
end

-- Remove affliction (also clears stacks)
function removeAffV2(aff)
    if not ataxia.settings.useAffTrackingV2 then return end

    if tAffsV2[aff] then
        tAffsV2[aff] = nil
        affTimersV2[aff] = nil
        if tAffStacksV2 then tAffStacksV2[aff] = nil end
        syncToOldSystem(aff, false)
        raiseEvent("target cured aff", aff)
    end
    updateAffDisplayV2()
end

-- Check if target has affliction
function haveAffV2(aff)
    if not ataxia.settings.useAffTrackingV2 then
        return haveAff(aff)  -- Fall back to old system
    end
    return tAffsV2[aff] == true
end

-- Backward compatibility alias (same as haveAffV2 in binary system)
function haveConfirmedAffV2(aff)
    return haveAffV2(aff)
end

-- ============================================
-- STACK TRACKING (separate table)
-- ============================================

-- Add a stack of an affliction
function stackAffV2(aff)
    if not ataxia.settings.useAffTrackingV2 then return end

    tAffStacksV2 = tAffStacksV2 or {}
    tAffStacksV2[aff] = (tAffStacksV2[aff] or 0) + 1

    -- Also ensure affliction is marked as present
    if not tAffsV2[aff] then
        tAffsV2[aff] = true
        affTimersV2[aff] = getEpoch()
        syncToOldSystem(aff, true)
        raiseEvent("tar afflicted", {aff})
        if checkTargetLocks then checkTargetLocks() end
    end
    updateAffDisplayV2()
end

-- Remove one stack of an affliction
function unstackAffV2(aff)
    if not ataxia.settings.useAffTrackingV2 then return end

    if tAffStacksV2 and tAffStacksV2[aff] and tAffStacksV2[aff] > 0 then
        tAffStacksV2[aff] = tAffStacksV2[aff] - 1
        if tAffStacksV2[aff] <= 0 then
            tAffStacksV2[aff] = nil
            removeAffV2(aff)
        else
            updateAffDisplayV2()
        end
    end
end

-- Get the number of stacks of an affliction
function getStackCountV2(aff)
    if not tAffStacksV2 then return 0 end
    return tAffStacksV2[aff] or 0
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

-- Bloodroot/Magnesium-curable afflictions
bloodrootCurableAffsV2 = {
    "paralysis", "slickness"
}

-- Ginseng/Ferrum-curable afflictions
ginsengCurableAffsV2 = {
    "haemophilia", "nausea", "addiction", "lethargy", "darkshade", "scytherus"
}

-- Goldenseal/Plumbum-curable afflictions
goldensealCurableAffsV2 = {
    "dizziness", "epilepsy", "impatience", "shyness", "stupidity", "depression"
}

-- Ash/Stannum-curable afflictions
ashCurableAffsV2 = {
    "confusion", "dementia", "hallucinations", "paranoia", "hypersomnia"
}

-- Bellwort/Cuprum-curable afflictions
bellwortCurableAffsV2 = {
    "generosity", "pacifism", "justice", "lovers", "retribution"
}

-- Lobelia/Argentum-curable afflictions
lobeliaCurableAffsV2 = {
    "agoraphobia", "claustrophobia", "loneliness", "masochism", "recklessness",
    "vertigo", "hypochondria", "fratricide"
}

-- Smoke-curable afflictions (elm, valerian, skullcap)
smokeCurableAffsV2 = {
    "aeon", "deadening", "tension", "disloyalty", "manaleech",
    "slickness", "unweavingspirit", "hellsight", "asthma"
}

-- Mending salve (body/skin) curable afflictions
mendingBodyCurableAffsV2 = {
    "slickness", "bloodfire", "selarnia", "frostbite", "anorexia", "itching"
}

-- Mending salve (skin) curable afflictions (caloric-related)
mendingSkinCurableAffsV2 = {
    "slickness", "bloodfire", "selarnia", "frostbite", "frozen", "shivering", "nocaloric"
}

-- Restoration salve (head) curable afflictions
restorationHeadCurableAffsV2 = {
    "slickness", "crushedthroat", "damagedhead", "mangledhead", "blindness", "scalded", "epidermal", "bloodfire"
}

-- Restoration salve (limbs) curable afflictions
restorationLimbsCurableAffsV2 = {
    "slickness", "bloodfire"
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
    for aff, present in pairs(tAffsV2) do
        if present and isInCureList(aff, cureList) then
            table.insert(matched, aff)
        end
    end
    return matched
end

-- ============================================
-- CURE HANDLERS
-- ============================================

-- Handle target using tree tattoo
function onTargetTreeV2(targetName)
    if not ataxia.settings.useAffTrackingV2 then return end
    reduceCureTypeAffCertaintyV2(treeCurableAffsV2, "tree")
end

-- Handle target using focus
function onTargetFocusV2(targetName)
    if not ataxia.settings.useAffTrackingV2 then return end
    reduceCureTypeAffCertaintyV2(focusCurableAffsV2, "focus")
end

-- Handle target eating kelp/aurum
function onTargetKelpV2(targetName)
    if not ataxia.settings.useAffTrackingV2 then return end
    reduceCureTypeAffCertaintyV2(kelpCurableAffsV2, "kelp")
end

-- Handle target eating bloodroot/magnesium (cures paralysis or slickness)
function onTargetBloodrootV2(targetName)
    if not ataxia.settings.useAffTrackingV2 then return end
    reduceCureTypeAffCertaintyV2(bloodrootCurableAffsV2, "bloodroot")
end

-- Handle target eating ginseng/ferrum (cures haemophilia, nausea, etc.)
function onTargetGinsengV2(targetName)
    if not ataxia.settings.useAffTrackingV2 then return end
    reduceCureTypeAffCertaintyV2(ginsengCurableAffsV2, "ginseng")
end

-- Handle target eating goldenseal/plumbum (cures dizziness, epilepsy, etc.)
function onTargetGoldensealV2(targetName)
    if not ataxia.settings.useAffTrackingV2 then return end
    reduceCureTypeAffCertaintyV2(goldensealCurableAffsV2, "goldenseal")
end

-- Handle target eating ash/stannum (cures confusion, dementia, etc.)
function onTargetAshV2(targetName)
    if not ataxia.settings.useAffTrackingV2 then return end
    reduceCureTypeAffCertaintyV2(ashCurableAffsV2, "ash")
end

-- Handle target eating bellwort/cuprum (cures generosity, pacifism, etc.)
function onTargetBellwortV2(targetName)
    if not ataxia.settings.useAffTrackingV2 then return end
    reduceCureTypeAffCertaintyV2(bellwortCurableAffsV2, "bellwort")
end

-- Handle target eating lobelia/argentum (cures agoraphobia, masochism, etc.)
function onTargetLobeliaV2(targetName)
    if not ataxia.settings.useAffTrackingV2 then return end
    reduceCureTypeAffCertaintyV2(lobeliaCurableAffsV2, "lobelia")
end

-- Handle target smoking (cures aeon, deadening, etc.)
-- Also triggers kelp asthma disambiguation
function onTargetSmokeV2(targetName)
    if not ataxia.settings.useAffTrackingV2 then return end

    -- Smoking proves asthma is cured (can't smoke with asthma)
    if haveAffV2("asthma") then
        removeAffV2("asthma")
        if ataxiaEcho then
            ataxiaEcho("[V2] Smoke detected - asthma cured (smoking proves no asthma)")
        end
    end

    -- Backtrack kelp guess if we assumed non-asthma was cured
    -- Smoke proves asthma was actually cured, so restore the wrong guess
    if lastGuessV2 and lastGuessV2.herb == "kelp" and lastGuessV2.removed ~= "asthma" then
        addAffV2(lastGuessV2.removed)
        if ataxiaEcho then
            ataxiaEcho("[V2] Smoke backtrack: restoring " .. lastGuessV2.removed .. " (kelp actually cured asthma)")
        end
        lastGuessV2 = nil
    end

    -- Handle kelp disambiguation
    if onKelpSmokeCuredV2 then onKelpSmokeCuredV2() end

    -- Reduce certainty of other smoke-curable affs
    reduceCureTypeAffCertaintyV2(smokeCurableAffsV2, "smoke")
end

-- Handle target applying salve to body
function onTargetSalveBodyV2(targetName)
    if not ataxia.settings.useAffTrackingV2 then return end

    -- Slickness is always cured by applying salve (proves no slickness)
    if haveAffV2("slickness") then
        removeAffV2("slickness")
        if ataxiaEcho then
            ataxiaEcho("[V2] Body salve - slickness cured (applying proves no slickness)")
        end
    end

    reduceCureTypeAffCertaintyV2(mendingBodyCurableAffsV2, "body salve")
end

-- Handle target applying salve to skin
function onTargetSalveSkinV2(targetName)
    if not ataxia.settings.useAffTrackingV2 then return end

    -- Slickness is always cured by applying salve
    if haveAffV2("slickness") then
        removeAffV2("slickness")
        if ataxiaEcho then
            ataxiaEcho("[V2] Skin salve - slickness cured (applying proves no slickness)")
        end
    end

    reduceCureTypeAffCertaintyV2(mendingSkinCurableAffsV2, "skin salve")
end

-- Handle target applying salve to head
function onTargetSalveHeadV2(targetName)
    if not ataxia.settings.useAffTrackingV2 then return end

    -- Slickness is always cured by applying salve
    if haveAffV2("slickness") then
        removeAffV2("slickness")
        if ataxiaEcho then
            ataxiaEcho("[V2] Head salve - slickness cured (applying proves no slickness)")
        end
    end

    reduceCureTypeAffCertaintyV2(restorationHeadCurableAffsV2, "head salve")
end

-- Handle target applying salve to limbs (arms or legs)
function onTargetSalveLimbsV2(targetName, limb)
    if not ataxia.settings.useAffTrackingV2 then return end

    -- Slickness is always cured by applying salve
    if haveAffV2("slickness") then
        removeAffV2("slickness")
        if ataxiaEcho then
            ataxiaEcho("[V2] " .. (limb or "limb") .. " salve - slickness cured (applying proves no slickness)")
        end
    end

    reduceCureTypeAffCertaintyV2(restorationLimbsCurableAffsV2, (limb or "limb") .. " salve")
end

-- Priority-based cure removal: removes one affliction based on priority
function reduceCureTypeAffCertaintyV2(cureList, cureType)
    local matchedAffs = getTrackedAffsOfType(cureList)

    if #matchedAffs == 0 then
        -- No matching afflictions tracked
        if ataxiaEcho then
            ataxiaEcho("[V2] " .. cureType .. " used but no matching affs tracked")
        end
        return
    elseif #matchedAffs == 1 then
        -- Only ONE matching affliction - remove it
        local aff = matchedAffs[1]
        removeAffV2(aff)
        if ataxiaEcho then
            ataxiaEcho("[V2] " .. cureType .. " cured: " .. aff .. " (only option)")
        end
    else
        -- Multiple matching afflictions - use priority-based removal
        local affToRemove = nil
        local allAffs = table.concat(matchedAffs, ", ")

        -- Check if we have a priority list for this cure type
        if herbRemovalPriority and herbRemovalPriority[cureType] then
            local priorityList = herbRemovalPriority[cureType]
            for _, priorityAff in ipairs(priorityList) do
                if table.contains(matchedAffs, priorityAff) then
                    affToRemove = priorityAff
                    break
                end
            end
        end

        -- Fallback to first matched if no priority match
        if not affToRemove then
            affToRemove = matchedAffs[1]
        end

        removeAffV2(affToRemove)
        if ataxiaEcho then
            ataxiaEcho("[V2] " .. cureType .. " cured: " .. affToRemove .. " (from: " .. allAffs .. ")")
        end
    end
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
    tAffStacksV2 = {}
    affTimersV2 = {}
end

-- Event handler: Sync from old system when afflictions are applied
-- This catches all tarAffed() calls from existing triggers
registerAnonymousEventHandler("tar afflicted", function(event, affList)
    if not ataxia.settings.useAffTrackingV2 then return end
    if not affList or type(affList) ~= "table" then return end

    for _, aff in pairs(affList) do
        if type(aff) == "string" then
            tAffsV2[aff] = true
            affTimersV2[aff] = getEpoch()
        end
    end
end)

-- Debug function
function debugAffsV2()
    echo("=== Affliction Tracking V2 State ===\n")
    echo("Enabled: " .. tostring(ataxia.settings.useAffTrackingV2) .. "\n")
    echo("\ntAffsV2 (presence):\n")
    local hasAffs = false
    for aff, present in pairs(tAffsV2) do
        if present then
            local stacks = getStackCountV2(aff)
            local stackStr = ""
            if stacks > 0 then
                stackStr = " (x" .. stacks .. " stacks)"
            end
            echo("  " .. aff .. stackStr .. "\n")
            hasAffs = true
        end
    end
    if not hasAffs then
        echo("  (none)\n")
    end
end
