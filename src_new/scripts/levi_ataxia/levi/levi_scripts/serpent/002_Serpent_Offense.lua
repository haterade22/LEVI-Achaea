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
    - EXECUTE: truelock finish, on a prone target, with the whip.

    EKANELIA TRANSFORMATIONS (BITE/IMPULSE only):
    - kalmia:    clumsiness + weariness           → slickness
    - aconite:   deadening + dementia              → paranoia
    - monkshood: asthma + masochism + weariness    → impatience
    - curare:    fratricide + nausea + scytherus    → hypochondria (CONSUMES the conditionals)
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
    - srd       : Group damage: sets scytherus mode, then one attack (aliases/.../serpent/006)
    - ekauto   : Auto-switch mode
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

-- Per-aff impulse timestamps for fratricide's 2.25 s relapse window (FRATRICIDE_RELAPSE below).
-- Every impulse call goes through recordImpulse() and selectImpulse() respects the window.
lastImpulsed = lastImpulsed or {}

-- Timestamp (now(), getEpoch) of when the target's rebounding was last observed to drop.
-- Rebounding reapplies ~8.5s after being stripped; we pre-empt that reapply with an
-- impulse instead of eating a reflected hit. 0 = disarmed. Reset on target change.
lastReboundingFlay = lastReboundingFlay or 0

-- Impatience delivery cooldown (2.5s).
-- Stamped by the ekanelia confirm trigger (serpent/016_Ekanelia_Success), NOT on send.
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

-- A LOCK PIECE IS SENT AGAIN AT THE LOCK'S OWN BAR. The soft, hard and true locks read asthma,
-- slickness, anorexia and impatience at the tactical 0.70, so the reads that ask "is this piece
-- missing, so send it" use haveAff_tactical too. A branched cure leaves a piece at 0.667: the cure
-- weights over two candidates do that to the second listed (a kelp eat over weariness + asthma, a
-- goldenseal eat over stupidity + impatience, a bloodroot eat over paralysis + slickness). With
-- nothing to settle the branch, haveAff's 0.30 called the piece up and the lock's 0.70 called it
-- down: nothing sent it, the lock never closed, and the round was "dstab <t> curare vernalius"
-- until a tree, focus or salve line moved the branch (2026-11-08 review). A monkshood sent again for
-- an impatience at 0.667 goes only if its reaction can fire (monkshoodCanReact). A read that asks if
-- a piece is there to build on (gecko wants asthma, slike wants impatience) stays at haveAff's 0.30.

-- RECKLESSNESS ONLY ON A LOCKED TARGET (user, 2026-11-07: "We shouldnt be doing recklessness unless
-- we have locked them. Else that is a wasted attack"). In the spar against Saibel 7 DSTABs carried
-- eurypteria, the Depthswalker class venom, and a focus or tree of hers followed each within about
-- 2 s (FL 361-372, FL 405-422, FL 994-1050); that it took the recklessness is INFERRED, kb/CONFLICTS.md
-- #65. One impulse also used the recklessness suggestion for the loki reaction (FL 1388).
--
-- "Locked" is the soft lock: anorexia + asthma + slickness, so eating, smoking and salves are shut.
-- Each piece must read at the tactical 0.70 that serp_ekanelia_offense uses for its lock pieces.
-- A hard lock and a true lock hold the same three pieces, so they count too. The offense's own
-- softlock flag also accepts bloodfire in place of one piece (3 of 4); bloodfire does not stop
-- eating, so that case does not count here.
local function targetLocked()
    return haveAff_tactical("anorexia") and haveAff_tactical("asthma") and haveAff_tactical("slickness")
end

-- The offense chooses recklessness (the eurypteria venom, the recklessness suggestion, or
-- recklessness as the loki conditional that an impulse brings) only when this is true.
local function recklessnessAllowed()
    return targetLocked() and true or false
end
serpent.recklessnessAllowed = recklessnessAllowed

-- Attack state tracking
serpent.state.attackInFlight = serpent.state.attackInFlight or false
serpent.state.lastBalState = serpent.state.lastBalState or "1"
-- The send time of the round in flight, and whether GMCP showed our balance down since then.
serpent.state.attackSentAt = serpent.state.attackSentAt or 0
serpent.state.balSpentSinceSend = serpent.state.balSpentSinceSend or false
-- Seconds after a send with no balance drop, on balance, after which the round counts as refused
-- (serp_ekanelia_offense's in-flight guard). A round that spends balance shows it down in about
-- 0.2 s (send 16:47:23.986, prompt without the balance flag 16:47:24.193,
-- kb/raw/logs/ours/2026-11-07_164635_Saibel.log:333, :368), so 1.5 s leaves room for lag.
local ATTACK_NO_SPEND = 1.5
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
-- True when a game line showed this target's rebounding UP: a raise line, a rebound line (both
-- reach us as tarAffed("rebounding")), or our flay's real strip line. The target reset only
-- ASSUMES rebounding (016 targetresetafflictionslevi), so it does not set this.
serpent.state.reboundingSeen = serpent.state.reboundingSeen or false
-- GROUP PRESSES (`sr`, `srd`; the user, 2026-11-10). True while the last press was one of them:
-- serp_ekanelia_offense(true) sets it, every other caller clears it. On a group press a target
-- that is not in the room is replaced (serpent.groupRetarget), and a new target starts with no
-- rebounding and no shield assumed (serpent.onGroupTarget): "we should not start out with
-- flaying, we should just hit". In the 2026-11-10 group fight 7 opening flays met no rebounding
-- and no shield.
serpent.state.groupPress = serpent.state.groupPress or false
-- True on a group target until a line shows its sileris coating gone or up. A bite needs the
-- coating gone ("need a flay or dstab with slickness"), so checkImpulseEligible() says no while
-- this is set, and the round strips it first: slickness that lands strips it (rule
-- defence.sileris.slickness, MEASURED 8), and so does a flay (attack.flay.coating, 23 of 23).
-- In the 2026-11-10 fight 4 of the 7 opening flays stripped a coating, so it is often up.
serpent.state.coatingUnknown = serpent.state.coatingUnknown or false
-- Snakes in our room, {[item id] = name}, from GMCP Char.Items (location "room").
serpent.state.snakesHere = serpent.state.snakesHere or {}
-- True once a GMCP room list arrived, so snakesHere is a real picture of the room.
serpent.state.roomListSeen = serpent.state.roomListSeen or false

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
-- The seal's delay in seconds: three is the least the game takes on every target (one only on a
-- deadened one, which the tracker cannot promise by the time the seal lands). Hypnosis.wiki:28.
local SEAL_DELAY = 3

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
    -- monkshood: "disloyalty", the name the tracker records (ataxia/001_Misc:208). Until v4.7.399
    -- this said "disfigurement" -- the OLD name, which the game still accepts as an alias
    -- (`affliction show disfigurement` answers "Disloyalty") but nothing ever records, so
    -- haveAff() was always false and the offense kept re-sending a venom that had already landed.
    aconite = "stupidity", monkshood = "disloyalty", scytherus = "scytherus",
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

-- False for a recklessness venom (eurypteria) while the target is not locked (recklessnessAllowed).
local function venomAllowed(venom)
    return VENOM_TO_AFF[venom] ~= "recklessness" or recklessnessAllowed()
end

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
    serpent.hypnosis.pendingSuggestion = nil   -- a word the last chain never got a success line for

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
    -- The timer marks the snap ready only for the fratricide chain, whose canSnap() is phase
    -- "ready_snap". The lock chain (ekhl) snaps once SEALED, and its suggest step needs phase
    -- "hypnotised" or "suggesting" (getCommand). One suggestion goes per round, so with three to
    -- give the third was due after the 4 s mark: the timer moved the phase to "ready_snap", and the
    -- chain never suggested again, never sealed and never snapped (2026-11-08 review, F9).
    serpent.hypnosis.snapTimer = tempTimer(SNAP_DELAY, function()
        serpent.hypnosis.snapTimerFired = true
        if serpent.hypnosis.mode ~= "lock"
           and (serpent.hypnosis.phase == "suggesting" or serpent.hypnosis.phase == "hypnotised") then
            serpent.hypnosis.phase = "ready_snap"
            Algedonic.Echo("<yellow>HYPNOSIS: <white>SNAP READY!")
        end
    end)
end

function serpent.hypnosis.onSuggested(suggestion)
    serpent.hypnosis.phase = "suggesting"
    serpent.hypnosis.pendingSuggestion = nil   -- this success line answered it (buildRound)

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
    -- The snap spends the seal. In lock mode canSnap() IS `sealed`, and only reset() used to clear
    -- it, so after a lock chain (ekhl) every round sent SNAP as its eq action until something reset
    -- the chain, and that eq action held off every impulse that needs a free eq slot (PRIORITY 3,
    -- 4, 5 and 7, the monkshood impatience among them). Cleared since v4.7.420.
    serpent.hypnosis.sealed = false

    if serpent.hypnosis.fratricideApplied then
        serpent.hypnosis.fratricideActive = true
        -- Through the tracker, not `tAffs.fratricide = true`: haveAff() reads V3 only
        -- (017_Affliction_Management.lua, haveAff), so a bare tAffs write left
        -- haveAff("fratricide") false, and the target's lobelia eat (onHerbCureV3) could never
        -- take it off (it takes fratricide only when nothing else lobelia cures is there, which
        -- keeps masochism's cure for the monkshood pair: herbCureLastV3, 007). Same scope as
        -- before: tarAffed records on the current target.
        tarAffed("fratricide")
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
    -- The tracker's removal (it also clears tAffs). The cure trigger below calls only this, so
    -- the cure is reported once.
    erAff("fratricide")
    Algedonic.Echo("<dim_grey>HYPNOSIS: <white>Target cured fratricide")
end

function serpent.hypnosis.onSealed()
    serpent.hypnosis.sealed = true
    Algedonic.Echo("<green>HYPNOSIS: <white>Sealed " .. #serpent.hypnosis.suggestions .. " suggestions!")
end

-- Resets the chain and what it knew about its target, but NOT the mode: that is the user's choice
-- (ekhl -> "lock", ekhyp -> "fratricide", set by serp_setmode_*), and this runs on every target
-- change (016 switchTarget, and the "changed target" handler below) and whenever a chain fails
-- (the hypnosisLost, hypnosisNoticed and hypnosisTooPerceptive triggers). It set mode =
-- "fratricide" until v4.7.420, so after a target change in hypnolock the next chain suggested
-- fratricide and snapped with no seal. The lock mode's suggestions are what THIS target lacks
-- (selectHypnoLockSuggestions), so they are picked again rather than kept from the last target.
function serpent.hypnosis.reset()
    serpent.hypnosis.phase = "idle"
    serpent.hypnosis.suggestions = {}
    serpent.hypnosis.fratricideApplied = false
    serpent.hypnosis.fratricideActive = false
    serpent.hypnosis.hypnoTarget = nil
    serpent.hypnosis.snapReadyTime = nil
    serpent.hypnosis.pendingSuggestion = nil
    -- Hypno lock fields
    serpent.hypnosis.targetSuggestions = (serpent.hypnosis.mode == "lock")
        and selectHypnoLockSuggestions() or {}
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
            -- All suggestions given, seal them. SEAL takes a DELAY in seconds, not a count:
            -- "SEAL <target> <delay in seconds>", "for three seconds and upwards", as low as one
            -- second only on a deadened target (kb/raw/wiki/Hypnosis.wiki:24, :28). This sent the
            -- number of suggestions, so with one or two of them the seal was under the minimum,
            -- never answered, and sent again every round (2026-11-08 review, F28).
            return "seal " .. tar .. " " .. SEAL_DELAY
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
        trigger = "scytherus",
        conditionals = {"addiction", "nausea"},
        trivials = {},
        result = "camus",
        priority = 5, -- damage pressure
    },
    -- CURARE: fratricide + nausea + scytherus -> hypochondria, and the reaction CONSUMES its
    -- conditionals (the user's Ekanelia table, 2026-11-11: "Cons? Yes", the only one). It was
    -- hypersomnia + masochism here, from no source. Eating scytherus ends the camus loop and
    -- eating fratricide ends the relapse window, for one hypochondria, so the offence never picks
    -- it (`consumes`, selectImpulsePair). It stays in the table for checkEkaneliaOpportunities
    -- and reactionNeeds.
    {
        trigger = "curare",
        conditionals = {"fratricide", "nausea", "scytherus"},
        trivials = {},
        result = "hypochondria",
        priority = 8,
        consumes = true,
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
    What each reaction GIVES, as the tracker's affliction names, keyed by the reaction's venom.
    The success line ("You sense the weakness in X as your <venom> takes hold.",
    triggers/.../serpent/016_Ekanelia_Success.lua) records these with tarAffed. Before it did,
    our own monkshood impatience reached the tracker only if the target printed the boredom line
    (414_Impatience_1), so PRIORITY 4, PRIORITY 7 and selectBiteVenom kept re-sending monkshood
    after it had worked.
    - Only the reaction's own result. The venom's own affliction comes from the bite line
      (009_Bite.lua, venom_to_aff), so listing it here would record it twice.
    - EKANELIA_TABLE.result is a display string ("nausea + paralysis"), so it is not parsed.
    - No scytherus: its reaction is camus DAMAGE, not an affliction.
    - Copied from EKANELIA_TABLE, which is our own: no reaction list is captured in kb/ (the game
      lists them with EKANELIA / EKANELIA STUDY <reaction>, kb/raw/wiki/Venom.wiki:383-391).
]]--
serpent.EKANELIA_RESULTS = {
    monkshood = {"impatience"},
    kalmia    = {"slickness"},
    loki      = {"nausea", "paralysis"},
    curare    = {"hypochondria"},
    aconite   = {"paranoia"},
    voyria    = {"confusion", "disrupted"},
}

-- THE MONKSHOOD IMPULSE ALWAYS CARRIES MASOCHISM, even onto a masochism the target holds. The
-- impulse's masochism lands in the same packet as the bite, so the reaction cannot miss it; a held
-- one can be focused away between our send and the bite. In the 2026-11-07 spar a round that
-- swapped it for another suggestion (kb/raw/logs/ours/2026-11-07_164635_Saibel.log:1344, "impulse
-- Saibel confusion monkshood") met her focus 56 ms later (:1345): the impulse and the bite landed
-- (:1364-1370) and no reaction line followed. All seven "impulse Saibel masochism monkshood"
-- rounds reacted (:1275, 1324, 1551, 1596, 1643, 1943, 2033). Not seen from our seat: an impulse
-- of a suggestion the target holds. On the victim's seat one that added nothing still bit
-- (kb/raw/logs/2026-11-01_claes_runewarden-vs-serpent_loss_azbErKcK.txt:3872-3876).
-- Used by selectImpulsePair (all conditionals met), PRIORITY 1.5, PRIORITY 4 and the keybind guard
-- below. PRIORITY 5's monkshood impulse is not a reaction round: impatience is already up there,
-- so its suggestion is free to push a mental.
local MONKSHOOD_SUGGESTION = "masochism"

-- True when `suggestion` is a conditional of `venom`'s reaction that the target lacks, i.e. the
-- impulse's suggestion is what lets the reaction fire (selectImpulsePair's one-missing case,
-- the lock_reinforce voyria/vertigo pair). The keybind override must not replace such a one.
-- Monkshood's masochism counts even when it is up (MONKSHOOD_SUGGESTION).
local function reactionNeeds(venom, suggestion)
    if venom == "monkshood" and suggestion == MONKSHOOD_SUGGESTION then return true end
    for _, ek in ipairs(EKANELIA_TABLE) do
        if ek.trigger == venom then
            for _, cond in ipairs(ek.conditionals) do
                if cond == suggestion then return not haveAff(suggestion) end
            end
            return false
        end
    end
    return false
end

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

-- Wall-clock seconds, like every other timer in this file (getEpoch: snapReadyTime, the darkshade
-- clock, pinshotSentAt). This was os.clock(), which Lua 5.1 defines as CPU time: it equals wall time
-- only under Windows' C runtime, so on Linux and macOS the 2.5 s impatience cooldown (live since
-- serpent/016 stamps it), the fratricide window and the 8.15 s rebounding pre-empt ran in CPU
-- seconds, which pass many times slower than real ones while the client waits on the game.
local function now()
    return getEpoch()
end

-- Seconds after an impulse during which fratricide will relapse it by itself, so impulsing the
-- same affliction again inside the window is wasted. 2.25 s is the relayed Serpent notes'
-- figure ("causes impulses (mentals only) to relapse at 2.25s",
-- kb/raw/players/serpent-2026-10-12.txt); the game's own record gives no number ("a short time
-- after being first introduced", kb/raw/live/affliction_show/fratricide.txt:7). Was 3.0, from
-- no stated source. Measured from our SEND (recordImpulse), as before.
local FRATRICIDE_RELAPSE = 2.25

--[[
    Two-pass impulse selection:
      Pass 1: respect fratricide's 2.25 s relapse window per aff (FRATRICIDE_RELAPSE)
      Pass 2: fallback ignoring cooldown (never returns nil)
    Optional excludeAff param for cases like curare ekanelia
    (don't re-impulse masochism when it's already the conditional).
]]--
local function selectImpulse(excludeAff)
    local hasFratricide = haveAff("fratricide")
        or (serpent.hypnosis and serpent.hypnosis.fratricideActive)
    -- No recklessness suggestion on a target that is not locked (recklessnessAllowed): both passes
    -- skip it, so the next suggestion in IMPULSE_PRIORITY goes instead.
    local noReck = not recklessnessAllowed()
    local function skip(aff)
        return aff == excludeAff or (noReck and aff == "recklessness")
    end

    -- Pass 1: respect fratricide cooldown
    for _, aff in ipairs(IMPULSE_PRIORITY) do
        if not skip(aff) and not haveAff(aff) then
            if hasFratricide then
                local lastTime = lastImpulsed[aff] or 0
                if (now() - lastTime) >= FRATRICIDE_RELAPSE then
                    return aff
                end
            else
                return aff
            end
        end
    end

    -- Pass 2: fallback — ignore fratricide cooldown rather than returning nil
    for _, aff in ipairs(IMPULSE_PRIORITY) do
        if not skip(aff) and not haveAff(aff) then
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
-- canAttemptImpatience() gates the send (PRIORITY 4). The flay round's shield-break impulse read
-- it too until the spar fixes of 2026-11-07, which took that impulse out of the flay round.
-- stampImpatienceCooldown() is called ONLY from the ekanelia confirm trigger
-- (serpent/016_Ekanelia_Success, on a monkshood reaction). Until that trigger called it,
-- nothing did, and the 2.5 s guard never closed.
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
-- Prevents snap from colliding with ekanelia delivery.
-- kalmia and impatience conditions override this -- they can't wait.
-- =============================================================================

local function getPostAction()
    local shouldSnap = hypSeal2 == true and snapped == false

    if shouldSnap then
        return "::snap " .. target, false
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
    "anorexia", "pacified", "nausea", "addiction",
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

-- Our target's class, lowercase, or "" (ataxia/ataxia/007, ataxia_targetClass: the target's NDB
-- class, else classDetect's attacker class when that attacker is the target).
local function targetClass()
    return ataxia_targetClass and ataxia_targetClass() or ""
end

-- Both class gates read the same class. Until the 2026-11-07 review this helper read the global
-- tarClass, which nothing assigned, so it was always true: the asthma-first order below never ran.
local function wantClumsiness()
    return ataxia_wantClumsiness(targetClass())
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
    -- No blademaster row. xentio gives clumsiness, and the class is immune (the user, 2026-11-08;
    -- ataxia_wantClumsiness). A Blademaster takes the order in pickVenom: asthma, then weariness.
    psion        = "aconite",
    alchemist    = "aconite",
    depthswalker = "eurypteria",
    druid        = "kalmia",
    sentinel     = "kalmia",
}

-- The TARGET's class (targetClass). This read classDetect.state.attackerClass first, the class of
-- whoever last hit us: one class line from a bystander, or the first attacker in a party fight
-- (the engine clears it only when it leaves a non-normal curingset), switched our target's lock
-- venom (a Magi got vernalius for a Monk's hit instead of notechis). Its fallback, tarClass, was
-- never assigned.
local function getClassLockAff()
    return CLASS_LOCK_VENOM[targetClass()]
end

-- =============================================================================
-- SLIKE (ANOREXIA) GATE
-- =============================================================================

local function slikeGateMet()
    if haveAff_tactical("anorexia") then return false end
    if haveAff("impatience") then return true end
    if tBals.focus == false and haveAff("asthma") then return true end
    return false
end

-- =============================================================================
-- LIGHTWALL CHECK
-- =============================================================================

-- A lightwall in our room (the dstab target stands in it): "It also drastically speeds up the
-- progression of the [darkshade] affliction for anyone standing in its presence"
-- (kb/raw/wiki/Subterfuge.wiki, Lightwall). ataxia.lightwall is the room flag: set from GMCP's room
-- items ("a lightwall", update_stuff/003) and the room line (misc_alerts/005). update_stuff/003
-- clears it on a room list without one and on a room Remove of "a lightwall".
-- Until the 2026-11-07 review this read haveAff("lightwall") / tAffs.lightwall, which nothing
-- writes, so the rule in pickVenom never fired; before v4.3.5 it read ataxia.lightwall.
local function hasLightwall()
    return (ataxia and ataxia.lightwall) and true or false
end

-- =============================================================================
-- UNIFIED VENOM SELECTION (pickVenom / pickVenomRelapse)
-- =============================================================================

local function pickVenom(exclude)
    local hasWea = haveAff("weariness")
    local hasClu = haveAff("clumsiness")
    local hasAst = haveAff("asthma")
    local needAst = not haveAff_tactical("asthma")

    if not haveAff("paralysis") and exclude ~= "curare" then return "curare" end

    -- Class-aware override (Track 4): once paralysis is locked, prefer the
    -- class-specific lock affliction that hits the target's weakest cure path.
    -- VENOM_TO_AFF lookup confirms the aff is missing before delivering.
    -- venomAllowed: a Depthswalker's eurypteria waits for a locked target; until then the order
    -- below picks the venom.
    local classVenom = getClassLockAff()
    if classVenom and exclude ~= classVenom and venomAllowed(classVenom) then
        local classAff = VENOM_TO_AFF[classVenom]
        if classAff and not haveAff(classAff) then
            return classVenom
        end
    end

    if wantClumsiness() then
        -- clumsiness > asthma > weariness
        if not hasClu and exclude ~= "xentio" then return "xentio" end
        if needAst and exclude ~= "kalmia" then return "kalmia" end
        if not hasWea and exclude ~= "vernalius" then return "vernalius" end
    else
        -- asthma > weariness (clumsiness is wasted on these classes)
        if needAst and exclude ~= "kalmia" then return "kalmia" end
        if not hasWea and exclude ~= "vernalius" then return "vernalius" end
    end

    if not haveAff("darkshade") and hasLightwall() and exclude ~= "darkshade" then return "darkshade" end
    if not haveAff_tactical("slickness") and hasAst and exclude ~= "gecko" then return "gecko" end
    if slikeGateMet() and exclude ~= "slike" then return "slike" end
    if exclude ~= "curare" then return "curare" end
    return "vernalius"
end

local function pickVenomGroup(exclude)
    -- 1. Paralysis first (blocks tree)
    if not haveAff("paralysis") and exclude ~= "curare" then return "curare" end
    -- 2. Asthma (blocks smoking, enables impulse)
    if not haveAff_tactical("asthma") and exclude ~= "kalmia" then return "kalmia" end
    -- 3. If asthma stuck -> slickness (blocks salves)
    if haveAff("asthma") and not haveAff_tactical("slickness") and exclude ~= "gecko" then return "gecko" end
    -- 4. Weariness (blocks fitness, enables impulse). Read at 0.70, as monkshoodCanReact does.
    if not haveAff_tactical("weariness") and exclude ~= "vernalius" then return "vernalius" end
    -- 5. Anorexia when impatience + slickness + asthma (blocks eating). The slickness may be the
    -- first venom's: after a gecko v1 (step 3) the same DSTAB lands it. Without that, v2 fell to
    -- the default curare onto paralysis already up; lock mode sends gecko slike on the same board.
    if haveAff("impatience") and (haveAff("slickness") or exclude == "gecko") and haveAff("asthma")
       and not haveAff_tactical("anorexia") and exclude ~= "slike" then return "slike" end
    -- 6. Fill remaining lock gaps
    if not haveAff("paralysis") and exclude ~= "curare" then return "curare" end
    if not haveAff_tactical("slickness") and exclude ~= "gecko" then return "gecko" end
    if not haveAff_tactical("weariness") and exclude ~= "vernalius" then return "vernalius" end
    if not haveAff_tactical("asthma") and exclude ~= "kalmia" then return "kalmia" end
    -- Default
    if exclude ~= "curare" then return "curare" end
    return "kalmia"
end

local function pickVenomRelapse(exclude)
    local hasWea = haveAff("weariness")
    local hasAst = haveAff("asthma")

    if not haveAff("paralysis") and exclude ~= "curare" then return "curare" end
    if not haveAff_tactical("asthma") and exclude ~= "kalmia" then return "kalmia" end
    if not hasWea and exclude ~= "vernalius" then return "vernalius" end
    if not haveAff_tactical("slickness") and hasAst and exclude ~= "gecko" then return "gecko" end
    if not haveAff_tactical("anorexia") and exclude ~= "slike" then return "slike" end
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
    0. A reaction that would add nothing is skipped (reactionSpent)
    1. If ALL conditionals met → return {suggestion=<useful>, venom=<trigger>}
       (monkshood: always masochism, MONKSHOOD_SUGGESTION)
    2. If exactly ONE trivial conditional missing → return {suggestion=<missing>, venom=<trigger>}
    3. Otherwise → nil
]]--

-- True when the reaction of `venom` and the bite's own venom would give nothing new: every result
-- in serpent.EKANELIA_RESULTS is up, and so is the venom's own affliction (VENOM_TO_AFF; loki's is
-- random, so it is not checked). Scytherus has no results entry (camus is damage), so it is never
-- spent. The group branch of PRIORITY 7 takes any pair, not only the impatience one (the spar's
-- group phase sent "impulse Saibel recklessness loki", kb/raw/logs/ours/2026-11-07_164635_Saibel.log:1388),
-- so without this it spent an impulse round on a loki reaction over nausea + paralysis already up,
-- or an aconite one over stupidity + paranoia, where its DSTAB gives two lock venoms.
local function reactionSpent(venom)
    local res = serpent.EKANELIA_RESULTS and serpent.EKANELIA_RESULTS[venom]
    if not res then return false end
    for _, r in ipairs(res) do
        -- Impatience at the lock's bar: the monkshood reaction is the only way to send it again,
        -- and a real reaction leaves disloyalty up, so this was what still blocked it at 0.667.
        if r == "impatience" then
            if not haveAff_tactical(r) then return false end
        elseif not haveAff(r) then
            return false
        end
    end
    local own = VENOM_TO_AFF[venom]
    return own == nil or own == "random" or haveAff(own)
end

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

        if ek.consumes or reactionSpent(ek.trigger) then
            -- Nothing new from this reaction, or it eats what we built (curare): try the next one.
        elseif #missing == 0 then
            -- ALL conditionals met → use nil-safe selectImpulse()
            -- instead of ek.trivials[1] which can be nil for venoms with
            -- no trivial conditionals (e.g. kalmia, scytherus). Monkshood keeps its masochism
            -- in the impulse (MONKSHOOD_SUGGESTION).
            local suggestion = (ek.trigger == "monkshood") and MONKSHOOD_SUGGESTION or selectImpulse(nil)
            return {suggestion = suggestion, venom = ek.trigger, label = ek.result}
        elseif #missing == 1 and #missingTrivials == 1
           and (missingTrivials[1] ~= "recklessness" or recklessnessAllowed()) then
            -- Exactly one trivial conditional missing → impulse completes it. Not when that
            -- conditional is recklessness and the target is not locked (recklessnessAllowed): the
            -- loop goes on to the next reaction instead.
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
      (No curare: its reaction needs fratricide + nausea + scytherus and consumes them; see
       EKANELIA_TABLE.)

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

    return nil
end

-- The monkshood reaction needs asthma, weariness and masochism together. An aurum eat, then a
-- plumbum eat, leaves impatience 0.667, asthma 0.667 and weariness 0.333: the eat took one of the
-- two, so no branch holds both and no reaction can fire. Sending the impulse repeats it for
-- nothing, and takes the round from the DSTAB that lands the piece back (2026-11-08 review).
local function monkshoodCanReact()
    return haveAff_tactical("asthma") and haveAff_tactical("weariness")
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
    -- Not while impatience is still up: selectImpulsePair does not check the reaction's result,
    -- so this was the one P7 path that re-sent monkshood onto impatience.
    if haveAff("slickness") and haveAff("anorexia") and not haveAff_tactical("impatience")
       and (not haveAff("impatience") or monkshoodCanReact()) then
        local monkshoodPair = selectImpulsePair()
        if monkshoodPair and monkshoodPair.label == "impatience" then
            return monkshoodPair
        end
    end

    -- Priority 2: Stupidity impulse (create focus pressure for when softlock isn't present).
    -- Not onto stupidity already up: the one stupidity impulse would add only its venom, in place
    -- of the relapse DSTAB's two. It waits, unspent, until the target cures the stupidity.
    if not serpent.state.stupidityImpulseSent and not haveAff("stupidity") then
        local venom
        if not haveAff("paralysis") then
            venom = "curare"
        elseif not haveAff("weariness") then
            venom = "vernalius"
        elseif not haveAff_tactical("asthma") then
            venom = "kalmia"
        elseif not haveAff_tactical("slickness") then
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
      5. (none: the curare reaction consumes scytherus, see EKANELIA_TABLE)
      6. confusion+recklessness present (loki ekanelia) → bite loki
         (nausea + paralysis)
      7. Fallback: paralysis missing → bite curare; asthma missing → bite kalmia;
         weariness missing → bite vernalius

    Returns {venom = "X", label = "Y"} or nil if no useful bite.
]]--
function selectBiteVenom(impulseCarriesMasochism)
    if not checkImpulseEligible() then return nil end  -- sileris/fangbarrier blocks bite

    -- 1. Scytherus stuck — keep biting for camus relapse damage
    if haveAff("scytherus") then
        return {venom = "scytherus", label = "camus damage"}
    end

    -- 2. Scytherus ekanelia ready (addiction + nausea)
    if haveAff("addiction") and haveAff("nausea") then
        return {venom = "scytherus", label = "deliver scytherus + camus"}
    end

    -- 3. Monkshood ekanelia ready → free impatience via bite (no EQ cost). Not onto impatience
    -- that is already up: the reaction's only product would be wasted. An impatience below the bar
    -- needs the reaction able to fire. Masochism too, unless the caller's impulse brings it (1.5).
    if haveAff("asthma") and haveAff("masochism") and haveAff("weariness")
       and not haveAff_tactical("impatience")
       and (not haveAff("impatience") or (monkshoodCanReact() and (impulseCarriesMasochism or haveAff_tactical("masochism")))) then
        return {venom = "monkshood", label = "impatience (ekanelia)"}
    end

    -- 4. Kalmia ekanelia ready → asthma + slickness
    if haveAff("clumsiness") and haveAff("weariness") and not haveAff("asthma") then
        return {venom = "kalmia", label = "asthma + slickness (ekanelia)"}
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

    -- A group target's coating is not known yet: strip it before the first bite. Slickness on the
    -- target means it is gone, however that slickness was recorded.
    if serpent.state.coatingUnknown and haveAff("slickness") then
        serpent.state.coatingUnknown = false
    end
    impulseReady = not hasSileris and not hasFangbarrier and not serpent.state.coatingUnknown
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

-- serpent.getFocusCooldownRemaining REMOVED (2026-11-08 review, X6): nothing called it, and its
-- 2 s / 5 s did not match trigger 398's focus clock (2 s, or 4.8 s under shadowmadness). The
-- target's focus balance is tBals.focus, which 398 keeps.

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
        -- herbs/003 (kelp / aurum, the target's eat). Until the 2026-11-07 review nothing called
        -- this with "kelp", so ekstatus showed 0 kelp cures.
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
        -- Priority 1: paralysis always. At truelock's 0.90 (haveAff_locked), not haveAff's 0.30:
        -- a paralysis a tree may have taken (0.875) is delivered again, or truelock is never
        -- reached (2026-11-08 review, F8).
        if not haveAff_locked("paralysis") then
            table.insert(envenomList, "curare")
            -- Second venom: class-specific lock aff or voyria to seal, then pickVenom's own pick.
            -- Never curare again: this DSTAB's first venom is curare. It went out as "curare curare"
            -- when the class lock affliction is paralysis (Occultist, Shaman, Jester) and when
            -- voyria was already up, and the second slot gave nothing.
            local v2
            local classLockAff = getLockingAffliction and getLockingAffliction("name")
            local classLockVenom = classLockAff and AFF_TO_VENOM[classLockAff]
            if classLockVenom and classLockVenom ~= "curare" and not haveAff(classLockAff)
               and venomAllowed(classLockVenom) then
                v2 = classLockVenom
            elseif not haveAff("voyria") then
                v2 = "voyria"
            else
                v2 = pickVenom("curare")
            end
            table.insert(envenomListTwo, v2)
            return
        end
        -- Priority 2: voyria reinforcement
        if not haveAff("voyria") then
            table.insert(envenomList, "voyria")
            if not haveAff("recklessness") and recklessnessAllowed() then
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
        table.insert(envenomListTwo,
            (not haveAff("recklessness") and recklessnessAllowed()) and "eurypteria" or "vardrax")
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
        -- `srd` on a target whose coating is not known: this strategy bites or impulses every
        -- round it can, and a bite needs the coating gone, so the dstab strips it with slickness.
        if serpent.state.coatingUnknown and not haveAff("slickness") then
            v1 = "gecko"
        elseif not haveAff("slickness") and haveAff("asthma") then
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

-- THE FLAY'S VENOM WHILE THE KALMIA REACTION WAITS (PRIORITY 1, paralysis up). The flay carries
-- one venom, and since the 2026-11-07 spar fixes it is the round's only balance action, so that
-- venom is the round's whole affliction. On clumsiness + weariness + paralysis this sent
-- vernalius, onto the weariness already up: the round added nothing (2026-11-08 review, F31). It is
-- now the first of these whose affliction is missing and that venomAllowed lets through:
--   pickVenom("kalmia")  pickVenom's own pick past kalmia: the class venom, the lightwall darkshade,
--                        slike once its gate is met;
--   slike                anorexia: no eat, so no kelp can take the clumsiness or weariness that
--                        the next round's reaction needs (sent here before slikeGateMet's
--                        impatience, on purpose);
--   euphorbia, vardrax, aconite, notechis   pressure that leaves the reaction alone.
-- Never asthma: the next round's kalmia bite gives it, and with it up kalmiaEkaneliaMet is false.
-- Vernalius only when every one of them is up.
local KALMIA_FLAY_FILL = { "slike", "euphorbia", "vardrax", "aconite", "notechis" }
local function kalmiaFlayVenom()
    local cands = { pickVenom("kalmia") }
    for _, v in ipairs(KALMIA_FLAY_FILL) do cands[#cands + 1] = v end
    for _, v in ipairs(cands) do
        local aff = VENOM_TO_AFF[v]
        if aff and aff ~= "asthma" and aff ~= "random" and not haveAff(aff) and venomAllowed(v) then
            return v
        end
    end
    return "vernalius"
end

--[[
    Execute the attack based on current strategy and venom selection.

    Priority order:
    1. Flay (strip shield/rebounding), alone: an impulse spends balance too
    2. Execute with the whip (truelock + prone + joint gate)
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
    --
    -- Only for a rebounding a game line SHOWED (serpent.state.reboundingSeen). A new target is
    -- assumed to have rebounding (016 targetresetafflictionslevi), and in the 2026-11-07 spar the
    -- first flay found "a non-existent aura of rebounding" (FL 305). That drop armed the clock,
    -- and the pre-empt fired 9.87 s later (FL 566) for a rebounding that never existed.
    -- Our flay's strip line stamps the clock itself, at the strip (serpent.onReboundingFlayed);
    -- this stamps a drop that only a raise or rebound line showed.
    if serpent.state.lastRebounding and not hasRebounding and serpent.state.reboundingSeen then
        lastReboundingFlay = now()
        serpent.state.reboundingSeen = false  -- the next arm needs a new raise or strip line
    end
    serpent.state.lastRebounding = hasRebounding

    -- Weapon wielding prefixes (single command, game assigns hands)
    local wieldWhip = "wield shield whip" .. sp
    local wieldDirk = "wield shield dirk" .. sp

    -- canUseSecondary: prevents snap from colliding with ekanelia delivery.
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
            -- The kalmia reaction waits for the next round (the impulse spends balance too, so
            -- it cannot ride with the flay). The flay does not give asthma, so the reaction
            -- stays possible. With paralysis up the venom is one that adds an affliction
            -- (kalmiaFlayVenom); it was vernalius, onto the weariness the reaction needs.
            flayVenom = not haveAff("paralysis") and "curare" or kalmiaFlayVenom()
        elseif not haveAff("paralysis") then
            flayVenom = "curare"
        elseif not haveAff("weariness") then
            flayVenom = "vernalius"
        elseif wantClumsiness() and not haveAff("clumsiness") then
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

        -- ONE BALANCE ACTION PER ROUND. This branch used to chain an impulse behind the flay
        -- (the kalmia reaction, or the monkshood "shield-break"), on the belief that an impulse
        -- uses only equilibrium. The 2026-11-07 spar shows every venom impulse spending BOTH:
        -- "Equilibrium used: 1.44s." and "Balance used: 1.7s." (13 of 13, e.g. FL 1270 + FL 1278).
        -- A second balance action after a spender is refused: the opener's flay after the
        -- pinshot got "You must regain balance first." (FL 235, FL 257). So the flay goes alone,
        -- and the next round sends the impulse (PRIORITY 3 or 4) once the defence is down. An
        -- equilibrium action (hypnosis, snap) can still go with it.
        if eqAction and canUseSecondary then
            if eqAction:find("^snap") then
                cmd = wieldWhip .. "flay " .. target .. " " .. defense .. " " .. flayVenom .. sp .. eqAction
            else
                cmd = wieldWhip .. eqAction .. sp .. "flay " .. target .. " " .. defense .. " " .. flayVenom
            end
        else
            cmd = wieldWhip .. "flay " .. target .. " " .. defense .. " " .. flayVenom
        end

        serp_sendAttack(cmd, preAtk)
        return
    end

    -- NOTE: Sileris/fangbarrier does NOT need flaying — dstab works through it.
    -- Only impulse/bite is blocked. checkImpulseEligible() handles this.

    -- --------------------------------------------------------
    -- PRIORITY 2: Execute a truelocked, PRONE target, with the whip.
    -- "While wielding a whip, you may attempt to execute a prone victim." (Subterfuge, Execute;
    -- kb/classes/serpent.md:64 and :122, 2.00 s of balance). This sent "execute <target>" to a
    -- STANDING target with the dirk in hand, and sent a prone one "wield shield scimitar::behead"
    -- (BEHEAD is on none of the Serpent's skill pages) with no joint gate (2026-11-08 review, F10).
    -- A prone target is the adder's trip (serpent/009_Prone). Any strategy, as the behead was: a
    -- kill that is ready wins.
    -- Joint-probability gate: the five lock affs and prone >= 90% likely together in one tracker
    -- branch, so the kill is not gambled on a bluff (prone is simple-tracked, so it reads 1.0).
    -- A standing truelocked target gets no finisher here: the round falls through to the
    -- lock_reinforce/finish DSTAB, which keeps the lock until the adder trips them. Whether BEHEAD
    -- (a paralysed, standing victim died to a Shaman's in Mystor's log) or EXECUTE on a standing
    -- target works for us is open: settle it with AB SUBTERFUGE EXECUTE before adding a branch.
    -- --------------------------------------------------------
    if truelock and haveAff_locked("prone")
        and (not getStateProbabilityV3
            or getStateProbabilityV3({"anorexia", "asthma", "slickness", "impatience", "paralysis", "prone"}) >= 0.90) then
        serp_sendAttack(wieldWhip .. "execute " .. target, preAtk)
        return
    end

    -- --------------------------------------------------------
    -- PRIORITY 1.5: Rebounding-reapply pre-empt. Rebounding returns ~8.5s after it
    -- was stripped; fire one impulse+bite through the gap just before it reapplies,
    -- instead of eating a reflected hit next round. Reaching here guarantees no
    -- shield/rebounding is up (the flay block above returns first). Placed AFTER the
    -- finisher so a ready kill always wins. Fires once per drop (disarms the timer).
    -- Not while a hypnosis step is due (eqAction: suggest, seal, snap, hypnotise): the impulse
    -- spends equilibrium, so the step was skipped that round (2026-11-08 review, F32), as every
    -- other impulse below already avoids. The clock stays armed for a round with no step.
    -- --------------------------------------------------------
    local eqAction = getEqAction()

    if lastReboundingFlay > 0
        and (now() - lastReboundingFlay) >= 8.15
        and not eqAction
        and checkImpulseEligible() then
        local bite = selectBiteVenom(true)
        local biteVenom = (bite and bite.venom) or pickVenom(nil)
        -- Chosen after the bite: a monkshood bite is the impatience reaction (MONKSHOOD_SUGGESTION).
        local impAff = (biteVenom == "monkshood") and MONKSHOOD_SUGGESTION
            or selectImpulse(nil) or "masochism"
        recordImpulse(impAff)
        lastReboundingFlay = 0  -- fire once per reapply cycle
        serp_sendAttack(wieldDirk .. "impulse " .. target .. " " .. impAff .. " " .. biteVenom, preAtk)
        return
    end

    -- --------------------------------------------------------
    -- PRIORITY 3: Kalmia ekanelia — override canUseSecondary, guarded
    -- by kalmiaEkaneliaMet() which checks asthma not already present.
    -- recordImpulse() called on every kalmia impulse send.
    -- --------------------------------------------------------
    if kalmiaEkaneliaMet() and canUseSecondary and not eqAction then
        local impulseAff = selectImpulse(nil)
        recordImpulse(impulseAff)
        serp_sendAttack(wieldDirk ..
            "impulse " .. target .. " " .. impulseAff .. " kalmia", preAtk)
        return
    end

    -- --------------------------------------------------------
    -- PRIORITY 4: Impatience delivery — canAttemptImpatience() gates send.
    -- stampImpatienceCooldown() called from ekanelia confirm trigger, not here.
    -- canUseSecondary overridden by impatienceConditionsMet().
    -- checkImpulseEligible(): sileris/fangbarrier stops the monkshood bite, as for every impulse
    -- (scytherus mode's PRIORITY 7 impulse was the last without it, until v4.7.420). Without it
    -- this branch sent a blocked impulse every round and returned before the gecko strip further
    -- down could ever clear the barrier.
    -- --------------------------------------------------------
    -- During relapse_lock, use the relaxed condition check (asthma+weariness sufficient).
    -- Normal lock mode keeps the third-condition gate (fratricide/hypochondria/scytherus/slickness).
    local impatienceReady = (serpStrategy == "relapse_lock")
        and impatienceConditionsRelapse()
        or impatienceConditionsMet()
    if impatienceReady and canAttemptImpatience() and canUseSecondary and not eqAction
       and checkImpulseEligible() then
        -- Masochism even when it is believed up (MONKSHOOD_SUGGESTION): this swapped it for
        -- selectImpulse("masochism"), and the reaction then hung on a masochism she could focus away.
        local impulseAff = MONKSHOOD_SUGGESTION
        recordImpulse(impulseAff)
        serp_sendAttack(wieldDirk ..
            "impulse " .. target .. " " .. impulseAff .. " monkshood", preAtk)
        return
    end

    -- --------------------------------------------------------
    -- PRIORITY 5: Focus lock push (fratricide + 4 mentals + focus bal down)
    -- Gated on checkImpulseEligible() like PRIORITY 4: the impulse rides a monkshood bite.
    -- --------------------------------------------------------
    if focusLockReady() and canUseSecondary and not eqAction and checkImpulseEligible() then
        local impulseAff = selectImpulse(nil)
        recordImpulse(impulseAff)
        serp_sendAttack(wieldDirk ..
            "impulse " .. target .. " " .. impulseAff .. " monkshood", preAtk)
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
    --   2. Voyria (anorexia+impatience present, vertigo missing) — confusion+disrupted, once, and
    --      only at TRUELOCK. lock_reinforce also runs at hardlock in the relapse phase, where
    --      paralysis is missing or doubtful (a tree leaves it at 0.875, under truelock's 0.90).
    --      There this impulse went every round and the DSTAB's curare never did, so the lock never
    --      reached truelock or the finish (2026-11-08 review, F8). Below truelock the round is now
    --      that DSTAB: curare plus the class venom or voyria (selectVenoms, lock_reinforce).
    --   3. Normal impatience if somehow not yet landed
    if serpStrategy == "lock_reinforce" and not eqAction and checkImpulseEligible() then
        if haveAff("addiction") and haveAff("nausea") and not haveAff("scytherus") then
            -- Scytherus ekanelia: camus damage spike
            impulsePair = {suggestion = selectImpulse(nil), venom = "scytherus", label = "camus"}
            useImpulse = true
        elseif truelock and not serpent.state.voyriaSent
           and haveAff("anorexia") and haveAff("impatience") then
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
    -- checkImpulseEligible() like every other impulse: the scytherus rides a bite, and by our rule
    -- sileris/fangbarrier stops a bite. This was the one impulse without it (until v4.7.420), so
    -- with the barrier up this mode sent a blocked impulse every round instead of its dstab.
    elseif serpOffenseMode == "scytherus" and serpStrategy == "scytherus_attack"
       and not useBite and not eqAction and not haveAff("scytherus")
       and checkImpulseEligible() then
        impulsePair = {suggestion = selectImpulse(nil), venom = "scytherus", label = "camus"}
        useImpulse = true

    -- Group mode: impulse impatience when weariness + asthma stuck, impatience missing
    elseif serpOffenseMode == "group" and not eqAction and checkImpulseEligible()
       and not haveAff("impatience") then
        impulsePair = selectImpulsePair()
        if impulsePair then
            useImpulse = true
        end

    -- Normal impulse for impatience (gated by shouldDeliverImpatience). At the lock's bar: this is
    -- also where group mode comes for an impatience a cure left at 0.667, and there only the
    -- monkshood pair (or an opportunistic reaction) goes, not the group branch's any pair.
    elseif not eqAction and not haveAff_tactical("impatience") and checkImpulseEligible()
       and (not haveAff("impatience") or monkshoodCanReact()) then
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
    if not useImpulse and not eqAction and not haveAff_tactical("impatience")
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
            if eqAction:find("^snap") then
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
        if eqAction:find("^snap") then
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

    -- Keybind-requested suggestion override. Never over a suggestion the reaction needs: for the
    -- monkshood impatience pair that suggestion is the masochism, and replacing it means the
    -- reaction cannot fire. (Nothing in the package sets hSuggRequest, so this only applies after
    -- a manual `lua hSuggRequest = ...`.)
    if useImpulse and hSuggActive ~= "" and impulsePair
       and not reactionNeeds(impulsePair.venom, impulsePair.suggestion) then
        recordImpulse(hSuggActive)
        cmd = wieldDirk .. "impulse " .. target .. " " .. hSuggActive .. " " .. impulsePair.venom
    end

    serp_sendAttack(cmd, preAtk)
end

--[[
    Determine the best EQ action for this round.
    Returns the eq command string or nil.
    Priority: snap > hypnosis step
    Our own SHRUGGING is not an offence step: ataxia_lockBreak (can(x)/003) sends it.
]]--
function getEqAction()
    -- 1. Snap: asthma on target + snap ready + not yet snapped
    if serpent.hypnosis.canSnap() then
        return "snap " .. target
    end

    -- 2. Hypnosis step: active hypnosis chain
    if serpent.hypnosis.isActive() then
        local hypCmd = serpent.hypnosis.getCommand()
        if hypCmd then
            return hypCmd
        end
    end

    -- 3. Hypno lock / hypnosis mode: start chain from idle
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
    The opening commands (Track 1), for the first attack on a target. Returns two lists:
      bow    -- remove and wield the bow, then PINSHOT. Empty when the bow opener is off or a
                pinshot is already in the target.
      sigils -- the sigil drop, when useSigils is on.
    buildRound puts the round's own wield and attack STRAIGHT AFTER the pinshot. The pinshot
    spends balance, so the game holds each later command that needs balance in its balance queue
    and runs them at the recovery. In the 2026-11-07 spar it held six (wield, order adder, g body,
    g gold, stand, wield) and refused the flay behind them without holding it ("You must regain
    balance first." with no "added" line, FL 235-257), so the coating strip slipped a whole round.
    With the wield and the attack first in that queue, the attack runs at the recovery.
]]--
local function buildOpener()
    local bow, sigils = {}, {}
    if not serpent.config.useOpener then return bow, sigils end

    -- Pinshot: only if the bow opener is on and no pinshot is already in the target.
    -- Pinshot REQUIRES a body part; "foot" is the standard impale target
    -- (matches the inbound trigger pattern "Your arrow slams into the foot of ...").
    -- tpinshot is the NAME the last pinshot went into, for its 21 s (serpent/002_Pinshot). It was
    -- true for anyone, so a new target within 21 s of a pinshot in the old one got no pinshot
    -- (2026-11-08 review, F33).
    local pinned = type(tpinshot) == "string" and type(target) == "string"
        and tpinshot:lower() == target:lower()
    -- No pinshot on a group press (`sr`, `srd`): the user's rule, 2026-11-11 ("Not needed. Waste
    -- of balance."). In the 2026-11-11 group log it ran again at each target switch and each
    -- 21 s pin end: 15 pinshots, about 42 s of balance, more than all our DSTABs.
    if serpent.config.useBowOpener and not pinned and not serpent.state.groupPress then
        local b = serpent.config.bowName or "bow"
        bow = { "remove " .. b, "wield " .. b, "pinshot " .. target .. " foot" }
        serpent.state.pinshotSentAt = getEpoch()
    end

    -- Sigil deployment: optional, requires inventory of sigils.
    if serpent.config.useSigils and not serpent.state.sigilDeployed then
        sigils = { "drop incandescent sigil", "attach monolith sigil to incandescent sigil" }
        serpent.state.sigilDeployed = true
    end

    return bow, sigils
end

-- =============================================================================
-- ROUND ASSEMBLY
-- =============================================================================

-- The verbs that spend our balance. The first one in the offence's command is the round's attack.
local ATTACK_VERBS = {
    dstab = true, doublestab = true, flay = true, impulse = true, bite = true,
    behead = true, execute = true,
}

-- combatQueue()'s three standing commands (ataxia/003). In the 2026-11-07 spar they did nothing in
-- 39 of 39 rounds: 'I see no "body" to take.', 'I see no "gold" to take.' and 'You are not fallen
-- or kneeling.'.
local IDLE_PRE = { ["g body"] = true, ["g gold"] = true, stand = true }

-- `s` split on the separator `sp`. Each piece is trimmed, and empty pieces are left out.
local function splitCommands(s, sp)
    local out = {}
    if type(s) ~= "string" or s == "" then return out end
    if type(sp) ~= "string" or sp == "" then
        local only = s:match("^%s*(.-)%s*$")
        if only ~= "" then out[1] = only end
        return out
    end
    local start = 1
    while true do
        local i, j = s:find(sp, start, true)
        local piece = s:sub(start, i and (i - 1) or #s):match("^%s*(.-)%s*$")
        if piece ~= "" then out[#out + 1] = piece end
        if not i then break end
        start = j + 1
    end
    return out
end

local function firstWord(piece)
    return piece:lower():match("^(%S+)")
end

-- OUR WEAPONS BY ITEM ID. Attack-first sends a wield only when GMCP shows the weapon is not in
-- hand. GMCP gives the names of the wielded items (ataxiaTemp.wieldedItems, basher/015), but the
-- user's dirk and whip are artefacts ("Thoth's fang", "Elentari's Scourge"), so a name does not
-- say which weapon it is. So the id is learned: at the round after one that wielded
-- "shield <weapon>", the one wielded item that is not the shield is that weapon, if it was not in
-- hand before that wield. Transient (ataxiaTemp), so a restart learns it again.
local function weaponIds()
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.serpentWeaponIds = ataxiaTemp.serpentWeaponIds or {}
    return ataxiaTemp.serpentWeaponIds
end

local function isShieldName(name)
    return type(name) == "string" and name:lower():find("shield", 1, true) ~= nil
end

-- The ids of the wielded items that are not the shield, or nil when GMCP has not shown the hands.
local function heldWeapons()
    local inHand = ataxiaTemp and ataxiaTemp.wieldedItems
    if type(inHand) ~= "table" then return nil end
    local out = {}
    for id, name in pairs(inHand) do
        if not isShieldName(name) then out[tostring(id)] = true end
    end
    return out
end

local function learnWeapon()
    local kw, before = serpent.state.lastWieldKw, serpent.state.lastWieldBefore
    serpent.state.lastWieldKw, serpent.state.lastWieldBefore = nil, nil
    local inHand = ataxiaTemp and ataxiaTemp.wieldedItems
    if not kw or type(before) ~= "table" or type(inHand) ~= "table" then return end
    local other, count, shield = nil, 0, false
    for id, name in pairs(inHand) do
        if isShieldName(name) then
            shield = true
        else
            other, count = tostring(id), count + 1
        end
    end
    -- The bow takes both hands, so a shield in hand also shows that the wield ran. The item must
    -- be NEW: when the same item is still in hand, the wield failed or changed nothing, and that
    -- item is not proven to be the weapon. A wrong id would hold back a wield that is needed.
    if shield and count == 1 and not before[other] then
        local ids = weaponIds()
        for k, v in pairs(ids) do
            if v == other then ids[k] = nil end
        end
        ids[kw] = other
    end
end

-- Ask GMCP for the inventory once, so the next rounds know what is in hand.
local function askInventory()
    ataxiaTemp = ataxiaTemp or {}
    if not ataxiaTemp.serpentInvAsked and sendGMCP then
        ataxiaTemp.serpentInvAsked = true
        pcall(sendGMCP, "Char.Items.Inv")
    end
end

-- True when this wield ("wield shield dirk") must go before the attack: GMCP shows one of its
-- items not in hand. An unknown hand counts as not in hand, as in basher/015: a wrong weapon costs
-- the whole round, and an extra wield costs only a few milliseconds.
local function wieldNeeded(piece)
    local inHand = ataxiaTemp and ataxiaTemp.wieldedItems
    if type(inHand) ~= "table" then
        askInventory()
        return true
    end
    for word in piece:lower():gmatch("%S+") do
        if word ~= "wield" then
            local id = weaponIds()[word]
            local held = false
            if id then
                held = inHand[id] ~= nil
            else
                for _, name in pairs(inHand) do
                    if type(name) == "string" and name:lower():find(word, 1, true) then
                        held = true
                        break
                    end
                end
            end
            if not held then return true end
        end
    end
    return false
end

-- =============================================================================
-- THE DEATH ADDER
-- Every round sent "order adder kill <target>". In the 2026-11-07 spar no adder was out (user:
-- "we have an adder I just didnt put it out there"), and the game refused all 39 orders with five
-- different texts. Trigger 641 read three of them as "the target left the room" and started the
-- TargetOutOfRoom timer, which erased target afflictions seven times and reset the tracker twice.
-- So the order goes only when our adder is here: a snake in the room (GMCP Char.Items, location
-- "room"), or the mount we ride is the adder (basher/013).
-- =============================================================================

-- The snake's name, from the basher's class-pet list (basher/001, ataxiaBasher_CLASS_PETS.Serpent).
local function snakeWords()
    local pets = ataxiaBasher_CLASS_PETS and ataxiaBasher_CLASS_PETS.Serpent
    if type(pets) == "table" and #pets > 0 then return pets end
    return { "death adder" }
end

-- True when the name is the snake's (the mount check has only a name).
local function isSnake(name)
    if type(name) ~= "string" then return false end
    local low = name:lower()
    if low:find("corpse", 1, true) then return false end
    for _, w in ipairs(snakeWords()) do
        if type(w) == "string" and w ~= "" and low:find(w:lower(), 1, true) then return true end
    end
    return false
end

-- A room item is our snake only when GMCP marks it a living monster: attrib holds "m" and no "d"
-- (dead). An item such as "a death adder fang" or "a statue of a death adder" has no "m", and an
-- order to it is refused like the 39 in the spar. Our own adder can carry "x" (do not attack),
-- so "x" does not count against it (update_stuff/003 drops "x" only from the denizens).
local function isRoomSnake(name, attrib)
    if type(attrib) ~= "string" or not attrib:find("m", 1, true) then return false end
    if attrib:find("d", 1, true) then return false end
    return isSnake(name)
end

-- GMCP room contents: keep the snakes in our room, by item id. A List for the room replaces the
-- picture (a new room sends one); Add and Remove change one item.
function serpent.onRoomItems(event)
    local items = gmcp and gmcp.Char and gmcp.Char.Items
    if type(items) ~= "table" then return end
    if event == "gmcp.Char.Items.List" then
        local l = items.List
        if type(l) ~= "table" or l.location ~= "room" then return end
        local here = {}
        for _, it in pairs(l.items or {}) do
            if type(it) == "table" and isRoomSnake(it.name, it.attrib) then here[tostring(it.id)] = it.name end
        end
        serpent.state.snakesHere = here
        serpent.state.roomListSeen = true
        return
    end
    local key = (event == "gmcp.Char.Items.Add" and "Add") or (event == "gmcp.Char.Items.Remove" and "Remove")
    local m = key and items[key]
    if type(m) ~= "table" or m.location ~= "room" or type(m.item) ~= "table" then return end
    serpent.state.snakesHere = serpent.state.snakesHere or {}
    local id = tostring(m.item.id)
    if key == "Add" and isRoomSnake(m.item.name, m.item.attrib) then
        serpent.state.snakesHere[id] = m.item.name
    else
        serpent.state.snakesHere[id] = nil
    end
end

-- We ride our adder: basher/013 keeps the mounted belief, and the name and id of the mount.
local function ridingSnake()
    if not (ataxiaBasher_isMounted and ataxiaBasher_isMounted()) then return false end
    if isSnake(omount) then return true end
    local id = ataxia.settings and ataxia.settings.user and ataxia.settings.user.mount
    local names = ataxiaBasher and ataxiaBasher.mountIds
    if type(names) ~= "table" or not id then return false end
    return isSnake(names[tonumber(id)])
end

function serpent.adderHere()
    if next(serpent.state.snakesHere or {}) ~= nil then return true end
    return ridingSnake()
end

-- "order adder kill <target>" when the adder is here. Else nil, with one note per target: the
-- changed-target handler clears the note, and so does an adder that comes back.
-- No room list since the load (a login, or a reload before the first move): ask GMCP for the
-- room's items once. The answer is a Char.Items.List for the room, which onRoomItems reads.
local function askRoom()
    ataxiaTemp = ataxiaTemp or {}
    if not serpent.state.roomListSeen and not ataxiaTemp.serpentRoomAsked and sendGMCP then
        ataxiaTemp.serpentRoomAsked = true
        pcall(sendGMCP, "Char.Items.Room")
    end
end

local function adderOrder()
    if serpent.adderHere() then
        serpent.state.adderNotedFor = nil
        return "order adder kill " .. target
    end
    askRoom()
    if serpent.state.adderNotedFor ~= target then
        serpent.state.adderNotedFor = target
        Algedonic.Echo("<yellow>ADDER<white>: no death adder here, so the rounds go without 'order adder kill'.")
    end
    return nil
end

--[[
    The round, as one line for send(). `cmd` is the offence's own command (its wield, its attack,
    and an equilibrium action if any). `pre` is combatQueue()'s prefix. `block` is the exit-block
    command, or nil.

    MUDLET SPLITS THE LINE ON THE SEPARATOR, so the game gets one command per piece. Only the FIRST
    piece goes into "queue addclear freestand"; the other pieces go raw, one after the other. The
    offence sends only with balance up, so that queued piece runs at once. A raw piece that needs
    balance and comes after the attack is refused and then HELD by the game ("... was added to your
    balance queue."), and the game runs it at the next recovery (FL 235-255).

    TWO ORDERS (aconfig serpent attackfirst):
      off (the default): purge, the adder order, combatQueue's commands, then the offence's wield
          and attack (the order before the 2026-11-07 spar, with the adder fix).
      on: the attack goes before purge, the adder order, the sigils and combatQueue's commands.
          Only these go in front of it:
            - a raw stand, only when we are prone. It goes in front of the queue command, because a
              freestand entry cannot run while we are prone (HELP 4.6.1);
            - the wield, only when GMCP shows the weapon is not in hand (wieldNeeded);
            - an equilibrium step that the offence puts before the attack (suggest, seal,
              hypnotise). Since 2026-10-23 a SUGGEST used off balance takes a fixed equilibrium
              that nothing can modify, and a SEAL used off balance takes an unmodified equilibrium
              (kb/changes/2026-10-23_classleads.md). Before the attack, they go on balance.
          A step the offence puts after the attack (snap) stays after it.
          Why: in the 2026-11-07 spar the game answered the second and later commands of a send
          about 0.09 s after the first, so an attack sent after six commands landed about 0.12 s
          later on our clock. Whether it also lands later at the server is open (lens_costs F2,
          F6). This setting is the probe.
    THE FIRST ROUND on a target opens with DISPEL in both orders, because a reflection would take
    the attack. With the bow opener on it then sends the PINSHOT, and the round's wield and attack go
    straight after it (buildOpener). That round leaves out combatQueue's three idle commands.
    THE EXIT BLOCK goes LAST in every order, after the attack (see serp_sendAttack).
]]--
local function buildRound(cmd, pre, block)
    local sp = ataxia.settings.separator
    local cmdPieces = splitCommands(cmd, sp)
    local prePieces = splitCommands(pre, sp)
    local prone = (ataxia.afflictions and ataxia.afflictions.prone) and true or false
    local attackFirst = (ataxia.settings.serpentattackfirst == true)

    learnWeapon()

    -- The offence's command: its wield (before the attack), the other pieces before the attack,
    -- its attack, and the pieces after the attack.
    local wieldPiece, attackPiece, beforeAttack, afterAttack = nil, nil, {}, {}
    for _, p in ipairs(cmdPieces) do
        local w = firstWord(p)
        if w == "wield" and not wieldPiece and not attackPiece then
            wieldPiece = p
        elseif ATTACK_VERBS[w] and not attackPiece then
            attackPiece = p
        elseif attackPiece then
            afterAttack[#afterAttack + 1] = p
        else
            beforeAttack[#beforeAttack + 1] = p
        end
    end

    local order = adderOrder()
    local bow, sigils = {}, {}
    if serpent.state.firstAttack then
        bow, sigils = buildOpener()
        serpent.state.firstAttack = false
    end

    local pieces, rawFirst = {}, nil
    local function add(p) if p then pieces[#pieces + 1] = p end end
    local function addAll(list) for _, p in ipairs(list) do add(p) end end

    if not serpent.state.dispelSent then
        add("dispel " .. target)
        serpent.state.dispelSent = true
    end

    if #bow > 0 then
        -- The opening round, in both orders. Purge needs no balance: in the spar it ran just after
        -- the pinshot spent balance, with no hold (FL 235, FL 240). A stand goes while balance is
        -- still up. So neither takes a held slot.
        add("purge")
        if prone then add("stand") end
        addAll(bow)
        if not wieldPiece then add("wield shield dirk") end  -- the bow must leave our hands
        addAll(cmdPieces)
        add(order)
        addAll(sigils)
        for _, p in ipairs(prePieces) do
            if not IDLE_PRE[p:lower()] then add(p) end
        end
    elseif attackFirst and attackPiece then
        if prone then rawFirst = "stand" end
        if wieldPiece and wieldNeeded(wieldPiece) then add(wieldPiece) end
        addAll(beforeAttack)   -- suggest, seal or hypnotise: they must go on balance
        add(attackPiece)
        addAll(afterAttack)    -- snap
        add("purge")
        add(order)
        addAll(sigils)
        for _, p in ipairs(prePieces) do
            if not (rawFirst and p:lower() == "stand") then add(p) end
        end
    else
        addAll(sigils)
        add("purge")
        add(order)
        addAll(prePieces)
        addAll(cmdPieces)
    end
    add(block)

    -- The weapon this round wields, and what was in hand before it, for learnWeapon at the next
    -- round.
    for _, p in ipairs(pieces) do
        local kw = p:lower():match("^wield shield (%S+)$")
        if kw then
            serpent.state.lastWieldKw = kw
            serpent.state.lastWieldBefore = heldWeapons()
        end
        -- The suggestion this round gives, for the success line ("You issue the suggestion, ...",
        -- the suggestGiven trigger below). That line names no suggestion, and the trigger read
        -- ataxiaTemp.suggestAff, which queue_Scan sets only from a QUEUED command's run line. In
        -- the default order the queued piece is purge or dispel (kb/raw/logs/ours/
        -- 2026-11-07_164635_Saibel.log:225, "Running queued freestand command: DISPEL SAIBEL"), so
        -- the suggest went raw, fratricideApplied never became true, the fratricide suggest went
        -- again every round, and the snap never recorded fratricide (2026-11-08 review, F29).
        local sug = p:lower():match("^suggest %S+ (%S+)$")
        if sug then serpent.hypnosis.pendingSuggestion = sug end
    end

    local line = "queue addclear freestand " .. table.concat(pieces, sp)
    if rawFirst then line = rawFirst .. sp .. line end
    return line
end

--[[
    Send one round if the target is in the room. buildRound puts it together, and attackInFlight
    holds the next dispatch until balance comes back. `cmd` is the offence's own command and `pre`
    is combatQueue()'s prefix; they come apart so that attack-first can move the prefix.
    Per-round denial (Track 3): exit-block rotated through gmcp.Room.Info.exits.
]]--
function serp_sendAttack(cmd, pre)
    if not table.contains(ataxia.playersHere, target) then
        Algedonic.Echo("<red>Target not in room!<white>")
        return
    end

    -- EXIT BLOCK (serpent.config.useExitBlock, off by default; one new direction each 5 s).
    -- No log shows what BLOCK costs. If it spends balance, a block in front of the round makes the
    -- attack the second balance action: the game refuses it and holds it to the next recovery, so
    -- the attack slips a whole balance. It used to go out raw just before the round, for that
    -- reason, on the belief that the whole round was queued. Only the round's first piece is
    -- queued (buildRound), so the block now goes LAST in the round, after the attack. The attack
    -- then never waits for it. If BLOCK needs balance, the game holds it and runs it at the next
    -- recovery; if BLOCK also spends balance, the NEXT round's attack waits for it.
    local block
    if serpent.config.useExitBlock then
        local epoch = getEpoch()
        if (epoch - serpent.state.lastBlockSentAt) >= 5 then
            local dir = nextExitToBlock()
            if dir then
                block = "block " .. dir
                serpent.state.blockedExits[dir] = epoch
                serpent.state.lastBlockSentAt = epoch
            end
        end
    end

    send(buildRound(cmd, pre or "", block))
    serpent.state.attackInFlight = true
    -- For the no-spend watchdog in serp_ekanelia_offense: when the round went, and whether GMCP
    -- has shown our balance down since (the balRecovery handler below).
    serpent.state.attackSentAt = getEpoch()
    serpent.state.balSpentSinceSend = false
end

-- =============================================================================
-- MAIN OFFENSE FUNCTION
-- =============================================================================

-- A PART NAME IS COMPLETED BEFORE THE ROUND IS BUILT. `t sai` keeps "Sai" as the target (016
-- switchTarget), and serp_sendAttack sends only when ataxia.playersHere holds the target exactly,
-- so with "Saibel" listed every press printed "Target not in room!" until a line about her went
-- through isTargeted (2026-11-08 review, F35). When exactly one listed name starts with the target
-- (case ignored), it goes through isTargeted, which completes a part name and refuses a full one
-- (016:243-249): target Kai, whom a line has named, has left and Kaiden is listed, and Kaiden is
-- someone else. The same name in another case ("saibel" with Saibel listed) is only respelt
-- (updateTarget), and isTargeted then records it as a full name. Two such names (Saibel and Saidra
-- for "Sai"), or none, change nothing: the refusal stays.
local function completeTargetName()
    if type(target) ~= "string" or target == "" then return end
    local here = ataxia and ataxia.playersHere
    if type(here) ~= "table" or table.contains(here, target) then return end
    local want, hit = target:lower(), nil
    for _, n in pairs(here) do
        if type(n) == "string" and n:lower():sub(1, #want) == want then
            if hit then return end      -- more than one: leave it to the user
            hit = n
        end
    end
    if not hit then return end
    if hit:lower() == want and updateTarget then updateTarget(hit) end
    if isTargeted then isTargeted(hit) else target = hit end
end

-- groupPress: true from `sr` and `srd` only (see serpent.state.groupPress). A group press with the
-- target gone picks a new one first (serpent.groupRetarget); that needs no balance, so it comes
-- before the balance guard, and the press after it attacks.
function serp_ekanelia_offense(groupPress)
    serpent.state.groupPress = (groupPress == true)
    if serpent.state.groupPress then
        completeTargetName()
        serpent.groupRetarget()
    else
        serpent.state.coatingUnknown = false
    end

    -- Only dispatch when we actually have balance — prevents computing
    -- attack with current state then queuing it for later execution
    -- (by which time game state has changed)
    if gmcp.Char.Vitals.bal ~= "1" then
        return
    end

    -- Guard: don't re-dispatch while off balance. Only the balance 0 -> 1 edge (balRecovery below)
    -- or a target change cleared it, so a round the game refused WITHOUT spending balance left it
    -- set for good, and every later press returned here in silence: "You are paralysed and cannot
    -- do that." with the balance flag still up (kb/raw/logs/ours/2026-10-27_135412_Tabethys.log:
    -- 4920-4924), or "You cannot see that being here." for a hidden or departed target
    -- (kb/raw/logs/ours/2026-11-03_081009_Froedine.log:3181) (2026-11-08 review, F0).
    -- So the guard lets a press through once ATTACK_NO_SPEND seconds have passed since the send
    -- with no balance drop on GMCP: we are on balance here (the check above), and a round that
    -- spends balance shows it down within about 0.2 s. Inside that window it still holds, which
    -- is what stops a mashed key from sending two rounds before the prompt.
    -- It also holds while we are slowed (aeon; retardationOn sets ataxia.afflictions.aeon as well):
    -- a command waits there with balance still up, and a new send replaces the waiting one and
    -- starts its delay again (kb/mechanics/balance-and-queueing.md, "Retardation"), so a release
    -- could keep the attack from ever happening. The press after the slow ends releases it.
    if serpent.state.attackInFlight then
        if serpent.state.balSpentSinceSend
           or (ataxia.afflictions and ataxia.afflictions.aeon)
           or (getEpoch() - (serpent.state.attackSentAt or 0)) < ATTACK_NO_SPEND then
            return
        end
        serpent.state.attackInFlight = false
        Algedonic.Echo("<yellow>SERPENT<white>: the last round spent no balance (refused?), sending again.")
    end

    completeTargetName()

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
                -- lock_reinforce sends the voyria impulse (PRIORITY 7), as in lock and darkshade.
                -- Group stayed on "group" here, and since that impulse moved under lock_reinforce
                -- (77bc6c96, 2026-03) nothing in group mode set voyriaSent: the finish could not
                -- be reached and every round was curare + kalmia onto a full lock.
                serpStrategy = "lock_reinforce"
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
            -- reset() no longer sets the mode (v4.7.420), so this alias chooses fratricide itself,
            -- first: a "lock" left by an earlier ekhl would otherwise survive into this chain.
            serpent.hypnosis.mode = "fratricide"
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
        if serpent.state.coatingUnknown then table.insert(missing, "coating not known (group)") end
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
    cecho("<white>Death Adder: " .. (serpent.adderHere() and "<green>HERE (ordered each round)"
        or "<red>NOT HERE (no order sent)") .. "<reset>\n")
    cecho("<white>Attack First: " .. ((ataxia.settings and ataxia.settings.serpentattackfirst) and "<green>ON"
        or "<dim_grey>OFF") .. "<white> (aconfig serpent attackfirst)<reset>\n")
    cecho("<white>Recklessness: " .. (recklessnessAllowed() and "<green>ALLOWED (target locked)"
        or "<dim_grey>HELD (target not locked)") .. "<reset>\n")

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

-- "tar afflicted" (017 tarAffed): `added` is the list of afflictions just given to the target.
-- A coating line (442 a shell forms, 707 a bite it stopped) or slickness tells us the coating, so
-- a group target's coating is known from then on (sileris up: the normal bite gate holds).
local COATING_TOLD = { sileris = true, fangbarrier = true, slickness = true }
function serpent.onTargetAfflicted(added)
    if type(added) ~= "table" then added = { added } end
    for _, aff in pairs(added) do
        if aff == "rebounding" then serpent.state.reboundingSeen = true end
        if COATING_TOLD[aff] then serpent.state.coatingUnknown = false end
    end
end

-- A line showed our target's coating gone (706: our flay's strip lines, a rip). Nothing to strip.
function serpent.onCoatingGone()
    serpent.state.coatingUnknown = false
end

--[[
    A NEW TARGET ON A GROUP PRESS (the "changed target" handler below runs this after 016's
    reset). The user, 2026-11-10: "In group (sr, srd) we should not start out with flaying, we
    should just hit unless it is a bite ... we should probably state in the beginning (new target)
    they dont have rebounding or shield." So no rebounding and no shield are assumed (016 assumes
    rebounding), and a dstab that rebounds teaches it ("The attack rebounds back onto you!",
    serpent/001), after which PRIORITY 1 flays. The coating is marked unknown, so a bite waits
    for a strip (checkImpulseEligible).
]]--
function serpent.onGroupTarget()
    if not serpent.state.groupPress then
        serpent.state.coatingUnknown = false
        return
    end
    -- 016 assumed them in tAffs only; its resetStatesV3() left V3 with neither.
    if tAffs then
        tAffs.rebounding = false
        tAffs.shield = false
    end
    serpent.state.lastRebounding = false
    serpent.state.reboundingSeen = false
    serpent.state.coatingUnknown = true
end

--[[
    A GROUP PRESS WITH THE TARGET GONE (the user, 2026-11-10: "during those situations in group
    mode, I'd much rather move onto the next target that isn't Mhaldorian. Switch targets
    automatically because I set the party leader to a person and follow their calls but sometimes
    they are slow."). In the 2026-11-10 group fight 100 presses printed "Target not in room!".
    The new target is the first player GMCP lists in the room (the list never holds us) who is
    not on ataxiaTemp.allies and not of our city. Our city is the caption of the `ct` channel (GMCP
    Comm.Channel.List, ataxia.channels.ct: "Mhaldor"), as mindnet reads it
    (ataxia_mindnetTellParty). A player whose city the NDB does not know is passed over: a city
    mate the NDB has not gathered would be attacked. Rogues are taken. With our city unread, no
    switch. The switch goes through the `t` alias, as switchtargetnext does, so the game's
    target and the highlights follow. The leader's next call still sets the target as before.
    Returns the new target's name, or nil.
]]--
function serpent.groupRetarget()
    local here = ataxia and ataxia.playersHere
    if type(here) ~= "table" then return nil end
    if type(target) == "string" and target ~= "" and table.contains(here, target) then return nil end
    local city = ataxia.channels and ataxia.channels.ct
    if type(city) ~= "string" or city == "" then return nil end
    local allies = (ataxiaTemp and ataxiaTemp.allies) or {}
    for _, name in ipairs(here) do
        if type(name) == "string" and name ~= "" and not table.contains(allies, name) then
            local cit = ataxiaNDB_getCitizenship and ataxiaNDB_getCitizenship(name) or "Unknown"
            if cit ~= "Unknown" and cit:lower() ~= city:lower() then
                Algedonic.Echo("<yellow>GROUP<white>: " .. tostring(target) .. " is not here -- now "
                    .. name .. " (" .. cit .. ")")
                expandAlias("t " .. name)
                return name
            end
        end
    end
    return nil
end

-- Our flay's own line about the target's rebounding. `real` is true for the strip line ("You
-- flay away X's aura of rebounding defence."), which shows that the rebounding was up. It is
-- false for "You try to flay a non-existent aura of rebounding from X.", which shows that it was
-- not. Trigger 400 takes rebounding off the tracker on both lines; these two lines only decide
-- whether that drop arms the reapply pre-empt (PRIORITY 1.5): the strip line arms it, the
-- non-existent line does not.
--
-- The strip line itself starts the reapply clock (lastReboundingFlay). The drop check in
-- serp_ekanelia_attack stamped it at the first ROUND after the drop, about a balance later (in the
-- 2026-11-07 spar the flay's rebounding line came at 16:47:22.414 and the next round at 23.986,
-- kb/raw/logs/ours/2026-11-07_164635_Saibel.log:305, :333), so the 8.15 s pre-empt came 9.7 s or
-- more after the strip, later than the measured reapply (8.40-8.57 s after the smoke,
-- kb/mechanics/clocks.md:43) (2026-11-08 review, F30). reboundingSeen is cleared with the stamp, so
-- that drop check does not stamp the same drop again; it still stamps a drop a raise line showed.
function serpent.onReboundingFlayed(who, real)
    local ours = (isTargeted and isTargeted(who)) or (who == target)
    if not ours then return end
    if real then lastReboundingFlay = now() end
    serpent.state.reboundingSeen = false
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
        serpent.state.reboundingSeen = false  -- the new target's rebounding is only assumed
        serpent.state.adderNotedFor = nil     -- say again, once, that the adder is not out
        serpent.state.lastWieldKw = nil
        serpent.state.lastWieldBefore = nil
        hSuggActive = ""
        -- Last: on a group press, no rebounding or shield assumed (it rewrites what 016 set).
        serpent.onGroupTarget()
    end)

    -- A game line showed the target's rebounding up: a raise line (430), "The attack rebounds
    -- back onto you!" (274, serpent/001, 011) and the other tarAffed("rebounding") callers.
    serpent.eventHandlers.tarAfflicted = registerAnonymousEventHandler("tar afflicted", function(_, added)
        if serpent.onTargetAfflicted then serpent.onTargetAfflicted(added) end
    end)

    -- The snakes in our room, for the adder order (serpent.onRoomItems).
    for _, ev in ipairs({ "gmcp.Char.Items.List", "gmcp.Char.Items.Add", "gmcp.Char.Items.Remove" }) do
        serpent.eventHandlers["roomItems " .. ev] = registerAnonymousEventHandler(ev, function(event)
            if serpent.onRoomItems then serpent.onRoomItems(event) end
        end)
    end

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
            serpent.state.balSpentSinceSend = true   -- the round spent it: no watchdog release
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
                -- What our round sent (buildRound), else a queued suggest's run line (queue_Scan)
                local suggestion = serpent.hypnosis.pendingSuggestion
                    or (ataxiaTemp and ataxiaTemp.suggestAff) or "unknown"
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
            -- onFratricideCured does the erAff; a second one here would report the cure twice.
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

    -- Our flay's two rebounding lines (serpent.onReboundingFlayed). Trigger 400 has the same two
    -- patterns and does the tracker's removal; these set serpent.state.reboundingSeen, and the
    -- strip line starts the reapply clock.
    serpent.triggers.reboundingFlayed = tempRegexTrigger(
        "^You flay away (\\w+)'s aura of rebounding defence\\.$",
        [[
            if serpent and serpent.onReboundingFlayed then serpent.onReboundingFlayed(matches[2], true) end
        ]]
    )

    serpent.triggers.reboundingNotThere = tempRegexTrigger(
        "^You try to flay a non-existent aura of rebounding from (\\w+)\\.$",
        [[
            if serpent and serpent.onReboundingFlayed then serpent.onReboundingFlayed(matches[2], false) end
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
