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
===============================================================================
                        INFERNAL DWC VIVISECT OFFENSE
===============================================================================

KILL CONDITION:
    VIVISECT requires ALL 4 LIMBS to have at least LEVEL 1 break:
    - Level 1 break = from epteth/epseth venoms (applied via DSL)
    - Level 2 break = from actually breaking the limb (100%+ damage)

    The normal vivisect sequence achieves this with only 2 physical breaks:
    - Left leg: Level 2 (undercut breaks it)
    - Right arm: Level 2 (DSL breaks it)
    - Left arm: Level 1 (epteth venom on DSL provides this)
    - Right leg: Level 1 (epseth venom on DSL provides this)

-------------------------------------------------------------------------------
PHASE OVERVIEW:
-------------------------------------------------------------------------------

    PREP PHASE:
        Build afflictions AND prep limbs simultaneously.
        - Venom priority: clumsiness → nausea → healthleech → asthma → slickness → anorexia/exploit → aconite/recklessness
        - Limb prepping: Both arms + left leg to 90%+ damage
        - Transition to EXECUTE when all 3 limbs prepped

    EXECUTE PHASE:
        Step 0: UNDERCUT with battleaxe
            - Command: wield battleaxe;hellforge invest exploit;undercut <target> left leg
            - Result: Breaks left leg (Level 2) + prones target + 4 SECOND SALVE LOCK
            - The salve lock is critical - they cannot mend during this window

        Step 1: DSL RIGHT ARM with epteth/epseth
            - Command: DSL right arm with epteth (sword 1) + epseth (sword 2)
            - Result: Breaks right arm (Level 2) + epteth gives Level 1 to left arm
                      + epseth gives Level 1 to right leg
            - After this attack, ALL 4 LIMBS have at least Level 1 → can vivisect

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
        When detected: Call infernalDWC.enterRiftlock()
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

    PHASE 1 - Build to Asthma (v2 = curare):
        1. Clumsiness (xentio)      - 33% miss chance on their attacks
        2. Nausea (euphorbia)       - Parry bypass, enables limb prepping
        3. Healthleech (torment)    - Drains health (hellforge investment)
        4. Asthma (kalmia)          - Blocks smoke cures

    PHASE 2 - Push Slickness (once asthma >50% / stuck):
        V1: Slickness (gecko)       - Blocks apply (salve cures)
        V2: Curare (paralysis)      - Maintain paralysis

    PHASE 3 - Focus Lock (once slickness confirmed):
        V1: Anorexia (slike)        - Blocks eating
        V2: Exploit (weariness+paranoia) - Hellforge, blocks Fitness

    PHASE 4 - Complete Lock (once anorexia + weariness stuck):
        V1: Stupidity (aconite)     - Focus bait
        V2: Recklessness (eurypteria) - Prevents defensive abilities

    V2 Default: Curare (paralysis) - Critical to maintain, on V2 to survive clumsiness miss

-------------------------------------------------------------------------------
EXECUTE PHASE VENOMS:
-------------------------------------------------------------------------------

    Step 0 (Undercut):
        - No venoms (battleaxe + hellforge exploit investment)

    Step 1 (Break right arm):
        - V1: epteth (gives Level 1 break to left arm)
        - V2: epseth (gives Level 1 break to right leg)

-------------------------------------------------------------------------------
LIMB PREPPING:
-------------------------------------------------------------------------------

    - Limbs are tracked via Romaen's limb counter: lb[target].hits["left arm"], etc.
    - Prepped = 90%+ damage (prepThreshold)
    - Broken = 100%+ damage (breakThreshold)

    PREP targets (in order):
        1. Focus arm (lowest damage arm)
        2. Off arm
        3. Focus leg (left by default)

    Only prep limbs when NAUSEA is stuck (parry bypass active).

-------------------------------------------------------------------------------
CONFIGURATION:
-------------------------------------------------------------------------------

    infernalDWC.config = {
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

    infernalDWC.state = {
        phase = "NAUSEA_SETUP",     -- Current phase (not used, getPhase() is dynamic)
        executeStep = 0,            -- 0=undercut, 1=right arm
        focusArm = "left",          -- Dynamically set to lowest damage arm
        focusLeg = "left",          -- Which leg to prep/break (configurable)
        lastPhase = nil,            -- Track phase changes for debugging
        riftlockMode = false,       -- True when target uses RESTORE
    }

-------------------------------------------------------------------------------
COMMANDS:
-------------------------------------------------------------------------------

    infernalDWCVivisect()           -- Main attack function (alias: infdwc)
    infernalDWCStatus()             -- Show current state and limb damage
    infernalDWCReset()              -- Reset state to defaults
    infernalDWCSetWeapons(w1, w2)   -- Set scimitar IDs
    infernalDWCSetFocusLeg(side)    -- Set focus leg ("left" or "right")
    infernalDWC.enterRiftlock()     -- Enter riftlock mode (call from RESTORE trigger)
    infernalDWC.exitRiftlock()      -- Exit riftlock mode

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
            end

===============================================================================
]]--

-------------------------------------------------------------------------------
-- NAMESPACE AND STATE
-------------------------------------------------------------------------------

infernalDWC = infernalDWC or {}

-- State tracking
infernalDWC.state = {
    phase = "NAUSEA_SETUP",     -- Legacy field (getPhase() is dynamic now)
    executeStep = 0,            -- 0=undercut left leg, 1=DSL right arm
    focusArm = "left",          -- Dynamically set to lowest damage arm during PREP
    focusLeg = "left",          -- Which leg to prep/break (default: left)
    lastPhase = nil,            -- Track phase changes for debugging
    riftlockMode = false,       -- True when target uses RESTORE (heals all limbs)
    parriedLimb = nil,          -- Which limb target is parrying (set on parry detection)
    lastTargetedLimb = nil,     -- Last limb we targeted (for parry detection)
}

-- Configuration
infernalDWC.config = {
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
    -- Check percentage damage (level 2 break)
    if damage >= infernalDWC.config.breakThreshold then
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

function infernalDWC.isLegBroken(side)
    local damage = (side == "left") and infernalDWC.getLL() or infernalDWC.getRL()
    -- Check percentage damage (level 2 break)
    if damage >= infernalDWC.config.breakThreshold then
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

function infernalDWC.areBothArmsPrepped()
    return infernalDWC.isArmPrepped("left") and infernalDWC.isArmPrepped("right")
end

function infernalDWC.areBothArmsBroken()
    return infernalDWC.isArmBroken("left") and infernalDWC.isArmBroken("right")
end

function infernalDWC.areBothLegsBroken()
    return infernalDWC.isLegBroken("left") and infernalDWC.isLegBroken("right")
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
function infernalDWC.getAffProb(aff)
    if affConfigV3 and affConfigV3.enabled then
        return getAffProbabilityV3(aff)
    end
    -- Fallback: binary (1.0 if has, 0 if not)
    return infernalDWC.hasAff(aff) and 1.0 or 0
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

--[[
    PHASES:
    1. PREP - Build afflictions + prep both arms + left leg to 90%+
    2. EXECUTE - Step 0: Undercut left leg (break + 4s salve lock)
                 Step 1: DSL right arm with epteth/epseth (break + level 1 to other limbs)
    3. KILL - Left leg broken + right arm broken → vivisect
              (epteth/epseth provide level 1 to left arm and right leg)
    4. RIFTLOCK - If RESTORE detected, break left arm then go for anorexia/slickness lock
]]--

function infernalDWC.getPhase()
    -- Riftlock mode takes priority (when target uses RESTORE)
    if infernalDWC.state.riftlockMode then
        return "RIFTLOCK"
    end

    -- Kill check: Vivisect requires broken leg + broken right arm
    -- (undercut gives 4s salve lock, enough time to break right arm and vivisect)
    if infernalDWC.isFocusLegBroken() and infernalDWC.isArmBroken("right") then
        return "KILL"
    end

    -- Execute phase case 1: all limbs prepped (starting execute)
    if infernalDWC.areBothArmsPrepped() and infernalDWC.isFocusLegPrepped() then
        return "EXECUTE"
    end

    -- Execute phase case 2: leg broken + right arm prepped (after undercut)
    if infernalDWC.isFocusLegBroken() and infernalDWC.isArmPrepped("right") then
        return "EXECUTE"
    end

    -- Default: PREP phase - building afflictions and prepping limbs
    return "PREP"
end

-------------------------------------------------------------------------------
-- VENOM SELECTION BY PHASE
-------------------------------------------------------------------------------

--[[
    VENOM PRIORITY (user specified):
    1. Paralysis (curare)
    2. Clumsiness (xentio) - 33% miss chance
    3. Nausea (euphorbia) - parry bypass
    4. Asthma (kalmia)
    5. Weariness (exploit - hellforge investment)
    6. Healthleech (torture - hellforge investment)
    7. Softlock afflictions (once asthma is stuck):
       - Anorexia (slike)
       - Slickness (gecko)
       - Stupidity (aconite)

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
]]--

-- V3 probability-aware venom selection for PREP phase
-- PHASE 1: clumsiness -> nausea -> healthleech -> asthma (v2 = curare)
-- PHASE 2 (Push Slickness): Once asthma >50%, v1 = gecko (slickness), v2 = curare
-- PHASE 3 (Focus Lock): Once slickness confirmed, v1 = slike (anorexia), v2 = exploit (hellforge)
-- PHASE 4 (Complete Lock): Once anorexia+weariness stuck, v1 = aconite (stupidity), v2 = eurypteria (recklessness)
function infernalDWC.selectVenomsV3()
    local getProb = infernalDWC.getAffProb

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

function infernalDWC.selectVenoms()
    local v1, v2 = nil, nil
    local phase = infernalDWC.getPhase()
    local hasAff = infernalDWC.hasAff

    --[[
        IMPORTANT: Curare (paralysis) should ALWAYS be on v2 (second sword)
        because if WE have clumsiness, we might miss the first swing.
        This ensures paralysis still lands on the second hit.
    ]]--

    if phase == "EXECUTE" then
        local step = infernalDWC.state.executeStep

        if step == 0 then
            -- Undercut doesn't use venoms (handled in main function)
            v1 = nil
            v2 = nil
        else
            -- Step 1: Break RIGHT arm with epteth + epseth → then vivisect
            v1 = "epteth"
            v2 = "epseth"
        end

    elseif phase == "RIFTLOCK" then
        -- Riftlock: they used RESTORE, break left arm then go for rift lock
        -- If left arm not broken yet, use kalmia/vardrax to break it
        if not infernalDWC.isArmBroken("left") then
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
        -- PREP phase - FOCUS LOCK STRATEGY
        -- Phase 1: clumsiness -> nausea -> healthleech -> asthma (v2 = curare)
        -- Phase 2: asthma stuck -> push slickness (v1 = gecko, v2 = curare)
        -- Phase 3: slickness confirmed -> anorexia/exploit (focus lock)
        -- Phase 4: anorexia + weariness stuck -> aconite/recklessness (complete lock)

        -- V3: Probability-aware venom selection
        if affConfigV3 and affConfigV3.enabled then
            return infernalDWC.selectVenomsV3()
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
-- LIMB TARGET SELECTION
-------------------------------------------------------------------------------

-- DWC hits ONE limb per attack (both swords hit same limb)
function infernalDWC.selectLimbTarget()
    local phase = infernalDWC.getPhase()

    if phase == "PREP" then
        local focusArm = infernalDWC.getFocusArm()
        local offArm = infernalDWC.getOffArm()
        local focusLeg = infernalDWC.state.focusLeg

        -- NAUSEA REQUIRED for limb targeting (parry bypass)
        -- Without nausea, they can parry whatever we hit - so don't target limbs
        if not infernalDWC.hasAff("nausea") then
            -- No nausea = don't target limbs, focus on building afflictions
            return nil
        end

        -- Nausea stuck = parry bypass active, can target limbs freely
        infernalDWC.state.parriedLimb = nil  -- Clear stale parry data

        -- Prep arms first (need both for vivisect)
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
            -- Step 0: Undercut targets focus leg (handled separately in main function)
            return infernalDWC.state.focusLeg .. " leg"
        elseif step == 1 then
            -- Step 1: Break RIGHT arm (with epteth/epseth) → then vivisect
            return "right arm"
        end

    elseif phase == "RIFTLOCK" then
        -- Riftlock: they used RESTORE, now break left arm and go for rift lock
        -- Target left arm first (with kalmia/vardrax), then maintain pressure
        if not infernalDWC.isArmBroken("left") then
            return "left arm"
        end
        -- Left arm broken, maintain pressure on any unprepped limb
        if not infernalDWC.isArmPrepped("right") then
            return "right arm"
        end
        local focusLeg = infernalDWC.state.focusLeg
        if not infernalDWC.isLegPrepped(focusLeg) then
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
    Step 0: Undercut left leg → waits for leg to break
    Step 1: DSL right arm with epteth/epseth → after right arm breaks, KILL triggers

    Note: After step 1 completes, getPhase() returns KILL (not EXECUTE),
    so step advancement beyond 1 doesn't happen in normal flow.
    RIFTLOCK handles left arm breaking separately.
]]--

-- Call this BEFORE selecting venoms/limbs to advance step based on previous attack results
function infernalDWC.advanceExecuteStep()
    local phase = infernalDWC.getPhase()

    -- Reset step if we're NOT in EXECUTE (coming from PREP or target changed)
    if phase ~= "EXECUTE" then
        if infernalDWC.state.executeStep ~= 0 then
            infernalDWC.state.executeStep = 0
            infernalDWC.state.focusArm = nil  -- Clear focusArm so it gets re-selected
        end
        return
    end

    local step = infernalDWC.state.executeStep

    if step == 0 then
        -- Step 0 → 1: Check if leg broke from undercut
        if infernalDWC.isFocusLegBroken() then
            infernalDWC.state.executeStep = 1
            cecho("\n<green>[INF DWC]<reset> Leg BROKEN (4s salve lock)! DSL right arm with epteth/epseth.")
        end
    end
    -- Note: Step 1 doesn't advance because KILL triggers when right arm breaks
    -- (leg broken + right arm broken = KILL phase)
end

-------------------------------------------------------------------------------
-- DAMAGE KILL CHECK (quash + arc when target low health)
-------------------------------------------------------------------------------

-- Check if target is below damage kill threshold (uses ataxiaTemp.lastAssess from assess)
function infernalDWC.shouldDamageKill()
    if not ataxiaTemp or not ataxiaTemp.lastAssess then
        return false
    end
    return ataxiaTemp.lastAssess <= infernalDWC.config.damageKillThreshold
end

-- Get target health % from last assess
function infernalDWC.getTargetHealth()
    if ataxiaTemp and ataxiaTemp.lastAssess then
        return ataxiaTemp.lastAssess
    end
    return 100  -- Default to full health if unknown
end

-------------------------------------------------------------------------------
-- RIFTLOCK MODE (when target uses RESTORE)
-------------------------------------------------------------------------------

-- Call this when RESTORE is detected (trigger: "X crackles with blue energy...")
function infernalDWC.enterRiftlock()
    infernalDWC.state.riftlockMode = true
    cecho("\n<red>[INF DWC]<reset> RESTORE detected! Entering RIFTLOCK mode.")
end

-- Exit riftlock (manual or when riftlock achieved)
function infernalDWC.exitRiftlock()
    infernalDWC.state.riftlockMode = false
    cecho("\n<green>[INF DWC]<reset> Exiting RIFTLOCK mode.")
end

-------------------------------------------------------------------------------
-- PARRY HANDLING
-------------------------------------------------------------------------------

--[[
    When our attack gets parried, it means nausea is NOT active on the target
    (nausea bypasses parry). We track which limb they parried and switch to
    a different prep target until nausea sticks again.

    Call infernalDWC.onParry() from the parry trigger:
        Pattern: ^(\w+) parries the attack with a deft manoeuvre\.$
        Code: if infernalDWC then infernalDWC.onParry() end
]]--

-- Called when our attack is parried. Uses lastTargetedLimb to know which limb.
-- Can also accept a limb parameter directly (e.g. from ataxiaTemp.parriedLimb).
function infernalDWC.onParry(limb)
    limb = limb or infernalDWC.state.lastTargetedLimb
    if limb then
        infernalDWC.state.parriedLimb = limb
        -- Parry means nausea is NOT active (nausea bypasses parry)
        if erAff then erAff("nausea") end
        cecho("\n<yellow>[INF DWC]<reset> PARRY on <red>" .. limb .. "<reset>! Switching limb target.")
    end
end

-- Clear parry tracking (called when nausea is confirmed)
function infernalDWC.clearParry()
    infernalDWC.state.parriedLimb = nil
end

-------------------------------------------------------------------------------
-- MAIN DISPATCH FUNCTION
-------------------------------------------------------------------------------

function infernalDWCVivisect()
    --[[
    PRIORITY ORDER:
    1. VIVISECT - All 4 limbs broken at level 1+ → instant kill
    2. DAMAGE KILL - Health ≤40% → quash + arc (any phase except vivisect)
    3. RIFTLOCK - In EXECUTE and target used RESTORE → lock them down
    4. EXECUTE - Break limbs in sequence (undercut → DSL arms)
    5. PREP - Build limb damage to prep threshold
    ]]--

    -- Use global 'target' variable (set by "t <name>" command)
    if not target or target == "" then
        cecho("\n<red>[INF DWC]<reset> No target set! Use: t <name>")
        return
    end

    -- Get current phase (for display and venom/limb selection)
    local phase = infernalDWC.getPhase()

    -- Track phase changes for debugging
    if phase ~= infernalDWC.state.lastPhase then
        cecho("\n<cyan>[INF DWC]<reset> Phase: <yellow>" .. phase .. "<reset>")
        infernalDWC.state.lastPhase = phase
    end

    --------------------------------------------------------------------------
    -- PRIORITY 1: VIVISECT - All 4 limbs broken at level 1+
    --------------------------------------------------------------------------
    if infernalDWC.areBothArmsBroken() and infernalDWC.areBothLegsBroken() then
        send("queue addclear freestand vivisect " .. target)
        cecho("\n<green>[INF DWC]<reset> VIVISECT! All 4 limbs broken!")
        return
    end

    --------------------------------------------------------------------------
    -- PRIORITY 2: DAMAGE KILL - Health ≤40%
    --------------------------------------------------------------------------
    if infernalDWC.shouldDamageKill() then
        local healthPct = infernalDWC.getTargetHealth()
        send("queue addclear freestand quash " .. target .. ";arc " .. target)
        cecho("\n<red>[INF DWC]<reset> DAMAGE KILL! Target at " .. healthPct .. "% - QUASH + ARC!")
        return
    end

    --------------------------------------------------------------------------
    -- PRIORITY 3: RIFTLOCK - Target used RESTORE during EXECUTE
    --------------------------------------------------------------------------
    if infernalDWC.state.riftlockMode then
        -- RIFTLOCK: Focus on anorexia/slickness to lock them down
        -- Then break left arm for salve pressure
        local v1, v2 = infernalDWC.selectVenoms()  -- Will return riftlock venoms
        local limb = infernalDWC.selectLimbTarget()  -- Will target arms for riftlock

        -- Build attack command
        local weapon1 = infernalDWC.config.weapon1
        local weapon2 = infernalDWC.config.weapon2
        local atk = "wield right " .. weapon1 .. ";wield left " .. weapon2
        atk = atk .. ";wipe " .. weapon1 .. ";wipe " .. weapon2

        -- Check for rebounding/shield (trust hasAff() V3→V2→V1 hierarchy)
        local hasRebounding = infernalDWC.hasAff("rebounding")
        local hasShield = infernalDWC.hasAff("shield")

        if hasRebounding or hasShield then
            local rslVenom = v2 or v1 or "curare"
            atk = atk .. ";rsl " .. target .. " " .. rslVenom
            cecho("\n<yellow>[INF DWC]<reset> RIFTLOCK | Razing " .. (hasRebounding and "REBOUNDING" or "SHIELD"))
        else
            atk = atk .. ";dsl " .. target .. " " .. limb .. " " .. (v1 or "slike") .. " " .. (v2 or "curare")
            cecho("\n<magenta>[INF DWC]<reset> RIFTLOCK | " .. limb .. " | " .. (v1 or "slike") .. "/" .. (v2 or "curare"))
        end

        send("queue addclear freestand " .. atk .. ";assess " .. target)
        return
    end

    --------------------------------------------------------------------------
    -- PRIORITY 4: EXECUTE - Break limbs in sequence
    --------------------------------------------------------------------------
    -- Advance EXECUTE step if previous attack broke a limb
    infernalDWC.advanceExecuteStep()

    -- EXECUTE STEP 0: Undercut with battleaxe
    if phase == "EXECUTE" and infernalDWC.state.executeStep == 0 then
        local leg = infernalDWC.state.focusLeg
        local battleaxe = infernalDWC.config.battleaxe

        -- Wield battleaxe, invest exploit, undercut
        local atk = "wield " .. battleaxe .. " left"
        atk = atk .. ";hellforge invest exploit"
        atk = atk .. ";undercut " .. target .. " " .. leg .. " leg"

        cecho("\n<cyan>[INF DWC]<reset> <yellow>EXECUTE<reset> | " .. leg .. " leg | UNDERCUT | [prone + break]")
        send("queue addclear freestand " .. atk .. ";assess " .. target)
        return
    end

    --------------------------------------------------------------------------
    -- PRIORITY 5: PREP / EXECUTE continuation (DSL attacks)
    --------------------------------------------------------------------------
    -- Get venoms and limb target
    local v1, v2 = infernalDWC.selectVenoms()
    local limb = infernalDWC.selectLimbTarget()

    -- Track last targeted limb for parry detection
    infernalDWC.state.lastTargetedLimb = limb

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
    local weapon1 = infernalDWC.config.weapon1
    local weapon2 = infernalDWC.config.weapon2
    local atk = "wield right " .. weapon1 .. ";wield left " .. weapon2
    atk = atk .. ";wipe " .. weapon1 .. ";wipe " .. weapon2

    -- REBOUNDING CHECK - MUST clear rebounding first or attacks bounce back!
    -- Rebounding causes all melee attacks to reflect damage back to attacker
    -- RSL uses first sword to raze, second sword applies venom
    -- IMPORTANT: RSL cannot use hellforge investments (exploit/torture/torment)
    -- Must use a regular venom like curare
    -- Trust hasAff() which routes through V3→V2→V1 hierarchy based on what's enabled
    local hasRebounding = infernalDWC.hasAff("rebounding")
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
        cecho("\n<yellow>[INF DWC]<reset> Razing REBOUNDING!")
        return
    end

    -- SHIELD CHECK - must clear shield before attacks land
    -- Same logic as rebounding - RSL can't use hellforge investments
    -- Trust hasAff() which routes through V3→V2→V1 hierarchy based on what's enabled
    local hasShield = infernalDWC.hasAff("shield")
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
        cecho("\n<yellow>[INF DWC]<reset> Razing SHIELD!")
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
    if infernalDWC.hasAff("clumsiness") then affStr = affStr .. "clu " end
    if infernalDWC.hasAff("nausea") then affStr = affStr .. "nau " end
    if infernalDWC.hasAff("healthleech") then affStr = affStr .. "hle " end
    if infernalDWC.hasAff("haemophilia") then affStr = affStr .. "hae " end
    if infernalDWC.hasAff("sensitivity") then affStr = affStr .. "sen " end
    if infernalDWC.hasAff("weariness") then affStr = affStr .. "wea " end
    if infernalDWC.hasAff("asthma") then affStr = affStr .. "ast " end
    if infernalDWC.hasAff("paralysis") then affStr = affStr .. "par " end
    if affStr == "" then affStr = "none" end

    local la = string.format("%.0f", infernalDWC.getLA())
    local ra = string.format("%.0f", infernalDWC.getRA())
    local ll = string.format("%.0f", infernalDWC.getLL())
    local rl = string.format("%.0f", infernalDWC.getRL())
    local limbStr = "LA:" .. la .. " RA:" .. ra .. " LL:" .. ll .. " RL:" .. rl

    local venomStr = (v1 or "-") .. "/" .. (v2 or "-")
    local limbTarget = limb or "body"

    cecho("\n<cyan>[INF DWC]<reset> <yellow>" .. phase .. "<reset> | " .. limbTarget .. " | " .. venomStr .. " | [" .. affStr .. "] | " .. limbStr)

    -- Execute with assess
    send("queue addclear freestand " .. atk .. ";assess " .. target)
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
    local targetHealth = infernalDWC.getTargetHealth()

    cecho("\n<cyan>========================================<reset>")
    -- Show which tracking system is in use
    local trackingSystem = "V1 (tAffs)"
    if ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
        trackingSystem = "V2 (tAffsV2)"
    end
    cecho("\n<cyan>[INF DWC VIVISECT]<reset> Target: <yellow>" .. tar .. "<reset> | Tracking: <yellow>" .. trackingSystem .. "<reset>")

    -- Target health (for damage kill check)
    local healthColor = targetHealth <= infernalDWC.config.damageKillThreshold and "<red>" or "<green>"
    cecho("\n<cyan>[INF DWC]<reset> Target HP: " .. healthColor .. targetHealth .. "%<reset>")
    if infernalDWC.shouldDamageKill() then
        cecho(" <red>→ DAMAGE KILL (quash+arc)<reset>")
    end

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
    infernalDWC.state.riftlockMode = false
    infernalDWC.state.parriedLimb = nil
    infernalDWC.state.lastTargetedLimb = nil
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
