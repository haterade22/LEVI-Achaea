--[[mudlet
type: script
name: ClassName Limb Tracking
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
LIMB TRACKING SYSTEM TEMPLATE
================================================================================

Use this template for classes that rely on limb damage for kills:
- Monk (Shikudo/Tekura)
- Blademaster
- Knights (DWB spec)
- Any class with limb-break requirements

LIMB DAMAGE LEVELS:
  Level 0: 0-32%    - No effect
  Level 1: 33-99%   - Damaged (minor impairment)
  Level 2: 100-199% - Broken/Crippled (major impairment)
  Level 3: 200%+    - Mangled (cannot use Restore)

TEMPLATE USAGE:
1. Copy this file to your class offense directory
2. Customize damage values for your class attacks
3. Integrate with your offense system

================================================================================
]]--

-- ============================================================================
-- NAMESPACE INITIALIZATION
-- ============================================================================

limbTracker = limbTracker or {}
limbTracker.config = limbTracker.config or {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

limbTracker.config = {
  -- Debug mode
  debug = false,

  -- Auto-calculate damage based on target health
  autocalculate = true,

  -- Default staff/weapon modifier (artefact bonuses)
  weaponModifier = 1.0,
}

-- ============================================================================
-- LIMB DATA STRUCTURE
-- ============================================================================

-- Target limb damage tracking
tLimbs = tLimbs or {
  H = 0,    -- Head
  T = 0,    -- Torso
  LA = 0,   -- Left Arm
  RA = 0,   -- Right Arm
  LL = 0,   -- Left Leg
  RL = 0,   -- Right Leg
}

-- Limb name mappings (for convenience)
limbTracker.limbCodes = {
  ["head"] = "H",
  ["torso"] = "T",
  ["left arm"] = "LA",
  ["right arm"] = "RA",
  ["left leg"] = "LL",
  ["right leg"] = "RL",
  -- Short forms
  ["h"] = "H",
  ["t"] = "T",
  ["la"] = "LA",
  ["ra"] = "RA",
  ["ll"] = "LL",
  ["rl"] = "RL",
  -- Alternate forms
  ["leftarm"] = "LA",
  ["rightarm"] = "RA",
  ["leftleg"] = "LL",
  ["rightleg"] = "RL",
}

limbTracker.codeToName = {
  H = "head",
  T = "torso",
  LA = "left arm",
  RA = "right arm",
  LL = "left leg",
  RL = "right leg",
}

-- ============================================================================
-- DAMAGE FORMULAS
-- ============================================================================

--[[
  Attack damage values as percentage of target health.
  These should be customized for your class.

  Formula pattern: damage = (coefficient * targetHP + base) * weaponMod
  Then convert to percentage: percentage = (damage / targetHP) * 100

  TODO: Replace with your class's actual attack damage values
]]--
limbTracker.attackDamage = {
  -- Example values (customize for your class)
  -- Format: attack_name = percentage_damage

  -- Basic attacks
  slash = 8.0,
  thrust = 10.0,
  strike = 6.0,

  -- Kick attacks (Monk example)
  risingkick = 9.2,
  flashheel = 9.2,
  frontkick = 9.2,
  spinkick = 27.0,

  -- Staff attacks (Shikudo example)
  dart = 4.4,
  hiru = 4.3,
  hiraku = 4.3,
  kuro = 9.2,
  ruku = 4.5,
  needle = 10.6,
  nervestrike = 13.4,
  livestrike = 7.8,
  thrust_staff = 14.5,

  -- Knight attacks
  slash_knight = 8.0,
  raze = 5.0,
}

-- ============================================================================
-- DYNAMIC DAMAGE CALCULATION
-- ============================================================================

--[[
  Calculate damage percentages based on target health.
  Call this when target changes or you get health info.

  @param targetHealth (number) - Target's max health
]]--
function limbTracker.calculateDamage(targetHealth)
  if not targetHealth or targetHealth <= 0 then
    targetHealth = 5000  -- Default assumption
  end

  local mod = limbTracker.config.weaponModifier

  -- Calculate each attack's damage as percentage
  -- TODO: Customize these formulas for your class

  -- Example: Shikudo-style formulas
  limbTracker.attackDamage.dart = ((0.0440 * targetHealth + 156) * mod / targetHealth) * 100
  limbTracker.attackDamage.kuro = ((0.0451 * targetHealth + 261) * mod / targetHealth) * 100
  limbTracker.attackDamage.hiru = ((0.0426 * targetHealth + 290) * mod / targetHealth) * 100
  limbTracker.attackDamage.needle = ((0.1057 * targetHealth + 295) * mod / targetHealth) * 100

  -- Round to 2 decimal places
  for attack, dmg in pairs(limbTracker.attackDamage) do
    limbTracker.attackDamage[attack] = tonumber(string.format("%.2f", dmg))
  end

  if limbTracker.config.debug then
    cecho("\n<cyan>[LimbTracker] Damage calculated for HP: " .. targetHealth)
  end
end

-- ============================================================================
-- CORE FUNCTIONS
-- ============================================================================

--[[
  Get damage percentage for a limb.

  @param limb (string) - Limb name or code
  @return (number) - Current damage percentage
]]--
function limbTracker.getLimbDamage(limb)
  local code = limbTracker.limbCodes[limb:lower()] or limb:upper()
  return tLimbs[code] or 0
end

--[[
  Set damage percentage for a limb.

  @param limb (string) - Limb name or code
  @param damage (number) - Damage percentage to set
]]--
function limbTracker.setLimbDamage(limb, damage)
  local code = limbTracker.limbCodes[limb:lower()] or limb:upper()
  if tLimbs[code] ~= nil then
    tLimbs[code] = damage
  end
end

--[[
  Add damage to a limb from an attack.

  @param attack (string) - Attack name
  @param limb (string) - Target limb
  @param hyperfocusLimb (string, optional) - Limb being hyperfocused by target
]]--
function limbTracker.addDamage(attack, limb, hyperfocusLimb)
  local code = limbTracker.limbCodes[limb:lower()]
  if not code then
    if limbTracker.config.debug then
      cecho("\n<red>[LimbTracker] Unknown limb: " .. tostring(limb))
    end
    return
  end

  local damage = limbTracker.attackDamage[attack:lower()]
  if not damage then
    if limbTracker.config.debug then
      cecho("\n<red>[LimbTracker] Unknown attack: " .. tostring(attack))
    end
    return
  end

  -- Hyperfocus reduces damage by half
  if hyperfocusLimb and hyperfocusLimb:lower() == limb:lower() then
    damage = damage / 2
  end

  tLimbs[code] = tLimbs[code] + damage

  -- Check for break
  if tLimbs[code] >= 100 then
    limbTracker.onLimbBroken(limb, code)
  end

  if limbTracker.config.debug then
    cecho("\n<yellow>[LimbTracker] " .. limb .. " +" .. string.format("%.1f", damage) .. "% = " .. string.format("%.1f", tLimbs[code]) .. "%")
  end
end

--[[
  Handle limb break event.

  @param limb (string) - Limb name
  @param code (string) - Limb code
]]--
function limbTracker.onLimbBroken(limb, code)
  cecho("\n<red> -= " .. limb .. " BROKE! =-")

  -- Add appropriate affliction
  if code == "H" then
    tAffs.damagedhead = true
  elseif code == "LL" then
    tAffs.crippled_left_leg = true
  elseif code == "RL" then
    tAffs.crippled_right_leg = true
  elseif code == "LA" then
    tAffs.crippled_left_arm = true
  elseif code == "RA" then
    tAffs.crippled_right_arm = true
  end

  -- Raise event for other systems
  raiseEvent("limb broke", limb)
end

--[[
  Handle limb mended/restored.

  @param limb (string) - Limb name
]]--
function limbTracker.onLimbMended(limb)
  local code = limbTracker.limbCodes[limb:lower()]
  if not code then return end

  -- Reduce damage (mending heals broken state)
  if tLimbs[code] >= 100 then
    tLimbs[code] = 50  -- Partially healed
  else
    tLimbs[code] = math.max(0, tLimbs[code] - 33)
  end

  -- Clear affliction
  if code == "H" then
    tAffs.damagedhead = nil
  elseif code == "LL" then
    tAffs.crippled_left_leg = nil
  elseif code == "RL" then
    tAffs.crippled_right_leg = nil
  elseif code == "LA" then
    tAffs.crippled_left_arm = nil
  elseif code == "RA" then
    tAffs.crippled_right_arm = nil
  end

  if limbTracker.config.debug then
    cecho("\n<green>[LimbTracker] " .. limb .. " mended -> " .. string.format("%.1f", tLimbs[code]) .. "%")
  end
end

-- ============================================================================
-- PREP THRESHOLD HELPERS
-- ============================================================================

--[[
  Get the "prep threshold" for a limb - the damage level at which
  one more hit will break it.

  @param limb (string) - Limb name
  @param nextAttack (string) - Attack that will be used
  @return (number) - Threshold percentage
]]--
function limbTracker.getPrepThreshold(limb, nextAttack)
  local attackDmg = limbTracker.attackDamage[nextAttack:lower()] or 10
  return 100 - attackDmg
end

--[[
  Check if a limb is "prepped" (one more hit will break it).

  @param limb (string) - Limb name
  @param nextAttack (string) - Attack that will be used
  @return (boolean)
]]--
function limbTracker.isLimbPrepped(limb, nextAttack)
  local current = limbTracker.getLimbDamage(limb)
  local threshold = limbTracker.getPrepThreshold(limb, nextAttack)
  return current >= threshold
end

--[[
  Calculate how many hits until a limb is prepped.

  @param limb (string) - Limb name
  @param attack (string) - Attack to use
  @return (number) - Number of hits needed (0 if already prepped)
]]--
function limbTracker.hitsToPrep(limb, attack)
  local current = limbTracker.getLimbDamage(limb)
  local dmg = limbTracker.attackDamage[attack:lower()] or 10
  local threshold = 100 - dmg

  if current >= threshold then
    return 0
  end

  local remaining = threshold - current
  return math.ceil(remaining / dmg)
end

--[[
  Check if a limb is broken (at or above 100%).

  @param limb (string) - Limb name
  @return (boolean)
]]--
function limbTracker.isLimbBroken(limb)
  return limbTracker.getLimbDamage(limb) >= 100
end

--[[
  Check if a limb is mangled (at or above 200%).

  @param limb (string) - Limb name
  @return (boolean)
]]--
function limbTracker.isLimbMangled(limb)
  return limbTracker.getLimbDamage(limb) >= 200
end

-- ============================================================================
-- LIMB SELECTION HELPERS
-- ============================================================================

--[[
  Get the leg with lower damage (for balanced prep).

  @return (string) - "left" or "right"
]]--
function limbTracker.getFocusLeg()
  local ll = limbTracker.getLimbDamage("left leg")
  local rl = limbTracker.getLimbDamage("right leg")
  return ll <= rl and "left" or "right"
end

--[[
  Get the leg with higher damage.

  @return (string) - "left" or "right"
]]--
function limbTracker.getOffLeg()
  local ll = limbTracker.getLimbDamage("left leg")
  local rl = limbTracker.getLimbDamage("right leg")
  return ll >= rl and "left" or "right"
end

--[[
  Get the arm with lower damage (for balanced prep).

  @return (string) - "left" or "right"
]]--
function limbTracker.getFocusArm()
  local la = limbTracker.getLimbDamage("left arm")
  local ra = limbTracker.getLimbDamage("right arm")
  return la <= ra and "left" or "right"
end

--[[
  Check if both legs are prepped.

  @param attack (string) - Attack to use for threshold calc
  @return (boolean)
]]--
function limbTracker.areBothLegsPrepped(attack)
  return limbTracker.isLimbPrepped("left leg", attack) and
         limbTracker.isLimbPrepped("right leg", attack)
end

--[[
  Check if both arms are prepped.

  @param attack (string) - Attack to use for threshold calc
  @return (boolean)
]]--
function limbTracker.areBothArmsPrepped(attack)
  return limbTracker.isLimbPrepped("left arm", attack) and
         limbTracker.isLimbPrepped("right arm", attack)
end

--[[
  Check if both arms are broken (for riftlock).

  @return (boolean)
]]--
function limbTracker.areBothArmsBroken()
  return limbTracker.isLimbBroken("left arm") and
         limbTracker.isLimbBroken("right arm")
end

-- ============================================================================
-- RESET AND UTILITY
-- ============================================================================

--[[
  Reset all limb damage (call on target change).
]]--
function limbTracker.reset()
  tLimbs = {
    H = 0,
    T = 0,
    LA = 0,
    RA = 0,
    LL = 0,
    RL = 0,
  }
  cecho("\n<cyan>[LimbTracker] Limb damage reset")
end

--[[
  Display current limb status.
]]--
function limbTracker.status()
  cecho("\n<cyan>╔══════════════════════════════════════════════╗")
  cecho("\n<cyan>║         <white>LIMB DAMAGE STATUS<cyan>                   ║")
  cecho("\n<cyan>╠══════════════════════════════════════════════╣")

  local function formatLimb(name, code)
    local dmg = tLimbs[code] or 0
    local color = "<green>"
    if dmg >= 100 then color = "<red>"
    elseif dmg >= 80 then color = "<yellow>"
    elseif dmg >= 50 then color = "<orange>"
    end
    return string.format("║   <white>%-10s " .. color .. "%6.1f%%", name, dmg)
  end

  cecho("\n<cyan>" .. formatLimb("Head", "H"))
  cecho("\n<cyan>" .. formatLimb("Torso", "T"))
  cecho("\n<cyan>" .. formatLimb("Left Arm", "LA"))
  cecho("\n<cyan>" .. formatLimb("Right Arm", "RA"))
  cecho("\n<cyan>" .. formatLimb("Left Leg", "LL"))
  cecho("\n<cyan>" .. formatLimb("Right Leg", "RL"))

  cecho("\n<cyan>╠══════════════════════════════════════════════╣")
  cecho("\n<cyan>║ <white>BREAK STATUS:")
  cecho("\n<cyan>║   Arms broken: " .. (limbTracker.areBothArmsBroken() and "<green>YES" or "<red>NO"))
  cecho("  Legs broken: " .. ((limbTracker.isLimbBroken("left leg") or limbTracker.isLimbBroken("right leg")) and "<green>YES" or "<red>NO"))
  cecho("\n<cyan>╚══════════════════════════════════════════════╝")
end

-- ============================================================================
-- CONVENIENCE ALIASES
-- ============================================================================

function limbstatus()
  limbTracker.status()
end

function limbreset()
  limbTracker.reset()
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

cecho("\n<cyan>[LimbTracker] System loaded. Commands: limbstatus(), limbreset()")
