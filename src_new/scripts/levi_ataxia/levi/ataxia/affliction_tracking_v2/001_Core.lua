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
    Certainty Levels:
    2 = Confirmed - We applied it, saw the message
    1 = Likely - Applied but might have been randomly cured
    0 = Absent - Never applied or definitely cured
]]--

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

-- Update affliction display
function updateAffDisplayV2()
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
    echo("\ntAffsV2 (certainty levels):\n")
    local hasAffs = false
    for aff, cert in pairs(tAffsV2) do
        if cert and cert > 0 then
            local certStr = cert == 2 and "CONFIRMED" or "likely"
            echo("  " .. aff .. " = " .. cert .. " (" .. certStr .. ")\n")
            hasAffs = true
        end
    end
    if not hasAffs then
        echo("  (none)\n")
    end
end
