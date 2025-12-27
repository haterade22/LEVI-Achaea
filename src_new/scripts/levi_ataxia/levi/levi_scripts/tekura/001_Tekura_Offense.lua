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

-- Helper: Get limb damage from lb[target].hits
function tekura.dispatch.getLimbDamage(limb)
  if not target or target == "" then return 0 end
  lb = lb or {}
  if not lb[target] then return 0 end
  if not lb[target].hits then return 0 end
  return lb[target].hits[limb] or 0
end

-- Check if torso is prepped (one punch away from breaking)
function tekura.dispatch.checkTorsoPrepped()
  local hfpDamage = 14
  local torsoDmg = tekura.dispatch.getLimbDamage("torso")
  return torsoDmg + hfpDamage >= tekura.config.breakThreshold and torsoDmg < tekura.config.breakThreshold
end

-- Check if torso is broken
function tekura.dispatch.checkTorsoBroken()
  tAffs = tAffs or {}
  local torsoDmg = tekura.dispatch.getLimbDamage("torso")
  return torsoDmg >= tekura.config.breakThreshold or tAffs.damagedtorso
end

-- Check if a specific leg is prepped (one punch away from breaking)
function tekura.dispatch.checkLegPrepped(leg)
  local hfpDamage = 14
  local limbName = leg .. " leg"
  local legDmg = tekura.dispatch.getLimbDamage(limbName)
  return legDmg + hfpDamage >= tekura.config.breakThreshold and legDmg < tekura.config.breakThreshold
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
  tAffs = tAffs or {}
  ataxiaTemp = ataxiaTemp or {}

  local parried = ataxiaTemp.parriedLimb or "none"

  -- If target is prone or paralyzed, parry doesn't matter
  if tAffs.prone or tAffs.paralysis then
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
function tekura.dispatch.buildTorsoPrepAttack()
  local parried = tekura.dispatch.getParried()

  -- If they're parrying torso, prep legs instead
  if parried == "torso" then
    -- Use SWK to bypass any leg parry, then HFP both legs
    return "combo " .. target .. " swk hfp left hfp right"
  end

  -- If they're parrying a leg, use SWK to bypass and still prep legs
  if parried == "left leg" or parried == "right leg" then
    -- SWK bypasses parry (kick balance only), then punches hit unparried legs
    return "combo " .. target .. " swk hfp left hfp right"
  end

  -- Normal torso prep: SDK (sidekick) = 25% to torso, HKP (hook punch) = 14% each
  return "combo " .. target .. " sdk hkp hkp"
end

-- PHASE 2: Leg Prep - SNK HFP HFP (or handle parry)
function tekura.dispatch.buildLegPrepAttack()
  local parried = tekura.dispatch.getParried()
  local focus = tekura.dispatch.getFocusLeg()
  local other = tekura.dispatch.getOtherLeg(focus)

  -- If parrying a leg, use SWK instead - only uses kick balance, still get 2 punches
  if parried == "left leg" or parried == "right leg" then
    -- SWK (sweep) uses kick balance, then HFP both legs with punches
    return "combo " .. target .. " swk hfp left hfp right"
  end

  -- If parrying torso, legs are open - prep them normally
  -- (torso parry doesn't affect leg attacks)

  -- Normal leg prep: SNK + HFP + HFP on focus leg, some on other to balance
  return "combo " .. target .. " snk " .. focus .. " hfp " .. focus .. " hfp " .. other
end

-- PHASE 3: Torso Break - SDK HKP HKP;HRS (break torso, switch to Horse)
function tekura.dispatch.buildTorsoBreakAttack()
  local parried = tekura.dispatch.getParried()

  -- If they're parrying torso, attack legs to force parry switch
  if parried == "torso" then
    -- SWK + HFP + HFP on legs - forces them to consider parrying legs
    return "combo " .. target .. " swk hfp left hfp right"
  end

  -- If parrying legs, they've switched - break torso now!
  if parried == "left leg" or parried == "right leg" then
    -- They switched to leg parry, hit torso and switch to Horse
    return "combo " .. target .. " sdk hkp hkp;hrs"
  end

  -- Normal torso break: SDK combo then switch to Horse stance for WRT
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

  -- Get parry status
  local parried = tekura.dispatch.getParried()

  -- Get limb damage from lb[target].hits
  local torsoDmg = tekura.dispatch.getLimbDamage("torso")
  local llDmg = tekura.dispatch.getLimbDamage("left leg")
  local rlDmg = tekura.dispatch.getLimbDamage("right leg")

  -- Debug output
  cecho("\n<yellow>[TKD " .. phaseName .. "]<reset> ")
  cecho("T:<cyan>" .. string.format("%.0f", torsoDmg) .. "%<reset> ")
  cecho("LL:<cyan>" .. string.format("%.0f", llDmg) .. "%<reset> ")
  cecho("RL:<cyan>" .. string.format("%.0f", rlDmg) .. "%<reset> ")
  cecho("Prone:<" .. (tAffs.prone and "green>YES" or "red>NO") .. "<reset>")
  if parried ~= "none" then
    cecho(" <red>PARRY:" .. parried .. "<reset>")
  end

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

  -- Parse combo to track attack queue for parry detection
  tekura.parry.parseCombo(attack)

  -- Construct full command
  cmd = cmd .. "unwield all;dismount;" .. attack

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
  tAffs = tAffs or {}
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
tekura.parry.triggers = {}       -- Store trigger IDs for cleanup

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

-- Kill all registered triggers
function tekura.parry.killTriggers()
  for name, id in pairs(tekura.parry.triggers) do
    if id then killTrigger(id) end
  end
  tekura.parry.triggers = {}
end

-- Register triggers (call once on load)
function tekura.parry.registerTriggers()
  tekura.parry.killTriggers()

  -- ATTACK MESSAGES (fire onAttack to pop from queue)

  -- Snap kick: "You let fly at X with a snap kick."
  tekura.parry.triggers.snk = tempRegexTrigger(
    "^You let fly at .+ with a snap kick\\.$",
    function() tekura.parry.onAttack() end
  )

  -- Side kick: "You pump out at X with a powerful side kick."
  tekura.parry.triggers.sdk = tempRegexTrigger(
    "^You pump out at .+ with a powerful side kick\\.$",
    function() tekura.parry.onAttack() end
  )

  -- Hammerfist: "You ball up one fist and hammerfist X."
  tekura.parry.triggers.hfp = tempRegexTrigger(
    "^You ball up one fist and hammerfist .+\\.$",
    function() tekura.parry.onAttack() end
  )

  -- Hook: "You unleash a powerful hook towards X."
  tekura.parry.triggers.hkp = tempRegexTrigger(
    "^You unleash a powerful hook towards .+\\.$",
    function() tekura.parry.onAttack() end
  )

  -- Sweep: "You lash out at X with a vicious sweep."
  tekura.parry.triggers.swk = tempRegexTrigger(
    "^You lash out at .+ with a vicious sweep\\.$",
    function() tekura.parry.onAttack() end
  )

  -- Roundhouse: "You twist your torso and send a roundhouse towards X."
  tekura.parry.triggers.rhk = tempRegexTrigger(
    "^You twist your torso and send a roundhouse towards .+\\.$",
    function() tekura.parry.onAttack() end
  )

  -- Wrench: "You wrench X's arm|torso|head|leg viciously."
  tekura.parry.triggers.wrt = tempRegexTrigger(
    "^You wrench .+'s (left arm|right arm|torso|head|left leg|right leg) viciously\\.$",
    function() tekura.parry.onAttack() end
  )

  -- Jab punch: "You jab at X's arms."
  tekura.parry.triggers.jbp = tempRegexTrigger(
    "^You jab at .+'s arms\\.$",
    function() tekura.parry.onAttack() end
  )

  -- Axe kick: "You raise your leg high and bring it down on X."
  tekura.parry.triggers.axk = tempRegexTrigger(
    "^You raise your leg high and bring it down on .+\\.$",
    function() tekura.parry.onAttack() end
  )

  -- Palm strike: "You throw your force behind a forward palmstrike at X's face."
  tekura.parry.triggers.pmp = tempRegexTrigger(
    "^You throw your force behind a forward palmstrike at .+'s face\\.$",
    function() tekura.parry.onAttack() end
  )

  -- Moon kick: "You hurl yourself towards X with a lightning-fast moon kick."
  tekura.parry.triggers.mnk = tempRegexTrigger(
    "^You hurl yourself towards .+ with a lightning-fast moon kick\\.$",
    function() tekura.parry.onAttack() end
  )

  -- Spear punch: "You form a spear hand and stab out towards X."
  tekura.parry.triggers.spp = tempRegexTrigger(
    "^You form a spear hand and stab out towards .+\\.$",
    function() tekura.parry.onAttack() end
  )

  -- Uppercut (UCP): "You launch a powerful uppercut at X."
  tekura.parry.triggers.ucp = tempRegexTrigger(
    "^You launch a powerful uppercut at .+\\.$",
    function() tekura.parry.onAttack() end
  )

  -- Whirlwind kick (WWK): "You spin into the air and throw a whirlwind kick towards X."
  tekura.parry.triggers.wwk = tempRegexTrigger(
    "^You spin into the air and throw a whirlwind kick towards .+\\.$",
    function() tekura.parry.onAttack() end
  )

  -- Bladehand: "You whip your hand in a vicious bladehand at the neck of X."
  tekura.parry.triggers.blp = tempRegexTrigger(
    "^You whip your hand in a vicious bladehand at the neck of .+\\.$",
    function() tekura.parry.onAttack() end
  )

  -- Backbreaker: "You grab X and haul them over your knee."
  tekura.parry.triggers.bbt = tempRegexTrigger(
    "^You grab .+ and haul them over your knee\\.$",
    function() tekura.parry.onAttack() end
  )

  -- PARRY MESSAGE
  tekura.parry.triggers.parry = tempRegexTrigger(
    "^\\w+ parries the attack with a deft manoeuvre\\.$",
    function() tekura.parry.onParry() end
  )

  -- DAMAGE MESSAGE (attack hit - clear pending)
  tekura.parry.triggers.damage = tempRegexTrigger(
    "damage to .+'s (left leg|right leg|left arm|right arm|head|torso)",
    function()
      local limb = matches[2]
      tekura.parry.onHit(limb)
    end
  )

  -- Also clear pending on combo-specific damage messages
  tekura.parry.triggers.damage2 = tempRegexTrigger(
    "(left leg|right leg|left arm|right arm|head|torso) has taken",
    function()
      local limb = matches[2]
      tekura.parry.onHit(limb)
    end
  )

  cecho("\n<yellow>[TKD] Parry tracking triggers registered<reset>")
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
