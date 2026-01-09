--[[mudlet
type: script
name: ClassName Offense
hierarchy:
- Levi_Ataxia
- LEVI
- Levi Scripts
- Leviticus
- ClassName
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
================================================================================
CLASSNAME OFFENSE SYSTEM TEMPLATE
================================================================================

REQUIRED READING before modifying:
- .claude/classes/lock_types.md (lock definitions)
- .claude/classes/classname.md (class mechanics)
- .claude/databases/venoms.yaml (venom reference)
- .claude/databases/afflictions.yaml (affliction reference)
- .claude/databases/locks.yaml (lock progression)

Lock progression: Softlock -> Venomlock -> Hardlock -> Truelock
See lock_types.md for affliction requirements and escape routes.

TEMPLATE USAGE:
1. Copy this file to src_new/scripts/levi_ataxia/levi/levi_scripts/classname/
2. Replace all instances of "classname" with your class name (lowercase)
3. Replace all instances of "ClassName" with your class name (TitleCase)
4. Implement the TODO sections

================================================================================
]]--

-- ============================================================================
-- NAMESPACE INITIALIZATION
-- ============================================================================

classname = classname or {}
classname.config = classname.config or {}
classname.state = classname.state or {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

classname.config = {
  -- Debug mode - set to true for verbose output
  debug = false,

  -- Combat mode: "lock", "damage", "hybrid"
  mode = "lock",

  -- Weapon IDs (customize per character)
  primaryWeapon = "weaponID1",
  secondaryWeapon = "weaponID2",

  -- TODO: Add class-specific configuration options
}

-- ============================================================================
-- STATE TRACKING
-- ============================================================================

classname.state = {
  -- Current combat phase
  phase = "SETUP",

  -- Last action taken (for avoiding repeats)
  lastAction = nil,

  -- Combo counter (if applicable)
  comboCount = 0,

  -- TODO: Add class-specific state variables
}

-- ============================================================================
-- CONSTANTS
-- ============================================================================

-- Lock affliction for this class (see .claude/databases/locks.yaml)
classname.LOCK_AFFLICTION = "weariness"  -- TODO: Change based on class

-- Venom mappings (venom -> affliction)
classname.venomEffects = {
  kalmia = "asthma",
  slike = "anorexia",
  gecko = "slickness",
  curare = "paralysis",
  euphorbia = "impatience",
  vernalius = "weariness",
  -- TODO: Add venoms your class uses
}

-- ============================================================================
-- LOCK DETECTION (from .claude/databases/locks.yaml)
-- ============================================================================

function classname.checkSoftlock()
  return tAffs.asthma and tAffs.anorexia and tAffs.slickness
end

function classname.checkVenomlock()
  return classname.checkSoftlock() and tAffs.paralysis
end

function classname.checkHardlock()
  return classname.checkVenomlock() and tAffs.impatience
end

function classname.checkTruelock()
  return classname.checkHardlock() and tAffs[classname.LOCK_AFFLICTION]
end

function classname.getLockLevel()
  if classname.checkTruelock() then return "TRUELOCK" end
  if classname.checkHardlock() then return "HARDLOCK" end
  if classname.checkVenomlock() then return "VENOMLOCK" end
  if classname.checkSoftlock() then return "SOFTLOCK" end
  return "NONE"
end

-- ============================================================================
-- VENOM/AFFLICTION SELECTION
-- ============================================================================

--[[
  Select the next venom to apply based on current target afflictions.
  Priority: Build toward softlock -> venomlock -> hardlock -> truelock

  Returns: venom name (string) or nil if no venom needed
]]--
function classname.selectVenom()
  -- Priority 1: Complete softlock
  if not tAffs.asthma then
    return "kalmia"
  end

  if not tAffs.slickness then
    return "gecko"
  end

  if not tAffs.anorexia then
    return "slike"
  end

  -- Priority 2: Add paralysis for venomlock
  if not tAffs.paralysis then
    return "curare"
  end

  -- Priority 3: Add impatience for hardlock
  if not tAffs.impatience then
    return "euphorbia"
  end

  -- Priority 4: Add class-specific lock affliction
  if not tAffs[classname.LOCK_AFFLICTION] then
    return "vernalius"  -- TODO: Change based on class lock affliction
  end

  -- Locked - maintain pressure
  return "curare"  -- Keep paralysis refreshed
end

--[[
  Select secondary venom for dual-venom attacks (like DWC knights)
  Returns: venom name (string) or nil
]]--
function classname.selectSecondaryVenom()
  -- TODO: Implement based on class mechanics
  -- Example: Return a venom that complements the primary
  if tAffs.asthma and not tAffs.anorexia then
    return "slike"
  end

  if tAffs.slickness and not tAffs.paralysis then
    return "curare"
  end

  return "vernalius"  -- Default to weariness for pressure
end

-- ============================================================================
-- ATTACK SELECTION
-- ============================================================================

--[[
  Select the main attack to use.
  Override this function for class-specific attack logic.

  Returns: attack command (string)
]]--
function classname.selectAttack()
  -- TODO: Implement class-specific attack selection
  -- This is the main function you need to customize

  local venom1 = classname.selectVenom()
  local venom2 = classname.selectSecondaryVenom()

  -- Example for a knight-style class:
  -- return "dsl " .. target .. " " .. venom1 .. " " .. venom2

  -- Example for a simple class:
  return "attack " .. target .. " with " .. venom1
end

--[[
  Select finisher attack when lock conditions are met.
  Returns: finisher command (string) or nil
]]--
function classname.selectFinisher()
  if classname.checkTruelock() then
    -- TODO: Implement class-specific kill command
    return "kill " .. target
  end

  return nil
end

-- ============================================================================
-- PRE-ATTACK ACTIONS
-- ============================================================================

--[[
  Actions to perform before the main attack.
  Returns: command string or empty string
]]--
function classname.preAttackActions()
  local actions = {}

  -- Example: Ensure weapon is wielded
  -- table.insert(actions, "wield " .. classname.config.primaryWeapon)

  -- Example: Rebounding strip if needed
  if tAffs.rebounding then
    -- table.insert(actions, "strip rebounding " .. target)
  end

  -- Example: Shield strip
  if tAffs.shield then
    -- table.insert(actions, "shatter " .. target)
  end

  return table.concat(actions, ";")
end

-- ============================================================================
-- COMBO BUILDER
-- ============================================================================

--[[
  Build the complete attack command including pre-actions and attack.
  Returns: full command string
]]--
function classname.buildCombo()
  local cmd = ""

  -- Add pre-attack actions
  local preActions = classname.preAttackActions()
  if preActions and preActions ~= "" then
    cmd = cmd .. preActions .. ";"
  end

  -- Check for finisher first
  local finisher = classname.selectFinisher()
  if finisher then
    return cmd .. finisher
  end

  -- Add main attack
  local attack = classname.selectAttack()
  cmd = cmd .. attack

  return cmd
end

-- ============================================================================
-- MAIN DISPATCH FUNCTION
-- ============================================================================

--[[
  Main offense function - call this to execute an attack.
  Can be bound to an alias or key.
]]--
function classname.dispatch()
  -- Initialize globals if needed
  ataxia = ataxia or {}
  ataxia.balances = ataxia.balances or {}
  ataxiaTemp = ataxiaTemp or {}
  tAffs = tAffs or {}

  -- Safety check: Ensure we have a target
  if not target or target == "" then
    cecho("\n<red>[ClassName] No target set! Use: tar <name>")
    return
  end

  -- Debug output
  if classname.config.debug then
    cecho("\n<cyan>[ClassName] Target: <yellow>" .. tostring(target))
    cecho(" <cyan>| Lock: <yellow>" .. classname.getLockLevel())
  end

  -- Build and send command
  local cmd = classname.buildCombo()

  -- Use queue system for reliable execution
  send("queue addclear free " .. cmd)

  -- Update state
  classname.state.lastAction = cmd
  classname.state.comboCount = classname.state.comboCount + 1
end

-- ============================================================================
-- STATUS DISPLAY
-- ============================================================================

function classname.status()
  tAffs = tAffs or {}

  cecho("\n<cyan>╔══════════════════════════════════════════════╗")
  cecho("\n<cyan>║         <white>CLASSNAME STATUS<cyan>                     ║")
  cecho("\n<cyan>╠══════════════════════════════════════════════╣")
  cecho("\n<cyan>║ <white>Mode: <yellow>" .. tostring(classname.config.mode))
  cecho("\n<cyan>║ <white>Target: <yellow>" .. tostring(target or "None"))
  cecho("\n<cyan>║ <white>Lock Level: <yellow>" .. classname.getLockLevel())

  -- Softlock status
  cecho("\n<cyan>╠══════════════════════════════════════════════╣")
  cecho("\n<cyan>║ <white>AFFLICTIONS:")
  cecho("\n<cyan>║   " .. (tAffs.asthma and "<green>[X]" or "<red>[ ]") .. " asthma")
  cecho("  " .. (tAffs.anorexia and "<green>[X]" or "<red>[ ]") .. " anorexia")
  cecho("  " .. (tAffs.slickness and "<green>[X]" or "<red>[ ]") .. " slickness")
  cecho("\n<cyan>║   " .. (tAffs.paralysis and "<green>[X]" or "<red>[ ]") .. " paralysis")
  cecho("  " .. (tAffs.impatience and "<green>[X]" or "<red>[ ]") .. " impatience")
  cecho("  " .. (tAffs[classname.LOCK_AFFLICTION] and "<green>[X]" or "<red>[ ]") .. " " .. classname.LOCK_AFFLICTION)

  cecho("\n<cyan>╚══════════════════════════════════════════════╝")
end

-- ============================================================================
-- RESET FUNCTION
-- ============================================================================

function classname.reset()
  classname.state.phase = "SETUP"
  classname.state.lastAction = nil
  classname.state.comboCount = 0
  cecho("\n<cyan>[ClassName] State reset")
end

-- ============================================================================
-- MODE SWITCHING
-- ============================================================================

function classname.setMode(mode)
  local validModes = {lock = true, damage = true, hybrid = true}
  if validModes[mode] then
    classname.config.mode = mode
    cecho("\n<cyan>[ClassName] Mode set to: <yellow>" .. mode:upper())
  else
    cecho("\n<red>[ClassName] Invalid mode. Use: lock, damage, or hybrid")
  end
end

-- ============================================================================
-- CONVENIENCE ALIASES
-- ============================================================================

-- Main dispatch aliases
function cndispatch()
  classname.dispatch()
end

-- Status aliases
function cnstatus()
  classname.status()
end

-- Reset alias
function cnreset()
  classname.reset()
end

-- ============================================================================
-- EVENT HANDLERS (Optional)
-- ============================================================================

--[[
  Example: Handle affliction gains on target
  Uncomment and customize if needed
]]--
-- registerAnonymousEventHandler("target aff gained", function(event, aff)
--   if classname.config.debug then
--     cecho("\n<green>[ClassName] Target gained: " .. aff)
--   end
-- end)

--[[
  Example: Handle affliction losses on target
]]--
-- registerAnonymousEventHandler("target aff lost", function(event, aff)
--   if classname.config.debug then
--     cecho("\n<red>[ClassName] Target cured: " .. aff)
--   end
-- end)

-- ============================================================================
-- INITIALIZATION MESSAGE
-- ============================================================================

cecho("\n<cyan>[ClassName] Offense system loaded. Commands: cndispatch(), cnstatus(), cnreset()")
