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

--[[
    Priority lists for all herbs (AK-inspired)
    Order: unverifiable afflictions first (assume cured first)
    Verifiable ones last (we can confirm via signals, so keep tracking)
]]--
herbRemovalPriority = {
    -- KELP/AURUM: asthma, clumsiness, sensitivity, weariness, healthleech, hypochondria, parasite
    kelp = {
        "hypochondria",  -- Can't verify, low combat impact
        "parasite",      -- Can't verify
        "weariness",     -- Can't easily verify (passive cure block)
        "healthleech",   -- Can't easily verify
        "sensitivity",   -- Hard to verify, moderate impact
        "clumsiness",    -- CAN verify via fumble - keep longer
        "asthma",        -- CAN verify via smoke - keep longest
    },

    -- GINSENG/FERRUM: addiction, darkshade, haemophilia, lethargy, nausea, scytherus
    ginseng = {
        "addiction",     -- Can't easily verify
        "lethargy",      -- Can't easily verify
        "haemophilia",   -- Can verify via bleeding
        "darkshade",     -- Timed death - important to track
        "nausea",        -- Can verify via vomit
        "scytherus",     -- Damage ticks - important
    },

    -- GOLDENSEAL/PLUMBUM: dizziness, epilepsy, impatience, shyness, stupidity, depression
    goldenseal = {
        "depression",    -- Can't verify
        "shyness",       -- Can't verify
        "dizziness",     -- Can verify via stumble
        "stupidity",     -- Can verify via failed actions
        "epilepsy",      -- Can verify via seizure
        "impatience",    -- Critical for locks - keep longest
    },

    -- ASH/STANNUM: confusion, dementia, hallucinations, paranoia, hypersomnia
    ash = {
        "hypersomnia",   -- Can't easily verify
        "hallucinations", -- Can verify via illusion attacks
        "dementia",      -- Can verify via random actions
        "paranoia",      -- Can verify via random flee
        "confusion",     -- Critical for focus lock
    },

    -- BELLWORT/CUPRUM: generosity, pacifism, justice, lovers, retribution
    bellwort = {
        "retribution",   -- Can verify via damage reflection
        "lovers",        -- Can verify via refusing attack
        "justice",       -- Can verify via damage reflection
        "generosity",    -- Can verify via giving items
        "pacifism",      -- Can verify via refusing attack
    },

    -- LOBELIA/ARGENTUM: agoraphobia, claustrophobia, loneliness, masochism, recklessness, vertigo, hypochondria, fratricide
    lobelia = {
        "fratricide",    -- Serpent specific, timed
        "hypochondria",  -- Fake affs, can't verify
        "loneliness",    -- Can verify via leaving group
        "claustrophobia", -- Can verify via fleeing indoors
        "agoraphobia",   -- Can verify via fleeing outdoors
        "vertigo",       -- Can verify via falling
        "masochism",     -- Important for Ekanelia
        "recklessness",  -- Important for Ekanelia
    },

    -- BLOODROOT/MAGNESIUM: paralysis, slickness
    bloodroot = {
        "slickness",     -- Can verify via failed apply
        "paralysis",     -- Critical for locks - keep longest
    },
}

-- Backward compatibility alias
local kelpRemovalPriority = herbRemovalPriority.kelp

-- V2 state for disambiguation
pendingKelpAffsV2 = nil
kelpDisambiguateTimerV2 = nil
lastGuessV2 = nil  -- Generic guess storage for all herbs
lastKelpGuessV2 = nil  -- Backward compatibility

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
    -- Get herb-specific priority list, fall back to kelp if not found
    local priorityList = herbRemovalPriority[herb] or herbRemovalPriority.kelp

    for _, aff in ipairs(priorityList) do
        if table.contains(candidates, aff) then
            removeAffV2(aff)
            -- Store for backtracking
            storeGuessV2(aff, candidates, herb)
            return
        end
    end

    -- Fallback: if no priority match, remove first candidate
    if #candidates > 0 then
        removeAffV2(candidates[1])
        storeGuessV2(candidates[1], candidates, herb)
    end
end

-- Store guess for potential backtracking (generic for all herbs)
function storeGuessV2(removedAff, candidates, herb)
    local timestamp = getEpoch()
    lastGuessV2 = {
        removed = removedAff,
        candidates = candidates,
        herb = herb or "unknown",
        timestamp = timestamp
    }

    -- Expire after 5 seconds
    tempTimer(5, function()
        if lastGuessV2 and lastGuessV2.timestamp == timestamp then
            lastGuessV2 = nil
        end
    end)
end

-- Backward compatibility alias
function storeKelpGuessV2(removedAff, candidates)
    storeGuessV2(removedAff, candidates, "kelp")
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
