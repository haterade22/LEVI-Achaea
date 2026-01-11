--[[mudlet
type: script
name: Affliction Tracking V2 - Herb Cures
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
    Affliction Tracking V2 - Herb Cure Detection

    This module handles herb/mineral cure detection with V2 logic.
    Key feature: Priority based on verifiability (unverifiable first).
]]--

-- Priority lists: unverifiable afflictions first (assume cured first)
-- Verifiable ones last (we can confirm via signals, so keep tracking)
local kelpRemovalPriority = {
    "hypochondria",  -- Can't verify
    "parasite",      -- Can't verify
    "weariness",     -- Can't easily verify
    "healthleech",   -- Can't easily verify
    "clumsiness",    -- CAN verify via fumble - keep longer
    "sensitivity",   -- Hard to verify but low impact
}

-- V2 state for kelp disambiguation
pendingKelpAffsV2 = nil
kelpDisambiguateTimerV2 = nil
lastKelpGuessV2 = nil

-- Wrapper function: routes to V2 or old system based on setting
-- Replace targetAte() calls in triggers with this
function targetAteWrapper(herb)
    if ataxia.settings.useAffTrackingV2 then
        targetAteV2(herb)
    else
        targetAte(herb)  -- Original function unchanged
    end
end

-- V2 herb cure detection
function targetAteV2(herb)
    -- Anorexia is always cured by eating anything
    if haveAffV2("anorexia") then
        removeAffV2("anorexia")
    end

    -- Special case: kelp with asthma - wait for smoke disambiguation
    if herb == "kelp" and haveAffV2("asthma") then
        handleKelpWithAsthmaV2()
        return
    end

    -- Get all afflictions this herb could cure
    if not curingTable or not curingTable[herb] then
        predictBal("herb", 1.55)
        return
    end

    local candidates = {}
    for i = 1, #curingTable[herb] do
        local aff = curingTable[herb][i]
        if haveAffV2(aff) then
            table.insert(candidates, aff)
        end
    end

    if #candidates == 0 then
        -- No matching afflictions tracked
        predictBal("herb", 1.55)
        return
    end

    if #candidates == 1 then
        -- Only one candidate - definitely cured this one
        removeAffV2(candidates[1])
    else
        -- Multiple candidates - use priority removal + track for backtracking
        removeByPriorityV2(candidates, herb)
    end

    predictBal("herb", 1.55)
end

-- Handle kelp when asthma is present - wait for smoke to disambiguate
function handleKelpWithAsthmaV2()
    -- Store current kelp afflictions for later disambiguation
    pendingKelpAffsV2 = {}
    for _, aff in ipairs(curingTable["kelp"]) do
        if haveAffV2(aff) then
            table.insert(pendingKelpAffsV2, aff)
        end
    end

    -- Kill any existing timer
    if kelpDisambiguateTimerV2 then
        killTimer(kelpDisambiguateTimerV2)
    end

    -- Wait 2.5 seconds for smoke
    kelpDisambiguateTimerV2 = tempTimer(2.5, function()
        if pendingKelpAffsV2 then
            -- No smoke = asthma NOT cured
            -- Remove highest priority NON-asthma aff
            for _, aff in ipairs(kelpRemovalPriority) do
                if aff ~= "asthma" and table.contains(pendingKelpAffsV2, aff) then
                    removeAffV2(aff)
                    -- Store for potential backtracking
                    storeKelpGuessV2(aff, pendingKelpAffsV2)
                    ataxiaEcho("[V2] No smoke: assumed " .. aff .. " cured (asthma still present)")
                    break
                end
            end
            pendingKelpAffsV2 = nil
        end
        kelpDisambiguateTimerV2 = nil
    end)

    predictBal("herb", 1.55)
end

-- Remove affliction based on priority and track for backtracking
function removeByPriorityV2(candidates, herb)
    local priorityList = kelpRemovalPriority  -- TODO: add lists for other herbs

    for _, aff in ipairs(priorityList) do
        if table.contains(candidates, aff) then
            removeAffV2(aff)
            -- Store for backtracking
            storeKelpGuessV2(aff, candidates)
            return
        end
    end

    -- Fallback: if no priority match, remove first candidate
    if #candidates > 0 then
        removeAffV2(candidates[1])
        storeKelpGuessV2(candidates[1], candidates)
    end
end

-- Store guess for potential backtracking
function storeKelpGuessV2(removedAff, candidates)
    local timestamp = getEpoch()
    lastKelpGuessV2 = {
        removed = removedAff,
        candidates = candidates,
        timestamp = timestamp
    }

    -- Expire after 5 seconds
    tempTimer(5, function()
        if lastKelpGuessV2 and lastKelpGuessV2.timestamp == timestamp then
            lastKelpGuessV2 = nil
        end
    end)
end

-- Called by smoke trigger when target smokes (proves asthma cured)
function onKelpSmokeCuredV2()
    if pendingKelpAffsV2 then
        -- Smoke within timeout = asthma was cured
        removeAffV2("asthma")
        pendingKelpAffsV2 = nil
    end
    if kelpDisambiguateTimerV2 then
        killTimer(kelpDisambiguateTimerV2)
        kelpDisambiguateTimerV2 = nil
    end
end
