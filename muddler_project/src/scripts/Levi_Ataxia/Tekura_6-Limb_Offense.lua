-- Tekura 6-Limb Backbreaker Dispatch System
-- Kill Route: Prep ALL 6 limbs -> Break Arms+Torso (HRS) -> WRT Torso + Break Legs (BRS) -> BBT
--
-- Phases:
--   1. PREP:        All 6 limbs to 86%+ (one punch from break)
--   2. BREAK_UPPER: combo tar mnk <arm> spp <arm> hkp;hrs
--   3. BREAK_LOWER: combo tar wrt torso hfp left hfp right;brs
--   4. KILL:        bbt tar (Bear stance)
--
-- Parry Avoidance:
--   - During PREP: skip parried limb, target others
--   - Last limb parried: kai surge (dismount) -> sweep (prones) -> punch last limb

--------------------------------------------------------------------------------
-- NAMESPACE & STATE
--------------------------------------------------------------------------------

tekura6 = tekura6 or {}
tekura6.dispatch = tekura6.dispatch or {}

tekura6.state = {
  lastAttackTime = 0,
  kickDamage = 25,       -- default, updated dynamically from combat
  punchDamage = 14,      -- default, updated dynamically from combat
}

tekura6.config = {
  breakThreshold = 100,
  debugEcho = true,
}

tekura6.PHASES = {
  PREP = 1,
  BREAK_UPPER = 2,
  BREAK_LOWER = 3,
  KILL = 4,
}

tekura6.PHASE_NAMES = {
  [1] = "PREP (6-Limb)",
  [2] = "BREAK UPPER",
  [3] = "BREAK LOWER",
  [4] = "*** KILL ***",
}

-- Maps each limb to its kick and punch abbreviation
tekura6.LIMB_ATTACKS = {
  head           = { kick = "wwk",       punch = "ucp" },
  torso          = { kick = "sdk",       punch = "hkp" },
  ["left arm"]   = { kick = "mnk left",  punch = "spp left" },
  ["right arm"]  = { kick = "mnk right", punch = "spp right" },
  ["left leg"]   = { kick = "snk left",  punch = "hfp left" },
  ["right leg"]  = { kick = "snk right", punch = "hfp right" },
}

-- All 6 limb names for iteration
tekura6.ALL_LIMBS = {
  "head", "torso", "left arm", "right arm", "left leg", "right leg"
}

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------------------

-- Dynamic prep threshold based on actual punch damage
function tekura6.getPrepThreshold()
  return tekura6.config.breakThreshold - tekura6.state.punchDamage
end

-- Event handler: capture actual kick/punch damage from combat
function tekura6.onLimbHitUpdated(event, name, limb, amount)
  if not target or type(target) ~= "string" or name:lower() ~= target:lower() then return end
  -- Kicks do ~18-25%, punches do ~14-15%. Threshold at 16% to classify.
  if amount > 16 then
    tekura6.state.kickDamage = amount
  else
    tekura6.state.punchDamage = amount
  end
end

if tekura6._eventHandler then killAnonymousEventHandler(tekura6._eventHandler) end
tekura6._eventHandler = registerAnonymousEventHandler("limb hits updated", "tekura6.onLimbHitUpdated")

-- Get limb damage from lb[target].hits
function tekura6.getLimbDamage(limb)
  if not target or target == "" then return 0 end
  lb = lb or {}
  if not lb[target] then return 0 end
  if not lb[target].hits then return 0 end
  return lb[target].hits[limb] or 0
end

-- Check if a specific limb is prepped (one punch from break, dynamic threshold)
function tekura6.isLimbPrepped(limb)
  return tekura6.getLimbDamage(limb) >= tekura6.getPrepThreshold()
end

-- Check if a specific limb is broken (100%+)
function tekura6.isLimbBroken(limb)
  return tekura6.getLimbDamage(limb) >= tekura6.config.breakThreshold
end

-- Check if ALL 6 limbs are prepped (86%+)
function tekura6.checkAllSixPrepped()
  for _, limb in ipairs(tekura6.ALL_LIMBS) do
    if not tekura6.isLimbPrepped(limb) then
      return false
    end
  end
  return true
end

-- Get list of unprepped limbs (below 86%)
function tekura6.getUnpreppedLimbs()
  local unprepped = {}
  for _, limb in ipairs(tekura6.ALL_LIMBS) do
    if not tekura6.isLimbPrepped(limb) then
      table.insert(unprepped, limb)
    end
  end
  return unprepped
end

-- Get parried limb from existing tracking
function tekura6.getParried()
  ataxiaTemp = ataxiaTemp or {}
  return ataxiaTemp.parriedLimb or "none"
end

-- Check if target can parry (cannot parry while prone or paralyzed)
function tekura6.canTargetParry()
  tAffs = tAffs or {}
  if tAffs.prone or tAffs.paralysis then
    return false
  end
  return true
end

-- Get effective parried limb (accounts for prone/paralysis)
function tekura6.getEffectiveParry()
  if not tekura6.canTargetParry() then
    return "none"
  end
  return tekura6.getParried()
end

-- Check if target has shield
function tekura6.checkShield()
  tAffs = tAffs or {}
  return tAffs.shield or false
end

-- Check if target is mounted
function tekura6.isMounted()
  tAffs = tAffs or {}
  return tmounted or tAffs.mounted or false
end

-- Echo helper with tag
function tekura6.echo(text)
  cecho("\n<yellow>[TK6]<reset> " .. text)
end

--------------------------------------------------------------------------------
-- PHASE DETECTION
--------------------------------------------------------------------------------

function tekura6.dispatch.getPhase()
  tAffs = tAffs or {}

  -- KILL: All 6 broken AND prone
  local allBroken = true
  for _, limb in ipairs(tekura6.ALL_LIMBS) do
    if not tekura6.isLimbBroken(limb) then
      allBroken = false
      break
    end
  end
  if allBroken and tAffs.prone then
    return tekura6.PHASES.KILL
  end

  -- BREAK_LOWER: Both arms + torso broken (from BREAK_UPPER), legs NOT yet both broken
  local armsBroken = tekura6.isLimbBroken("left arm") and tekura6.isLimbBroken("right arm")
  local torsoBroken = tekura6.isLimbBroken("torso")
  local bothLegsBroken = tekura6.isLimbBroken("left leg") and tekura6.isLimbBroken("right leg")

  if armsBroken and torsoBroken and not bothLegsBroken then
    return tekura6.PHASES.BREAK_LOWER
  end

  -- BREAK_UPPER: All 6 prepped (86%+), need to break arms + torso
  if tekura6.checkAllSixPrepped() then
    return tekura6.PHASES.BREAK_UPPER
  end

  -- PREP: Default
  return tekura6.PHASES.PREP
end

function tekura6.dispatch.getPhaseName(phase)
  return tekura6.PHASE_NAMES[phase] or "UNKNOWN"
end

--------------------------------------------------------------------------------
-- COMBO BUILDERS
--------------------------------------------------------------------------------

-- PREP: Dynamic combo builder with parry avoidance and overflow prevention
-- RULE: Never break a limb before all 6 are prepped.
-- Priority: non-parried safe > parried safe > jbp arms (punches only)
function tekura6.dispatch.buildPrepAttack()
  local parried = tekura6.getEffectiveParry()
  local unprepped = tekura6.getUnpreppedLimbs()
  local kickDmg = tekura6.state.kickDamage
  local punchDmg = tekura6.state.punchDamage
  local breakAt = tekura6.config.breakThreshold

  -- EDGE CASE: Only 1 unprepped limb and it's parried
  if #unprepped == 1 and unprepped[1] == parried then
    return tekura6.dispatch.buildParryBypassAttack(unprepped[1])
  end

  -- EDGE CASE: No unprepped limbs (shouldn't reach here, phase would be BREAK)
  if #unprepped == 0 then
    return "combo " .. target .. " sdk jbp arms jbp arms"
  end

  -- Build simulated damage table for ALL unprepped limbs
  local simDmg = {}
  for _, limb in ipairs(unprepped) do
    simDmg[limb] = tekura6.getLimbDamage(limb)
  end

  -- Helper: find the best safe limb for an attack of given damage
  -- Prefers non-parried, falls back to parried if no safe non-parried exists
  local function findSafeLimb(candidates, atkDmg)
    -- Sort candidates by simulated damage ascending
    table.sort(candidates, function(a, b)
      return (simDmg[a] or 0) < (simDmg[b] or 0)
    end)
    -- First pass: non-parried limbs
    for _, limb in ipairs(candidates) do
      if limb ~= parried and (simDmg[limb] or 0) + atkDmg < breakAt then
        return limb
      end
    end
    -- Second pass: parried limb (better to waste a hit than break a limb)
    for _, limb in ipairs(candidates) do
      if limb == parried and (simDmg[limb] or 0) + atkDmg < breakAt then
        return limb
      end
    end
    return nil
  end

  -- Make a working copy of unprepped for candidate lists
  local allCandidates = {}
  for _, limb in ipairs(unprepped) do
    table.insert(allCandidates, limb)
  end

  -- KICK: Find safe kick target (prefer non-parried, fallback to parried)
  local kickLimb = findSafeLimb(allCandidates, kickDmg)
  if not kickLimb then
    -- Absolute last resort: kick lowest-damage limb (extremely rare)
    table.sort(allCandidates, function(a, b)
      return (simDmg[a] or 0) < (simDmg[b] or 0)
    end)
    kickLimb = allCandidates[1]
  end
  simDmg[kickLimb] = (simDmg[kickLimb] or 0) + kickDmg

  -- PUNCH 1: Find safe punch target
  local punch1Str
  local punch1Limb = findSafeLimb(allCandidates, punchDmg)
  if punch1Limb then
    punch1Str = tekura6.LIMB_ATTACKS[punch1Limb].punch
    simDmg[punch1Limb] = (simDmg[punch1Limb] or 0) + punchDmg
  else
    punch1Str = "jbp arms"
  end

  -- PUNCH 2: Find safe punch target (after simulated punch 1)
  local punch2Str
  local punch2Limb = findSafeLimb(allCandidates, punchDmg)
  if punch2Limb then
    punch2Str = tekura6.LIMB_ATTACKS[punch2Limb].punch
  else
    punch2Str = "jbp arms"
  end

  local kick = tekura6.LIMB_ATTACKS[kickLimb].kick
  return "combo " .. target .. " " .. kick .. " " .. punch1Str .. " " .. punch2Str
end

-- PARRY BYPASS: Kai surge (dismount) + sweep (prone) + punch last limb
function tekura6.dispatch.buildParryBypassAttack(parriedLimb)
  local cmd = ""

  -- Kai surge to dismount if mounted (required for sweep)
  if tekura6.isMounted() then
    cmd = "kai surge " .. target .. ";"
  end

  -- Sweep prones target (prone = can't parry), then 2 punches on last limb
  local punch = tekura6.LIMB_ATTACKS[parriedLimb].punch

  cmd = cmd .. "combo " .. target .. " swk " .. punch .. " " .. punch

  return cmd
end

-- BREAK_UPPER: Break both arms + torso, switch to Horse stance
function tekura6.dispatch.buildBreakUpperAttack()
  local parried = tekura6.getEffectiveParry()

  -- Default: kick left arm, punch right arm
  local kickArm = "left"
  local punchArm = "right"

  -- If parrying left arm, kick right instead (guaranteed break with 25%)
  if parried == "left arm" then
    kickArm = "right"
    punchArm = "left"
  elseif parried == "right arm" then
    kickArm = "left"
    punchArm = "right"
  end

  -- MNK arm (25% = breaks), SPP other arm (14% = breaks if prepped), HKP torso (14% = breaks if prepped)
  return "combo " .. target .. " mnk " .. kickArm .. " spp " .. punchArm .. " hkp;hrs"
end

-- BREAK_LOWER: Wrench torso (prones) + break both legs, switch to Bear stance
function tekura6.dispatch.buildBreakLowerAttack()
  -- WRT torso (Horse stance, prones target) + HFP left + HFP right (break both legs)
  return "combo " .. target .. " wrt torso hfp left hfp right;brs"
end

-- KILL: Backbreaker in Bear stance
function tekura6.dispatch.buildKillAttack()
  return "bbt " .. target
end

--------------------------------------------------------------------------------
-- MAIN DISPATCH FUNCTION
--------------------------------------------------------------------------------

function tekura6.dispatch.run()
  -- Initialize globals
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}
  ataxiaTemp = ataxiaTemp or {}
  tAffs = tAffs or {}

  -- Safety check
  if not target or target == "" then
    cecho("\n<red>[TK6] No target set! Use: tar <name>")
    return
  end

  -- Get current phase
  local phase = tekura6.dispatch.getPhase()
  local phaseName = tekura6.dispatch.getPhaseName(phase)

  -- Get parry status
  local parried = tekura6.getEffectiveParry()

  -- Debug output: all 6 limbs
  local h  = tekura6.getLimbDamage("head")
  local t  = tekura6.getLimbDamage("torso")
  local la = tekura6.getLimbDamage("left arm")
  local ra = tekura6.getLimbDamage("right arm")
  local ll = tekura6.getLimbDamage("left leg")
  local rl = tekura6.getLimbDamage("right leg")

  if tekura6.config.debugEcho then
    cecho("\n<yellow>[TK6 " .. phaseName .. "]<reset> ")
    cecho("H:<cyan>" .. string.format("%.0f", h) .. "%<reset> ")
    cecho("T:<cyan>" .. string.format("%.0f", t) .. "%<reset> ")
    cecho("LA:<cyan>" .. string.format("%.0f", la) .. "%<reset> ")
    cecho("RA:<cyan>" .. string.format("%.0f", ra) .. "%<reset> ")
    cecho("LL:<cyan>" .. string.format("%.0f", ll) .. "%<reset> ")
    cecho("RL:<cyan>" .. string.format("%.0f", rl) .. "%<reset> ")
    cecho("Prone:<" .. (tAffs.prone and "green>YES" or "red>NO") .. "<reset>")
    cecho(" K:<yellow>" .. string.format("%.1f", tekura6.state.kickDamage) .. "<reset>")
    cecho(" P:<yellow>" .. string.format("%.1f", tekura6.state.punchDamage) .. "<reset>")
    if parried ~= "none" then
      cecho(" <red>PARRY:" .. parried .. "<reset>")
    end
  end

  -- Build command with combatQueue prefix
  local cmd = ""
  if combatQueue then
    cmd = combatQueue()
  end

  -- SHIELD CHECK: raze with RHK
  if tekura6.checkShield() then
    cmd = cmd .. "unwield all;dismount;combo " .. target .. " rhk hkp hkp"
    send("queue addclear free " .. cmd)
    cecho("\n<yellow>[TK6] RAZING SHIELD")
    return
  end

  -- Build attack based on phase
  local attack
  if phase == tekura6.PHASES.PREP then
    attack = tekura6.dispatch.buildPrepAttack()
  elseif phase == tekura6.PHASES.BREAK_UPPER then
    attack = tekura6.dispatch.buildBreakUpperAttack()
  elseif phase == tekura6.PHASES.BREAK_LOWER then
    attack = tekura6.dispatch.buildBreakLowerAttack()
  elseif phase == tekura6.PHASES.KILL then
    attack = tekura6.dispatch.buildKillAttack()
  else
    attack = tekura6.dispatch.buildPrepAttack()
  end

  -- Parse combo for parry detection (reuse existing tekura.parry system)
  if tekura and tekura.parry and tekura.parry.parseCombo then
    tekura.parry.parseCombo(attack)
  end

  -- Construct full command
  if phase == tekura6.PHASES.KILL then
    cmd = cmd .. attack
  else
    cmd = cmd .. "unwield all;dismount;" .. attack
  end

  -- Queue command
  send("queue addclear free " .. cmd)

  -- Update state
  tekura6.state.lastAttackTime = os.time()
end

--------------------------------------------------------------------------------
-- STATUS DISPLAY
--------------------------------------------------------------------------------

function tekura6.dispatch.status()
  tAffs = tAffs or {}
  ataxiaTemp = ataxiaTemp or {}

  local phase = tekura6.dispatch.getPhase()
  local phaseName = tekura6.dispatch.getPhaseName(phase)

  -- Progress bar helper
  local function progressBar(pct, width)
    width = width or 15
    local filled = math.floor((pct / 100) * width)
    if filled > width then filled = width end
    if filled < 0 then filled = 0 end
    return string.rep("#", filled) .. string.rep("-", width - filled)
  end

  -- Prep status helper (dynamic threshold)
  local prepThresh = tekura6.getPrepThreshold()
  local function prepStatus(pct)
    if pct >= 100 then
      return "<green>BROKEN "
    elseif pct >= prepThresh then
      return "<yellow>PREPPED"
    else
      return "<red>       "
    end
  end

  cecho("\n<yellow>+================================================+")
  cecho("\n<yellow>|       <white>TEKURA 6-LIMB BACKBREAKER DISPATCH<yellow>       |")
  cecho("\n<yellow>+================================================+")
  cecho("\n<yellow>| <white>Target: <cyan>" .. string.format("%-16s", tostring(target or "None")))
  cecho("<white>Phase: <green>" .. phaseName)
  cecho("\n<yellow>+------------------------------------------------+")
  cecho("\n<yellow>| <white>Kick: <cyan>" .. string.format("%.1f%%", tekura6.state.kickDamage))
  cecho("  <white>Punch: <cyan>" .. string.format("%.1f%%", tekura6.state.punchDamage))
  cecho("  <white>Prep@: <cyan>" .. string.format("%.1f%%", prepThresh))
  cecho("\n<yellow>+------------------------------------------------+")
  cecho("\n<yellow>| <white>LIMB STATUS (prepped = 1 punch from break):<yellow>")

  for _, name in ipairs(tekura6.ALL_LIMBS) do
    local dmg = tekura6.getLimbDamage(name)
    local label = string.format("%-10s", name:sub(1, 1):upper() .. name:sub(2))
    cecho("\n<yellow>|   <white>" .. label .. " " .. prepStatus(dmg)
      .. string.format("%5.1f%%", dmg) .. "<reset> [<cyan>"
      .. progressBar(dmg) .. "<reset>]")
  end

  cecho("\n<yellow>+------------------------------------------------+")
  cecho("\n<yellow>| <white>CONDITIONS:<yellow>")
  cecho("\n<yellow>|   <white>Prone: " .. (tAffs.prone and "<green>YES" or "<red>NO"))
  cecho("      <white>Parried: <cyan>" .. (ataxiaTemp.parriedLimb or "none"))
  cecho("\n<yellow>|   <white>Mounted: " .. (tekura6.isMounted() and "<red>YES" or "<green>NO"))
  cecho("    <white>Shield: " .. (tekura6.checkShield() and "<red>YES" or "<green>NO"))
  cecho("\n<yellow>+------------------------------------------------+")
  cecho("\n<yellow>| <white>ALL 6 PREPPED: " .. (tekura6.checkAllSixPrepped() and "<green>YES" or "<red>NO"))
  local unprepped = tekura6.getUnpreppedLimbs()
  if #unprepped > 0 then
    cecho("  <white>Remaining: <cyan>" .. #unprepped)
  end
  cecho("\n<yellow>+------------------------------------------------+")
  cecho("\n<yellow>| <white>STRATEGY:<yellow>")
  cecho("\n<yellow>|   " .. (phase == 1 and "<white>" or "<grey>") .. "1. PREP: All 6 limbs to 86%+ (kick+punch+punch)")
  cecho("\n<yellow>|   " .. (phase == 2 and "<white>" or "<grey>") .. "2. BREAK UPPER: MNK arm + SPP arm + HKP torso -> HRS")
  cecho("\n<yellow>|   " .. (phase == 3 and "<white>" or "<grey>") .. "3. BREAK LOWER: WRT torso + HFP left + HFP right -> BRS")
  cecho("\n<yellow>|   " .. (phase == 4 and "<green>" or "<grey>") .. "4. KILL: BBT until dead (Bear Stance)")
  cecho("\n<yellow>+================================================+\n")
end

--------------------------------------------------------------------------------
-- ALIAS FUNCTIONS
--------------------------------------------------------------------------------

function tk6()
  tekura6.dispatch.run()
end

function tk6status()
  tekura6.dispatch.status()
end

function tk6reset()
  tekura6.state.lastAttackTime = 0
  if tekura and tekura.parry and tekura.parry.clear then
    tekura.parry.clear()
  end
  cecho("\n<yellow>[TK6] State reset (parry tracking cleared)<reset>")
end

function tk6debug()
  tekura6.config.debugEcho = not tekura6.config.debugEcho
  cecho("\n<yellow>[TK6] Debug: " .. (tekura6.config.debugEcho and "<green>ON" or "<red>OFF") .. "<reset>")
end

-- Set target and clear parry
function tk6tar(newTarget)
  if newTarget and newTarget ~= "" then
    target = newTarget
    if tekura and tekura.parry and tekura.parry.clear then
      tekura.parry.clear()
    end
    cecho("\n<yellow>[TK6] Target set to: <cyan>" .. target .. "<reset>")
  end
end
