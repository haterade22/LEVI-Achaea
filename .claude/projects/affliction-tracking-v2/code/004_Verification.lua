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

    These are called from triggers that detect the relevant game messages.
]]--

-- Track non-fumble attacks for clumsiness uncertainty
clumsyAttackCountV2 = 0

--[[
    Called when target fumbles an attack.
    This PROVES they have clumsiness.

    Usage: Add to fumble detection trigger:
        if isTargeted(attacker) then
            onTargetFumbleV2(attacker)
        end
]]--
function onTargetFumbleV2(attacker)
    if not ataxia.settings.useAffTrackingV2 then return end
    if not isTargeted(attacker) then return end

    -- Check if we need to backtrack a wrong guess
    if hasPendingGuessV2 and hasPendingGuessV2("clumsiness") then
        backtrackKelpCureV2("clumsiness")
    else
        -- Just confirm clumsiness is present
        confirmAffV2("clumsiness")
    end

    -- Reset non-fumble counter
    clumsyAttackCountV2 = 0
end

--[[
    Called when target successfully attacks (no fumble).
    After multiple successful attacks, we become less certain about clumsiness.

    Usage: Add to attack detection trigger:
        if isTargeted(attacker) and not fumbled then
            onTargetAttackV2(attacker)
        end
]]--
function onTargetAttackV2(attacker)
    if not ataxia.settings.useAffTrackingV2 then return end
    if not isTargeted(attacker) then return end

    clumsyAttackCountV2 = clumsyAttackCountV2 + 1

    -- After 3 successful attacks without fumble, reduce clumsiness certainty
    if clumsyAttackCountV2 >= 3 and haveAffV2("clumsiness") then
        uncertainAffV2("clumsiness")
        clumsyAttackCountV2 = 0
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
    if not ataxia.settings.useAffTrackingV2 then return end
    if not isTargeted(smoker) then return end

    -- Smoking proves asthma was cured
    removeAffV2("asthma")

    -- If we were waiting for smoke disambiguation, handle it
    if onKelpSmokeCuredV2 then
        onKelpSmokeCuredV2()
    end
end

--[[
    Reset verification tracking (e.g., on target change)
]]--
function resetVerificationV2()
    clumsyAttackCountV2 = 0
end

--[[
    Hook into target change to reset tracking
]]--
registerAnonymousEventHandler("ataxia target changed", function()
    resetVerificationV2()
    clearPendingGuessesV2()
    resetAffsV2()
end)
