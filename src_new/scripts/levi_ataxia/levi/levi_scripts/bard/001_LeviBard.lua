--[[mudlet
type: script
name: LeviBard
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Bard
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
================================================================================
BARD OFFENSE SYSTEM
================================================================================

REQUIRED READING before modifying:
- .claude/classes/lock_types.md (lock definitions)
- .claude/classes/bard.md      (class mechanics)

Lock progression: Softlock -> Venomlock -> Hardlock -> Truelock (voyria)
See lock_types.md for affliction requirements and escape routes.

ATTACK STRUCTURE (per balance):
- BLADE <move> <target> <limb?> <refrain>  : Main blade attack (bladedance skill)
  Moves: highsun, jab, heelsnap, flick, punctuate, sunset, sunrise
- Refrain delivery is via blade moves (not a separate queue)

DISPATCH FUNCTIONS:
- bard.dispatchOne()  : Blade attack set 1 — sunrise kill route, sunset tempo
- bard.dispatchTwo()  : Blade attack set 2 — tempo-gated sunset, shorter chain

ALIASES (via tempAlias):
- bardstatus : Status display
- bardreset  : Reset all state and bare globals
- barddebug  : Toggle debug echo
- bardecho   : Toggle per-attack echo

BACKWARD-COMPAT GLOBALS:
- levibardone() / levibardtwo() — wrappers at bottom of file

BARE GLOBALS owned by triggers (do not move to bard.state):
- bardtempostance, bardsunset, bardsunrise, bladefinale, bardtemposequence
- bardtempo       (written by tempo triggers + login)
- rapierdamage    (read by 008_Sunrise.lua and 009_SunSet.lua for lb updates)
- envenomList     (read by external envenom queue system)
================================================================================
]]--

-- =============================================================================
-- SECTION 1: NAMESPACE & STATE
-- =============================================================================

bard = bard or {}
bard.state  = bard.state  or {}
bard.config = bard.config or {}

-- Dispatch-owned state (preserved across reloads via `or`)
bard.state.lastRefrain = bard.state.lastRefrain or nil
bard.state.lastAttack  = bard.state.lastAttack  or nil

-- Fallback init for trigger-written globals.
-- Triggers own these after first fire; this just ensures they exist on load.
bardtempostance   = bardtempostance   or "none"
bardsunset        = bardsunset        or false
bardsunrise       = bardsunrise       or false
bladefinale       = bladefinale       or false
bardtemposequence = bardtemposequence or 0
bardtempo         = bardtempo         or false

-- =============================================================================
-- SECTION 2: CONFIG
-- =============================================================================

bard.config.debug = bard.config.debug or false
-- nil-guard (not `or`) because false is a valid value
bard.config.echoStrategy = (bard.config.echoStrategy == nil) and true or bard.config.echoStrategy

-- =============================================================================
-- SECTION 3: CONSTANTS
-- =============================================================================

-- Refrain priority table — first entry whose aff is missing on target wins
bard.REFRAIN_AFFS = {
  { aff = "paralysis",   song = "paean"     },
  { aff = "asthma",      song = "ode"       },
  { aff = "slickness",   song = "ghazal"    },
  { aff = "lethargy",    song = "elegy"     },
  { aff = "sensitivity", song = "prosodion" },
  { aff = "dizziness",   song = "bhajan"    },
  { aff = "addiction",   song = "gusheh"    },
}
bard.REFRAIN_FALLBACK = "paean"

-- Affliction list used for bardflick decision
bard.FLICK_AFF_LIST = {
  "paralysis", "asthma", "weariness", "clumsiness", "impatience",
  "addiction", "nausea", "generosity", "heathleech", "confusion",
  "recklessness", "diminished", "haemophilia", "sensitivity",
}
bard.FLICK_AFF_THRESHOLD = 3

-- =============================================================================
-- SECTION 4: HELPERS
-- =============================================================================

function bard.hasAff(aff)
  return haveAff(aff)
end

--- V1 fallback for rebounding on TARGET.
--- GMCP timing gap: balance fires before text triggers in same data chunk,
--- so haveAff() may return false for a frame. V1 fallback prevents missed blocks.
function bard.hasRebounding()
  return haveAff("rebounding") or (tAffs and tAffs.rebounding)
end

--- V1 fallback for shield on TARGET (same GMCP timing gap)
function bard.hasShield()
  return haveAff("shield") or (tAffs and tAffs.shield)
end

function bard.echo(text)
  cecho("\n<medium_purple>[<plum>Bard<medium_purple>]<reset> " .. text)
end

function bard.decho(text)
  if bard.config.debug then bard.echo(text) end
end

-- =============================================================================
-- SECTION 5: PREP CALCULATION (extracted, deduplicated)
-- =============================================================================

--[[
  Calculate which limbs are "prepped" (one more rapier hit would break them).
  Sets bard._preppedHead/Torso/LeftArm/RightArm/LeftLeg/RightLeg.

  IMPORTANT: Also sets the bare global `rapierdamage` — triggers 008_Sunrise and
  009_SunSet read this global directly to update lb[target].hits on attack land.
  Do not remove the bare global assignment.
]]--
function bard.calcPreps()
  local rd   = ataxiaTables.limbData.bardRapier
  local hits = lb[target].hits

  -- Keep bare global alive for trigger reads
  rapierdamage = rd

  bard._rapierdamage    = rd
  bard._preppedHead     = hits["head"]      + rd >= 100 and not tAffs.damagedhead
  bard._preppedTorso    = hits["torso"]     + rd >= 100 and not tAffs.mildtrauma
  bard._preppedLeftLeg  = hits["left leg"]  + rd >= 100 and not tAffs.damagedleftleg
  bard._preppedRightLeg = hits["right leg"] + rd >= 100 and not tAffs.damagedrightleg
  bard._preppedRightArm = hits["right arm"] + rd >= 100 and not tAffs.damagedrightarm
  bard._preppedLeftArm  = hits["left arm"]  + rd >= 100 and not tAffs.damagedleftarm
end

-- =============================================================================
-- SECTION 6: REFRAIN SELECTION (extracted, deduplicated)
-- =============================================================================

--[[
  Select the optimal refrain to deliver this attack.
  Returns the song name string. Iterates REFRAIN_AFFS in priority order,
  picking the first affliction the target does not have.
]]--
function bard.selectRefrain()
  for _, entry in ipairs(bard.REFRAIN_AFFS) do
    if not haveAff(entry.aff) then
      bard.state.lastRefrain = entry.song
      return entry.song
    end
  end
  bard.state.lastRefrain = bard.REFRAIN_FALLBACK
  return bard.REFRAIN_FALLBACK
end

-- =============================================================================
-- SECTION 7: SHARED PRE-DISPATCH SETUP
-- =============================================================================

--[[
  Common preamble run at the start of both dispatch functions.
  Sets up analysis globals, runs limb prep calculation.
]]--
function bard.preDispatch()
  -- Bare global fallback guards (triggers own these; this just protects from nil)
  bardtempostance   = bardtempostance   or "none"
  bardsunset        = bardsunset        or false
  bardsunrise       = bardsunrise       or false
  bladefinale       = bladefinale       or false
  bardtemposequence = bardtemposequence or 0

  -- External analysis hooks
  getLockingAffliction()
  checkTargetLocks()

  -- Bardflick threshold check
  if checkAffList(bard.FLICK_AFF_LIST, bard.FLICK_AFF_THRESHOLD) then
    bardflick = true
  else
    bardflick = false
  end

  -- envenomList stays bare global — consumed by external envenom queue
  envenomList = {}

  -- Limb prep calculation (also refreshes rapierdamage bare global)
  bard.calcPreps()
end

-- =============================================================================
-- SECTION 8: COMBAT ECHO
-- =============================================================================

--[[
  Per-attack echo showing current decision. Gated by bard.config.echoStrategy.
]]--
function bard.combatEcho()
  local r   = bard.state.lastRefrain or "?"
  local atk = bard.state.lastAttack  or ""

  -- Extract readable command name from the attack string
  local cmd = atk:match("blade (%a+)") or atk:match(";(%a+)") or "?"

  -- Tempo display
  local tempoStr = ""
  if bardtempo and bardtempo ~= false then
    tempoStr = " <dim_grey>tempo:<reset>" .. tostring(bardtempo)
    if bardtempostance and bardtempostance ~= "none" then
      tempoStr = tempoStr .. "/" .. bardtempostance .. "[" .. tostring(bardtemposequence or 0) .. "]"
    end
  end

  -- Crescendo / FINALE display
  local cStr = ""
  if tAffs and tAffs.crescendo and tAffs.crescendo ~= 0 and tAffs.crescendo ~= false then
    if bladefinale then
      cStr = " <red>[FINALE]"
    else
      cStr = " <orange>[CRES:" .. tostring(tAffs.crescendo) .. "]"
    end
  end

  -- Sunset / Sunrise flags
  local flagStr = ""
  if bardsunset  then flagStr = flagStr .. " <yellow>[SUNSET]"  end
  if bardsunrise then flagStr = flagStr .. " <cyan>[SUNRISE]" end

  cecho("\n<medium_purple>[<plum>Bard<medium_purple>]<reset> "
    .. "<white>" .. cmd .. "<reset> "
    .. "<dim_grey>refrain:<reset>" .. r
    .. tempoStr .. cStr .. flagStr)
end

-- =============================================================================
-- SECTION 9: DISPATCH ONE — Replaces levibardone
-- =============================================================================

--[[
  Primary blade dispatch. Kill route: sunrise (head+arm+torso+leg prepped) →
  sunset (head+arm+torso prepped, tempo-gated) → progressive limb prep.

  Rebound gate is already present from the original implementation.
]]--
function bard.dispatchOne()
  -- Rebound hold gate
  if reboundHold and reboundHold.gate(bard.dispatchOne) then return end

  local atk = combatQueue()

  bard.preDispatch()
  local refrain = bard.selectRefrain()

  -- Local aliases for readability
  local ph  = bard._preppedHead
  local pt  = bard._preppedTorso
  local pla = bard._preppedLeftArm
  local pra = bard._preppedRightArm
  local pll = bard._preppedLeftLeg
  local prl = bard._preppedRightLeg

  -- -------------------------------------------------------------------------
  -- Attack selection chain (priority-ordered)
  -- NOTE: Known bugs in conditions below are preserved verbatim from original.
  -- Do not "fix" mildtramua/mildtraumna typos or bardsunrise precedence — see plan.
  -- -------------------------------------------------------------------------

  if bard.hasShield() or bard.hasRebounding() then
    atk = atk .. "blade punctuate " .. target .. " " .. refrain

  elseif bladefinale == true then
    atk = atk .. "blade flick " .. target .. ";finale " .. target

  elseif bardsunset == true then
    atk = atk .. "wield right fang;wipe fang;envenom fang with slike;jab " .. target

  -- NOTE: `or bardsunrise == true` at end — Lua precedence makes bardsunrise alone
  -- able to trigger these branches. Preserved from original (intentional behavior).
  elseif ph and pla and (tAffs.mildtramua and tAffs.damagedleftleg) or bardsunrise == true then
    atk = atk .. "blade sunset " .. target .. " left paean"
  elseif ph and pra and (tAffs.mildtramua and tAffs.damagedrightleg) or bardsunrise == true then
    atk = atk .. "blade sunset " .. target .. " right paean"

  elseif ph and pra and pt and pll then
    atk = atk .. "blade sunrise " .. target .. " left " .. refrain
  elseif ph and pla and pt and pll then
    atk = atk .. "blade sunrise " .. target .. " left " .. refrain
  elseif ph and pra and pt and prl then
    atk = atk .. "blade sunrise " .. target .. " right " .. refrain
  elseif ph and pla and pt and prl then
    atk = atk .. "blade sunrise " .. target .. " right " .. refrain

  elseif tAffs.crescendo == 0 or tAffs.crescendo == false then
    atk = atk .. "blade flick " .. target .. " " .. refrain

  elseif ph and pra and pt and not pll then
    atk = atk .. "blade heelsnap " .. target .. " left " .. refrain
  elseif ph and pla and pt and not pll then
    atk = atk .. "blade heelsnap " .. target .. " left " .. refrain
  elseif ph and pra and pt and not prl then
    atk = atk .. "blade heelsnap " .. target .. " right " .. refrain
  elseif ph and pla and pt and not prl then
    atk = atk .. "blade heelsnap " .. target .. " right " .. refrain

  elseif ph and pla and not pt then
    atk = atk .. "blade jab " .. target .. " torso " .. refrain
  elseif ph and pra and not pt then
    atk = atk .. "blade jab " .. target .. " torso " .. refrain

  elseif ph and not pla then
    atk = atk .. "blade highsun " .. target .. " left arm " .. refrain
  elseif ph and not pra then
    atk = atk .. "blade highsun " .. target .. " right arm " .. refrain

  -- Second crescendo check — fallback before damaged-limb chain (preserved from original)
  elseif tAffs.crescendo == 0 or tAffs.crescendo == false then
    atk = atk .. "blade flick " .. target .. " " .. refrain

  elseif not ph and not tAffs.damagedhead then
    atk = atk .. "blade highsun " .. target .. " head " .. refrain
  elseif not pla and not tAffs.damagedleftarm then
    atk = atk .. "blade highsun " .. target .. " left arm " .. refrain
  elseif not pra and not tAffs.damagedrightarm then
    atk = atk .. "blade highsun " .. target .. " right arm " .. refrain
  elseif not pt and not tAffs.mildtraumna then
    atk = atk .. "blade jab " .. target .. " torso " .. refrain
  elseif not pll and not tAffs.damagedleftleg then
    atk = atk .. "blade heelsnap " .. target .. " left " .. refrain
  elseif not prl and not tAffs.damagedrightleg then
    atk = atk .. "blade heelsnap " .. target .. " left " .. refrain
  end

  bard.state.lastAttack = atk

  -- Send — sunset uses fang wipe, so skip lyre/rapier wield prefix
  if bardsunset == false then
    send("queue addclearfull freestand wield left lyre;wield right rapier;" .. atk)
  else
    table.insert(envenomList, "slike")
    send("queue addclearfull freestand " .. atk)
  end

  if bard.config.echoStrategy then bard.combatEcho() end
end

-- =============================================================================
-- SECTION 10: DISPATCH TWO — Replaces levibardtwo
-- =============================================================================

--[[
  Secondary blade dispatch. Tempo-aware sunset routing.
  Uses bardtempo/bardtempostance/bardtemposequence (written by tempo triggers).

  BUG FIX: Rebound gate was missing from original levibardtwo. Added here.
]]--
function bard.dispatchTwo()
  -- Rebound hold gate (was missing from original — now added)
  if reboundHold and reboundHold.gate(bard.dispatchTwo) then return end

  local atk = combatQueue()

  bard.preDispatch()
  local refrain = bard.selectRefrain()

  -- Local aliases for readability
  local ph  = bard._preppedHead
  local pt  = bard._preppedTorso
  local pla = bard._preppedLeftArm
  local pra = bard._preppedRightArm

  -- -------------------------------------------------------------------------
  -- Attack selection chain
  -- -------------------------------------------------------------------------

  if bard.hasShield() or bard.hasRebounding() then
    atk = atk .. "blade punctuate " .. target .. " " .. refrain

  elseif pt == true and bardsunset == true and bardtempo == "back" then
    atk = atk .. "blade jab " .. target .. " torso " .. refrain

  elseif ph and pra and pt then
    if bardtempo == "back" and ((bardtempostance == "Adagio" and bardtemposequence <= 1) or (bardtempostance == "Moderato" and bardtemposequence == 0)) then
      atk = atk .. "blade sunset " .. target .. " right bhajan"
    elseif bardtempo == "side" and ((bardtempostance == "Adagio" and bardtemposequence == 3) or (bardtempostance == "Moderato" and bardtemposequence == 1) or (bardtempostance == "Allegro" and bardtemposequence == 0)) then
      atk = atk .. "blade sunset " .. target .. " right bhajan"
    else
      atk = atk .. "blade flick " .. target .. " " .. refrain
    end

  elseif ph and pla and pt then
    if bardtempo == "back" and ((bardtempostance == "Adagio" and bardtemposequence <= 1) or (bardtempostance == "Moderato" and bardtemposequence == 0)) then
      atk = atk .. "blade sunset " .. target .. " left bhajan"
    elseif bardtempo == "side" and ((bardtempostance == "Adagio" and bardtemposequence == 3) or (bardtempostance == "Moderato" and bardtemposequence == 1) or (bardtempostance == "Allegro" and bardtemposequence == 0)) then
      atk = atk .. "blade sunset " .. target .. " left bhajan"
    else
      atk = atk .. "blade flick " .. target .. " " .. refrain
    end

  elseif bladefinale == true then
    atk = atk .. ";finale " .. target

  elseif ph and pla and not pt then
    atk = atk .. "blade jab " .. target .. " torso " .. refrain
  elseif ph and pra and not pt then
    atk = atk .. "blade jab " .. target .. " torso " .. refrain

  elseif ph and not pla then
    atk = atk .. "blade highsun " .. target .. " left arm " .. refrain
  elseif ph and not pra then
    atk = atk .. "blade highsun " .. target .. " right arm " .. refrain

  elseif tAffs.crescendo == 0 or tAffs.crescendo == false then
    atk = atk .. "blade flick " .. target .. " " .. refrain

  elseif not ph and not tAffs.damagedhead then
    atk = atk .. "blade highsun " .. target .. " head " .. refrain
  elseif not pla and not tAffs.damagedleftarm then
    atk = atk .. "blade highsun " .. target .. " left arm " .. refrain
  elseif not pra and not tAffs.damagedrightarm then
    atk = atk .. "blade highsun " .. target .. " right arm " .. refrain
  elseif not pt and not tAffs.mildtraumna then
    atk = atk .. "blade jab " .. target .. " torso " .. refrain
  end

  bard.state.lastAttack = atk

  send("queue addclearfull freestand wield left lyre;wield right rapier;" .. atk)

  if bard.config.echoStrategy then bard.combatEcho() end
end

-- =============================================================================
-- SECTION 11: STATUS DISPLAY
-- =============================================================================

function bard.status()
  bard.echo("<white>--- Bard Offense Status ---")
  bard.echo("Debug:      " .. (bard.config.debug and "<green>ON" or "<red>OFF") .. "<reset>")
  bard.echo("EchoStrat:  " .. (bard.config.echoStrategy and "<green>ON" or "<red>OFF") .. "<reset>")

  -- Crescendo / finale
  local cres = (tAffs and tAffs.crescendo) or 0
  bard.echo("Crescendo:  <white>" .. tostring(cres) .. (bladefinale and " <red>[FINALE READY]" or "") .. "<reset>")

  -- Tempo state (trigger-written globals)
  bard.echo("Tempo:      <white>" .. tostring(bardtempo or "none")
    .. " / stance: " .. tostring(bardtempostance or "none")
    .. " / seq: "    .. tostring(bardtemposequence or 0) .. "<reset>")

  -- Flags
  bard.echo("Sunset:     " .. (bardsunset  and "<green>YES" or "<dim_grey>no") .. "<reset>")
  bard.echo("Sunrise:    " .. (bardsunrise and "<green>YES" or "<dim_grey>no") .. "<reset>")

  -- Limb preps
  if target and lb and lb[target] then
    bard.calcPreps()
    bard.echo("Preps: "
      .. " Head:"  .. (bard._preppedHead     and "<green>Y" or "<red>N")
      .. " Torso:" .. (bard._preppedTorso    and "<green>Y" or "<red>N")
      .. " LA:"    .. (bard._preppedLeftArm  and "<green>Y" or "<red>N")
      .. " RA:"    .. (bard._preppedRightArm and "<green>Y" or "<red>N")
      .. " LL:"    .. (bard._preppedLeftLeg  and "<green>Y" or "<red>N")
      .. " RL:"    .. (bard._preppedRightLeg and "<green>Y" or "<red>N")
      .. "<reset>")
    bard.echo("Rapier dmg: <white>" .. tostring(bard._rapierdamage or "?") .. "<reset>")
  else
    bard.echo("<dim_grey>No target — limb preps unavailable.")
  end

  -- Refrain (read-only call, no side effects beyond state.lastRefrain)
  local refrain = bard.selectRefrain()
  bard.echo("Refrain:    <white>" .. refrain .. "<reset>")
  bard.echo("BardFlick:  " .. (bardflick and "<green>YES" or "<dim_grey>no") .. "<reset>")
end

-- =============================================================================
-- SECTION 12: RESET
-- =============================================================================

--[[
  Reset dispatch-owned state and bare globals to neutral values.
  This mirrors what the login function does on reconnect.
]]--
function bard.reset()
  bard.state.lastRefrain = nil
  bard.state.lastAttack  = nil

  -- Reset trigger-written globals (bard.reset() is the canonical "clear all" entry point)
  bardtempostance   = "none"
  bardsunset        = false
  bardsunrise       = false
  bladefinale       = false
  bardtemposequence = 0
  bardtempo         = false
  bardflick         = false

  bard.echo("State reset.")
end

-- =============================================================================
-- SECTION 13: ALIAS REGISTRATION
-- =============================================================================

-- Cleanup before re-registration (prevents duplication on script reload)
if bard._aliases then
  for _, id in pairs(bard._aliases) do
    killAlias(id)
  end
end
bard._aliases = {}

bard._aliases.status = tempAlias("^bardstatus$", function() bard.status() end)
bard._aliases.reset  = tempAlias("^bardreset$",  function() bard.reset()  end)
bard._aliases.debug  = tempAlias("^barddebug$",  function()
  bard.config.debug = not bard.config.debug
  bard.echo("Debug: " .. (bard.config.debug and "<green>ON" or "<red>OFF"))
end)
bard._aliases.echo   = tempAlias("^bardecho$",   function()
  bard.config.echoStrategy = not bard.config.echoStrategy
  bard.echo("EchoStrategy: " .. (bard.config.echoStrategy and "<green>ON" or "<red>OFF"))
end)

-- =============================================================================
-- SECTION 14: BACKWARD-COMPAT WRAPPERS
-- =============================================================================

-- These maintain compatibility with any alias or script calling the old names.
function levibardone() bard.dispatchOne() end
function levibardtwo() bard.dispatchTwo() end

cecho("\n<medium_purple>[<plum>Bard<medium_purple>]<reset> Offense system loaded. bardstatus | bardreset | barddebug | bardecho")
