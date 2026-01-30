--[[mudlet
type: script
name: Herb Cures
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

    -- TREE: cures most afflictions - priority order for tracking
    tree = {
        "hypersomnia",   -- Can't easily verify
        "addiction",     -- Can't easily verify
        "shyness",       -- Can't verify
        "dizziness",     -- Can verify via stumble
        "sensitivity",   -- Hard to verify
        "weariness",     -- Can't easily verify
        "haemophilia",   -- Can verify via bleeding
        "nausea",        -- Can verify via vomit - parry bypass important
        "hallucinations", -- Can verify via illusion attacks
        "dementia",      -- Can verify via random actions
        "epilepsy",      -- Can verify via seizure
        "clumsiness",    -- CAN verify via fumble
        "stupidity",     -- Can verify via failed actions
        "confusion",     -- Critical for focus lock
        "paranoia",      -- Critical for locks
        "asthma",        -- CAN verify via smoke - important for lock
        "anorexia",      -- Critical for locks - keep longest
        "slickness",     -- Critical for locks
        "paralysis",     -- Critical for locks - keep longest
    },

    -- FOCUS: cures mental afflictions
    focus = {
        "hypersomnia",   -- Can't easily verify
        "addiction",     -- Can't easily verify
        "loneliness",    -- Can verify
        "vertigo",       -- Can verify via falling
        "feeble",        -- Can verify
        "shyness",       -- Can't verify
        "dizziness",     -- Can verify via stumble
        "hallucinations", -- Can verify via illusion attacks
        "dementia",      -- Can verify via random actions
        "epilepsy",      -- Can verify via seizure
        "recklessness",  -- Important for Ekanelia
        "masochism",     -- Important for Ekanelia
        "confusion",     -- Critical for focus lock
        "paranoia",      -- Critical for locks
        "stupidity",     -- Can verify via failed actions - important for lock
        "anorexia",      -- Critical for locks
        "impatience",    -- Critical for locks - keep longest
    },
}

-- Backward compatibility alias
local kelpRemovalPriority = herbRemovalPriority.kelp

-- V2 state for disambiguation
pendingKelpAffsV2 = nil
kelpDisambiguateTimerV2 = nil
lastGuessV2 = nil  -- Generic guess storage for all herbs
lastKelpGuessV2 = nil  -- Backward compatibility

-- Wrapper function: routes to V3/V2/V1 based on settings
-- Replace targetAte() calls in triggers with this
function targetAteWrapper(herb)
    if affConfigV3 and affConfigV3.enabled then
        onHerbCureV3(herb)  -- V3 branching state tracker
    elseif ataxia.settings.useAffTrackingV2 then
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
        ataxiaEcho("[V2] " .. herb .. " eaten - cured anorexia (ate something)")
    end

    -- Special case: kelp with asthma - wait for smoke disambiguation
    if herb == "kelp" and haveAffV2("asthma") then
        handleKelpWithAsthmaV2()
        return
    end

    -- Get all afflictions this herb could cure
    if not curingTable or not curingTable[herb] then
        ataxiaEcho("[V2] " .. herb .. " eaten - no cure table found")
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
        ataxiaEcho("[V2] " .. herb .. " eaten - no matching affs tracked")
        predictBal("herb", 1.55)
        return
    end

    if #candidates == 1 then
        -- Only one candidate - definitely cured this one
        removeAffV2(candidates[1])
        ataxiaEcho("[V2] " .. herb .. " eaten - cured " .. candidates[1] .. " (only candidate)")
    else
        -- Multiple candidates - use priority removal + track for backtracking
        removeByPriorityV2(candidates, herb)
    end

    predictBal("herb", 1.55)
end

-- Track pending kelp count for multiple eats
pendingKelpCountV2 = 0

-- Handle kelp when asthma is present - wait for smoke to disambiguate
function handleKelpWithAsthmaV2()
    -- First check if asthma is the ONLY kelp-curable affliction
    -- If so, no point waiting for smoke - just remove asthma
    local otherKelpAffs = {}
    for _, aff in ipairs(curingTable["kelp"] or kelpCurableAffsV2) do
        if aff ~= "asthma" and haveAffV2(aff) then
            table.insert(otherKelpAffs, aff)
        end
    end

    if #otherKelpAffs == 0 then
        -- Asthma is the only kelp-curable aff - remove it directly
        removeAffV2("asthma")
        ataxiaEcho("[V2] Kelp eaten - cured asthma (only kelp aff tracked)")
        predictBal("herb", 1.55)
        return
    end

    -- If we're already waiting for kelp disambiguation, increment counter
    -- and immediately remove a non-asthma affliction for the PREVIOUS kelp
    if pendingKelpAffsV2 and pendingKelpCountV2 > 0 then
        -- They ate another kelp while we're waiting - process previous one now
        -- Remove highest priority NON-asthma aff for the previous kelp
        for _, aff in ipairs(kelpRemovalPriority) do
            if aff ~= "asthma" and haveAffV2(aff) then
                removeAffV2(aff)
                -- Store for potential backtracking if smoke proves asthma was cured
                storeKelpGuessV2(aff, pendingKelpAffsV2)
                ataxiaEcho("[V2] Multi-kelp: assumed " .. aff .. " cured (asthma still present)")
                break
            end
        end
    end

    -- Store current kelp afflictions for later disambiguation
    pendingKelpAffsV2 = {}
    for _, aff in ipairs(curingTable["kelp"] or kelpCurableAffsV2) do
        if haveAffV2(aff) then
            table.insert(pendingKelpAffsV2, aff)
        end
    end
    pendingKelpCountV2 = pendingKelpCountV2 + 1

    -- Kill any existing timer (we'll create a new one)
    if kelpDisambiguateTimerV2 then
        killTimer(kelpDisambiguateTimerV2)
    end

    -- Echo pending status
    local pendingStr = table.concat(pendingKelpAffsV2, ", ")
    ataxiaEcho("[V2] Kelp eaten with asthma - waiting for smoke (pending: " .. pendingStr .. ")")

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
            pendingKelpCountV2 = 0
        end
        kelpDisambiguateTimerV2 = nil
    end)

    predictBal("herb", 1.55)
end

-- Remove affliction based on priority and track for backtracking
function removeByPriorityV2(candidates, herb)
    -- Get herb-specific priority list, fall back to kelp if not found
    local priorityList = herbRemovalPriority[herb] or herbRemovalPriority.kelp

    -- Build candidates string for echo
    local candStr = table.concat(candidates, ", ")

    for _, aff in ipairs(priorityList) do
        if table.contains(candidates, aff) then
            removeAffV2(aff)
            -- Store for backtracking
            storeGuessV2(aff, candidates, herb)
            ataxiaEcho("[V2] " .. herb .. " eaten - cured " .. aff .. " (priority from: " .. candStr .. ")")
            return
        end
    end

    -- Fallback: if no priority match, remove first candidate
    if #candidates > 0 then
        removeAffV2(candidates[1])
        storeGuessV2(candidates[1], candidates, herb)
        ataxiaEcho("[V2] " .. herb .. " eaten - cured " .. candidates[1] .. " (fallback from: " .. candStr .. ")")
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
        ataxiaEcho("[V2] Smoke detected - kelp cured asthma (confirmed by smoke)")
        pendingKelpAffsV2 = nil
        pendingKelpCountV2 = 0
    end
    if kelpDisambiguateTimerV2 then
        killTimer(kelpDisambiguateTimerV2)
        kelpDisambiguateTimerV2 = nil
    end
end
