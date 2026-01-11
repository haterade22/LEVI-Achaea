--[[mudlet
type: script
name: Infernal DWC Vivisect
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- INFERNAL
- DWC
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    Infernal DWC Vivisect Offense

    Strategy: Nausea-first parry bypass into soft lock + limb prep for vivisect

    Kill Condition: VIVISECT requires Prone + Both Arms Broken

    Phases:
    1. NAUSEA_SETUP: Establish nausea (parry bypass), clumsiness (33% miss), weariness (blocks Fitness)
    2. PARALLEL_PREP: While nausea stuck, prep both arms + one leg AND build soft lock
    3. EXECUTE: Break arm1 → Break leg (delphinium prone) → Break arm2 (epseth/epteth) → Vivisect
    4. KILL: Execute vivisect

    Soft Lock = Anorexia + Slickness + Asthma + Paralysis + Stupidity
]]--

-------------------------------------------------------------------------------
-- NAMESPACE AND STATE
-------------------------------------------------------------------------------

infernalDWC = infernalDWC or {}

-- State tracking
infernalDWC.state = {
    phase = "NAUSEA_SETUP",     -- NAUSEA_SETUP, PARALLEL_PREP, EXECUTE, KILL
    executeStep = 0,            -- 0=none, 1=arm1_broken, 2=leg_broken, 3=arm2_broken
    focusArm = "left",          -- Which arm to break first (set dynamically)
    focusLeg = "left",          -- Which leg to prep/break
    lastPhase = nil,            -- Track phase changes for debugging
}

-- Configuration
infernalDWC.config = {
    prepThreshold = 90,         -- Limb ready for break (90%+)
    breakThreshold = 100,       -- Limb breaks at 100%
    weapon1 = "scimitar405403", -- Left hand weapon ID
    weapon2 = "scimitar405398", -- Right hand weapon ID
}

-------------------------------------------------------------------------------
-- LIMB DAMAGE HELPERS
-------------------------------------------------------------------------------

-- Get limb damage from Romaen's limb counter
-- Uses global 'target' variable and lb[target].hits table
function infernalDWC.getLA()
    if not target or not lb or not lb[target] or not lb[target].hits then return 0 end
    return tonumber(lb[target].hits["left arm"]) or 0
end

function infernalDWC.getRA()
    if not target or not lb or not lb[target] or not lb[target].hits then return 0 end
    return tonumber(lb[target].hits["right arm"]) or 0
end

function infernalDWC.getLL()
    if not target or not lb or not lb[target] or not lb[target].hits then return 0 end
    return tonumber(lb[target].hits["left leg"]) or 0
end

function infernalDWC.getRL()
    if not target or not lb or not lb[target] or not lb[target].hits then return 0 end
    return tonumber(lb[target].hits["right leg"]) or 0
end

-- Get DWC slash damage value
function infernalDWC.getSlashDamage()
    if ataxiaTables and ataxiaTables.limbData and ataxiaTables.limbData.dwcSlash then
        return tonumber(ataxiaTables.limbData.dwcSlash) or 6.6
    end
    return 6.6 -- Default fallback
end

-------------------------------------------------------------------------------
-- LIMB PREP CHECKING
-------------------------------------------------------------------------------

function infernalDWC.isArmPrepped(side)
    local damage = (side == "left") and infernalDWC.getLA() or infernalDWC.getRA()
    return damage >= infernalDWC.config.prepThreshold
end

function infernalDWC.isLegPrepped(side)
    local damage = (side == "left") and infernalDWC.getLL() or infernalDWC.getRL()
    return damage >= infernalDWC.config.prepThreshold
end

function infernalDWC.isArmBroken(side)
    local damage = (side == "left") and infernalDWC.getLA() or infernalDWC.getRA()
    local affName = (side == "left") and "damagedleftarm" or "damagedrightarm"
    return damage >= infernalDWC.config.breakThreshold or (tAffs and tAffs[affName])
end

function infernalDWC.isLegBroken(side)
    local damage = (side == "left") and infernalDWC.getLL() or infernalDWC.getRL()
    local affName = (side == "left") and "damagedleftleg" or "damagedrightleg"
    return damage >= infernalDWC.config.breakThreshold or (tAffs and tAffs[affName])
end

function infernalDWC.areBothArmsPrepped()
    return infernalDWC.isArmPrepped("left") and infernalDWC.isArmPrepped("right")
end

function infernalDWC.areBothArmsBroken()
    return infernalDWC.isArmBroken("left") and infernalDWC.isArmBroken("right")
end

function infernalDWC.isFocusLegPrepped()
    return infernalDWC.isLegPrepped(infernalDWC.state.focusLeg)
end

function infernalDWC.isFocusLegBroken()
    return infernalDWC.isLegBroken(infernalDWC.state.focusLeg)
end

-------------------------------------------------------------------------------
-- SMART LIMB BALANCING (hit lower damage first)
-------------------------------------------------------------------------------

function infernalDWC.getFocusArm()
    local la = infernalDWC.getLA()
    local ra = infernalDWC.getRA()
    return (la <= ra) and "left" or "right"
end

function infernalDWC.getOffArm()
    local la = infernalDWC.getLA()
    local ra = infernalDWC.getRA()
    return (la >= ra) and "left" or "right"
end

function infernalDWC.getFocusLeg()
    local ll = infernalDWC.getLL()
    local rl = infernalDWC.getRL()
    return (ll <= rl) and "left" or "right"
end

-------------------------------------------------------------------------------
-- AFFLICTION TRACKING HELPERS (V2 compatible)
-------------------------------------------------------------------------------

--[[
    Tracking System Toggle:
    - ataxia.settings.useAffTrackingV2 = true   → Use V2 ONLY (no V1 fallback)
    - ataxia.settings.useAffTrackingV2 = false  → Use V1 only

    When V2 is enabled, V1 is completely ignored to prevent conflicts.
]]--

-- Helper to check if target has an affliction (V2 or V1, no mixing)
function infernalDWC.hasAff(aff)
    -- V2 system (when enabled, use ONLY V2 - no fallback)
    if ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
        if haveAffV2 then
            return haveAffV2(aff)
        elseif tAffsV2 then
            return (tAffsV2[aff] or 0) >= 1
        end
        -- V2 enabled but not loaded - return false (don't fall back to V1)
        return false
    end

    -- V1 system (only when V2 is disabled)
    if tAffs then
        return tAffs[aff] == true
    end
    return false
end

-- Helper to confirm we applied an affliction (V2 or V1)
function infernalDWC.confirmAff(aff)
    -- V2 system (when enabled, use ONLY V2)
    if ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
        if confirmAffV2 then
            confirmAffV2(aff)
        end
        return -- Don't also set V1
    end

    -- V1 system (only when V2 is disabled)
    if tAffs then
        tAffs[aff] = true
    end
end

-- Check which tracking system is active
function infernalDWC.getTrackingSystem()
    if ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
        return "V2"
    end
    return "V1"
end

-------------------------------------------------------------------------------
-- LOCK DETECTION
-------------------------------------------------------------------------------

-- Check if we have soft lock (ANO + SLI + AST + PAR + STU)
function infernalDWC.checkSoftLock()
    return infernalDWC.hasAff("anorexia")
       and infernalDWC.hasAff("slickness")
       and infernalDWC.hasAff("asthma")
       and infernalDWC.hasAff("paralysis")
       and infernalDWC.hasAff("stupidity")
end

-- Check if we have venom lock (soft lock + crippled limb)
function infernalDWC.checkVenomLock()
    if not infernalDWC.checkSoftLock() then return false end
    return infernalDWC.hasAff("damagedleftarm") or infernalDWC.hasAff("damagedrightarm")
        or infernalDWC.hasAff("damagedleftleg") or infernalDWC.hasAff("damagedrightleg")
end

-- Check if nausea is stuck (parry bypass active)
function infernalDWC.isNauseaStuck()
    return infernalDWC.hasAff("nausea")
end

-- Check partial lock progress (for soft lock building)
function infernalDWC.countLockAffs()
    local count = 0
    if infernalDWC.hasAff("anorexia") then count = count + 1 end
    if infernalDWC.hasAff("slickness") then count = count + 1 end
    if infernalDWC.hasAff("asthma") then count = count + 1 end
    if infernalDWC.hasAff("paralysis") then count = count + 1 end
    if infernalDWC.hasAff("stupidity") then count = count + 1 end
    return count
end

-------------------------------------------------------------------------------
-- PHASE DETECTION
-------------------------------------------------------------------------------

function infernalDWC.getPhase()
    -- Kill check first - both arms broken + prone
    if infernalDWC.hasAff("prone") and infernalDWC.areBothArmsBroken() then
        return "KILL"
    end

    -- Execute phase check - all prepped AND soft locked
    if infernalDWC.areBothArmsPrepped()
       and infernalDWC.isFocusLegPrepped()
       and infernalDWC.checkSoftLock() then
        return "EXECUTE"
    end

    -- Parallel prep phase - nausea is stuck, work on limbs + lock
    if infernalDWC.isNauseaStuck() then
        return "PARALLEL_PREP"
    end

    -- Initial setup - get nausea to stick first
    return "NAUSEA_SETUP"
end

-------------------------------------------------------------------------------
-- VENOM SELECTION BY PHASE
-------------------------------------------------------------------------------

function infernalDWC.selectVenoms()
    local v1, v2 = nil, nil
    local phase = infernalDWC.getPhase()
    local hasAff = infernalDWC.hasAff  -- Local reference for cleaner code

    if phase == "NAUSEA_SETUP" then
        -- Priority: Nausea (parry bypass) > Clumsiness (33% miss) > Weariness (blocks Fitness)
        if not hasAff("nausea") then
            v1 = "eurypteria"
        elseif not hasAff("clumsiness") then
            v1 = "kalmia"
        elseif not hasAff("weariness") then
            v1 = "vernalius"
        else
            v1 = "eurypteria" -- Maintain nausea
        end

        -- Second venom slot
        if not hasAff("clumsiness") and v1 ~= "kalmia" then
            v2 = "kalmia"
        elseif not hasAff("weariness") and v1 ~= "vernalius" then
            v2 = "vernalius"
        elseif not hasAff("asthma") then
            v2 = "kalmia" -- Start building asthma for lock
        else
            v2 = "curare" -- Start paralysis pressure
        end

    elseif phase == "PARALLEL_PREP" then
        -- Soft lock priority order for v1
        if not hasAff("slickness") then
            v1 = "gecko"
        elseif not hasAff("asthma") then
            v1 = "kalmia"
        elseif not hasAff("anorexia") then
            v1 = "slike"
        elseif not hasAff("paralysis") then
            v1 = "curare"
        elseif not hasAff("stupidity") then
            v1 = "aconite"
        else
            v1 = "curare" -- Maintain paralysis
        end

        -- Second venom: maintain key afflictions or continue lock building
        if not hasAff("nausea") then
            v2 = "eurypteria" -- Re-apply nausea if lost
        elseif not hasAff("weariness") then
            v2 = "vernalius"
        elseif not hasAff("clumsiness") and v1 ~= "kalmia" then
            v2 = "kalmia"
        elseif not hasAff("paralysis") and v1 ~= "curare" then
            v2 = "curare"
        elseif not hasAff("stupidity") and v1 ~= "aconite" then
            v2 = "aconite"
        else
            v2 = "curare" -- Default to paralysis maintenance
        end

    elseif phase == "EXECUTE" then
        local step = infernalDWC.state.executeStep

        if step == 0 then
            -- Break arm 1: maintain lock pressure
            v1 = "curare"
            v2 = "aconite"
        elseif step == 1 then
            -- Break leg: delphinium x2 for prone on break
            v1 = "delphinium"
            v2 = "delphinium"
        elseif step == 2 then
            -- Break arm 2: epseth + epteth finishers
            v1 = "epseth"
            v2 = "epteth"
        else
            -- Fallback
            v1 = "curare"
            v2 = "aconite"
        end

    elseif phase == "KILL" then
        -- No venoms needed for vivisect
        v1 = nil
        v2 = nil
    end

    return v1, v2
end

-------------------------------------------------------------------------------
-- LIMB TARGET SELECTION
-------------------------------------------------------------------------------

-- DWC hits ONE limb per attack (both swords hit same limb)
function infernalDWC.selectLimbTarget()
    local phase = infernalDWC.getPhase()

    if phase == "NAUSEA_SETUP" then
        -- No limb targeting during setup, focus on venoms
        -- Can optionally start prepping an arm
        local focusArm = infernalDWC.getFocusArm()
        if not infernalDWC.isArmPrepped(focusArm) then
            return focusArm .. " arm"
        end
        return nil

    elseif phase == "PARALLEL_PREP" then
        -- Priority: Arms first (need both for vivisect), then leg
        local focusArm = infernalDWC.getFocusArm()
        local offArm = infernalDWC.getOffArm()
        local focusLeg = infernalDWC.state.focusLeg

        -- Prep arms first
        if not infernalDWC.isArmPrepped(focusArm) then
            return focusArm .. " arm"
        elseif not infernalDWC.isArmPrepped(offArm) then
            return offArm .. " arm"
        -- Then prep leg
        elseif not infernalDWC.isLegPrepped(focusLeg) then
            return focusLeg .. " leg"
        else
            -- All prepped, maintain pressure on focus arm
            return focusArm .. " arm"
        end

    elseif phase == "EXECUTE" then
        local step = infernalDWC.state.executeStep

        if step == 0 then
            -- Step 1: Break arm 1 (use current focus arm based on damage)
            infernalDWC.state.focusArm = infernalDWC.getFocusArm()
            return infernalDWC.state.focusArm .. " arm"
        elseif step == 1 then
            -- Step 2: Break leg (with delphinium for prone)
            return infernalDWC.state.focusLeg .. " leg"
        elseif step == 2 then
            -- Step 3: Break arm 2
            local offArm = (infernalDWC.state.focusArm == "left") and "right" or "left"
            return offArm .. " arm"
        end
    end

    return nil
end

-------------------------------------------------------------------------------
-- MAIN DISPATCH FUNCTION
-------------------------------------------------------------------------------

function infernalDWCVivisect()
    -- Use global 'target' variable (set by "t <name>" command)
    if not target or target == "" then
        cecho("\n<red>[INF DWC]<reset> No target set! Use: t <name>")
        return
    end

    -- Get current phase
    local phase = infernalDWC.getPhase()

    -- Track phase changes for debugging
    if phase ~= infernalDWC.state.lastPhase then
        cecho("\n<cyan>[INF DWC]<reset> Phase: <yellow>" .. phase .. "<reset>")
        infernalDWC.state.lastPhase = phase
    end

    -- KILL CHECK - Execute vivisect
    if phase == "KILL" then
        send("queue addclear freestand vivisect " .. target)
        cecho("\n<green>[INF DWC]<reset> VIVISECT!")
        return
    end

    -- Get venoms and limb target
    local v1, v2 = infernalDWC.selectVenoms()
    local limb = infernalDWC.selectLimbTarget()

    -- Build base command
    local weapon1 = infernalDWC.config.weapon1
    local weapon2 = infernalDWC.config.weapon2
    local atk = "wield left " .. weapon1 .. ";wield right " .. weapon2
    atk = atk .. ";wipe " .. weapon1 .. ";wipe " .. weapon2

    -- REBOUNDING CHECK - MUST clear rebounding first or attacks bounce back!
    -- Rebounding causes all melee attacks to reflect damage back to attacker
    if infernalDWC.hasAff("rebounding") then
        if v1 then
            -- razeslash removes rebounding AND applies venom
            atk = atk .. ";rsl " .. target .. " " .. v1
        else
            atk = atk .. ";raze " .. target
        end
        -- Execute raze and return - don't continue with normal attack
        send("queue addclear freestand " .. atk .. ";assess " .. target)
        cecho("\n<yellow>[INF DWC]<reset> Razing REBOUNDING!")
        return
    end

    -- SHIELD CHECK - must clear shield before attacks land
    if infernalDWC.hasAff("shield") then
        if v1 then
            atk = atk .. ";rsl " .. target .. " " .. v1
        else
            atk = atk .. ";raze " .. target
        end
        send("queue addclear freestand " .. atk .. ";assess " .. target)
        cecho("\n<yellow>[INF DWC]<reset> Razing SHIELD!")
        return
    end

    -- No rebounding or shield - proceed with normal attack
    if false then
        -- This block intentionally empty - placeholder for the elseif chain below
    -- Handle hellforge investments (exploit, torture, torment)
    elseif v1 == "exploit" or v1 == "torture" or v1 == "torment" then
        atk = atk .. ";hellforge invest " .. v1
        if limb and v2 then
            atk = atk .. ";dsl " .. target .. " " .. limb .. " " .. v2
        elseif v2 then
            atk = atk .. ";dsl " .. target .. " " .. v2
        else
            atk = atk .. ";dsl " .. target
        end
    elseif v2 == "exploit" or v2 == "torture" or v2 == "torment" then
        atk = atk .. ";hellforge invest " .. v2
        if limb and v1 then
            atk = atk .. ";dsl " .. target .. " " .. limb .. " " .. v1
        elseif v1 then
            atk = atk .. ";dsl " .. target .. " " .. v1
        else
            atk = atk .. ";dsl " .. target
        end
    else
        -- Standard dual slash with limb targeting
        if limb and v1 and v2 then
            atk = atk .. ";dsl " .. target .. " " .. limb .. " " .. v1 .. " " .. v2
        elseif v1 and v2 then
            atk = atk .. ";dsl " .. target .. " " .. v1 .. " " .. v2
        elseif v1 then
            atk = atk .. ";dsl " .. target .. " " .. v1
        else
            atk = atk .. ";dsl " .. target
        end
    end

    -- Execute with assess
    send("queue addclear freestand " .. atk .. ";assess " .. target)

    -- Update execute step if in execute phase and limb broke
    if phase == "EXECUTE" then
        local step = infernalDWC.state.executeStep
        if step == 0 and infernalDWC.isArmBroken(infernalDWC.state.focusArm) then
            infernalDWC.state.executeStep = 1
            cecho("\n<green>[INF DWC]<reset> Arm 1 BROKEN! Moving to leg break.")
        elseif step == 1 and infernalDWC.isFocusLegBroken() then
            infernalDWC.state.executeStep = 2
            cecho("\n<green>[INF DWC]<reset> Leg BROKEN! Target should be PRONE. Moving to arm 2.")
        elseif step == 2 then
            local offArm = (infernalDWC.state.focusArm == "left") and "right" or "left"
            if infernalDWC.isArmBroken(offArm) then
                infernalDWC.state.executeStep = 3
                cecho("\n<green>[INF DWC]<reset> Arm 2 BROKEN! Ready for VIVISECT!")
            end
        end
    end
end

-------------------------------------------------------------------------------
-- STATUS DISPLAY
-------------------------------------------------------------------------------

function infernalDWCStatus()
    local tar = target or "None"
    local phase = infernalDWC.getPhase()
    local la = infernalDWC.getLA()
    local ra = infernalDWC.getRA()
    local ll = infernalDWC.getLL()
    local rl = infernalDWC.getRL()

    cecho("\n<cyan>========================================<reset>")
    -- Show which tracking system is in use
    local trackingSystem = "V1 (tAffs)"
    if ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
        trackingSystem = "V2 (tAffsV2)"
    end
    cecho("\n<cyan>[INF DWC VIVISECT]<reset> Target: <yellow>" .. tar .. "<reset> | Tracking: <yellow>" .. trackingSystem .. "<reset>")
    cecho("\n<cyan>[INF DWC]<reset> Phase: <yellow>" .. phase .. "<reset>")

    if phase == "EXECUTE" then
        cecho(" | Step: <yellow>" .. infernalDWC.state.executeStep .. "<reset>")
    end

    -- Limb status
    local laColor = la >= 90 and "<green>" or "<red>"
    local raColor = ra >= 90 and "<green>" or "<red>"
    local llColor = ll >= 90 and "<green>" or "<red>"
    local rlColor = rl >= 90 and "<green>" or "<red>"

    cecho("\n<cyan>[INF DWC]<reset> Arms: LA=" .. laColor .. string.format("%.1f", la) .. "%<reset>")
    cecho(" RA=" .. raColor .. string.format("%.1f", ra) .. "%<reset>")
    cecho("\n<cyan>[INF DWC]<reset> Legs: LL=" .. llColor .. string.format("%.1f", ll) .. "%<reset>")
    cecho(" RL=" .. rlColor .. string.format("%.1f", rl) .. "%<reset>")

    -- Lock status
    local lockCount = infernalDWC.countLockAffs()
    local lockColor = lockCount >= 5 and "<green>" or "<yellow>"
    cecho("\n<cyan>[INF DWC]<reset> Lock: " .. lockColor .. lockCount .. "/5<reset>")

    if infernalDWC.checkSoftLock() then
        cecho(" <green>SOFT LOCK!<reset>")
    end
    if infernalDWC.checkVenomLock() then
        cecho(" <green>VENOM LOCK!<reset>")
    end

    -- Affliction checklist (using V2-compatible helper)
    local hasAff = infernalDWC.hasAff
    local affs = {
        {"nau", hasAff("nausea")},
        {"clu", hasAff("clumsiness")},
        {"wea", hasAff("weariness")},
        {"sli", hasAff("slickness")},
        {"ast", hasAff("asthma")},
        {"ano", hasAff("anorexia")},
        {"par", hasAff("paralysis")},
        {"stu", hasAff("stupidity")},
    }

    cecho("\n<cyan>[INF DWC]<reset> Affs: ")
    for _, aff in ipairs(affs) do
        if aff[2] then
            cecho("<green>" .. aff[1] .. "<reset> ")
        else
            cecho("<red>" .. aff[1] .. "<reset> ")
        end
    end

    -- Defenses status (rebounding/shield)
    cecho("\n<cyan>[INF DWC]<reset> Defs: ")
    if hasAff("rebounding") then
        cecho("<red>REBOUNDING<reset> ")
    else
        cecho("<green>no reb<reset> ")
    end
    if hasAff("shield") then
        cecho("<red>SHIELD<reset> ")
    else
        cecho("<green>no shd<reset> ")
    end

    -- Prone status
    if hasAff("prone") then
        cecho("\n<cyan>[INF DWC]<reset> <green>TARGET IS PRONE<reset>")
    end

    cecho("\n<cyan>========================================<reset>")
end

-------------------------------------------------------------------------------
-- RESET AND INITIALIZATION
-------------------------------------------------------------------------------

function infernalDWCReset()
    infernalDWC.state.phase = "NAUSEA_SETUP"
    infernalDWC.state.executeStep = 0
    infernalDWC.state.focusArm = "left"
    infernalDWC.state.focusLeg = "left"
    infernalDWC.state.lastPhase = nil
    cecho("\n<cyan>[INF DWC]<reset> State reset!")
end

function infernalDWCSetWeapons(weapon1, weapon2)
    if weapon1 then infernalDWC.config.weapon1 = weapon1 end
    if weapon2 then infernalDWC.config.weapon2 = weapon2 end
    cecho("\n<cyan>[INF DWC]<reset> Weapons set: " .. infernalDWC.config.weapon1 .. ", " .. infernalDWC.config.weapon2)
end

function infernalDWCSetFocusLeg(side)
    if side == "left" or side == "right" then
        infernalDWC.state.focusLeg = side
        cecho("\n<cyan>[INF DWC]<reset> Focus leg set to: " .. side)
    else
        cecho("\n<red>[INF DWC]<reset> Invalid leg side. Use 'left' or 'right'.")
    end
end

-------------------------------------------------------------------------------
-- ALIASES (for convenience)
-------------------------------------------------------------------------------

-- Main attack alias: infdwc or infernaldwcvivisect
-- Status alias: infdwcstatus or infernaldwcstatus
-- Reset alias: infdwcreset or infernaldwcreset
-- Set weapons: infdwcweapons weapon1 weapon2
-- Set focus leg: infdwcleg left/right

cecho("\n<cyan>[INF DWC Vivisect]<reset> Loaded! Use infernalDWCVivisect() to attack.")
cecho("\n<cyan>[INF DWC Vivisect]<reset> Commands: infernalDWCStatus(), infernalDWCReset(), infernalDWCSetWeapons(w1, w2)")
cecho("\n<cyan>[INF DWC Vivisect]<reset> Supports affliction tracking V2 (set ataxia.settings.useAffTrackingV2 = true)")
