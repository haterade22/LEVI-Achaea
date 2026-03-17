--[[mudlet
type: script
name: Tekura Offense
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- MONK
- Tekura
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

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
  attackInFlight = false,     -- Anti-desync: true while off-balance (DWC pattern)
  lastTarget = nil,           -- Target-change detection (DWB pattern)
  lastEchoTime = nil,         -- Debounced echo timestamp (DWB pattern)
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
-- AFFLICTION TRACKING HELPERS (V3 compatible)
--------------------------------------------------------------------------------

-- Helper to check if target has an affliction (V3/V2/V1 routing)
function tekura.hasAff(aff)
  -- V3 system (highest priority - probability-based)
  if affConfigV3 and affConfigV3.enabled then
    if haveAffV3 then
      return haveAffV3(aff)
    end
  end
  -- V1 fallback
  if tAffs and tAffs[aff] then
    return true
  end
  return false
end

-- Get affliction probability (V3 only, returns 0-1)
function tekura.getAffProb(aff)
  if affConfigV3 and affConfigV3.enabled and getAffProbabilityV3 then
    return getAffProbabilityV3(aff)
  end
  return tekura.hasAff(aff) and 1.0 or 0
end

-- Check which tracking system is active
function tekura.getTrackingSystem()
  if affConfigV3 and affConfigV3.enabled then return "V3" end
  return "V1"
end

--------------------------------------------------------------------------------
-- SEND ATTACK (centralized: engage + freestand + attackInFlight)
--------------------------------------------------------------------------------

function tekura.sendAttack(cmd)
  if not cmd or cmd == "" then return end

  -- Lock break check (shared system)
  if ataxia_needLockBreak and ataxia_needLockBreak() then
    if ataxia_lockBreak then ataxia_lockBreak() end
    return
  end

  -- Target presence check
  if ataxia and ataxia.playersHere and not table.contains(ataxia.playersHere, target) then
    return
  end

  tekura.state.attackInFlight = true
  send("queue addclear free " .. cmd)
end

--------------------------------------------------------------------------------
-- ECHO DEBOUNCE (DWB pattern: 0.3s guard prevents spam on rapid mashing)
--------------------------------------------------------------------------------

function tekura.shouldEcho()
  local now = getEpoch()
  if not tekura.state.lastEchoTime or (now - tekura.state.lastEchoTime) > 0.3 then
    tekura.state.lastEchoTime = now
    return true
  end
  return false
end

--------------------------------------------------------------------------------
-- WOULD-BREAK GUARD (DWC pattern: prevents accidental breaks during PREP)
--------------------------------------------------------------------------------

-- Check if next combo attack would break a limb prematurely
-- punchDamage = HFP (14%), kickDamage varies by attack (SDK=25, SNK=25)
function tekura.wouldBreakLimb(limb, attackDamage)
  local damage = tekura.dispatch.getLimbDamage(limb)
  if damage <= 0 then return false end
  attackDamage = attackDamage or 14  -- default to HFP punch damage
  return (damage + attackDamage) >= tekura.config.breakThreshold
end

--------------------------------------------------------------------------------
-- CONDITION CHECK FUNCTIONS
--------------------------------------------------------------------------------

-- Helper: Get limb damage from lb[target].hits
function tekura.dispatch.getLimbDamage(limb)
  if not target or target == "" then return 0 end
  lb = lb or {}
  if not lb[target] then return 0 end
  if not lb[target].hits then return 0 end
  return lb[target].hits[limb] or 0
end

-- Check if torso is prepped (one punch away from breaking, or wouldBreak)
function tekura.dispatch.checkTorsoPrepped()
  local torsoDmg = tekura.dispatch.getLimbDamage("torso")
  if torsoDmg >= tekura.config.prepThreshold and torsoDmg < tekura.config.breakThreshold then
    return true
  end
  -- Treat near-break limbs as prepped to prevent accidental breaks during PREP
  return tekura.wouldBreakLimb("torso", 14)
end

-- Check if torso is broken
function tekura.dispatch.checkTorsoBroken()
  local torsoDmg = tekura.dispatch.getLimbDamage("torso")
  return torsoDmg >= tekura.config.breakThreshold or tekura.hasAff("damagedtorso")
end

-- Check if a specific leg is prepped (one punch away from breaking, or wouldBreak)
function tekura.dispatch.checkLegPrepped(leg)
  local limbName = leg .. " leg"
  local legDmg = tekura.dispatch.getLimbDamage(limbName)
  if legDmg >= tekura.config.prepThreshold and legDmg < tekura.config.breakThreshold then
    return true
  end
  -- Treat near-break limbs as prepped to prevent accidental breaks during PREP
  return tekura.wouldBreakLimb(limbName, 14)
end

-- Check if both legs are prepped
function tekura.dispatch.checkBothLegsPrepped()
  return tekura.dispatch.checkLegPrepped("left") and tekura.dispatch.checkLegPrepped("right")
end

-- Check if both legs are broken
function tekura.dispatch.checkBothLegsBroken()
  local llDmg = tekura.dispatch.getLimbDamage("left leg")
  local rlDmg = tekura.dispatch.getLimbDamage("right leg")
  return llDmg >= tekura.config.breakThreshold and rlDmg >= tekura.config.breakThreshold
end

-- Check if ALL are prepped (torso + both legs)
function tekura.dispatch.checkAllPrepped()
  return tekura.dispatch.checkTorsoPrepped()
     and tekura.dispatch.checkBothLegsPrepped()
end

-- Check if SCYTHE kill route is ready
function tekura.dispatch.checkScytheReady()
  local hasBattered = battered or false
  local hasDamagedHead = tekura.hasAff("damagedhead")
  local isProne = tekura.hasAff("prone")
  return hasBattered and hasDamagedHead and isProne
end

-- Check if target has shield (V1 fallback for GMCP timing gap)
function tekura.dispatch.checkShield()
  return tekura.hasAff("shield") or (tAffs and tAffs.shield) or false
end

-- Check if target has rebounding (V1 fallback for GMCP timing gap)
function tekura.dispatch.checkRebounding()
  return tekura.hasAff("rebounding") or (tAffs and tAffs.rebounding) or false
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

-- Check if parrying head (for SCYTHE route)
function tekura.dispatch.checkParryingHead()
  ataxiaTemp = ataxiaTemp or {}
  return ataxiaTemp.parriedLimb == "head"
end

-- Check if parrying torso
function tekura.dispatch.checkParryingTorso()
  ataxiaTemp = ataxiaTemp or {}
  return ataxiaTemp.parriedLimb == "torso"
end

-- Check if parrying any arm
function tekura.dispatch.checkParryingArms()
  ataxiaTemp = ataxiaTemp or {}
  local parried = ataxiaTemp.parriedLimb or "none"
  return parried == "left arm" or parried == "right arm"
end

--------------------------------------------------------------------------------
-- PHASE DETECTION
--------------------------------------------------------------------------------

-- Check if we're in Bear stance (set after DOUBLE_BREAK via ;brs)
function tekura.isInBearStance()
  return ataxia and ataxia.vitals and ataxia.vitals.stance == "Bear"
end

function tekura.dispatch.getPhase()
  -- SCYTHE: Alternative kill (if enabled and ready)
  if tekura.state.preferScythe and tekura.dispatch.checkScytheReady() then
    return tekura.PHASES.SCYTHE
  end

  -- KILL: In Bear stance AND target is prone → BBT
  -- Bear stance means we already completed break phases
  if tekura.isInBearStance() and tekura.hasAff("prone") then
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
  ataxiaTemp = ataxiaTemp or {}

  local parried = ataxiaTemp.parriedLimb or "none"

  -- If target is prone or paralyzed, parry doesn't matter
  if tekura.hasAff("prone") or tekura.hasAff("paralysis") then
    parried = "none"
  end

  -- Get leg damage from lb[target].hits
  local llDmg = tekura.dispatch.getLimbDamage("left leg")
  local rlDmg = tekura.dispatch.getLimbDamage("right leg")

  -- Focus the leg with LESS damage (to balance prep)
  local focusLeft = llDmg <= rlDmg

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
  elseif parried == "right arm" then
    return "left"
  end
  return "left"  -- default to left arm
end

--------------------------------------------------------------------------------
-- ATTACK BUILDER FUNCTIONS
--------------------------------------------------------------------------------

-- PHASE 1: Torso Prep - SDK HKP HKP (or handle parry)
-- Break guard: simulated damage prevents accidental breaks within a single combo
function tekura.dispatch.buildTorsoPrepAttack()
  local parried = tekura.dispatch.getParried()
  local breakAt = tekura.config.breakThreshold

  -- If they're parrying torso or a leg, prep legs with SWK + break-guarded punches
  if parried == "torso" or parried == "left leg" or parried == "right leg" then
    local p1 = tekura.wouldBreakLimb("left leg", 14) and "jbp" or "hfp left"
    local p2 = tekura.wouldBreakLimb("right leg", 14) and "jbp" or "hfp right"
    return "combo " .. target .. " swk " .. p1 .. " " .. p2
  end

  -- Normal torso prep with simulated damage guard
  local sim = tekura.dispatch.getLimbDamage("torso")

  -- SDK (25% to torso)
  local kickStr
  if (sim + 25) < breakAt then
    kickStr = "sdk"
    sim = sim + 25
  else
    kickStr = "rhk"
  end

  -- HKP punch 1 (14% to torso)
  local p1Str
  if (sim + 14) < breakAt then
    p1Str = "hkp"
    sim = sim + 14
  else
    p1Str = "jbp"
  end

  -- HKP punch 2 (14% to torso)
  local p2Str
  if (sim + 14) < breakAt then
    p2Str = "hkp"
  else
    p2Str = "jbp"
  end

  return "combo " .. target .. " " .. kickStr .. " " .. p1Str .. " " .. p2Str
end

-- PHASE 2: Leg Prep - SNK HFP HFP (or handle parry)
-- Break guard: simulated damage prevents accidental breaks within a single combo
function tekura.dispatch.buildLegPrepAttack()
  local parried = tekura.dispatch.getParried()
  local focus = tekura.dispatch.getFocusLeg()
  local other = tekura.dispatch.getOtherLeg(focus)
  local focusLimb = focus .. " leg"
  local otherLimb = other .. " leg"
  local breakAt = tekura.config.breakThreshold

  -- If parrying a leg, use SWK with break-guarded punches
  if parried == "left leg" or parried == "right leg" then
    local p1 = tekura.wouldBreakLimb("left leg", 14) and "jbp" or "hfp left"
    local p2 = tekura.wouldBreakLimb("right leg", 14) and "jbp" or "hfp right"
    return "combo " .. target .. " swk " .. p1 .. " " .. p2
  end

  -- Normal leg prep with simulated damage guard
  local simFocus = tekura.dispatch.getLimbDamage(focusLimb)
  local simOther = tekura.dispatch.getLimbDamage(otherLimb)

  -- SNK kick (25% damage) — pick safe target, prefer focus
  local kickStr
  if (simFocus + 25) < breakAt then
    kickStr = "snk " .. focus
    simFocus = simFocus + 25
  elseif (simOther + 25) < breakAt then
    kickStr = "snk " .. other
    simOther = simOther + 25
  else
    kickStr = "rhk"
  end

  -- HFP punch 1 (14% damage) — prefer focus
  local p1Str
  if (simFocus + 14) < breakAt then
    p1Str = "hfp " .. focus
    simFocus = simFocus + 14
  elseif (simOther + 14) < breakAt then
    p1Str = "hfp " .. other
    simOther = simOther + 14
  else
    p1Str = "jbp"
  end

  -- HFP punch 2 (14% damage) — prefer other for balance
  local p2Str
  if (simOther + 14) < breakAt then
    p2Str = "hfp " .. other
  elseif (simFocus + 14) < breakAt then
    p2Str = "hfp " .. focus
  else
    p2Str = "jbp"
  end

  return "combo " .. target .. " " .. kickStr .. " " .. p1Str .. " " .. p2Str
end

-- PHASE 3: Torso Break - SDK HKP HKP;HRS (break torso, switch to Horse)
function tekura.dispatch.buildTorsoBreakAttack()
  local parried = tekura.dispatch.getParried()

  -- If they're parrying torso, sweep to prone (can't parry) then break torso
  if parried == "torso" then
    return "combo " .. target .. " swk hkp hkp;hrs"
  end

  -- Normal / leg parry: break torso and switch to Horse
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
  tAffs = tAffs or {}

  -- Safety check for target
  if not target or target == "" then
    cecho("\n<red>[TKD] No target set! Use: tar <name>")
    return
  end

  -- Aeon check: don't dispatch under aeon (DWB pattern)
  if ataxia.afflictions and ataxia.afflictions.aeon then
    cecho("\n<yellow>[TKD] <red>AEON - skipping dispatch")
    return
  end

  -- Target-change detection: auto-reset on new target (DWB pattern)
  if tekura.state.lastTarget ~= target then
    tekura.parry.clear()
    tekura.state.attackInFlight = false
    tekura.state.lastTarget = target
  end

  -- Get current phase
  local phase = tekura.dispatch.getPhase()
  local phaseName = tekura.dispatch.getPhaseName(phase)

  -- Get parry status
  local parried = tekura.dispatch.getParried()

  -- Debounced echo (0.3s guard prevents spam on rapid mashing)
  if tekura.shouldEcho() then
    local torsoDmg = tekura.dispatch.getLimbDamage("torso")
    local llDmg = tekura.dispatch.getLimbDamage("left leg")
    local rlDmg = tekura.dispatch.getLimbDamage("right leg")

    cecho("\n<yellow>[TKD " .. phaseName .. "]<reset> ")
    cecho("T:<cyan>" .. string.format("%.0f", torsoDmg) .. "%<reset> ")
    cecho("LL:<cyan>" .. string.format("%.0f", llDmg) .. "%<reset> ")
    cecho("RL:<cyan>" .. string.format("%.0f", rlDmg) .. "%<reset> ")
    cecho("Prone:<" .. (tekura.hasAff("prone") and "green>YES" or "red>NO") .. "<reset>")
    if parried ~= "none" then
      cecho(" <red>PARRY:" .. parried .. "<reset>")
    end
  end

  -- Build command with combatQueue prefix
  local cmd = ""
  if combatQueue then
    cmd = combatQueue()
  end

  -- Handle rebounding (raze with RHK - roundhouse kick)
  if tekura.dispatch.checkRebounding() then
    cmd = cmd .. "unwield all;dismount;combo " .. target .. " rhk hkp hkp"
    tekura.sendAttack(cmd)
    if tekura.shouldEcho() then
      cecho("\n<yellow>[TKD] RAZING REBOUNDING")
    end
    return
  end

  -- Handle shield (raze with RHK - roundhouse kick)
  if tekura.dispatch.checkShield() then
    cmd = cmd .. "unwield all;dismount;combo " .. target .. " rhk hkp hkp"
    tekura.sendAttack(cmd)
    if tekura.shouldEcho() then
      cecho("\n<yellow>[TKD] RAZING SHIELD")
    end
    return
  end

  -- Build attack based on phase
  local attack = tekura.dispatch.selectAttack()

  -- Parse combo to track attack queue for parry detection
  tekura.parry.parseCombo(attack)

  -- Construct full command
  cmd = cmd .. "unwield all;dismount;" .. attack

  -- Queue command via centralized send
  tekura.sendAttack(cmd)

  -- Update state
  tekura.state.lastAttackTime = os.time()
end

--------------------------------------------------------------------------------
-- STATUS DISPLAY FUNCTION
--------------------------------------------------------------------------------

function tekura.dispatch.status()
  ataxiaTemp = ataxiaTemp or {}

  local phase = tekura.dispatch.getPhase()
  local phaseName = tekura.dispatch.getPhaseName(phase)
  local hfpDamage = 14

  -- Get limb damage from lb[target].hits
  local torsoDmg = tekura.dispatch.getLimbDamage("torso")
  local llDmg = tekura.dispatch.getLimbDamage("left leg")
  local rlDmg = tekura.dispatch.getLimbDamage("right leg")
  local headDmg = tekura.dispatch.getLimbDamage("head")

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
  cecho("\n<yellow>|   <white>Torso: " .. prepStatus(torsoDmg) .. string.format("%5.1f%%", torsoDmg) .. "<reset> [<cyan>" .. progressBar(torsoDmg) .. "<reset>]")
  cecho("\n<yellow>|   <white>L Leg: " .. prepStatus(llDmg) .. string.format("%5.1f%%", llDmg) .. "<reset> [<cyan>" .. progressBar(llDmg) .. "<reset>]")
  cecho("\n<yellow>|   <white>R Leg: " .. prepStatus(rlDmg) .. string.format("%5.1f%%", rlDmg) .. "<reset> [<cyan>" .. progressBar(rlDmg) .. "<reset>]")
  cecho("\n<yellow>|   <white>Head:  " .. prepStatus(headDmg) .. string.format("%5.1f%%", headDmg) .. "<reset> [<magenta>" .. progressBar(headDmg) .. "<reset>] <grey>(SCYTHE)")
  cecho("\n<yellow>+--------------------------------------------+")
  cecho("\n<yellow>| <white>CONDITIONS:<yellow>")
  cecho("\n<yellow>|   <white>Prone: " .. (tekura.hasAff("prone") and "<green>YES" or "<red>NO"))
  cecho("      <white>Parried: <cyan>" .. (ataxiaTemp.parriedLimb or "none"))
  cecho("\n<yellow>|   <white>All Prepped: " .. (tekura.dispatch.checkAllPrepped() and "<green>YES" or "<red>NO"))
  cecho("  <white>Torso Broken: " .. (tekura.dispatch.checkTorsoBroken() and "<green>YES" or "<red>NO"))
  cecho("\n<yellow>|   <white>Tracking: <cyan>" .. tekura.getTrackingSystem())
  cecho("\n<yellow>+--------------------------------------------+")
  cecho("\n<yellow>| <white>KILL ROUTES:<yellow>")
  cecho("\n<yellow>|   <white>BBT Ready: " .. (tekura.isInBearStance() and tekura.hasAff("prone") and "<green>YES" or "<red>NO"))
  cecho("    <white>SCYTHE Ready: " .. (tekura.dispatch.checkScytheReady() and "<magenta>YES" or "<grey>NO"))
  cecho("\n<yellow>|   <white>SCYTHE Mode: " .. (tekura.state.preferScythe and "<magenta>ENABLED" or "<grey>DISABLED"))
  cecho("\n<yellow>+--------------------------------------------+")
  cecho("\n<yellow>| <white>STRATEGY:<yellow>")
  cecho("\n<yellow>|   " .. (phase == 1 and "<white>" or "<grey>") .. "1. TORSO_PREP: SDK HKP HKP")
  cecho("\n<yellow>|   " .. (phase == 2 and "<white>" or "<grey>") .. "2. LEG_PREP: SNK HFP HFP (SWK if parry)")
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
  tekura.state.attackInFlight = false
  tekura.state.lastTarget = nil
  tekura.parry.clear()
  cecho("\n<yellow>[TKD] State reset (parry tracking cleared)<reset>")
end

-- Set target and clear parry
function tekura.dispatch.setTarget(newTarget)
  if newTarget and newTarget ~= "" then
    target = newTarget
    tekura.parry.clear()
    cecho("\n<yellow>[TKD] Target set to: <cyan>" .. target .. "<reset>")
  end
end

-- Echo helper
function tekura.dispatch.echo(text)
  cecho("\n<yellow>[TKD]<reset> " .. text)
end

--------------------------------------------------------------------------------
-- PARRY TRACKING SYSTEM
--------------------------------------------------------------------------------

tekura.parry = tekura.parry or {}
tekura.parry.attackQueue = {}    -- Queue of limbs we're attacking
tekura.parry.pendingLimb = nil   -- The limb we're currently waiting for result on
tekura.parry.triggers = tekura.parry.triggers or {}  -- Preserve IDs so killTriggers() can clean up old triggers on reload

-- Parse combo to build attack queue (in order!)
function tekura.parry.parseCombo(comboStr)
  tekura.parry.attackQueue = {}
  tekura.parry.pendingLimb = nil

  -- We need to parse in ORDER of appearance in the combo
  -- Pattern: combo target attack1 [limb] attack2 [limb] attack3 [limb]

  -- Find all attack patterns with their positions
  local attacks = {}

  -- SDK (torso kick)
  for pos in string.gmatch(comboStr, "()sdk") do
    table.insert(attacks, {pos = pos, limb = "torso"})
  end

  -- SNK (leg kick) - snk left or snk right
  for pos, leg in string.gmatch(comboStr, "()snk (%w+)") do
    table.insert(attacks, {pos = pos, limb = leg .. " leg"})
  end

  -- HKP (torso punch)
  for pos in string.gmatch(comboStr, "()hkp") do
    table.insert(attacks, {pos = pos, limb = "torso"})
  end

  -- HFP (leg punch) - hfp left or hfp right
  for pos, leg in string.gmatch(comboStr, "()hfp (%w+)") do
    table.insert(attacks, {pos = pos, limb = leg .. " leg"})
  end

  -- SWK (sweep - legs)
  for pos in string.gmatch(comboStr, "()swk") do
    table.insert(attacks, {pos = pos, limb = "legs"})
  end

  -- WRT (wrench arm)
  for pos, arm in string.gmatch(comboStr, "()wrt (%w+) arm") do
    table.insert(attacks, {pos = pos, limb = arm .. " arm"})
  end

  -- WRT (wrench torso for bruised ribs)
  for pos in string.gmatch(comboStr, "()wrt torso") do
    table.insert(attacks, {pos = pos, limb = "torso"})
  end

  -- WRT (wrench head)
  for pos in string.gmatch(comboStr, "()wrt head") do
    table.insert(attacks, {pos = pos, limb = "head"})
  end

  -- RHK (roundhouse - no limb damage, used for shield raze)
  for pos in string.gmatch(comboStr, "()rhk") do
    table.insert(attacks, {pos = pos, limb = "none"})
  end

  -- JBP (jab punch - arms, disables parry)
  for pos in string.gmatch(comboStr, "()jbp") do
    table.insert(attacks, {pos = pos, limb = "arms"})
  end

  -- AXK (axe kick - head, only on prone)
  for pos in string.gmatch(comboStr, "()axk") do
    table.insert(attacks, {pos = pos, limb = "head"})
  end

  -- PMP (palm strike - no limb damage, affliction attack to head)
  for pos in string.gmatch(comboStr, "()pmp") do
    table.insert(attacks, {pos = pos, limb = "none"})
  end

  -- MNK (moon kick - arm) - mnk left or mnk right
  for pos, arm in string.gmatch(comboStr, "()mnk (%w+)") do
    table.insert(attacks, {pos = pos, limb = arm .. " arm"})
  end

  -- SPP (spear punch - arm) - spp left or spp right
  for pos, arm in string.gmatch(comboStr, "()spp (%w+)") do
    table.insert(attacks, {pos = pos, limb = arm .. " arm"})
  end

  -- BBT (backbreaker - body)
  for pos in string.gmatch(comboStr, "()bbt") do
    table.insert(attacks, {pos = pos, limb = "body"})
  end

  -- BLP (bladehand - no limb damage, affliction attack to neck/head)
  for pos in string.gmatch(comboStr, "()blp") do
    table.insert(attacks, {pos = pos, limb = "none"})
  end

  -- UCP (uppercut - head)
  for pos in string.gmatch(comboStr, "()ucp") do
    table.insert(attacks, {pos = pos, limb = "head"})
  end

  -- WWK (whirlwind kick - head)
  for pos in string.gmatch(comboStr, "()wwk") do
    table.insert(attacks, {pos = pos, limb = "head"})
  end

  -- Sort by position in string
  table.sort(attacks, function(a, b) return a.pos < b.pos end)

  -- Build queue in order
  for _, atk in ipairs(attacks) do
    table.insert(tekura.parry.attackQueue, atk.limb)
  end

  -- Debug: show combo string and resulting queue
  if tekura6 and tekura6.config and tekura6.config.debugEcho then
    local queueStr = table.concat(tekura.parry.attackQueue, ", ")
    cecho("\n<yellow>[TKD DBG]<reset> Combo: <cyan>" .. comboStr .. "<reset>")
    cecho("\n<yellow>[TKD DBG]<reset> Queue: <cyan>" .. queueStr .. "<reset>")
  end
end

-- Called when we see an attack message (before we know if hit or parried)
function tekura.parry.onAttack()
  if #tekura.parry.attackQueue > 0 then
    tekura.parry.pendingLimb = table.remove(tekura.parry.attackQueue, 1)
  end
end

-- Called when we see a parry message
function tekura.parry.onParry()
  if tekura.parry.pendingLimb then
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.parriedLimb = tekura.parry.pendingLimb
    cecho("\n<yellow>[TKD] <red>PARRIED: <white>" .. tekura.parry.pendingLimb .. "<reset>")
    tekura.parry.pendingLimb = nil
  end
end

-- Called when attack lands (damage message) - clear pending
function tekura.parry.onHit(limb)
  tekura.parry.pendingLimb = nil
  -- Don't clear parriedLimb here - we want it to persist until next combo
end

-- Clear parry tracking (call on new target)
function tekura.parry.clear()
  tekura.parry.attackQueue = {}
  tekura.parry.pendingLimb = nil
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.parriedLimb = nil
end

-- Legacy temp trigger cleanup (remove any orphaned triggers from previous loads)
function tekura.parry.killTriggers()
  if tekura.parry.triggers then
    for _, id in pairs(tekura.parry.triggers) do
      if id then killTrigger(id) end
    end
  end
  tekura.parry.triggers = {}
end

-- Register triggers is now a no-op: parry tracking uses permanent triggers
-- Attack messages: src_new/triggers/.../kicks/011_Tekura_Parry_Queue_Pop.lua
-- Parry message:   src_new/triggers/.../limb_hits_unorganised/002_Parried.lua
function tekura.parry.registerTriggers()
  -- Kill any leftover temp triggers from before the conversion
  tekura.parry.killTriggers()
  cecho("\n<yellow>[TKD] Parry tracking active (permanent triggers)<reset>")
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

function tkdparry()
  tekura.parry.registerTriggers()
end

function tkdtar(newTarget)
  tekura.dispatch.setTarget(newTarget)
end

function tkdclear()
  tekura.parry.clear()
  cecho("\n<yellow>[TKD] Parry tracking cleared<reset>")
end

-- Auto-register parry triggers on load
tekura.parry.registerTriggers()
