--[[mudlet
type: script
name: Affliction Tracking V2 - Backtracking
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
    Affliction Tracking V2 - Backtracking Module

    When we guess which affliction was cured and later get verification
    that our guess was wrong, this module reverses the guess.

    Example:
    1. Target has clumsiness + weariness
    2. They eat kelp -> we guess weariness cured (priority), remove it
    3. They DON'T fumble for a while -> our guess might be right
    4. But if they fumble -> proves clumsiness still there

    With verifiability priority (weariness removed before clumsiness),
    fumble just confirms we were right. Backtracking is only needed
    if we ever remove clumsiness when they still have it.

    Now supports ALL herb types via herbRemovalPriority from 002_Herb_Cures.lua
]]--

-- lastGuessV2 is defined in 002_Herb_Cures.lua
-- Structure: {removed = "aff", candidates = {...}, herb = "herbname", timestamp = epoch}

-- Generic backtrack function for any herb cure guess
-- Returns true if backtracking was performed
function backtrackCureV2(provenAff)
    if not ataxia.settings.useAffTrackingV2 then return false end
    if not lastGuessV2 then return false end
    if lastGuessV2.removed ~= provenAff then return false end

    -- We removed this aff, but it's proven still there!
    -- Put it back with high certainty
    confirmAffV2(provenAff)

    -- Get the priority list for the herb that made the guess
    local priorityList = nil
    if herbRemovalPriority and lastGuessV2.herb then
        priorityList = herbRemovalPriority[lastGuessV2.herb]
    end
    -- Fallback to kelp priority if no specific list found
    if not priorityList then
        priorityList = herbRemovalPriority and herbRemovalPriority.kelp or {}
    end

    -- Remove the next candidate from the original list instead
    local backtracked = false
    for _, aff in ipairs(priorityList) do
        if aff ~= provenAff and table.contains(lastGuessV2.candidates, aff) then
            removeAffV2(aff)
            ataxiaEcho("[V2] Backtracked: " .. aff .. " was actually cured, not " .. provenAff)
            backtracked = true
            break
        end
    end

    -- If no priority match found, try first available candidate
    if not backtracked and lastGuessV2.candidates then
        for _, aff in ipairs(lastGuessV2.candidates) do
            if aff ~= provenAff then
                removeAffV2(aff)
                ataxiaEcho("[V2] Backtracked: " .. aff .. " was actually cured, not " .. provenAff)
                backtracked = true
                break
            end
        end
    end

    -- Clear the guess
    lastGuessV2 = nil

    return backtracked
end

-- Backward compatibility alias for kelp-specific backtracking
function backtrackKelpCureV2(provenAff)
    return backtrackCureV2(provenAff)
end

-- Check if we have a pending guess for a specific affliction
function hasPendingGuessV2(aff)
    return lastGuessV2 and lastGuessV2.removed == aff
end

-- Clear all pending guesses (e.g., on target change)
function clearPendingGuessesV2()
    lastGuessV2 = nil
    lastKelpGuessV2 = nil  -- Backward compatibility
    pendingKelpAffsV2 = nil
    if kelpDisambiguateTimerV2 then
        killTimer(kelpDisambiguateTimerV2)
        kelpDisambiguateTimerV2 = nil
    end
end
