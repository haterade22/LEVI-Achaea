--[[mudlet
type: script
name: Infernal_DWC_Vivisect_2L
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

--[[mudlet
type: script
name: Infernal DWC Vivisect 2L
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
===============================================================================
                    INFERNAL DWC 2-LIMB VIVISECT OFFENSE
===============================================================================

KILL CONDITION:
    VIVISECT requires ALL 4 LIMBS to have at least LEVEL 1 break:
    - Level 1 break = from epteth/epseth venoms (applied via DSL)
    - Level 2 break = from actually breaking the limb (100%+ damage)

    The 2-limb vivisect sequence achieves this with only 2 physical breaks
    and only 2 prepped limbs:
    - Left leg: Level 2 (undercut breaks it)
    - Right arm: Level 2 (DSL breaks it)
    - Left arm: Level 1 (epteth venom on DSL provides this)
    - Right leg: Level 1 (epseth venom on DSL provides this)

-------------------------------------------------------------------------------
PHASE OVERVIEW:
-------------------------------------------------------------------------------

    PREP PHASE:
        Build afflictions AND prep 2 limbs simultaneously.
        - Venom priority: clumsiness -> nausea -> healthleech -> asthma -> slickness -> anorexia/exploit -> aconite/recklessness
        - Limb prepping: Right arm + left leg to 90%+ damage (2 limbs only)
        - Transition to EXECUTE when both limbs prepped

    EXECUTE PHASE:
        Step 0: UNDERCUT with battleaxe
            - Command: wield battleaxe;hellforge invest exploit;undercut <target> left leg
            - Result: Breaks left leg (Level 2) + prones target + 4 SECOND SALVE LOCK
            - The salve lock is critical - they cannot mend during this window

        Step 1: DSL RIGHT ARM with epteth/epseth
            - Command: DSL right arm with epteth (sword 1) + epseth (sword 2)
            - Result: Breaks right arm (Level 2) + epteth gives Level 1 to left arm
                      + epseth gives Level 1 to right leg
            - After this attack, ALL 4 LIMBS have at least Level 1 -> can vivisect

    KILL PHASE:
        - Execute vivisect when leg broken + right arm broken
        - The epteth/epseth venoms have already provided Level 1 to remaining limbs

    DAMAGE KILL (Highest Priority - Overrides ALL Phases):
        - If target health <= 40% (ataxiaTemp.lastAssess), use QUASH + ARC
        - This takes priority over PREP, EXECUTE, KILL, and RIFTLOCK phases
        - When they're low, finish them with damage instead of completing vivisect setup
        - Quash removes shields and deals damage, Arc is a high-damage follow-up

-------------------------------------------------------------------------------
RIFTLOCK MODE (Counter to RESTORE):
-------------------------------------------------------------------------------

    If target uses RESTORE (heals all broken limbs), we enter RIFTLOCK mode.

    RESTORE Detection:
        Trigger pattern: "X crackles with blue energy that wreathes itself about his limbs."
        When detected: Call infernalDWC2L.enterRiftlock()
        Also reset limb counter: lb[target].hits for all limbs to 0
        Also clear broken limb afflictions: erAff("brokenleftleg"), etc.

    RIFTLOCK Strategy:
        1. Break LEFT ARM with kalmia/vardrax (asthma + addiction)
        2. Then go for RIFT LOCK afflictions:
           - Anorexia (slike): Blocks eating herbs
           - Slickness (gecko): Blocks applying salves
           - Addiction (vardrax): When stuck, eating triggers cooldown preventing further eating
           - Paralysis (curare): Always maintained

    Rift Lock = They cannot cure because:
        - Can't eat herbs (anorexia)
        - Can't apply salves (slickness)
        - If they do eat, addiction triggers cooldown

-------------------------------------------------------------------------------
VENOM PRIORITY (PREP PHASE):
-------------------------------------------------------------------------------

    Phase 1 (Build to asthma):
        v1 chain:
            1. Clumsiness (xentio)      - 33% miss chance on their attacks
            2. Nausea (euphorbia)       - Parry bypass, enables limb prepping
            3. Healthleech (torment)    - Drains health (hellforge investment)
            4. Asthma (kalmia)          - Blocks smoke cures
        v2: Curare (paralysis) - Always

    Phase 2 (Push slickness): Once asthma >50% / stuck
        v1: Slickness (gecko)          - Blocks apply (salve cures)
        v2: Curare (paralysis)

    Phase 3 (Focus lock): Once slickness confirmed
        v1: Anorexia (slike)           - Blocks eating herbs
        v2: Exploit (weariness + paranoia, hellforge)

    Phase 4 (Complete lock): Once anorexia + weariness stuck
        v1: Stupidity (aconite)        - Focus bait
        v2: Recklessness (eurypteria)  - Prevents defensive abilities

-------------------------------------------------------------------------------
EXECUTE PHASE VENOMS:
-------------------------------------------------------------------------------

    Step 0 (Undercut):
        - No venoms (battleaxe + hellforge exploit investment)

    Step 1 (Break right arm):
        - V1: epteth (gives Level 1 break to left arm)
        - V2: epseth (gives Level 1 break to right leg)

-------------------------------------------------------------------------------
LIMB PREPPING (2-LIMB):
-------------------------------------------------------------------------------

    - Limbs are tracked via Romaen's limb counter: lb[target].hits["left arm"], etc.
    - Prepped = 90%+ damage (prepThreshold)
    - Broken = 100%+ damage (breakThreshold)

    PREP targets (in order):
        1. Right arm (the arm we will DSL with epteth/epseth)
        2. Left leg (the leg we will undercut)

    Only prep limbs when NAUSEA is stuck (parry bypass active).

-------------------------------------------------------------------------------
CONFIGURATION:
-------------------------------------------------------------------------------

    infernalDWC2L.config = {
        prepThreshold = 90,             -- Limb ready for break
        breakThreshold = 100,           -- Limb breaks at this damage
        weapon1 = "scimitar405403",     -- Right hand scimitar
        weapon2 = "scimitar405398",     -- Left hand scimitar
        battleaxe = "battleaxe590991",  -- Battleaxe for undercut
        damageKillThreshold = 40,       -- Below this HP%, use quash+arc instead of vivisect
    }

-------------------------------------------------------------------------------
STATE TRACKING:
-------------------------------------------------------------------------------

    infernalDWC2L.state = {
        phase = "NAUSEA_SETUP",     -- Current phase (not used, getPhase() is dynamic)
        executeStep = 0,            -- 0=undercut, 1=right arm
        focusLeg = "left",          -- Which leg to prep/break (configurable)
        lastPhase = nil,            -- Track phase changes for debugging
        riftlockMode = false,       -- True when target uses RESTORE
    }

-------------------------------------------------------------------------------
COMMANDS:
-------------------------------------------------------------------------------

    infernalDWC2LVivisect()         -- Main attack function (alias: infdwc2l)
    infernalDWC2LStatus()           -- Show current state and limb damage
    infernalDWC2LReset()            -- Reset state to defaults
    infernalDWC2LSetWeapons(w1, w2) -- Set scimitar IDs
    infernalDWC2LSetFocusLeg(side)  -- Set focus leg ("left" or "right")
    infernalDWC2L.enterRiftlock()   -- Enter riftlock mode (call from RESTORE trigger)
    infernalDWC2L.exitRiftlock()    -- Exit riftlock mode

-------------------------------------------------------------------------------
TRIGGER SETUP (External):
-------------------------------------------------------------------------------

    RESTORE Trigger:
        Pattern: ^(\w+) crackles with blue energy that wreathes itself about (?:his|her) limbs\.$
        Code:
            if isTargeted(matches[2]) then
                tdeliverance = false
                erAff("brokenleftleg")
                erAff("brokenrightleg")
                erAff("brokenleftarm")
                erAff("brokenrightarm")
                if lb and lb[target] and lb[target].hits then
                    lb[target].hits["left arm"] = 0
                    lb[target].hits["right arm"] = 0
                    lb[target].hits["left leg"] = 0
                    lb[target].hits["right leg"] = 0
                end
                infernalDWC.enterRiftlock()
                if infernalDWC2L then
                    infernalDWC2L.enterRiftlock()
                end
            end

===============================================================================
]]--

-------------------------------------------------------------------------------
-- NAMESPACE AND STATE
-------------------------------------------------------------------------------

infernalDWC2L = infernalDWC2L or {}

-- State tracking
infernalDWC2L.state = {
    phase = "NAUSEA_SETUP",     -- Legacy field (getPhase() is dynamic now)
    executeStep = 0,            -- 0=undercut left leg, 1=DSL right arm
    focusLeg = "left",          -- Which leg to prep/break (default: left)
    lastPhase = nil,            -- Track phase changes for debugging
    riftlockMode = false,       -- True when target uses RESTORE (heals all limbs)
    parriedLimb = nil,          -- Which limb target is parrying (set on parry detection)
    lastTargetedLimb = nil,     -- Last limb we targeted (for parry detection)
}

-- Configuration
infernalDWC2L.config = {
    prepThreshold = 90,         -- Limb ready for break (90%+)
    breakThreshold = 100,       -- Limb breaks at 100%
    weapon1 = "scimitar405403", -- Right hand weapon ID
    weapon2 = "scimitar405398", -- Left hand weapon ID
    battleaxe = "battleaxe590991", -- Battleaxe for undercut
    damageKillThreshold = 40,   -- Below this health %, use quash + arc instead of vivisect
}

-------------------------------------------------------------------------------
-- LIMB DAMAGE HELPERS
-------------------------------------------------------------------------------

-- Get limb damage from Romaen's limb counter
-- Uses global 'target' variable and lb[target].hits table
function infernalDWC2L.getLA()
    if not target or not lb or not lb[target] or not lb[target].hits then return 0 end
    return tonumber(lb[target].hits["left arm"]) or 0
end

function infernalDWC2L.getRA()
    if not target or not lb or not lb[target] or not lb[target].hits then return 0 end
    return tonumber(lb[target].hits["right arm"]) or 0
end

function infernalDWC2L.getLL()
    if not target or not lb or not lb[target] or not lb[target].hits then return 0 end
    return tonumber(lb[target].hits["left leg"]) or 0
end

function infernalDWC2L.getRL()
    if not target or not lb or not lb[target] or not lb[target].hits then return 0 end
    return tonumber(lb[target].hits["right leg"]) or 0
end

-- Get DWC slash damage value
function infernalDWC2L.getSlashDamage()
    if ataxiaTables and ataxiaTables.limbData and ataxiaTables.limbData.dwcSlash then
        return tonumber(ataxiaTables.limbData.dwcSlash) or 6.6
    end
    return 6.6 -- Default fallback
end

-------------------------------------------------------------------------------
-- LIMB PREP CHECKING
-------------------------------------------------------------------------------

function infernalDWC2L.isArmPrepped(side)
    local damage = (side == "left") and infernalDWC2L.getLA() or infernalDWC2L.getRA()
    return damage >= infernalDWC2L.config.prepThreshold
end

function infernalDWC2L.isLegPrepped(side)
    local damage = (side == "left") and infernalDWC2L.getLL() or infernalDWC2L.getRL()
    return damage >= infernalDWC2L.config.prepThreshold
end

function infernalDWC2L.isArmBroken(side)
    local damage = (side == "left") and infernalDWC2L.getLA() or infernalDWC2L.getRA()
    -- Check percentage damage (level 2 break)
    if damage >= infernalDWC2L.config.breakThreshold then
        return true
    end
    -- Check affliction-based breaks (level 1 from epteth/epseth, level 2 from physical)
    if tAffs then
        if side == "left" then
            return tAffs.damagedleftarm or tAffs.crippledleftarm or tAffs.brokenleftarm
        else
            return tAffs.damagedrightarm or tAffs.crippledrightarm or tAffs.brokenrightarm
        end
    end
    return false
end

function infernalDWC2L.isLegBroken(side)
    local damage = (side == "left") and infernalDWC2L.getLL() or infernalDWC2L.getRL()
    -- Check percentage damage (level 2 break)
    if damage >= infernalDWC2L.config.breakThreshold then
        return true
    end
    -- Check affliction-based breaks (level 1 from epteth/epseth, level 2 from physical)
    if tAffs then
        if side == "left" then
            return tAffs.damagedleftleg or tAffs.crippledleftleg or tAffs.brokenleftleg
        else
            return tAffs.damagedrightleg or tAffs.crippledrightleg or tAffs.brokenrightleg
        end
    end
    return false
end

function infernalDWC2L.areBothArmsBroken()
    return infernalDWC2L.isArmBroken("left") and infernalDWC2L.isArmBroken("right")
end

function infernalDWC2L.areBothLegsBroken()
    return infernalDWC2L.isLegBroken("left") and infernalDWC2L.isLegBroken("right")
end

function infernalDWC2L.isFocusLegPrepped()
    return infernalDWC2L.isLegPrepped(infernalDWC2L.state.focusLeg)
end

function infernalDWC2L.isFocusLegBroken()
    return infernalDWC2L.isLegBroken(infernalDWC2L.state.focusLeg)
end

-------------------------------------------------------------------------------
-- AFFLICTION TRACKING HELPERS (V2 compatible)
-------------------------------------------------------------------------------

--[[
    Tracking System Toggle:
    - ataxia.settings.useAffTrackingV2 = true   -> Use V2 ONLY (no V1 fallback)
    - ataxia.settings.useAffTrackingV2 = false  -> Use V1 only

    When V2 is enabled, V1 is completely ignored to prevent conflicts.
]]--

-- Helper to check if target has an affliction (V2 or V1, no mixing)
function infernalDWC2L.hasAff(aff)
    -- V3 system (highest priority - probability-based)
    if affConfigV3 and affConfigV3.enabled then
        return haveAffV3(aff)  -- Uses 30% threshold by default
    end

    -- V2 system (when enabled, use ONLY V2 - no fallback)
    if ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
        if haveAffV2 then
            return haveAffV2(aff)
        elseif tAffsV2 and tAffsV2[aff] then
            -- Binary system: check for any truthy value
            return true
        end
        -- V2 enabled but not loaded - return false (don't fall back to V1)
        return false
    end

    -- V1 system (only when V2 is disabled)
    -- Check for any truthy value (not just == true, as some values may be 1 or timestamps)
    if tAffs and tAffs[aff] then
        return true
    end
    return false
end

-- Get affliction probability (V3 only, returns 0-1)
-- Falls back to binary (1.0 if has, 0 if not) for V2/V1
function infernalDWC2L.getAffProb(aff)
    if affConfigV3 and affConfigV3.enabled then
        return getAffProbabilityV3(aff)
    end
    -- Fallback: binary (1.0 if has, 0 if not)
    return infernalDWC2L.hasAff(aff) and 1.0 or 0
end

-- Helper to confirm we applied an affliction (V2 or V1)
function infernalDWC2L.confirmAff(aff)
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
function infernalDWC2L.getTrackingSystem()
    if affConfigV3 and affConfigV3.enabled then
        return "V3"
    elseif ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
        return "V2"
    end
    return "V1"
end

-------------------------------------------------------------------------------
-- LOCK DETECTION
-------------------------------------------------------------------------------

-- Check if we have soft lock (ANO + SLI + AST + PAR + STU)
function infernalDWC2L.checkSoftLock()
    return infernalDWC2L.hasAff("anorexia")
       and infernalDWC2L.hasAff("slickness")
       and infernalDWC2L.hasAff("asthma")
       and infernalDWC2L.hasAff("paralysis")
       and infernalDWC2L.hasAff("stupidity")
end

-- Check if we have venom lock (soft lock + crippled limb)
function infernalDWC2L.checkVenomLock()
    if not infernalDWC2L.checkSoftLock() then return false end
    return infernalDWC2L.hasAff("damagedleftarm") or infernalDWC2L.hasAff("damagedrightarm")
        or infernalDWC2L.hasAff("damagedleftleg") or infernalDWC2L.hasAff("damagedrightleg")
end

-- Check if nausea is stuck (parry bypass active)
function infernalDWC2L.isNauseaStuck()
    return infernalDWC2L.hasAff("nausea")
end

-- Check partial lock progress (for soft lock building)
function infernalDWC2L.countLockAffs()
    local count = 0
    if infernalDWC2L.hasAff("anorexia") then count = count + 1 end
    if infernalDWC2L.hasAff("slickness") then count = count + 1 end
    if infernalDWC2L.hasAff("asthma") then count = count + 1 end
    if infernalDWC2L.hasAff("paralysis") then count = count + 1 end
    if infernalDWC2L.hasAff("stupidity") then count = count + 1 end
    return count
end

-------------------------------------------------------------------------------
-- PHASE DETECTION
-------------------------------------------------------------------------------

--[[
    PHASES (2-LIMB):
    1. PREP - Build afflictions + prep right arm + left leg to 90%+
    2. EXECUTE - Step 0: Undercut left leg (break + 4s salve lock)
                 Step 1: DSL right arm with epteth/epseth (break + level 1 to other limbs)
    3. KILL - Left leg broken + right arm broken -> vivisect
              (epteth/epseth provide level 1 to left arm and right leg)
    4. RIFTLOCK - If RESTORE detected, break left arm then go for anorexia/slickness lock
]]--

function infernalDWC2L.getPhase()
    -- Riftlock mode takes priority (when target uses RESTORE)
    if infernalDWC2L.state.riftlockMode then
        return "RIFTLOCK"
    end

    -- Kill check: Vivisect requires broken leg + broken right arm
    -- (undercut gives 4s salve lock, enough time to break right arm and vivisect)
    if infernalDWC2L.isFocusLegBroken() and infernalDWC2L.isArmBroken("right") then
        return "KILL"
    end

    -- Execute phase: right arm prepped + focus leg prepped (2 limbs only)
    if infernalDWC2L.isArmPrepped("right") and infernalDWC2L.isFocusLegPrepped() then
        return "EXECUTE"
    end

    -- Execute phase case 2: leg broken + right arm prepped (after undercut)
    if infernalDWC2L.isFocusLegBroken() and infernalDWC2L.isArmPrepped("right") then
        return "EXECUTE"
    end

    -- Default: PREP phase - building afflictions and prepping limbs
    return "PREP"
end

-------------------------------------------------------------------------------
-- VENOM SELECTION BY PHASE
-------------------------------------------------------------------------------

--[[
    VENOM PRIORITY (2-LIMB):
    Phase 1 (Build to asthma): v2 = curare (paralysis)
        1. Nausea (euphorbia)        - Parry bypass, enables limb prepping
        2. Clumsiness (xentio)       - 33% miss chance on their attacks
        3. Healthleech (torment)     - Drains health (hellforge investment)
        4. Asthma (kalmia)           - Blocks smoke cures

    Phase 2 (Push slickness): Once asthma >50% / stuck
        v1 = gecko (slickness)       - Blocks apply (salve cures)
        v2 = curare (paralysis)

    Phase 3 (Focus lock): Once slickness confirmed
        v1 = slike (anorexia)        - Blocks eating herbs
        v2 = exploit (weariness + paranoia, hellforge)

    Phase 4 (Complete lock): Once anorexia + weariness stuck
        v1 = aconite (stupidity)     - Focus bait
        v2 = eurypteria (recklessness) - Prevents defensive abilities

    CORRECT VENOM MAPPINGS:
    - curare = paralysis
    - xentio = clumsiness (NOT kalmia!)
    - euphorbia = nausea (NOT eurypteria!)
    - kalmia = asthma
    - exploit = weariness + paranoia (hellforge)
    - torture = haemophilia (hellforge)
    - torment = healthleech (hellforge)
    - slike = anorexia
    - gecko = slickness
    - aconite = stupidity
    - eurypteria = recklessness
]]--

-- V3 probability-aware venom selection for PREP phase
-- PHASE 1: clumsiness -> nausea -> healthleech -> asthma (v2 = curare)
-- PHASE 2 (Push Slickness): Once asthma >50%, v1 = gecko (slickness), v2 = curare
-- PHASE 3 (Focus Lock): Once slickness confirmed, v1 = slike (anorexia), v2 = exploit (hellforge)
-- PHASE 4 (Complete Lock): Once anorexia+weariness stuck, v1 = aconite (stupidity), v2 = eurypteria (recklessness)
function infernalDWC2L.selectVenomsV3()
    local getProb = infernalDWC2L.getAffProb

    -- Check phase conditions
    local asthmaProb = getProb("asthma")
    local slicknessProb = getProb("slickness")
    local anorexiaProb = getProb("anorexia")
    local wearinessProb = getProb("weariness")
    local stupidityProb = getProb("stupidity")
    local recklessnessProb = getProb("recklessness")

    local asthmaHigh = asthmaProb >= 0.5
    local slicknessStuck = slicknessProb >= 0.9
    local anorexiaStuck = anorexiaProb >= 0.9
    local wearinessStuck = wearinessProb >= 0.9

    -- PHASE 4: Anorexia + weariness stuck -> aconite/recklessness (complete lock)
    if slicknessStuck and anorexiaStuck and wearinessStuck then
        local v1, v2
        if stupidityProb < 0.9 then
            v1 = "aconite"        -- Stupidity (focus bait)
        else
            v1 = "slike"          -- Maintain anorexia
        end
        if recklessnessProb < 0.9 then
            v2 = "eurypteria"     -- Recklessness (prevents defensive abilities)
        else
            v2 = "aconite"        -- Maintain stupidity
        end
        return v1, v2
    end

    -- PHASE 3: Slickness confirmed -> anorexia/exploit (focus lock)
    if slicknessStuck then
        local v1, v2
        if anorexiaProb < 0.9 then
            v1 = "slike"          -- Anorexia (blocks eat)
        else
            v1 = "aconite"        -- Stupidity (focus bait) if anorexia already stuck
        end
        if wearinessProb < 0.9 then
            v2 = "exploit"        -- Weariness + Paranoia (hellforge)
        else
            v2 = "eurypteria"     -- Recklessness if weariness already stuck
        end
        return v1, v2
    end

    -- PHASE 2: Asthma >50% -> push slickness
    if asthmaHigh then
        local v1 = "gecko"        -- Slickness (blocks apply)
        local v2 = "curare"       -- Paralysis
        return v1, v2
    end

    -- PHASE 1: Build to asthma (clumsiness -> nausea -> healthleech -> asthma)
    local v1Chain = {
        {venom = "xentio",    aff = "clumsiness",  weight = 2.0},  -- 1. Clumsiness (33% miss chance)
        {venom = "euphorbia", aff = "nausea",       weight = 1.9},  -- 2. Nausea (parry bypass)
        {venom = "torment",   aff = "healthleech",  weight = 1.8}, -- 3. Healthleech (hellforge)
        {venom = "kalmia",    aff = "asthma",       weight = 1.7},  -- 4. Asthma
    }

    -- Helper to get best venom from a chain (excludes a specific venom)
    local function getBestFromChain(chain, excludeVenom)
        local candidates = {}
        for _, data in ipairs(chain) do
            if data.venom ~= excludeVenom then
                local prob = getProb(data.aff)
                if prob < 0.9 then  -- Only consider if <90% stuck
                    local score = (1 - prob) * data.weight
                    table.insert(candidates, {
                        venom = data.venom,
                        aff = data.aff,
                        prob = prob,
                        score = score
                    })
                end
            end
        end
        table.sort(candidates, function(a, b) return a.score > b.score end)
        return candidates[1] and candidates[1].venom or nil
    end

    -- Select v1 from priority chain
    local v1 = getBestFromChain(v1Chain, nil) or "xentio"

    -- v2: always curare in phase 1
    local v2 = "curare"

    return v1, v2
end

function infernalDWC2L.selectVenoms()
    local v1, v2 = nil, nil
    local phase = infernalDWC2L.getPhase()
    local hasAff = infernalDWC2L.hasAff

    --[[
        IMPORTANT: Curare (paralysis) should ALWAYS be on v2 (second sword)
        because if WE have clumsiness, we might miss the first swing.
        This ensures paralysis still lands on the second hit.
    ]]--

    if phase == "EXECUTE" then
        local step = infernalDWC2L.state.executeStep

        if step == 0 then
            -- Undercut doesn't use venoms (handled in main function)
            v1 = nil
            v2 = nil
        else
            -- Step 1: Break RIGHT arm with epteth + epseth -> then vivisect
            v1 = "epteth"
            v2 = "epseth"
        end

    elseif phase == "RIFTLOCK" then
        -- Riftlock: they used RESTORE, break left arm then go for rift lock
        -- If left arm not broken yet, use kalmia/vardrax to break it
        if not infernalDWC2L.isArmBroken("left") then
            v1 = "kalmia"
            v2 = "vardrax"
        else
            -- Left arm broken, now go for anorexia + slickness + addiction
            local anoStuck = hasAff("anorexia")
            local slickStuck = hasAff("slickness")
            local addictStuck = hasAff("addiction")

            v2 = "curare"  -- Always paralysis

            if not anoStuck then
                v1 = "slike"      -- Anorexia (blocks eat)
            elseif not slickStuck then
                v1 = "gecko"      -- Slickness (blocks apply)
            elseif not addictStuck then
                v1 = "vardrax"    -- Addiction (eating triggers cooldown)
            else
                v1 = "slike"      -- Maintain anorexia
            end
        end

    elseif phase == "KILL" then
        -- No venoms needed for vivisect
        v1 = nil
        v2 = nil

    else
        -- PREP phase - FOCUS LOCK STRATEGY (2-LIMB)
        -- Phase 1: clumsiness -> nausea -> healthleech -> asthma (v2 = curare)
        -- Phase 2: asthma stuck -> push slickness (v1 = gecko, v2 = curare)
        -- Phase 3: slickness confirmed -> anorexia/exploit (focus lock)
        -- Phase 4: anorexia + weariness stuck -> aconite/recklessness (complete lock)

        -- V3: Probability-aware venom selection
        if affConfigV3 and affConfigV3.enabled then
            return infernalDWC2L.selectVenomsV3()
        end

        -- Binary logic (V2/V1 fallback)
        -- Check what's stuck
        local nausStuck = hasAff("nausea")
        local clumStuck = hasAff("clumsiness")
        local hlthlStuck = hasAff("healthleech")
        local asthStuck = hasAff("asthma")
        local slickStuck = hasAff("slickness")
        local anoStuck = hasAff("anorexia")
        local wearStuck = hasAff("weariness")
        local stuStuck = hasAff("stupidity")
        local reckStuck = hasAff("recklessness")

        -- PHASE 4: Anorexia + weariness stuck -> aconite/recklessness (complete lock)
        if slickStuck and anoStuck and wearStuck then
            if not stuStuck then
                v1 = "aconite"        -- Stupidity (focus bait)
            else
                v1 = "slike"          -- Maintain anorexia
            end
            if not reckStuck then
                v2 = "eurypteria"     -- Recklessness (prevents defensive abilities)
            else
                v2 = "aconite"        -- Maintain stupidity
            end

        -- PHASE 3: Slickness confirmed -> anorexia/exploit (focus lock)
        elseif slickStuck then
            if not anoStuck then
                v1 = "slike"          -- Anorexia (blocks eat)
            else
                v1 = "aconite"        -- Stupidity if anorexia already stuck
            end
            if not wearStuck then
                v2 = "exploit"        -- Weariness + Paranoia (hellforge)
            else
                v2 = "eurypteria"     -- Recklessness if weariness already stuck
            end

        -- PHASE 2: Asthma stuck -> push slickness
        elseif asthStuck then
            v1 = "gecko"             -- Slickness (blocks apply)
            v2 = "curare"            -- Paralysis

        -- PHASE 1: Build to asthma (clumsiness -> nausea -> healthleech -> asthma)
        else
            v2 = "curare"            -- Always paralysis

            if not clumStuck then
                v1 = "xentio"        -- 1. Clumsiness (33% miss chance)
            elseif not nausStuck then
                v1 = "euphorbia"     -- 2. Nausea (parry bypass)
            elseif not hlthlStuck then
                v1 = "torment"       -- 3. Healthleech (hellforge)
            elseif not asthStuck then
                v1 = "kalmia"        -- 4. Asthma (blocks smoke)
            else
                v1 = "xentio"        -- Maintain clumsiness
            end
        end
    end

    return v1, v2
end

-------------------------------------------------------------------------------
-- LIMB TARGET SELECTION (2-LIMB)
-------------------------------------------------------------------------------

-- DWC hits ONE limb per attack (both swords hit same limb)
function infernalDWC2L.selectLimbTarget()
    local phase = infernalDWC2L.getPhase()

    if phase == "PREP" then
        local focusLeg = infernalDWC2L.state.focusLeg

        -- NAUSEA REQUIRED for limb targeting (parry bypass)
        -- Without nausea, they can parry whatever we hit - so don't target limbs
        if not infernalDWC2L.hasAff("nausea") then
            -- No nausea = don't target limbs, focus on building afflictions
            return nil
        end

        -- Nausea stuck = parry bypass active, can target limbs freely
        infernalDWC2L.state.parriedLimb = nil  -- Clear stale parry data

        -- 2-LIMB: Only prep right arm + focus leg
        -- Prep right arm first (the arm we will DSL with epteth/epseth)
        if not infernalDWC2L.isArmPrepped("right") then
            return "right arm"
        -- Then prep focus leg (the leg we will undercut)
        elseif not infernalDWC2L.isLegPrepped(focusLeg) then
            return focusLeg .. " leg"
        else
            -- Both prepped, maintain pressure on right arm
            return "right arm"
        end

    elseif phase == "EXECUTE" then
        local step = infernalDWC2L.state.executeStep

        if step == 0 then
            -- Step 0: Undercut targets focus leg (handled separately in main function)
            return infernalDWC2L.state.focusLeg .. " leg"
        elseif step == 1 then
            -- Step 1: Break RIGHT arm (with epteth/epseth) -> then vivisect
            return "right arm"
        end

    elseif phase == "RIFTLOCK" then
        -- Riftlock: they used RESTORE, now break left arm and go for rift lock
        -- Target left arm first (with kalmia/vardrax), then maintain pressure
        if not infernalDWC2L.isArmBroken("left") then
            return "left arm"
        end
        -- Left arm broken, maintain pressure on any unprepped limb
        if not infernalDWC2L.isArmPrepped("right") then
            return "right arm"
        end
        local focusLeg = infernalDWC2L.state.focusLeg
        if not infernalDWC2L.isLegPrepped(focusLeg) then
            return focusLeg .. " leg"
        end
        return "left arm"  -- Maintain pressure
    end

    return nil
end

-------------------------------------------------------------------------------
-- EXECUTE STEP ADVANCEMENT
-------------------------------------------------------------------------------

--[[
    EXECUTE steps:
    Step 0: Undercut left leg -> waits for leg to break
    Step 1: DSL right arm with epteth/epseth -> after right arm breaks, KILL triggers

    Note: After step 1 completes, getPhase() returns KILL (not EXECUTE),
    so step advancement beyond 1 doesn't happen in normal flow.
    RIFTLOCK handles left arm breaking separately.
]]--

-- Call this BEFORE selecting venoms/limbs to advance step based on previous attack results
function infernalDWC2L.advanceExecuteStep()
    local phase = infernalDWC2L.getPhase()

    -- Reset step if we're NOT in EXECUTE (coming from PREP or target changed)
    if phase ~= "EXECUTE" then
        if infernalDWC2L.state.executeStep ~= 0 then
            infernalDWC2L.state.executeStep = 0
        end
        return
    end

    local step = infernalDWC2L.state.executeStep

    if step == 0 then
        -- Step 0 -> 1: Check if leg broke from undercut
        if infernalDWC2L.isFocusLegBroken() then
            infernalDWC2L.state.executeStep = 1
            cecho("\n<green>[INF DWC 2L]<reset> Leg BROKEN (4s salve lock)! DSL right arm with epteth/epseth.")
        end
    end
    -- Note: Step 1 doesn't advance because KILL triggers when right arm breaks
    -- (leg broken + right arm broken = KILL phase)
end

-------------------------------------------------------------------------------
-- DAMAGE KILL CHECK (quash + arc when target low health)
-------------------------------------------------------------------------------

-- Check if target is below damage kill threshold (uses ataxiaTemp.lastAssess from assess)
function infernalDWC2L.shouldDamageKill()
    if not ataxiaTemp or not ataxiaTemp.lastAssess then
        return false
    end
    return ataxiaTemp.lastAssess <= infernalDWC2L.config.damageKillThreshold
end

-- Get target health % from last assess
function infernalDWC2L.getTargetHealth()
    if ataxiaTemp and ataxiaTemp.lastAssess then
        return ataxiaTemp.lastAssess
    end
    return 100  -- Default to full health if unknown
end

-------------------------------------------------------------------------------
-- RIFTLOCK MODE (when target uses RESTORE)
-------------------------------------------------------------------------------

-- Call this when RESTORE is detected (trigger: "X crackles with blue energy...")
function infernalDWC2L.enterRiftlock()
    infernalDWC2L.state.riftlockMode = true
    cecho("\n<red>[INF DWC 2L]<reset> RESTORE detected! Entering RIFTLOCK mode.")
end

-- Exit riftlock (manual or when riftlock achieved)
function infernalDWC2L.exitRiftlock()
    infernalDWC2L.state.riftlockMode = false
    cecho("\n<green>[INF DWC 2L]<reset> Exiting RIFTLOCK mode.")
end

-------------------------------------------------------------------------------
-- PARRY HANDLING
-------------------------------------------------------------------------------

--[[
    When our attack gets parried, it means nausea is NOT active on the target
    (nausea bypasses parry). We track which limb they parried and switch to
    the other prep target until nausea sticks again.

    Call infernalDWC2L.onParry() from the parry trigger:
        Pattern: ^(\w+) parries the attack with a deft manoeuvre\.$
        Code: if infernalDWC2L then infernalDWC2L.onParry() end
]]--

-- Called when our attack is parried. Uses lastTargetedLimb to know which limb.
-- Can also accept a limb parameter directly (e.g. from ataxiaTemp.parriedLimb).
function infernalDWC2L.onParry(limb)
    limb = limb or infernalDWC2L.state.lastTargetedLimb
    if limb then
        infernalDWC2L.state.parriedLimb = limb
        -- Parry means nausea is NOT active (nausea bypasses parry)
        if erAff then erAff("nausea") end
        cecho("\n<yellow>[INF DWC 2L]<reset> PARRY on <red>" .. limb .. "<reset>! Switching limb target.")
    end
end

-- Clear parry tracking (called when nausea is confirmed)
function infernalDWC2L.clearParry()
    infernalDWC2L.state.parriedLimb = nil
end

-------------------------------------------------------------------------------
-- MAIN DISPATCH FUNCTION
-------------------------------------------------------------------------------

function infernalDWC2LVivisect()
    --[[
    PRIORITY ORDER:
    1. VIVISECT - All 4 limbs broken at level 1+ -> instant kill
    2. DAMAGE KILL - Health <=40% -> quash + arc (any phase except vivisect)
    3. RIFTLOCK - In EXECUTE and target used RESTORE -> lock them down
    4. EXECUTE - Break limbs in sequence (undercut -> DSL right arm)
    5. PREP - Build limb damage to prep threshold (2 limbs only)
    ]]--

    -- Use global 'target' variable (set by "t <name>" command)
    if not target or target == "" then
        cecho("\n<red>[INF DWC 2L]<reset> No target set! Use: t <name>")
        return
    end

    -- Get current phase (for display and venom/limb selection)
    local phase = infernalDWC2L.getPhase()

    -- Track phase changes for debugging
    if phase ~= infernalDWC2L.state.lastPhase then
        cecho("\n<cyan>[INF DWC 2L]<reset> Phase: <yellow>" .. phase .. "<reset>")
        infernalDWC2L.state.lastPhase = phase
    end

    --------------------------------------------------------------------------
    -- PRIORITY 1: VIVISECT - All 4 limbs broken at level 1+
    --------------------------------------------------------------------------
    if infernalDWC2L.areBothArmsBroken() and infernalDWC2L.areBothLegsBroken() then
        send("queue addclear freestand vivisect " .. target)
        cecho("\n<green>[INF DWC 2L]<reset> VIVISECT! All 4 limbs broken!")
        return
    end

    --------------------------------------------------------------------------
    -- PRIORITY 2: DAMAGE KILL - Health <=40%
    --------------------------------------------------------------------------
    if infernalDWC2L.shouldDamageKill() then
        local healthPct = infernalDWC2L.getTargetHealth()
        send("queue addclear freestand quash " .. target .. ";arc " .. target)
        cecho("\n<red>[INF DWC 2L]<reset> DAMAGE KILL! Target at " .. healthPct .. "% - QUASH + ARC!")
        return
    end

    --------------------------------------------------------------------------
    -- PRIORITY 3: RIFTLOCK - Target used RESTORE during EXECUTE
    --------------------------------------------------------------------------
    if infernalDWC2L.state.riftlockMode then
        -- RIFTLOCK: Focus on anorexia/slickness to lock them down
        -- Then break left arm for salve pressure
        local v1, v2 = infernalDWC2L.selectVenoms()  -- Will return riftlock venoms
        local limb = infernalDWC2L.selectLimbTarget()  -- Will target arms for riftlock

        -- Build attack command
        local weapon1 = infernalDWC2L.config.weapon1
        local weapon2 = infernalDWC2L.config.weapon2
        local atk = "wield right " .. weapon1 .. ";wield left " .. weapon2
        atk = atk .. ";wipe " .. weapon1 .. ";wipe " .. weapon2

        -- Check for rebounding/shield (trust hasAff() V3→V2→V1 hierarchy)
        local hasRebounding = infernalDWC2L.hasAff("rebounding")
        local hasShield = infernalDWC2L.hasAff("shield")

        if hasRebounding or hasShield then
            local rslVenom = v2 or v1 or "curare"
            atk = atk .. ";rsl " .. target .. " " .. rslVenom
            cecho("\n<yellow>[INF DWC 2L]<reset> RIFTLOCK | Razing " .. (hasRebounding and "REBOUNDING" or "SHIELD"))
        else
            atk = atk .. ";dsl " .. target .. " " .. limb .. " " .. (v1 or "slike") .. " " .. (v2 or "curare")
            cecho("\n<magenta>[INF DWC 2L]<reset> RIFTLOCK | " .. limb .. " | " .. (v1 or "slike") .. "/" .. (v2 or "curare"))
        end

        send("queue addclear freestand " .. atk .. ";assess " .. target)
        return
    end

    --------------------------------------------------------------------------
    -- PRIORITY 4: EXECUTE - Break limbs in sequence
    --------------------------------------------------------------------------
    -- Advance EXECUTE step if previous attack broke a limb
    infernalDWC2L.advanceExecuteStep()

    -- EXECUTE STEP 0: Undercut with battleaxe
    if phase == "EXECUTE" and infernalDWC2L.state.executeStep == 0 then
        local leg = infernalDWC2L.state.focusLeg
        local battleaxe = infernalDWC2L.config.battleaxe

        -- Wield battleaxe, invest exploit, undercut
        local atk = "wield " .. battleaxe .. " left"
        atk = atk .. ";hellforge invest exploit"
        atk = atk .. ";undercut " .. target .. " " .. leg .. " leg"

        cecho("\n<cyan>[INF DWC 2L]<reset> <yellow>EXECUTE<reset> | " .. leg .. " leg | UNDERCUT | [prone + break]")
        send("queue addclear freestand " .. atk .. ";assess " .. target)
        return
    end

    --------------------------------------------------------------------------
    -- PRIORITY 5: PREP / EXECUTE continuation (DSL attacks)
    --------------------------------------------------------------------------
    -- Get venoms and limb target
    local v1, v2 = infernalDWC2L.selectVenoms()
    local limb = infernalDWC2L.selectLimbTarget()

    -- Track last targeted limb for parry detection
    infernalDWC2L.state.lastTargetedLimb = limb

    -- Populate envenomList for trigger tracking (critical for affliction detection)
    -- The DWC triggers use these global lists to know what afflictions to track
    envenomList = envenomList or {}
    envenomListTwo = envenomListTwo or {}
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.hitCount = 0  -- Reset hit counter for this attack

    -- Clear and set up venom lists for the triggers
    envenomList = {}
    envenomListTwo = {}
    if v1 then table.insert(envenomList, v1) end
    if v2 then table.insert(envenomListTwo, v2) end

    -- Build base command
    local weapon1 = infernalDWC2L.config.weapon1
    local weapon2 = infernalDWC2L.config.weapon2
    local atk = "wield right " .. weapon1 .. ";wield left " .. weapon2
    atk = atk .. ";wipe " .. weapon1 .. ";wipe " .. weapon2

    -- REBOUNDING CHECK - MUST clear rebounding first or attacks bounce back!
    -- Rebounding causes all melee attacks to reflect damage back to attacker
    -- RSL uses first sword to raze, second sword applies venom
    -- IMPORTANT: RSL cannot use hellforge investments (exploit/torture/torment)
    -- Must use a regular venom like curare
    -- Trust hasAff() which routes through V3→V2→V1 hierarchy based on what's enabled
    local hasRebounding = infernalDWC2L.hasAff("rebounding")
    if hasRebounding then
        -- Determine which venom to use for RSL (must NOT be a hellforge investment)
        local rslVenom = nil
        local isV1Hellforge = (v1 == "exploit" or v1 == "torture" or v1 == "torment")
        local isV2Hellforge = (v2 == "exploit" or v2 == "torture" or v2 == "torment")

        if v2 and not isV2Hellforge then
            rslVenom = v2  -- Prefer v2 (usually curare)
        elseif v1 and not isV1Hellforge then
            rslVenom = v1
        end

        -- Update envenomLists to reflect what RSL actually applies
        -- RSL: first sword razes (no venom), second sword applies rslVenom
        envenomList = {}
        envenomListTwo = {}
        if rslVenom then
            table.insert(envenomListTwo, rslVenom)
            -- razeslash removes rebounding AND applies venom
            atk = atk .. ";rsl " .. target .. " " .. rslVenom
        else
            atk = atk .. ";raze " .. target
        end
        -- Execute raze and return - don't continue with normal attack
        send("queue addclear freestand " .. atk .. ";assess " .. target)
        cecho("\n<yellow>[INF DWC 2L]<reset> Razing REBOUNDING!")
        return
    end

    -- SHIELD CHECK - must clear shield before attacks land
    -- Same logic as rebounding - RSL can't use hellforge investments
    -- Trust hasAff() which routes through V3→V2→V1 hierarchy based on what's enabled
    local hasShield = infernalDWC2L.hasAff("shield")
    if hasShield then
        local rslVenom = nil
        local isV1Hellforge = (v1 == "exploit" or v1 == "torture" or v1 == "torment")
        local isV2Hellforge = (v2 == "exploit" or v2 == "torture" or v2 == "torment")

        if v2 and not isV2Hellforge then
            rslVenom = v2
        elseif v1 and not isV1Hellforge then
            rslVenom = v1
        end

        -- Update envenomLists to reflect what RSL actually applies
        envenomList = {}
        envenomListTwo = {}
        if rslVenom then
            table.insert(envenomListTwo, rslVenom)
            atk = atk .. ";rsl " .. target .. " " .. rslVenom
        else
            atk = atk .. ";raze " .. target
        end
        send("queue addclear freestand " .. atk .. ";assess " .. target)
        cecho("\n<yellow>[INF DWC 2L]<reset> Razing SHIELD!")
        return
    end

    -- No rebounding or shield - proceed with normal attack
    if false then
        -- This block intentionally empty - placeholder for the elseif chain below
    -- Handle hellforge investments (exploit, torture, torment)
    -- IMPORTANT: When using hellforge invest, the investment type MUST also be included
    -- as a "venom" in the DSL command. invest consumes the sword venom but DSL still
    -- needs to specify what effect to apply.
    -- Correct: "hellforge invest exploit;dsl target exploit curare"
    -- Wrong:   "hellforge invest exploit;dsl target curare"
    elseif v1 == "exploit" or v1 == "torture" or v1 == "torment" then
        atk = atk .. ";hellforge invest " .. v1
        if limb and v2 then
            -- Include v1 (the investment) as first venom in DSL
            atk = atk .. ";dsl " .. target .. " " .. limb .. " " .. v1 .. " " .. v2
        elseif v2 then
            atk = atk .. ";dsl " .. target .. " " .. v1 .. " " .. v2
        else
            atk = atk .. ";dsl " .. target .. " " .. v1
        end
    elseif v2 == "exploit" or v2 == "torture" or v2 == "torment" then
        atk = atk .. ";hellforge invest " .. v2
        if limb and v1 then
            -- Include v2 (the investment) as second venom in DSL
            atk = atk .. ";dsl " .. target .. " " .. limb .. " " .. v1 .. " " .. v2
        elseif v1 then
            atk = atk .. ";dsl " .. target .. " " .. v1 .. " " .. v2
        else
            atk = atk .. ";dsl " .. target .. " " .. v2
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

    -- Echo attack status (phase, afflictions, limbs, venoms)
    local affStr = ""
    if infernalDWC2L.hasAff("clumsiness") then affStr = affStr .. "clu " end
    if infernalDWC2L.hasAff("nausea") then affStr = affStr .. "nau " end
    if infernalDWC2L.hasAff("healthleech") then affStr = affStr .. "hle " end
    if infernalDWC2L.hasAff("haemophilia") then affStr = affStr .. "hae " end
    if infernalDWC2L.hasAff("sensitivity") then affStr = affStr .. "sen " end
    if infernalDWC2L.hasAff("weariness") then affStr = affStr .. "wea " end
    if infernalDWC2L.hasAff("asthma") then affStr = affStr .. "ast " end
    if infernalDWC2L.hasAff("paralysis") then affStr = affStr .. "par " end
    if affStr == "" then affStr = "none" end

    local la = string.format("%.0f", infernalDWC2L.getLA())
    local ra = string.format("%.0f", infernalDWC2L.getRA())
    local ll = string.format("%.0f", infernalDWC2L.getLL())
    local rl = string.format("%.0f", infernalDWC2L.getRL())
    local limbStr = "LA:" .. la .. " RA:" .. ra .. " LL:" .. ll .. " RL:" .. rl

    local venomStr = (v1 or "-") .. "/" .. (v2 or "-")
    local limbTarget = limb or "body"

    cecho("\n<cyan>[INF DWC 2L]<reset> <yellow>" .. phase .. "<reset> | " .. limbTarget .. " | " .. venomStr .. " | [" .. affStr .. "] | " .. limbStr)

    -- Execute with assess
    send("queue addclear freestand " .. atk .. ";assess " .. target)
end

-------------------------------------------------------------------------------
-- STATUS DISPLAY
-------------------------------------------------------------------------------

function infernalDWC2LStatus()
    local tar = target or "None"
    local phase = infernalDWC2L.getPhase()
    local la = infernalDWC2L.getLA()
    local ra = infernalDWC2L.getRA()
    local ll = infernalDWC2L.getLL()
    local rl = infernalDWC2L.getRL()
    local targetHealth = infernalDWC2L.getTargetHealth()

    cecho("\n<cyan>========================================<reset>")
    -- Show which tracking system is in use
    local trackingSystem = "V1 (tAffs)"
    if ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
        trackingSystem = "V2 (tAffsV2)"
    end
    cecho("\n<cyan>[INF DWC 2L VIVISECT]<reset> Target: <yellow>" .. tar .. "<reset> | Tracking: <yellow>" .. trackingSystem .. "<reset>")

    -- Target health (for damage kill check)
    local healthColor = targetHealth <= infernalDWC2L.config.damageKillThreshold and "<red>" or "<green>"
    cecho("\n<cyan>[INF DWC 2L]<reset> Target HP: " .. healthColor .. targetHealth .. "%<reset>")
    if infernalDWC2L.shouldDamageKill() then
        cecho(" <red>-> DAMAGE KILL (quash+arc)<reset>")
    end

    cecho("\n<cyan>[INF DWC 2L]<reset> Phase: <yellow>" .. phase .. "<reset>")

    if phase == "EXECUTE" then
        cecho(" | Step: <yellow>" .. infernalDWC2L.state.executeStep .. "<reset>")
    end

    -- Limb status (highlight the 2 prep targets: right arm + left leg)
    local laColor = la >= 90 and "<green>" or "<red>"
    local raColor = ra >= 90 and "<green>" or "<red>"
    local llColor = ll >= 90 and "<green>" or "<red>"
    local rlColor = rl >= 90 and "<green>" or "<red>"

    cecho("\n<cyan>[INF DWC 2L]<reset> Arms: LA=" .. laColor .. string.format("%.1f", la) .. "%<reset>")
    cecho(" RA=" .. raColor .. string.format("%.1f", ra) .. "%<reset> <yellow>[PREP]<reset>")
    cecho("\n<cyan>[INF DWC 2L]<reset> Legs: LL=" .. llColor .. string.format("%.1f", ll) .. "%<reset> <yellow>[PREP]<reset>")
    cecho(" RL=" .. rlColor .. string.format("%.1f", rl) .. "%<reset>")

    -- Lock status
    local lockCount = infernalDWC2L.countLockAffs()
    local lockColor = lockCount >= 5 and "<green>" or "<yellow>"
    cecho("\n<cyan>[INF DWC 2L]<reset> Lock: " .. lockColor .. lockCount .. "/5<reset>")

    if infernalDWC2L.checkSoftLock() then
        cecho(" <green>SOFT LOCK!<reset>")
    end
    if infernalDWC2L.checkVenomLock() then
        cecho(" <green>VENOM LOCK!<reset>")
    end

    -- Affliction checklist (using V2-compatible helper)
    local hasAff = infernalDWC2L.hasAff
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

    cecho("\n<cyan>[INF DWC 2L]<reset> Affs: ")
    for _, aff in ipairs(affs) do
        if aff[2] then
            cecho("<green>" .. aff[1] .. "<reset> ")
        else
            cecho("<red>" .. aff[1] .. "<reset> ")
        end
    end

    -- Defenses status (rebounding/shield)
    cecho("\n<cyan>[INF DWC 2L]<reset> Defs: ")
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
        cecho("\n<cyan>[INF DWC 2L]<reset> <green>TARGET IS PRONE<reset>")
    end

    cecho("\n<cyan>========================================<reset>")
end

-------------------------------------------------------------------------------
-- RESET AND INITIALIZATION
-------------------------------------------------------------------------------

function infernalDWC2LReset()
    infernalDWC2L.state.phase = "NAUSEA_SETUP"
    infernalDWC2L.state.executeStep = 0
    infernalDWC2L.state.focusLeg = "left"
    infernalDWC2L.state.lastPhase = nil
    infernalDWC2L.state.riftlockMode = false
    infernalDWC2L.state.parriedLimb = nil
    infernalDWC2L.state.lastTargetedLimb = nil
    cecho("\n<cyan>[INF DWC 2L]<reset> State reset!")
end

function infernalDWC2LSetWeapons(weapon1, weapon2)
    if weapon1 then infernalDWC2L.config.weapon1 = weapon1 end
    if weapon2 then infernalDWC2L.config.weapon2 = weapon2 end
    cecho("\n<cyan>[INF DWC 2L]<reset> Weapons set: " .. infernalDWC2L.config.weapon1 .. ", " .. infernalDWC2L.config.weapon2)
end

function infernalDWC2LSetFocusLeg(side)
    if side == "left" or side == "right" then
        infernalDWC2L.state.focusLeg = side
        cecho("\n<cyan>[INF DWC 2L]<reset> Focus leg set to: " .. side)
    else
        cecho("\n<red>[INF DWC 2L]<reset> Invalid leg side. Use 'left' or 'right'.")
    end
end

-------------------------------------------------------------------------------
-- ALIASES (for convenience)
-------------------------------------------------------------------------------

-- Main attack alias: infdwc2l or infernaldwc2lvivisect
-- Status alias: infdwc2lstatus or infernaldwc2lstatus
-- Reset alias: infdwc2lreset or infernaldwc2lreset
-- Set weapons: infdwc2lweapons weapon1 weapon2
-- Set focus leg: infdwc2lleg left/right

cecho("\n<cyan>[INF DWC 2L Vivisect]<reset> Loaded! Use infernalDWC2LVivisect() to attack.")
cecho("\n<cyan>[INF DWC 2L Vivisect]<reset> Commands: infernalDWC2LStatus(), infernalDWC2LReset(), infernalDWC2LSetWeapons(w1, w2)")
cecho("\n<cyan>[INF DWC 2L Vivisect]<reset> 2-LIMB MODE: Preps right arm + left leg only (faster execute)")
cecho("\n<cyan>[INF DWC 2L Vivisect]<reset> Supports affliction tracking V2 (set ataxia.settings.useAffTrackingV2 = true)")
