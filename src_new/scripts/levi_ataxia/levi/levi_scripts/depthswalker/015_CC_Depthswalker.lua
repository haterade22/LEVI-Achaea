--[[mudlet
type: script
name: CC_Depthswalker
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- DEPTHSWALKER
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--------------------------------------------------------------------------------
-- CC_Depthswalker: Unified Depthswalker Offensive System (V3 Integration)
--
-- Replaces old 001_Attack.lua (depthswalker_damageroute / depthswalker_lockroute)
-- with a single namespace-based system. Backward-compat wrappers live in
-- 014_Levi_Depthswalker.lua.
--
-- Integrates with Affliction Tracker V3 (probability-based), V2, or V1.
--
-- Kill Routes (4 modes + group):
--   1. Lock        - Instill + venom toward truelock, recklessness to block Accelerate
--   2. Damage      - Claim shadow via leach, degeneration attune/capstone, mutilate
--   3. Dictate     - Stack DW affs to lower threshold, retribution for mana sap
--   4. Madpression - Madness capstone (stun) -> Depression capstone (anorexia+masochism)
--   5. Group       - Simplified damage-focused for group fights
--
-- Each attack delivers TWO afflictions from independent pools:
--   Instill slot: 1 DW-specific aff (depression, madness, retribution, etc.)
--   Venom slot:   1 standard venom aff (curare=paralysis, kalmia=asthma, etc.)
--   With Timeloop: 2 DW affs but NO venom (trades venom for double instill)
--
-- Capstones are PER INSTILL (v4.7.365). Each Instill has its own ladder: the
-- first three applications give its three afflictions in order, the next one
-- gives THAT Instill's capstone. So "is the depression capstone ready?" is
-- "does the target carry every rung of the depression ladder?" -- never a
-- total of unrelated DW afflictions (the old `5 DW affs` rule fired capstones
-- that were not ready and missed ones that were). See INSTILL_STACKS.
--
-- Dictate threshold (AB DICTATE): 40% mana + 5% for EACH of depression,
--   madness, retribution and parasite -- those four only (v4.7.366).
-- Mutilate threshold: 40% HP + 30% mana + shadow claimed
-- The shadow is claimed by the leach CAPSTONE strike itself: there is no
--   SHADOW CLAIM command (live-tested by the auditor, v4.7.366).
--------------------------------------------------------------------------------

depthswalker = depthswalker or {}

--------------------------------------------------------------------------------
-- STATE & CONFIG
--------------------------------------------------------------------------------

depthswalker.state = {
    mode = "lock",              -- "lock", "damage", "dictate", "madpression", "group"
    haveShadow = false,         -- shadow claimed from target
    madCapAt = nil,             -- when the madness capstone landed (trigger 483)
    distorted = false,          -- distort active in room
    partyrelay = true,          -- relay to party
    bellwortComplete = false,   -- bellwort phase done (timeloop applied), skip to finisher
    lastTarget = nil,           -- track target changes to reset state
}

depthswalker.config = {
    lockThreshold = 0.3,            -- V3 probability threshold for "has affliction"
    highConfidence = 0.7,           -- V3 threshold for high-confidence decisions
    scytheId = "scythe20431",       -- configurable weapon ID
    cullHealthThreshold = 35,       -- hp% below which to cull
    mutilateHealthThreshold = 40,   -- hp% for mutilate execute
    mutilateManaThreshold = 30,     -- mana% for mutilate execute
    debugEcho = false,              -- echo debug info per attack
    -- Seconds after the madness capstone line (trigger 483) during which
    -- MADPRESSION treats the target as stunned. UNCONFIRMED: the stun's
    -- length has never been measured.
    madStunWindow = 3,
    -- Append `assess <target>` to every attack. ASSESS is balanceless only
    -- with the HEALTH INSPECTOR trait; without it, every attack pays for it.
    -- Cull/Mutilate read the target's health (php) from these assesses.
    -- Toggle with `dwassess on|off`.
    assess = true,
}

-- Current attack selections (set each dispatch cycle)
depthswalker.selections = {
    instill = nil,
    venom = nil,
    attune = "degeneration",
    useTimeloop = false,
    phase = "init",       -- "shadow", "bellwort", or mode name (set by selectInstill)
}

-- Each Instill's ladder, in application order. The rung triggers (468/469/472/
-- 473/474, 479 under timeloop) apply the FIRST MISSING rung, so the stage is
-- read from the target's afflictions by the same rule -- the offense and the
-- tracker agree by construction. Once every rung is up, the NEXT application
-- of that Instill is its capstone.
--   degeneration -> damage burst (halved without a shadow)
--   depression   -> depression + anorexia + masochism
--   madness      -> stun
--   leach        -> claims the target's shadow (the capstone strike IS the
--                   claim; there is no SHADOW CLAIM command)
--   retribution  -> mana sap (its ladder is two rungs, per the class doc)
-- This table is also the whitelist of valid instills: "impatience" is NOT one
-- (the game refuses `shadow instill scythe with impatience`, leaving the old
-- instill on the scythe).
depthswalker.INSTILL_STACKS = {
    degeneration = { "clumsiness", "weariness", "paralysis" },
    depression   = { "depression", "nausea", "hypochondria" },
    madness      = { "shadowmadness", "vertigo", "hallucinations" },
    leach        = { "parasite", "healthleech", "manaleech" },
    retribution  = { "justice", "retribution" },
}
depthswalker.INSTILL_ORDER = { "depression", "degeneration", "madness", "leach", "retribution" }

-- DW-specific afflictions on the target: the "is this a fresh fight?" reset
-- and the status readout. Neither capstones nor Dictate use this list.
depthswalker.DW_AFFS = {
    "depression", "retribution", "parasite", "healthleech",
    "manaleech", "justice", "timeloop", "shadowmadness",
}

-- The four afflictions AB DICTATE names as raising its threshold, 5% each
-- (v4.7.366; captured AB via the auditor). "madness" there is our first
-- madness rung, which the tracker records as shadowmadness. Before this, the
-- threshold counted seven affs (healthleech/manaleech/justice/timeloop too)
-- and could reach 75% where the real cap is 60% -- Dictate fired early.
depthswalker.DICTATE_AFFS = { "depression", "shadowmadness", "retribution", "parasite" }

-- The pressure foundation the opening builds (kelp + bellwort). The
-- opening-complete latch holds only while at least FOUNDATION_MIN of these are
-- still up (v4.7.366); below that the route rebuilds instead of finishing.
depthswalker.FOUNDATION_AFFS = { "clumsiness", "justice", "retribution", "timeloop" }
depthswalker.FOUNDATION_MIN = 2

--------------------------------------------------------------------------------
-- V3 ROUTING HELPERS
--------------------------------------------------------------------------------

-- Check if target has an affliction (V3 is always on, routes through global haveAff)
function depthswalker.hasAff(aff)
    return haveAff(aff)
end

-- Affliction present at a STRICTER confidence than haveAff's 30% default.
-- For decisions that commit something -- the Dictate kill threshold, the
-- opening-complete latch -- a 30% V3 branch is not enough (v4.7.366). With no
-- V3 probability available it falls back to haveAff.
function depthswalker.hasAffConfident(aff)
    if getAffProbabilityV3 then
        return getAffProbabilityV3(aff) >= depthswalker.config.highConfidence
    end
    return depthswalker.hasAff(aff)
end

-- Get affliction probability (0.0-1.0).
function depthswalker.getAffProb(aff)
    return getAffProbabilityV3 and getAffProbabilityV3(aff) or 0
end

-- Check which tracking system is active
function depthswalker.getTrackingSystem()
    return "V3"
end

-- Get lock status with probabilities
function depthswalker.getLocks()
    if affConfigV3 and affConfigV3.enabled and getLockStatusV3 then
        return getLockStatusV3()
    end
    local hasAll = function(affs)
        for _, aff in ipairs(affs) do
            if not depthswalker.hasAff(aff) then return 0 end
        end
        return 1.0
    end
    return {
        softlock = hasAll({"anorexia", "asthma", "slickness"}),
        hardlock = hasAll({"anorexia", "asthma", "slickness", "impatience"}),
        truelock = hasAll({"anorexia", "asthma", "slickness", "impatience", "paralysis"}),
    }
end

--------------------------------------------------------------------------------
-- DW-SPECIFIC HELPERS
--------------------------------------------------------------------------------

-- Count DW afflictions on target (V3-weighted for probability accuracy)
function depthswalker.countDWAffs()
    local count = 0
    for _, aff in ipairs(depthswalker.DW_AFFS) do
        if affConfigV3 and affConfigV3.enabled then
            count = count + depthswalker.getAffProb(aff)
        else
            if depthswalker.hasAff(aff) then
                count = count + 1
            end
        end
    end
    return count
end

-- Integer count for thresholds and display
function depthswalker.countDWAffsInt()
    local count = 0
    for _, aff in ipairs(depthswalker.DW_AFFS) do
        if depthswalker.hasAff(aff) then
            count = count + 1
        end
    end
    return count
end

-- Is this a real Shadowmancy instill?
function depthswalker.validInstill(instill)
    return instill ~= nil and depthswalker.INSTILL_STACKS[instill] ~= nil
end

-- Rungs of this Instill already on the target, counted up to the first missing
-- one (the rung triggers' own rule). 0..#stack; nil for an invalid instill.
function depthswalker.instillStage(instill)
    local stack = depthswalker.INSTILL_STACKS[instill]
    if not stack then return nil end
    for i, aff in ipairs(stack) do
        if not depthswalker.hasAff(aff) then return i - 1 end
    end
    return #stack
end

-- True when the NEXT application of this Instill is its capstone. The
-- argument is required: capstones are per Instill, never a global count.
function depthswalker.capstoneReady(instill)
    local stack = depthswalker.INSTILL_STACKS[instill]
    if not stack then return false end
    return depthswalker.instillStage(instill) == #stack
end

-- Applications of this Instill needed to land its capstone (1 = next hit).
function depthswalker.hitsToCapstone(instill)
    local stack = depthswalker.INSTILL_STACKS[instill]
    if not stack then return nil end
    return #stack - depthswalker.instillStage(instill) + 1
end

-- Compact per-Instill readout for the echoes: "Dep 2/3 Degen 3/3* ..."
-- (* = capstone on the next application).
depthswalker.INSTILL_SHORT = {
    depression = "Dep", degeneration = "Degen", madness = "Mad",
    leach = "Leach", retribution = "Ret",
}
function depthswalker.stageSummary()
    local parts = {}
    for _, instill in ipairs(depthswalker.INSTILL_ORDER) do
        local stage = depthswalker.instillStage(instill)
        local n = #depthswalker.INSTILL_STACKS[instill]
        parts[#parts + 1] = depthswalker.INSTILL_SHORT[instill] .. " " .. stage .. "/" .. n
            .. (stage == n and "*" or "")
    end
    return table.concat(parts, " ")
end

-- Dictate threshold: 40% base + 5% per DW affliction on target
-- Only the four AB-named afflictions count, each at high confidence: an
-- overestimated threshold sends Dictate while their mana is still too high.
function depthswalker.getDictateThreshold()
    local n = 0
    for _, aff in ipairs(depthswalker.DICTATE_AFFS) do
        if depthswalker.hasAffConfident(aff) then n = n + 1 end
    end
    return 40 + (n * 5)
end

-- Check if dictate conditions are met
function depthswalker.canDictate()
    if not pm then return false end
    return pm <= depthswalker.getDictateThreshold()
end

-- Get character age from ataxiaTables or GMCP fallback
function depthswalker.getAge()
    if ataxiaTables and ataxiaTables.depthswalker then
        return ataxiaTables.depthswalker.age or 0
    end
    if gmcp and gmcp.Char and gmcp.Char.Vitals and gmcp.Char.Vitals.charstats then
        local charstat = gmcp.Char.Vitals.charstats[4]
        if charstat then
            local ageStr = string.sub(charstat, 6)
            return tonumber(ageStr) or 0
        end
    end
    return 0
end

-- Timeloop availability checks
function depthswalker.canUnboostedLoop()
    return depthswalker.getAge() <= 250
end

function depthswalker.canBoostedLoop()
    -- Boosted timeloop works at any age (requires the skill)
    return haveWord and haveWord("boost") or false
end

function depthswalker.canTimeloop()
    return depthswalker.canUnboostedLoop() or depthswalker.canBoostedLoop()
end

-- Timeloop decision: trade venom for double instill?
-- Key timing: when healthleech stuck, use chrono loop boost to get manaleech in same hit
function depthswalker.shouldTimeloop()
    if not depthswalker.canTimeloop() then return false end

    -- Don't timeloop if target already has the timeloop aff
    if depthswalker.hasAff("timeloop") then return false end

    local mode = depthswalker.state.mode
    local phase = depthswalker.selections.phase
    local instill = depthswalker.selections.instill

    -- Never loop a capstone hit: the loop trades the venom for a second rung,
    -- and a capstone application has no rung left to double.
    if depthswalker.capstoneReady(instill) then return false end

    -- CRITICAL: When healthleech stuck but not manaleech, use chrono loop boost
    -- ONLY during shadow phase - double-apply leach to get manaleech before they cure healthleech
    -- Don't let this trigger during bellwort/lock phases!
    if phase == "shadow" and depthswalker.hasAff("healthleech") and not depthswalker.hasAff("manaleech") then
        return true
    end

    -- DAMAGE/GROUP MODE: only use timeloop for the healthleech->manaleech transition (above)
    -- All other damage situations: chrono assert (keep venom pressure)
    if mode == "damage" or mode == "group" then
        return false
    end

    -- BELLWORT PHASE: Only use chrono loop AFTER first bellwort aff is CONFIRMED stuck
    -- Strategy: (1) retribution+curare → justice, (2) retribution+chrono loop → retribution+timeloop
    -- This maximizes bellwort pressure: all 3 bellwort affs stuck, they can only cure 1 per balance
    if phase == "bellwort" then
        -- Use probability threshold to ensure bellwort aff is actually stuck (not just V3 branching)
        local justiceProb = depthswalker.getAffProb("justice")
        local retribProb = depthswalker.getAffProb("retribution")
        local hasBellwortConfirmed = justiceProb >= depthswalker.config.highConfidence
                                  or retribProb >= depthswalker.config.highConfidence

        if hasBellwortConfirmed and not depthswalker.hasAff("timeloop") then
            return true
        end
        return false  -- Don't use chrono loop until first bellwort aff is CONFIRMED stuck
    end

    -- LOCK/DICTATE/MADPRESSION: loop when the selected Instill still needs two
    -- or more rungs before its capstone, so the doubled instill lands two rungs
    -- instead of one. (Replaces the old "3-4 of 5 DW affs" rule, which counted
    -- unrelated afflictions toward a capstone that does not exist.)
    local toCap = depthswalker.hitsToCapstone(instill)
    return toCap ~= nil and toCap >= 3
end

-- Get the chrono command based on timeloop decision
function depthswalker.getChronoCommand()
    if depthswalker.selections.useTimeloop then
        -- CRITICAL: For healthleech->manaleech transition, MUST use boost to double-apply leach
        -- Boost doubles the instill effect, which is what gets manaleech in one hit
        if depthswalker.hasAff("healthleech") and not depthswalker.hasAff("manaleech") then
            return "chrono loop boost"
        end
        -- Otherwise prefer unboosted if available (saves age resource)
        if depthswalker.canUnboostedLoop() then
            return "chrono loop"
        else
            return "chrono loop boost"
        end
    end
    return "chrono assert"
end

--------------------------------------------------------------------------------
-- INSTILL PRIORITY CHAINS
--
-- Strategy: Universal opening phase -> Mode-specific finisher
--
-- DAMAGE/GROUP MODE: Completely different strategy (kelp pressure first)
--   1. Spam degeneration + curare to build kelp stack (clumsiness, weariness)
--   2. Once kelp stuck, build leach toward shadow (kalmia when healthleech stuck)
--   3. Shadow claimed = spam degeneration for capstone damage
--
-- LOCK/DICTATE/MADPRESSION: Use universal opening (kelp -> shadow -> bellwort)
--   1. KELP: Stick clumsiness with degeneration (healthleech/manaleech are kelp-cured!)
--   2. SHADOW: Instill leach until shadow claimed (parasite/healthleech/manaleech)
--   3. BELLWORT STACK: Stick timeloop -> retribution -> justice
--      All 3 are bellwort-cured. Target can only eat bellwort once per balance,
--      so with 3 bellwort affs, 2 remain stuck at all times.
--   4. MODE-SPECIFIC: After opening completes, enter mode finisher
--
-- Capstone note: capstones are PER INSTILL -- the application after an
-- Instill's full ladder is its capstone (depthswalker.capstoneReady(instill)).
-- Mode finishers pick which Instill to finish.
--------------------------------------------------------------------------------

-- How much of the kelp/bellwort foundation is still on the target.
function depthswalker.foundationCount()
    local n = 0
    for _, aff in ipairs(depthswalker.FOUNDATION_AFFS) do
        if depthswalker.hasAff(aff) then n = n + 1 end
    end
    return n
end

-- Universal opening: kelp pressure -> shadow -> bellwort stack
-- Returns the next instill for the opening phase, or nil if opening is complete.
--
-- ALL modes need kelp pressure first! healthleech/manaleech are kelp-cured,
-- so without clumsiness stuck, they just cure the leach affs immediately.
--
-- CRITICAL: Once bellwort phase is complete (timeloop applied), we NEVER go back
-- to opening phases. The bellwortComplete flag ensures we move to finisher (depression)
-- even if target cures bellwort affs. This prevents the kelp->bellwort loop.
function depthswalker.selectInstillOpening()
    -- BELLWORT COMPLETE: skip the opening and go to the mode finisher -- but
    -- only while the foundation it built still stands. The latch used to be
    -- permanent once timeloop was seen, so a target that cured the kelp/
    -- bellwort stack down kept eating finishers with no pressure behind them
    -- (v4.7.366). Below FOUNDATION_MIN the latch drops and the opening rebuilds.
    if depthswalker.state.bellwortComplete then
        if depthswalker.foundationCount() >= depthswalker.FOUNDATION_MIN then
            return nil
        end
        depthswalker.state.bellwortComplete = false
    end

    -- Timeloop present (at high confidence -- this latches a phase change)
    -- with the foundation standing: the bellwort phase is complete.
    if depthswalker.hasAffConfident("timeloop")
        and depthswalker.foundationCount() >= depthswalker.FOUNDATION_MIN then
        depthswalker.state.bellwortComplete = true
        return nil
    end

    -- Phase 1: KELP PRESSURE - must stick clumsiness before going for leach
    -- Without kelp pressure, healthleech/manaleech get cured instantly
    if not depthswalker.hasAff("clumsiness") then
        depthswalker.selections.phase = "kelp"
        return "degeneration"
    end

    -- Phase 2: SHADOW - climb the leach ladder and fire its capstone; the
    -- capstone strike IS the claim (there is no SHADOW CLAIM command), and
    -- trigger 478 confirms it (kelp is now pressured, so the kelp-cured leach
    -- affs stick). EVERY mode takes it, LOCK included (v4.7.365): LOCK used
    -- to skip this phase, and in live spars it built kelp/bellwort pressure
    -- indefinitely without ever converting it into a shadow.
    if not depthswalker.state.haveShadow then
        depthswalker.selections.phase = "shadow"
        -- Rungs 1-3 and then the capstone are all the same instill.
        return "leach"
    end

    -- Phase 3: BELLWORT STACK - bury target with bellwort affs
    -- justice and retribution both come from instill retribution (justice first, retribution second)
    -- timeloop comes from chrono loop (handled by shouldTimeloop())
    depthswalker.selections.phase = "bellwort"
    if not depthswalker.hasAff("justice") then return "retribution" end
    if not depthswalker.hasAff("retribution") then return "retribution" end
    -- timeloop is applied via chrono loop when shouldTimeloop() returns true

    -- Opening complete: all bellwort affs stuck
    return nil
end

-- Lock finisher: the depression capstone (depression + anorexia + masochism)
-- is the lock's Shadowmancy contribution, so LOCK climbs the depression ladder
-- and fires its capstone -- the application AFTER its three rungs, never on a
-- total of unrelated DW affs. Once anorexia is stuck, the next ladder worth
-- climbing is degeneration, whose rungs and capstone include paralysis.
--
-- There is NO impatience branch: "impatience" is not a Shadowmancy instill
-- (v4.7.365; the game refuses it and leaves the previous instill on the
-- scythe, desyncing the venom and rung triggers after it).
function depthswalker.selectInstillLock()
    if not depthswalker.hasAff("anorexia") then
        return "depression"   -- a rung, or the capstone when capstoneReady
    end
    if not depthswalker.hasAff("paralysis") or depthswalker.capstoneReady("degeneration") then
        return "degeneration"
    end
    -- Anorexia and paralysis both stuck: keep the depression ladder cycling so
    -- its capstone is re-armed for the moment they cure anorexia.
    return "depression"
end

-- Damage route: kelp pressure first -> leach for shadow -> degeneration capstone
-- DIFFERENT from other modes: does NOT use universal opening, has its own strategy
--
-- Goal: Claim shadow to amplify degeneration damage (halved without shadow)
-- Strategy:
--   1. Spam degeneration + curare until clumsiness sticks (establishes kelp pressure)
--   2. Once clumsiness stuck, switch to leach for shadow (healthleech/manaleech are kelp-cured)
--   3. When healthleech stuck: use kalmia venom or chrono loop boost to get manaleech
--   4. Shadow claimed = spam degeneration for full capstone damage
function depthswalker.selectInstillDamage()
    -- Priority 1: Spam degeneration until clumsiness sticks
    -- Clumsiness is the first degeneration aff - once it sticks, kelp is pressured
    -- We don't wait for weariness because that comes automatically from continued degeneration
    if not depthswalker.hasAff("clumsiness") then
        depthswalker.selections.phase = "kelp"
        return "degeneration"
    end

    -- Priority 2: Clumsiness stuck, now climb the leach ladder toward shadow.
    -- With all three rungs up (capstoneReady("leach")) the next leach IS the
    -- capstone, and that strike claims the shadow (478 confirms it).
    -- Continue degeneration pressure (weariness/paralysis) via the venom slot
    if not depthswalker.state.haveShadow then
        depthswalker.selections.phase = "shadow"
        return "leach"
    end

    -- Priority 3: Shadow claimed = spam degeneration for capstone damage
    depthswalker.selections.phase = "damage"
    return "degeneration"
end

-- Dictate finisher: the retribution capstone saps mana toward the dictate
-- threshold. Its ladder is justice -> retribution, so the application after
-- both are up is the capstone; while a rung is missing, retribution climbs it.
function depthswalker.selectInstillDictate()
    return "retribution"
end

-- Is the target inside the stun window of our madness capstone? Stamped by
-- trigger 483 (the capstone line); nothing records "stun" as an affliction.
function depthswalker.madnessStunned()
    local at = depthswalker.state.madCapAt
    if not at then return false end
    return (getEpoch() - at) <= depthswalker.config.madStunWindow
end

function depthswalker.onMadnessCapstone()
    depthswalker.state.madCapAt = getEpoch()
end

-- Madpression finisher: madness capstone (stun), then the depression capstone
-- (anorexia + masochism) while they are stunned. Each fires only when ITS
-- ladder is complete; the two ladders are climbed together so both capstones
-- are armed at once.
function depthswalker.selectInstillMadpression()
    local madReady = depthswalker.capstoneReady("madness")
    local depReady = depthswalker.capstoneReady("depression")

    -- Stunned by our madness capstone: cash in depression while it lasts.
    if depthswalker.madnessStunned() then
        return "depression"
    end
    -- Both armed: open with the madness stun.
    if madReady and depReady then
        return "madness"
    end
    -- Arm whichever ladder is not yet complete (the one further behind first;
    -- depression on a tie).
    if depReady then return "madness" end
    if madReady then return "depression" end
    if depthswalker.instillStage("madness") < depthswalker.instillStage("depression") then
        return "madness"
    end
    return "depression"
end

-- Unified instill selector: damage skips opening, others use opening first
function depthswalker.selectInstill()
    local mode = depthswalker.state.mode

    -- DAMAGE/GROUP: Skip universal opening, use dedicated damage logic
    -- Damage route has its own kelp pressure -> leach -> degeneration strategy
    if mode == "damage" or mode == "group" then
        return depthswalker.selectInstillDamage()
    end

    -- LOCK/DICTATE/MADPRESSION: Universal opening takes priority (kelp -> shadow -> bellwort)
    -- Note: selectInstillOpening() sets depthswalker.selections.phase internally
    local opening = depthswalker.selectInstillOpening()
    if opening then
        return opening
    end

    -- Opening complete: route to mode-specific finisher
    depthswalker.selections.phase = mode
    if mode == "lock" then return depthswalker.selectInstillLock()
    elseif mode == "dictate" then return depthswalker.selectInstillDictate()
    elseif mode == "madpression" then return depthswalker.selectInstillMadpression()
    end
    return "degeneration"
end

--------------------------------------------------------------------------------
-- VENOM PRIORITY CHAINS
--
-- Venoms deliver standard afflictions via weapon strike (shadow reap).
-- When timeloop is active, venom slot is empty (no venom applied).
--
-- RULE: Use curare ALWAYS unless:
--   1. Target already has paralysis
--   2. Instill is madness or depression (use mode-specific logic)
--------------------------------------------------------------------------------

-- Special venom selection for madness/depression instills
-- These instills are used when building toward capstone, so we want to stack
-- afflictions that support the kill route
function depthswalker.selectVenomSpecial()
    local mode = depthswalker.state.mode
    local locks = depthswalker.getLocks()
    local instill = depthswalker.selections.instill

    -- INSTILL-SPECIFIC VENOM PAIRING (takes priority over mode logic)
    -- Depression: euphorbia (nausea) to progress the depression stack faster
    -- Depression stack: depression → nausea → hypochondria → capstone
    if instill == "depression" then
        if not depthswalker.hasAff("nausea") then return "euphorbia" end
        -- Nausea present: fall through to mode-specific logic
    end

    -- Madness: aconite (stupidity) for goldenseal stacking
    -- All madness affs are goldenseal-cured, stupidity is also goldenseal-cured
    -- Stacking goldenseal affs creates cure pressure (only 1 goldenseal per balance)
    if instill == "madness" then
        if not depthswalker.hasAff("stupidity") then return "aconite" end
        -- Stupidity present: fall through to mode-specific logic
    end

    -- Lock mode: build toward lock afflictions
    if mode == "lock" then
        -- Truelock achieved: apply class-specific lock aff
        if locks.truelock >= depthswalker.config.highConfidence then
            if getLockingAffliction then
                local lockAff = getLockingAffliction(target)
                if lockAff == "reckless" and not depthswalker.hasAff("recklessness") then
                    return "eurypteria"
                elseif lockAff == "weariness" and not depthswalker.hasAff("weariness") then
                    return "xentio"
                elseif lockAff == "plague" and not depthswalker.hasAff("voyria") then
                    return "voyria"
                elseif lockAff == "stupid" and not depthswalker.hasAff("stupidity") then
                    return "aconite"
                end
            end
            if not depthswalker.hasAff("recklessness") then return "eurypteria" end
        end
        -- Lock progression
        if not depthswalker.hasAff("asthma") then return "kalmia" end
        if not depthswalker.hasAff("slickness") then return "gecko" end
        if not depthswalker.hasAff("anorexia") then return "slike" end
        return "curare"
    end

    -- Madpression: sensitivity for masochism damage boost
    if mode == "madpression" then
        if not depthswalker.hasAff("sensitivity") then return "prefarar" end
        if not depthswalker.hasAff("asthma") then return "kalmia" end
        return "curare"
    end

    -- Dictate/Damage: asthma to block curing
    if not depthswalker.hasAff("asthma") then return "kalmia" end
    return "curare"
end

-- Secondary venom when paralysis already present (and not madness/depression instill)
function depthswalker.selectVenomSecondary()
    local mode = depthswalker.state.mode

    -- Damage mode: special healthleech timing
    if mode == "damage" or mode == "group" then
        if depthswalker.hasAff("healthleech") and not depthswalker.hasAff("asthma") then
            return "kalmia"
        end
    end

    -- Lock mode: continue lock progression
    if mode == "lock" then
        local locks = depthswalker.getLocks()
        if locks.truelock >= depthswalker.config.highConfidence then
            if not depthswalker.hasAff("recklessness") then return "eurypteria" end
        end
        if not depthswalker.hasAff("asthma") then return "kalmia" end
        if not depthswalker.hasAff("slickness") then return "gecko" end
        if not depthswalker.hasAff("anorexia") then return "slike" end
    end

    -- Default secondary: asthma if missing, else kelp stacking
    if not depthswalker.hasAff("asthma") then return "kalmia" end
    if not depthswalker.hasAff("clumsiness") then return "xentio" end
    if not depthswalker.hasAff("weariness") then return "xentio" end

    return "curare"
end

-- Unified venom selector
-- RULE: curare ALWAYS unless paralysis present OR instill is madness/depression
function depthswalker.selectVenom()
    local instill = depthswalker.selections.instill

    -- Madness/depression instills: use mode-specific smart selection
    if instill == "madness" or instill == "depression" then
        return depthswalker.selectVenomSpecial()
    end

    -- Default: curare unless paralysis present
    if not depthswalker.hasAff("paralysis") then
        return "curare"
    end

    -- Paralysis present: use secondary choice based on mode/situation
    return depthswalker.selectVenomSecondary()
end

--------------------------------------------------------------------------------
-- KILL CONDITION CHECKERS
--------------------------------------------------------------------------------

function depthswalker.needDictate()
    return depthswalker.canDictate()
end

function depthswalker.needMutilate()
    if not depthswalker.state.haveShadow then return false end
    if not php or not pm then return false end
    return php <= depthswalker.config.mutilateHealthThreshold
       and pm <= depthswalker.config.mutilateManaThreshold
end

function depthswalker.needCull()
    if not php then return false end
    return php <= depthswalker.config.cullHealthThreshold
end

function depthswalker.needShieldStrip()
    return depthswalker.hasAff("shield")
end


--------------------------------------------------------------------------------
-- ATTACK BUILDER
--
-- Priority: Dictate > Mutilate > Cull > Shield Strip > Normal
-- (No claim step: the leach capstone strike claims the shadow. v4.7.365 wired
-- a synthetic `shadow claim <target>`, which is not a command.)
--
-- Normal attack pattern:
--   shadow attune <target> to <attune>;
--   shadow instill scythe with <dw_aff>;
--   chrono assert|chrono loop [boost];
--   shadow reap <target> [venom];
--   [assess <target>;]   (config.assess -- Health Inspector makes it free)
--   contemplate <target>
--------------------------------------------------------------------------------

-- The info tail every packet ends with. ASSESS only when configured (it is
-- balanceless only with the Health Inspector trait); CONTEMPLATE always, since
-- Dictate and Mutilate read the target's mana (pm) from it.
function depthswalker.infoTail(sp)
    local tail = ""
    if depthswalker.config.assess then
        tail = "assess " .. target .. sp
    end
    return tail .. "contemplate " .. target
end

function depthswalker.buildAttack()
    local sp = ataxia.settings.separator
    local atk = depthswalkerQueue()
    local sel = depthswalker.selections
    local scythe = depthswalker.config.scytheId

    -- 1. Dictate (mana kill) - highest priority
    if depthswalker.needDictate() then
        atk = atk .. "shadow dictate " .. target
        return atk
    end

    -- 2. Mutilate (shadow execute)
    if depthswalker.needMutilate() then
        atk = atk .. "wield right dagger" .. sp
            .. "shadow mutilate " .. target .. " curare" .. sp
            .. depthswalker.infoTail(sp)
        return atk
    end

    -- 3. Cull (low HP finisher)
    if depthswalker.needCull() then
        atk = atk .. "shadow attune " .. target .. " to " .. sel.attune .. sp
            .. "intone tooros" .. sp
            .. "chrono assert" .. sp
            .. "shadow cull " .. target .. " curare" .. sp
            .. depthswalker.infoTail(sp)
        return atk
    end

    -- 5. Normal attack: attune + instill + chrono + reap [+ venom]
    -- Never send an instill the game will refuse: a refused instill leaves the
    -- previous one on the scythe and the rung/venom triggers fall out of step.
    if not depthswalker.validInstill(sel.instill) then
        if ataxiaEcho then
            ataxiaEcho("[DW] Refusing invalid instill '" .. tostring(sel.instill) .. "' -- using degeneration")
        end
        sel.instill = "degeneration"
    end
    local chrono = depthswalker.getChronoCommand()

    atk = atk .. "shadow attune " .. target .. " to " .. sel.attune .. sp
        .. "shadow instill scythe with " .. sel.instill .. sp
        .. chrono .. sp

    if sel.useTimeloop then
        -- Timeloop: reap without venom (double instill instead)
        atk = atk .. "shadow reap " .. target .. sp
    else
        -- Normal: reap with venom
        atk = atk .. "shadow reap " .. target .. " " .. sel.venom .. sp
    end

    atk = atk .. depthswalker.infoTail(sp)

    return atk
end

-- Shield strip: shadow strike to remove shield
function depthswalker.handleShield()
    local sp = ataxia.settings.separator
    local atk = depthswalkerQueue()
    atk = atk .. "shadow strike " .. target .. sp
        .. depthswalker.infoTail(sp)
    return atk
end

--------------------------------------------------------------------------------
-- MAIN DISPATCH
-- Entry point called by aliases. Validates target, selects instill/venom/attune,
-- builds attack, sends.
--------------------------------------------------------------------------------

function depthswalker.dispatch()
    -- Validate target exists
    if not target then return end

    -- Check target is in room
    if ataxia and ataxia.playersHere and not table.contains(ataxia.playersHere, target) then
        expandAlias("nt")
        return
    end

    -- Don't act under aeon
    if ataxia and ataxia.afflictions and ataxia.afflictions.aeon then return end

    -- Don't act if paralysed
    if ataxia and ataxia.afflictions and ataxia.afflictions.paralysis then return end

    -- Rebound hold gate
    if reboundHold and reboundHold.gate(depthswalker.dispatch) then return end

    -- RESET STATE: Clear bellwortComplete when target changes or new fight detected
    if depthswalker.state.lastTarget ~= target then
        depthswalker.state.bellwortComplete = false
        depthswalker.state.lastTarget = target
        depthswalker.state.madCapAt = nil
    end
    -- Also reset if no DW affs on target (fresh fight, they reset or new target)
    if depthswalker.countDWAffsInt() == 0 then
        depthswalker.state.bellwortComplete = false
    end

    -- Initialize defaults
    if not php then php = 100 end
    if not pm then pm = 100 end

    -- Initialize envenomList global (triggers read this to know which venom was applied)
    envenomList = {}

    -- Sync shadow state from global (set by triggers)
    depthswalker.state.haveShadow = haveshadow or false
    depthswalker.state.distorted = depdistort or false

    -- Check locks
    if checkTargetLocksV3 then
        checkTargetLocksV3()
    elseif checkTargetLocks then
        checkTargetLocks()
    end

    -- Select instill, venom, timeloop, attune
    depthswalker.selections.instill = depthswalker.selectInstill()
    depthswalker.selections.venom = depthswalker.selectVenom()
    depthswalker.selections.useTimeloop = depthswalker.shouldTimeloop()

    -- Populate envenomList for triggers (unless using timeloop = no venom)
    if not depthswalker.selections.useTimeloop and depthswalker.selections.venom then
        table.insert(envenomList, depthswalker.selections.venom)
    end

    -- Attune selection by mode
    if depthswalker.state.mode == "madpression" then
        depthswalker.selections.attune = "madness"
    else
        depthswalker.selections.attune = "degeneration"
    end

    -- Attack echo (always shows) and debug echo (if enabled)
    depthswalker.attackEcho()
    depthswalker.debugEcho()

    -- Shield check: strip shield instead of attacking
    if depthswalker.needShieldStrip() then
        local cmd = depthswalker.handleShield()
        send("wield left " .. depthswalker.config.scytheId .. ";wield right dagger;wipe " .. depthswalker.config.scytheId .. ";queue addclear free " .. cmd)
        return
    end

    -- Build and send attack
    local atk = depthswalker.buildAttack()
    send("wield left " .. depthswalker.config.scytheId .. ";wield right shield;wipe " .. depthswalker.config.scytheId .. ";queue addclear free " .. atk)
end

--------------------------------------------------------------------------------
-- MODE SETTERS
--------------------------------------------------------------------------------

function depthswalker.setMode(mode)
    local validModes = {lock = true, damage = true, dictate = true, madpression = true, group = true}
    if not validModes[mode] then
        if ataxiaEcho then
            ataxiaEcho("[DW] Invalid mode: " .. tostring(mode) .. ". Valid: lock, damage, dictate, madpression, group")
        end
        return
    end
    depthswalker.state.mode = mode
    if ataxiaEcho then
        ataxiaEcho("[DW] Mode set to: " .. mode)
    end
end

--------------------------------------------------------------------------------
-- DEBUG / STATUS
--------------------------------------------------------------------------------

-- Attack echo - ALWAYS shows attack info (like Infernal/Shikudo offenses)
function depthswalker.attackEcho()
    local sel = depthswalker.selections
    local inst = sel.instill or "?"
    local ven = sel.venom or "?"
    local chrono = sel.useTimeloop and "<magenta>LOOP<reset>" or "assert"
    local phase = sel.phase or depthswalker.state.mode
    local mode = depthswalker.state.mode:upper()

    -- Phase color
    local phaseColor = "<cyan>"
    if phase == "kelp" then phaseColor = "<green>"
    elseif phase == "shadow" then phaseColor = "<yellow>"
    elseif phase == "bellwort" then phaseColor = "<magenta>"
    elseif phase == "damage" then phaseColor = "<red>"
    end

    -- DW affs summary for damage mode
    local dwInfo = ""
    if depthswalker.state.mode == "damage" or depthswalker.state.mode == "group" then
        local clum = depthswalker.hasAff("clumsiness") and "<green>C<reset>" or "<red>c<reset>"
        local wear = depthswalker.hasAff("weariness") and "<green>W<reset>" or "<red>w<reset>"
        local para = depthswalker.hasAff("paralysis") and "<green>P<reset>" or "<red>p<reset>"
        local par = depthswalker.hasAff("parasite") and "<green>p<reset>" or "<red>-<reset>"
        local hl = depthswalker.hasAff("healthleech") and "<green>h<reset>" or "<red>-<reset>"
        local ml = depthswalker.hasAff("manaleech") and "<green>m<reset>" or "<red>-<reset>"
        local shad = depthswalker.state.haveShadow and "<green>SHADOW<reset>" or "<red>no shadow<reset>"
        dwInfo = " | Degen:[" .. clum .. wear .. para .. "] Leach:[" .. par .. hl .. ml .. "] " .. shad
    else
        -- Per-Instill ladders (* = capstone next) for the capstone routes
        dwInfo = " | " .. depthswalker.stageSummary()
    end

    cecho("\n<cyan>[DW:" .. mode .. "]<reset> " .. phaseColor .. phase:upper() .. "<reset>"
        .. " | <green>" .. inst .. "<reset>/" .. ven
        .. " | " .. chrono
        .. dwInfo .. "\n")
end

-- Verbose debug echo - shows full details (toggle with dwd)
function depthswalker.debugEcho()
    if not depthswalker.config.debugEcho then return end

    local sys = depthswalker.getTrackingSystem()
    -- Per-Instill ladders; * = that Instill's capstone is the next application
    local capStr = depthswalker.stageSummary()

    -- Key lock affs
    local lockAffs = {"asthma", "slickness", "paralysis", "impatience", "anorexia", "recklessness"}
    local stuck = {}
    for _, aff in ipairs(lockAffs) do
        if depthswalker.hasAff(aff) then
            stuck[#stuck + 1] = aff
        end
    end
    local stuckStr = #stuck > 0 and table.concat(stuck, ", ") or "none"

    cecho("<cyan>[DW DEBUG]<reset> Cap: <yellow>" .. capStr
        .. "<reset> | Stuck(<cyan>" .. sys .. "<reset>): <red>" .. stuckStr .. "<reset>\n")
end

function depthswalker.status()
    local sys = depthswalker.getTrackingSystem()
    local locks = depthswalker.getLocks()
    local dwCount = depthswalker.countDWAffsInt()
    local dictThresh = depthswalker.getDictateThreshold()
    local age = depthswalker.getAge()

    echo("\n=== Depthswalker Offense Status ===\n")
    echo("  Mode: " .. depthswalker.state.mode .. "\n")
    echo("  Tracking: " .. sys .. "\n")
    echo("  Age: " .. age .. "\n")
    echo("  Shadow: " .. tostring(depthswalker.state.haveShadow) .. "\n")
    echo("  DW Affs: " .. dwCount .. "\n")
    echo("  Assess per attack: " .. tostring(depthswalker.config.assess) .. " (dwassess on|off)\n")
    echo("  Instill ladders (* = capstone next): " .. depthswalker.stageSummary() .. "\n")
    echo("  Dictate Threshold: " .. dictThresh .. "% (target mana: " .. (pm or "?") .. "%)\n")
    echo("  Can Dictate: " .. tostring(depthswalker.canDictate()) .. "\n")
    echo("  Softlock: " .. string.format("%.0f%%", locks.softlock * 100) .. "\n")
    echo("  Hardlock: " .. string.format("%.0f%%", locks.hardlock * 100) .. "\n")
    echo("  Truelock: " .. string.format("%.0f%%", locks.truelock * 100) .. "\n")
    echo("  Scythe ID: " .. depthswalker.config.scytheId .. "\n")
    echo("  Can Timeloop: " .. tostring(depthswalker.canTimeloop()) .. "\n")

    -- DW afflictions on target
    echo("\n  DW Afflictions on target:\n")
    local anyDW = false
    for _, aff in ipairs(depthswalker.DW_AFFS) do
        if depthswalker.hasAff(aff) then
            local prob = depthswalker.getAffProb(aff)
            echo("    " .. aff .. ": " .. string.format("%.0f%%", prob * 100) .. "\n")
            anyDW = true
        end
    end
    if not anyDW then
        echo("    (none)\n")
    end

    -- Current selections
    local sel = depthswalker.selections
    echo("\n  Phase: " .. (sel.phase or "init") .. "\n")
    if sel.instill then
        echo("  Last Instill: " .. sel.instill .. "\n")
    end
    if sel.venom then
        echo("  Last Venom: " .. sel.venom .. "\n")
    end
    echo("====================================\n")
end
