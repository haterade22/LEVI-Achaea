--[[mudlet
type: script
name: Serpent Offense
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Serpent
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    SERPENT OFFENSE SYSTEM (Overhaul)
    ============================================================================

    DSTAB-primary offense with conditional IMPULSE for Ekanelia triggers.

    ATTACK MODES:
    - DSTAB (primary): 2 venoms per round, BAL only. Always works.
    - IMPULSE (conditional): suggestion + bite + Ekanelia (BAL+EQ).
      Only when: no sileris/fangbarrier AND Ekanelia achievable AND eq free.
    - FLAY: strip defense + venom, BAL only.
    - EXECUTE: truelock finish.

    EKANELIA TRANSFORMATIONS (BITE/IMPULSE only):
    - kalmia:    clumsiness + weariness           → slickness
    - aconite:   deadening + dementia              → paranoia
    - monkshood: asthma + masochism + weariness    → impatience
    - curare:    hypersomnia + masochism            → hypochondria
    - voyria:    anorexia + impatience + vertigo    → confusion + disrupted
    - loki:      confusion + recklessness           → nausea + paralysis
    - scytherus: addiction + nausea                 → camus

    SELECTION LOGIC (Lock-First):
    0. Strip rebounding/shield (flay)
    1. Can complete truelock? → deliver missing piece
    2. Can complete hardlock? → deliver missing piece
    3. Can complete softlock? → deliver missing piece
    4. Ekanelia conditionals all met? → free Ekanelia via impulse
    5. One trivial conditional missing? → impulse completes it
    6. Need DSTAB setup? → dstab venoms that set up Ekanelia
    Fallback: general affliction pressure

    ALIASES:
    - ek        : Main attack
    - eklock    : Lock mode
    - ekhyp     : Hypnosis combo mode
    - ekdark    : Darkshade DoT mode
    - ekscyth   : Scytherus camus damage mode
    - ekauto    : Auto-switch mode
    - ekstatus  : Status display
    ============================================================================
]]--

-- =============================================================================
-- INITIALIZATION & CONFIGURATION
-- =============================================================================

serpent = serpent or {}
serpent.config = serpent.config or {}
serpent.hypnosis = serpent.hypnosis or {}
serpent.state = serpent.state or {}

-- Per-aff impulse timestamps for fratricide 3s relapse window.
-- Every impulse call goes through recordImpulse() and selectImpulse() respects the window.
lastImpulsed = lastImpulsed or {}

-- Timestamp (os.clock) of when the target's rebounding was last observed to drop.
-- Rebounding reapplies ~8.5s after being stripped; we pre-empt that reapply with an
-- impulse instead of eating a reflected hit. 0 = disarmed. Reset on target change.
lastReboundingFlay = lastReboundingFlay or 0

-- Impatience delivery cooldown (2.5s).
-- Stamped by the ekanelia confirm trigger, NOT on send.
lastImpatienceAttempt = lastImpatienceAttempt or 0

-- Combat state
serpOffenseMode = serpOffenseMode or "auto"
serpStrategy = serpStrategy or "lock"
attackMode = attackMode or "dstab"
ekaneliaReady = ekaneliaReady or {}
impulseReady = false
affTimers = affTimers or {}

-- Confidence-tier wrappers over the V3 branching tracker (P0 finisher-safety).
-- LEVI's tracker exposes graded probabilities; these give the lock/finisher
-- logic the same semantic tiers inferno uses (locked = 0.90 for the kill gate,
-- tactical = 0.70 for lock pieces) instead of the flat 0.30 that haveAff() uses.
-- haveAffV3 is a global from 007_Branching_State_Tracker.lua; fall back to
-- haveAff() only if the tracker isn't loaded yet (partial-reload safety).
-- NOTE: explicit if-form, not `haveAffV3 and haveAffV3(a,x) or haveAff(a)` —
-- the and/or idiom would wrongly return the fallback whenever the graded check
-- is legitimately false.
local function haveAff_locked(aff)
    if haveAffV3 then return haveAffV3(aff, 0.90) end
    return haveAff(aff)
end
local function haveAff_tactical(aff)
    if haveAffV3 then return haveAffV3(aff, 0.70) end
    return haveAff(aff)
end

-- Attack state tracking
serpent.state.attackInFlight = serpent.state.attackInFlight or false
serpent.state.lastBalState = serpent.state.lastBalState or "1"
serpent.state.dispelSent = serpent.state.dispelSent or false
serpent.state.firstAttack = (serpent.state.firstAttack == nil) and true or serpent.state.firstAttack
serpent.state.pinshotSentAt = serpent.state.pinshotSentAt or 0
serpent.state.sigilDeployed = serpent.state.sigilDeployed or false
serpent.state.blockedExits = serpent.state.blockedExits or {}  -- {[dir] = epoch_blocked_at}
serpent.state.lastBlockSentAt = serpent.state.lastBlockSentAt or 0

-- Relapse locking state
serpent.state.impatienceDelivered = serpent.state.impatienceDelivered or false
serpent.state.stupidityImpulseSent = serpent.state.stupidityImpulseSent or false
serpent.state.relapsePhase = serpent.state.relapsePhase or false
serpent.state.voyriaSent = serpent.state.voyriaSent or false
serpent.state.geckoStripAttempted = serpent.state.geckoStripAttempted or false
-- Target rebounding presence last tick, to detect the present->absent drop.
serpent.state.lastRebounding = serpent.state.lastRebounding or false
serpent.state.postGeckoLockdown = serpent.state.postGeckoLockdown or false
serpent.state.lockReinforceSent = serpent.state.lockReinforceSent or false
serpent.state.camusDelivered = serpent.state.camusDelivered or false

-- Suggestion queueing (keybind-driven)
hSuggRequest = hSuggRequest or ""
hSuggActive = hSuggActive or ""

-- Configuration
serpent.config = {
    debug = false,
    echoStrategy = true,
    echoAffs = true,
    autoFratricide = true,
    -- Round-1 tempo (Track 1)
    useOpener = true,        -- inject pinshot + adder + dispel on first attack
    useBowOpener = true,     -- include bow swap + pinshot in the opener (set false if bow not held)
    bowName = "bow",         -- name used in `wield <bowName>` (lupine bow default works as `bow`)
    -- Defensive denial (Track 3) — gated OFF by default; enable per-fight
    useExitBlock = false,    -- send `block <direction>` between rounds
    useSigils = false,       -- drop incandescent + monolith sigil on round 1
}

-- Constants
DARKSHADE_KILL_TIME = 26
DARKSHADE_SWITCH_TIME = 15
SNAP_DELAY = 4
COOLDOWN_TIME = 4

-- Trivial suggestions (deliverable via IMPULSE)
local TRIVIAL_SUGGESTIONS = {
    "amnesia", "paranoia", "loneliness", "claustrophobia", "stuttering",
    "hallucinations", "dementia", "deadening", "epilepsy", "agoraphobia",
    "masochism", "recklessness", "vertigo", "confusion", "stupidity"
}

-- Impulse priority list for nil-safe selectImpulse().
-- Order: focus disruption first, then mental stacking, then ekanelia setup affs.
local IMPULSE_PRIORITY = {
    "confusion",      -- slows focus, sets up voyria ekanelia
    "stupidity",      -- blocks actions immediately
    "masochism",      -- key ekanelia conditional (impatience + hypochondria)
    "recklessness",   -- sets up loki ekanelia, blocks some passive cures
    "vertigo",        -- sets up voyria ekanelia
    "epilepsy",       -- nervous system disruption
    "dementia",       -- sets up aconite ekanelia
    "deadening",      -- sets up aconite ekanelia
    "hallucinations", -- mental stack filler
    "paranoia",       -- mental stack filler
    "loneliness",     -- mental stack filler
}

-- Venom → affliction mapping
local VENOM_TO_AFF = {
    kalmia = "asthma", vernalius = "weariness", xentio = "clumsiness",
    curare = "paralysis", gecko = "slickness", slike = "anorexia",
    euphorbia = "nausea", vardrax = "addiction", eurypteria = "recklessness",
    aconite = "stupidity", monkshood = "disfigurement", scytherus = "scytherus",
    darkshade = "darkshade", voyria = "voyria", notechis = "haemophilia",
    loki = "random",
}

-- Affliction → venom mapping (for lock completion)
local AFF_TO_VENOM = {
    asthma = "kalmia", weariness = "vernalius", clumsiness = "xentio",
    paralysis = "curare", slickness = "gecko", anorexia = "slike",
    nausea = "euphorbia", addiction = "vardrax", recklessness = "eurypteria",
    stupidity = "aconite", darkshade = "darkshade",
    voyria = "voyria", haemophilia = "notechis",
}

-- =============================================================================
-- HYPNOSIS STATE MACHINE
-- =============================================================================

serpent.hypnosis = {
    phase = "idle",
    suggestions = {},
    fratricideApplied = false,
    fratricideActive = false,
    snapTimer = nil,
    snapReadyTime = nil,
    hypnoTarget = nil,
    -- Hypno lock mode fields
    mode = "fratricide",      -- "fratricide" (existing) | "lock" (hypno lock)
    targetSuggestions = {},    -- pre-selected suggestions for lock mode
    sealed = false,           -- seal confirmed
    snapTimerFired = false,   -- 4s timer has fired (independent of phase)
}

function serpent.hypnosis.start(tar)
    serpent.hypnosis.phase = "hypnotising"
    serpent.hypnosis.suggestions = {}
    serpent.hypnosis.fratricideApplied = false
    serpent.hypnosis.hypnoTarget = tar or target

    if serpent.config.debug then
        Algedonic.Echo("<cyan>HYPNOSIS: <white>Starting hypnotise on " .. (tar or target))
    end
end

function serpent.hypnosis.onHypnotised()
    serpent.hypnosis.phase = "hypnotised"
    tAffs.hypnotised = true
    tAffs.hypnotising = false

    serpent.hypnosis.snapReadyTime = getEpoch() + SNAP_DELAY
    Algedonic.Echo("<green>HYPNOSIS: <white>Target hypnotised! Snap ready in " .. SNAP_DELAY .. "s")

    if serpent.hypnosis.snapTimer then
        killTimer(serpent.hypnosis.snapTimer)
    end
    serpent.hypnosis.snapTimerFired = false
    serpent.hypnosis.snapTimer = tempTimer(SNAP_DELAY, function()
        serpent.hypnosis.snapTimerFired = true
        if serpent.hypnosis.phase == "suggesting" or serpent.hypnosis.phase == "hypnotised" then
            serpent.hypnosis.phase = "ready_snap"
            Algedonic.Echo("<yellow>HYPNOSIS: <white>SNAP READY!")
        end
    end)
end

function serpent.hypnosis.onSuggested(suggestion)
    serpent.hypnosis.phase = "suggesting"

    if suggestion and suggestion:lower():find("fratricide") then
        serpent.hypnosis.fratricideApplied = true
        Algedonic.Echo("<magenta>HYPNOSIS: <white>Fratricide queued - mental affs will RELAPSE!")
    end

    table.insert(serpent.hypnosis.suggestions, suggestion)

    if serpent.config.debug then
        Algedonic.Echo("<cyan>HYPNOSIS: <white>Suggested " .. (suggestion or "unknown"))
    end
end

function serpent.hypnosis.onSnapped()
    serpent.hypnosis.phase = "cooldown"
    tAffs.snapped = true
    tAffs.hypnotised = false

    if serpent.hypnosis.fratricideApplied then
        serpent.hypnosis.fratricideActive = true
        tAffs.fratricide = true
        Algedonic.Echo("<red>HYPNOSIS: <white>SNAP! Fratricide ACTIVE - Impulse affs will relapse!")
    else
        Algedonic.Echo("<yellow>HYPNOSIS: <white>SNAP triggered!")
    end

    if serpent.hypnosis.snapTimer then
        killTimer(serpent.hypnosis.snapTimer)
        serpent.hypnosis.snapTimer = nil
    end

    -- Auto-switch: hypnolock → lock after snap
    if serpOffenseMode == "hypnolock" then
        tempTimer(0.5, function()
            serpOffenseMode = "lock"
            Algedonic.Echo("<green>HYPNO LOCK: <white>Snap complete -> switching to LOCK mode")
        end)
    end

    tempTimer(COOLDOWN_TIME, function()
        serpent.hypnosis.phase = "idle"
    end)
end

function serpent.hypnosis.onFratricideCured()
    serpent.hypnosis.fratricideActive = false
    tAffs.fratricide = false
    Algedonic.Echo("<dim_grey>HYPNOSIS: <white>Target cured fratricide")
end

function serpent.hypnosis.onSealed()
    serpent.hypnosis.sealed = true
    Algedonic.Echo("<green>HYPNOSIS: <white>Sealed " .. #serpent.hypnosis.suggestions .. " suggestions!")
end

function serpent.hypnosis.reset()
    serpent.hypnosis.phase = "idle"
    serpent.hypnosis.suggestions = {}
    serpent.hypnosis.fratricideApplied = false
    serpent.hypnosis.fratricideActive = false
    serpent.hypnosis.hypnoTarget = nil
    serpent.hypnosis.snapReadyTime = nil
    -- Hypno lock fields
    serpent.hypnosis.mode = "fratricide"
    serpent.hypnosis.targetSuggestions = {}
    serpent.hypnosis.sealed = false
    serpent.hypnosis.snapTimerFired = false

    if serpent.hypnosis.snapTimer then
        killTimer(serpent.hypnosis.snapTimer)
        serpent.hypnosis.snapTimer = nil
    end
end

function serpent.hypnosis.getCommand()
    local tar = target or serpent.hypnosis.hypnoTarget

    -- Start hypnosis (both modes)
    if serpent.hypnosis.phase == "idle" then
        return "hypnotise " .. tar
    end

    if serpent.hypnosis.mode == "lock" then
        -- Lock mode: suggest ×N → seal → snap
        local given = #serpent.hypnosis.suggestions
        local needed = #serpent.hypnosis.targetSuggestions

        if (serpent.hypnosis.phase == "hypnotised" or serpent.hypnosis.phase == "suggesting")
           and given < needed then
            -- Next suggestion
            return "suggest " .. tar .. " " .. serpent.hypnosis.targetSuggestions[given + 1]
        elseif given >= needed and not serpent.hypnosis.sealed then
            -- All suggestions given, seal them
            return "seal " .. tar .. " " .. needed
        elseif serpent.hypnosis.sealed then
            -- Sealed, snap
            return "snap " .. tar
        end
    else
        -- Fratricide mode (existing behavior)
        if (serpent.hypnosis.phase == "hypnotised" or serpent.hypnosis.phase == "suggesting")
           and not serpent.hypnosis.fratricideApplied then
            return "suggest " .. tar .. " fratricide"
        end

        if serpent.hypnosis.phase == "ready_snap" then
            return "snap " .. tar
        end
    end

    return nil
end

function serpent.hypnosis.canSnap()
    if serpent.hypnosis.mode == "lock" then
        return serpent.hypnosis.sealed
    end
    return serpent.hypnosis.phase == "ready_snap"
end

function serpent.hypnosis.isActive()
    return serpent.hypnosis.phase ~= "idle" and serpent.hypnosis.phase ~= "cooldown"
end

function serpent.hypnosis.hasFratricide()
    return serpent.hypnosis.fratricideActive or tAffs.fratricide
end

function serpent.hypnosis.getTimeToSnap()
    if serpent.hypnosis.phase == "ready_snap" then
        return 0
    end
    if serpent.hypnosis.snapReadyTime then
        local remaining = serpent.hypnosis.snapReadyTime - getEpoch()
        return remaining > 0 and remaining or 0
    end
    return -1
end

function serpent.hypnosis.status()
    cecho("\n<cyan>===== Hypnosis Status =====<reset>\n")
    cecho("<white>Phase: <yellow>" .. serpent.hypnosis.phase .. "<reset>\n")
    cecho("<white>Target: <yellow>" .. (serpent.hypnosis.hypnoTarget or "none") .. "<reset>\n")
    cecho("<white>Fratricide Queued: " ..
        (serpent.hypnosis.fratricideApplied and "<green>YES" or "<red>NO") .. "<reset>\n")
    cecho("<white>Fratricide Active: " ..
        (serpent.hypnosis.fratricideActive and "<green>YES" or "<red>NO") .. "<reset>\n")

    local timeToSnap = serpent.hypnosis.getTimeToSnap()
    if timeToSnap == 0 then
        cecho("<white>Snap: <green>READY!<reset>\n")
    elseif timeToSnap > 0 then
        cecho("<white>Snap Ready In: <yellow>" .. string.format("%.1f", timeToSnap) .. "s<reset>\n")
    else
        cecho("<white>Snap: <dim_grey>Not hypnotising<reset>\n")
    end

    if #serpent.hypnosis.suggestions > 0 then
        cecho("<white>Suggestions: <yellow>")
        for _, sug in ipairs(serpent.hypnosis.suggestions) do
            cecho(sug .. " ")
        end
        cecho("<reset>\n")
    end
    cecho("<cyan>===========================<reset>\n")
end

-- =============================================================================
-- HYPNO LOCK SUGGESTION SELECTION
-- =============================================================================

--[[
    Select up to 3 complex suggestions for hypno lock mode.
    Dynamic: picks based on what target doesn't have.
    Priority: clumsiness > nausea > hypersomnia > addiction > anorexia
]]--
function selectHypnoLockSuggestions()
    local pool = {"hypochondria", "disrupt", "generosity"}
    local suggestions = {}
    for _, aff in ipairs(pool) do
        if not haveAff(aff) then
            table.insert(suggestions, aff)
        end
    end
    if #suggestions == 0 then return pool end
    return suggestions
end

-- =============================================================================
-- EKANELIA DETECTION & IMPULSE PAIR SELECTION
-- =============================================================================

--[[
    Ekanelia transformation table.
    Each entry: trigger venom, conditional afflictions, result afflictions,
    and which conditionals are trivial suggestions (impulse-deliverable).
]]--
local EKANELIA_TABLE = {
    {
        trigger = "monkshood",
        conditionals = {"asthma", "masochism", "weariness"},
        trivials = {"masochism"},
        result = "impatience",
        priority = 1, -- truelock piece
    },
    {
        trigger = "kalmia",
        conditionals = {"clumsiness", "weariness"},
        trivials = {},
        result = "slickness",
        priority = 2, -- softlock piece
    },
    {
        trigger = "loki",
        conditionals = {"confusion", "recklessness"},
        trivials = {"confusion", "recklessness"},
        result = "nausea + paralysis",
        priority = 3, -- double aff, paralysis blocks tree
    },
    {
        trigger = "curare",
        conditionals = {"hypersomnia", "masochism"},
        trivials = {"masochism"},
        result = "hypochondria",
        priority = 4, -- lobelia pressure
    },
    {
        trigger = "scytherus",
        conditionals = {"addiction", "nausea"},
        trivials = {},
        result = "camus",
        priority = 5, -- damage pressure
    },
    {
        trigger = "aconite",
        conditionals = {"deadening", "dementia"},
        trivials = {"deadening", "dementia"},
        result = "paranoia",
        priority = 6, -- mental stack
    },
    {
        trigger = "voyria",
        conditionals = {"anorexia", "impatience", "vertigo"},
        trivials = {"vertigo"},
        result = "confusion + disrupted",
        priority = 7, -- needs monkshood chain first
    },
}

--[[
    Check for Ekanelia opportunities.
    Populates ekaneliaReady table with triggers that have ALL conditionals met.
]]--
function checkEkaneliaOpportunities()
    ekaneliaReady = {}

    for _, ek in ipairs(EKANELIA_TABLE) do
        local allMet = true
        for _, cond in ipairs(ek.conditionals) do
            if not haveAff(cond) then
                allMet = false
                break
            end
        end
        if allMet then
            ekaneliaReady[ek.trigger] = true
        end
    end
end

-- =============================================================================
-- IMPULSE SELECTION (Nil-safe, two-pass with fratricide window)
-- =============================================================================

local function now()
    return os.clock()
end

--[[
    Two-pass impulse selection:
      Pass 1: respect fratricide 3s cooldown per aff
      Pass 2: fallback ignoring cooldown (never returns nil)
    Optional excludeAff param for cases like curare ekanelia
    (don't re-impulse masochism when it's already the conditional).
]]--
local function selectImpulse(excludeAff)
    local hasFratricide = haveAff("fratricide")
        or (serpent.hypnosis and serpent.hypnosis.fratricideActive)

    -- Pass 1: respect fratricide cooldown
    for _, aff in ipairs(IMPULSE_PRIORITY) do
        if aff ~= excludeAff and not haveAff(aff) then
            if hasFratricide then
                local lastTime = lastImpulsed[aff] or 0
                if (now() - lastTime) >= 3.0 then
                    return aff
                end
            else
                return aff
            end
        end
    end

    -- Pass 2: fallback — ignore fratricide cooldown rather than returning nil
    for _, aff in ipairs(IMPULSE_PRIORITY) do
        if aff ~= excludeAff and not haveAff(aff) then
            return aff
        end
    end

    -- Last resort: always useful
    if excludeAff ~= "masochism" then return "masochism" end
    return "confusion"
end

-- Record impulse timestamp for fratricide window tracking.
-- Called on every impulse send so the window is tracked for ALL ekanelia paths.
local function recordImpulse(aff)
    if aff then lastImpulsed[aff] = now() end
end

-- =============================================================================
-- IMPATIENCE COOLDOWN
-- canAttemptImpatience() gates the send.
-- stampImpatienceCooldown() is called ONLY from the ekanelia confirm trigger.
-- =============================================================================

local function canAttemptImpatience()
    return (now() - lastImpatienceAttempt) >= 2.5
end

function stampImpatienceCooldown()
    lastImpatienceAttempt = now()
end

-- =============================================================================
-- KALMIA EKANELIA GUARD
-- Won't fire when asthma already present (primary effect wasted).
-- =============================================================================

local function kalmiaEkaneliaMet()
    return haveAff("clumsiness") and haveAff("weariness")
        and not haveAff("asthma")
        and checkImpulseEligible()
end

-- =============================================================================
-- IMPATIENCE CONDITIONS
-- Third-condition confidence gate: asthma + weariness + supporting mechanic.
-- =============================================================================

local function impatienceConditionsMet()
    if haveAff("impatience") then return false end
    if not haveAff("asthma") then return false end
    if not haveAff("weariness") then return false end
    return haveAff("fratricide")
        or (serpent.hypnosis and serpent.hypnosis.fratricideActive)
        or haveAff("hypochondria")
        or haveAff("scytherus")
        or haveAff("slickness")
        or (haveAff("anorexia") and tBals.focus == false)
end

-- Relaxed impatience check for relapse_lock: asthma+weariness is sufficient.
local function impatienceConditionsRelapse()
    if haveAff("impatience") then return false end
    if not haveAff("asthma") then return false end
    if not haveAff("weariness") then return false end
    return true
end

-- =============================================================================
-- canUseSecondary / getPostAction
-- Prevents snap/shrug from colliding with ekanelia delivery.
-- kalmia and impatience conditions override this -- they can't wait.
-- =============================================================================

local function getPostAction()
    local shouldSnap = hypSeal2 == true and snapped == false
    local shouldShrug = rTabSize(ataxia.afflictions) >= 3
        and canShrug == true
        and not ataxia.afflictions.weariness
        and not shouldSnap

    if shouldSnap then
        return "::snap " .. target, false
    elseif shouldShrug then
        return "::shrugging", false
    end
    return "", true
end

-- =============================================================================
-- MENTAL COUNT & FOCUS LOCK DETECTION
-- =============================================================================

local MENTAL_AFFS = {
    "confusion", "stupidity", "masochism", "recklessness",
    "vertigo", "epilepsy", "dementia", "deadening",
    "hallucinations", "paranoia", "loneliness", "hypochondria",
    "anorexia", "pacifism", "nausea", "addiction",
}

local function mentalCount()
    local count = 0
    for _, aff in ipairs(MENTAL_AFFS) do
        if haveAff(aff) then count = count + 1 end
    end
    return count
end

local function focusLockReady()
    return (haveAff("fratricide") or (serpent.hypnosis and serpent.hypnosis.fratricideActive))
        and mentalCount() >= 4
        and tBals.focus == false
        and haveAff("impatience")
        and haveAff("asthma")
        and haveAff("weariness")
end

-- =============================================================================
-- CLASS-AWARE CLUMSINESS
-- =============================================================================

local function wantClumsiness()
    return ataxia_wantClumsiness()
end

-- =============================================================================
-- CLASS-AWARE VENOM ROUTING (Track 4)
-- =============================================================================

--[[
    Pick the first-priority lock venom for the target's class.
    Returns a venom name (string) — call pickVenom(venom) as second venom.

    Per-class fastest-lock venom:
      - apostate         : voyria (sip blocker, hardest cure for apostate)
      - monk/shikudo     : vernalius (weariness blocks Fitness)
      - magi, sylvan     : notechis (haemophilia blocks blood/passive cures)
      - knight (any)     : xentio (clumsiness blocks parry+stance)
      - psion            : aconite (stupidity blocks weave queue)
      - alchemist        : aconite (stupidity blocks transmute)
      - depthswalker     : eurypteria (recklessness blocks shadow cures)
      - pariah           : voyria (sip-based plagues)
      - druid, sentinel  : kalmia (asthma blocks smoke + morph)
    Default: nil → fall back to pickVenom(nil) standard priority.

    Returns nil for unknown class -- callers should treat nil as "no override".
]]--
local CLASS_LOCK_VENOM = {
    apostate     = "voyria",
    pariah       = "voyria",
    monk         = "vernalius",
    shikudo      = "vernalius",
    tekura       = "vernalius",
    magi         = "notechis",
    sylvan       = "notechis",
    infernal     = "xentio",
    paladin      = "xentio",
    runewarden   = "xentio",
    unnamable    = "xentio",
    blademaster  = "xentio",
    psion        = "aconite",
    alchemist    = "aconite",
    depthswalker = "eurypteria",
    druid        = "kalmia",
    sentinel     = "kalmia",
}

local function getClassLockAff()
    -- Primary source: classDetect engine (active during PvP, written when
    -- attacker class is identified from class-specific attack messages).
    -- Fallback: tarClass global (legacy classDetect / manual set).
    local class = (classDetect and classDetect.state and classDetect.state.attackerClass)
        or tarClass
        or ""
    return CLASS_LOCK_VENOM[class:lower()]
end

-- =============================================================================
-- SLIKE (ANOREXIA) GATE
-- =============================================================================

local function slikeGateMet()
    if haveAff("anorexia") then return false end
    if haveAff("impatience") then return true end
    if tBals.focus == false and haveAff("asthma") then return true end
    return false
end

-- =============================================================================
-- LIGHTWALL CHECK
-- =============================================================================

local function hasLightwall()
    return haveAff("lightwall") or (tAffs and tAffs.lightwall)
end

-- =============================================================================
-- UNIFIED VENOM SELECTION (pickVenom / pickVenomRelapse)
-- =============================================================================

local function pickVenom(exclude)
    local hasWea = haveAff("weariness")
    local hasClu = haveAff("clumsiness")
    local hasAst = haveAff("asthma")

    if not haveAff("paralysis") and exclude ~= "curare" then return "curare" end

    -- Class-aware override (Track 4): once paralysis is locked, prefer the
    -- class-specific lock affliction that hits the target's weakest cure path.
    -- VENOM_TO_AFF lookup confirms the aff is missing before delivering.
    local classVenom = getClassLockAff()
    if classVenom and exclude ~= classVenom then
        local classAff = VENOM_TO_AFF[classVenom]
        if classAff and not haveAff(classAff) then
            return classVenom
        end
    end

    if wantClumsiness() then
        -- clumsiness > asthma > weariness
        if not hasClu and exclude ~= "xentio" then return "xentio" end
        if not hasAst and exclude ~= "kalmia" then return "kalmia" end
        if not hasWea and exclude ~= "vernalius" then return "vernalius" end
    else
        -- asthma > weariness (clumsiness is wasted on these classes)
        if not hasAst and exclude ~= "kalmia" then return "kalmia" end
        if not hasWea and exclude ~= "vernalius" then return "vernalius" end
    end

    if not haveAff("darkshade") and hasLightwall() and exclude ~= "darkshade" then return "darkshade" end
    if not haveAff("slickness") and hasAst and exclude ~= "gecko" then return "gecko" end
    if slikeGateMet() and exclude ~= "slike" then return "slike" end
    if exclude ~= "curare" then return "curare" end
    return "vernalius"
end

local function pickVenomGroup(exclude)
    -- 1. Paralysis first (blocks tree)
    if not haveAff("paralysis") and exclude ~= "curare" then return "curare" end
    -- 2. Asthma (blocks smoking, enables impulse)
    if not haveAff("asthma") and exclude ~= "kalmia" then return "kalmia" end
    -- 3. If asthma stuck -> slickness (blocks salves)
    if haveAff("asthma") and not haveAff("slickness") and exclude ~= "gecko" then return "gecko" end
    -- 4. Weariness (blocks fitness, enables impulse)
    if not haveAff("weariness") and exclude ~= "vernalius" then return "vernalius" end
    -- 5. Anorexia when impatience + slickness + asthma (blocks eating)
    if haveAff("impatience") and haveAff("slickness") and haveAff("asthma")
       and not haveAff("anorexia") and exclude ~= "slike" then return "slike" end
    -- 6. Fill remaining lock gaps
    if not haveAff("paralysis") and exclude ~= "curare" then return "curare" end
    if not haveAff("slickness") and exclude ~= "gecko" then return "gecko" end
    if not haveAff("weariness") and exclude ~= "vernalius" then return "vernalius" end
    if not haveAff("asthma") and exclude ~= "kalmia" then return "kalmia" end
    -- Default
    if exclude ~= "curare" then return "curare" end
    return "kalmia"
end

local function pickVenomRelapse(exclude)
    local hasWea = haveAff("weariness")
    local hasAst = haveAff("asthma")

    if not haveAff("paralysis") and exclude ~= "curare" then return "curare" end
    if not hasAst and exclude ~= "kalmia" then return "kalmia" end
    if not hasWea and exclude ~= "vernalius" then return "vernalius" end
    if not haveAff("slickness") and hasAst and exclude ~= "gecko" then return "gecko" end
    if not haveAff("anorexia") and exclude ~= "slike" then return "slike" end
    if exclude ~= "curare" then return "curare" end
    return "vernalius"
end

-- =============================================================================
-- IMPULSE PAIR SELECTION
-- =============================================================================

--[[
    Select the best impulse suggestion + venom pair for Ekanelia.
    Returns {suggestion=X, venom=Y} or nil if no Ekanelia achievable.

    Logic:
    1. If ALL conditionals met → return {suggestion=<useful>, venom=<trigger>}
    2. If exactly ONE trivial conditional missing → return {suggestion=<missing>, venom=<trigger>}
    3. Otherwise → nil
]]--
function selectImpulsePair()
    for _, ek in ipairs(EKANELIA_TABLE) do
        local missing = {}
        local missingTrivials = {}

        for _, cond in ipairs(ek.conditionals) do
            if not haveAff(cond) then
                table.insert(missing, cond)
                -- Check if this missing conditional is a trivial suggestion
                for _, t in ipairs(ek.trivials) do
                    if t == cond then
                        table.insert(missingTrivials, cond)
                        break
                    end
                end
            end
        end

        if #missing == 0 then
            -- ALL conditionals met → use nil-safe selectImpulse()
            -- instead of ek.trivials[1] which can be nil for venoms with
            -- no trivial conditionals (e.g. kalmia, scytherus)
            local suggestion = selectImpulse(nil)
            return {suggestion = suggestion, venom = ek.trigger, label = ek.result}
        elseif #missing == 1 and #missingTrivials == 1 then
            -- Exactly one trivial conditional missing → impulse completes it
            return {suggestion = missingTrivials[1], venom = ek.trigger, label = ek.result}
        end
    end

    return nil
end

--[[
    Select a useful fallback suggestion when Ekanelia is free (all conditions met).
    Prioritize suggestions that advance the lock or add pressure.
]]--
function selectFallbackSuggestion()
    -- Delegate to nil-safe selectImpulse()
    return selectImpulse(nil)
end

--[[
    Track 5: Opportunistic high-value ekanelias.
    Fires when conditionals are already met for an underused ekanelia and
    standard impatience delivery isn't available this round.

    Priority order:
      1. loki   — confusion + recklessness present, paralysis missing
                  → impulse <missing-trivial> loki → nausea + paralysis (2 lock pieces!)
      2. aconite — deadening + dementia present, stupidity missing
                  → impulse <something useful> aconite → stupidity + paranoia (mental stack)
      3. curare — hypersomnia + masochism present, paralysis missing
                  → impulse <something useful> curare → paralysis + hypochondria

    Returns {suggestion, venom, label} or nil.
]]--
function selectOpportunisticEkanelia()
    -- 1. Loki: confusion + recklessness → nausea + paralysis (highest value: 2 lock pieces)
    if haveAff("confusion") and haveAff("recklessness") and not haveAff("paralysis") then
        local sug = selectImpulse(nil)
        return {suggestion = sug, venom = "loki", label = "nausea + paralysis (loki)"}
    end

    -- 2. Aconite: deadening + dementia → stupidity + paranoia (mental stack pressure)
    if haveAff("deadening") and haveAff("dementia") and not haveAff("stupidity") then
        local sug = selectImpulse("stupidity")
        return {suggestion = sug, venom = "aconite", label = "stupidity + paranoia (aconite)"}
    end

    -- 3. Curare ekanelia: hypersomnia + masochism → paralysis + hypochondria
    -- (Only fire if paralysis missing — otherwise just use curare for raw paralysis via dstab)
    if haveAff("hypersomnia") and haveAff("masochism") and not haveAff("paralysis") then
        local sug = selectImpulse("masochism")
        return {suggestion = sug, venom = "curare", label = "paralysis + hypochondria (curare-ek)"}
    end

    return nil
end

--[[
    Select impulse pair during relapse phase.
    Priority: stupidity first (clogs focus, relapses) > monkshood re-lock (only after pre-load)
    Stupidity MUST go first -- it's mental (competes with masochism for focus)
    and relapses via fratricide, creating the window for monkshood re-lock.
    Monkshood only fires after slickness+anorexia are pre-loaded on target,
    so the lock is sealed when impatience lands.
    Returns {suggestion, venom, label} or nil.
]]--
function selectRelapseImpulse()
    -- Priority 1: Monkshood re-lock — if softlock present, deliver impatience NOW
    -- Anorexia blocks eating -> target can't goldenseal -> impatience sticks
    -- Don't waste the softlock window on stupidity when herbs are already blocked
    if haveAff("slickness") and haveAff("anorexia") then
        local monkshoodPair = selectImpulsePair()
        if monkshoodPair and monkshoodPair.label == "impatience" then
            return monkshoodPair
        end
    end

    -- Priority 2: Stupidity impulse (create focus pressure for when softlock isn't present)
    if not serpent.state.stupidityImpulseSent then
        local venom
        if not haveAff("paralysis") then
            venom = "curare"
        elseif not haveAff("weariness") then
            venom = "vernalius"
        elseif not haveAff("asthma") then
            venom = "kalmia"
        elseif not haveAff("slickness") then
            venom = "gecko"
        else
            venom = "curare"
        end
        return {suggestion = "stupidity", venom = venom, label = "stupidity+" .. (VENOM_TO_AFF[venom] or venom)}
    end

    -- No useful impulse — fall back to dstab (relapse_lock delivers gecko+slike)
    return nil
end

-- =============================================================================
-- BITE VENOM SELECTION (Track 2: bite payload expansion)
-- =============================================================================

--[[
    Pick the best venom to BITE this round.
    Bite is BAL only (cheaper than IMPULSE), works through fangbarrier when
    scytherus is stuck (camus relapse cycle), and stacks 1 affliction per round.

    Selection priority:
      1. scytherus aff stuck → bite scytherus (preserve camus damage loop)
      2. addiction+nausea present, scytherus not stuck → bite scytherus
         (delivers scytherus aff + camus damage via ekanelia)
      3. asthma+masochism+weariness present (monkshood ekanelia) → bite monkshood
         (delivers impatience for free — same payload as IMPULSE but no EQ cost)
      4. clumsiness+weariness present (kalmia ekanelia) → bite kalmia
         (asthma + slickness via ekanelia)
      5. hypersomnia+masochism present (curare ekanelia) → bite curare
         (paralysis + hypochondria)
      6. confusion+recklessness present (loki ekanelia) → bite loki
         (nausea + paralysis)
      7. Fallback: paralysis missing → bite curare; asthma missing → bite kalmia;
         weariness missing → bite vernalius

    Returns {venom = "X", label = "Y"} or nil if no useful bite.
]]--
function selectBiteVenom()
    if not checkImpulseEligible() then return nil end  -- sileris/fangbarrier blocks bite

    -- 1. Scytherus stuck — keep biting for camus relapse damage
    if haveAff("scytherus") then
        return {venom = "scytherus", label = "camus damage"}
    end

    -- 2. Scytherus ekanelia ready (addiction + nausea)
    if haveAff("addiction") and haveAff("nausea") then
        return {venom = "scytherus", label = "deliver scytherus + camus"}
    end

    -- 3. Monkshood ekanelia ready → free impatience via bite (no EQ cost)
    if haveAff("asthma") and haveAff("masochism") and haveAff("weariness") then
        return {venom = "monkshood", label = "impatience (ekanelia)"}
    end

    -- 4. Kalmia ekanelia ready → asthma + slickness
    if haveAff("clumsiness") and haveAff("weariness") and not haveAff("asthma") then
        return {venom = "kalmia", label = "asthma + slickness (ekanelia)"}
    end

    -- 5. Curare ekanelia ready → paralysis + hypochondria
    if haveAff("hypersomnia") and haveAff("masochism") and not haveAff("paralysis") then
        return {venom = "curare", label = "paralysis + hypochondria (ekanelia)"}
    end

    -- 6. Loki ekanelia ready → nausea + paralysis
    if haveAff("confusion") and haveAff("recklessness") and not haveAff("paralysis") then
        return {venom = "loki", label = "nausea + paralysis (ekanelia)"}
    end

    -- 7. Aconite ekanelia ready → stupidity + paranoia (deadening + dementia present)
    if haveAff("deadening") and haveAff("dementia") and not haveAff("stupidity") then
        return {venom = "aconite", label = "stupidity + paranoia (ekanelia)"}
    end

    -- 8. Fallback single-aff bites for missing lock pieces
    if not haveAff("paralysis") then return {venom = "curare", label = "paralysis"} end
    if not haveAff("asthma")     then return {venom = "kalmia",  label = "asthma"} end
    if not haveAff("weariness")  then return {venom = "vernalius", label = "weariness"} end

    return nil
end

-- =============================================================================
-- IMPULSE ELIGIBILITY
-- =============================================================================

--[[
    Check if impulse can be used this round.
    Requires: no sileris/fangbarrier on target (bite must land).
    Does NOT check eq availability or Ekanelia — those are checked separately.
]]--
function checkImpulseEligible()
    local hasSileris = haveAff("sileris") or (tAffs and tAffs.sileris)
    local hasFangbarrier = haveAff("fangbarrier") or (tAffs and tAffs.fangbarrier)

    -- If sileris/fangbarrier is back up (quicksilver reapply), reset the strip flag.
    -- geckoStripAttempted is only valid for one round — the moment the target
    -- reapplies quicksilver it's no longer safe to assume bite will land.
    if (hasSileris or hasFangbarrier) and serpent.state.geckoStripAttempted then
        serpent.state.geckoStripAttempted = false
        serpent.state.postGeckoLockdown = false
    end

    impulseReady = not hasSileris and not hasFangbarrier
    return impulseReady
end

-- =============================================================================
-- DARKSHADE TRACKING
-- =============================================================================

function checkDarkshadeTimer()
    if haveAff("darkshade") and affTimers.darkshade then
        local darkshadeStuckTime = getEpoch() - affTimers.darkshade
        if darkshadeStuckTime >= DARKSHADE_KILL_TIME then
            Algedonic.Echo("<magenta>DARKSHADE KILL!<white> " .. math.floor(darkshadeStuckTime) .. "s stuck - target should be dead!")
            return true
        end
        return darkshadeStuckTime
    end
    return 0
end

-- =============================================================================
-- FOCUS TIMING & ADAPTIVE GATES
-- =============================================================================

--[[
    Get remaining focus cooldown in seconds.
    Returns 0 if focus is available, >0 if on cooldown.
    Uses epoch timestamp set by focus triggers (398/399).
]]--
function serpent.getFocusCooldownRemaining()
    if tBals.focus then return 0 end
    if not tBals.focusUsedAt then return 0 end
    local cd = haveAff("shadowmadness") and 5 or 2
    return math.max(0, cd - (getEpoch() - tBals.focusUsedAt))
end

--[[
    Check if anorexia can stick on target.
    Anorexia is cured by epidermal (salve) AND focus.
    Both cure routes must be blocked:
    - Slickness blocks epidermal (on target OR gecko delivering it this round)
    - Impatience blocks focus (or focus on cooldown > 1.8s)
]]--
-- serpent.canDeliverAnorexia, serpent.checkBloodrootExploit, serpent.shouldDeliverImpatience
-- REMOVED: replaced by slikeGateMet(), impatienceConditionsMet(), canAttemptImpatience()

-- =============================================================================
-- STACK COUNTING
-- =============================================================================

function countGinsengStack()
    local count = 0
    local ginsengAffs = {"addiction", "darkshade", "haemophilia", "lethargy", "scytherus", "nausea"}
    for _, aff in ipairs(ginsengAffs) do
        if tAffs[aff] then count = count + 1 end
    end
    return count
end

function countKelpStack()
    local count = 0
    local kelpAffs = {"asthma", "clumsiness", "sensitivity", "weariness", "healthleech", "parasite"}
    for _, aff in ipairs(kelpAffs) do
        if tAffs[aff] then count = count + 1 end
    end
    return count
end

function countBloodrootStack()
    local count = 0
    if tAffs.paralysis then count = count + 1 end
    if tAffs.slickness then count = count + 1 end
    return count
end

-- =============================================================================
-- ADAPTIVE STRATEGY SYSTEM (Lock-First)
-- =============================================================================

serpent.cureTracking = serpent.cureTracking or {
    kelpCures = 0,
    ginsengCures = 0,
    bloodrootCures = 0,
    focusCures = 0,
    lastReset = 0,
    trackingWindow = 6,
}

function serpent.trackCure(herbType)
    local now = getEpoch()

    if now - serpent.cureTracking.lastReset > serpent.cureTracking.trackingWindow then
        serpent.cureTracking.kelpCures = 0
        serpent.cureTracking.ginsengCures = 0
        serpent.cureTracking.bloodrootCures = 0
        serpent.cureTracking.focusCures = 0
        serpent.cureTracking.lastReset = now
    end

    if herbType == "kelp" then
        serpent.cureTracking.kelpCures = serpent.cureTracking.kelpCures + 1
    elseif herbType == "ginseng" then
        -- Only count if target has a kelp aff -- proves they're prioritizing ginseng over kelp
        if countKelpStack() > 0 then
            serpent.cureTracking.ginsengCures = serpent.cureTracking.ginsengCures + 1
        end
    elseif herbType == "bloodroot" then
        serpent.cureTracking.bloodrootCures = serpent.cureTracking.bloodrootCures + 1
    elseif herbType == "focus" then
        serpent.cureTracking.focusCures = serpent.cureTracking.focusCures + 1
    end
end

--[[
    Determine strategy using LOCK-FIRST logic.
    The goal is always lock completion. Ekanelia is a mechanism to get lock pieces.
]]--
function determineStrategy()
    -- ===== FINISHING MOVES =====
    if truelock then
        serpStrategy = "finish"
        return
    end

    -- ===== DARKSHADE FORK: Apply darkshade if not on target (darkshade mode only) =====
    -- Non-darkshade modes: darkshade auto-inserted as second venom when lightwall detected
    if serpOffenseMode == "darkshade" and not haveAff("darkshade") then
        serpStrategy = "apply_darkshade"
        return
    end

    -- ===== CAN WE COMPLETE TRUELOCK? =====
    -- Need: paralysis + asthma + anorexia + slickness + impatience
    if hardlock then
        -- Hardlock means: asthma + anorexia + slickness + impatience (missing paralysis)
        if not haveAff("paralysis") then
            serpStrategy = "complete_truelock"
            return
        end
    end

    -- Close to truelock: have most lock pieces, missing 1-2
    local lockPieces = 0
    if haveAff("paralysis") then lockPieces = lockPieces + 1 end
    if haveAff("asthma") then lockPieces = lockPieces + 1 end
    if haveAff("anorexia") then lockPieces = lockPieces + 1 end
    if haveAff("slickness") then lockPieces = lockPieces + 1 end
    if haveAff("impatience") then lockPieces = lockPieces + 1 end

    if lockPieces >= 4 then
        serpStrategy = "complete_truelock"
        return
    end

    -- ===== CAN WE COMPLETE HARDLOCK? =====
    -- Need: asthma + anorexia + slickness + (paralysis or impatience)
    if softlock then
        serpStrategy = "complete_hardlock"
        return
    end

    -- ===== CAN WE COMPLETE SOFTLOCK? =====
    -- Need: asthma + anorexia + slickness
    if haveAff("asthma") then
      local softPieces = 1
      if haveAff("anorexia") then softPieces = softPieces + 1 end
      if haveAff("slickness") then softPieces = softPieces + 1 end

      if softPieces >= 2 then
          serpStrategy = "complete_softlock"
          return
      end
    end

    -- ===== HYPNOSIS IN PROGRESS =====
    if serpent.hypnosis.phase == "ready_snap" then
        serpStrategy = "hypnosis"
        return
    end

    if serpent.hypnosis.isActive() then
        serpStrategy = "hypnosis"
        return
    end

    -- ===== POST-SNAP: Skip hindering, go straight for lock pieces =====
    if tAffs.snapped or (serpent.hypnosis.snapTimerFired and serpent.hypnosis.phase == "cooldown") then
        serpStrategy = "post_snap"
        return
    end

    -- ===== CURE ADAPTATION: Darkshade is on, react to cure patterns =====
    -- If target is eating ginseng, stack ginseng to 3 first so they're busy curing it.
    -- If target eats anything else, darkshade stays on — just push lock.
    local ct = serpent.cureTracking
    if ct.ginsengCures > 2 and countGinsengStack() < 3 then
        -- Target eating ginseng + stack not deep enough yet
        if serpent.config.debug then
            Algedonic.Echo("<cyan>ADAPTIVE: <white>Target eating ginseng -- stacking (" .. countGinsengStack() .. "/3)")
        end
        serpStrategy = "ginseng_pressure"
        return
    end

    -- Default: push lock (darkshade is on, lock them)
    serpStrategy = "setup_lock"
end

function serpent.assessCombatState()
    local dominated = 0

    if truelock then dominated = dominated + 100 end
    if hardlock then dominated = dominated + 50 end
    if softlock then dominated = dominated + 25 end

    if haveAff("asthma") then dominated = dominated + 10 end
    if haveAff("weariness") then dominated = dominated + 10 end
    if haveAff("slickness") then dominated = dominated + 15 end
    if haveAff("paralysis") then dominated = dominated + 20 end
    if haveAff("impatience") then dominated = dominated + 25 end
    if haveAff("anorexia") then dominated = dominated + 20 end

    if tAffs.fratricide or serpent.hypnosis.fratricideActive then
        dominated = dominated + 20
    end

    if haveAff("darkshade") then
        local stuckTime = 0
        if affTimers and affTimers.darkshade then
            stuckTime = getEpoch() - affTimers.darkshade
        end
        dominated = dominated + math.min(stuckTime, 26)
    end

    return dominated
end

-- =============================================================================
-- VENOM SELECTION (Ekanelia-Aware, Lock-First)
-- =============================================================================

--[[
    Select venoms based on current strategy.
    DSTAB venoms are chosen to:
    1. Complete lock pieces directly
    2. Set up Ekanelia conditionals for future impulse rounds
]]--
function selectVenoms()
    envenomList = {}
    envenomListTwo = {}
    attackMode = "dstab"

    -- ===== POST-GECKO LOCKDOWN: Close the lock after gecko strip =====
    -- After gecko+curare dstab + impulse monkshood, if impatience landed,
    -- slam curare+slike to deliver paralysis+anorexia and seal the lock.
    -- One-shot: only fires the round immediately after gecko strip.
    if serpent.state.postGeckoLockdown then
        serpent.state.postGeckoLockdown = false
        if haveAff("impatience") and not haveAff("anorexia") then
            table.insert(envenomList, "curare")
            table.insert(envenomListTwo, "slike")
            return
        end
    end

    -- ===== FINISH: Truelock achieved =====
    if serpStrategy == "finish" then
        local lockAff = getLockingAffliction(target)
        if lockAff == "weariness" and not haveAff("weariness") then
            table.insert(envenomList, "vernalius")
        elseif lockAff == "paralyse" and not haveAff("paralysis") then
            table.insert(envenomList, "curare")
        else
            table.insert(envenomList, "voyria")
        end
        local v1 = envenomList[1]
        table.insert(envenomListTwo, pickVenom(v1))
        return
    end

    -- ===== COMPLETE TRUELOCK: Missing 1-2 pieces =====
    if serpStrategy == "complete_truelock" then
        local v1
        if not haveAff("paralysis") then
            v1 = "curare"
        elseif not haveAff("impatience") then
            if not haveAff("asthma") then v1 = "kalmia"
            elseif not haveAff("weariness") then v1 = "vernalius"
            else v1 = pickVenom(nil) end
        elseif not haveAff("slickness") and haveAff("asthma") then
            v1 = "gecko"
        elseif not haveAff("anorexia") and haveAff("impatience") then
            v1 = "slike"
        else
            v1 = pickVenom(nil)
        end
        table.insert(envenomList, v1)
        table.insert(envenomListTwo, pickVenom(v1))
        return
    end

    -- ===== COMPLETE HARDLOCK: Softlock + need paralysis/impatience =====
    if serpStrategy == "complete_hardlock" then
        local v1
        if not haveAff("paralysis") then
            v1 = "curare"
        elseif not haveAff("impatience") then
            if not haveAff("asthma") then v1 = "kalmia"
            elseif not haveAff("weariness") then v1 = "vernalius"
            else v1 = pickVenom(nil) end
        else
            v1 = pickVenom(nil)
        end
        table.insert(envenomList, v1)
        table.insert(envenomListTwo, pickVenom(v1))
        return
    end

    -- ===== COMPLETE SOFTLOCK: asthma present, need slickness+anorexia =====
    if serpStrategy == "complete_softlock" then
        local v1
        if not haveAff("slickness") then
            if haveAff("clumsiness") and haveAff("weariness") then
                v1 = pickVenom(nil)  -- impulse handles kalmia, dstab something useful
            elseif not haveAff("weariness") then
                v1 = "vernalius"
            else
                v1 = "gecko"
            end
        elseif slikeGateMet() then
            v1 = "slike"
        elseif not haveAff("paralysis") then
            v1 = "curare"
        elseif not haveAff("weariness") then
            v1 = "vernalius"
        else
            v1 = pickVenom(nil)
        end
        table.insert(envenomList, v1)
        table.insert(envenomListTwo, pickVenom(v1))
        return
    end

    -- ===== HYPNOSIS: Maintain pressure while hypnosis completes =====
    if serpStrategy == "hypnosis" then
        local v1 = pickVenom(nil)
        table.insert(envenomList, v1)
        table.insert(envenomListTwo, pickVenom(v1))
        return
    end

    -- ===== HYPNO LOCK: Lock venoms while hypnosis handles EQ =====
    if serpStrategy == "hypnolock" then
        local suggesting = {}
        for _, s in ipairs(serpent.hypnosis.targetSuggestions or {}) do
            suggesting[s] = true
        end
        local v1 = pickVenom(nil)
        -- Skip venoms that hypnosis will deliver
        if suggesting[VENOM_TO_AFF[v1] or ""] then v1 = pickVenom(v1) end
        table.insert(envenomList, v1)
        table.insert(envenomListTwo, pickVenom(v1))
        return
    end

    -- ===== RELAPSE LOCK: Coordinate venoms with fratricide relapses =====
    if serpStrategy == "relapse_lock" then
        -- Pre-load slickness+anorexia only when asthma+weariness stacked
        local readyForPreload = haveAff("asthma") and haveAff("weariness")
        if readyForPreload and not haveAff("slickness") and not haveAff("anorexia") then
            table.insert(envenomList, "gecko")
            table.insert(envenomListTwo, "slike")
            return
        end
        local v1 = pickVenomRelapse(nil)
        table.insert(envenomList, v1)
        table.insert(envenomListTwo, pickVenomRelapse(v1))
        return
    end

    -- ===== LOCK REINFORCE / BURST FINISH =====
    -- Post-truelock sequence:
    --   1. Paralysis always (they can't cure while paralysed)
    --   2. Voyria reinforcement (confusion+disrupted deepens lock)
    --   3. Scytherus setup: vardrax+euphorbia (addiction+nausea -> camus)
    --   4. Scytherus delivery: impulse fires via attack execution
    --   5. Maintain pressure with curare+recklessness
    if serpStrategy == "lock_reinforce" then
        -- Priority 1: paralysis always
        if not haveAff("paralysis") then
            table.insert(envenomList, "curare")
            -- Second venom: class-specific lock aff or voyria to seal
            local v2
            local classLockAff = getLockingAffliction and getLockingAffliction("name")
            local classLockVenom = classLockAff and AFF_TO_VENOM[classLockAff]
            if classLockVenom and not haveAff(classLockAff) then
                v2 = classLockVenom
            elseif not haveAff("voyria") then
                v2 = "voyria"
            else
                v2 = "curare"
            end
            table.insert(envenomListTwo, v2)
            return
        end
        -- Priority 2: voyria reinforcement
        if not haveAff("voyria") then
            table.insert(envenomList, "voyria")
            if not haveAff("recklessness") then
                table.insert(envenomListTwo, "eurypteria")
            else
                table.insert(envenomListTwo, "curare")
            end
            return
        end
        -- Priority 3: scytherus burst setup — addiction+nausea -> camus damage
        if not haveAff("addiction") then
            table.insert(envenomList, "vardrax")
            table.insert(envenomListTwo, not haveAff("nausea") and "euphorbia" or "curare")
            return
        end
        if not haveAff("nausea") then
            table.insert(envenomList, "euphorbia")
            table.insert(envenomListTwo, "curare")
            return
        end
        -- Priority 4: addiction+nausea present — scytherus impulse fires via attack execution
        table.insert(envenomList, "curare")
        table.insert(envenomListTwo, not haveAff("recklessness") and "eurypteria" or "vardrax")
        return
    end

    -- ===== APPLY DARKSHADE =====
    if serpStrategy == "apply_darkshade" then
        table.insert(envenomList, "darkshade")
        local v2 = (serpOffenseMode == "darkshade" and not haveAff("paralysis"))
            and "curare"
            or pickVenom("darkshade")
        table.insert(envenomListTwo, v2)
        return
    end

    -- ===== GINSENG PRESSURE =====
    if serpStrategy == "ginseng_pressure" then
        local ginsengOrder = {"vardrax", "euphorbia", "notechis", "scytherus", "darkshade"}
        local v1 = "curare"
        for _, v in ipairs(ginsengOrder) do
            if not haveAff(VENOM_TO_AFF[v] or v) then
                v1 = v
                break
            end
        end
        table.insert(envenomList, v1)
        local v2
        if serpOffenseMode == "darkshade" and not haveAff("paralysis") and v1 ~= "curare" then
            v2 = "curare"
        else
            v2 = "curare"
            for _, v in ipairs(ginsengOrder) do
                if v ~= v1 and not haveAff(VENOM_TO_AFF[v] or v) then
                    v2 = v
                    break
                end
            end
        end
        table.insert(envenomListTwo, v2)
        return
    end

    -- ===== BUILD SCYTHERUS =====
    if serpStrategy == "build_scytherus" then
        local v1 = not haveAff("addiction") and "vardrax"
               or  not haveAff("nausea")    and "euphorbia"
               or  "curare"
        table.insert(envenomList, v1)
        local v2
        if v1 ~= "euphorbia" and not haveAff("nausea") then
            v2 = "euphorbia"
        elseif v1 ~= "vardrax" and not haveAff("addiction") then
            v2 = "vardrax"
        else
            v2 = pickVenom(v1)
        end
        table.insert(envenomListTwo, v2)
        return
    end

    -- ===== SCYTHERUS ATTACK =====
    if serpStrategy == "scytherus_attack" then
        local v1
        if not haveAff("slickness") and haveAff("asthma") then
            v1 = "gecko"
        else
            v1 = pickVenom(nil)
        end
        table.insert(envenomList, v1)
        table.insert(envenomListTwo, pickVenom(v1))
        return
    end

    -- ===== GROUP =====
    if serpStrategy == "group" then
        local v1 = pickVenomGroup(nil)
        table.insert(envenomList, v1)
        table.insert(envenomListTwo, pickVenomGroup(v1))
        return
    end

    -- ===== POST-SNAP =====
    if serpStrategy == "post_snap" then
        local v1 = pickVenom(nil)
        table.insert(envenomList, v1)
        table.insert(envenomListTwo, pickVenom(v1))
        return
    end

    -- ===== DEFAULT: setup_lock =====
    local v1 = pickVenom(nil)
    table.insert(envenomList, v1)
    local v2 = pickVenom(v1)
    table.insert(envenomListTwo, v2)
end

--[[
    Build second venom for doublestab (must differ from first).
    Default: curare (paralysis blocks tree — strongest escape mechanism).
    If paralysis stuck: fill with missing lock pieces ordered by priority.
    Lightwall auto-insertion: darkshade as second venom when lightwall detected (non-darkshade mode).
]]--
-- buildSecondVenom, buildSecondVenomGinseng, buildSecondVenomRelapse
-- REMOVED: replaced by unified pickVenom(exclude) and pickVenomRelapse(exclude)

-- =============================================================================
-- ATTACK EXECUTION
-- =============================================================================

--[[
    Execute the attack based on current strategy and venom selection.

    Priority order:
    1. Flay (strip shield/rebounding) — with kalmia ekanelia impulse on eq
    2. Behead (truelock + prone) or execute (finish strategy)
    3. Kalmia ekanelia impulse (asthma not present, clumsy+weary met)
    4. Impatience delivery (canAttemptImpatience + conditions gate)
    5. Focus lock push (fratricide + 4 mentals + focus down)
    6. Bite (scytherus mode, scytherus aff stuck)
    7. Impulse cases (lock_reinforce burst, relapse, darkshade, scytherus, normal)
    8. Gecko strip (sileris blocking impulse)
    9. DSTAB with postAction if canUseSecondary
]]--
function serp_ekanelia_attack()
    if not target or target == "" then
        Algedonic.Echo("<red>No target set!<white>")
        return
    end

    local sp = ataxia.settings.separator
    local preAtk = combatQueue()

    -- Shield/rebounding detection: haveAff, tAffs, AND Ataxia globals (most reliable)
    local hasRebounding = haveAff("rebounding") or (tAffs and tAffs.rebounding) or Rebounding
    local hasShield = haveAff("shield") or (tAffs and tAffs.shield) or Shielded

    -- Rebounding-reapply prediction: when the target's rebounding drops (present->absent
    -- between ticks), stamp the clock so the PRIORITY 1.5 block below can pre-empt the
    -- ~8.5s reapply. Stamped here every tick; fired once when the reapply window opens.
    if serpent.state.lastRebounding and not hasRebounding then
        lastReboundingFlay = now()
    end
    serpent.state.lastRebounding = hasRebounding

    -- Weapon wielding prefixes (single command, game assigns hands)
    local wieldWhip = "wield shield whip" .. sp
    local wieldDirk = "wield shield dirk" .. sp

    -- canUseSecondary: prevents snap/shrug from colliding with ekanelia delivery.
    -- Kalmia and impatience conditions override this gate (they consume eq themselves).
    local postAction, canUseSecondary = getPostAction()
    if impatienceConditionsMet() or impatienceConditionsRelapse() or kalmiaEkaneliaMet() then
        canUseSecondary = true
    end

    -- --------------------------------------------------------
    -- PRIORITY 1: Flay shield or rebounding
    -- --------------------------------------------------------
    if hasRebounding or hasShield then
        local defense = hasShield and "shield" or "rebounding"
        -- Flay delivers one venom — pick the highest-value single venom.
        -- Kalmia ekanelia window (clumsy+weariness → asthma+slickness) takes priority
        -- over raw paralysis if bite is available, since we get two affs from one impulse.
        local flayVenom = envenomList[1] or "curare"
        -- gecko (slickness) is wasted without asthma — target smokes valerian instantly
        if flayVenom == "gecko" and not haveAff("asthma") then
            flayVenom = "curare"
        end
        if kalmiaEkaneliaMet() then
            -- Ekanelia fires via impulse this round — flay just needs any useful venom
            flayVenom = not haveAff("paralysis") and "curare" or "vernalius"
        elseif not haveAff("paralysis") then
            flayVenom = "curare"
        elseif not haveAff("weariness") then
            flayVenom = "vernalius"
        elseif not haveAff("clumsiness") then
            flayVenom = "xentio"
        elseif not haveAff("asthma") then
            -- Only direct-dstab kalmia when ekanelia conditionals aren't both present
            flayVenom = "kalmia"
        elseif not haveAff("slickness") and haveAff("asthma") then
            flayVenom = "gecko"
        end
        envenomList = {flayVenom}
        envenomListTwo = {}

        local eqAction = getEqAction()
        local cmd

        -- If kalmia ekanelia is ready, chain impulse on eq alongside flay on bal.
        -- Flay uses lash (bal), impulse uses dirk (eq) -- they don't share a balance type.
        --
        -- Shield-break pressure (Track 3.3): when target shields, prefer chaining
        -- monkshood impulse to keep impatience landing — impatience forces touch-shield
        -- failures, which is the fastest way through a shield wall.
        local impulsePriority = nil  -- {sug, venom, label}
        if kalmiaEkaneliaMet() then
            impulsePriority = {sug = selectImpulse(nil), venom = "kalmia", label = "asthma+slickness"}
        elseif hasShield and impatienceConditionsMet() and canAttemptImpatience() then
            -- Shield-break: monkshood ekanelia for impatience (forces shield touch-fail)
            local sug = haveAff("masochism") and selectImpulse("masochism") or "masochism"
            impulsePriority = {sug = sug, venom = "monkshood", label = "impatience (shield-break)"}
        end

        if impulsePriority and not eqAction then
            recordImpulse(impulsePriority.sug)
            cmd = wieldWhip .. "flay " .. target .. " " .. defense .. " " .. flayVenom
                .. sp .. wieldDirk .. "impulse " .. target .. " " .. impulsePriority.sug .. " " .. impulsePriority.venom
        elseif eqAction and canUseSecondary then
            if eqAction:find("^snap") or eqAction:find("^shrugging") then
                cmd = wieldWhip .. "flay " .. target .. " " .. defense .. " " .. flayVenom .. sp .. eqAction
            else
                cmd = wieldWhip .. eqAction .. sp .. "flay " .. target .. " " .. defense .. " " .. flayVenom
            end
        else
            cmd = wieldWhip .. "flay " .. target .. " " .. defense .. " " .. flayVenom
        end

        serp_sendAttack(preAtk .. cmd)
        return
    end

    -- NOTE: Sileris/fangbarrier does NOT need flaying — dstab works through it.
    -- Only impulse/bite is blocked. checkImpulseEligible() handles this.

    -- --------------------------------------------------------
    -- PRIORITY 2: Behead (prone) or execute (finish strategy only)
    -- During lock_reinforce we run the burst finish sequence, not execute.
    -- --------------------------------------------------------
    if truelock then
        if haveAff("prone") then
            -- Prone: behead immediately regardless of strategy
            serp_sendAttack(preAtk .. "wield shield scimitar" .. sp .. "behead " .. target)
            return
        elseif serpStrategy == "finish"
            and (not getStateProbabilityV3
                or getStateProbabilityV3({"anorexia", "asthma", "slickness", "impatience", "paralysis"}) >= 0.90) then
            -- Joint-probability gate: only commit the irreversible execute when all
            -- five lock affs are >=90% likely to be present together in one tracker
            -- branch. If truelock is per-aff true but jointly shaky, fall through to
            -- the lock_reinforce burst instead of gambling the kill on a bluff.
            serp_sendAttack(preAtk .. "execute " .. target)
            return
        end
        -- Otherwise fall through to lock_reinforce burst finish sequence
    end

    -- --------------------------------------------------------
    -- PRIORITY 1.5: Rebounding-reapply pre-empt. Rebounding returns ~8.5s after it
    -- was stripped; fire one impulse+bite through the gap just before it reapplies,
    -- instead of eating a reflected hit next round. Reaching here guarantees no
    -- shield/rebounding is up (the flay block above returns first). Placed AFTER the
    -- finisher so a ready kill always wins. Fires once per drop (disarms the timer).
    -- --------------------------------------------------------
    if lastReboundingFlay > 0
        and (now() - lastReboundingFlay) >= 8.15
        and checkImpulseEligible() then
        local impAff = selectImpulse(nil) or "masochism"
        local bite = selectBiteVenom()
        local biteVenom = (bite and bite.venom) or pickVenom(nil)
        recordImpulse(impAff)
        lastReboundingFlay = 0  -- fire once per reapply cycle
        serp_sendAttack(preAtk .. wieldDirk .. "impulse " .. target .. " " .. impAff .. " " .. biteVenom)
        return
    end

    local eqAction = getEqAction()

    -- --------------------------------------------------------
    -- PRIORITY 3: Kalmia ekanelia — override canUseSecondary, guarded
    -- by kalmiaEkaneliaMet() which checks asthma not already present.
    -- recordImpulse() called on every kalmia impulse send.
    -- --------------------------------------------------------
    if kalmiaEkaneliaMet() and canUseSecondary and not eqAction then
        local impulseAff = selectImpulse(nil)
        recordImpulse(impulseAff)
        serp_sendAttack(preAtk .. wieldDirk ..
            "impulse " .. target .. " " .. impulseAff .. " kalmia")
        return
    end

    -- --------------------------------------------------------
    -- PRIORITY 4: Impatience delivery — canAttemptImpatience() gates send.
    -- stampImpatienceCooldown() called from ekanelia confirm trigger, not here.
    -- canUseSecondary overridden by impatienceConditionsMet().
    -- --------------------------------------------------------
    -- During relapse_lock, use the relaxed condition check (asthma+weariness sufficient).
    -- Normal lock mode keeps the third-condition gate (fratricide/hypochondria/scytherus/slickness).
    local impatienceReady = (serpStrategy == "relapse_lock")
        and impatienceConditionsRelapse()
        or impatienceConditionsMet()
    if impatienceReady and canAttemptImpatience() and canUseSecondary and not eqAction then
        local impulseAff
        if haveAff("masochism") then
            impulseAff = selectImpulse("masochism")
        else
            impulseAff = "masochism"
        end
        recordImpulse(impulseAff)
        serp_sendAttack(preAtk .. wieldDirk ..
            "impulse " .. target .. " " .. impulseAff .. " monkshood")
        return
    end

    -- --------------------------------------------------------
    -- PRIORITY 5: Focus lock push (fratricide + 4 mentals + focus bal down)
    -- --------------------------------------------------------
    if focusLockReady() and canUseSecondary and not eqAction then
        local impulseAff = selectImpulse(nil)
        recordImpulse(impulseAff)
        serp_sendAttack(preAtk .. wieldDirk ..
            "impulse " .. target .. " " .. impulseAff .. " monkshood")
        return
    end

    -- --------------------------------------------------------
    -- PRIORITY 6: Bite
    --   - scytherus mode: bite scytherus when aff stuck (camus damage loop)
    --   - bitepayload mode: use selectBiteVenom() for multi-venom payload
    -- --------------------------------------------------------
    local useBite = false
    local biteVenom = nil
    local biteLabel = nil
    if serpOffenseMode == "scytherus" and serpStrategy == "scytherus_attack"
       and checkImpulseEligible() and haveAff("scytherus") then
        useBite = true
        biteVenom = "scytherus"
        biteLabel = "camus"
    elseif serpOffenseMode == "bitepayload" and not eqAction then
        local pick = selectBiteVenom()
        if pick then
            useBite = true
            biteVenom = pick.venom
            biteLabel = pick.label
        end
    end

    -- --------------------------------------------------------
    -- PRIORITY 7: Impulse eligibility (with per-aff cooldown + nil-safe)
    -- --------------------------------------------------------
    local useImpulse = false
    local impulsePair = nil

    -- lock_reinforce burst finish: impulse priority order
    --   1. Scytherus ekanelia (addiction+nausea present) — camus damage burst
    --   2. Voyria (anorexia+impatience present, vertigo missing) — confusion+disrupted
    --   3. Normal impatience if somehow not yet landed
    if serpStrategy == "lock_reinforce" and not eqAction and checkImpulseEligible() then
        if haveAff("addiction") and haveAff("nausea") and not haveAff("scytherus") then
            -- Scytherus ekanelia: camus damage spike
            impulsePair = {suggestion = selectImpulse(nil), venom = "scytherus", label = "camus"}
            useImpulse = true
        elseif haveAff("anorexia") and haveAff("impatience") then
            -- Voyria ekanelia: confusion+disrupted deepens lock
            if not haveAff("vertigo") then
                impulsePair = {suggestion = "vertigo", venom = "voyria", label = "confusion + disrupted"}
            else
                impulsePair = {suggestion = selectImpulse(nil), venom = "voyria", label = "confusion + disrupted"}
            end
            useImpulse = true
            serpent.state.voyriaSent = true
        end

    -- Relapse phase impulse (stupidity+venom or monkshood re-lock)
    elseif serpStrategy == "relapse_lock"
       and (serpOffenseMode == "lock" or serpOffenseMode == "darkshade")
       and not eqAction and checkImpulseEligible() then
        impulsePair = selectRelapseImpulse()
        if impulsePair then
            useImpulse = true
            if impulsePair.suggestion == "stupidity" then
                serpent.state.stupidityImpulseSent = true
            end
        end

    -- Darkshade ginseng impulse — deliver camus via scytherus ekanelia
    elseif serpOffenseMode == "darkshade" and serpStrategy == "ginseng_pressure"
       and not eqAction and checkImpulseEligible()
       and haveAff("addiction") and haveAff("nausea") then
        impulsePair = {suggestion = selectImpulse(nil), venom = "scytherus", label = "camus"}
        useImpulse = true

    -- Scytherus mode impulse — deliver scytherus when aff not on target
    elseif serpOffenseMode == "scytherus" and serpStrategy == "scytherus_attack"
       and not useBite and not eqAction and not haveAff("scytherus") then
        impulsePair = {suggestion = selectImpulse(nil), venom = "scytherus", label = "camus"}
        useImpulse = true

    -- Group mode: impulse impatience when weariness + asthma stuck, impatience missing
    elseif serpOffenseMode == "group" and not eqAction and checkImpulseEligible()
       and not haveAff("impatience") then
        impulsePair = selectImpulsePair()
        if impulsePair then
            useImpulse = true
        end

    -- Normal impulse for impatience (gated by shouldDeliverImpatience)
    elseif not eqAction and not haveAff("impatience") and checkImpulseEligible() then
        impulsePair = selectImpulsePair()
        if impulsePair and impulsePair.label == "impatience" then
            useImpulse = true
        else
            -- Track 5: opportunistic high-value ekanelias (loki/aconite/curare)
            -- when monkshood isn't available this round.
            local opp = selectOpportunisticEkanelia()
            if opp then
                impulsePair = opp
                useImpulse = true
            end
        end
    end

    -- Gecko override: strip sileris to enable impulse next round.
    -- Only fires once per rotation. Don't fire if monkshood conditionals
    -- aren't actually ready yet -- no point stripping sileris prematurely.
    if not useImpulse and not eqAction and not haveAff("impatience")
       and not serpent.state.geckoStripAttempted
       and serpOffenseMode ~= "scytherus"
       and serpStrategy ~= "relapse_lock"
       and not checkImpulseEligible() then
        local potentialImpulse = selectImpulsePair()
        if potentialImpulse and potentialImpulse.label == "impatience" then
            envenomList = {"gecko"}
            envenomListTwo = {}
            table.insert(envenomListTwo, pickVenom("gecko"))
            serpent.state.geckoStripAttempted = true
            serpent.state.postGeckoLockdown = true
            Algedonic.Echo("<yellow>GECKO STRIP<white> -> enabling impulse (" .. potentialImpulse.label .. ")")
        end
    end

    -- Scytherus gecko strip: only needed when scytherus stuck + fangbarrier blocks bite
    if serpOffenseMode == "scytherus" and serpStrategy == "scytherus_attack"
       and not useBite and not useImpulse
       and haveAff("scytherus") and not checkImpulseEligible() then
        Algedonic.Echo("<yellow>GECKO (slickness)<white> -> clearing fangbarrier for bite")
    end

    -- --------------------------------------------------------
    -- BUILD ATTACK COMMAND
    -- postAction appended when canUseSecondary is true
    -- and no impulse/bite/eqAction is consuming the eq slot.
    -- --------------------------------------------------------
    local cmd

    if useBite then
        attackMode = "bite"
        serpent.impulseSuccess = false
        cmd = wieldDirk .. "bite " .. target .. " " .. biteVenom
        Algedonic.Echo("<yellow>BITE " .. biteVenom:upper() .. "<white> -> " .. (biteLabel or "camus"))
        envenomList = {biteVenom}
        envenomListTwo = {}
        if eqAction and canUseSecondary then
            if eqAction:find("^snap") or eqAction:find("^shrugging") then
                cmd = cmd .. sp .. eqAction
            else
                cmd = wieldDirk .. eqAction .. sp .. "bite " .. target .. " " .. biteVenom
            end
        end

    elseif useImpulse and impulsePair then
        serpent.impulseSuccess = false
        -- Record impulse timestamp for per-aff fratricide cooldown
        recordImpulse(impulsePair.suggestion)
        cmd = wieldDirk .. "impulse " .. target .. " " .. impulsePair.suggestion .. " " .. impulsePair.venom
        Algedonic.Echo("<yellow>IMPULSE " .. impulsePair.suggestion:upper() .. " + " .. impulsePair.venom:upper() .. "<white> -> " .. impulsePair.label)
        envenomList = {impulsePair.venom}
        envenomListTwo = {}

    elseif eqAction and canUseSecondary then
        if eqAction:find("^snap") or eqAction:find("^shrugging") then
            cmd = wieldDirk .. "dstab " .. target .. " " .. envenomList[1] .. " " .. envenomListTwo[1] .. sp .. eqAction
        else
            cmd = wieldDirk .. eqAction .. sp .. "dstab " .. target .. " " .. envenomList[1] .. " " .. envenomListTwo[1]
        end

    else
        -- DSTAB only — append postAction if canUseSecondary
        cmd = wieldDirk .. "dstab " .. target .. " " .. envenomList[1] .. " " .. envenomListTwo[1]
        if canUseSecondary and postAction ~= "" then
            cmd = cmd .. postAction
        end
    end

    -- Keybind-requested suggestion override
    if useImpulse and hSuggActive ~= "" and impulsePair then
        recordImpulse(hSuggActive)
        cmd = wieldDirk .. "impulse " .. target .. " " .. hSuggActive .. " " .. impulsePair.venom
    end

    serp_sendAttack(preAtk .. cmd)
end

--[[
    Determine the best EQ action for this round.
    Returns the eq command string or nil.
    Priority: snap > shrug > hypnosis step
]]--
function getEqAction()
    -- 1. Snap: asthma on target + snap ready + not yet snapped
    if serpent.hypnosis.canSnap() then
        return "snap " .. target
    end

    -- 2. Shrug: we're near-locked and can self-cure
    -- (Shrugging uses eq to cure an affliction from ourselves)
    if serpent.state.shouldShrug then
        serpent.state.shouldShrug = false
        return "shrugging"
    end

    -- 3. Hypnosis step: active hypnosis chain
    if serpent.hypnosis.isActive() then
        local hypCmd = serpent.hypnosis.getCommand()
        if hypCmd then
            return hypCmd
        end
    end

    -- 4. Hypno lock / hypnosis mode: start chain from idle
    if (serpOffenseMode == "hypnolock" or serpOffenseMode == "hypnosis") and serpent.hypnosis.phase == "idle" then
        local hypCmd = serpent.hypnosis.getCommand()
        if hypCmd then
            return hypCmd
        end
    end

    return nil
end

--[[
    Pick the next exit to block (Track 3.1).
    Walks gmcp.Room.Exits and returns the first direction we haven't
    blocked in the last 5s. Returns nil if all exits are recently blocked
    or no exit data is available.
]]--
local function nextExitToBlock()
    if not gmcp or not gmcp.Room or not gmcp.Room.Info or not gmcp.Room.Info.exits then
        return nil
    end
    local epoch = getEpoch()
    -- gmcp.Room.Info.exits is a table keyed by short-direction → room-id
    for dir, _ in pairs(gmcp.Room.Info.exits) do
        local lastBlocked = serpent.state.blockedExits[dir] or 0
        if (epoch - lastBlocked) >= 5 then
            return dir
        end
    end
    return nil
end

--[[
    Build the opening burst (Track 1).
    Fired once per fight when serpent.state.firstAttack is true.
    Includes: dispel, adder order (already added by caller), optional pinshot
    via bow swap, optional sigil drop. Returns prefix string (with trailing sp)
    or "" if no opener pieces are active.
]]--
local function buildOpener(sp)
    local prefix = ""
    if not serpent.config.useOpener then return prefix end

    -- Pinshot: only if bow opener enabled, pinshot not already active on target,
    -- and we have a fresh dispel slot (covers ekauto re-init via tar changed).
    -- Pinshot REQUIRES a body part; "foot" is the standard impale target
    -- (matches the inbound trigger pattern "Your arrow slams into the foot of ...").
    if serpent.config.useBowOpener and not tpinshot then
        local bow = serpent.config.bowName or "bow"
        prefix = prefix
            .. "remove " .. bow .. sp
            .. "wield " .. bow .. sp
            .. "pinshot " .. target .. " foot" .. sp
            .. "wield shield dirk" .. sp
        serpent.state.pinshotSentAt = getEpoch()
    end

    -- Sigil deployment: optional, requires inventory of sigils.
    if serpent.config.useSigils and not serpent.state.sigilDeployed then
        prefix = prefix
            .. "drop incandescent sigil" .. sp
            .. "attach monolith sigil to incandescent sigil" .. sp
        serpent.state.sigilDeployed = true
    end

    return prefix
end

--[[
    Send the attack if target is present.
    Wraps with queue and handles dispel + attackInFlight.
    Round-1 burst (Track 1): pinshot + sigils + dispel + adder order.
    Per-round denial (Track 3): exit-block rotated through gmcp.Room.Info.exits.
]]--
function serp_sendAttack(atk)
    if not table.contains(ataxia.playersHere, target) then
        Algedonic.Echo("<red>Target not in room!<white>")
        return
    end

    local sp = ataxia.settings.separator

    -- Exit-block: send block on a fresh direction (config-gated, throttled).
    -- We DON'T add this to the queue prefix because `block <dir>` uses balance
    -- in Achaea — chaining it before dstab in the same queue would error.
    -- Instead, fire it as a standalone send when our balance is up but the
    -- attack is queued. Currently called via prefix to keep the change local;
    -- if it causes balance errors live, move out of the chain.
    if serpent.config.useExitBlock then
        local epoch = getEpoch()
        if (epoch - serpent.state.lastBlockSentAt) >= 5 then
            local dir = nextExitToBlock()
            if dir then
                -- Send block as its own (unqueued) command; if it errors, the
                -- main attack still goes through unaffected.
                send("block " .. dir, false)
                serpent.state.blockedExits[dir] = epoch
                serpent.state.lastBlockSentAt = epoch
            end
        end
    end

    -- Order adder to attack target
    atk = "order adder kill " .. target .. sp .. atk

    -- Purge residual venom before new attack
    atk = "purge" .. sp .. atk

    -- Prepend round-1 opener burst (pinshot, sigils — first attack only)
    if serpent.state.firstAttack then
        atk = buildOpener(sp) .. atk
        serpent.state.firstAttack = false
    end

    -- Prepend dispel if first attack
    if not serpent.state.dispelSent then
        atk = "dispel " .. target .. sp .. atk
        serpent.state.dispelSent = true
    end

    send("queue addclear freestand " .. atk)
    serpent.state.attackInFlight = true
end

-- =============================================================================
-- MAIN OFFENSE FUNCTION
-- =============================================================================

function serp_ekanelia_offense()
    -- Only dispatch when we actually have balance — prevents computing
    -- attack with current state then queuing it for later execution
    -- (by which time game state has changed)
    if gmcp.Char.Vitals.bal ~= "1" then
        return
    end

    -- Guard: don't re-dispatch while off balance
    if serpent.state.attackInFlight then
        return
    end

    -- Rebound hold gate
    if reboundHold and reboundHold.gate(serp_ekanelia_offense) then return end

    -- Sync suggestion queueing
    if hSuggRequest ~= "" and hSuggRequest ~= hSuggActive then
        hSuggActive = hSuggRequest
    end

    -- Initialize state
    tAffs.hypnotising = tAffs.hypnotising or false
    tAffs.hypnotised = tAffs.hypnotised or false
    tAffs.hypnoseal = tAffs.hypnoseal or false
    tAffs.snapped = tAffs.snapped or false

    -- Get target lock status
    checkTargetLocks()

    -- P0 finisher-safety: recompute locks at graded confidence, overwriting the
    -- shared 0.30 boolean values from checkTargetLocks(). Same lock *definition*
    -- (3-of-4 soft pieces; impatience/sandfever for hard), only the confidence
    -- bar is raised — paralysis must read 0.90 before we call it a truelock, so a
    -- finisher never fires on an aff the target may have already cured.
    do
        softlock, hardlock, truelock = false, false, false
        local softPieces = 0
        for _, a in ipairs({"anorexia", "asthma", "slickness", "bloodfire"}) do
            if haveAff_tactical(a) then softPieces = softPieces + 1 end
        end
        if softPieces >= 3 then softlock = true end
        if softlock and (haveAff_tactical("impatience") or haveAff_tactical("sandfever")) then
            hardlock = true
        end
        if hardlock and haveAff_locked("paralysis") then truelock = true end
    end

    -- Check for Ekanelia opportunities
    checkEkaneliaOpportunities()

    -- Track relapse phase (lock mode)
    -- impatienceDelivered is set by 016_Ekanelia_Success trigger (event-driven)
    -- Once impatience was delivered, we're in relapse phase -- target will cure it,
    -- and we need to immediately start stupidity+curare then gecko+slike
    serpent.state.relapsePhase = serpent.state.impatienceDelivered

    -- Check darkshade timer
    local darkshadeTime = checkDarkshadeTimer()

    -- Determine strategy (lock-first)
    if serpOffenseMode == "auto" then
        determineStrategy()
    elseif serpOffenseMode == "lock" then
        if truelock then
            if not serpent.state.voyriaSent then
                serpStrategy = "lock_reinforce"
            else
                serpStrategy = "finish"
            end
        elseif hardlock and serpent.state.relapsePhase then
            -- Second monkshood landed (hardlock), need curare + class aff to complete truelock
            serpStrategy = "lock_reinforce"
        elseif serpent.state.relapsePhase then
            serpStrategy = "relapse_lock"
        else
            serpStrategy = "lock"
        end
    elseif serpOffenseMode == "group" then
        if truelock then
            if not serpent.state.voyriaSent then
                serpStrategy = "group"  -- maintain pressure while waiting for voyria impulse
            else
                serpStrategy = "finish"
            end
        else
            serpStrategy = "group"
        end
    elseif serpOffenseMode == "darkshade" then
        -- Darkshade-first, then full lock cycle
        -- If target eats ginseng to cure darkshade, stack ginseng affs to protect it
        local ct = serpent.cureTracking
        if ct.ginsengCures > 0 and countGinsengStack() < 3 and not serpent.state.camusDelivered then
            -- Target eating ginseng: stack addiction/nausea to hide darkshade
            -- Once camus delivered via scytherus, transition to lock cycle
            serpStrategy = "ginseng_pressure"
        elseif not haveAff("darkshade") and not serpent.state.camusDelivered then
            serpStrategy = "apply_darkshade"
        elseif truelock then
            if not serpent.state.voyriaSent then
                serpStrategy = "lock_reinforce"
            else
                serpStrategy = "finish"
            end
        elseif hardlock and serpent.state.relapsePhase then
            serpStrategy = "lock_reinforce"
        elseif serpent.state.relapsePhase then
            serpStrategy = "relapse_lock"
        else
            serpStrategy = "lock"
        end
    elseif serpOffenseMode == "scytherus" then
        -- Scytherus camus damage: scytherus stuck = ALWAYS bite, else build or impulse
        if haveAff("scytherus") then
            -- Scytherus stuck: bite for camus no matter what
            serpStrategy = "scytherus_attack"
        elseif haveAff("addiction") and haveAff("nausea") then
            -- Conditionals met: impulse to deliver scytherus
            serpStrategy = "scytherus_attack"
        else
            serpStrategy = "build_scytherus"
        end
    elseif serpOffenseMode == "bitepayload" then
        -- Bite-centric sustained-pressure mode (Track 2).
        -- Strategy is "setup_lock" (not "bite_payload") so selectVenoms() uses
        -- the standard lock chain for dstab fallback when selectBiteVenom() nils.
        -- The bitepayload-specific behavior lives in serp_ekanelia_attack() PRIORITY 6,
        -- gated on serpOffenseMode (not on strategy name).
        if truelock then
            if not serpent.state.voyriaSent then
                serpStrategy = "lock_reinforce"
            else
                serpStrategy = "finish"
            end
        else
            serpStrategy = "setup_lock"
        end
    elseif serpOffenseMode == "hypnosis" then
        serpStrategy = "hypnosis"
    elseif serpOffenseMode == "hypnolock" then
        -- Use lock venoms while hypnosis handles EQ
        if serpent.hypnosis.isActive() or serpent.hypnosis.phase == "idle" then
            serpStrategy = "hypnolock"
        else
            -- After snap cooldown, mode already switched to "lock"
            serpStrategy = "lock"
        end
    end

    -- Echo strategy
    if serpent.config.echoStrategy then
        Algedonic.Echo("<dim_grey>Strategy: <white>" .. serpStrategy)
    end

    -- Echo target afflictions for debugging
    if serpent.config.echoAffs then
        local affStr = ""
        if haveAff("asthma") then affStr = affStr .. "<cyan>AST " end
        if haveAff("weariness") then affStr = affStr .. "<cyan>WEA " end
        if haveAff("clumsiness") then affStr = affStr .. "<cyan>CLU " end
        if haveAff("slickness") then affStr = affStr .. "<yellow>SLI " end
        if haveAff("paralysis") then affStr = affStr .. "<yellow>PAR " end
        if haveAff("impatience") then affStr = affStr .. "<red>IMP " end
        if haveAff("anorexia") then affStr = affStr .. "<red>ANO " end
        if haveAff("masochism") then affStr = affStr .. "<magenta>MAS " end
        if haveAff("stupidity") then affStr = affStr .. "<magenta>STU " end
        if haveAff("confusion") then affStr = affStr .. "<magenta>CON " end
        if haveAff("recklessness") then affStr = affStr .. "<magenta>RCK " end
        if haveAff("disrupted") then affStr = affStr .. "<red>DIS " end
        if haveAff("voyria") then affStr = affStr .. "<red>VOY " end
        if haveAff("sileris") or (tAffs and tAffs.sileris) then affStr = affStr .. "<red>SIL " end
        if haveAff("fangbarrier") or (tAffs and tAffs.fangbarrier) then affStr = affStr .. "<red>FNG " end
        if haveAff("darkshade") then affStr = affStr .. "<green>DRK " end
        if haveAff("addiction") then affStr = affStr .. "<green>ADD " end
        if haveAff("nausea") then affStr = affStr .. "<green>NAU " end
        if affStr == "" then affStr = "<dim_grey>none" end
        cecho("<white>[tAffs]: " .. affStr .. "<reset>\n")
    end

    -- Build venom lists
    selectVenoms()

    -- Execute attack
    serp_ekanelia_attack()
end

-- =============================================================================
-- MODE SWITCHING FUNCTIONS
-- =============================================================================

function serp_setmode_lock()
    if serpOffenseMode ~= "lock" then
        serpent.state.impatienceDelivered = false
        serpent.state.stupidityImpulseSent = false
        serpent.state.relapsePhase = false
        serpent.state.voyriaSent = false
        serpent.state.lockReinforceSent = false
        serpent.state.camusDelivered = false
        serpOffenseMode = "lock"
        cecho("\n<green>Serpent offense: LOCK mode<reset>\n")
        cecho("<dim_grey>  Priority: Lock completion via Ekanelia + venom pressure<reset>\n")
    end
    serpOffenseMode = "lock"
end

function serp_setmode_group()
    if serpOffenseMode ~= "group" then
        serpent.state.voyriaSent = false
        serpOffenseMode = "group"
        cecho("\n<cyan>Serpent offense: GROUP mode<reset>\n")
        cecho("<dim_grey>  Priority: Fast lock -- paralysis > asthma > slickness > weariness > impulse impatience > anorexia<reset>\n")
    end
    serpOffenseMode = "group"
end

function serp_setmode_darkshade()
    if serpOffenseMode ~= "darkshade" then
        serpent.state.impatienceDelivered = false
        serpent.state.stupidityImpulseSent = false
        serpent.state.relapsePhase = false
        serpent.state.voyriaSent = false
        serpent.state.lockReinforceSent = false
        serpent.state.camusDelivered = false
        serpOffenseMode = "darkshade"
        cecho("\n<magenta>Serpent offense: DARKSHADE mode<reset>\n")
        cecho("<dim_grey>  Priority: Apply darkshade, then lock via relapse cycle<reset>\n")
    end
    serpOffenseMode = "darkshade"
end

function serp_setmode_scytherus()
    if serpOffenseMode ~= "scytherus" then
        serpent.state.geckoStripAttempted = false
        serpent.state.camusDelivered = false
        serpOffenseMode = "scytherus"
        cecho("\n<red>Serpent offense: SCYTHERUS mode<reset>\n")
        cecho("<dim_grey>  Priority: Build addiction+nausea -> impulse/bite scytherus -> camus damage<reset>\n")
    end
    serpOffenseMode = "scytherus"
end

function serp_setmode_bitepayload()
    if serpOffenseMode ~= "bitepayload" then
        serpent.state.geckoStripAttempted = false
        serpOffenseMode = "bitepayload"
        cecho("\n<red>Serpent offense: BITE PAYLOAD mode<reset>\n")
        cecho("<dim_grey>  Priority: Bite for affliction stacking -- scytherus/monkshood/kalmia/curare/loki/aconite<reset>\n")
    end
    serpOffenseMode = "bitepayload"
end

function serp_setmode_hypnosis()
    if serpOffenseMode ~= "hypnosis" then
        serpOffenseMode = "hypnosis"
        if serpent.hypnosis and serpent.hypnosis.reset then
            serpent.hypnosis.reset()
        end
        cecho("\n<cyan>Serpent offense: HYPNOSIS COMBO mode<reset>\n")
        cecho("<dim_grey>  Priority: Fratricide -> mental affs RELAPSE after cure!<reset>\n")
    end
    serp_ekanelia_offense()
end

function serp_setmode_auto()
    serpOffenseMode = "auto"
    cecho("\n<yellow>Serpent offense: AUTO mode<reset>\n")
    cecho("<dim_grey>  Lock-first with adaptive Ekanelia + darkshade<reset>\n")
end

function serp_setmode_hypnolock()
    if serpOffenseMode ~= "hypnolock" then
        serpOffenseMode = "hypnolock"
        -- Initialize hypnosis for lock mode
        serpent.hypnosis.reset()
        serpent.hypnosis.mode = "lock"
        serpent.hypnosis.targetSuggestions = selectHypnoLockSuggestions()

        cecho("\n<yellow>Serpent offense: HYPNO LOCK mode<reset>\n")
        if #serpent.hypnosis.targetSuggestions > 0 then
            cecho("<dim_grey>  Hypnosis: ")
            for i, sug in ipairs(serpent.hypnosis.targetSuggestions) do
                cecho(sug .. (i < #serpent.hypnosis.targetSuggestions and ", " or ""))
            end
            cecho("<reset>\n")
        else
            cecho("<dim_grey>  Hypnosis: <red>No suggestions available (target has all candidates)<reset>\n")
        end
        cecho("<dim_grey>  Flow: dstab+hypnotise -> suggest x" .. #serpent.hypnosis.targetSuggestions ..
              " -> seal -> snap -> lock mode<reset>\n")
    end
    serp_ekanelia_offense()
end

-- =============================================================================
-- STATUS DISPLAY
-- =============================================================================

function serp_status()
    local darkshadeTime = 0
    if haveAff("darkshade") and affTimers.darkshade then
        darkshadeTime = getEpoch() - affTimers.darkshade
    end

    local ginsengCount = countGinsengStack()

    cecho("\n<cyan>===== Serpent Offense Status =====<reset>\n")
    cecho("<white>Mode: <yellow>" .. serpOffenseMode .. "<reset>\n")
    cecho("<white>Strategy: <yellow>" .. serpStrategy .. "<reset>\n")

    -- Lock status
    checkTargetLocks()
    local lockStr = "<white>Lock Status: "
    if truelock then lockStr = lockStr .. "<red>TRUE LOCK"
    elseif hardlock then lockStr = lockStr .. "<orange>HARD LOCK"
    elseif softlock then lockStr = lockStr .. "<yellow>SOFT LOCK"
    else lockStr = lockStr .. "<dim_grey>None" end
    cecho(lockStr .. "<reset>\n")

    -- Sileris/fangbarrier status (V1 fallback — haveAff alone misses fangbarrier)
    local hasSileris = haveAff("sileris") or (tAffs and tAffs.sileris)
    local hasFangbarrier = haveAff("fangbarrier") or (tAffs and tAffs.fangbarrier)
    cecho("<white>Sileris/Fangbarrier: " .. ((hasSileris or hasFangbarrier) and "<red>UP (blocks bite/impulse)" or "<green>DOWN") .. "<reset>\n")

    -- Impulse eligibility
    cecho("<white>Impulse Eligible: " .. (checkImpulseEligible() and "<green>YES" or "<red>NO"))
    if not checkImpulseEligible() then
        local missing = {}
        if hasSileris then table.insert(missing, "sileris") end
        if hasFangbarrier then table.insert(missing, "fangbarrier") end
        if #missing > 0 then
            cecho(" <dim_grey>(blocked: " .. table.concat(missing, ", ") .. ")")
        end
    end
    cecho("<reset>\n")

    -- Ekanelia opportunities
    checkEkaneliaOpportunities()
    local impPair = selectImpulsePair()

    if next(ekaneliaReady) then
        cecho("<white>Ekanelia Ready: ")
        for k, v in pairs(ekaneliaReady) do
            if v then cecho("<yellow>" .. k .. " ") end
        end
        cecho("<reset>\n")
    else
        cecho("<white>Ekanelia Ready: <dim_grey>None<reset>\n")
    end

    if impPair then
        cecho("<white>Impulse Pair: <green>impulse " .. target .. " " .. impPair.suggestion .. " " .. impPair.venom .. " -> " .. impPair.label .. "<reset>\n")
    else
        cecho("<white>Impulse Pair: <dim_grey>None available<reset>\n")
    end

    -- Hypnosis status
    if serpent.hypnosis then
        cecho("<white>Hypnosis Phase: <yellow>" .. serpent.hypnosis.phase .. "<reset>\n")
        cecho("<white>Fratricide: ")
        if serpent.hypnosis.fratricideActive or tAffs.fratricide then
            cecho("<green>ACTIVE<reset>\n")
        elseif serpent.hypnosis.fratricideApplied then
            cecho("<yellow>QUEUED<reset>\n")
        else
            cecho("<dim_grey>No<reset>\n")
        end

        local timeToSnap = serpent.hypnosis.getTimeToSnap()
        if timeToSnap == 0 then
            cecho("<white>Snap: <green>READY!<reset>\n")
        elseif timeToSnap > 0 then
            cecho("<white>Snap In: <yellow>" .. string.format("%.1f", timeToSnap) .. "s<reset>\n")
        end
    end

    -- Darkshade tracking
    cecho("<white>Darkshade: " .. (haveAff("darkshade") and ("<green>YES<white> (" .. math.floor(darkshadeTime) .. "s/" .. DARKSHADE_KILL_TIME .. "s)") or "<red>NO") .. "<reset>\n")
    cecho("<white>Ginseng Stack: <yellow>" .. ginsengCount .. "/6<reset>\n")
    cecho("<white>Kelp Stack: <yellow>" .. countKelpStack() .. "/7<reset>\n")
    cecho("<white>Bloodroot Stack: <yellow>" .. countBloodrootStack() .. "/2<reset>\n")

    -- Cure tracking
    cecho("<white>------- Adaptive Tracking --------<reset>\n")
    cecho("<white>Kelp Cures: <yellow>" .. serpent.cureTracking.kelpCures .. "<reset>")
    cecho("  <white>Ginseng Cures: <yellow>" .. serpent.cureTracking.ginsengCures .. "<reset>\n")
    cecho("<white>Bloodroot Cures: <yellow>" .. serpent.cureTracking.bloodrootCures .. "<reset>")
    cecho("  <white>Focus: <yellow>" .. serpent.cureTracking.focusCures .. "<reset>\n")

    if serpent.cureTracking.ginsengCures > serpent.cureTracking.kelpCures + 2 then
        cecho("<green>ADAPTIVE: <white>Target fears darkshade -> pushing LOCK<reset>\n")
    elseif serpent.cureTracking.kelpCures > serpent.cureTracking.ginsengCures + 2 then
        cecho("<magenta>ADAPTIVE: <white>Target fears lock -> pushing DARKSHADE<reset>\n")
    else
        cecho("<dim_grey>ADAPTIVE: <white>Balanced curing - standard progression<reset>\n")
    end

    -- Attack in flight
    cecho("<white>Attack In Flight: " .. (serpent.state.attackInFlight and "<yellow>YES" or "<dim_grey>No") .. "<reset>\n")
    cecho("<white>Dispel Sent: " .. (serpent.state.dispelSent and "<green>YES" or "<dim_grey>No") .. "<reset>\n")

    cecho("<cyan>==================================<reset>\n")
end

-- =============================================================================
-- EVENT HANDLERS
-- =============================================================================

function serpent.resetCureTracking()
    serpent.cureTracking.kelpCures = 0
    serpent.cureTracking.ginsengCures = 0
    serpent.cureTracking.bloodrootCures = 0
    serpent.cureTracking.focusCures = 0
    serpent.cureTracking.lastReset = getEpoch()
end

-- Kill existing event handlers to avoid duplicates
if serpent.eventHandlers then
    for _, handlerId in pairs(serpent.eventHandlers) do
        if killAnonymousEventHandler then killAnonymousEventHandler(handlerId) end
    end
end
serpent.eventHandlers = {}

if registerAnonymousEventHandler then
    -- Target change: reset state
    serpent.eventHandlers.tarChanged = registerAnonymousEventHandler("changed target", function()
        if serpent.hypnosis and serpent.hypnosis.reset then
            serpent.hypnosis.reset()
        end
        serpent.resetCureTracking()
        serpent.state.dispelSent = false
        serpent.state.attackInFlight = false
        serpent.state.impatienceDelivered = false
        serpent.state.stupidityImpulseSent = false
        serpent.state.relapsePhase = false
        serpent.state.voyriaSent = false
        serpent.state.geckoStripAttempted = false
        serpent.state.postGeckoLockdown = false
        serpent.state.lockReinforceSent = false
        serpent.state.camusDelivered = false
        serpent.state.firstAttack = true
        serpent.state.pinshotSentAt = 0
        serpent.state.sigilDeployed = false
        serpent.state.blockedExits = {}
        serpent.state.lastBlockSentAt = 0
        serpent.impulseSuccess = false
        serpent.impulseRelapsing = false
        lastImpulsed = {}
        lastImpatienceAttempt = 0
        lastReboundingFlay = 0
        serpent.state.lastRebounding = false
        hSuggActive = ""
    end)

    -- Balance recovery: clear attackInFlight (edge-triggered: only on 0→1 transition)
    -- Level-triggered clear caused double dispatches when keybind mashed — GMCP vitals
    -- fires with bal="1" on the same prompt that consumed balance, prematurely clearing the guard
    serpent.eventHandlers.balRecovery = registerAnonymousEventHandler("gmcp.Char.Vitals", function()
        if gmcp.Char.Vitals.bal == "1" then
            if serpent.state.lastBalState == "0" then
                serpent.state.attackInFlight = false
            end
            serpent.state.lastBalState = "1"
        else
            serpent.state.lastBalState = "0"
        end
    end)
end

-- =============================================================================
-- ALIAS REGISTRATION
-- =============================================================================

if serpent.aliases then
    for _, aliasId in pairs(serpent.aliases) do
        if killAlias then killAlias(aliasId) end
    end
end
serpent.aliases = {}

if tempAlias then
    serpent.aliases.ek = tempAlias("^ek$", [[serp_ekanelia_offense()]])
    serpent.aliases.eklock = tempAlias("^eklock$", [[serp_setmode_lock()]])
    serpent.aliases.ekdark = tempAlias("^ekdark$", [[serp_setmode_darkshade()]])
    serpent.aliases.ekhyp = tempAlias("^ekhyp$", [[serp_setmode_hypnosis()]])
    serpent.aliases.ekauto = tempAlias("^ekauto$", [[serp_setmode_auto()]])
    serpent.aliases.ekstatus = tempAlias("^ekstatus$", [[serp_status()]])
    serpent.aliases.ekhypstatus = tempAlias("^ekhypstatus$", [[serpent.hypnosis.status()]])
    serpent.aliases.ekhl = tempAlias("^ekhl$", [[serp_setmode_hypnolock()]])
    serpent.aliases.ekgroup = tempAlias("^ekgroup$", [[serp_setmode_group()]])
    serpent.aliases.ekscyth = tempAlias("^ekscyth$", [[serp_setmode_scytherus()]])
    serpent.aliases.ekbite = tempAlias("^ekbite$", [[serp_setmode_bitepayload()]])
end

-- =============================================================================
-- TRIGGER REGISTRATION
-- =============================================================================

if serpent.triggers then
    for _, triggerId in pairs(serpent.triggers) do
        if killTrigger then killTrigger(triggerId) end
    end
end
serpent.triggers = {}

if tempRegexTrigger then
    serpent.triggers.hypnosisStart = tempRegexTrigger(
        "^You prepare yourself to hypnotise your victim, (\\w+)\\.$",
        [[
            tAffs.hypnotising = true
            tAffs.hypnoseal = false
            ataxiaTemp.hypnoseal = false
            if serpent and serpent.hypnosis and serpent.hypnosis.start then
                serpent.hypnosis.start(matches[2])
            end
        ]]
    )

    serpent.triggers.hypnotised = tempRegexTrigger(
        "You fix (\\w+) with an entrancing stare, and smile in satisfaction as you realise that \\w+ mind is yours\\.",
        [[
            tAffs.hypnotising = nil
            tAffs.hypnotised = true
            tAffs.hypnoseal = false
            ataxiaTemp.hypnoseal = false
            if serpent and serpent.hypnosis and serpent.hypnosis.onHypnotised then
                serpent.hypnosis.onHypnotised()
            end
        ]]
    )

    serpent.triggers.snapped = tempRegexTrigger(
        "^You snap your fingers in front of (\\w+)\\.$",
        [[
            tAffs.hypnotising = false
            tAffs.hypnotised = false
            tAffs.snapped = true
            tAffs.hypnoseal = false
            ataxiaTemp.hypnoseal = false
            serpentsuggest = false
            tempTimer(3, function() tAffs.snapped = false; ataxiaTemp.suggestions = nil end)
            snapTarget = false
            if serpent and serpent.hypnosis and serpent.hypnosis.onSnapped then
                serpent.hypnosis.onSnapped()
            end
        ]]
    )

    serpent.triggers.suggestGiven = tempRegexTrigger(
        "^You issue the suggestion, concealing it deep within (\\w+)'s mind\\.$",
        [[
            serpentsuggest = true
            if serpent and serpent.hypnosis and serpent.hypnosis.onSuggested then
                local suggestion = ataxiaTemp.suggestAff or "unknown"
                serpent.hypnosis.onSuggested(suggestion)
            end
        ]]
    )

    serpent.triggers.suggestAlready = tempRegexTrigger(
        "^(\\w+)'s mind is already holding something quite similar to that suggestion\\.$",
        [[
            serpentsuggest = true
        ]]
    )

    serpent.triggers.fratricideCured = tempRegexTrigger(
        "The look of madness fades from (\\w+)'s eyes",
        [[
            if erAffWrapper then erAffWrapper("fratricide") elseif erAff then erAff("fratricide") end
            if serpent and serpent.hypnosis and serpent.hypnosis.onFratricideCured then
                serpent.hypnosis.onFratricideCured()
            end
        ]]
    )

    serpent.triggers.sealSuccess = tempRegexTrigger(
        "^You draw (\\w+) out of \\w+ hypnotic daze, your suggestions indelibly printed on \\w+ mind\\.$",
        [[
            if serpent and serpent.hypnosis and serpent.hypnosis.onSealed then
                serpent.hypnosis.onSealed()
            end
        ]]
    )

    serpent.triggers.hypnosisLost = tempRegexTrigger(
        "^You feel your control over (\\w+)'s mind fade\\.$",
        [[
            if serpent and serpent.hypnosis and serpent.hypnosis.reset then
                serpent.hypnosis.reset()
                Algedonic.Echo("<red>HYPNOSIS: <white>Lost control -- state reset")
            end
        ]]
    )

    serpent.triggers.hypnosisNoticed = tempRegexTrigger(
        "^(\\w+) has noticed your attempt at hypnosis\\!$",
        [[
            if serpent and serpent.hypnosis and serpent.hypnosis.reset then
                serpent.hypnosis.reset()
                Algedonic.Echo("<red>HYPNOSIS: <white>Target noticed -- state reset")
            end
        ]]
    )

    serpent.triggers.hypnosisTooPerceptive = tempRegexTrigger(
        "^(\\w+) is too perceptive for your hypnotic skill\\. ",
        [[
            if serpent and serpent.hypnosis and serpent.hypnosis.reset then
                serpent.hypnosis.reset()
                Algedonic.Echo("<red>HYPNOSIS: <white>Too perceptive -- state reset")
            end
        ]]
    )
end

-- =============================================================================
-- INITIALIZATION MESSAGE
-- =============================================================================

if Algedonic and Algedonic.Echo then
    Algedonic.Echo("<cyan>Serpent Offense System (Overhaul)<white> loaded.")
    Algedonic.Echo("<dim_grey>  DSTAB-primary, IMPULSE for Ekanelia triggers<reset>")
    Algedonic.Echo("<dim_grey>  Commands: ek, eklock, ekhyp, ekhl, ekdark, ekscyth, ekauto, ekstatus, ekhypstatus<reset>")
else
    cecho("<cyan>Serpent Offense System (Overhaul)<white> loaded.\n")
end
