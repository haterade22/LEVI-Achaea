--[[mudlet
type: script
name: Shaman Offense
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- SHAMAN
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    SHAMAN OFFENSE SYSTEM (V3-Aware Rebuild)
    ============================================================================

    Unified shaman offense with V3 affliction tracking.

    DELIVERY METHODS (speed order):
    - SWIFTCURSE (0.8s): Fast single curse. Gated by curseCharge > 1. Filler between CDs.
    - CURSE+INVOKE (2.2s): Standard curse + bonus action. PRIMARY when relapse off CD.
    - JINX (2.3s): 2 curses per balance. Gated by ataxiaTemp.canJinx. Charged by curse.

    GROUP MODE: Swiftcurse-first (speed is king in group fights)
    1. SWIFTCURSE (0.8s) — fastest aff delivery
    2. JINX (if charged from a prior curse — swiftcurse does NOT charge jinx)
    3. SWIFTCURSE RECHARGE (bare swiftcurse when charges depleted)
    4. CURSE+INVOKE — fallback (charges jinx for next balance, relapse available)

    LOCK/BLEED/OTHER MODES: Cooldown-driven curse → jinx cycling
    1. CURSE + INVOKE RELAPSE (relapse off CD) → paralysis relapsed + charges jinx
    2. JINX (charged from curse) → 2 affs on different cure paths
    3. CURSE + INVOKE (charges jinx again) → cycle continues
    → Relapse CD expires → repeat from 1

    INVOKE ABILITIES (bonus action on curse):
    - bloodlet: Apply haemophilia + start bleeding. Cooldown tracked.
    - coagulation: Convert bleed into slickness. Requires aspar spirit + bleed >= 200.
    - relapse: Force affliction to relapse after cure. Requires syvis spirit.
    - soulscourge: Mana damage.
    - soulrend: Mana damage (higher, requires doll fashions > 0).

    MODES:
    - group: Reactive gap-filling for group true lock (PRIMARY)
    - lock: Solo lock progression with invoke support
    - bleed: Haemophilia-first lock — stick haemo, bleed passively via teraile, lock kills
    - damage: Pure haemophilia/bleed pressure
    - tzantza: Mental aff stack for tzantza kill

    ALIASES (via tempAlias):
    - shgroup   : Group lock mode
    - shlock    : Solo lock mode
    - shbleed   : Bleed lock mode (haemo + lock)
    - shdmg     : Damage mode
    - shtz      : Tzantza mode
    - shstatus  : Status display
    - shreset   : Reset state
    - shspirits : Show spirit profile guide

    DOLL HANDLING:
    - First attack on a new target: auto-fashions + wields doll
    - Subsequent attacks: wields doll only
    - Target change or shreset: re-fashions on next attack

    EXTERNAL ALIASES (modified in alias files):
    - zz : Main attack dispatch (152_First_Attack)
    - sr : Group attack dispatch (154_Group_All_Classes)
    ============================================================================
]]--

-- =============================================================================
-- SECTION 1: NAMESPACE & STATE
-- =============================================================================

shamanOffense = shamanOffense or {}
shamanOffense.state = shamanOffense.state or {}
shamanOffense.config = shamanOffense.config or {}

-- Mode: what the player selected
shamanOffense.state.mode = shamanOffense.state.mode or "group"
-- Strategy: computed each balance based on mode + game state
shamanOffense.state.strategy = shamanOffense.state.strategy or "group"

-- Doll tracking: fashion once per target, wield every attack
shamanOffense.state.dollTarget = shamanOffense.state.dollTarget or nil
-- Relapse tracking: skip this aff in curse selection (it's coming back via relapse)
shamanOffense.state.relapseTarget = shamanOffense.state.relapseTarget or nil
-- Swiftcurse tracking: limit to one swiftcurse per curse cycle (prevents infinite swift loop)
shamanOffense.state.swiftFired = shamanOffense.state.swiftFired or false
-- Jinx cycle tracking: swiftcurse only fires AFTER jinx consumed (prevents wasting 0.8s as opener)
shamanOffense.state.jinxUsedThisCycle = shamanOffense.state.jinxUsedThisCycle or false

-- Configuration
shamanOffense.config.debug = shamanOffense.config.debug or false
shamanOffense.config.echoStrategy = true
shamanOffense.config.partyRelay = true

-- =============================================================================
-- SECTION 2: CONSTANTS
-- =============================================================================

-- Group lock priority: swiftcurse speed, no haemophilia (bloodlet handles it)
-- NOTE: Anorexia has conditional priority (inserted by selectGroupCurses when gate met)
-- Static order: impatience > [anorexia if gate] > asthma > paralysis > weariness > clumsiness > classlock > rest
-- Group mode only cares about locking affs — weariness before clumsiness
local GROUP_PRIORITY = {
    {aff = "impatience",  curse = "impatience",  cure = "goldenseal"},
    {aff = "asthma",      curse = "asthma",      cure = "kelp"},
    {aff = "paralysis",   curse = "paralyse",    cure = "bloodroot"},
    {aff = "weariness",   curse = "weariness",   cure = "kelp"},
    {aff = "clumsiness",  curse = "clumsy",      cure = "kelp"},
    -- classlock aff inserted dynamically by selectGroupCurses() after weariness
    {aff = "anorexia",    curse = "anorexia",    cure = "kelp"},
    {aff = "stupidity",   curse = "stupid",      cure = "goldenseal"},
    {aff = "manaleech",   curse = "manaleech",   cure = "smoke"},      -- soulrend gate + mana drain (smoke-cured, gate behind asthma)
    {aff = "confusion",   curse = "confusion",   cure = "ash"},        -- soulrend gate
    {aff = "sensitivity", curse = "sensitivity", cure = "kelp"},
    {aff = "healthleech", curse = "healthleech", cure = "kelp"},
    {aff = "dizziness",   curse = "dizzy",       cure = "goldenseal"},
    {aff = "recklessness",curse = "reckless",    cure = "lobelia"},
    {aff = "masochism",   curse = "masochism",   cure = "lobelia"},
    {aff = "dementia",    curse = "dementia",    cure = "ash"},
    {aff = "vertigo",     curse = "vertigo",     cure = "lobelia"},
}

-- Lock priority: paralysis first (relapse target), no haemophilia (bloodlet handles it)
local LOCK_PRIORITY = {
    {aff = "paralysis",   curse = "paralyse",    cure = "bloodroot"},
    {aff = "impatience",  curse = "impatience",  cure = "goldenseal"},
    {aff = "asthma",      curse = "asthma",      cure = "kelp"},
    {aff = "clumsiness",  curse = "clumsy",      cure = "kelp"},
    {aff = "anorexia",    curse = "anorexia",    cure = "kelp"},
    {aff = "weariness",   curse = "weariness",   cure = "kelp"},
    {aff = "stupidity",   curse = "stupid",      cure = "goldenseal"},
    {aff = "manaleech",   curse = "manaleech",   cure = "smoke"},      -- soulrend gate + mana drain (smoke-cured, gate behind asthma)
    {aff = "confusion",   curse = "confusion",   cure = "ash"},        -- soulrend gate
    {aff = "sensitivity", curse = "sensitivity", cure = "kelp"},
    {aff = "healthleech", curse = "healthleech", cure = "kelp"},
    {aff = "dizziness",   curse = "dizzy",       cure = "goldenseal"},
    {aff = "recklessness",curse = "reckless",    cure = "lobelia"},
    {aff = "masochism",   curse = "masochism",   cure = "lobelia"},
    {aff = "dementia",    curse = "dementia",    cure = "ash"},
    {aff = "vertigo",     curse = "vertigo",     cure = "lobelia"},
}

-- Bleed priority: paralysis first, no haemophilia (bloodlet handles it)
-- Teraile attune = passive bleed on every curse; bloodlet invoke = haemophilia
local BLEED_PRIORITY = {
    {aff = "paralysis",    curse = "paralyse",     cure = "bloodroot"},   -- lock piece + relapse target
    {aff = "impatience",   curse = "impatience",   cure = "goldenseal"},  -- blocks focus
    {aff = "asthma",       curse = "asthma",       cure = "kelp"},        -- kelp stack partner
    {aff = "clumsiness",   curse = "clumsy",        cure = "kelp"},       -- kelp stack
    {aff = "weariness",    curse = "weariness",     cure = "kelp"},       -- kelp competition
    {aff = "anorexia",     curse = "anorexia",     cure = "kelp"},        -- kelp competition
    {aff = "stupidity",    curse = "stupid",         cure = "goldenseal"},
    {aff = "manaleech",    curse = "manaleech",     cure = "smoke"},      -- soulrend gate + mana drain (smoke-cured, gate behind asthma)
    {aff = "confusion",    curse = "confusion",     cure = "ash"},        -- soulrend gate
    {aff = "sensitivity",  curse = "sensitivity",   cure = "kelp"},       -- amplifies bleed damage
    {aff = "healthleech",  curse = "healthleech",   cure = "kelp"},       -- kelp stack
    {aff = "dizziness",    curse = "dizzy",          cure = "goldenseal"},
    {aff = "recklessness", curse = "reckless",       cure = "lobelia"},
    {aff = "masochism",    curse = "masochism",      cure = "lobelia"},
    {aff = "vertigo",      curse = "vertigo",        cure = "lobelia"},
}

-- Core lock afflictions (for truelock detection)
local TRUELOCK_AFFS = {"asthma", "anorexia", "slickness", "impatience", "paralysis"}

-- Focus-curable afflictions: cured by focus (separate channel from herbs)
-- Jinx should NOT pair a herb-only aff with a focus-curable aff (target clears both simultaneously)
local FOCUS_CURABLE = {
    stupidity = true, confusion = true, anorexia = true,
    dementia = true, masochism = true, recklessness = true,
    dizziness = true, impatience = true,
}

-- =============================================================================
-- SECTION 3: V3-AWARE HELPERS
-- =============================================================================

-- Affliction check routing: V3 → V2 → V1
function shamanOffense.hasAff(aff)
    if affConfigV3 and affConfigV3.enabled and haveAffV3 then
        return haveAffV3(aff)
    end
    if ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 and haveAffV2 then
        return haveAffV2(aff)
    end
    -- V1 fallback (haveAff routes V3→V1 when available)
    if haveAff then
        return haveAff(aff)
    end
    return tAffs and tAffs[aff] or false
end

-- Lock detection
function shamanOffense.checkLock()
    local soft = shamanOffense.hasAff("asthma") and shamanOffense.hasAff("anorexia") and shamanOffense.hasAff("slickness")
    local hard = soft and shamanOffense.hasAff("impatience")
    local true_ = hard and shamanOffense.hasAff("paralysis")
    return soft, hard, true_
end

-- Echo helpers
function shamanOffense.echo(text)
    cecho("\n<orange_red>[Shaman]<reset> " .. text)
end

function shamanOffense.decho(text)
    if shamanOffense.config.debug then
        shamanOffense.echo(text)
    end
end

-- =============================================================================
-- SECTION 4: STRATEGY COMPUTATION
-- =============================================================================

function shamanOffense.computeStrategy()
    local mode = shamanOffense.state.mode
    local soft, hard, truelock = shamanOffense.checkLock()

    if mode == "group" then
        if truelock then
            -- Check class-specific lock aff
            local classAff = getLockingAffliction and getLockingAffliction() or nil
            if classAff and not shamanOffense.hasAff(classAff) then
                shamanOffense.state.strategy = "classlock"
            else
                shamanOffense.state.strategy = "finish"
            end
        else
            shamanOffense.state.strategy = "group"
        end

    elseif mode == "lock" then
        if truelock then
            local classAff = getLockingAffliction and getLockingAffliction() or nil
            if classAff and not shamanOffense.hasAff(classAff) then
                shamanOffense.state.strategy = "classlock"
            else
                shamanOffense.state.strategy = "finish"
            end
        else
            shamanOffense.state.strategy = "lock"
        end

    elseif mode == "bleed" then
        if truelock then
            local classAff = getLockingAffliction and getLockingAffliction() or nil
            if classAff and not shamanOffense.hasAff(classAff) then
                shamanOffense.state.strategy = "classlock"
            else
                shamanOffense.state.strategy = "finish"
            end
        else
            shamanOffense.state.strategy = "bleed"
        end

    elseif mode == "damage" then
        shamanOffense.state.strategy = "damage"

    elseif mode == "tzantza" then
        local tzCount = getTzantzaAffs and getTzantzaAffs() or 0
        if tzCount >= 6 then
            shamanOffense.state.strategy = "tzantza_execute"
        else
            shamanOffense.state.strategy = "tzantza_build"
        end
    end
end

-- =============================================================================
-- SECTION 5: CURSE SELECTION
-- =============================================================================

--[[
    Select curses for group mode.
    Returns: primary (string), secondary (string or nil), primaryAff (string or nil)

    For jinx pairing: prefer secondary on SAME cure path + same cure channel.
    E.g. asthma(kelp) + clumsy(kelp) = two kelp affs, target can only cure one per balance.
    Manaleech gated behind asthma (smoke-cured, useless without asthma).
]]--
function shamanOffense.selectGroupCurses()
    local primary, secondary = nil, nil
    local primaryCure = nil
    local hasAsthma = shamanOffense.hasAff("asthma")

    -- Build effective priority list with conditional entries
    -- Order: impatience > [anorexia if gate met] > asthma > paralysis > clumsiness > weariness > classlock > rest
    local effectivePriority = {}

    for _, entry in ipairs(GROUP_PRIORITY) do
        -- After impatience, conditionally insert anorexia
        if entry.aff == "asthma" then
            -- Anorexia gate: only prioritize when asthma + slickness + impatience all present
            if hasAsthma and shamanOffense.hasAff("slickness")
               and shamanOffense.hasAff("impatience") then
                table.insert(effectivePriority, {aff = "anorexia", curse = "anorexia", cure = "kelp"})
            end
        end

        -- After weariness, insert class lock aff dynamically
        -- getLockingAffliction() returns curse name string, getLockingAffliction("name") returns aff name
        if entry.aff == "weariness" then
            local classCurse = getLockingAffliction and getLockingAffliction() or nil
            local classAffName = getLockingAffliction and getLockingAffliction("name") or nil
            if classCurse and classAffName then
                table.insert(effectivePriority, {aff = classAffName, curse = classCurse, cure = "class"})
            end
        end

        -- Skip anorexia (handled conditionally above) and manaleech without asthma
        if entry.aff == "anorexia" then
            -- already handled above
        elseif entry.aff == "manaleech" and not hasAsthma then
            -- skip manaleech unless asthma present (smoke-cured, smoked off without asthma)
        else
            table.insert(effectivePriority, entry)
        end
    end

    -- Scan effective priority for primary
    local primaryAff = nil
    for _, entry in ipairs(effectivePriority) do
        if not shamanOffense.hasAff(entry.aff) then
            primary = entry.curse
            primaryCure = entry.cure
            primaryAff = entry.aff
            break
        end
    end

    -- For jinx secondary: prefer SAME cure path + same cure channel
    if ataxiaTemp and ataxiaTemp.canJinx and primary then
        local primaryIsFocus = FOCUS_CURABLE[primaryAff]
        -- First pass: same cure path AND same cure channel (no herb+focus cross-channel)
        for _, entry in ipairs(effectivePriority) do
            if not shamanOffense.hasAff(entry.aff) and entry.curse ~= primary and entry.cure == primaryCure then
                local entryIsFocus = FOCUS_CURABLE[entry.aff]
                if (primaryIsFocus and entryIsFocus) or (not primaryIsFocus and not entryIsFocus) then
                    secondary = entry.curse
                    break
                end
            end
        end
        -- Fallback: any cure path but same cure channel (no herb+focus cross-channel)
        if not secondary then
            for _, entry in ipairs(effectivePriority) do
                if not shamanOffense.hasAff(entry.aff) and entry.curse ~= primary then
                    local entryIsFocus = FOCUS_CURABLE[entry.aff]
                    if (primaryIsFocus and entryIsFocus) or (not primaryIsFocus and not entryIsFocus) then
                        secondary = entry.curse
                        break
                    end
                end
            end
        end
    end

    return primary, secondary, primaryAff
end

--[[
    Select curse + relapse target when relapse is off cooldown.
    Returns: curseName (string), relapseTarget (string)

    Paralysis is the #1 relapse target because:
    - Highest priority cure (target eats bloodroot immediately → relapse fires fast)
    - Lock piece (needed for truelock)
    - Bloodroot exclusive (easy to track, no cure competition)
]]--
function shamanOffense.selectRelapseCurse()
    -- If target doesn't have paralysis: curse it + relapse it
    -- relapseTarget uses AFF name ("paralysis") to match entry.aff in selectLockCurses skip
    if not shamanOffense.hasAff("paralysis") then
        return "paralyse", "paralysis"
    end

    -- Target HAS paralysis: curse next missing lock aff + relapse paralysis
    local primary = nil
    for _, entry in ipairs(GROUP_PRIORITY) do
        if not shamanOffense.hasAff(entry.aff) then
            primary = entry.curse
            break
        end
    end
    primary = primary or "plague"

    -- Relapse their existing paralysis (they WILL cure it, then it comes back)
    return primary, "paralysis"
end

-- Bleed variant: uses BLEED_PRIORITY instead of GROUP_PRIORITY for the curse
function shamanOffense.selectRelapseBleedCurse()
    -- If target doesn't have paralysis: curse it + relapse it
    -- relapseTarget uses AFF name ("paralysis") to match entry.aff in selectBleedCurses skip
    if not shamanOffense.hasAff("paralysis") then
        return "paralyse", "paralysis"
    end

    -- Target HAS paralysis: curse next missing bleed-priority aff + relapse paralysis
    local primary = nil
    for _, entry in ipairs(BLEED_PRIORITY) do
        if not shamanOffense.hasAff(entry.aff) then
            primary = entry.curse
            break
        end
    end
    primary = primary or "plague"

    return primary, "paralysis"
end

-- Select curses for bleed mode: paralysis first, no haemophilia (bloodlet handles it)
-- Skips relapseTarget aff (it's coming back via relapse, don't waste a slot)
-- Anorexia gated: only when target has impatience + asthma + slickness
-- Manaleech gated: only when target has asthma (smoke-cured, useless without asthma)
-- Jinx secondary prefers SAME cure path + same cure channel (kelp stacking, no herb+focus)
function shamanOffense.selectBleedCurses()
    local primary, secondary = nil, nil
    local primaryCure = nil
    local primaryAff = nil
    local skipAff = shamanOffense.state.relapseTarget
    -- Anorexia gate: only deliver when imp + asthma + slickness all present
    local anoGate = shamanOffense.hasAff("impatience") and shamanOffense.hasAff("asthma")
                    and shamanOffense.hasAff("slickness")
    local hasAsthma = shamanOffense.hasAff("asthma")

    -- Find primary
    for _, entry in ipairs(BLEED_PRIORITY) do
        if entry.aff == "anorexia" and not anoGate then
            -- skip anorexia unless gate met
        elseif entry.aff == "manaleech" and not hasAsthma then
            -- skip manaleech unless asthma present (smoke-cured, smoked off without asthma)
        elseif not shamanOffense.hasAff(entry.aff) and entry.aff ~= skipAff then
            primary = entry.curse
            primaryCure = entry.cure
            primaryAff = entry.aff
            break
        end
    end

    -- For jinx secondary: prefer SAME cure path + same cure channel
    if ataxiaTemp and ataxiaTemp.canJinx and primary then
        local primaryIsFocus = FOCUS_CURABLE[primaryAff]
        -- First pass: same cure path AND same cure channel (no herb+focus cross-channel)
        for _, entry in ipairs(BLEED_PRIORITY) do
            if entry.aff == "anorexia" and not anoGate then
                -- skip
            elseif entry.aff == "manaleech" and not hasAsthma then
                -- skip
            elseif not shamanOffense.hasAff(entry.aff) and entry.curse ~= primary
               and entry.aff ~= skipAff and entry.cure == primaryCure then
                local entryIsFocus = FOCUS_CURABLE[entry.aff]
                if (primaryIsFocus and entryIsFocus) or (not primaryIsFocus and not entryIsFocus) then
                    secondary = entry.curse
                    break
                end
            end
        end
        -- Fallback: any cure path but same cure channel (no herb+focus cross-channel)
        if not secondary then
            for _, entry in ipairs(BLEED_PRIORITY) do
                if entry.aff == "anorexia" and not anoGate then
                    -- skip
                elseif entry.aff == "manaleech" and not hasAsthma then
                    -- skip
                elseif not shamanOffense.hasAff(entry.aff) and entry.curse ~= primary and entry.aff ~= skipAff then
                    local entryIsFocus = FOCUS_CURABLE[entry.aff]
                    if (primaryIsFocus and entryIsFocus) or (not primaryIsFocus and not entryIsFocus) then
                        secondary = entry.curse
                        break
                    end
                end
            end
        end
    end

    return primary, secondary, primaryAff
end

-- Lock curse selection: paralysis first, no haemophilia (bloodlet handles it)
-- Skips relapseTarget aff (it's coming back via relapse, don't waste a slot)
-- Anorexia gated: only when target has impatience + asthma + slickness
-- Manaleech gated: only when target has asthma (smoke-cured, useless without asthma)
-- Jinx secondary prefers SAME cure path + same cure channel (kelp stacking, no herb+focus)
function shamanOffense.selectLockCurses()
    local primary, secondary = nil, nil
    local primaryCure = nil
    local primaryAff = nil
    local skipAff = shamanOffense.state.relapseTarget  -- aff that's pending relapse
    -- Anorexia gate: only deliver when imp + asthma + slickness all present
    local anoGate = shamanOffense.hasAff("impatience") and shamanOffense.hasAff("asthma")
                    and shamanOffense.hasAff("slickness")
    local hasAsthma = shamanOffense.hasAff("asthma")

    -- Find primary
    for _, entry in ipairs(LOCK_PRIORITY) do
        if entry.aff == "anorexia" and not anoGate then
            -- skip anorexia unless gate met
        elseif entry.aff == "manaleech" and not hasAsthma then
            -- skip manaleech unless asthma present (smoke-cured, smoked off without asthma)
        elseif not shamanOffense.hasAff(entry.aff) and entry.aff ~= skipAff then
            primary = entry.curse
            primaryCure = entry.cure
            primaryAff = entry.aff
            break
        end
    end

    -- For jinx secondary: prefer SAME cure path + same cure channel
    if ataxiaTemp and ataxiaTemp.canJinx and primary then
        local primaryIsFocus = FOCUS_CURABLE[primaryAff]
        -- First pass: same cure path AND same cure channel (no herb+focus cross-channel)
        for _, entry in ipairs(LOCK_PRIORITY) do
            if entry.aff == "anorexia" and not anoGate then
                -- skip
            elseif entry.aff == "manaleech" and not hasAsthma then
                -- skip
            elseif not shamanOffense.hasAff(entry.aff) and entry.curse ~= primary
               and entry.aff ~= skipAff and entry.cure == primaryCure then
                local entryIsFocus = FOCUS_CURABLE[entry.aff]
                if (primaryIsFocus and entryIsFocus) or (not primaryIsFocus and not entryIsFocus) then
                    secondary = entry.curse
                    break
                end
            end
        end
        -- Fallback: any cure path but same cure channel (no herb+focus cross-channel)
        if not secondary then
            for _, entry in ipairs(LOCK_PRIORITY) do
                if entry.aff == "anorexia" and not anoGate then
                    -- skip
                elseif entry.aff == "manaleech" and not hasAsthma then
                    -- skip
                elseif not shamanOffense.hasAff(entry.aff) and entry.curse ~= primary and entry.aff ~= skipAff then
                    local entryIsFocus = FOCUS_CURABLE[entry.aff]
                    if (primaryIsFocus and entryIsFocus) or (not primaryIsFocus and not entryIsFocus) then
                        secondary = entry.curse
                        break
                    end
                end
            end
        end
    end

    return primary, secondary, primaryAff
end

-- =============================================================================
-- SECTION 6: INVOKE SELECTION
-- =============================================================================

-- Coagulation affliction priority: pick the most useful aff to give the target
-- Slickness if they have asthma (can't smoke to cure it), else first missing from list
local COAGULATION_PRIORITY = {
    "impatience", "paralysis", "asthma", "slickness", "anorexia", "weariness", "lethargy", "clumsiness"
}


function shamanOffense.selectCoagulationAff(skipAff)
    -- Slickness first if they have asthma (can't smoke to cure slickness)
    if shamanOffense.hasAff("asthma") and not shamanOffense.hasAff("slickness") and skipAff ~= "slickness" then
        return "slickness"
    end
    -- Else first missing from priority list (skip the aff being delivered by the curse)
    for _, aff in ipairs(COAGULATION_PRIORITY) do
        if aff ~= skipAff and not shamanOffense.hasAff(aff) then
            return aff
        end
    end
    return "slickness"  -- fallback
end

-- Soulrend mental aff gate: target must have one of these
local SOULREND_GATE_AFFS = {"manaleech", "confusion", "shyness", "paranoia", "dementia"}

function shamanOffense.canSoulrend()
    if not (shaman and shaman.spiritisbound and shaman.spiritisbound("maligus")) then
        return false
    end
    for _, aff in ipairs(SOULREND_GATE_AFFS) do
        if shamanOffense.hasAff(aff) then
            return true
        end
    end
    return false
end

--[[
    Invoke priority for curse rounds (relapse handled at buildAttack level):
    1. Soulrend — target has manaleech/confusion/shyness/paranoia/dementia + maligus bound
    2. Coagulation — bleeding >= 200 + aspar bound → smart aff selection
    3. Bloodlet — teraile bound → haemophilia + bleed
]]--
function shamanOffense.selectInvoke(primaryAff)
    -- Soulrend: mana pressure when target has mental affs
    if shamanOffense.canSoulrend() then
        return "invoke soulrend"
    end

    -- Coagulation: convert bleed → useful affliction
    -- Gate behind haemophilia: without it, bleed isn't accumulating and BL data may be stale
    -- Skip the aff being cursed this round (avoid wasting coagulation on a duplicate)
    if shamanOffense.hasAff("haemophilia")
       and ataxiaTemp and not ataxiaTemp.coagulate
       and shaman and shaman.spiritisbound and shaman.spiritisbound("aspar")
       and (tAffs.bleed or 0) >= 200 then
        local coagAff = shamanOffense.selectCoagulationAff(primaryAff)
        return "invoke coagulation " .. coagAff
    end

    -- Bloodlet: haemophilia + bleed (always available fallback)
    if ataxiaTemp and not ataxiaTemp.bloodlet
       and shaman and shaman.spiritisbound and shaman.spiritisbound("teraile") then
        return "invoke bloodlet " .. target
    end

    return nil
end

-- Bleed mode invoke: same priority but bloodlet fires more aggressively
function shamanOffense.selectBleedInvoke(primaryAff)
    -- Soulrend: mana pressure when target has mental affs
    if shamanOffense.canSoulrend() then
        return "invoke soulrend"
    end

    -- Coagulation: convert bleed → useful affliction
    -- Gate behind haemophilia: without it, bleed isn't accumulating and BL data may be stale
    -- Skip the aff being cursed this round (avoid wasting coagulation on a duplicate)
    if shamanOffense.hasAff("haemophilia")
       and ataxiaTemp and not ataxiaTemp.coagulate
       and shaman and shaman.spiritisbound and shaman.spiritisbound("aspar")
       and (tAffs.bleed or 0) >= 200 then
        local coagAff = shamanOffense.selectCoagulationAff(primaryAff)
        return "invoke coagulation " .. coagAff
    end

    -- Bloodlet: always fire when off cooldown in bleed mode
    if ataxiaTemp and not ataxiaTemp.bloodlet
       and shaman and shaman.spiritisbound and shaman.spiritisbound("teraile") then
        return "invoke bloodlet " .. target
    end

    return nil
end

-- =============================================================================
-- SECTION 7: ATTACK BUILDING
-- =============================================================================

function shamanOffense.buildAttack()
    local atk = combatQueue and combatQueue() or ""
    local strategy = shamanOffense.state.strategy

    -- Doll: fashion on first attack against new target, skip in group mode
    -- Doll: fashion on first attack against new target, skip in group mode
    local prefix = ""
    if shamanOffense.state.mode ~= "group" and shamanOffense.state.dollTarget ~= target then
        shamanOffense.state.dollTarget = target
        atk = atk .. "fashion doll of " .. target
        return atk  -- Fashion takes eq; offense starts next press
    end

    -- ==========================================
    -- CURSEWARD CHECK (always top priority)
    -- ==========================================
    if shamanOffense.hasAff("curseward") or (tAffs and tAffs.curseward) then
        atk = atk .. prefix .. "curse " .. target .. " breach"
        return atk
    end

    -- ==========================================
    -- FINISH STRATEGY (truelock + class aff achieved)
    -- ==========================================
    if strategy == "finish" then
        -- Party callout
        if shamanOffense.config.partyRelay and partyrelay and not (ataxia and ataxia.afflictions and ataxia.afflictions.aeon) then
            send("pt TRUELOCK on " .. target .. " -- EXECUTE", false)
        end
        -- Jinx sleep for prone, or plague + mana damage
        if ataxiaTemp and ataxiaTemp.canJinx then
            atk = atk .. "stand;" .. prefix .. "jinx sleep sleep " .. target
        elseif shaman and shaman.spiritisbound and shaman.spiritisbound("marak") then
            atk = atk .. prefix .. "curse " .. target .. " plague invoke soulscourge"
        else
            atk = atk .. prefix .. "curse " .. target .. " plague"
        end
        return atk
    end

    -- ==========================================
    -- CLASSLOCK STRATEGY (truelock achieved, need class aff)
    -- ==========================================
    if strategy == "classlock" then
        local classAff = getLockingAffliction and getLockingAffliction() or "weariness"

        -- Swiftcurse is fastest, use it if available
        if curseCharge and curseCharge > 1 then
            atk = atk .. prefix .. "swiftcurse " .. target .. " " .. classAff
        elseif ataxiaTemp and ataxiaTemp.canJinx then
            -- Jinx class aff + pressure aff (plague for voyria)
            atk = atk .. "stand;" .. prefix .. "jinx " .. classAff .. " plague " .. target
        else
            if shaman and shaman.spiritisbound and shaman.spiritisbound("marak") then
                atk = atk .. prefix .. "curse " .. target .. " " .. classAff .. " invoke soulscourge"
            else
                atk = atk .. prefix .. "curse " .. target .. " " .. classAff
            end
        end
        return atk
    end

    -- ==========================================
    -- GROUP STRATEGY (swiftcurse-first for speed in group fights)
    -- NOTE: Jinx can only charge from regular curse, NOT swiftcurse.
    -- In group mode we primarily use swiftcurse, so jinx rarely fires.
    -- Jinx checks kept for edge cases (e.g. mode switch from lock).
    -- ==========================================
    if strategy == "group" then
        local primary, secondary, primaryAff = shamanOffense.selectGroupCurses()

        -- If all tracked affs are present, deliver class lock aff or pressure
        if not primary then
            local classAff = getLockingAffliction and getLockingAffliction() or "weariness"
            if not shamanOffense.hasAff(classAff) then
                primary = classAff
                primaryAff = classAff
            else
                primary = "plague"
                primaryAff = nil
            end
        end

        -- ===== PRIORITY 1: SWIFTCURSE (0.8s, speed is king in group) =====
        if curseCharge and curseCharge > 1 then
            atk = atk .. prefix .. "swiftcurse " .. target .. " " .. primary
            return atk
        end

        -- ===== PRIORITY 2: JINX if available (only charged by regular curse, not swiftcurse) =====
        if ataxiaTemp and ataxiaTemp.canJinx and primary and secondary then
            atk = atk .. "stand;" .. prefix .. "jinx " .. primary .. " " .. secondary .. " " .. target
            return atk
        end

        -- ===== PRIORITY 3: SWIFTCURSE RECHARGE =====
        if curseCharge and curseCharge <= 1 then
            atk = atk .. prefix .. "swiftcurse"
            return atk
        end

        -- ===== PRIORITY 4: REGULAR CURSE + INVOKE (also charges jinx for next balance) =====
        local invoke = shamanOffense.selectInvoke(primaryAff)
        if invoke then
            atk = atk .. prefix .. "curse " .. target .. " " .. primary .. " " .. invoke
        else
            atk = atk .. prefix .. "curse " .. target .. " " .. primary
        end
        return atk
    end

    -- ==========================================
    -- LOCK STRATEGY (cooldown-driven curse → jinx → swift rotation)
    -- Cycle: curse+relapse(2.2s) → jinx(2.3s) → swiftcurse(0.8s) → curse+invoke(2.2s) → jinx → swift → ...
    -- Each regular curse charges jinx AND carries an invoke bonus.
    -- Swiftcurse is a 0.8s filler for +1 aff between jinx and regular curse.
    -- Skip relapse when target has tree (too slow, tree cures it off).
    -- ==========================================
    if strategy == "lock" then
        local primary, secondary, primaryAff = shamanOffense.selectLockCurses()

        -- If all tracked affs are present, deliver class lock aff or pressure
        if not primary then
            local classAff = getLockingAffliction and getLockingAffliction() or "weariness"
            if not shamanOffense.hasAff(classAff) then
                primary = classAff
                primaryAff = classAff
            else
                primary = "plague"
                primaryAff = nil
            end
        end

        -- ===== PRIORITY 1: CURSE + INVOKE RELAPSE (only when tree is down) =====
        -- Forces target to cure the aff TWICE + charges jinx for next balance
        -- Skip if target has tree — relapse is wasted, they just tree it off
        if not (tBals and tBals.tree)
           and ataxiaTemp and not ataxiaTemp.relapse
           and shaman and shaman.spiritisbound and shaman.spiritisbound("syvis") then
            local curseName, relapseAff = shamanOffense.selectRelapseCurse()
            shamanOffense.state.relapseTarget = relapseAff  -- AFF name ("paralysis") for skip matching
            shamanOffense.state.swiftFired = false  -- New curse cycle
            shamanOffense.state.jinxUsedThisCycle = false  -- New cycle starts
            atk = atk .. prefix .. "curse " .. target .. " " .. curseName .. " invoke relapse " .. relapseAff
            return atk
        end

        -- Clear relapse target once relapse has fired (on CD = it already reapplied the aff)
        if ataxiaTemp and ataxiaTemp.relapse then
            shamanOffense.state.relapseTarget = nil
        end

        -- ===== PRIORITY 2: JINX (consume charge from curse, 2 affs) =====
        if ataxiaTemp and ataxiaTemp.canJinx and primary and secondary then
            shamanOffense.state.jinxUsedThisCycle = true  -- Jinx consumed, swiftcurse now eligible
            atk = atk .. "stand;" .. prefix .. "jinx " .. primary .. " " .. secondary .. " " .. target
            return atk
        end

        -- ===== PRIORITY 3: SWIFTCURSE (0.8s filler between jinx and regular curse) =====
        -- Only fires AFTER jinx consumed this cycle (prevents wasting 0.8s as opener)
        -- One swiftcurse per cycle: fires after jinx, before next regular curse
        if shamanOffense.state.jinxUsedThisCycle
           and curseCharge and curseCharge > 1
           and not shamanOffense.state.swiftFired then
            shamanOffense.state.swiftFired = true
            atk = atk .. prefix .. "swiftcurse " .. target .. " " .. primary
            return atk
        end

        -- ===== PRIORITY 4: CURSE + OTHER INVOKE (charges jinx for next balance) =====
        -- Keeps the curse → jinx cycle going while relapse is on CD
        shamanOffense.state.swiftFired = false  -- New curse cycle
        shamanOffense.state.jinxUsedThisCycle = false  -- New cycle starts
        local invoke = shamanOffense.selectInvoke(primaryAff)
        if invoke then
            atk = atk .. prefix .. "curse " .. target .. " " .. primary .. " " .. invoke
        else
            atk = atk .. prefix .. "curse " .. target .. " " .. primary
        end
        return atk
    end

    -- ==========================================
    -- BLEED STRATEGY (cooldown-driven, haemophilia + lock, bleeds via teraile)
    -- ==========================================
    if strategy == "bleed" then
        local primary, secondary, primaryAff = shamanOffense.selectBleedCurses()

        -- If all tracked affs present, deliver class lock aff or pressure
        if not primary then
            local classAff = getLockingAffliction and getLockingAffliction() or "weariness"
            if not shamanOffense.hasAff(classAff) then
                primary = classAff
                primaryAff = classAff
            else
                primary = "plague"
                primaryAff = nil
            end
        end

        -- PRIORITY 1: CURSE + INVOKE RELAPSE (only when tree is down)
        -- Skip if target has tree — relapse is wasted, they just tree it off
        if not (tBals and tBals.tree)
           and ataxiaTemp and not ataxiaTemp.relapse
           and shaman and shaman.spiritisbound and shaman.spiritisbound("syvis") then
            local curseName, relapseAff = shamanOffense.selectRelapseBleedCurse()
            shamanOffense.state.relapseTarget = relapseAff  -- AFF name ("paralysis") for skip matching
            shamanOffense.state.swiftFired = false  -- New curse cycle
            shamanOffense.state.jinxUsedThisCycle = false  -- New cycle starts
            atk = atk .. prefix .. "curse " .. target .. " " .. curseName .. " invoke relapse " .. relapseAff
            return atk
        end

        -- Clear relapse target once relapse has fired (on CD = it already reapplied the aff)
        if ataxiaTemp and ataxiaTemp.relapse then
            shamanOffense.state.relapseTarget = nil
        end

        -- PRIORITY 2: JINX (consume charge from curse, 2 affs)
        if ataxiaTemp and ataxiaTemp.canJinx and primary and secondary then
            shamanOffense.state.jinxUsedThisCycle = true  -- Jinx consumed, swiftcurse now eligible
            atk = atk .. "stand;" .. prefix .. "jinx " .. primary .. " " .. secondary .. " " .. target
            return atk
        end

        -- PRIORITY 3: SWIFTCURSE (0.8s filler between jinx and regular curse)
        -- Only fires AFTER jinx consumed this cycle (prevents wasting 0.8s as opener)
        if shamanOffense.state.jinxUsedThisCycle
           and curseCharge and curseCharge > 1
           and not shamanOffense.state.swiftFired then
            shamanOffense.state.swiftFired = true
            atk = atk .. prefix .. "swiftcurse " .. target .. " " .. primary
            return atk
        end

        -- ===== PRIORITY 4: CURSE + BLEED INVOKE (charges jinx for next balance) =====
        -- Keeps the curse → jinx cycle going while relapse is on CD
        -- Bloodlet fires aggressively here (haemo + bleed pressure)
        shamanOffense.state.swiftFired = false  -- New curse cycle
        shamanOffense.state.jinxUsedThisCycle = false  -- New cycle starts
        local invoke = shamanOffense.selectBleedInvoke(primaryAff)
        if invoke then
            atk = atk .. prefix .. "curse " .. target .. " " .. primary .. " " .. invoke
        else
            atk = atk .. prefix .. "curse " .. target .. " " .. primary
        end
        return atk
    end

    -- ==========================================
    -- DAMAGE STRATEGY
    -- ==========================================
    if strategy == "damage" then
        -- Focus: haemophilia → bloodlet → bleed → coagulate → slickness
        if not shamanOffense.hasAff("haemophilia") then
            if curseCharge and curseCharge > 1 then
                atk = atk .. prefix .. "swiftcurse " .. target .. " haemophilia"
            else
                atk = atk .. prefix .. "curse " .. target .. " haemophilia"
            end
        elseif ataxiaTemp and not ataxiaTemp.bloodlet
               and shaman and shaman.spiritisbound and shaman.spiritisbound("teraile") then
            atk = atk .. prefix .. "curse " .. target .. " asthma invoke bloodlet " .. target
        elseif ataxiaTemp and not ataxiaTemp.coagulate
               and shaman and shaman.spiritisbound and shaman.spiritisbound("aspar")
               and (tAffs.bleed or 0) >= 200 then
            atk = atk .. prefix .. "curse " .. target .. " anorexia invoke coagulation slickness"
        else
            -- Pressure curse with mana damage
            local primary = shamanOffense.selectGroupCurses()
            primary = primary or "asthma"
            if curseCharge and curseCharge > 1 then
                atk = atk .. prefix .. "swiftcurse " .. target .. " " .. primary
            elseif shaman and shaman.spiritisbound and shaman.spiritisbound("marak") then
                atk = atk .. prefix .. "curse " .. target .. " " .. primary .. " invoke soulscourge"
            else
                atk = atk .. prefix .. "curse " .. target .. " " .. primary
            end
        end
        return atk
    end

    -- ==========================================
    -- TZANTZA STRATEGIES
    -- ==========================================
    if strategy == "tzantza_execute" then
        if ataxiaTemp and ataxiaTemp.canJinx then
            atk = atk .. "stand;" .. prefix .. "jinx amnesia tzantza " .. target
        elseif curseCharge and curseCharge > 1 then
            atk = atk .. prefix .. "swiftcurse " .. target .. " tzantza"
        else
            if shaman and shaman.spiritisbound and shaman.spiritisbound("marak") then
                atk = atk .. prefix .. "curse " .. target .. " tzantza invoke soulscourge vodun bind"
            else
                atk = atk .. prefix .. "curse " .. target .. " tzantza"
            end
        end
        return atk
    end

    if strategy == "tzantza_build" then
        local primary, secondary = shamanOffense.selectGroupCurses()
        primary = primary or "stupid"

        if curseCharge and curseCharge > 1 then
            atk = atk .. prefix .. "swiftcurse " .. target .. " " .. primary
        elseif ataxiaTemp and ataxiaTemp.canJinx and secondary then
            atk = atk .. "stand;" .. prefix .. "jinx " .. primary .. " " .. secondary .. " " .. target
        else
            atk = atk .. prefix .. "curse " .. target .. " " .. primary
        end
        return atk
    end

    -- Fallback
    atk = atk .. prefix .. "curse " .. target .. " asthma"
    return atk
end

-- =============================================================================
-- SECTION 8: SEND ATTACK
-- =============================================================================

function shamanOffense.sendAttack(atk)
    if not atk or atk == "" then return end

    -- Lock break check
    if ataxia_needLockBreak and ataxia_needLockBreak() then
        if ataxia_lockBreak then ataxia_lockBreak() end
        return
    end

    -- Target presence check
    if ataxia and ataxia.playersHere and not table.contains(ataxia.playersHere, target) then
        shamanOffense.decho("Target " .. target .. " not in room")
        return
    end

    send("queue addclear free " .. atk)

    -- Combat echo: mode/strategy | delivery | target affs | lock status | cooldowns
    local soft, hard, truelock = shamanOffense.checkLock()

    -- Lock status
    local lockStr = ""
    if truelock then lockStr = " <red>TRUELOCK<reset>"
    elseif hard then lockStr = " <orange>HARDLOCK<reset>"
    elseif soft then lockStr = " <yellow>SOFTLOCK<reset>"
    end

    -- Target afflictions: only show what they have
    local allAffs = {
        {aff = "impatience",  code = "IMP"},
        {aff = "asthma",      code = "AST"},
        {aff = "paralysis",   code = "PAR"},
        {aff = "anorexia",    code = "ANO"},
        {aff = "slickness",   code = "SLI"},
        {aff = "haemophilia",  code = "HAE"},
        {aff = "weariness",    code = "WEA"},
        {aff = "clumsiness",   code = "CLU"},
        {aff = "stupidity",    code = "STU"},
        {aff = "manaleech",    code = "MNL"},
        {aff = "confusion",    code = "CNF"},
        {aff = "shyness",      code = "SHY"},
        {aff = "paranoia",     code = "PRN"},
        {aff = "dementia",     code = "DEM"},
    }
    local affStr = ""
    for _, entry in ipairs(allAffs) do
        if shamanOffense.hasAff(entry.aff) then
            affStr = affStr .. "<green>" .. entry.code .. "<reset> "
        end
    end
    if affStr == "" then affStr = "<red>none<reset> " end

    -- Cooldowns (show what's ready)
    local cdStr = ""
    if ataxiaTemp then
        if not ataxiaTemp.relapse then cdStr = cdStr .. "<green>REL<reset> "
        else cdStr = cdStr .. "<red>REL<reset> " end
        if not ataxiaTemp.bloodlet then cdStr = cdStr .. "<green>BLD<reset> "
        else cdStr = cdStr .. "<red>BLD<reset> " end
        if not ataxiaTemp.coagulate then cdStr = cdStr .. "<green>COA<reset> "
        else cdStr = cdStr .. "<red>COA<reset> " end
        if ataxiaTemp.canJinx then cdStr = cdStr .. "<green>JNX<reset> "
        else cdStr = cdStr .. "<red>JNX<reset> " end
    end
    local chargeStr = "<dim_grey>SC:" .. (curseCharge or 0) .. "<reset>"
    local bleedStr = "<dim_grey>BL:" .. (tAffs.bleed or 0) .. "<reset>"
    local treeStr = (tBals and tBals.tree) and " <sienna>TREE<reset>" or ""

    -- Mode/strategy header
    cecho("\n<cyan>[SHAM]<reset> <yellow>" .. shamanOffense.state.mode .. "/" .. shamanOffense.state.strategy .. "<reset>" .. lockStr .. treeStr)
    -- Affs line
    cecho("\n<cyan>[SHAM]<reset> " .. affStr .. "| " .. cdStr .. "| " .. chargeStr .. " " .. bleedStr)
end

-- =============================================================================
-- SECTION 9: MAIN DISPATCH
-- =============================================================================

function shamanOffense.dispatch()
    -- Target validation
    if not target or type(target) ~= "string" or target == "" then
        shamanOffense.echo("No target set")
        return
    end

    -- Aeon check
    if ataxia and ataxia.afflictions and ataxia.afflictions.aeon then return end

    -- Balance gate (prevent stale-state dispatch)
    if gmcp and gmcp.Char and gmcp.Char.Vitals and gmcp.Char.Vitals.bal ~= "1" then
        return
    end

    -- Rebound hold gate
    if reboundHold and reboundHold.gate(shamanOffense.dispatch) then return end

    -- One-time spirit binding warning
    if not shamanOffense.state.spiritWarningShown then
        shamanOffense.state.spiritWarningShown = true
        if shaman and shaman.spiritisbound then
            local REQUIRED_SPIRITS = {"marak", "teraile", "aspar", "syvis", "maligus"}
            local missing = {}
            for _, spirit in ipairs(REQUIRED_SPIRITS) do
                if not shaman.spiritisbound(spirit) then
                    table.insert(missing, spirit)
                end
            end
            if #missing > 0 then
                shamanOffense.echo("<red>WARNING: Missing spirit bindings: " .. table.concat(missing, ", ") .. "<reset>")
                shamanOffense.echo("Use: <white>sp create combat binds marak teraile aspar syvis maligus attunes marak teraile maligus tether anthius<reset>")
                shamanOffense.echo("Then: <white>sp combat<reset> to load it")
            end
        end
    end

    -- Initialize tracking vars to safe defaults
    curseCharge = curseCharge or 0
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.canJinx = ataxiaTemp.canJinx or false
    ataxiaTemp.bloodlet = ataxiaTemp.bloodlet or false
    ataxiaTemp.coagulate = ataxiaTemp.coagulate or false
    ataxiaTemp.relapse = ataxiaTemp.relapse or false
    ataxiaTemp.dollFashions = ataxiaTemp.dollFashions or 0
    tAffs = tAffs or {}
    tAffs.bleed = tAffs.bleed or 0

    -- Compute strategy based on current mode + game state
    shamanOffense.computeStrategy()

    -- Build and send attack
    local atk = shamanOffense.buildAttack()
    shamanOffense.sendAttack(atk)
end

-- =============================================================================
-- SECTION 10: MODE SETTERS & UTILITIES
-- =============================================================================

function shamanOffense.setMode(mode)
    local validModes = {group = true, lock = true, bleed = true, damage = true, tzantza = true}
    if not validModes[mode] then
        shamanOffense.echo("Invalid mode: " .. tostring(mode) .. ". Valid: group, lock, bleed, damage, tzantza")
        return
    end
    if shamanOffense.state.mode ~= mode then
        shamanOffense.state.mode = mode
        shamanOffense.echo("Mode: <green>" .. mode .. "<reset>")
    end
end

function shamanOffense.status()
    local soft, hard, truelock = shamanOffense.checkLock()

    shamanOffense.echo("=== Shaman Offense Status ===")
    shamanOffense.echo("Mode: <green>" .. (shamanOffense.state.mode or "?") .. "<reset>")
    shamanOffense.echo("Strategy: <cyan>" .. (shamanOffense.state.strategy or "?") .. "<reset>")

    -- Tracking system
    local tracking = "V1"
    if affConfigV3 and affConfigV3.enabled then tracking = "V3"
    elseif ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then tracking = "V2"
    end
    shamanOffense.echo("Tracking: " .. tracking)

    -- Ability status
    shamanOffense.echo("Swiftcurse: " .. (curseCharge or 0) .. " charges")
    shamanOffense.echo("Jinx: " .. ((ataxiaTemp and ataxiaTemp.canJinx) and "<green>READY" or "<red>NOT READY") .. "<reset>")
    shamanOffense.echo("Bloodlet: " .. ((ataxiaTemp and ataxiaTemp.bloodlet) and "<red>COOLDOWN" or "<green>READY") .. "<reset>")
    shamanOffense.echo("Coagulate: " .. ((ataxiaTemp and ataxiaTemp.coagulate) and "<red>COOLDOWN" or "<green>READY") .. "<reset>")
    shamanOffense.echo("Relapse: " .. ((ataxiaTemp and ataxiaTemp.relapse) and "<red>COOLDOWN" or "<green>READY") .. "<reset>")
    shamanOffense.echo("Bleed: " .. (tAffs and tAffs.bleed or 0))
    shamanOffense.echo("Doll Fashions: " .. (ataxiaTemp and ataxiaTemp.dollFashions or 0))

    -- Lock status
    local lockStr = "NONE"
    if truelock then lockStr = "<red>TRUELOCK<reset>"
    elseif hard then lockStr = "<orange>HARDLOCK<reset>"
    elseif soft then lockStr = "<yellow>SOFTLOCK<reset>"
    end
    shamanOffense.echo("Lock: " .. lockStr)

    -- Missing lock pieces
    local missing = {}
    for _, aff in ipairs(TRUELOCK_AFFS) do
        if not shamanOffense.hasAff(aff) then
            table.insert(missing, aff)
        end
    end
    if #missing > 0 then
        shamanOffense.echo("Missing: <red>" .. table.concat(missing, ", ") .. "<reset>")
    end

    -- Spirits
    if shaman and shaman.spiritisbound then
        local spirits = {}
        local COMBAT_SPIRITS = {"teraile", "aspar", "syvis", "marak", "arayan"}
        for _, spirit in ipairs(COMBAT_SPIRITS) do
            if shaman.spiritisbound(spirit) then
                table.insert(spirits, "<green>" .. spirit .. "<reset>")
            else
                table.insert(spirits, "<red>" .. spirit .. "<reset>")
            end
        end
        shamanOffense.echo("Spirits: " .. table.concat(spirits, ", "))
    end
end

function shamanOffense.reset()
    shamanOffense.state.mode = "group"
    shamanOffense.state.strategy = "group"
    shamanOffense.state.dollTarget = nil
    shamanOffense.state.relapseTarget = nil
    shamanOffense.state.swiftFired = false
    shamanOffense.state.jinxUsedThisCycle = false
    shamanOffense.state.spiritWarningShown = false
    shamanOffense.echo("State reset (group mode)")
end

-- =============================================================================
-- SECTION 11: ALIAS REGISTRATION
-- =============================================================================

-- Clean up old aliases
if shamanOffense.aliases then
    for name, id in pairs(shamanOffense.aliases) do
        if id and killAlias then
            killAlias(id)
        end
    end
end
shamanOffense.aliases = {}

if tempAlias then
    shamanOffense.aliases.shgroup = tempAlias("^shgroup$", [[
        shamanOffense.setMode("group")
        shamanOffense.dispatch()
    ]])

    shamanOffense.aliases.shlock = tempAlias("^shlock$", [[
        shamanOffense.setMode("lock")
        shamanOffense.dispatch()
    ]])

    shamanOffense.aliases.shbleed = tempAlias("^shbleed$", [[
        shamanOffense.setMode("bleed")
        shamanOffense.dispatch()
    ]])

    shamanOffense.aliases.shdmg = tempAlias("^shdmg$", [[
        shamanOffense.setMode("damage")
        shamanOffense.dispatch()
    ]])

    shamanOffense.aliases.shtz = tempAlias("^shtz$", [[
        shamanOffense.setMode("tzantza")
        shamanOffense.dispatch()
    ]])

    shamanOffense.aliases.shstatus = tempAlias("^shstatus$", [[shamanOffense.status()]])
    shamanOffense.aliases.shreset = tempAlias("^shreset$", [[shamanOffense.reset()]])


    shamanOffense.aliases.shspirits = tempAlias("^shspirits$", [[
        shamanOffense.echo("=== Recommended Combat Spirit Profile ===")
        shamanOffense.echo("Bindings (5): teraile, aspar, syvis, marak, arayan")
        shamanOffense.echo("  teraile = invoke bloodlet (haemophilia + bleed)")
        shamanOffense.echo("  aspar   = invoke coagulation (bleed -> slickness)")
        shamanOffense.echo("  syvis   = invoke relapse (aff relapses after cure)")
        shamanOffense.echo("  marak   = invoke soulscourge (mana pressure)")
        shamanOffense.echo("  maligus = invoke soulrend (enhanced mana pressure)")
        shamanOffense.echo("Attunements (3): marak (+constitution), teraile (bleed on curses), maligus (drain health/mana)")
        shamanOffense.echo("Tether: anthius")
        shamanOffense.echo("")
        shamanOffense.echo("To create: <white>sp create combat binds marak teraile aspar syvis maligus attunes marak teraile maligus tether anthius<reset>")
        shamanOffense.echo("To load:   <white>sp combat<reset>")
        if shaman and shaman.spiritisbound then
            local REQUIRED_SPIRITS = {"marak", "teraile", "aspar", "syvis", "maligus"}
            local bound, missing = {}, {}
            for _, spirit in ipairs(REQUIRED_SPIRITS) do
                if shaman.spiritisbound(spirit) then
                    table.insert(bound, spirit)
                else
                    table.insert(missing, spirit)
                end
            end
            shamanOffense.echo("Currently bound: " .. (#bound > 0 and "<green>" .. table.concat(bound, ", ") .. "<reset>" or "none"))
            if #missing > 0 then
                shamanOffense.echo("Missing: <red>" .. table.concat(missing, ", ") .. "<reset>")
            end
        end
    ]])
end

shamanOffense.echo("<green>Shaman Offense loaded<reset> (mode: " .. shamanOffense.state.mode .. ")")
