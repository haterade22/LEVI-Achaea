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
    2. They eat kelp → we guess weariness cured (priority), remove it
    3. They DON'T fumble for a while → our guess might be right
    4. But if they fumble → proves clumsiness still there

    With verifiability priority (weariness removed before clumsiness),
    fumble just confirms we were right. Backtracking is only needed
    if we ever remove clumsiness when they still have it.
]]--

-- lastKelpGuessV2 is defined in 002_Herb_Cures.lua
-- Structure: {removed = "aff", candidates = {...}, timestamp = epoch}

-- Priority list for backtracking (same as in Herb_Cures)
local kelpRemovalPriority = {
    "hypochondria",
    "parasite",
    "weariness",
    "healthleech",
    "clumsiness",
    "sensitivity",
}

-- Backtrack a kelp cure guess when verification proves it wrong
-- Returns true if backtracking was performed
function backtrackKelpCureV2(provenAff)
    if not ataxia.settings.useAffTrackingV2 then return false end
    if not lastKelpGuessV2 then return false end
    if lastKelpGuessV2.removed ~= provenAff then return false end

    -- We removed this aff, but it's proven still there!
    -- Put it back with high certainty
    confirmAffV2(provenAff)

    -- Remove the next candidate from the original list instead
    local backtracked = false
    for _, aff in ipairs(kelpRemovalPriority) do
        if aff ~= provenAff and table.contains(lastKelpGuessV2.candidates, aff) then
            removeAffV2(aff)
            ataxiaEcho("[V2] Backtracked: " .. aff .. " was actually cured, not " .. provenAff)
            backtracked = true
            break
        end
    end

    -- Clear the guess
    lastKelpGuessV2 = nil

    return backtracked
end

-- Check if we have a pending guess for a specific affliction
function hasPendingGuessV2(aff)
    return lastKelpGuessV2 and lastKelpGuessV2.removed == aff
end

-- Clear all pending guesses (e.g., on target change)
function clearPendingGuessesV2()
    lastKelpGuessV2 = nil
    pendingKelpAffsV2 = nil
    if kelpDisambiguateTimerV2 then
        killTimer(kelpDisambiguateTimerV2)
        kelpDisambiguateTimerV2 = nil
    end
end
