--[[mudlet
type: script
name: Runewarden Group Lock
hierarchy:
- Levi_Ataxia
- LEVI
- Levi Scripts
- Leviticus
- RUNEWARDEN
- DWC
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
===============================================================================
                        RUNEWARDEN GROUP LOCK OFFENSE
===============================================================================

KILL CONDITION:
    LOCKED = Target cannot cure afflictions fast enough under group pressure.

    Required afflictions (4 total):
    - Asthma (kalmia)       - Blocks smoke cures
    - Slickness (gecko)     - Blocks salve cures
    - Anorexia (slike)      - Blocks eating herbs
    - Paralysis (curare)    - Blocks tree tattoo escape

-------------------------------------------------------------------------------
DESIGN PRINCIPLES:
-------------------------------------------------------------------------------

    1. NO LIMB TARGETING - Pure `dsl target v1 v2` for maximum speed
    2. PAIR-BASED VENOMS - Two fixed pairs that each cover 2 lock affs
    3. SIMPLE CONDITIONAL LOGIC - Clear "if X, then Y" priority chain
    4. V3 PROBABILITY SUPPORT - Routes through existing tracking infrastructure
    5. MINIMAL STATE - Group combat needs fast, stateless execution
    6. VENOM ONLY - No hellforge, no special abilities, pure venom pressure

-------------------------------------------------------------------------------
VENOM PAIRS:
-------------------------------------------------------------------------------

    Pair A: curare / kalmia   (paralysis + asthma)
    Pair B: slike  / gecko    (anorexia  + slickness)

    V1 = right hand weapon (can miss through clumsiness)
    V2 = left hand weapon  (guaranteed to land)

    Key: kalmia on V2 (Pair A) = asthma guaranteed even through clumsiness
         gecko on V2 (Pair B)  = slickness guaranteed even through clumsiness

-------------------------------------------------------------------------------
VENOM PRIORITY CHAIN:
-------------------------------------------------------------------------------

    V1/V2 Selection (Pair-based):
        Priority 1: If NO asthma     -> Pair A: curare/kalmia
        Priority 2: If NO slickness  -> Pair B: slike/gecko
        Priority 3: If NO anorexia   -> Pair B: slike/gecko
        Priority 4: If NO paralysis  -> Pair A: curare/kalmia
        Priority 5: If all stuck     -> Pair A: curare/kalmia (reinforce asthma)

    Rebounding/Shield Override:
        If rebounding OR shield -> RSL with best single venom for missing aff

-------------------------------------------------------------------------------
LOCK PROGRESSION:
-------------------------------------------------------------------------------

    NONE     -> No lock afflictions present
    SOFTLOCK -> asthma + anorexia + slickness (blocks smoke, eat, salve)
    LOCKED   -> softlock + paralysis (blocks tree — full lock under pressure)

-------------------------------------------------------------------------------
COMMANDS:
-------------------------------------------------------------------------------

    runeGroupLockAttack()       -- Main attack function (alias: rwgl)
    runeGroupLockStatus()       -- Show current state and lock progress
    runeGroupLock.hasLocked()   -- Check if fully locked
    runeGroupLock.getLockLevel() -- Get current lock level string

-------------------------------------------------------------------------------
CONFIGURATION:
-------------------------------------------------------------------------------

    runeGroupLock.config = {
        weapon1 = "WEAPON_ID_RIGHT",   -- Right hand weapon ID (v1)
        weapon2 = "WEAPON_ID_LEFT",    -- Left hand weapon ID (v2)
        empowerrunesset = "kena mannaz sleizak",  -- Empower rune priority
    }

===============================================================================
]]--

-------------------------------------------------------------------------------
-- NAMESPACE AND STATE
-------------------------------------------------------------------------------

runeGroupLock = runeGroupLock or {}

-- Configuration
runeGroupLock.config = {
    weapon1 = "WEAPON_ID_RIGHT",   -- Right hand weapon ID (v1)
    weapon2 = "WEAPON_ID_LEFT",    -- Left hand weapon ID (v2)
    empowerrunesset = "kena mannaz sleizak",  -- Empower rune priority
}

-- State tracking (minimal for group combat)
runeGroupLock.state = {
    lastLockLevel = nil,  -- Track lock level changes for debug output
    firstAttack = true,   -- First attack sends falcon slay
}

-------------------------------------------------------------------------------
-- AFFLICTION TRACKING HELPER
-------------------------------------------------------------------------------

-- Route through V3 -> V2 -> V1 tracking systems
function runeGroupLock.hasAff(aff)
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
function runeGroupLock.getClassLockAff()
    if not target then return "weariness", "vernalius" end

    local result = getLockingAffliction and getLockingAffliction(target)
    if type(result) == "table" then
        return result[1], result[2]
    elseif type(result) == "string" then
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
    return "weariness", "vernalius"
end

-------------------------------------------------------------------------------
-- LOCK DETECTION FUNCTIONS
-------------------------------------------------------------------------------

function runeGroupLock.hasSoftlock()
    return runeGroupLock.hasAff("asthma")
       and runeGroupLock.hasAff("anorexia")
       and runeGroupLock.hasAff("slickness")
end

function runeGroupLock.hasLocked()
    return runeGroupLock.hasSoftlock()
       and runeGroupLock.hasAff("paralysis")
end

function runeGroupLock.hasTruelock()
    if not runeGroupLock.hasLocked() then return false end
    local lockAff = runeGroupLock.getClassLockAff()
    return runeGroupLock.hasAff("voyria")
       and runeGroupLock.hasAff(lockAff)
end

function runeGroupLock.getLockLevel()
    if runeGroupLock.hasTruelock() then return "TRUELOCK" end
    if runeGroupLock.hasLocked() then return "LOCKED" end
    if runeGroupLock.hasSoftlock() then return "SOFTLOCK" end
    return "NONE"
end

-- Count how many of the 6 lock afflictions are present (for progress display)
function runeGroupLock.countLockAffs()
    local count = 0
    local hasAff = runeGroupLock.hasAff
    if hasAff("asthma") then count = count + 1 end
    if hasAff("slickness") then count = count + 1 end
    if hasAff("anorexia") then count = count + 1 end
    if hasAff("paralysis") then count = count + 1 end
    if hasAff("voyria") then count = count + 1 end
    local lockAff = runeGroupLock.getClassLockAff()
    if hasAff(lockAff) then count = count + 1 end
    return count
end

-------------------------------------------------------------------------------
-- VENOM SELECTION
-------------------------------------------------------------------------------

function runeGroupLock.selectVenoms()
    local hasAff = runeGroupLock.hasAff

    -- Priority chain: select the pair that covers the most important missing aff
    if not hasAff("asthma") then
        return "curare", "kalmia"       -- Pair A: asthma priority (kalmia on V2 = guaranteed)
    elseif not hasAff("slickness") then
        return "slike", "gecko"         -- Pair B: slickness (gecko on V2 = guaranteed)
    elseif not hasAff("anorexia") then
        return "slike", "gecko"         -- Pair B: anorexia
    elseif not hasAff("paralysis") then
        return "curare", "kalmia"       -- Pair A: paralysis
    else
        -- All 4 core affs stuck — push voyria + class lock aff
        local lockAff, lockVenom = runeGroupLock.getClassLockAff()
        if not hasAff("voyria") and not hasAff(lockAff) then
            return "voyria", lockVenom          -- Both missing: voyria V1, class lock V2
        elseif not hasAff("voyria") then
            return "voyria", "kalmia"           -- Only voyria missing, reinforce asthma on V2
        elseif not hasAff(lockAff) then
            return lockVenom, "kalmia"          -- Only class lock missing, reinforce asthma on V2
        else
            return "curare", "kalmia"           -- All stuck: reinforce asthma (first to drop)
        end
    end
end

-- Select single best venom for RSL (raze — only one venom applies)
function runeGroupLock.selectRSLVenom()
    local hasAff = runeGroupLock.hasAff

    if not hasAff("asthma") then
        return "kalmia"     -- Asthma is foundation
    elseif not hasAff("slickness") then
        return "gecko"      -- Slickness blocks salves
    elseif not hasAff("anorexia") then
        return "slike"      -- Anorexia blocks eating
    elseif not hasAff("paralysis") then
        return "curare"     -- Paralysis blocks tree
    else
        -- All 4 core stuck — push finish affs
        local lockAff, lockVenom = runeGroupLock.getClassLockAff()
        if not hasAff("voyria") then
            return "voyria"
        elseif not hasAff(lockAff) then
            return lockVenom
        else
            return "kalmia"     -- All stuck: reinforce asthma
        end
    end
end

-------------------------------------------------------------------------------
-- MAIN ATTACK FUNCTION
-------------------------------------------------------------------------------

function runeGroupLockAttack()
    -- Validate target
    if not target or target == "" then
        cecho("\n<red>[RW GROUP]<reset> No target set! Use: t <name>")
        return
    end

    -- Get current lock level
    local lockLevel = runeGroupLock.getLockLevel()

    -- Announce lock level changes
    if lockLevel ~= runeGroupLock.state.lastLockLevel then
        if lockLevel == "TRUELOCK" then
            cecho("\n<green>[RW GROUP]<reset> TRUE LOCK ACHIEVED! Maintaining pressure...")
        elseif lockLevel == "LOCKED" then
            cecho("\n<yellow>[RW GROUP]<reset> LOCKED! Pushing voyria + class lock...")
        elseif lockLevel == "SOFTLOCK" then
            cecho("\n<cyan>[RW GROUP]<reset> SOFTLOCK achieved!")
        end
        runeGroupLock.state.lastLockLevel = lockLevel
    end

    -- Populate envenomList for trigger tracking
    envenomList = envenomList or {}
    envenomListTwo = envenomListTwo or {}
    envenomList = {}
    envenomListTwo = {}

    -- Build base command
    local w1 = runeGroupLock.config.weapon1
    local w2 = runeGroupLock.config.weapon2
    local atk = ""
    local isOpening = runeGroupLock.state.firstAttack

    -- First attack: unwield, wield, falcon slay prefix
    if isOpening then
        runeGroupLock.state.firstAttack = false
        atk = "unwield left;unwield right"
        atk = atk .. ";wield " .. w1 .. " " .. w2 .. ";wipe " .. w1 .. ";wipe " .. w2
        atk = atk .. ";empower priority set " .. runeGroupLock.config.empowerrunesset
        atk = atk .. ";falcon slay " .. target
    else
        atk = "wield " .. w1 .. " " .. w2 .. ";wipe " .. w1 .. ";wipe " .. w2
        atk = atk .. ";empower priority set " .. runeGroupLock.config.empowerrunesset
    end

    -- Rebounding/Shield check (dual-check pattern for safety)
    local hasRebounding = runeGroupLock.hasAff("rebounding") or (tAffs and tAffs.rebounding)
    local hasShield = runeGroupLock.hasAff("shield") or (tAffs and tAffs.shield)

    if hasRebounding or hasShield then
        -- RSL: raze with single best venom
        local rslVenom = runeGroupLock.selectRSLVenom()
        atk = atk .. ";rsl " .. target .. " " .. rslVenom
        -- Update envenomLists for RSL (only one venom applies)
        envenomList = {}
        envenomListTwo = {rslVenom}
        cecho("\n<yellow>[RW GROUP]<reset> Razing " .. (hasRebounding and "REBOUNDING" or "SHIELD") .. " (" .. rslVenom .. ")")
    else
        -- Standard non-limb DSL with pair-based venoms
        local v1, v2 = runeGroupLock.selectVenoms()
        atk = atk .. ";dsl " .. target .. " " .. v1 .. " " .. v2

        -- Populate trigger tracking
        envenomList = {v1}
        envenomListTwo = {v2}

        cecho("\n<cyan>[RW GROUP]<reset> " .. v1 .. "/" .. v2 .. " | Lock: " .. lockLevel .. " (" .. runeGroupLock.countLockAffs() .. "/6)")
    end

    -- First attack ends with engage
    if isOpening then
        atk = atk .. ";engage " .. target
    end

    -- Execute with assess
    send("queue addclear freestand " .. atk .. ";assess " .. target)
end

-------------------------------------------------------------------------------
-- ALIAS FUNCTION
-------------------------------------------------------------------------------

-- Main alias: rwgl
function runeGroupLock_dispatch()
    runeGroupLockAttack()
end

-------------------------------------------------------------------------------
-- STATUS DISPLAY
-------------------------------------------------------------------------------

function runeGroupLockStatus()
    local hasAff = runeGroupLock.hasAff
    local lockLevel = runeGroupLock.getLockLevel()
    local lockCount = runeGroupLock.countLockAffs()
    local lockAff, lockVenom = runeGroupLock.getClassLockAff()

    cecho("\n<cyan>====== RW GROUP LOCK STATUS ======<reset>")
    cecho("\n<white>Target:<reset> " .. (target or "None"))
    cecho("\n<white>Lock Level:<reset> <yellow>" .. lockLevel .. "<reset> (" .. lockCount .. "/6)")
    cecho("\n<white>Class Lock:<reset> " .. lockAff .. " (" .. lockVenom .. ")")
    cecho("\n")
    cecho("\n<white>Afflictions:<reset>")
    cecho("\n  Asthma:     " .. (hasAff("asthma") and "<green>YES" or "<red>NO") .. "<reset>")
    cecho("\n  Slickness:  " .. (hasAff("slickness") and "<green>YES" or "<red>NO") .. "<reset>")
    cecho("\n  Anorexia:   " .. (hasAff("anorexia") and "<green>YES" or "<red>NO") .. "<reset>")
    cecho("\n  Paralysis:  " .. (hasAff("paralysis") and "<green>YES" or "<red>NO") .. "<reset>")
    cecho("\n  Voyria:     " .. (hasAff("voyria") and "<green>YES" or "<red>NO") .. "<reset>")
    cecho("\n  " .. lockAff .. ": " .. (hasAff(lockAff) and "<green>YES" or "<red>NO") .. "<reset> (class)")
    cecho("\n<cyan>==================================<reset>")
end

-------------------------------------------------------------------------------
-- RESET FUNCTION
-------------------------------------------------------------------------------

function runeGroupLockReset()
    runeGroupLock.state.lastLockLevel = nil
    runeGroupLock.state.firstAttack = true
    cecho("\n<cyan>[RW GROUP]<reset> State reset.")
end
