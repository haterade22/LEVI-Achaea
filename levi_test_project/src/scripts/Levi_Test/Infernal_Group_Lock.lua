--[[
===============================================================================
                        INFERNAL GROUP LOCK OFFENSE
===============================================================================

KILL CONDITION:
    TRUE LOCK = Target cannot cure any afflictions without external help.

    Required afflictions (6 total):
    - Asthma (kalmia)       - Blocks smoke cures
    - Slickness (gecko)     - Blocks salve cures
    - Anorexia (slike)      - Blocks eating herbs
    - Paralysis (curare)    - Blocks tree tattoo escape
    - Impatience (euphorbia) - Blocks focus escape
    - Class Lock Aff        - Blocks class-specific escape (via getLockingAffliction)

-------------------------------------------------------------------------------
DESIGN PRINCIPLES:
-------------------------------------------------------------------------------

    1. NO LIMB TARGETING - Pure `dsl target v1 v2` for maximum speed
    2. ALWAYS CURARE ON V2 - Paralysis survives clumsiness miss (v1 can miss)
    3. SIMPLE CONDITIONAL LOGIC - Clear "if X, then Y" priority chain
    4. V3 PROBABILITY SUPPORT - Routes through existing tracking infrastructure
    5. MINIMAL STATE - Group combat needs fast, stateless execution
    6. HELLFORGE EXPLOIT - Use for 2-aff pressure when pushing weariness
    7. CLASS-AWARE - Use getLockingAffliction(target) for final lock aff

-------------------------------------------------------------------------------
VENOM PRIORITY CHAIN:
-------------------------------------------------------------------------------

    V1 Selection (Primary Affliction):
        Priority 1: If NO asthma        -> kalmia      (blocks smoke)
        Priority 2: If NO slickness     -> gecko       (blocks salve)
        Priority 3: If NO anorexia      -> slike       (blocks eat)
        Priority 4: If NO impatience    -> euphorbia   (blocks focus)
        Priority 5: If NO class lock    -> getLockingAffliction() venom
        Priority 6: If all stuck        -> kalmia      (reinforce, first to drop)

    V2 Selection (Always Paralysis):
        Always: curare (paralysis)

    Hellforge Exploit Integration:
        When pushing for class lock affliction and class needs weariness:
        - Use `hellforge invest exploit` (gives weariness + paranoia)
        - Otherwise use standard venom from getLockingAffliction()

    Rebounding/Shield Override:
        If rebounding OR shield -> RSL with curare (raze + apply paralysis)

-------------------------------------------------------------------------------
CLASS-SPECIFIC LOCK AFFLICTIONS:
-------------------------------------------------------------------------------

    Class                                          | Affliction    | Venom
    -----------------------------------------------|---------------|------------
    Blademaster, Druid, Infernal, Monk, Paladin,  | weariness     | vernalius
    Runewarden, Sentinel                          |               |
    Apostate, Pariah, Bard, Priest                | voyria        | voyria
    Magi, Sylvan                                  | haemophilia   | eurypteria
    Alchemist                                     | stupidity     | aconite
    Depthswalker                                  | recklessness  | sumac
    Psion                                         | confusion     | aconite_ash
    Jester, Occultist, Shaman                     | paralysis     | curare

-------------------------------------------------------------------------------
LOCK PROGRESSION:
-------------------------------------------------------------------------------

    NONE      -> No lock afflictions present
    SOFTLOCK  -> asthma + anorexia + slickness (blocks smoke, eat, salve)
    VENOMLOCK -> softlock + paralysis (blocks tree)
    HARDLOCK  -> venomlock + impatience (blocks focus)
    TRUELOCK  -> hardlock + class lock aff (no escape without help)

-------------------------------------------------------------------------------
COMMANDS:
-------------------------------------------------------------------------------

    infernalGroupLockAttack()       -- Main attack function (alias: grplock/gl)
    infernalGroupLockStatus()       -- Show current state and lock progress
    infernalGroupLock.hasTruelock() -- Check if true locked
    infernalGroupLock.getLockLevel() -- Get current lock level string

-------------------------------------------------------------------------------
CONFIGURATION:
-------------------------------------------------------------------------------

    infernalGroupLock.config = {
        weapon1 = "scimitar405403",  -- Right hand weapon ID (v1)
        weapon2 = "scimitar405398",  -- Left hand weapon ID (v2 = curare)
    }

===============================================================================
]]--

-------------------------------------------------------------------------------
-- NAMESPACE AND STATE
-------------------------------------------------------------------------------

infernalGroupLock = infernalGroupLock or {}

-- Configuration
infernalGroupLock.config = {
    weapon1 = "scimitar405403",  -- Right hand weapon ID (v1)
    weapon2 = "scimitar405398",  -- Left hand weapon ID (v2 = curare)
}

-- State tracking (minimal for group combat)
infernalGroupLock.state = {
    lastLockLevel = nil,  -- Track lock level changes for debug output
}

-- Venom mapping for class-specific lock afflictions
infernalGroupLock.lockVenomMap = {
    weariness = "vernalius",
    voyria = "voyria",
    haemophilia = "eurypteria",
    stupidity = "aconite",
    recklessness = "sumac",
    confusion = "aconite_ash",
    paralysis = "curare",
}

-------------------------------------------------------------------------------
-- AFFLICTION TRACKING HELPER
-------------------------------------------------------------------------------

-- Route through V3 -> V2 -> V1 tracking systems
function infernalGroupLock.hasAff(aff)
    -- V3 (probability-based) - highest priority
    if affConfigV3 and affConfigV3.enabled then
        return haveAffV3(aff)
    end
    -- V2 (certainty levels) - when enabled
    if ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
        if haveAffV2 then return haveAffV2(aff) end
    end
    -- V1 (boolean) - fallback
    return tAffs and tAffs[aff]
end

-------------------------------------------------------------------------------
-- CLASS-SPECIFIC LOCK AFFLICTION
-------------------------------------------------------------------------------

-- Get class-specific lock affliction using existing getLockingAffliction()
function infernalGroupLock.getClassLockAff()
    if not target then return "weariness", "vernalius" end

    -- getLockingAffliction returns {affliction, venom} or just the venom string
    local result = getLockingAffliction and getLockingAffliction(target)
    if type(result) == "table" then
        return result[1], result[2]  -- {affliction, venom}
    elseif type(result) == "string" then
        -- It returned just the venom name, look up the affliction
        local venomToAff = {
            weariness = "weariness",
            plague = "voyria",
            voyria = "voyria",
            haemophilia = "haemophilia",
            stupid = "stupidity",
            reckless = "recklessness",
            paralyse = "paralysis",
        }
        return venomToAff[result] or "weariness", result
    end
    return "weariness", "vernalius"  -- Default fallback
end

-------------------------------------------------------------------------------
-- LOCK DETECTION FUNCTIONS
-------------------------------------------------------------------------------

function infernalGroupLock.hasSoftlock()
    return infernalGroupLock.hasAff("asthma")
       and infernalGroupLock.hasAff("anorexia")
       and infernalGroupLock.hasAff("slickness")
end

function infernalGroupLock.hasVenomlock()
    return infernalGroupLock.hasSoftlock()
       and infernalGroupLock.hasAff("paralysis")
end

function infernalGroupLock.hasHardlock()
    return infernalGroupLock.hasVenomlock()
       and infernalGroupLock.hasAff("impatience")
end

function infernalGroupLock.hasTruelock()
    if not infernalGroupLock.hasHardlock() then return false end
    -- Check class-specific lock affliction
    local lockAff = infernalGroupLock.getClassLockAff()
    return infernalGroupLock.hasAff(lockAff)
end

function infernalGroupLock.getLockLevel()
    if infernalGroupLock.hasTruelock() then return "TRUELOCK" end
    if infernalGroupLock.hasHardlock() then return "HARDLOCK" end
    if infernalGroupLock.hasVenomlock() then return "VENOMLOCK" end
    if infernalGroupLock.hasSoftlock() then return "SOFTLOCK" end
    return "NONE"
end

-- Count how many of the 6 lock afflictions are present (for progress display)
function infernalGroupLock.countLockAffs()
    local count = 0
    local hasAff = infernalGroupLock.hasAff
    if hasAff("asthma") then count = count + 1 end
    if hasAff("slickness") then count = count + 1 end
    if hasAff("anorexia") then count = count + 1 end
    if hasAff("paralysis") then count = count + 1 end
    if hasAff("impatience") then count = count + 1 end
    local lockAff = infernalGroupLock.getClassLockAff()
    if hasAff(lockAff) then count = count + 1 end
    return count
end

-------------------------------------------------------------------------------
-- VENOM SELECTION
-------------------------------------------------------------------------------

function infernalGroupLock.selectVenoms()
    local hasAff = infernalGroupLock.hasAff

    -- V2 is ALWAYS curare (paralysis)
    local v2 = "curare"
    local v1 = nil
    local useHellforge = false

    -- Priority chain for V1 (if X missing, apply Y)
    if not hasAff("asthma") then
        v1 = "kalmia"       -- Priority 1: Asthma (blocks smoke)
    elseif not hasAff("slickness") then
        v1 = "gecko"        -- Priority 2: Slickness (blocks salve)
    elseif not hasAff("anorexia") then
        v1 = "slike"        -- Priority 3: Anorexia (blocks eat)
    elseif not hasAff("impatience") then
        v1 = "euphorbia"    -- Priority 4: Impatience (blocks focus)
    else
        -- Priority 5: Class-specific lock affliction
        local lockAff, lockVenom = infernalGroupLock.getClassLockAff()
        if lockAff and not hasAff(lockAff) then
            -- Use hellforge exploit if class needs weariness (2-aff pressure)
            if lockAff == "weariness" then
                v1 = "exploit"
                useHellforge = true
            else
                v1 = lockVenom or "vernalius"
            end
        else
            v1 = "kalmia"   -- Priority 6: Reinforce asthma (first to drop)
        end
    end

    return v1, v2, useHellforge
end

-------------------------------------------------------------------------------
-- MAIN ATTACK FUNCTION
-------------------------------------------------------------------------------

function infernalGroupLockAttack()
    -- Validate target
    if not target or target == "" then
        cecho("\n<red>[GROUP LOCK]<reset> No target set! Use: t <name>")
        return
    end

    -- Get current lock level
    local lockLevel = infernalGroupLock.getLockLevel()

    -- Announce lock level changes
    if lockLevel ~= infernalGroupLock.state.lastLockLevel then
        if lockLevel == "TRUELOCK" then
            cecho("\n<green>[GROUP LOCK]<reset> TRUE LOCK ACHIEVED! Maintaining pressure...")
        elseif lockLevel == "HARDLOCK" then
            cecho("\n<yellow>[GROUP LOCK]<reset> HARDLOCK! One more aff to true lock...")
        elseif lockLevel == "VENOMLOCK" then
            cecho("\n<cyan>[GROUP LOCK]<reset> VENOMLOCK achieved!")
        elseif lockLevel == "SOFTLOCK" then
            cecho("\n<cyan>[GROUP LOCK]<reset> SOFTLOCK achieved!")
        end
        infernalGroupLock.state.lastLockLevel = lockLevel
    end

    -- Get venoms (v1, v2, and whether to use hellforge)
    local v1, v2, useHellforge = infernalGroupLock.selectVenoms()

    -- Populate envenomList for trigger tracking
    envenomList = envenomList or {}
    envenomListTwo = envenomListTwo or {}
    envenomList = {}
    envenomListTwo = {}
    if v1 and v1 ~= "exploit" then table.insert(envenomList, v1) end
    if v2 then table.insert(envenomListTwo, v2) end

    -- Build base command
    local w1 = infernalGroupLock.config.weapon1
    local w2 = infernalGroupLock.config.weapon2
    local atk = "wield right " .. w1 .. ";wield left " .. w2
    atk = atk .. ";wipe " .. w1 .. ";wipe " .. w2

    -- Rebounding/Shield check (dual-check pattern for safety)
    local hasRebounding = infernalGroupLock.hasAff("rebounding") or (tAffs and tAffs.rebounding)
    local hasShield = infernalGroupLock.hasAff("shield") or (tAffs and tAffs.shield)

    if hasRebounding or hasShield then
        -- RSL: raze with paralysis (can't use hellforge with RSL)
        atk = atk .. ";rsl " .. target .. " " .. v2
        -- Update envenomLists for RSL (only v2 applies)
        envenomList = {}
        envenomListTwo = {v2}
        cecho("\n<yellow>[GROUP LOCK]<reset> Razing " .. (hasRebounding and "REBOUNDING" or "SHIELD"))
    else
        -- Hellforge invest if needed (exploit gives weariness + paranoia)
        if useHellforge then
            atk = atk .. ";hellforge invest exploit"
            -- When using hellforge, v1 becomes "exploit" in DSL command
            atk = atk .. ";dsl " .. target .. " exploit " .. v2
            -- Update envenomLists for hellforge
            envenomList = {"exploit"}
            cecho("\n<magenta>[GROUP LOCK]<reset> HELLFORGE exploit/" .. v2 .. " | Lock: " .. lockLevel .. " (" .. infernalGroupLock.countLockAffs() .. "/6)")
        else
            -- Standard non-limb DSL
            atk = atk .. ";dsl " .. target .. " " .. v1 .. " " .. v2
            cecho("\n<cyan>[GROUP LOCK]<reset> " .. v1 .. "/" .. v2 .. " | Lock: " .. lockLevel .. " (" .. infernalGroupLock.countLockAffs() .. "/6)")
        end
    end

    -- Execute with assess
    send("queue addclear freestand " .. atk .. ";assess " .. target)
end

-------------------------------------------------------------------------------
-- ALIAS FUNCTION
-------------------------------------------------------------------------------

-- Main alias: grplock or gl
function infernalGroupLock_dispatch()
    infernalGroupLockAttack()
end

-------------------------------------------------------------------------------
-- STATUS DISPLAY
-------------------------------------------------------------------------------

function infernalGroupLockStatus()
    local hasAff = infernalGroupLock.hasAff
    local lockLevel = infernalGroupLock.getLockLevel()
    local lockAff, lockVenom = infernalGroupLock.getClassLockAff()
    local lockCount = infernalGroupLock.countLockAffs()

    cecho("\n<cyan>====== GROUP LOCK STATUS ======<reset>")
    cecho("\n<white>Target:<reset> " .. (target or "None"))
    cecho("\n<white>Lock Level:<reset> <yellow>" .. lockLevel .. "<reset> (" .. lockCount .. "/6)")
    cecho("\n<white>Class Lock:<reset> " .. lockAff .. " (" .. lockVenom .. ")")
    cecho("\n")
    cecho("\n<white>Afflictions:<reset>")
    cecho("\n  Asthma:     " .. (hasAff("asthma") and "<green>YES" or "<red>NO") .. "<reset>")
    cecho("\n  Slickness:  " .. (hasAff("slickness") and "<green>YES" or "<red>NO") .. "<reset>")
    cecho("\n  Anorexia:   " .. (hasAff("anorexia") and "<green>YES" or "<red>NO") .. "<reset>")
    cecho("\n  Paralysis:  " .. (hasAff("paralysis") and "<green>YES" or "<red>NO") .. "<reset>")
    cecho("\n  Impatience: " .. (hasAff("impatience") and "<green>YES" or "<red>NO") .. "<reset>")
    cecho("\n  " .. lockAff .. ": " .. (hasAff(lockAff) and "<green>YES" or "<red>NO") .. "<reset> (class)")
    cecho("\n<cyan>===============================<reset>")
end

-------------------------------------------------------------------------------
-- RESET FUNCTION
-------------------------------------------------------------------------------

function infernalGroupLockReset()
    infernalGroupLock.state.lastLockLevel = nil
    cecho("\n<cyan>[GROUP LOCK]<reset> State reset.")
end
