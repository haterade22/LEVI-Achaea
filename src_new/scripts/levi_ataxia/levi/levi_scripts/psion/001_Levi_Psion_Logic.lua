--[[mudlet
type: script
name: Levi Psion Logic
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Psion
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    PSION OFFENSE SYSTEM (V3-Aware Rebuild)
    ============================================================================

    Unified psion offense with V3 affliction tracking.

    ATTACK STRUCTURE (per balance):
    - PSI TRANSCEND <type> <target>     : Resource spend (blast/excise/muddle/shatter)
    - WEAVE PREPARE <disruption>        : Free affliction (paralysis/haemophilia/asthma/epilepsy)
    - WEAVE <attack> <target>           : Main attack (overhand/backhand/deathblow/unweave/etc.)
    - Plus: lightbind, assess, contemplate as suffixes

    KILL ROUTES:
    - Psi Excise (mana kill): Stack plumbum affs → Psi Blast → Mind Ravaged → drain mana → excise at 30%
    - Deconstruct (unweave kill): Any TWO unweaves at level 3+ = instant kill
    - Flurry (damage burst): High spirit unweave level → massive % HP damage

    MODES:
    - mind   : Primary mode — unweave pressure + mana kill via psi blast/excise
    - flurry : Damage mode — invert unweaves to spirit, then flurry for burst damage

    REBOUNDING (recent change):
    - Regular weave attacks ARE blocked by rebounding
    - Unweaves, Entwine, Finishers (Deconstruct) BYPASS rebounding
    - When rebounding detected + non-bypass weave needed → cleave to strip

    ALIASES (via tempAlias):
    - psmind   : Mind mode + dispatch
    - psflurry : Flurry mode + dispatch
    - psstatus : Status display
    - psreset  : Reset state

    EXTERNAL ALIASES:
    - zz : Main attack dispatch (152_First_Attack)
    ============================================================================
]]--

-- =============================================================================
-- SECTION 1: NAMESPACE & STATE
-- =============================================================================

psion = psion or {}
psion.state = psion.state or {}
psion.config = psion.config or {}

-- State defaults (preserved across reloads via `or`)
psion.state.mode = psion.state.mode or "mind"
psion.state.attackInFlight = psion.state.attackInFlight or false

-- Config defaults
psion.config.debug = psion.config.debug or false
psion.config.echoStrategy = (psion.config.echoStrategy == nil) and true or psion.config.echoStrategy
psion.config.partyRelay = (psion.config.partyRelay == nil) and true or psion.config.partyRelay

-- =============================================================================
-- SECTION 2: CONSTANTS
-- =============================================================================

local PSI_BLAST_AFFS = {"impatience", "stupidity", "blackout", "dizziness", "epilepsy", "unweavingmind"}

local PRIEST_OCC_PARIAH = {
  Priest = true,
  Occultist = true,
  Pariah = true,
}

-- =============================================================================
-- SECTION 3: HELPERS
-- =============================================================================

function psion.hasAff(aff)
  return haveAff(aff)
end

function psion.getAffProb(aff)
  return getAffProbabilityV3 and getAffProbabilityV3(aff) or 0
end

function psion.echo(text)
  cecho("\n<medium_purple>[<plum>Psion<medium_purple>]<reset> " .. text)
end

function psion.decho(text)
  if psion.config.debug then
    psion.echo(text)
  end
end

--- V1 fallback for rebounding on TARGET
--- GMCP timing gap: balance fires before text triggers in same data chunk,
--- so haveAff() may return false for a frame. V1 fallback prevents missed strips.
function psion.hasRebounding()
  return haveAff("rebounding") or (tAffs and tAffs.rebounding)
end

--- V1 fallback for shield on TARGET (same GMCP timing gap)
function psion.hasShield()
  return haveAff("shield") or (tAffs and tAffs.shield)
end

--- Check if 2+ critical unweaves present (deconstruct kill condition)
function psion.canDeconstruct()
  local count = 0
  if psion.hasAff("criticalmind") then count = count + 1 end
  if psion.hasAff("criticalbody") then count = count + 1 end
  if psion.hasAff("criticalspirit") then count = count + 1 end
  return count >= 2
end

--- Check psi blast criteria (3+ of the 6 qualifying affs)
function psion.canPsiBlast()
  if not checkAffList then return false end
  return checkAffList(PSI_BLAST_AFFS, 3)
end

--- Check if a limb is prepped (one more weave hit would break it)
function psion.isLimbPrepped(limb)
  if not lb or not target or not lb[target] or not lb[target].hits then return false end
  local weavesDmg = ataxiaTables and ataxiaTables.limbData and ataxiaTables.limbData.psionweaves or 25
  return (lb[target].hits[limb] or 0) + weavesDmg >= 100
end

--- Check if head is double-prepped (two weave hits would break it)
function psion.isHeadDoublePrepped()
  if not lb or not target or not lb[target] or not lb[target].hits then return false end
  local weavesDmg = ataxiaTables and ataxiaTables.limbData and ataxiaTables.limbData.psionweaves or 25
  return (lb[target].hits["head"] or 0) + (weavesDmg * 2) >= 100
end

--- Check if a weave command bypasses rebounding
local function weaveBypassesRebounding(weave)
  return weave == "unweave mind" or weave == "unweave body" or weave == "unweave spirit"
      or weave == "deconstruct"
end

-- =============================================================================
-- SECTION 4: PREPARE SELECTION
-- =============================================================================

--- Select the weave prepare affliction (free aff delivered with every attack)
--- Priority: laceration (if mindravaged), disruption (paralysis), laceration (haemophilia),
---           vapours (asthma), rattle (epilepsy/fallback)
function psion.selectPrepare()
  local has = psion.hasAff

  -- Mind ravaged: prioritize bleed pressure
  if has("mindravaged") and not has("haemophilia") then return "laceration" end

  -- Flurry mode: prioritize epilepsy when impatience already present
  if psion.state.mode == "flurry" and has("impatience") and not has("epilepsy") then
    return "rattle"
  end

  -- Standard priority chain
  if not has("paralysis") then return "disruption" end
  if not has("haemophilia") then return "laceration" end
  if not has("asthma") then return "vapours" end
  return "rattle"
end

-- =============================================================================
-- SECTION 5: WEAVE SELECTION
-- =============================================================================

--- Select the main weave attack. Unified logic for both mind and flurry modes.
--- @param prepare string The selected prepare (to avoid duplicate asthma delivery)
--- @return string The weave command name
function psion.selectWeave(prepare)
  local has = psion.hasAff
  local mode = psion.state.mode

  -- Priority 1: Deconstruct (instant kill — 2+ critical unweaves)
  if psion.canDeconstruct() then return "deconstruct" end

  -- Priority 2: [Flurry only] Inverted + ready → flurry burst
  if mode == "flurry" and (inverted or false) then return "flurry" end

  -- Priority 3: Head attacks for impatience/stupidity/dizziness delivery
  -- Impatience requires: damaged head OR target prone
  if has("damagedhead") and not has("impatience") then
    return "overhand"
  end

  if psion.isLimbPrepped("head") and not has("damagedhead") then
    -- Head is prepped (one hit breaks it) — choose best head attack
    if not has("impatience") then
      return "overhand"  -- Break head + deliver impatience
    elseif not has("stupidity") or not has("dizziness") then
      return "backhand"  -- Break head + deliver stupidity/dizziness
    elseif not has("asthma") and prepare ~= "vapours" then
      return "deathblow"  -- Break head + deliver asthma + bleed
    end
  end

  -- [Mind mode only] Double-head prep → deathblow for asthma
  if mode == "mind" and psion.isHeadDoublePrepped() and not has("asthma") then
    return "deathblow"
  end

  -- Priority 4: Prone target — exploit for impatience/mentals
  if has("prone") then
    if not has("impatience") then
      return "overhand"  -- Prone + overhand = impatience
    elseif not has("stupidity") or not has("dizziness") then
      return "backhand"  -- Prone + backhand = stupidity/dizziness
    end
  end

  -- Priority 5: [Not mind-ravaged, mind mode] Standing backhand for mentals
  if not has("mindravaged") and mode == "mind" then
    if has("impatience") and (not has("stupidity") or not has("dizziness")) then
      return "backhand"
    end
  end

  -- Priority 6: Unweave spirit (when mind+body applied, asthma blocks cure)
  if not has("mindravaged") and has("unweavingmind") and has("unweavingbody")
      and not has("unweavingspirit") and has("asthma") then
    return "unweave spirit"
  end

  -- Priority 7: Both primary unweaves applied → filler affs (class-aware)
  local bothUnweaves = has("unweavingmind") and has("unweavingbody")
  -- When mind-ravaged: unweavingmind is redundant (ravaged already drains mana),
  -- so we only need unweavingbody applied before moving to fillers
  if has("mindravaged") then
    bothUnweaves = has("unweavingbody")
  end

  if bothUnweaves then
    local targetClass = ataxiaNDB_getClass and ataxiaNDB_getClass(target) or ""
    if PRIEST_OCC_PARIAH[targetClass] then
      -- Priest/Occultist/Pariah: weariness first (blocks Fitness)
      if not has("weariness") then return "puncture" end
      if not has("clumsiness") then return "sever" end
    else
      -- Other classes: clumsiness first (33% miss chance on them)
      if not has("clumsiness") then return "sever" end
      if not has("weariness") then return "puncture" end
    end
    -- Both fillers applied: deathblow for asthma if available
    if not has("asthma") and prepare ~= "vapours" then
      return "deathblow"
    end
  end

  -- Priority 8: Apply missing unweaves
  if not has("unweavingbody") then return "unweave body" end
  if not has("unweavingmind") then return "unweave mind" end

  -- Fallback
  return "unweave mind"
end

-- =============================================================================
-- SECTION 6: TRANSCEND SELECTION
-- =============================================================================

--- Select psi transcend ability
function psion.selectTranscend()
  local mana = pm or 100
  if mana <= 30 then return "excise" end
  if psion.canPsiBlast() and not psion.hasAff("mindravaged") then return "blast" end
  if not psion.hasAff("muddled") then return "muddle" end
  return "shatter"
end

-- =============================================================================
-- SECTION 7: ATTACK BUILDER
-- =============================================================================

--- Build the complete attack string (without prefix/suffix)
--- @return string The attack command chain
function psion.buildAttack()
  local sp = ataxia.settings.separator or "::"
  local atk = combatQueue and combatQueue() or ""

  local prepare = psion.selectPrepare()
  local weave = psion.selectWeave(prepare)
  local transcend = psion.selectTranscend()
  local hasRebounding = psion.hasRebounding()
  local hasShield = psion.hasShield()

  -- Store selections for combat echo
  psion.state.lastPrepare = prepare
  psion.state.lastWeave = weave
  psion.state.lastTranscend = transcend

  -- Priority 1: Shield strip (cleave)
  if hasShield then
    return atk .. "psi transcend " .. transcend .. " " .. target
      .. sp .. "weave prepare " .. prepare
      .. sp .. "weave cleave " .. target
  end

  -- Priority 2: Mana kill execute (≤30%)
  if (pm or 100) <= 30 then
    return atk .. "psi transcend " .. transcend .. " " .. target
      .. sp .. "psi excise " .. target
  end

  -- Priority 3: Rebounding strip (cleave) — only for non-bypass weaves
  if hasRebounding and not weaveBypassesRebounding(weave) then
    psion.decho("Rebounding up — cleaving to strip")
    return atk .. "psi transcend " .. transcend .. " " .. target
      .. sp .. "weave prepare " .. prepare
      .. sp .. "weave cleave " .. target
  end

  -- Priority 4: [Flurry mode] Invert conditions
  if psion.state.mode == "flurry" then
    local isInverted = inverted or false
    if isInverted and (psion.hasAff("unweavingspirit") or psion.hasAff("criticalspirit")) then
      return atk .. "psi transcend shatter " .. target
        .. sp .. "weave prepare " .. prepare
        .. sp .. "weave flurry " .. target
    elseif psion.hasAff("criticalmind") and not psion.hasAff("criticalspirit") and not isInverted then
      return atk .. "weave prepare " .. prepare
        .. sp .. "weave invert " .. target .. " mind spirit"
    elseif psion.hasAff("criticalbody") and not psion.hasAff("criticalspirit") and not isInverted then
      return atk .. "weave prepare " .. prepare
        .. sp .. "weave invert " .. target .. " body spirit"
    end
  end

  -- Priority 5: Normal attack — transcend + prepare + weave
  local weaveCmd
  if weave == "unweave mind" then
    weaveCmd = "weave unweave " .. target .. " mind"
  elseif weave == "unweave body" then
    weaveCmd = "weave unweave " .. target .. " body"
  elseif weave == "unweave spirit" then
    weaveCmd = "weave unweave " .. target .. " spirit"
  elseif weave == "deconstruct" then
    weaveCmd = "weave deconstruct " .. target
  else
    weaveCmd = "weave " .. weave .. " " .. target
  end

  return atk .. "psi transcend " .. transcend .. " " .. target
    .. sp .. "weave prepare " .. prepare
    .. sp .. weaveCmd
end

-- =============================================================================
-- SECTION 8: SEND ATTACK
-- =============================================================================

--- Send the built attack with prefix (wield shield) and suffix (lightbind, assess, contemplate)
--- @param atk string The attack command chain from buildAttack()
function psion.sendAttack(atk)
  if not atk or atk == "" then return end

  -- Target presence check
  if ataxia and ataxia.playersHere and not table.contains(ataxia.playersHere, target) then
    psion.decho("Target not in room")
    return
  end

  local sp = ataxia.settings.separator or "::"

  -- Prefix: wield shield
  local prefix = "wield right shield" .. sp

  -- Suffix: lightbind + assess + contemplate
  local suffix = ""
  if not (lightbind or false) then
    suffix = suffix .. sp .. "enact lightbind " .. target
  end
  suffix = suffix .. sp .. "assess " .. target .. sp .. "contemplate " .. target

  send("queue addclear free " .. prefix .. atk .. suffix)
end

-- =============================================================================
-- SECTION 9: DISPATCH (MAIN ENTRY POINT)
-- =============================================================================

--- Main dispatch function — called by zz alias or directly
function psion.dispatch()
  -- Target validation
  if not target or type(target) ~= "string" or target == "" then
    psion.echo("No target set")
    return
  end

  -- Aeon check
  if ataxia and ataxia.afflictions and ataxia.afflictions.aeon then return end

  -- Balance gate (prevent stale-state dispatch)
  if gmcp and gmcp.Char and gmcp.Char.Vitals and gmcp.Char.Vitals.bal ~= "1" then return end

  -- Rebound hold gate (OUR defensive rebounding timing)
  if reboundHold and reboundHold.gate(psion.dispatch) then return end

  -- Safe defaults for globals
  pm = pm or 100
  tAffs = tAffs or {}
  lightbind = lightbind or false

  -- Pre-combat utilities
  if getLockingAffliction then getLockingAffliction() end
  if checkTargetLocks then checkTargetLocks() end

  -- Build and send
  local atk = psion.buildAttack()
  psion.sendAttack(atk)

  -- Combat echo
  if psion.config.echoStrategy then
    psion.combatEcho()
  end
end

-- =============================================================================
-- SECTION 10: MODE & STATUS
-- =============================================================================

--- Set offense mode
--- @param mode string "mind" or "flurry"
function psion.setMode(mode)
  local valid = { mind = true, flurry = true }
  if not valid[mode] then
    psion.echo("Invalid mode. Valid: <green>mind<reset>, <green>flurry")
    return
  end
  psion.state.mode = mode
  psion.echo("Mode: <green>" .. mode)
end

--- Reset state (on target change or manual reset)
function psion.reset()
  psion.state.attackInFlight = false
  psion.state.lastPrepare = nil
  psion.state.lastWeave = nil
  psion.state.lastTranscend = nil
  psion.echo("State reset")
end

--- Compact one-line combat echo
function psion.combatEcho()
  local w = psion.state.lastWeave or "?"
  local p = psion.state.lastPrepare or "?"
  local t = psion.state.lastTranscend or "?"
  local mode = psion.state.mode or "mind"

  -- Color-code weave type
  local wColor
  if w:find("unweave") then wColor = "<cyan>"
  elseif w == "deconstruct" then wColor = "<red>"
  elseif w == "flurry" then wColor = "<orange>"
  elseif w == "overhand" or w == "backhand" then wColor = "<yellow>"
  else wColor = "<white>" end

  -- Lock status
  local lockStr = ""
  if psion.hasAff("asthma") and psion.hasAff("anorexia") and psion.hasAff("slickness") then
    if psion.hasAff("impatience") and psion.hasAff("paralysis") then
      lockStr = " <red>[TRUELOCK]"
    elseif psion.hasAff("impatience") then
      lockStr = " <orange>[HARDLOCK]"
    else
      lockStr = " <yellow>[SOFTLOCK]"
    end
  end

  -- Psi blast status
  local blastStr = ""
  if psion.canPsiBlast() then
    blastStr = " <DeepSkyBlue>[BLAST RDY]"
  end

  -- Mana status
  local manaStr = ""
  if (pm or 100) <= 30 then
    manaStr = " <red>[EXCISE!]"
  elseif (pm or 100) <= 50 then
    manaStr = " <orange>[LOW MANA]"
  end

  cecho("\n<medium_purple>[<plum>PS<medium_purple>]<reset> "
    .. "<dim_grey>" .. mode .. "<reset> "
    .. wColor .. w .. "<reset> "
    .. "<dim_grey>prep:<reset>" .. p .. " "
    .. "<dim_grey>trans:<reset>" .. t
    .. lockStr .. blastStr .. manaStr)
end

--- Full status display
function psion.status()
  psion.echo("<white>--- Psion Offense Status ---")
  psion.echo("Mode: <green>" .. (psion.state.mode or "mind"))

  -- Unweave levels
  local uwm = psion.hasAff("unweavingmind") and "<green>YES" or "<red>NO"
  local uwb = psion.hasAff("unweavingbody") and "<green>YES" or "<red>NO"
  local uws = psion.hasAff("unweavingspirit") and "<green>YES" or "<red>NO"
  local cm = psion.hasAff("criticalmind") and " <red>[CRIT]" or ""
  local cb = psion.hasAff("criticalbody") and " <red>[CRIT]" or ""
  local cs = psion.hasAff("criticalspirit") and " <red>[CRIT]" or ""
  psion.echo("Unweave Mind: " .. uwm .. cm .. "<reset>  Body: " .. uwb .. cb .. "<reset>  Spirit: " .. uws .. cs)

  -- Kill conditions
  if psion.canDeconstruct() then
    psion.echo("<red>*** DECONSTRUCT READY ***")
  end
  if (pm or 100) <= 30 then
    psion.echo("<red>*** EXCISE READY (mana " .. (pm or 100) .. "%) ***")
  end
  if psion.canPsiBlast() and not psion.hasAff("mindravaged") then
    psion.echo("<DeepSkyBlue>Psi Blast condition met")
  end

  -- Transcendence
  local trans = ataxiaTemp and ataxiaTemp.transcendence or 0
  psion.echo("Transcendence: <white>" .. trans .. "%")

  -- Target mana
  psion.echo("Target Mana: <white>" .. (pm or "?") .. "%")
end

-- =============================================================================
-- SECTION 11: BACKWARD COMPATIBILITY
-- =============================================================================

--- Legacy function — mind mode dispatch
function levipsionmind()
  psion.setMode("mind")
  psion.dispatch()
end

--- Legacy function — flurry mode dispatch
function levipsionflurry()
  psion.setMode("flurry")
  psion.dispatch()
end

-- =============================================================================
-- SECTION 12: ALIASES (tempAlias with reload cleanup)
-- =============================================================================

if psion._aliases then
  for _, id in pairs(psion._aliases) do
    killAlias(id)
  end
end
psion._aliases = {}

psion._aliases.mind = tempAlias("^psmind$", function()
  psion.setMode("mind")
  psion.dispatch()
end)

psion._aliases.flurry = tempAlias("^psflurry$", function()
  psion.setMode("flurry")
  psion.dispatch()
end)

psion._aliases.status = tempAlias("^psstatus$", function()
  psion.status()
end)

psion._aliases.reset = tempAlias("^psreset$", function()
  psion.reset()
end)

psion._aliases.debug = tempAlias("^psdebug$", function()
  psion.config.debug = not psion.config.debug
  psion.echo("Debug: " .. (psion.config.debug and "<green>ON" or "<red>OFF"))
end)
