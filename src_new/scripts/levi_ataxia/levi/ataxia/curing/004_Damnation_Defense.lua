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
-- DAMNATION THREAT DETECTION
-- ============================================================================

function checkDamnationThreat()
  -- Only relevant when fighting Paladins
  if not target then return false end

  local targetClass = ataxiaNDB_getClass and ataxiaNDB_getClass(target) or nil
  if targetClass ~= "Paladin" then return false end

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

function Algedonic.AntiPaladin()
  -- Only run when fighting Paladins
  if not target then return end

  local targetClass = ataxiaNDB_getClass and ataxiaNDB_getClass(target) or nil
  if targetClass ~= "Paladin" then return end

  -- Track current affliction state
  local headBroken = ataxia.afflictions.damagedhead
                  or ataxia.afflictions.brokenhead
                  or ataxia.afflictions.mangledhead

  local hasPyre = ataxia.afflictions.pyre and ataxia.afflictions.pyre >= 1
  local pyreLevel = ataxia.afflictions.pyre or 0
  local hasGuilt = ataxia.afflictions.guilt
  local hasSpiritburn = ataxia.afflictions.spiritburn
  local burnLevel = ataxia.afflictions.burning or 0

  -- Count how many Damnation components we have
  local damnationComponents = 0
  if hasPyre then damnationComponents = damnationComponents + 1 end
  if hasGuilt then damnationComponents = damnationComponents + 1 end
  if hasSpiritburn then damnationComponents = damnationComponents + 1 end

  -- CRITICAL PRIORITY: Head broken with pyre 3 or high burning
  -- PYRE CURE STRATEGY: Only cure pyre if at level 3 AND need to resto
  -- At pyre 1-2, burning can be cured down safely (resto is safe)
  -- At pyre 3, burning floor is locked at 3 (Damnation danger zone)
  if headBroken and pyreLevel >= 3 then
    -- Pyre 3 + head broken = must cure pyre before resto is safe
    send("curing priority pyre 1")
    Algedonic.Echo("CRITICAL: <magenta>PYRE 3<white> + head broken - cure pyre before resto!")
    return
  end

  if headBroken and burnLevel >= 3 then
    -- Burning approaching Damnation threshold
    send("curing priority burning 1")
    Algedonic.Echo("CRITICAL: <orange>BURNING "..burnLevel.."<white> + head broken - Damnation threat!")
    -- Also prioritize head healing
    send("curing priority damagedhead 2")
    send("curing priority brokenhead 2")
    send("curing priority mangledhead 2")
    return
  end

  -- HIGH PRIORITY: Head broken, safe to resto if pyre <= 2
  if headBroken then
    send("curing priority damagedhead 2")
    send("curing priority brokenhead 2")
    send("curing priority mangledhead 2")
    if pyreLevel >= 1 then
      Algedonic.Echo("Head broken + pyre "..pyreLevel.." - safe to resto (pyre <= 2)")
    else
      Algedonic.Echo("Head broken vs Paladin - prioritizing head cure")
    end
    return
  end

  -- MEDIUM PRIORITY: Pyre 3 without head broken - cure down preemptively
  if pyreLevel >= 3 then
    send("curing priority pyre 3")
    Algedonic.Echo("Pyre 3 - curing preemptively before head gets targeted")
    return
  end

  -- Guilt blocks Focus - always high priority
  if hasGuilt then
    send("curing priority guilt 3")
  end

  -- Handle disembowel threat (standard Knight logic)
  -- Both legs broken + arm broken + prone = disembowel
  if ataxia.afflictions.brokenleftleg and ataxia.afflictions.brokenrightleg then
    if ataxia.afflictions.brokenleftarm or ataxia.afflictions.brokenrightarm then
      -- Disembowel setup complete
      send("curing priority brokenleftleg 1")
      send("curing priority brokenrightleg 1")
      Algedonic.Echo("DISEMBOWEL THREAT - cure legs immediately!")
    end
  end
end

-- ============================================================================
-- DAMNATION PROMPT WARNING
-- ============================================================================
-- Returns a string to append to prompt when Damnation threat is detected
function getDamnationPromptWarning()
  if not target then return "" end

  local targetClass = ataxiaNDB_getClass and ataxiaNDB_getClass(target) or nil
  if targetClass ~= "Paladin" then return "" end

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
