-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi Scripts > Leviticus > MONK > TEKURA DISPATCH
-- Tekura Backbreaker Dispatch System
-- Kill Route: Torso Prep -> Leg Prep -> Break Torso (HRS) -> WRT Double Break (BRS) -> BBT
-- Alternative: SCYTHE kill via Telepathy

--------------------------------------------------------------------------------
-- NAMESPACE & STATE
--------------------------------------------------------------------------------

tekura = tekura or {}
tekura.dispatch = tekura.dispatch or {}

tekura.state = {
  preferScythe = false,
  lastAttackTime = 0,
}

tekura.config = {
  -- "Prepped" means one punch (HFP = 14%) away from breaking
  prepThreshold = 86,  -- 86 + 14 = 100
  breakThreshold = 100,
}

tekura.PHASES = {
  TORSO_PREP = 1,      -- SDK HFP HFP to prep torso
  LEG_PREP = 2,        -- SNK HFP HFP to prep legs (handle parry)
  TORSO_BREAK = 3,     -- Break torso when all prepped, switch to HRS
  DOUBLE_BREAK = 4,    -- WRT arm + HFP legs, prones + breaks legs, switch to BRS
  KILL = 5,            -- BBT until dead (in Bear stance)
  SCYTHE = 6,          -- Alternative: Telepathy kill
}

tekura.PHASE_NAMES = {
  [1] = "TORSO PREP",
  [2] = "LEG PREP",
  [3] = "TORSO BREAK",
  [4] = "DOUBLE BREAK",
  [5] = "*** KILL ***",
  [6] = "*** SCYTHE ***",
}

--------------------------------------------------------------------------------
-- CONDITION CHECK FUNCTIONS
--------------------------------------------------------------------------------

-- Check if torso is prepped (one punch away from breaking)
function tekura.dispatch.checkTorsoPrepped()
  tLimbs = tLimbs or {H = 0, T = 0, LL = 0, RL = 0, LA = 0, RA = 0}
  local hfpDamage = 14
  return tLimbs.T + hfpDamage >= tekura.config.breakThreshold and tLimbs.T < tekura.config.breakThreshold
end

-- Check if torso is broken
function tekura.dispatch.checkTorsoBroken()
  tLimbs = tLimbs or {H = 0, T = 0, LL = 0, RL = 0, LA = 0, RA = 0}
  tAffs = tAffs or {}
  return tLimbs.T >= tekura.config.breakThreshold or tAffs.damagedtorso
end

-- Check if a specific leg is prepped (one punch away from breaking)
function tekura.dispatch.checkLegPrepped(leg)
  tLimbs = tLimbs or {H = 0, T = 0, LL = 0, RL = 0, LA = 0, RA = 0}
  local hfpDamage = 14
  local limbKey = leg == "left" and "LL" or "RL"
  return tLimbs[limbKey] + hfpDamage >= tekura.config.breakThreshold and tLimbs[limbKey] < tekura.config.breakThreshold
end

-- Check if both legs are prepped
function tekura.dispatch.checkBothLegsPrepped()
  return tekura.dispatch.checkLegPrepped("left") and tekura.dispatch.checkLegPrepped("right")
end

-- Check if both legs are broken
function tekura.dispatch.checkBothLegsBroken()
  tLimbs = tLimbs or {H = 0, T = 0, LL = 0, RL = 0, LA = 0, RA = 0}
  return tLimbs.LL >= tekura.config.breakThreshold and tLimbs.RL >= tekura.config.breakThreshold
end

-- Check if ALL are prepped (torso + both legs)
function tekura.dispatch.checkAllPrepped()
  return tekura.dispatch.checkTorsoPrepped()
     and tekura.dispatch.checkBothLegsPrepped()
end

-- Check if SCYTHE kill route is ready
function tekura.dispatch.checkScytheReady()
  tAffs = tAffs or {}
  local hasBattered = battered or false
  local hasDamagedHead = tAffs.damagedhead or false
  local isProne = tAffs.prone or false
  return hasBattered and hasDamagedHead and isProne
end

-- Check if target has shield
function tekura.dispatch.checkShield()
  tAffs = tAffs or {}
  return tAffs.shield or false
end

-- Check if target is parrying legs
function tekura.dispatch.checkParryingLegs()
  ataxiaTemp = ataxiaTemp or {}
  local parried = ataxiaTemp.parriedLimb or "none"
  return parried == "left leg" or parried == "right leg"
end

-- Get parried limb
function tekura.dispatch.getParried()
  ataxiaTemp = ataxiaTemp or {}
  return ataxiaTemp.parriedLimb or "none"
end

--------------------------------------------------------------------------------
-- PHASE DETECTION
--------------------------------------------------------------------------------

function tekura.dispatch.getPhase()
  tAffs = tAffs or {}
  tLimbs = tLimbs or {H = 0, T = 0, LL = 0, RL = 0, LA = 0, RA = 0}

  -- SCYTHE: Alternative kill (if enabled and ready)
  if tekura.state.preferScythe and tekura.dispatch.checkScytheReady() then
    return tekura.PHASES.SCYTHE
  end

  -- KILL: Both legs broken AND prone AND torso broken
  if tekura.dispatch.checkBothLegsBroken() and tAffs.prone then
    return tekura.PHASES.KILL
  end

  -- DOUBLE_BREAK: Torso is broken, both legs prepped, in Horse stance
  -- WRT arm will prone AND break legs
  if tekura.dispatch.checkTorsoBroken() and tekura.dispatch.checkBothLegsPrepped() then
    return tekura.PHASES.DOUBLE_BREAK
  end

  -- TORSO_BREAK: ALL are prepped (torso + both legs), break torso and go to Horse
  if tekura.dispatch.checkAllPrepped() then
    return tekura.PHASES.TORSO_BREAK
  end

  -- LEG_PREP: Torso is prepped but legs need prep
  if tekura.dispatch.checkTorsoPrepped() and not tekura.dispatch.checkBothLegsPrepped() then
    return tekura.PHASES.LEG_PREP
  end

  -- TORSO_PREP: Default - prep torso first
  return tekura.PHASES.TORSO_PREP
end

function tekura.dispatch.getPhaseName(phase)
  return tekura.PHASE_NAMES[phase] or "UNKNOWN"
end

--------------------------------------------------------------------------------
-- TARGETING FUNCTIONS
--------------------------------------------------------------------------------

-- Get focus leg (lower damage, avoid parry)
function tekura.dispatch.getFocusLeg()
  tLimbs = tLimbs or {H = 0, T = 0, LL = 0, RL = 0, LA = 0, RA = 0}
  tAffs = tAffs or {}
  ataxiaTemp = ataxiaTemp or {}

  local parried = ataxiaTemp.parriedLimb or "none"

  -- If target is prone or paralyzed, parry doesn't matter
  if tAffs.prone or tAffs.paralysis then
    parried = "none"
  end

  -- Focus the leg with LESS damage (to balance prep)
  local focusLeft = tLimbs.LL <= tLimbs.RL

  -- But if that leg is parried, switch
  if focusLeft and parried == "left leg" then
    return "right"
  elseif not focusLeft and parried == "right leg" then
    return "left"
  end

  return focusLeft and "left" or "right"
end

-- Get other leg
function tekura.dispatch.getOtherLeg(leg)
  return leg == "left" and "right" or "left"
end

-- Get arm to WRT (avoid parried arm)
function tekura.dispatch.getWrtArm()
  ataxiaTemp = ataxiaTemp or {}
  local parried = ataxiaTemp.parriedLimb or "none"

  if parried == "left arm" then
    return "right"
  end
  return "left"
end

--------------------------------------------------------------------------------
-- ATTACK BUILDER FUNCTIONS
--------------------------------------------------------------------------------

-- PHASE 1: Torso Prep - SDK HKP HKP
function tekura.dispatch.buildTorsoPrepAttack()
  -- SDK (sidekick) = 25% to torso, HKP (hook punch) = 14% each to torso
  -- Stance persists (already in Scorpion)
  return "combo " .. target .. " sdk hkp hkp"
end

-- PHASE 2: Leg Prep - SNK HFP HFP (or handle parry)
function tekura.dispatch.buildLegPrepAttack()
  local parried = tekura.dispatch.getParried()
  local focus = tekura.dispatch.getFocusLeg()
  local other = tekura.dispatch.getOtherLeg(focus)

  -- If parrying a leg, use JBP ARM to disable parry temporarily
  if parried == "left leg" or parried == "right leg" then
    -- JBP (jab punch) to ARM disables parrying temporarily
    -- Then SNK on the parried leg since parry is disabled
    local parriedLeg = parried == "left leg" and "left" or "right"
    return "combo " .. target .. " snk " .. parriedLeg .. " hfp " .. parriedLeg .. " jbp arms"
  end

  -- Normal leg prep: SNK + HFP + HFP on focus leg, some on other to balance
  -- Stance persists (already in Scorpion)
  return "combo " .. target .. " snk " .. focus .. " hfp " .. focus .. " hfp " .. other
end

-- PHASE 3: Torso Break - SDK HFP HFP;HRS (break torso, switch to Horse)
function tekura.dispatch.buildTorsoBreakAttack()
  -- Break torso with SDK combo, then switch to Horse stance for WRT
  return "combo " .. target .. " sdk hkp hkp;hrs"
end

-- PHASE 4: Double Break - WRT arm HFP left HFP right;BRS
-- This prones AND breaks both legs, then switches to Bear
function tekura.dispatch.buildDoubleBreakAttack()
  local wrtArm = tekura.dispatch.getWrtArm()

  -- WRT arm throws to ground (prones) + HFP breaks both legs
  -- Then switch to Bear stance for BBT
  return "combo " .. target .. " wrt " .. wrtArm .. " arm hfp left hfp right;brs"
end

-- PHASE 5: Kill - BBT until dead (in Bear stance)
function tekura.dispatch.buildKillAttack()
  -- BBT requires Bear stance for great modifier
  -- NEVER BBT unless in Bear stance
  return "bbt " .. target
end

-- PHASE 6: SCYTHE - Telepathy kill alternative
function tekura.dispatch.buildScytheAttack()
  return "mind scythe " .. target
end

-- Select attack based on current phase
function tekura.dispatch.selectAttack()
  local phase = tekura.dispatch.getPhase()

  if phase == tekura.PHASES.TORSO_PREP then
    return tekura.dispatch.buildTorsoPrepAttack()
  elseif phase == tekura.PHASES.LEG_PREP then
    return tekura.dispatch.buildLegPrepAttack()
  elseif phase == tekura.PHASES.TORSO_BREAK then
    return tekura.dispatch.buildTorsoBreakAttack()
  elseif phase == tekura.PHASES.DOUBLE_BREAK then
    return tekura.dispatch.buildDoubleBreakAttack()
  elseif phase == tekura.PHASES.KILL then
    return tekura.dispatch.buildKillAttack()
  elseif phase == tekura.PHASES.SCYTHE then
    return tekura.dispatch.buildScytheAttack()
  end

  -- Default fallback
  return tekura.dispatch.buildTorsoPrepAttack()
end

--------------------------------------------------------------------------------
-- MAIN DISPATCH FUNCTION
--------------------------------------------------------------------------------

function tekura.dispatch.run()
  -- Initialize global tables if missing
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}
  ataxiaTemp = ataxiaTemp or {}
  tLimbs = tLimbs or {H = 0, T = 0, LL = 0, RL = 0, LA = 0, RA = 0}
  tAffs = tAffs or {}

  -- Safety check for target
  if not target or target == "" then
    cecho("\n<red>[TKD] No target set! Use: tar <name>")
    return
  end

  -- Get current phase
  local phase = tekura.dispatch.getPhase()
  local phaseName = tekura.dispatch.getPhaseName(phase)

  -- Debug output
  cecho("\n<yellow>[TKD " .. phaseName .. "]<reset> ")
  cecho("T:<cyan>" .. string.format("%.0f", tLimbs.T) .. "%<reset> ")
  cecho("LL:<cyan>" .. string.format("%.0f", tLimbs.LL) .. "%<reset> ")
  cecho("RL:<cyan>" .. string.format("%.0f", tLimbs.RL) .. "%<reset> ")
  cecho("Prone:<" .. (tAffs.prone and "green>YES" or "red>NO") .. "<reset>")

  -- Build command with combatQueue prefix
  local cmd = ""
  if combatQueue then
    cmd = combatQueue()
  end

  -- Handle shield (raze with RHK - roundhouse kick)
  if tekura.dispatch.checkShield() then
    cmd = cmd .. "unwield all;dismount;combo " .. target .. " rhk hkp hkp"
    send("queue addclear free " .. cmd)
    cecho("\n<yellow>[TKD] RAZING SHIELD")
    return
  end

  -- Build attack based on phase
  local attack = tekura.dispatch.selectAttack()

  -- Construct full command
  cmd = cmd .. "unwield all;dismount;assess " .. target .. ";" .. attack

  -- Queue command
  send("queue addclear free " .. cmd)

  -- Update state
  tekura.state.lastAttackTime = os.time()
end

--------------------------------------------------------------------------------
-- STATUS DISPLAY FUNCTION
--------------------------------------------------------------------------------

function tekura.dispatch.status()
  -- Initialize if missing
  tLimbs = tLimbs or {H = 0, T = 0, LL = 0, RL = 0, LA = 0, RA = 0}
  tAffs = tAffs or {}
  ataxiaTemp = ataxiaTemp or {}

  local phase = tekura.dispatch.getPhase()
  local phaseName = tekura.dispatch.getPhaseName(phase)
  local hfpDamage = 14

  -- Progress bar helper
  local function progressBar(pct, width)
    width = width or 10
    local filled = math.floor((pct / 100) * width)
    if filled > width then filled = width end
    if filled < 0 then filled = 0 end
    return string.rep("#", filled) .. string.rep("-", width - filled)
  end

  -- Prep status helper (prepped = one HFP away from breaking)
  local function prepStatus(pct)
    if pct >= 100 then
      return "<green>BROKEN "
    elseif pct + hfpDamage >= 100 then
      return "<yellow>PREPPED"
    else
      return "<red>       "
    end
  end

  cecho("\n<yellow>+============================================+")
  cecho("\n<yellow>|       <white>TEKURA BACKBREAKER DISPATCH<yellow>        |")
  cecho("\n<yellow>+============================================+")
  cecho("\n<yellow>| <white>Target: <cyan>" .. string.format("%-16s", tostring(target or "None")))
  cecho("<white>Phase: <green>" .. phaseName)
  cecho("\n<yellow>+--------------------------------------------+")
  cecho("\n<yellow>| <white>LIMB STATUS (prepped = 1 punch from break):<yellow>")
  cecho("\n<yellow>|   <white>Torso: " .. prepStatus(tLimbs.T) .. string.format("%5.1f%%", tLimbs.T) .. "<reset> [<cyan>" .. progressBar(tLimbs.T) .. "<reset>]")
  cecho("\n<yellow>|   <white>L Leg: " .. prepStatus(tLimbs.LL) .. string.format("%5.1f%%", tLimbs.LL) .. "<reset> [<cyan>" .. progressBar(tLimbs.LL) .. "<reset>]")
  cecho("\n<yellow>|   <white>R Leg: " .. prepStatus(tLimbs.RL) .. string.format("%5.1f%%", tLimbs.RL) .. "<reset> [<cyan>" .. progressBar(tLimbs.RL) .. "<reset>]")
  cecho("\n<yellow>|   <white>Head:  " .. prepStatus(tLimbs.H) .. string.format("%5.1f%%", tLimbs.H) .. "<reset> [<magenta>" .. progressBar(tLimbs.H) .. "<reset>] <grey>(SCYTHE)")
  cecho("\n<yellow>+--------------------------------------------+")
  cecho("\n<yellow>| <white>CONDITIONS:<yellow>")
  cecho("\n<yellow>|   <white>Prone: " .. (tAffs.prone and "<green>YES" or "<red>NO"))
  cecho("      <white>Parried: <cyan>" .. (ataxiaTemp.parriedLimb or "none"))
  cecho("\n<yellow>|   <white>All Prepped: " .. (tekura.dispatch.checkAllPrepped() and "<green>YES" or "<red>NO"))
  cecho("  <white>Torso Broken: " .. (tekura.dispatch.checkTorsoBroken() and "<green>YES" or "<red>NO"))
  cecho("\n<yellow>+--------------------------------------------+")
  cecho("\n<yellow>| <white>KILL ROUTES:<yellow>")
  cecho("\n<yellow>|   <white>BBT Ready: " .. (tekura.dispatch.checkBothLegsBroken() and tAffs.prone and "<green>YES" or "<red>NO"))
  cecho("    <white>SCYTHE Ready: " .. (tekura.dispatch.checkScytheReady() and "<magenta>YES" or "<grey>NO"))
  cecho("\n<yellow>|   <white>SCYTHE Mode: " .. (tekura.state.preferScythe and "<magenta>ENABLED" or "<grey>DISABLED"))
  cecho("\n<yellow>+--------------------------------------------+")
  cecho("\n<yellow>| <white>STRATEGY:<yellow>")
  cecho("\n<yellow>|   " .. (phase == 1 and "<white>" or "<grey>") .. "1. TORSO_PREP: SDK HKP HKP")
  cecho("\n<yellow>|   " .. (phase == 2 and "<white>" or "<grey>") .. "2. LEG_PREP: SNK HFP HFP (JBP arms if parry)")
  cecho("\n<yellow>|   " .. (phase == 3 and "<white>" or "<grey>") .. "3. TORSO_BREAK: SDK HKP HKP -> HRS")
  cecho("\n<yellow>|   " .. (phase == 4 and "<white>" or "<grey>") .. "4. DOUBLE_BREAK: WRT arm HFP HFP -> BRS")
  cecho("\n<yellow>|   " .. (phase == 5 and "<green>" or "<grey>") .. "5. KILL: BBT until dead (BRS)")
  cecho("\n<yellow>|   " .. (phase == 6 and "<magenta>" or "<grey>") .. "ALT: SCYTHE if head prepped + battered")
  cecho("\n<yellow>+============================================+\n")
end

--------------------------------------------------------------------------------
-- HELPER & UTILITY FUNCTIONS
--------------------------------------------------------------------------------

-- Toggle SCYTHE mode
function tekura.dispatch.toggleScythe()
  tekura.state.preferScythe = not tekura.state.preferScythe
  cecho("\n<yellow>[TKD] SCYTHE mode: " .. (tekura.state.preferScythe and "<magenta>ENABLED" or "<grey>DISABLED") .. "<reset>")
end

-- Reset state for new target
function tekura.dispatch.reset()
  tekura.state.preferScythe = false
  cecho("\n<yellow>[TKD] State reset<reset>")
end

-- Echo helper
function tekura.dispatch.echo(text)
  cecho("\n<yellow>[TKD]<reset> " .. text)
end

--------------------------------------------------------------------------------
-- ALIAS FUNCTIONS
--------------------------------------------------------------------------------

function tkd()
  tekura.dispatch.run()
end

function tkdstatus()
  tekura.dispatch.status()
end

function tkdreset()
  tekura.dispatch.reset()
end

function tkdscythe()
  tekura.dispatch.toggleScythe()
end
