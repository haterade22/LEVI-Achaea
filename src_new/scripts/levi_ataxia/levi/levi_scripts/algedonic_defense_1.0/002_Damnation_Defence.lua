--[[mudlet
type: script
name: Damnation Defence
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Algedonic Defense 1.0
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[mudlet
type: script
name: Damnation Defense
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Curing
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- ============================================================================
-- DAMNATION DEFENSE MODULE
-- ============================================================================
-- Paladin kill condition: PERFORM DAMNATION <target>
-- Requirements: Broken head + (two of pyre/guilt/spiritburn OR burning level 5)
-- This module provides threat detection and automatic curing priority adjustment
--
-- IMPORTANT: PYRE and BURNING are DIFFERENT afflictions!
-- - PYRE: Stacking affliction (1-3) that BLOCKS curing burning below pyre level
--   Applied by PERFORM PYRE, cured by cuprum
-- - BURNING: Fire DoT affliction (1-5) from BLADEFIRE weapon strikes
--   Level 5 burning + broken head = alternative Damnation trigger
--
-- CRITICAL: PALADINS CAN ONLY GIVE PYRE!
-- - Guilt and spiritburn come from PRIESTS, not Paladins
-- - Solo Paladin Damnation requires: broken head + burning level 5
-- - Group (Paladin + Priest): broken head + pyre + guilt/spiritburn
-- - If fighting solo Paladin, focus on preventing burning stack to 5

-- ============================================================================
-- PALADIN DETECTION HELPER
-- ============================================================================
-- Checks NDB class OR combat-detected flag (set when pyre is applied)
-- This allows Damnation defense to work even if target isn't in NDB

local function isPaladinTarget()
  if not target then return false end
  local targetClass = ataxiaNDB_getClass and ataxiaNDB_getClass(target) or nil
  return (targetClass == "Paladin") or (ataxiaTemp and ataxiaTemp.fightingPaladin)
end

-- ============================================================================
-- DAMNATION THREAT DETECTION
-- ============================================================================

function checkDamnationThreat()
  -- Only relevant when fighting Paladins
  if not isPaladinTarget() then return false end

  -- Check if head is broken (any level of damage counts)
  local headBroken = ataxia.afflictions.damagedhead
                  or ataxia.afflictions.brokenhead
                  or ataxia.afflictions.mangledhead

  if not headBroken then return false end

  -- Count Damnation components (need 2 of these with broken head)
  -- PYRE: From Paladin (PERFORM PYRE)
  -- GUILT: From Priest only (zeal abilities)
  -- SPIRITBURN: From Priest only (zeal abilities)
  -- Note: If fighting solo Paladin, they can ONLY use the burning level 5 route
  local components = {}
  local componentCount = 0
  local pyreLevel = ataxia.afflictions.pyre or 0

  if pyreLevel >= 1 then
    componentCount = componentCount + 1
    table.insert(components, "PYRE("..pyreLevel..")")
  end
  if ataxia.afflictions.guilt then
    componentCount = componentCount + 1
    table.insert(components, "GUILT")
  end
  if ataxia.afflictions.spiritburn then
    componentCount = componentCount + 1
    table.insert(components, "SPIRITBURN")
  end

  local burnLevel = ataxia.afflictions.burning or 0
  local componentStr = table.concat(components, " + ")

  -- Check kill conditions and warn appropriately
  if componentCount >= 2 then
    -- CRITICAL: Kill conditions fully met via pyre/guilt/spiritburn route
    ataxia_boxEcho("DAMNATION READY! HEAD + "..componentStr, "a_darkred:white")
    ataxia_boxEcho("SHIELD NOW OR DIE!", "a_darkred:white")
    return true, "critical"
  elseif burnLevel >= 5 then
    -- CRITICAL: Kill conditions met via burning level 5 route
    ataxia_boxEcho("DAMNATION READY! HEAD + BURNING(5)", "a_darkred:white")
    ataxia_boxEcho("SHIELD NOW OR DIE!", "a_darkred:white")
    return true, "critical"
  elseif pyreLevel >= 3 then
    -- CRITICAL: Pyre 3 locks burning floor at 3 - cure pyre before resto!
    ataxia_boxEcho("DAMNATION DANGER! HEAD + PYRE(3) - cure pyre before resto!", "a_darkred:white")
    return true, "critical"
  elseif componentCount >= 1 and (ataxia.afflictions.guilt or ataxia.afflictions.spiritburn) then
    -- WARNING: Guilt/spiritburn present (from Priest) - one more component = death
    ataxia_boxEcho("DAMNATION WARNING! HEAD + "..componentStr.." (Priest components!)", "orange")
    return true, "warning"
  elseif burnLevel >= 3 then
    -- WARNING: Burning approaching threshold
    ataxia_boxEcho("DAMNATION WARNING! HEAD + BURNING("..burnLevel..") approaching 5", "orange")
    return true, "warning"
  elseif pyreLevel >= 1 then
    -- INFO: Pyre 1-2 is manageable - resto is safe
    ataxia_boxEcho("Pyre "..pyreLevel.." + head broken - resto safe (pyre <= 2)", "yellow")
    return true, "info"
  end

  return false
end

-- ============================================================================
-- ANTI-PALADIN CURING PRIORITY LOGIC
-- ============================================================================
-- NOTE: Paladins can ONLY give PYRE (via PERFORM PYRE)
-- Guilt and spiritburn come from PRIESTS, not Paladins
-- Solo Paladin Damnation requires: broken head + burning level 5
-- Group fight: Priest can provide guilt/spiritburn for faster kill

-- Is any Damnation escalation currently warranted? Deliberately SILENT -- checkDamnationThreat
-- prints alert boxes, so it cannot be used as a predicate on the restore path.
-- Every branch of AntiPaladin that writes a priority requires a broken head, so this one
-- condition covers all of them.
local function damnationEscalationNeeded()
  if not isPaladinTarget() then return false end
  return (ataxia.afflictions.damagedhead
       or ataxia.afflictions.brokenhead
       or ataxia.afflictions.mangledhead) and true or false
end

-- Every name AntiPaladin escalates, so the writes and the restores can never drift apart.
-- All eight have a static entry in ataxia_defaultCuringPrios(), which is what lets
-- ataxia_restorePrio put an exact value back.
local DAMNATION_PRIOS = {
  "pyre", "pyre3", "burning4", "burning5", "guilt", "spiritburn",
  "damagedhead", "mangledhead",
}

-- Is an escalation of ours still standing? The ataxiaTemp latch is the normal answer, but it
-- does not survive a reload -- and `ataxia_resetOnLogin`, which an earlier version of this
-- comment named as the backstop, HAS NO CALLERS anywhere in src_new, so nothing rewrites the
-- table on login. What does survive is `ataxia.curingprio`: saved to disk, refilled by
-- trigger 719. A recorded value that disagrees with the table is an escalation that outlived
-- its latch. ataxia_getPrio answers 0 for a name the server never confirmed, so a real
-- recorded value is required before believing it.
local function damnationStillEscalated()
  ataxiaTemp = ataxiaTemp or {}
  if ataxiaTemp.damnationPrios then return true end
  for _, aff in ipairs(DAMNATION_PRIOS) do
    local cur = ataxia.curingprio and ataxia.curingprio[aff]
    local def = ataxia_defaultPrioAff and ataxia_defaultPrioAff(aff)
    if type(cur) == "number" and cur > 0 and def and cur ~= def then return true end
  end
  return false
end

-- AntiPaladin writes STORED curing priorities and this file had NEVER restored them. That
-- was survivable only while the writes were no-ops: they all targeted the BARE name
-- (`curing priority burning 1`), which the per-stack entries silently overrode. Now that
-- they land, one Damnation scare would otherwise leave burning ahead of paralysis in the
-- active curingset permanently -- and if that set is the PvE `bash` one, permanently there.
--
-- The latch lives on ataxiaTemp, NOT ataxia: the saved namespace is serialized wholesale and
-- deepMerged back with an unconditional dst[k] = v, so a latch stored there would come back
-- TRUE after a relog with nothing alive to clear it.
function Algedonic.RestorePaladin()
  ataxiaTemp = ataxiaTemp or {}
  if not damnationStillEscalated() then return end
  if damnationEscalationNeeded() then return end
  -- ataxia_restorePrio routes through ataxia_sendCuringPriority, which DROPS stored
  -- affliction writes while the PvE bash set is active. Clearing the latch regardless would
  -- strand the escalation in the PvP set the moment a Damnation scare was followed by a
  -- bashing session -- so hold it until the writes can actually leave.
  if ataxia_bashProfileActive and ataxia_bashProfileActive() then return end
  for _, aff in ipairs(DAMNATION_PRIOS) do
    ataxia_restorePrio(aff)
  end
  ataxiaTemp.damnationPrios = nil
  Algedonic.Echo("Damnation threat clear <white>- curing priorities restored.")
end

function Algedonic.AntiPaladin()
  -- Only run when fighting Paladins
  if not isPaladinTarget() then return end

  local headBroken = ataxia.afflictions.damagedhead
                  or ataxia.afflictions.brokenhead
                  or ataxia.afflictions.mangledhead

  local pyreLevel = ataxia.afflictions.pyre or 0
  local burnLevel = ataxia.afflictions.burning or 0
  local hasGuilt = ataxia.afflictions.guilt
  local hasSpiritburn = ataxia.afflictions.spiritburn

  -- Two of pyre/guilt/spiritburn with a broken head IS the kill.
  local components = (pyreLevel >= 1 and 1 or 0)
                   + (hasGuilt and 1 or 0)
                   + (hasSpiritburn and 1 or 0)

  -- NEVER WRITE A BARE STACK NAME TO ESCALATE. Since the 2026-08-19 announcement a bare
  -- `curing priority burning <n>` sets the BASE, which is exactly what the per-stack entries
  -- override -- so the writes this function used to make were unreachable at the very levels
  -- they were written for. Only escalate a level that has a static entry in
  -- ataxia_defaultCuringPrios(), so ataxia_restorePrio always has an exact value to put back.
  --
  -- ataxia_setAffPrio (not sendCuringPriority) because AntiPaladin runs from
  -- Algedonic.Prioritize() on EVERY affliction gained, and setAffPrio carries the 1s per-aff
  -- debounce. `brokenhead` is deliberately not written: it is not in the default table, so it
  -- could never be restored -- if it turns out to be a real server name, price it there first.
  local function escalate(aff, n)
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.damnationPrios = true
    ataxia_setAffPrio(aff, n)
  end

  -- NO EARLY RETURNS. The old chain was three `if ... return end` branches, which meant the
  -- head cure was skipped by the pyre-3 branch -- the single most dangerous state it models
  -- -- and the guilt write at the bottom was reachable ONLY when the head was whole, the one
  -- state in which guilt does not matter. Every applicable response now runs.

  -- THE HEAD is the shared prerequisite of both kill routes, so it is raised whenever broken.
  if headBroken then
    escalate("damagedhead", 2)
    escalate("mangledhead", 2)
  end

  -- ROUTE A -- COMPONENTS. paladin.md calls "two of pyre/guilt/spiritburn" the MOST COMMON
  -- route, and nothing used to escalate any of its members.
  if headBroken and components >= 1 then
    if pyreLevel >= 3 then
      escalate("pyre3", 1)      -- pyre 3 pins the burn floor at 3; 1 is the reserved slot
    elseif pyreLevel >= 1 then
      escalate("pyre", 3)
    end
    if hasGuilt then escalate("guilt", 2) end
    if hasSpiritburn then escalate("spiritburn", 2) end
  end

  -- ROUTE B -- SOLO BURN. A Paladin alone can only apply pyre, so their other route is
  -- burning 5 with a broken head. The static table has burning4 at 6 and burning5 at 4; the
  -- broken head is the context it cannot know, so both go to the emergency slot.
  if headBroken and burnLevel >= 3 then
    escalate("burning4", 1)
    escalate("burning5", 1)
  end

  -- Guilt blocks Focus even with the head whole.
  if hasGuilt and not headBroken then escalate("guilt", 3) end

  -- One callout, chosen from the whole picture rather than from whichever branch fired first.
  local parts = {}
  if pyreLevel >= 1 then parts[#parts + 1] = "PYRE(" .. pyreLevel .. ")" end
  if hasGuilt then parts[#parts + 1] = "GUILT" end
  if hasSpiritburn then parts[#parts + 1] = "SPIRITBURN" end
  if burnLevel >= 1 then parts[#parts + 1] = "BURNING(" .. burnLevel .. ")" end
  local desc = table.concat(parts, " + ")

  if headBroken and (components >= 2 or burnLevel >= 5) then
    Algedonic.Echo("CRITICAL: <a_darkred>DAMNATION READY<white> - head + " .. desc)
  elseif headBroken and (components >= 1 or burnLevel >= 3) then
    Algedonic.Echo("WARNING: <orange>head broken<white> + " .. desc)
  elseif headBroken then
    Algedonic.Echo("Head broken vs Paladin - prioritising head cure")
  elseif pyreLevel >= 3 then
    Algedonic.Echo("Pyre 3 - already prioritised by the table; watch for the head")
  end

  -- Handle disembowel threat (standard Knight logic)
  -- Both legs broken + arm broken + prone = disembowel
  if ataxia.afflictions.brokenleftleg and ataxia.afflictions.brokenrightleg then
    if ataxia.afflictions.brokenleftarm or ataxia.afflictions.brokenrightarm then
      -- Disembowel setup complete
      ataxia_sendCuringPriority("curing priority brokenleftleg 1")
      ataxia_sendCuringPriority("curing priority brokenrightleg 1")
      Algedonic.Echo("DISEMBOWEL THREAT - cure legs immediately!")
    end
  end
end

-- ============================================================================
-- DAMNATION PROMPT WARNING
-- ============================================================================
-- Returns a string to append to prompt when Damnation threat is detected
function getDamnationPromptWarning()
  if not isPaladinTarget() then return "" end

  local headBroken = ataxia.afflictions.damagedhead
                  or ataxia.afflictions.brokenhead
                  or ataxia.afflictions.mangledhead

  if not headBroken then return "" end

  local pyreLevel = ataxia.afflictions.pyre or 0
  local burnLevel = ataxia.afflictions.burning or 0
  local hasGuilt = ataxia.afflictions.guilt
  local hasSpiritburn = ataxia.afflictions.spiritburn

  -- Count components
  local count = 0
  if pyreLevel >= 1 then count = count + 1 end
  if hasGuilt then count = count + 1 end
  if hasSpiritburn then count = count + 1 end

  if count >= 2 or burnLevel >= 5 then
    return " <a_darkred>(Locks: DAMNATION!)"
  elseif count >= 1 or burnLevel >= 3 then
    return " <orange>(Locks: damnation!)"
  end

  return ""
end
