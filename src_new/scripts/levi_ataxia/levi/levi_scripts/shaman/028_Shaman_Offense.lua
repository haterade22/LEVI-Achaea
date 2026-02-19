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
    - SWIFTCURSE (0.8s): Fast single curse. Gated by curseCharge > 1. PRIMARY for group.
    - CURSE+INVOKE (2.0s): Standard curse + bonus action. Fallback.
    - JINX (2.2s): 2 curses per balance. Gated by ataxiaTemp.canJinx. Used when recharging.

    INVOKE ABILITIES (bonus action on curse):
    - bloodlet: Apply haemophilia + start bleeding. Cooldown tracked.
    - coagulation: Convert bleed into slickness. Requires aspar spirit + bleed >= 100.
    - relapse: Force affliction to relapse after cure. Requires syvis spirit.
    - soulscourge: Mana damage.
    - soulrend: Mana damage (higher, requires doll fashions > 0).

    MODES:
    - group: Reactive gap-filling for group true lock (PRIMARY)
    - lock: Solo lock progression with invoke support
    - damage: Haemophilia/bleed pressure
    - tzantza: Mental aff stack for tzantza kill

    ALIASES (via tempAlias):
    - shgroup   : Group lock mode
    - shlock    : Solo lock mode
    - shdmg     : Damage mode
    - shtz      : Tzantza mode
    - shstatus  : Status display
    - shreset   : Reset state

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

-- Configuration
shamanOffense.config.debug = shamanOffense.config.debug or false
shamanOffense.config.echoStrategy = true
shamanOffense.config.partyRelay = true

-- =============================================================================
-- SECTION 2: CONSTANTS
-- =============================================================================

-- Group lock priority table: ordered by impact for achieving truelock ASAP
-- Scan top-down, curse the first aff the target DOESN'T have
local GROUP_PRIORITY = {
    {aff = "impatience",  curse = "impatience",  cure = "goldenseal"},
    {aff = "asthma",      curse = "asthma",      cure = "kelp"},
    {aff = "paralysis",   curse = "paralyse",    cure = "bloodroot"},
    {aff = "anorexia",    curse = "anorexia",    cure = "kelp"},
    {aff = "slickness",   curse = "gecko",       cure = "smoke"},
    {aff = "weariness",   curse = "weariness",   cure = "kelp"},
    {aff = "clumsiness",  curse = "clumsy",      cure = "kelp"},
    {aff = "stupidity",   curse = "stupid",      cure = "goldenseal"},
    {aff = "nausea",      curse = "vomiting",    cure = "ginseng"},
    {aff = "addiction",   curse = "addiction",    cure = "ginseng"},
    {aff = "sensitivity", curse = "sensitivity", cure = "kelp"},
    {aff = "healthleech", curse = "healthleech", cure = "kelp"},
    {aff = "dizziness",   curse = "dizzy",       cure = "goldenseal"},
    {aff = "recklessness",curse = "reckless",    cure = "lobelia"},
    {aff = "masochism",   curse = "masochism",   cure = "lobelia"},
    {aff = "dementia",    curse = "dementia",    cure = "ash"},
    {aff = "vertigo",     curse = "vertigo",     cure = "lobelia"},
}

-- Core lock afflictions (for truelock detection)
local TRUELOCK_AFFS = {"asthma", "anorexia", "slickness", "impatience", "paralysis"}

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
    Select curses for group/lock mode.
    Returns: primary (string), secondary (string or nil)

    For jinx pairing: prefer secondary on a DIFFERENT cure path to overwhelm curing.
    E.g. impatience(goldenseal) + asthma(kelp) = two different herb paths
]]--
function shamanOffense.selectGroupCurses()
    local primary, secondary = nil, nil
    local primaryCure = nil

    for _, entry in ipairs(GROUP_PRIORITY) do
        if not shamanOffense.hasAff(entry.aff) then
            if not primary then
                primary = entry.curse
                primaryCure = entry.cure
            elseif not secondary then
                -- For jinx: prefer different cure path
                if ataxiaTemp and ataxiaTemp.canJinx and entry.cure ~= primaryCure then
                    secondary = entry.curse
                    break
                elseif not (ataxiaTemp and ataxiaTemp.canJinx) then
                    -- No jinx, only need primary
                    break
                end
            end
        end
    end

    -- If jinx available but no different-cure-path secondary found, take any
    if ataxiaTemp and ataxiaTemp.canJinx and primary and not secondary then
        for _, entry in ipairs(GROUP_PRIORITY) do
            if not shamanOffense.hasAff(entry.aff) and entry.curse ~= primary then
                secondary = entry.curse
                break
            end
        end
    end

    return primary, secondary
end

-- =============================================================================
-- SECTION 6: INVOKE SELECTION
-- =============================================================================

--[[
    Determine the best invoke for a regular curse round.
    Returns: invoke command string or nil

    Only used when falling back to regular curse (no swiftcurse, no jinx).
    Invokes are bonus actions appended to curse.
]]--
function shamanOffense.selectInvoke(primaryCurse)
    -- Bloodlet: haemophilia + start bleed
    if ataxiaTemp and not ataxiaTemp.bloodlet
       and not shamanOffense.hasAff("haemophilia")
       and shamanOffense.hasAff("paralysis")
       and primaryCurse ~= "haemophilia" then
        return "invoke bloodlet " .. target
    end

    -- Coagulation: convert bleed → slickness
    if ataxiaTemp and not ataxiaTemp.coagulate
       and shaman and shaman.spiritisbound and shaman.spiritisbound("aspar")
       and (tAffs.bleed or 0) >= 100
       and shamanOffense.hasAff("haemophilia")
       and not shamanOffense.hasAff("slickness") then
        return "invoke coagulation slickness"
    end

    -- Relapse: force affliction to relapse after cure
    if ataxiaTemp and not ataxiaTemp.relapse
       and shaman and shaman.spiritisbound and shaman.spiritisbound("syvis")
       and shamanOffense.hasAff("impatience") then
        local classAff = getLockingAffliction and getLockingAffliction() or nil
        if classAff
           and classAff ~= "weariness"
           and classAff ~= "confusion"
           and classAff ~= "plague"
           and not shamanOffense.hasAff(classAff) then
            return "invoke relapse " .. classAff
        end
    end

    -- Soulrend: mana pressure when doll fashions available
    if ataxiaTemp and ataxiaTemp.dollFashions and ataxiaTemp.dollFashions > 0 then
        if shamanOffense.hasAff("manaleech") then
            return "invoke soulrend " .. target
        end
        return "invoke soulscourge"
    end

    return nil
end

-- =============================================================================
-- SECTION 7: ATTACK BUILDING
-- =============================================================================

function shamanOffense.buildAttack()
    local atk = combatQueue and combatQueue() or ""
    local strategy = shamanOffense.state.strategy

    -- Prefix: wield shield + doll, vodun status
    local prefix = "wield shield doll {" .. target .. "};vodun status;"

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
        else
            atk = atk .. prefix .. "curse " .. target .. " plague invoke soulscourge"
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
            atk = atk .. prefix .. "curse " .. target .. " " .. classAff .. " invoke soulscourge"
        end
        return atk
    end

    -- ==========================================
    -- GROUP / LOCK STRATEGY (main offense)
    -- ==========================================
    if strategy == "group" or strategy == "lock" then
        local primary, secondary = shamanOffense.selectGroupCurses()

        -- If all tracked affs are present, deliver class lock aff or pressure
        if not primary then
            local classAff = getLockingAffliction and getLockingAffliction() or "weariness"
            if not shamanOffense.hasAff(classAff) then
                primary = classAff
            else
                primary = "plague"
            end
        end

        -- ===== PRIORITY 1: SWIFTCURSE (0.8s, king of group fights) =====
        if curseCharge and curseCharge > 1 then
            atk = atk .. prefix .. "swiftcurse " .. target .. " " .. primary
            return atk
        end

        -- ===== PRIORITY 2: SWIFTCURSE RECHARGE — prefer jinx if available =====
        if curseCharge and curseCharge <= 1 then
            -- If jinx ready, use it instead of wasting balance on bare recharge
            if ataxiaTemp and ataxiaTemp.canJinx and primary and secondary then
                atk = atk .. "stand;" .. prefix .. "jinx " .. primary .. " " .. secondary .. " " .. target
                return atk
            end
            -- Otherwise just recharge
            atk = atk .. prefix .. "swiftcurse"
            return atk
        end

        -- ===== PRIORITY 3: JINX (no swiftcurse charges at all) =====
        if ataxiaTemp and ataxiaTemp.canJinx and primary and secondary then
            atk = atk .. "stand;" .. prefix .. "jinx " .. primary .. " " .. secondary .. " " .. target
            return atk
        end

        -- ===== PRIORITY 4: REGULAR CURSE + INVOKE =====
        local invoke = shamanOffense.selectInvoke(primary)
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
        elseif ataxiaTemp and not ataxiaTemp.bloodlet then
            atk = atk .. prefix .. "curse " .. target .. " asthma invoke bloodlet " .. target
        elseif ataxiaTemp and not ataxiaTemp.coagulate
               and shaman and shaman.spiritisbound and shaman.spiritisbound("aspar")
               and (tAffs.bleed or 0) >= 100 then
            atk = atk .. prefix .. "curse " .. target .. " anorexia invoke coagulation slickness"
        else
            -- Pressure curse with mana damage
            local primary = shamanOffense.selectGroupCurses()
            primary = primary or "asthma"
            if curseCharge and curseCharge > 1 then
                atk = atk .. prefix .. "swiftcurse " .. target .. " " .. primary
            else
                atk = atk .. prefix .. "curse " .. target .. " " .. primary .. " invoke soulscourge"
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
            atk = atk .. prefix .. "curse " .. target .. " tzantza invoke soulscourge vodun bind"
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

    -- Strategy echo
    if shamanOffense.config.echoStrategy then
        local soft, hard, truelock = shamanOffense.checkLock()
        local lockStr = ""
        if truelock then lockStr = " <red>[TRUELOCK]<reset>"
        elseif hard then lockStr = " <orange>[HARDLOCK]<reset>"
        elseif soft then lockStr = " <yellow>[SOFTLOCK]<reset>"
        end
        cecho("\n<dim_grey>[" .. shamanOffense.state.mode .. "/" .. shamanOffense.state.strategy .. "]" .. lockStr .. "<reset>")
    end
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
    local validModes = {group = true, lock = true, damage = true, tzantza = true}
    if not validModes[mode] then
        shamanOffense.echo("Invalid mode: " .. tostring(mode) .. ". Valid: group, lock, damage, tzantza")
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
        if shaman.spiritisbound("aspar") then table.insert(spirits, "aspar") end
        if shaman.spiritisbound("syvis") then table.insert(spirits, "syvis") end
        if shaman.spiritisbound("teraile") then table.insert(spirits, "teraile") end
        if shaman.spiritisbound("marak") then table.insert(spirits, "marak") end
        shamanOffense.echo("Spirits: " .. (#spirits > 0 and table.concat(spirits, ", ") or "none"))
    end
end

function shamanOffense.reset()
    shamanOffense.state.mode = "group"
    shamanOffense.state.strategy = "group"
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
end

shamanOffense.echo("<green>Shaman Offense loaded<reset> (mode: " .. shamanOffense.state.mode .. ")")
