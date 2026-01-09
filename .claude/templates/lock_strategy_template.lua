--[[mudlet
type: script
name: Lock Strategy System
hierarchy:
- Levi_Ataxia
- LEVI
- Levi Scripts
- Leviticus
- Core
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
================================================================================
LOCK STRATEGY SYSTEM TEMPLATE
================================================================================

Use this template to implement affliction-based lock strategies:
- Softlock (asthma + anorexia + slickness)
- Venomlock (+ paralysis)
- Hardlock (+ impatience)
- Truelock (+ class-specific affliction)

Alternative locks:
- Focuslock (mental stack instead of impatience)
- Riftlock (broken arms + slickness + asthma)
- Aeonlock (aeon + asthma)

See .claude/databases/locks.yaml for complete reference.

================================================================================
]]--

-- ============================================================================
-- NAMESPACE INITIALIZATION
-- ============================================================================

lockStrategy = lockStrategy or {}
lockStrategy.config = lockStrategy.config or {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

lockStrategy.config = {
  -- Debug mode
  debug = false,

  -- Primary strategy: "truelock", "focuslock", "riftlock", "aeonlock"
  strategy = "truelock",

  -- Target class (affects which class-specific affliction is needed)
  targetClass = nil,
}

-- ============================================================================
-- CLASS-SPECIFIC LOCK AFFLICTIONS
-- (from .claude/databases/locks.yaml)
-- ============================================================================

lockStrategy.classLockAfflictions = {
  -- Weariness classes
  Blademaster = "weariness",
  Druid = "weariness",
  Infernal = "weariness",
  Monk = "weariness",
  Paladin = "weariness",
  Unnamable = "weariness",
  Runewarden = "weariness",
  Sentinel = "weariness",
  Serpent = "weariness",
  Airlord = "weariness",
  Waterlord = "weariness",
  Earthlord = "weariness",
  Firelord = "weariness",

  -- Voyria classes
  Apostate = "voyria",
  Pariah = "voyria",
  Bard = "voyria",
  Priest = "voyria",

  -- Special classes
  Alchemist = "stupidity",
  Magi = "haemophilia",
  Sylvan = "haemophilia",
  Depthswalker = "recklessness",
  Psion = "confusion",

  -- Paralysis is already in base lock
  Jester = "paralysis",
  Occultist = "paralysis",
  Shaman = "paralysis",
}

-- ============================================================================
-- VENOM MAPPINGS
-- ============================================================================

lockStrategy.afflictionToVenom = {
  asthma = "kalmia",
  anorexia = "slike",
  slickness = "gecko",
  paralysis = "curare",
  impatience = "euphorbia",
  weariness = "vernalius",
  stupidity = "xentio",
  haemophilia = "eurypteria",
  recklessness = "sumac",
  confusion = "aconite",
  voyria = "voyria",
  clumsiness = "supara",
  sensitivity = "prefarar",
  dizziness = "aconite",
  epilepsy = "colocasia",
  shyness = "notechis",
  depression = "digitalis",
  addiction = "vardrax",
  lethargy = "oleander",
  nausea = "noctec",
}

-- ============================================================================
-- LOCK STATE CHECKING
-- ============================================================================

--[[
  Check if target has softlock (asthma + anorexia + slickness).
  @return (boolean)
]]--
function lockStrategy.checkSoftlock()
  return tAffs.asthma and tAffs.anorexia and tAffs.slickness
end

--[[
  Check if target has venomlock (softlock + paralysis).
  @return (boolean)
]]--
function lockStrategy.checkVenomlock()
  return lockStrategy.checkSoftlock() and tAffs.paralysis
end

--[[
  Check if target has hardlock (venomlock + impatience).
  @return (boolean)
]]--
function lockStrategy.checkHardlock()
  return lockStrategy.checkVenomlock() and tAffs.impatience
end

--[[
  Check if target has truelock (hardlock + class-specific affliction).
  @return (boolean)
]]--
function lockStrategy.checkTruelock()
  local classAff = lockStrategy.getClassLockAffliction()
  return lockStrategy.checkHardlock() and tAffs[classAff]
end

--[[
  Check if target has focuslock (venomlock + 2+ mental afflictions).
  @return (boolean)
]]--
function lockStrategy.checkFocuslock()
  if not lockStrategy.checkVenomlock() then return false end

  local mentalCount = 0
  local mentals = {"stupidity", "dizziness", "epilepsy", "impatience", "shyness", "depression"}
  for _, aff in ipairs(mentals) do
    if tAffs[aff] then mentalCount = mentalCount + 1 end
  end

  return mentalCount >= 2
end

--[[
  Check if target has riftlock (both arms broken + slickness + asthma).
  @return (boolean)
]]--
function lockStrategy.checkRiftlock()
  local armsBroken = (tLimbs.LA >= 100) and (tLimbs.RA >= 100)
  return armsBroken and tAffs.slickness and tAffs.asthma
end

--[[
  Check if target has aeonlock (aeon + asthma).
  @return (boolean)
]]--
function lockStrategy.checkAeonlock()
  return tAffs.aeon and tAffs.asthma
end

--[[
  Get current lock level as string.
  @return (string)
]]--
function lockStrategy.getLockLevel()
  if lockStrategy.checkTruelock() then return "TRUELOCK" end
  if lockStrategy.checkHardlock() then return "HARDLOCK" end
  if lockStrategy.checkFocuslock() then return "FOCUSLOCK" end
  if lockStrategy.checkVenomlock() then return "VENOMLOCK" end
  if lockStrategy.checkSoftlock() then return "SOFTLOCK" end
  if lockStrategy.checkRiftlock() then return "RIFTLOCK" end
  if lockStrategy.checkAeonlock() then return "AEONLOCK" end
  return "NONE"
end

-- ============================================================================
-- AFFLICTION TRACKING
-- ============================================================================

--[[
  Get the class-specific lock affliction for the target.
  @return (string) - Affliction name
]]--
function lockStrategy.getClassLockAffliction()
  local targetClass = lockStrategy.config.targetClass or tClass or "Unknown"
  return lockStrategy.classLockAfflictions[targetClass] or "weariness"
end

--[[
  Count how many softlock afflictions the target has.
  @return (number) 0-3
]]--
function lockStrategy.countSoftlockAffs()
  local count = 0
  if tAffs.asthma then count = count + 1 end
  if tAffs.anorexia then count = count + 1 end
  if tAffs.slickness then count = count + 1 end
  return count
end

--[[
  Get list of missing softlock afflictions.
  @return (table) - List of affliction names
]]--
function lockStrategy.getMissingSoftlockAffs()
  local missing = {}
  if not tAffs.asthma then table.insert(missing, "asthma") end
  if not tAffs.anorexia then table.insert(missing, "anorexia") end
  if not tAffs.slickness then table.insert(missing, "slickness") end
  return missing
end

-- ============================================================================
-- VENOM SELECTION
-- ============================================================================

--[[
  Select the next venom to apply for truelock strategy.
  Priority order: softlock → paralysis → impatience → class lock

  @return (string) - Venom name, or nil if locked
]]--
function lockStrategy.selectVenomTruelock()
  -- Priority 1: Build softlock
  if not tAffs.asthma then
    return "kalmia"
  end

  if not tAffs.slickness then
    return "gecko"
  end

  if not tAffs.anorexia then
    return "slike"
  end

  -- Priority 2: Paralysis for tree block
  if not tAffs.paralysis then
    return "curare"
  end

  -- Priority 3: Impatience for focus block
  if not tAffs.impatience then
    return "euphorbia"
  end

  -- Priority 4: Class-specific lock affliction
  local classAff = lockStrategy.getClassLockAffliction()
  if not tAffs[classAff] then
    return lockStrategy.afflictionToVenom[classAff] or "vernalius"
  end

  -- Already locked - maintain paralysis
  return "curare"
end

--[[
  Select venom for focuslock strategy.
  Uses mental stack instead of impatience.

  @return (string) - Venom name
]]--
function lockStrategy.selectVenomFocuslock()
  -- Priority 1: Build softlock
  if not tAffs.asthma then return "kalmia" end
  if not tAffs.slickness then return "gecko" end
  if not tAffs.anorexia then return "slike" end

  -- Priority 2: Paralysis
  if not tAffs.paralysis then return "curare" end

  -- Priority 3: Stack mental afflictions
  local mentals = {
    {aff = "stupidity", venom = "xentio"},
    {aff = "dizziness", venom = "aconite"},
    {aff = "epilepsy", venom = "colocasia"},
    {aff = "impatience", venom = "euphorbia"},
    {aff = "shyness", venom = "notechis"},
    {aff = "depression", venom = "digitalis"},
  }

  for _, m in ipairs(mentals) do
    if not tAffs[m.aff] then
      return m.venom
    end
  end

  -- All stacked - maintain paralysis
  return "curare"
end

--[[
  Select venom for riftlock strategy.
  Focuses on arm breaks + slickness + asthma.

  @return (string) - Venom name, or nil if should focus on limb damage
]]--
function lockStrategy.selectVenomRiftlock()
  -- Need asthma to block smoke cure for slickness
  if not tAffs.asthma then
    return "kalmia"
  end

  -- Need slickness to prevent mending
  if not tAffs.slickness then
    return "gecko"
  end

  -- Addiction helps deplete herbs faster
  if not tAffs.addiction then
    return "vardrax"
  end

  -- Arms not broken yet - return nil to signal limb damage focus
  if not lockStrategy.checkRiftlock() then
    return nil
  end

  -- Maintain slickness
  return "gecko"
end

--[[
  Select venom for aeonlock strategy.
  Needs aeon + asthma + kelp stack.

  @return (string) - Venom name
]]--
function lockStrategy.selectVenomAeonlock()
  -- Priority 1: Asthma (blocks smoking elm)
  if not tAffs.asthma then
    return "kalmia"
  end

  -- Priority 2: Stack kelp cures to keep asthma stuck
  local kelpStack = {
    {aff = "clumsiness", venom = "supara"},
    {aff = "sensitivity", venom = "prefarar"},
    {aff = "weariness", venom = "vernalius"},
    {aff = "healthleech", venom = "epseth"},
  }

  for _, k in ipairs(kelpStack) do
    if not tAffs[k.aff] then
      return k.venom
    end
  end

  -- Maintain asthma
  return "kalmia"
end

--[[
  Main venom selection function - uses configured strategy.

  @return (string) - Venom name
]]--
function lockStrategy.selectVenom()
  local strategy = lockStrategy.config.strategy

  if strategy == "focuslock" then
    return lockStrategy.selectVenomFocuslock()
  elseif strategy == "riftlock" then
    return lockStrategy.selectVenomRiftlock()
  elseif strategy == "aeonlock" then
    return lockStrategy.selectVenomAeonlock()
  else
    -- Default: truelock
    return lockStrategy.selectVenomTruelock()
  end
end

--[[
  Select secondary venom for dual-venom attacks.
  Complements the primary venom selection.

  @param primaryVenom (string) - The already-selected primary venom
  @return (string) - Secondary venom name
]]--
function lockStrategy.selectSecondaryVenom(primaryVenom)
  -- Try to hit different cure balances

  -- If primary is kelp cure, use bloodroot cure
  local kelpVenoms = {kalmia = true, vernalius = true, prefarar = true, supara = true}
  if kelpVenoms[primaryVenom] then
    if not tAffs.paralysis then return "curare" end
    if not tAffs.slickness then return "gecko" end
  end

  -- If primary is bloodroot cure, use kelp cure
  local bloodrootVenoms = {curare = true, gecko = true}
  if bloodrootVenoms[primaryVenom] then
    if not tAffs.asthma then return "kalmia" end
    if not tAffs.weariness then return "vernalius" end
  end

  -- If primary is goldenseal cure, use something else
  local goldensealVenoms = {euphorbia = true, xentio = true, aconite = true, colocasia = true}
  if goldensealVenoms[primaryVenom] then
    if not tAffs.paralysis then return "curare" end
    if not tAffs.weariness then return "vernalius" end
  end

  -- Default: weariness for pressure
  if not tAffs.weariness then return "vernalius" end

  -- Fallback: lethargy
  return "oleander"
end

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

--[[
  Set the lock strategy.

  @param strategy (string) - "truelock", "focuslock", "riftlock", "aeonlock"
]]--
function lockStrategy.setStrategy(strategy)
  local validStrategies = {
    truelock = true,
    focuslock = true,
    riftlock = true,
    aeonlock = true,
  }

  if validStrategies[strategy] then
    lockStrategy.config.strategy = strategy
    cecho("\n<cyan>[LockStrategy] Strategy set to: <yellow>" .. strategy:upper())
  else
    cecho("\n<red>[LockStrategy] Invalid strategy. Options: truelock, focuslock, riftlock, aeonlock")
  end
end

--[[
  Set the target class (for class-specific lock affliction).

  @param class (string) - Class name
]]--
function lockStrategy.setTargetClass(class)
  lockStrategy.config.targetClass = class
  local lockAff = lockStrategy.getClassLockAffliction()
  cecho("\n<cyan>[LockStrategy] Target class: <yellow>" .. class)
  cecho(" <cyan>| Lock aff: <yellow>" .. lockAff)
end

-- ============================================================================
-- STATUS DISPLAY
-- ============================================================================

function lockStrategy.status()
  tAffs = tAffs or {}

  local classAff = lockStrategy.getClassLockAffliction()

  cecho("\n<cyan>╔══════════════════════════════════════════════╗")
  cecho("\n<cyan>║         <white>LOCK STRATEGY STATUS<cyan>                 ║")
  cecho("\n<cyan>╠══════════════════════════════════════════════╣")
  cecho("\n<cyan>║ <white>Strategy: <yellow>" .. lockStrategy.config.strategy:upper())
  cecho("\n<cyan>║ <white>Lock Level: <yellow>" .. lockStrategy.getLockLevel())
  cecho("\n<cyan>║ <white>Target Class: <yellow>" .. tostring(lockStrategy.config.targetClass or "Unknown"))
  cecho("\n<cyan>║ <white>Class Lock Aff: <yellow>" .. classAff)

  cecho("\n<cyan>╠══════════════════════════════════════════════╣")
  cecho("\n<cyan>║ <white>SOFTLOCK:")
  cecho("\n<cyan>║   " .. (tAffs.asthma and "<green>[X]" or "<red>[ ]") .. " asthma")
  cecho("  " .. (tAffs.anorexia and "<green>[X]" or "<red>[ ]") .. " anorexia")
  cecho("  " .. (tAffs.slickness and "<green>[X]" or "<red>[ ]") .. " slickness")

  cecho("\n<cyan>║ <white>VENOMLOCK:")
  cecho("\n<cyan>║   " .. (tAffs.paralysis and "<green>[X]" or "<red>[ ]") .. " paralysis")

  cecho("\n<cyan>║ <white>HARDLOCK:")
  cecho("\n<cyan>║   " .. (tAffs.impatience and "<green>[X]" or "<red>[ ]") .. " impatience")

  cecho("\n<cyan>║ <white>TRUELOCK:")
  cecho("\n<cyan>║   " .. (tAffs[classAff] and "<green>[X]" or "<red>[ ]") .. " " .. classAff)

  if lockStrategy.config.strategy == "focuslock" then
    cecho("\n<cyan>╠══════════════════════════════════════════════╣")
    cecho("\n<cyan>║ <white>MENTAL STACK:")
    local mentals = {"stupidity", "dizziness", "epilepsy", "shyness", "depression"}
    local count = 0
    for _, m in ipairs(mentals) do
      if tAffs[m] then count = count + 1 end
    end
    cecho("\n<cyan>║   Count: <yellow>" .. count .. "/5")
  end

  if lockStrategy.config.strategy == "riftlock" then
    cecho("\n<cyan>╠══════════════════════════════════════════════╣")
    cecho("\n<cyan>║ <white>RIFTLOCK:")
    cecho("\n<cyan>║   " .. ((tLimbs.LA >= 100) and "<green>[X]" or "<red>[ ]") .. " left arm broken")
    cecho("\n<cyan>║   " .. ((tLimbs.RA >= 100) and "<green>[X]" or "<red>[ ]") .. " right arm broken")
    cecho("\n<cyan>║   " .. (tAffs.addiction and "<green>[X]" or "<red>[ ]") .. " addiction")
  end

  cecho("\n<cyan>╠══════════════════════════════════════════════╣")
  cecho("\n<cyan>║ <white>Next Venom: <yellow>" .. tostring(lockStrategy.selectVenom()))

  cecho("\n<cyan>╚══════════════════════════════════════════════╝")
end

-- ============================================================================
-- CONVENIENCE ALIASES
-- ============================================================================

function lockstatus()
  lockStrategy.status()
end

function setstrategy(strategy)
  lockStrategy.setStrategy(strategy)
end

function settargetclass(class)
  lockStrategy.setTargetClass(class)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

cecho("\n<cyan>[LockStrategy] System loaded. Commands: lockstatus(), setstrategy(strategy), settargetclass(class)")
