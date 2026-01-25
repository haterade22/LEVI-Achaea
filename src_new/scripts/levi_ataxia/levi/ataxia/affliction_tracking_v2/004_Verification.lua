--[[mudlet
type: script
name: Affliction Tracking V2 - Verification
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
    Affliction Tracking V2 - Verification Signals Module

    This module handles third-party verification signals that prove
    whether the target has or doesn't have certain afflictions.

    Verification Signals:
    - Fumble: Proves clumsiness is present
    - Smoke: Proves asthma was cured (absence of asthma)
    - Vomit: Proves nausea is present
    - Slick fail: Proves slickness is present
    - Paralysis block: Proves paralysis is present

    These are called from triggers that detect the relevant game messages.
]]--

--[[
    Called when target fumbles an attack.
    This PROVES they have clumsiness.

    Usage: Add to fumble detection trigger:
        if isTargeted(attacker) then
            onTargetFumbleV2(attacker)
        end
]]--
function onTargetFumbleV2(attacker)
    if not isTargeted(attacker) then return end

    -- Route to V3 if enabled
    if affConfigV3 and affConfigV3.enabled then
        collapseAffPresentV3("clumsiness")
        return
    end

    if not ataxia.settings.useAffTrackingV2 then return end

    -- Check if we need to backtrack a wrong guess
    if hasPendingGuessV2 and hasPendingGuessV2("clumsiness") then
        backtrackCureV2("clumsiness")
    else
        -- Confirm clumsiness is present
        addAffV2("clumsiness")
    end
end

--[[
    Called when target smokes successfully.
    This PROVES they don't have asthma (you can't smoke with asthma).

    Usage: Add to smoke detection trigger:
        if isTargeted(smoker) then
            onTargetSmokeV2(smoker)
        end
]]--
function onTargetSmokeV2(smoker)
    if not isTargeted(smoker) then return end

    -- Route to V3 if enabled
    if affConfigV3 and affConfigV3.enabled then
        collapseAffAbsentV3("asthma")
        return
    end

    if not ataxia.settings.useAffTrackingV2 then return end

    -- Smoking proves asthma was cured
    removeAffV2("asthma")

    -- If we were waiting for smoke disambiguation, handle it
    if onKelpSmokeCuredV2 then
        onKelpSmokeCuredV2()
    end
end

-- ============================================
-- NAUSEA VERIFICATION
-- ============================================

--[[
    Called when target vomits.
    This PROVES they have nausea.

    Usage: Add to vomit detection trigger:
        if isTargeted(vomiter) then
            onTargetVomitV2(vomiter)
        end
]]--
function onTargetVomitV2(vomiter)
    if not isTargeted(vomiter) then return end

    -- Route to V3 if enabled
    if affConfigV3 and affConfigV3.enabled then
        collapseAffPresentV3("nausea")
        return
    end

    if not ataxia.settings.useAffTrackingV2 then return end

    -- Check if we need to backtrack a wrong guess
    if hasPendingGuessV2 and hasPendingGuessV2("nausea") then
        backtrackCureV2("nausea")
    else
        -- Just confirm nausea is present
        addAffV2("nausea")
    end
end

-- ============================================
-- SLICKNESS VERIFICATION
-- ============================================

--[[
    Called when target fails to apply salve due to slickness.
    This PROVES they have slickness.

    Usage: Add to slick fail detection trigger:
        if isTargeted(target) then
            onTargetSlickFailV2(target)
        end
]]--
function onTargetSlickFailV2(target)
    if not isTargeted(target) then return end

    -- Route to V3 if enabled
    if affConfigV3 and affConfigV3.enabled then
        collapseAffPresentV3("slickness")
        return
    end

    if not ataxia.settings.useAffTrackingV2 then return end

    -- Check if we need to backtrack a wrong guess
    if hasPendingGuessV2 and hasPendingGuessV2("slickness") then
        backtrackCureV2("slickness")
    else
        -- Just confirm slickness is present
        addAffV2("slickness")
    end
end

-- ============================================
-- PARALYSIS VERIFICATION
-- ============================================

--[[
    Called when target's action is blocked by paralysis.
    This PROVES they have paralysis.

    Usage: Add to paralysis block detection trigger:
        if isTargeted(target) then
            onTargetParalysisBlockV2(target)
        end
]]--
function onTargetParalysisBlockV2(target)
    if not isTargeted(target) then return end

    -- Route to V3 if enabled
    if affConfigV3 and affConfigV3.enabled then
        collapseAffPresentV3("paralysis")
        return
    end

    if not ataxia.settings.useAffTrackingV2 then return end

    -- Check if we need to backtrack a wrong guess
    if hasPendingGuessV2 and hasPendingGuessV2("paralysis") then
        backtrackCureV2("paralysis")
    else
        -- Just confirm paralysis is present
        addAffV2("paralysis")
    end
end

-- ============================================
-- RESET FUNCTIONS
-- ============================================

--[[
    Reset verification tracking (e.g., on target change)
]]--
function resetVerificationV2()
    -- No state to reset in binary system
end

--[[
    Hook into target change to reset tracking
]]--
registerAnonymousEventHandler("ataxia target changed", function()
    resetVerificationV2()
    clearPendingGuessesV2()
    resetAffsV2()
end)
