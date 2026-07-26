--[[mudlet
type: script
name: Tekura 6-Limb Offense
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
  attackInFlight = false,     -- Anti-desync: true while off-balance (DWC pattern)
  lastTarget = nil,           -- Target-change detection (DWB pattern)
  lastEchoTime = nil,         -- Debounced echo timestamp (DWB pattern)
  lastKickLimb = nil,         -- Direct parry tracking: stores kick target for parry trigger
}

tekura6.config = {
  breakThreshold = 100,
  debugEcho = true,
  kaiMode = "surge",  -- "surge" (31 kai, 3.2s eq) or "cripple" (41 kai, 4s eq, L1 breaks all)
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
-- AFFLICTION TRACKING HELPERS (V3 compatible)
--------------------------------------------------------------------------------

-- Helper to check if target has an affliction (V3/V2/V1 routing)
function tekura6.hasAff(aff)
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

function tekura6.getAffProb(aff)
  if affConfigV3 and affConfigV3.enabled and getAffProbabilityV3 then
    return getAffProbabilityV3(aff)
  end
  return tekura6.hasAff(aff) and 1.0 or 0
end

function tekura6.getTrackingSystem()
  if affConfigV3 and affConfigV3.enabled then return "V3" end
  return "V1"
end

--------------------------------------------------------------------------------
-- SEND ATTACK (centralized: freestand + attackInFlight)
--------------------------------------------------------------------------------

function tekura6.sendAttack(cmd)
  if not cmd or cmd == "" then return end

  if ataxia_needLockBreak and ataxia_needLockBreak() then
    if ataxia_lockBreak then ataxia_lockBreak() end
    return
  end

  if ataxia and ataxia.playersHere and not table.contains(ataxia.playersHere, target) then
    return
  end

  tekura6.state.attackInFlight = true
  send("queue addclear free " .. cmd)
end

--------------------------------------------------------------------------------
-- ECHO DEBOUNCE (0.3s guard prevents spam on rapid mashing)
--------------------------------------------------------------------------------

function tekura6.shouldEcho()
  local now = getEpoch()
  if not tekura6.state.lastEchoTime or (now - tekura6.state.lastEchoTime) > 0.3 then
    tekura6.state.lastEchoTime = now
    return true
  end
  return false
end

--------------------------------------------------------------------------------
-- WOULD-BREAK GUARD (DWC pattern: prevents accidental breaks during PREP)
--------------------------------------------------------------------------------

function tekura6.wouldBreakLimb(limb, attackDamage)
  local damage = tekura6.getLimbDamage(limb)
  if damage <= 0 then return false end
  attackDamage = attackDamage or tekura6.state.punchDamage
  return (damage + attackDamage) >= tekura6.config.breakThreshold
end

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
  if not amount or type(amount) ~= "number" then return end
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
  if tekura6.hasAff("prone") or tekura6.hasAff("paralysis") then
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

-- Check if target has shield (V1 fallback for GMCP timing gap)
function tekura6.checkShield()
  return tekura6.hasAff("shield") or (tAffs and tAffs.shield) or false
end

-- Check if target has rebounding (V1 fallback for GMCP timing gap)
function tekura6.checkRebounding()
  return tekura6.hasAff("rebounding") or (tAffs and tAffs.rebounding) or false
end

-- Check if target is mounted
function tekura6.isMounted()
  return tmounted or tekura6.hasAff("mounted") or false
end

-- Echo helper with tag
function tekura6.echo(text)
  cecho("\n<yellow>[TK6]<reset> " .. text)
end

--------------------------------------------------------------------------------
-- PHASE DETECTION
--------------------------------------------------------------------------------

-- Check if we're in Bear stance (set after BREAK_LOWER via ;brs)
function tekura6.isInBearStance()
  return ataxia and ataxia.vitals and ataxia.vitals.stance == "Bear"
end

function tekura6.dispatch.getPhase()
  local armsBroken = tekura6.isLimbBroken("left arm") and tekura6.isLimbBroken("right arm")
  local torsoBroken = tekura6.isLimbBroken("torso")
  local bothLegsBroken = tekura6.isLimbBroken("left leg") and tekura6.isLimbBroken("right leg")

  -- KILL: In Bear stance AND target is prone → BBT
  -- Bear stance means we already completed break phases
  if tekura6.isInBearStance() and tekura6.hasAff("prone") then
    return tekura6.PHASES.KILL
  end

  -- BREAK_LOWER: Both arms + torso broken (from BREAK_UPPER), legs NOT yet both broken
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
-- Priority: non-parried unprepped > parried unprepped > non-parried prepped (safe overflow) > parried prepped
-- SPREAD: Kick and punches target different limbs when possible (opponent can only parry 1 of 3)
function tekura6.dispatch.buildPrepAttack()
  -- Use raw parry (not effective parry) during PREP — always avoid the parried limb
  -- regardless of prone/paralysis tracking. Zero cost: we just prep a different limb instead.
  local parried = tekura6.getParried()
  local unprepped = tekura6.getUnpreppedLimbs()
  local kickDmg = tekura6.state.kickDamage
  local punchDmg = tekura6.state.punchDamage
  local breakAt = tekura6.config.breakThreshold

  -- KAI SURGE WINDOW: target can't remount for 15s -- sweep + double-punch the parried limb
  -- Parry bypassed because sweep prones them; use the window to prep the stuck limb.
  ataxiaTemp = ataxiaTemp or {}
  if ataxiaTemp.kaiSurgeWindow and parried ~= "none" then
    return tekura6.dispatch.buildParryBypassAttack(parried)
  end

  -- EDGE CASE: Only 1 unprepped limb and it's parried
  if #unprepped == 1 and unprepped[1] == parried then
    return tekura6.dispatch.buildParryBypassAttack(unprepped[1])
  end

  -- EDGE CASE: No unprepped limbs (shouldn't reach here, phase would be BREAK)
  if #unprepped == 0 then
    return "combo " .. target .. " sdk hkp hkp"
  end

  -- Build TWO candidate lists + simulated damage for ALL non-broken limbs
  local unprepCandidates = {}   -- unprepped limbs (priority targets)
  local overflowCandidates = {} -- prepped-but-not-broken limbs (safe overflow)
  local simDmg = {}
  for _, limb in ipairs(tekura6.ALL_LIMBS) do
    if not tekura6.isLimbBroken(limb) then
      simDmg[limb] = tekura6.getLimbDamage(limb)
      if not tekura6.isLimbPrepped(limb) then
        table.insert(unprepCandidates, limb)
      else
        table.insert(overflowCandidates, limb)
      end
    end
  end

  -- Helper: find the best safe limb for an attack of given damage
  -- Searches preferred list first, then fallback list
  -- Within each list: non-parried first, then parried
  -- skipLimb: optional limb to deprioritize (for attack spread)
  local function findSafeLimb(preferred, fallback, atkDmg, skipLimb)
    -- Sort both lists by simulated damage ascending (lowest first)
    -- Tiebreaker: prefer right limbs when damage is equal (right gets prepped last,
    -- so restoration heals left first and right stays broken longer)
    local function limbSort(a, b)
      local da, db = (simDmg[a] or 0), (simDmg[b] or 0)
      if da == db then
        return a:find("right") and not b:find("right")
      end
      return da < db
    end
    table.sort(preferred, limbSort)
    table.sort(fallback, limbSort)

    -- Pass 1: non-parried, non-skipped preferred (best targets)
    for _, limb in ipairs(preferred) do
      if limb ~= parried and limb ~= skipLimb and (simDmg[limb] or 0) + atkDmg < breakAt then
        return limb
      end
    end
    -- Pass 2: non-parried, skipped preferred (spread failed, same limb is ok)
    if skipLimb then
      for _, limb in ipairs(preferred) do
        if limb ~= parried and limb == skipLimb and (simDmg[limb] or 0) + atkDmg < breakAt then
          return limb
        end
      end
    end
    -- Pass 3: parried preferred (better to waste on parried than break)
    for _, limb in ipairs(preferred) do
      if limb == parried and (simDmg[limb] or 0) + atkDmg < breakAt then
        return limb
      end
    end
    -- Pass 4: non-parried, non-skipped overflow (prepped, safe waste)
    for _, limb in ipairs(fallback) do
      if limb ~= parried and limb ~= skipLimb and (simDmg[limb] or 0) + atkDmg < breakAt then
        return limb
      end
    end
    -- Pass 5: non-parried, skipped overflow
    if skipLimb then
      for _, limb in ipairs(fallback) do
        if limb ~= parried and limb == skipLimb and (simDmg[limb] or 0) + atkDmg < breakAt then
          return limb
        end
      end
    end
    -- Pass 6: parried overflow
    for _, limb in ipairs(fallback) do
      if limb == parried and (simDmg[limb] or 0) + atkDmg < breakAt then
        return limb
      end
    end
    return nil
  end

  -- KICK: Find safe kick target
  local kickStr
  local kickLimb = findSafeLimb(unprepCandidates, overflowCandidates, kickDmg)
  if kickLimb then
    kickStr = tekura6.LIMB_ATTACKS[kickLimb].kick
    simDmg[kickLimb] = (simDmg[kickLimb] or 0) + kickDmg
    tekura6.state.lastKickLimb = kickLimb  -- Direct parry tracking (bypasses queue)
  else
    -- No safe kick target (all limbs would break) — use RHK as filler (no limb damage)
    kickStr = "rhk"
    tekura6.state.lastKickLimb = nil
  end

  -- PUNCHES: Find two safe punch targets, spread across different limbs than kick
  -- skipLimb = kickLimb forces punches to different limbs when alternatives exist
  local punchA, punchB  -- raw targets (nil = filler)

  local punchALimb = findSafeLimb(unprepCandidates, overflowCandidates, punchDmg, kickLimb)
  if punchALimb then
    punchA = tekura6.LIMB_ATTACKS[punchALimb].punch
    simDmg[punchALimb] = (simDmg[punchALimb] or 0) + punchDmg
  end

  -- Second punch also tries to avoid kick limb AND first punch limb for max spread
  local skipForPunchB = kickLimb
  if punchALimb and punchALimb ~= kickLimb then
    -- First punch already spread from kick — try to spread from punch1 too
    skipForPunchB = punchALimb
  end
  local punchBLimb = findSafeLimb(unprepCandidates, overflowCandidates, punchDmg, skipForPunchB)
  if punchBLimb then
    punchB = tekura6.LIMB_ATTACKS[punchBLimb].punch
  end

  -- Order: JBP filler always goes first (disables parry for the following real punch)
  local punch1Str, punch2Str
  if punchA and punchB then
    -- Both real punches — no reorder needed
    punch1Str, punch2Str = punchA, punchB
  elseif punchA and not punchB then
    -- One real, one filler — jbp first, real punch second (benefits from parry disable)
    punch1Str, punch2Str = "jbp", punchA
  elseif not punchA and punchB then
    punch1Str, punch2Str = "jbp", punchB
  else
    -- Both fillers
    punch1Str, punch2Str = "jbp", "jbp"
  end

  return "combo " .. target .. " " .. kickStr .. " " .. punch1Str .. " " .. punch2Str
end

-- PARRY BYPASS: Kai surge (dismount) + sweep (prone) + punch last limb
-- Break guard: if 2 punches would break, use 1 real punch + overflow/filler
function tekura6.dispatch.buildParryBypassAttack(parriedLimb)
  local cmd = ""
  local punchDmg = tekura6.state.punchDamage
  local breakAt = tekura6.config.breakThreshold
  local currentDmg = tekura6.getLimbDamage(parriedLimb)

  -- Kai dismount if mounted (required for sweep)
  if tekura6.isMounted() then
    cmd = "kai " .. tekura6.config.kaiMode .. " " .. target .. ";"
  end

  tekura6.state.lastKickLimb = nil  -- Sweep doesn't target a specific limb

  local punch = tekura6.LIMB_ATTACKS[parriedLimb].punch

  -- Check if TWO punches would break the limb
  if (currentDmg + 2 * punchDmg) >= breakAt then
    -- Only 1 punch on the parried limb; find overflow for 2nd punch
    local overflow = nil
    for _, limb in ipairs(tekura6.ALL_LIMBS) do
      if limb ~= parriedLimb and not tekura6.isLimbBroken(limb)
         and (tekura6.getLimbDamage(limb) + punchDmg) < breakAt then
        overflow = limb
        break
      end
    end

    if overflow then
      -- Sweep prones (no parry), so real punch first, overflow second
      cmd = cmd .. "combo " .. target .. " swk " .. punch .. " " .. tekura6.LIMB_ATTACKS[overflow].punch
    else
      -- No safe overflow — use filler for 2nd punch
      cmd = cmd .. "combo " .. target .. " swk " .. punch .. " jbp"
    end
  else
    -- Safe to double-punch (won't break)
    cmd = cmd .. "combo " .. target .. " swk " .. punch .. " " .. punch
  end

  return cmd
end

-- BREAK_UPPER: Break torso + both arms in Scorpion stance, then switch to Horse
-- SDK (torso kick) + SPP left + SPP right: all 3 upper limbs break in one combo.
-- Stay in Scorpion stance for the combo — hrs fires after to transition.
function tekura6.dispatch.buildBreakUpperAttack()
  tekura6.state.lastKickLimb = "torso"
  return "combo " .. target .. " sdk spp left spp right;hrs"
end

-- BREAK_LOWER: Wrench torso (prones) + break both legs, switch to Bear stance
function tekura6.dispatch.buildBreakLowerAttack()
  -- WRT torso (Horse stance, prones target) + HFP left + HFP right (break both legs)
  tekura6.state.lastKickLimb = "torso"
  return "combo " .. target .. " wrt torso hfp left hfp right;brs"
end

-- KILL: Backbreaker in Bear stance
function tekura6.dispatch.buildKillAttack()
  tekura6.state.lastKickLimb = nil  -- No combo kick
  return "bbt " .. target
end

-- Safe raze punches: during PREP, pick punch targets that won't break any limb
function tekura6.dispatch.safeRazePunches()
  if tekura6.dispatch.getPhase() ~= tekura6.PHASES.PREP then
    return "hkp", "hkp"
  end
  local punchDmg = tekura6.state.punchDamage
  local breakAt = tekura6.config.breakThreshold
  local simDmg = {}
  for _, limb in ipairs(tekura6.ALL_LIMBS) do
    simDmg[limb] = tekura6.getLimbDamage(limb)
  end
  local function safePunch()
    for _, limb in ipairs(tekura6.ALL_LIMBS) do
      if not tekura6.isLimbBroken(limb) and (simDmg[limb] + punchDmg) < breakAt then
        simDmg[limb] = simDmg[limb] + punchDmg
        return tekura6.LIMB_ATTACKS[limb].punch
      end
    end
    return "jbp"
  end
  return safePunch(), safePunch()
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

  -- Aeon check: don't dispatch under aeon (DWB pattern)
  if ataxia.afflictions and ataxia.afflictions.aeon then
    cecho("\n<yellow>[TK6] <red>AEON - skipping dispatch")
    return
  end

  -- Target-change detection: auto-reset on new target (DWB pattern)
  if tekura6.state.lastTarget ~= target then
    if tekura and tekura.parry and tekura.parry.clear then
      tekura.parry.clear()
    end
    tekura6.state.attackInFlight = false
    tekura6.state.lastTarget = target
  end

  -- Get current phase
  local phase = tekura6.dispatch.getPhase()
  local phaseName = tekura6.dispatch.getPhaseName(phase)

  -- Get parry status (raw parry — always show what opponent is parrying)
  local parried = tekura6.getParried()

  -- Debounced echo (0.3s guard prevents spam on rapid mashing)
  if tekura6.config.debugEcho and tekura6.shouldEcho() then
    local h  = tekura6.getLimbDamage("head")
    local t  = tekura6.getLimbDamage("torso")
    local la = tekura6.getLimbDamage("left arm")
    local ra = tekura6.getLimbDamage("right arm")
    local ll = tekura6.getLimbDamage("left leg")
    local rl = tekura6.getLimbDamage("right leg")

    cecho("\n<yellow>[TK6 " .. phaseName .. "]<reset> ")
    cecho("H:<cyan>" .. string.format("%.0f", h) .. "%<reset> ")
    cecho("T:<cyan>" .. string.format("%.0f", t) .. "%<reset> ")
    cecho("LA:<cyan>" .. string.format("%.0f", la) .. "%<reset> ")
    cecho("RA:<cyan>" .. string.format("%.0f", ra) .. "%<reset> ")
    cecho("LL:<cyan>" .. string.format("%.0f", ll) .. "%<reset> ")
    cecho("RL:<cyan>" .. string.format("%.0f", rl) .. "%<reset> ")
    cecho("Prone:<" .. (tekura6.hasAff("prone") and "green>YES" or "red>NO") .. "<reset>")
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

  -- SHIELD CHECK: raze with RHK (break-guarded punches during PREP; monk bypasses rebounding)
  if tekura6.checkShield() then
    local p1, p2 = tekura6.dispatch.safeRazePunches()
    cmd = cmd .. "unwield all;dismount;combo " .. target .. " rhk " .. p1 .. " " .. p2
    tekura6.state.lastKickLimb = nil  -- RHK raze, no limb target
    tekura6.sendAttack(cmd)
    if tekura6.shouldEcho() then
      cecho("\n<yellow>[TK6] RAZING SHIELD")
    end
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

  -- Queue command via centralized send
  tekura6.sendAttack(cmd)

  -- Update state
  tekura6.state.lastAttackTime = os.time()
end

--------------------------------------------------------------------------------
-- STATUS DISPLAY
--------------------------------------------------------------------------------

function tekura6.dispatch.status()
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
  cecho("\n<yellow>|   <white>Prone: " .. (tekura6.hasAff("prone") and "<green>YES" or "<red>NO"))
  cecho("      <white>Parried: <cyan>" .. (ataxiaTemp.parriedLimb or "none"))
  cecho("\n<yellow>|   <white>Mounted: " .. (tekura6.isMounted() and "<red>YES" or "<green>NO"))
  cecho("    <white>Shield: " .. (tekura6.checkShield() and "<red>YES" or "<green>NO"))
  cecho("\n<yellow>|   <white>Tracking: <cyan>" .. tekura6.getTrackingSystem())
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
  tekura6.state.attackInFlight = false
  tekura6.state.lastTarget = nil
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
