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
-- Capstones fire automatically at 5 DW afflictions. The capstone type matches
-- the instill affliction, so capstone selection IS the instill selection.
--
-- DW Afflictions (count toward capstones and Dictate threshold):
--   depression, retribution, parasite, madness, degeneration,
--   healthleech, manaleech, justice, timeloop
--
-- Dictate threshold: 40% mana + 5% per DW affliction on target
-- Mutilate threshold: 40% HP + 30% mana + shadow claimed
--------------------------------------------------------------------------------

depthswalker = depthswalker or {}

--------------------------------------------------------------------------------
-- STATE & CONFIG
--------------------------------------------------------------------------------

depthswalker.state = {
    mode = "lock",              -- "lock", "damage", "dictate", "madpression", "group"
    haveShadow = false,         -- shadow claimed from target
    canClaimShadow = false,     -- leach capstone fired, shadow available to claim
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
}

-- Current attack selections (set each dispatch cycle)
depthswalker.selections = {
    instill = nil,
    venom = nil,
    attune = "degeneration",
    useTimeloop = false,
    phase = "init",       -- "shadow", "bellwort", or mode name (set by selectInstill)
}

-- The 9 DW-specific afflictions tracked on the target
depthswalker.DW_AFFS = {
    "depression", "retribution", "parasite", "madness",
    "degeneration", "healthleech", "manaleech", "justice", "timeloop",
}

--------------------------------------------------------------------------------
-- V3 ROUTING HELPERS
--------------------------------------------------------------------------------

-- Check if target has an affliction (V3 -> V2 -> V1 routing)
-- Now consistent with global haveAff() which also routes to V3 when enabled.
function depthswalker.hasAff(aff)
    -- V3 first when enabled
    if affConfigV3 and affConfigV3.enabled and haveAffV3 then
        return haveAffV3(aff)
    end
    -- V2 fallback
    if ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
        if haveAffV2 then
            return haveAffV2(aff)
        elseif tAffsV2 and tAffsV2[aff] then
            return true
        end
        return false
    end
    -- V1 fallback
    if tAffs and tAffs[aff] then
        return true
    end
    return false
end

-- Get affliction probability (0.0-1.0). Falls back to binary for V2/V1.
function depthswalker.getAffProb(aff)
    if affConfigV3 and affConfigV3.enabled and getAffProbabilityV3 then
        return getAffProbabilityV3(aff)
    end
    return depthswalker.hasAff(aff) and 1.0 or 0
end

-- Check which tracking system is active
function depthswalker.getTrackingSystem()
    if affConfigV3 and affConfigV3.enabled then return "V3"
    elseif ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then return "V2"
    end
    return "V1"
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

-- Returns true if target has 5+ DW afflictions (capstone fires on next instill)
function depthswalker.capstoneReady()
    return depthswalker.countDWAffsInt() >= 5
end

-- Dictate threshold: 40% base + 5% per DW affliction on target
function depthswalker.getDictateThreshold()
    local dwAffCount = depthswalker.countDWAffsInt()
    return 40 + (dwAffCount * 5)
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

    local dwCount = depthswalker.countDWAffsInt()
    local mode = depthswalker.state.mode
    local phase = depthswalker.selections.phase

    -- CRITICAL: When healthleech stuck but not manaleech, use chrono loop boost
    -- ONLY during shadow phase - double-apply leach to get manaleech before they cure healthleech
    -- Don't let this trigger during bellwort/lock phases!
    local phase = depthswalker.selections.phase
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
    local phase = depthswalker.selections.phase
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

    -- LOCK/DICTATE/MADPRESSION: use timeloop more aggressively to build DW aff count
    -- High-value: 3-4 DW affs, rushing to capstone threshold (5)
    if dwCount >= 3 and dwCount < 5 then return true end

    -- Lock mode: double affliction pressure when building
    if mode == "lock" and dwCount >= 2 then return true end

    -- Madpression: rush to capstone
    if mode == "madpression" and dwCount >= 2 then return true end

    -- Dictate: maximize DW aff count for lower threshold
    if mode == "dictate" and dwCount >= 2 then return true end

    return false
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
-- Capstone note: When 5+ DW affs are present, capstone fires matching the
-- instill type. Mode finishers handle capstone selection.
--------------------------------------------------------------------------------

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
    -- BELLWORT COMPLETE: Skip opening entirely, go straight to mode finisher
    -- This is set when timeloop is first applied during bellwort phase.
    -- Even if target cures bellwort affs, we stay in finisher (depression/madness).
    if depthswalker.state.bellwortComplete then
        return nil
    end

    -- Check if timeloop is present - if so, bellwort phase is complete
    -- This catches the case where timeloop was applied but bellwortComplete wasn't set yet
    if depthswalker.hasAff("timeloop") then
        depthswalker.state.bellwortComplete = true
        return nil
    end

    -- Phase 1: KELP PRESSURE - must stick clumsiness before going for leach
    -- Without kelp pressure, healthleech/manaleech get cured instantly
    if not depthswalker.hasAff("clumsiness") then
        depthswalker.selections.phase = "kelp"
        return "degeneration"
    end

    -- Phase 2: SHADOW - get leach affs for shadow claim (kelp is now pressured)
    -- LOCK MODE: Skip shadow phase entirely - go straight to bellwort for mental stacking
    -- Shadow is only needed for damage/dictate modes (mutilate execute, enhanced damage)
    local mode = depthswalker.state.mode
    if mode ~= "lock" and not depthswalker.state.haveShadow then
        depthswalker.selections.phase = "shadow"
        if not depthswalker.hasAff("parasite") then return "leach" end
        if not depthswalker.hasAff("healthleech") then return "leach" end
        if not depthswalker.hasAff("manaleech") then return "leach" end
        -- All leach affs present but no shadow yet: if capstone ready, fire leach
        -- capstone to enable shadow claim. If not ready, fall through to bellwort
        -- stacking to build DW aff count toward capstone.
        if depthswalker.capstoneReady() then return "leach" end
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

-- Lock finisher: impatience (only via instill!), depression capstone for anorexia+masochism
function depthswalker.selectInstillLock()
    local capReady = depthswalker.capstoneReady()

    -- Capstone ready: depression gives anorexia + masochism (lock components)
    if capReady then
        return "depression"
    end

    -- Impatience is ONLY deliverable via instill - prioritize when asthma is stuck
    if not depthswalker.hasAff("impatience") and depthswalker.hasAff("asthma") then
        return "impatience"
    end

    -- Build remaining DW affs toward capstone (bellwort affs already stuck from opening)
    if not depthswalker.hasAff("depression") then return "depression" end
    if not depthswalker.hasAff("madness") then return "madness" end
    if not depthswalker.hasAff("degeneration") then return "degeneration" end
    if not depthswalker.hasAff("parasite") then return "leach" end
    if not depthswalker.hasAff("healthleech") then return "leach" end
    if not depthswalker.hasAff("manaleech") then return "leach" end

    -- All DW affs applied, keep cycling depression for capstone
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

    -- Priority 2: Clumsiness stuck, now build leach toward shadow
    -- Continue degeneration pressure (weariness/paralysis) via the venom slot
    if not depthswalker.state.haveShadow then
        depthswalker.selections.phase = "shadow"
        if not depthswalker.hasAff("parasite") then return "leach" end
        if not depthswalker.hasAff("healthleech") then return "leach" end
        if not depthswalker.hasAff("manaleech") then return "leach" end
        -- All leach affs present: capstone will fire and claim shadow
        return "leach"
    end

    -- Priority 3: Shadow claimed = spam degeneration for capstone damage
    depthswalker.selections.phase = "damage"
    return "degeneration"
end

-- Dictate finisher: retribution capstone for mana sap (retribution already stuck from opening)
function depthswalker.selectInstillDictate()
    local capReady = depthswalker.capstoneReady()

    -- Capstone ready: retribution saps mana toward dictate threshold
    if capReady then
        return "retribution"
    end

    -- Build DW aff count (bellwort affs already stuck, each lowers dictate threshold by 5%)
    if not depthswalker.hasAff("depression") then return "depression" end
    if not depthswalker.hasAff("madness") then return "madness" end
    if not depthswalker.hasAff("degeneration") then return "degeneration" end
    if not depthswalker.hasAff("parasite") then return "leach" end
    if not depthswalker.hasAff("healthleech") then return "leach" end
    if not depthswalker.hasAff("manaleech") then return "leach" end

    return "retribution"
end

-- Madpression finisher: madness capstone (stun) then depression capstone (anorexia+masochism)
function depthswalker.selectInstillMadpression()
    local capReady = depthswalker.capstoneReady()

    -- Capstone ready: alternate madness then depression
    if capReady then
        -- Fire madness first for stun, then depression while stunned
        if not depthswalker.hasAff("stun") then
            return "madness"
        end
        -- Target stunned: depression gives anorexia + masochism
        return "depression"
    end

    -- Build remaining DW affs toward capstone (bellwort affs already stuck)
    if not depthswalker.hasAff("depression") then return "depression" end
    if not depthswalker.hasAff("madness") then return "madness" end
    if not depthswalker.hasAff("degeneration") then return "degeneration" end
    if not depthswalker.hasAff("parasite") then return "leach" end
    if not depthswalker.hasAff("healthleech") then return "leach" end

    return "madness"
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

function depthswalker.needClaimShadow()
    return depthswalker.state.canClaimShadow and not depthswalker.state.haveShadow
end

--------------------------------------------------------------------------------
-- ATTACK BUILDER
--
-- Priority: Dictate > Mutilate > Cull > Claim Shadow > Shield Strip > Normal
--
-- Normal attack pattern:
--   shadow attune <target> to <attune>;
--   shadow instill scythe with <dw_aff>;
--   chrono assert|chrono loop [boost];
--   shadow reap <target> [venom];
--   assess <target>;
--   contemplate <target>
--------------------------------------------------------------------------------

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
            .. "assess " .. target .. sp
            .. "contemplate " .. target
        return atk
    end

    -- 3. Cull (low HP finisher)
    if depthswalker.needCull() then
        atk = atk .. "shadow attune " .. target .. " to " .. sel.attune .. sp
            .. "intone tooros" .. sp
            .. "chrono assert" .. sp
            .. "shadow cull " .. target .. " curare" .. sp
            .. "assess " .. target .. sp
            .. "contemplate " .. target
        return atk
    end

    -- 4. Claim shadow (after leach capstone)
    if depthswalker.needClaimShadow() then
        atk = atk .. "shadow attune " .. target .. " to " .. sel.attune .. sp
            .. "shadow instill scythe with degeneration" .. sp
            .. "chrono assert" .. sp
            .. "shadow claim " .. target .. sp
            .. "assess " .. target .. sp
            .. "contemplate " .. target
        return atk
    end

    -- 5. Normal attack: attune + instill + chrono + reap [+ venom]
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

    atk = atk .. "assess " .. target .. sp .. "contemplate " .. target

    return atk
end

-- Shield strip: shadow strike to remove shield
function depthswalker.handleShield()
    local sp = ataxia.settings.separator
    local atk = depthswalkerQueue()
    atk = atk .. "shadow strike " .. target .. sp
        .. "assess " .. target .. sp
        .. "contemplate " .. target
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

    -- RESET STATE: Clear bellwortComplete when target changes or new fight detected
    if depthswalker.state.lastTarget ~= target then
        depthswalker.state.bellwortComplete = false
        depthswalker.state.lastTarget = target
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
    end

    cecho("\n<cyan>[DW:" .. mode .. "]<reset> " .. phaseColor .. phase:upper() .. "<reset>"
        .. " | <green>" .. inst .. "<reset>/" .. ven
        .. " | " .. chrono
        .. dwInfo .. "\n")
end

-- Verbose debug echo - shows full details (toggle with dwd)
function depthswalker.debugEcho()
    if not depthswalker.config.debugEcho then return end

    local sel = depthswalker.selections
    local dwCount = depthswalker.countDWAffsInt()
    local sys = depthswalker.getTrackingSystem()
    local capStr = depthswalker.capstoneReady() and "<green>READY<reset>" or (tostring(dwCount) .. "/5")

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
    echo("  DW Affs: " .. dwCount .. "/5 (capstone " .. (depthswalker.capstoneReady() and "READY" or "building") .. ")\n")
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
