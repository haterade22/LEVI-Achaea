-------------------------------------------------------------------------------
-- INFERNAL PREFARAR OFFENSE
--
-- Simple 3-phase offense:
--   RAZE   -> rsl target prefarar (strip shield/rebounding + undeaf)
--   UNDEAF -> dsl target prefarar prefarar (strip deafness)
--   KILL   -> battlecry target; arc target prefarar (damage mode)
--
-- Prefarar cures deafness if deaf, or applies sensitivity if not deaf.
-- Battlecry only works on non-deaf targets (prones + stuns, uses EQ).
-- Arc does damage + applies venom (uses BAL).
-------------------------------------------------------------------------------

infernalPF = infernalPF or {}

infernalPF.state = {
    attackInFlight = false,
    initialized = false,
    lastTarget = nil,
    lastPhase = nil,
}

-------------------------------------------------------------------------------
-- PHASE DETECTION
-------------------------------------------------------------------------------

function infernalPF.getPhase()
    -- V1 fallback for timing safety (GMCP fires before text triggers)
    local hasRebounding = haveAff("rebounding") or (tAffs and tAffs.rebounding)
    local hasShield = haveAff("shield") or (tAffs and tAffs.shield)

    if hasRebounding or hasShield then
        return "RAZE"
    end

    if tAffs and tAffs.deafness then
        return "UNDEAF"
    end

    return "KILL"
end

-------------------------------------------------------------------------------
-- MAIN DISPATCH
-------------------------------------------------------------------------------

function infernalPFOffense()
    -- Guard: prevent re-dispatch while off balance
    if infernalPF.state.attackInFlight then
        return
    end

    -- Target check
    if not target or target == "" then
        cecho("\n<red>[INF PF]<reset> No target set! Use: t <name>")
        return
    end

    -- Target change detection -> reset initialized flag
    if infernalPF.state.lastTarget ~= target then
        infernalPF.state.initialized = false
        infernalPF.state.lastTarget = target
    end

    -- First dispatch: assume target is deaf
    if not infernalPF.state.initialized then
        infernalPF.state.initialized = true
        tAffs = tAffs or {}
        tAffs.deafness = true
        if applyAffV3 then
            applyAffV3("deafness")
        end
        cecho("\n<cyan>[INF PF]<reset> Assuming target is deaf. Undeafing with prefarar...")
    end

    -- Get weapon IDs (fallback to DWC config)
    local weapon1 = (infernalDWC and infernalDWC.config and infernalDWC.config.weapon1)
        or "scimitar"
    local weapon2 = (infernalDWC and infernalDWC.config and infernalDWC.config.weapon2)
        or "scimitar"

    -- Get current phase
    local phase = infernalPF.getPhase()

    -- Echo phase changes
    if phase ~= infernalPF.state.lastPhase then
        cecho("\n<cyan>[INF PF]<reset> Phase: <yellow>" .. phase .. "<reset>")
        infernalPF.state.lastPhase = phase
    end

    -------------------------------------------------------------------
    -- RAZE: Shield or rebounding present
    -------------------------------------------------------------------
    if phase == "RAZE" then
        local atk = "wield right " .. weapon1 .. ";wield left " .. weapon2
        atk = atk .. ";wipe " .. weapon1 .. ";wipe " .. weapon2
        atk = atk .. ";rsl " .. target .. " prefarar"

        envenomList = {}
        envenomListTwo = {"prefarar"}
        ataxiaTemp = ataxiaTemp or {}
        ataxiaTemp.hitCount = 0

        local defName = (haveAff("rebounding") or (tAffs and tAffs.rebounding))
            and "REBOUNDING" or "SHIELD"
        cecho("\n<yellow>[INF PF]<reset> RAZE | rsl prefarar (stripping " .. defName .. ")")

        infernalPF.state.attackInFlight = true
        knightSendAttack(atk .. ";assess " .. target)
        return
    end

    -------------------------------------------------------------------
    -- UNDEAF: Strip deafness with DSL prefarar prefarar
    -------------------------------------------------------------------
    if phase == "UNDEAF" then
        local atk = "wield right " .. weapon1 .. ";wield left " .. weapon2
        atk = atk .. ";wipe " .. weapon1 .. ";wipe " .. weapon2
        atk = atk .. ";dsl " .. target .. " prefarar prefarar"

        envenomList = {"prefarar"}
        envenomListTwo = {"prefarar"}
        ataxiaTemp = ataxiaTemp or {}
        ataxiaTemp.hitCount = 0

        cecho("\n<magenta>[INF PF]<reset> UNDEAF | dsl prefarar/prefarar")

        infernalPF.state.attackInFlight = true
        knightSendAttack(atk .. ";assess " .. target)
        return
    end

    -------------------------------------------------------------------
    -- KILL: Battlecry (EQ) + Arc prefarar (BAL) = damage mode
    -------------------------------------------------------------------
    if phase == "KILL" then
        local atk = "wield right " .. weapon1
        atk = atk .. ";battlecry " .. target
        atk = atk .. ";arc " .. target .. " prefarar"

        envenomList = {"prefarar"}
        envenomListTwo = {}
        ataxiaTemp = ataxiaTemp or {}
        ataxiaTemp.hitCount = 0

        cecho("\n<green>[INF PF]<reset> KILL | battlecry + arc prefarar")

        infernalPF.state.attackInFlight = true
        knightSendAttack(atk .. ";assess " .. target)
        return
    end
end

-------------------------------------------------------------------------------
-- RESET
-------------------------------------------------------------------------------

function infernalPFReset()
    infernalPF.state.attackInFlight = false
    infernalPF.state.initialized = false
    infernalPF.state.lastTarget = nil
    infernalPF.state.lastPhase = nil
    cecho("\n<cyan>[INF PF]<reset> State reset!")
end

-------------------------------------------------------------------------------
-- STATUS
-------------------------------------------------------------------------------

function infernalPFStatus()
    local tar = target or "None"
    local phase = infernalPF.getPhase()
    local hasDeaf = tAffs and tAffs.deafness and true or false
    local hasSens = tAffs and tAffs.sensitivity and true or false
    local hasReb = haveAff("rebounding") or (tAffs and tAffs.rebounding)
    local hasShd = haveAff("shield") or (tAffs and tAffs.shield)

    cecho("\n<cyan>========================================<reset>")
    cecho("\n<cyan>[INF PF]<reset> Target: <yellow>" .. tar .. "<reset>")
    cecho("\n<cyan>[INF PF]<reset> Phase: <yellow>" .. phase .. "<reset>")
    cecho("\n<cyan>[INF PF]<reset> Initialized: " .. (infernalPF.state.initialized and "<green>yes" or "<red>no") .. "<reset>")
    cecho("\n<cyan>[INF PF]<reset> Deafness: " .. (hasDeaf and "<red>YES" or "<green>no") .. "<reset>")
    cecho("\n<cyan>[INF PF]<reset> Sensitivity: " .. (hasSens and "<green>YES" or "<red>no") .. "<reset>")
    cecho("\n<cyan>[INF PF]<reset> Defs: " .. (hasReb and "<red>REB " or "") .. (hasShd and "<red>SHD" or "") .. (not hasReb and not hasShd and "<green>clear" or "") .. "<reset>")
    cecho("\n<cyan>========================================<reset>")
end

-------------------------------------------------------------------------------
-- BALANCE RECOVERY (clears attackInFlight)
-------------------------------------------------------------------------------

-- Battlecry uses EQ, Arc uses BAL. Wait for both before re-dispatching.
if infernalPF._balHandler then
    killAnonymousEventHandler(infernalPF._balHandler)
end
infernalPF._balHandler = registerAnonymousEventHandler("gmcp.Char.Vitals", function()
    if gmcp.Char.Vitals.bal == "1" and gmcp.Char.Vitals.eq == "1" then
        infernalPF.state.attackInFlight = false
    end
end)

cecho("\n<cyan>[INF PF]<reset> Loaded! Alias: pf | Reset: pfreset | Status: pfstatus")
