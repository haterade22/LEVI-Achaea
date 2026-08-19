--[[mudlet
type: script
name: CC_BM_Ice
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Blademaster
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[mudlet
type: script
name: CC_BM_Ice
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Blademaster
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- Blademaster Dispatch System
-- Three strategies available:
--
-- STRATEGY 1: DOUBLE-PREP (Legs only) - bmd / bmdispatch
--   1. LEG PREP (Lightning): Alternate legslash to get both legs to 90%+
--   2. LEG BREAK (Ice): Double-break legs + KNEES (prone)
--   3. MANGLE (Ice): Legslash right + STERNUM
--
-- STRATEGY 2: QUAD-PREP / ICE PATH (Arms + Legs) - bmdq / bmdispatchquad
--   1. ARM PREP (Lightning): Alternate armslash to get both arms to 90%+
--   2. LEG PREP (Lightning): Alternate legslash to get both legs to 90%+
--   3. FLAMEFIST: Negate rebounding before break sequence
--   4. ARM BREAK (Ice): Double-break both arms
--   5. LEG BREAK (Ice): Double-break legs + KNEES (prone), always RIGHT
--   6. MANGLE (Ice): Legslash RIGHT + STERNUM (always right, curing applies left first)
--
-- STRATEGY 3: BROKENSTAR (Instant Kill) - bmbs / bmdispatchbs
--   1. UPPER PREP (Lightning): Centreslash up/down to get torso+head to 90%+
--      - Direction auto-selected to balance damage (like leg focus)
--      - UP: torso primary (18.1%), head secondary (12.1%)
--      - DOWN: head primary (18.1%), torso secondary (12.1%)
--   2. LEG PREP (Lightning): Legslash to get both legs to 90%+
--   3. UPPER BREAK (Ice): Centreslash up/down to break torso+head
--   4. LEG BREAK (Ice): Double-break legs + KNEES (prone)
--   5. IMPALE: Impale prone target
--   6. IMPALESLASH: Slash arteries for bleeding
--   7. BLADETWIST: Twist until 700 bleeding (discern on 3rd)
--   8. WITHDRAW: Withdraw blade (if impaled) or skip if writhed free
--   9. BROKENSTAR: Execute instant kill
--
-- STRATEGY 4: GROUP (Pommelstrike Lock) - bmgroup
--   Ice infuse + pommelstrike with affliction priority:
--   1. Hamstring > 2. Paralysis > 3. Asthma > 4. Slickness (if asthma)
--   5. Anorexia (if impatience+slickness) > 6. Class lock aff > 7. Hypochondria
--   8. Sternum (damage) when locked

blademaster = blademaster or {}
blademaster.dispatch = blademaster.dispatch or {}
blademaster.state = {
  -- Mode & dispatch state
  mode = "double",            -- "double", "quad", "brokenstar"
  attackInFlight = false,     -- Anti-desync: true while off-balance (DWC pattern)
  lastTarget = nil,           -- Target-change detection (DWB pattern)
  lastEchoTime = nil,         -- Debounced echo timestamp (DWB pattern)
  -- Leg tracking
  focusLeg = nil,
  lastPrimaryLeg = nil,
  legPrimaryDamage = 17.3,
  legSecondaryDamage = 11.5,
  -- Arm tracking
  focusArm = nil,
  lastPrimaryArm = nil,
  armPrimaryDamage = 17.3,
  armSecondaryDamage = 11.5,
  -- Upper body tracking (centreslash up hits torso + head with different damage!)
  torsoDamage = 18.1,  -- Damage to torso from centreslash up (primary)
  headDamage = 12.1,   -- Damage to head from centreslash up (secondary)
  -- Prone timer tracking (Double-Prep mangle phase)
  proneTimerStart = nil,      -- Timestamp when salve detected
  proneAttackCount = 0,       -- Number of attacks since prone started
  proneTimerActive = false,   -- Is the 9-second window active
  -- Brokenstar tracking
  isImpaled = false,          -- Target is currently impaled
  impaleslashDone = false,    -- Impaleslash has been executed
  secondImpale = false,       -- Second impale after impaleslash done
  bleedingReady = false,      -- Bleeding at 700+ (heavy torrents)
  targetBleeding = 0,         -- Actual bleeding value from assess
  withdrawDone = false,       -- Blade withdrawn (ready for brokenstar)
  bladetwistCount = 0,        -- Number of bladetwists since impaleslash
  -- Flamefist tracking (Quad-Prep ice path)
  flamefistDone = false,       -- Flamefist sent this fight (reset on target change)
  -- Prompt retry (v4.7.275) -- see blademaster.retryTick
  autoRetry = true,           -- `bmretry` toggles
  lastManualAt = nil,         -- epoch of the last bmd/bmdq/bmbs/bmgroup keypress
  -- Suppression echo (v4.7.275)
  lastSuppressAt = nil,
  lastSuppressReason = nil,
  -- Other
  lastHamstringTime = 0,
  compassDamage = 14.9,
}

-- Configuration
blademaster.config = {
  breakThreshold = 100,
  prepThreshold = 90,
  killHealthThreshold = 30,
  hamstringDuration = 10,
  proneTimerDuration = 9,     -- Seconds from salve to stand
  balanceslashThreshold = 4,  -- Switch to balanceslash on this attack number
  brokenstarBleedThreshold = 700,  -- Bleeding level for brokenstar execution
  retryWindow = 12,           -- seconds after the last manual press that retryTick keeps swinging
}

--------------------------------------------------------------------------------
-- AFFLICTION TRACKING HELPERS (V3 compatible)
--------------------------------------------------------------------------------

-- Helper to check if target has an affliction (V3 is always on, routes through global haveAff)
function blademaster.hasAff(aff)
  return haveAff(aff)
end

-- Get affliction probability (0.0-1.0).
function blademaster.getAffProb(aff)
  return getAffProbabilityV3 and getAffProbabilityV3(aff) or 0
end

-- Check which tracking system is active
function blademaster.getTrackingSystem()
  return "V3"
end

--------------------------------------------------------------------------------
-- SEND ATTACK (centralized: engage + freestand + attackInFlight)
-- Source: DWC knightSendAttack() + DWB dwbRunie.sendAttack()
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- SUPPRESSION ECHO (v4.7.275)
--
-- Every guard below used to `return` in silence, and the [BM ...] status block prints in
-- runDoublePrep BEFORE the send -- so in the 2026-08-19 Grulk log the screen reported
-- "6 hits to leg double-break" 89 times while only 8 commands reached the server, and the
-- log could not say which guard ate the other 81. Reconstructing it took two passes over
-- 2,819 lines. One line per suppression turns that into a glance.
--
-- Debounced per-REASON, not globally: repeated identical suppressions collapse, but a change
-- of reason still prints immediately, which is the transition worth seeing.
--------------------------------------------------------------------------------
function blademaster.suppressed(reason)
  local now = (getEpoch and getEpoch()) or os.time()
  local st = blademaster.state
  if st.lastSuppressReason == reason and st.lastSuppressAt
     and (now - st.lastSuppressAt) < 1.0 then
    return
  end
  st.lastSuppressAt = now
  st.lastSuppressReason = reason
  cecho("\n<red>[BM]<reset> attack suppressed: <yellow>" .. tostring(reason))
end

function blademaster.sendAttack(cmd)
  if not cmd or cmd == "" then return end

  -- Lock break check (shared system).
  --
  -- v4.7.275: this used to return UNCONDITIONALLY, which produced the 2026-08-19 deadlock.
  -- ataxia_lockBreak() does nothing when ataxia_canActive() is false, and Blademaster's
  -- blocker is WEARINESS -- which the Sentinel kept up for the last 19 seconds of the fight.
  -- So the offense deferred to a lock-break that could not run, the lock-break declined
  -- because of weariness, and we stood still for 86 seconds while he broke our head.
  --
  -- Defer ONLY when the cure can actually go out. When it cannot, swinging is strictly
  -- better than doing nothing at all.
  if ataxia_needLockBreak and ataxia_needLockBreak() then
    if ataxia_lockBreak then ataxia_lockBreak() end
    if ataxia_canActive and ataxia_canActive() then
      blademaster.suppressed("breaking lock (active cure going out)")
      return
    end
    -- fall through and attack: the lock-break is blocked, standing still helps nobody
  end

  -- Target presence check
  if ataxia and ataxia.playersHere and not table.contains(ataxia.playersHere, target) then
    blademaster.suppressed("target '" .. tostring(target) .. "' not in ataxia.playersHere")
    return
  end

  blademaster.state.attackInFlight = true

  -- Engage on first attack (DWC/DWB pattern)
  if not engaged then
    send("queue addclear freestand " .. cmd .. ";engage " .. target)
    engaged = true
  else
    send("queue addclear freestand " .. cmd)
  end
end

--------------------------------------------------------------------------------
-- QUEUE RECALL ON A DEFENCE RAISED MID-SWING (v4.7.275)
--
-- selectAttackDoublePrep / QuadPrep / Brokenstar / Group all decide raze-vs-attack at DISPATCH
-- time. Once `queue addclear freestand <cmd>` is with the server, a defence raised afterwards is
-- eaten -- and `queue addclear` cannot be recalled by the dispatch that made it.
--
-- Both halves of that cost us in the 2026-08-19 Grulk log:
--   * 09:58:07 -- shield went up after we queued; the swing rebounded off it and stunned us.
--   * 09:58:34 -- [REB] printed 830ms before our armslash landed. It reflected for 18.1% into
--     our OWN left arm, which is the hit that broke it: his six throws made 88.2%, not a break,
--     and our 18.1% took it to 106.3% -- a break AND a second restoration.
--
-- `addclear` REPLACES rather than appends, so this is a one-command correction with no new
-- state. Converting can still whiff if the defence drops again before our balance returns (that
-- is the "to no effect" line, twice in the log) -- but a whiffed raze costs only the swing,
-- where eating a rebound costs the swing, 615 damage, and a self-inflicted limb break.
--------------------------------------------------------------------------------
function blademaster.onTargetDefenceUp(def)
  if not blademaster.state.attackInFlight then return end
  if not target or target == "" then return end
  if ataxia_isClass and not ataxia_isClass("blademaster") then return end
  if ataxia and ataxia.playersHere and not table.contains(ataxia.playersHere, target) then return end

  send("queue addclear freestand raze " .. target)
  cecho("\n<cyan>[BM]<reset> " .. tostring(def) .. " raised mid-swing -- pending attack converted to <yellow>RAZE<reset>.")
end

--------------------------------------------------------------------------------
-- ECHO DEBOUNCE (DWB pattern: 0.3s guard prevents spam on rapid mashing)
--------------------------------------------------------------------------------

function blademaster.shouldEcho()
  local now = getEpoch()
  if not blademaster.state.lastEchoTime or (now - blademaster.state.lastEchoTime) > 0.3 then
    blademaster.state.lastEchoTime = now
    return true
  end
  return false
end

--------------------------------------------------------------------------------
-- INFUSE COMMAND (infuse is consumed per attack, must re-send every round)
--------------------------------------------------------------------------------

function blademaster.infuseCmd(infuseType)
  return "infuse " .. infuseType .. ";"
end

--------------------------------------------------------------------------------
-- FULL RESET
--------------------------------------------------------------------------------

function blademaster.fullReset()
  blademaster.state.mode = "double"
  blademaster.state.attackInFlight = false
  blademaster.state.lastTarget = nil
  blademaster.state.lastEchoTime = nil
  blademaster.state.flamefistDone = false
  blademaster.resetBrokenstarState()
  blademaster.resetProneTimer()
  cecho("\n<green>[BM] Full state reset!")
end

--------------------------------------------------------------------------------
-- LB LIMB TRACKING HELPERS
--------------------------------------------------------------------------------

function blademaster.getLimbDamage(limb)
  if not lb or not target then return 0 end
  local t = target:lower():gsub("^%l", string.upper)
  if not lb[t] or not lb[t].hits then return 0 end
  return lb[t].hits[limb] or 0
end

function blademaster.getLL()
  return blademaster.getLimbDamage("left leg")
end

function blademaster.getRL()
  return blademaster.getLimbDamage("right leg")
end

function blademaster.getLA()
  return blademaster.getLimbDamage("left arm")
end

function blademaster.getRA()
  return blademaster.getLimbDamage("right arm")
end

function blademaster.getTorso()
  return blademaster.getLimbDamage("torso")
end

function blademaster.getHead()
  return blademaster.getLimbDamage("head")
end

--------------------------------------------------------------------------------
-- CONDITION CHECKS - ARMS
--------------------------------------------------------------------------------

function blademaster.checkBothArmsPrepped()
  return blademaster.isArmEffectivelyPrepped("left") and
         blademaster.isArmEffectivelyPrepped("right")
end

-- wouldBreak guard (DWC/DWB pattern): treat arm as prepped if a single hit would break it
function blademaster.isArmEffectivelyPrepped(side)
  local dmg = (side == "left") and blademaster.getLA() or blademaster.getRA()
  if dmg >= blademaster.config.prepThreshold then return true end
  return (dmg + blademaster.state.armPrimaryDamage) >= blademaster.config.breakThreshold
end

function blademaster.checkBothArmsBroken()
  return blademaster.getLA() >= blademaster.config.breakThreshold and
         blademaster.getRA() >= blademaster.config.breakThreshold
end

function blademaster.checkAnyArmBroken()
  return blademaster.getLA() >= blademaster.config.breakThreshold or
         blademaster.getRA() >= blademaster.config.breakThreshold
end

function blademaster.checkWillDoubleBreakArms()
  local LA = blademaster.getLA()
  local RA = blademaster.getRA()
  local P = blademaster.state.armPrimaryDamage
  local S = blademaster.state.armSecondaryDamage
  local focusArm = blademaster.getFocusArm()

  if focusArm == "left" then
    return (LA + P >= 100) and (RA + S >= 100)
  else
    return (RA + P >= 100) and (LA + S >= 100)
  end
end

function blademaster.checkWillPrepBothArms()
  -- Check if the next attack will bring BOTH arms to 90%+ (prep threshold)
  local LA = blademaster.getLA()
  local RA = blademaster.getRA()
  local P = blademaster.state.armPrimaryDamage
  local S = blademaster.state.armSecondaryDamage
  local threshold = blademaster.config.prepThreshold
  local focusArm = blademaster.getFocusArm()

  -- If already both prepped, return false (we're past this point)
  if LA >= threshold and RA >= threshold then
    return false
  end

  if focusArm == "left" then
    return (LA + P >= threshold) and (RA + S >= threshold)
  else
    return (RA + P >= threshold) and (LA + S >= threshold)
  end
end

--------------------------------------------------------------------------------
-- CONDITION CHECKS - LEGS
--------------------------------------------------------------------------------

function blademaster.checkBothLegsPrepped()
  return blademaster.isLegEffectivelyPrepped("left") and
         blademaster.isLegEffectivelyPrepped("right")
end

-- wouldBreak guard (DWC/DWB pattern): treat limb as prepped if a single hit would break it
-- Prevents accidental breaks during PREP with wrong infuse (lightning instead of ice)
function blademaster.isLegEffectivelyPrepped(side)
  local dmg = (side == "left") and blademaster.getLL() or blademaster.getRL()
  if dmg >= blademaster.config.prepThreshold then return true end
  return (dmg + blademaster.state.legPrimaryDamage) >= blademaster.config.breakThreshold
end

function blademaster.checkBothLegsBroken()
  return blademaster.getLL() >= blademaster.config.breakThreshold and
         blademaster.getRL() >= blademaster.config.breakThreshold
end

function blademaster.checkAnyLegBroken()
  return blademaster.getLL() >= blademaster.config.breakThreshold or
         blademaster.getRL() >= blademaster.config.breakThreshold
end

function blademaster.checkWillDoubleBreakLegs()
  local LL = blademaster.getLL()
  local RL = blademaster.getRL()
  local P = blademaster.state.legPrimaryDamage
  local S = blademaster.state.legSecondaryDamage
  local focusLeg = blademaster.getFocusLeg()

  if focusLeg == "left" then
    return (LL + P >= 100) and (RL + S >= 100)
  else
    return (RL + P >= 100) and (LL + S >= 100)
  end
end

function blademaster.checkWillPrepBothLegs()
  -- Check if the next attack will bring BOTH legs to 90%+ (prep threshold)
  local LL = blademaster.getLL()
  local RL = blademaster.getRL()
  local P = blademaster.state.legPrimaryDamage
  local S = blademaster.state.legSecondaryDamage
  local threshold = blademaster.config.prepThreshold
  local focusLeg = blademaster.getFocusLeg()

  -- If already both prepped, return false (we're past this point)
  if LL >= threshold and RL >= threshold then
    return false
  end

  if focusLeg == "left" then
    return (LL + P >= threshold) and (RL + S >= threshold)
  else
    return (RL + P >= threshold) and (LL + S >= threshold)
  end
end

--------------------------------------------------------------------------------
-- CONDITION CHECKS - UPPER BODY (Torso + Head via Centreslash Up)
--------------------------------------------------------------------------------

function blademaster.checkUpperPrepped()
  -- Both torso AND head must be at 90%+ for prep
  return blademaster.getTorso() >= blademaster.config.prepThreshold and
         blademaster.getHead() >= blademaster.config.prepThreshold
end

function blademaster.checkUpperBroken()
  -- Both torso AND head must be at 100%+ for broken
  return blademaster.getTorso() >= blademaster.config.breakThreshold and
         blademaster.getHead() >= blademaster.config.breakThreshold
end

function blademaster.checkWillPrepUpper()
  -- Check if the next centreslash will bring BOTH torso and head to 90%+
  -- Uses optimal direction (hit lower limb as primary) for accurate calculation
  local torso = blademaster.getTorso()
  local head = blademaster.getHead()
  local primaryDmg = blademaster.state.torsoDamage   -- 18.1%
  local secondaryDmg = blademaster.state.headDamage  -- 12.1%
  local threshold = blademaster.config.prepThreshold

  -- If already both prepped, return false
  if torso >= threshold and head >= threshold then
    return false
  end

  -- Calculate based on which limb gets primary damage (lower limb = primary)
  if head <= torso then
    -- DOWN: head gets primary, torso gets secondary
    return (head + primaryDmg >= threshold) and (torso + secondaryDmg >= threshold)
  else
    -- UP: torso gets primary, head gets secondary
    return (torso + primaryDmg >= threshold) and (head + secondaryDmg >= threshold)
  end
end

function blademaster.checkWillBreakUpper()
  -- Check if the next centreslash will BREAK both torso and head
  -- Uses the optimal direction (up or down) based on which limb is lower
  local torso = blademaster.getTorso()
  local head = blademaster.getHead()
  local primaryDmg = blademaster.state.torsoDamage   -- 18.1%
  local secondaryDmg = blademaster.state.headDamage  -- 12.1%
  local breakThreshold = blademaster.config.breakThreshold

  -- If we hit the lower limb as primary, calculate final values
  if head <= torso then
    -- DOWN: head gets primary, torso gets secondary
    return (head + primaryDmg >= breakThreshold) and (torso + secondaryDmg >= breakThreshold)
  else
    -- UP: torso gets primary, head gets secondary
    return (torso + primaryDmg >= breakThreshold) and (head + secondaryDmg >= breakThreshold)
  end
end

function blademaster.getCentreslashDirection()
  -- Choose direction to hit the LOWER limb as primary (like getFocusLeg)
  -- UP: torso = primary (18.1%), head = secondary (12.1%)
  -- DOWN: head = primary (18.1%), torso = secondary (12.1%)
  local torso = blademaster.getTorso()
  local head = blademaster.getHead()

  if head <= torso then
    return "down"  -- Hit head as primary
  else
    return "up"    -- Hit torso as primary
  end
end

--------------------------------------------------------------------------------
-- FOCUS DIRECTION HELPERS
--------------------------------------------------------------------------------

function blademaster.getParried()
  local parried = tparrying or ataxiaTemp.parriedLimb or "none"
  if parried == false or parried == "" then
    parried = "none"
  end
  return parried
end

function blademaster.getFocusArm()
  local LA = blademaster.getLA()
  local RA = blademaster.getRA()
  local parried = blademaster.getParried()

  if LA >= blademaster.config.prepThreshold and RA >= blademaster.config.prepThreshold then
    return parried == "left arm" and "right" or "left"
  end

  local focus = (LA <= RA) and "left" or "right"

  if parried == focus .. " arm" then
    return focus == "left" and "right" or "left"
  end

  return focus
end

function blademaster.getFocusLeg()
  local LL = blademaster.getLL()
  local RL = blademaster.getRL()
  local parried = blademaster.getParried()

  if LL >= blademaster.config.prepThreshold and RL >= blademaster.config.prepThreshold then
    return parried == "left leg" and "right" or "left"
  end

  local focus = (LL <= RL) and "left" or "right"

  if parried == focus .. " leg" then
    return focus == "left" and "right" or "left"
  end

  return focus
end

--------------------------------------------------------------------------------
-- PATH CALCULATIONS
--------------------------------------------------------------------------------

function blademaster.calculateArmPath()
  local LA = blademaster.getLA()
  local RA = blademaster.getRA()
  local P = blademaster.state.armPrimaryDamage
  local S = blademaster.state.armSecondaryDamage
  local threshold = blademaster.config.prepThreshold

  if LA >= threshold and RA >= threshold then
    return { hitsToDouble = 0, explanation = "Both arms ready for double-break!" }
  end

  local simLA, simRA = LA, RA
  local hits = 0
  local sequence = {}

  while simLA < threshold or simRA < threshold do
    hits = hits + 1
    if hits > 20 then break end

    if simLA <= simRA then
      simLA = simLA + P
      simRA = simRA + S
      table.insert(sequence, "L")
    else
      simLA = simLA + S
      simRA = simRA + P
      table.insert(sequence, "R")
    end
  end

  return {
    hitsToDouble = hits,
    explanation = string.format("%d hits to arm double-break (sequence: %s)", hits, table.concat(sequence, ""))
  }
end

function blademaster.calculateLegPath()
  local LL = blademaster.getLL()
  local RL = blademaster.getRL()
  local P = blademaster.state.legPrimaryDamage
  local S = blademaster.state.legSecondaryDamage
  local threshold = blademaster.config.prepThreshold

  if LL >= threshold and RL >= threshold then
    return { hitsToDouble = 0, explanation = "Both legs ready for double-break!" }
  end

  local simLL, simRL = LL, RL
  local hits = 0
  local sequence = {}

  while simLL < threshold or simRL < threshold do
    hits = hits + 1
    if hits > 20 then break end

    if simLL <= simRL then
      simLL = simLL + P
      simRL = simRL + S
      table.insert(sequence, "L")
    else
      simLL = simLL + S
      simRL = simRL + P
      table.insert(sequence, "R")
    end
  end

  return {
    hitsToDouble = hits,
    explanation = string.format("%d hits to leg double-break (sequence: %s)", hits, table.concat(sequence, ""))
  }
end

--------------------------------------------------------------------------------
-- SHIN & AIRFIST
--------------------------------------------------------------------------------

function blademaster.getShin()
  if gmcp and gmcp.Char and gmcp.Char.Vitals and gmcp.Char.Vitals.charstats then
    for _, stat in ipairs(gmcp.Char.Vitals.charstats) do
      local shinValue = string.match(stat, "Shin:%s*(%d+)")
      if shinValue then
        return tonumber(shinValue) or 0
      end
    end
  end
  return 0
end

function blademaster.needsAirfist(targetLimbType)
  local parried = blademaster.getParried()
  local shin = blademaster.getShin()

  if shin < 25 then
    return false, "not enough shin (" .. shin .. "/25)"
  end

  if blademaster.hasAff("airfisted") then
    return false, "already airfisted"
  end

  if targetLimbType == "arm" then
    if parried == "left arm" or parried == "right arm" then
      return true, "parrying arm (" .. parried .. ")"
    end
  elseif targetLimbType == "leg" then
    if parried == "left leg" or parried == "right leg" then
      return true, "parrying leg (" .. parried .. ")"
    end
  end

  return false, "not parrying target limb"
end

--------------------------------------------------------------------------------
-- STRIKE SELECTION (shared)
--------------------------------------------------------------------------------

function blademaster.selectPrepStrike()
  -- Prep phase strikes: Hamstring first, then afflictions
  local now = os.time()
  local hamstringExpired = (now - (blademaster.state.lastHamstringTime or 0)) >= blademaster.config.hamstringDuration
  if not blademaster.hasAff("hamstring") or hamstringExpired then
    return "hamstring"
  end

  -- Lightning prep: paralysis > hypochondria > weariness > clumsiness
  if not blademaster.hasAff("paralysis") then
    return "neck"
  end
  if not blademaster.hasAff("hypochondria") then
    return "chest"
  end
  if not blademaster.hasAff("weariness") then
    return "shoulder"
  end
  if not blademaster.hasAff("clumsiness") then
    return "ears"
  end

  return "neck"
end

function blademaster.selectIceStrike()
  -- Ice phase: clumsiness first (ice doesn't give it), then others
  if not blademaster.hasAff("clumsiness") then
    return "ears"
  end
  if not blademaster.hasAff("paralysis") then
    return "neck"
  end
  return "neck"
end

--------------------------------------------------------------------------------
-- UNIFIED DISPATCH (DWC/DWB pattern: single entry point with shared guards)
-- All mode-specific logic is delegated to runDoublePrep/runQuadPrep/runBrokenstar
-- after guards pass. This ensures attackInFlight, reboundHold, target-change
-- reset, and aeon checks apply uniformly across all strategies.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- PROMPT RETRY (v4.7.275)
--
-- PvP Blademaster offense is 100% keypress-driven. ataxia_promptCommands() re-dispatches every
-- prompt ONLY when ataxiaBasher.enabled -- the PvE path -- so in PvP a suppressed or
-- server-refused attack is simply lost until the next press, silently.
--
-- In the 2026-08-19 Grulk log that produced a 30-second stretch (09:59:10 -> 09:59:39) with
-- zero dispatches at all, and 89 presses that yielded 10 outbound actions.
--
-- The window is deliberately anchored to the last MANUAL press, not to the last run: press once
-- and we keep swinging; stop pressing and it stops on its own inside `retryWindow`. That keeps
-- the "attack only when I say so" contract while removing the "one press, one lost attack" tax.
--------------------------------------------------------------------------------
function blademaster.markManual()
  blademaster.state.lastManualAt = (getEpoch and getEpoch()) or os.time()
end

-- MODE FLAP WARNING (v4.7.275). The 2026-08-19 log switched double -> quad -> double -> quad
-- mid-fight. Each switch changes which limb group we prep, and the group left behind decays
-- back to 0 -- the two productive arm swings (30.2%/30.2%) were abandoned and the legs
-- (18.1%/12.1%) never advanced past the opening swing. Advisory only: the user may well mean
-- it, and refusing a keypress mid-fight would be worse than a line of text.
function blademaster.warnModeFlap(newMode)
  if blademaster.state.mode == newMode then return end
  local LL, RL = blademaster.getLL(), blademaster.getRL()
  local LA, RA = blademaster.getLA(), blademaster.getRA()
  if (LL + RL + LA + RA) <= 0 then return end
  cecho(string.format(
    "\n<yellow>[BM]<reset> mode <white>%s<reset> -> <white>%s<reset> with prep on the board"
    .. " (legs %.1f/%.1f, arms %.1f/%.1f) -- the group you leave decays back to 0.",
    tostring(blademaster.state.mode), tostring(newMode), LL, RL, LA, RA))
end

function blademaster.retryTick()
  local st = blademaster.state
  if not st.autoRetry then return end
  if not st.lastManualAt then return end
  if st.attackInFlight then return end
  if not target or target == "" then return end
  if ataxia_isClass and not ataxia_isClass("blademaster") then return end

  local now = (getEpoch and getEpoch()) or os.time()
  if (now - st.lastManualAt) > blademaster.config.retryWindow then return end

  -- Cheap pre-checks so we do not rebuild a combo we cannot possibly send. `blademaster.run()`
  -- and `sendAttack` still own the real guards; these only avoid the churn.
  if canBals and not canBals() then return end
  if affed then
    if affed("prone") or affed("paralysis") or affed("aeon") then return end
  end

  blademaster.run()
end

function blademaster.run()
  -- Anti-desync: block re-dispatch while previous attack hasn't resolved (DWC pattern)
  if blademaster.state.attackInFlight then return end

  -- Safe defaults (prevent nil errors on first load)
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}
  ataxia.settings = ataxia.settings or {}
  ataxia.afflictions = ataxia.afflictions or {}
  ataxiaTemp = ataxiaTemp or {}
  tAffs = tAffs or {}

  -- Target validation
  if not target or target == "" then
    cecho("\n<red>[BM] No target set! Use: tar <name>")
    return
  end

  -- Aeon check (shared with shaman/serpent)
  if ataxia.afflictions.aeon then
    blademaster.suppressed("aeon")
    return
  end

  -- Rebound hold gate (shared system - delays attack until rebound drops)
  if reboundHold and reboundHold.gate(blademaster.run) then
    blademaster.suppressed("rebound hold (waiting for our rebounding)")
    return
  end

  -- Target-change reset (DWB pattern: prevents stale Brokenstar state on new target)
  if blademaster.state.lastTarget ~= target then
    blademaster.state.lastTarget = target
    blademaster.state.flamefistDone = false
    blademaster.resetBrokenstarState()
    blademaster.resetProneTimer()
  end

  -- Mode routing
  local mode = blademaster.state.mode
  if mode == "double" then
    blademaster.dispatch.runDoublePrep()
  elseif mode == "quad" then
    blademaster.dispatch.runQuadPrep()
  elseif mode == "brokenstar" then
    blademaster.dispatch.runBrokenstar()
  elseif mode == "group" then
    blademaster.dispatch.runGroup()
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  STRATEGY 1: DOUBLE-PREP (LEGS ONLY)
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function blademaster.getPhaseDoublePrep()
  -- 3-phase system for legs only:
  -- 1. leg_prep: Both legs < 90% (Lightning)
  -- 2. leg_break: Legs prepped, not broken (Ice)
  -- 3. mangle: PRONE (Ice + Sternum) - stay in mangle as long as they're down

  local legsPrepped = blademaster.checkBothLegsPrepped()

  -- MANGLE: If prone, stay in mangle for max damage
  if blademaster.hasAff("prone") then
    return "mangle"
  end

  if legsPrepped or blademaster.checkWillDoubleBreakLegs() then
    return "leg_break"
  end

  return "leg_prep"
end

function blademaster.getPhaseLabelDoublePrep()
  local phase = blademaster.getPhaseDoublePrep()
  local labels = {
    leg_prep = "<yellow>Leg Prep",
    leg_break = "<blue>Leg Break",
    mangle = "<red>Mangle",
  }
  return labels[phase] or "<grey>Unknown"
end

function blademaster.selectStrikeDoublePrep()
  local phase = blademaster.getPhaseDoublePrep()

  -- MANGLE: Always STERNUM
  if phase == "mangle" then
    return "sternum"
  end

  -- LEG BREAK: KNEES for prone
  if phase == "leg_break" then
    return "knees"
  end

  -- LEG PREP: Check if we need to dismount before double-break
  if phase == "leg_prep" then
    -- Dismount during final prep hit if mounted + hamstrung
    -- This ensures KNEES on double-break will prone (not just dismount)
    if tmounted and blademaster.hasAff("hamstring") and blademaster.checkWillPrepBothLegs() then
      return "knees"  -- Dismount now, so KNEES on double-break will prone
    end
    return blademaster.selectPrepStrike()
  end

  return blademaster.selectPrepStrike()
end

function blademaster.selectAttackDoublePrep()
  local phase = blademaster.getPhaseDoublePrep()

  -- V1 fallback: GMCP balance fires before text trigger in the same data chunk,
  -- so haveAffV3("rebounding") may return false even when rebounding is active.
  -- The tAffs fallback catches this timing gap. DO NOT remove.
  if blademaster.hasAff("shield") or blademaster.hasAff("rebounding") or (tAffs and (tAffs.shield or tAffs.rebounding)) then
    return "raze", nil
  end

  -- Airfist is its own full-balance attack (use during prep phases)
  if phase == "leg_prep" then
    local needsAF, _ = blademaster.needsAirfist("leg")
    if needsAF then
      return "airfist", nil
    end
  end

  -- MANGLE PHASE: Right leg first to 200%+ (mangled), then left leg
  if phase == "mangle" then
    local RL = blademaster.getRL()
    if RL < 200 then
      return "legslash", "right"
    else
      return "legslash", "left"
    end
  end

  return "legslash", blademaster.getFocusLeg()
end

function blademaster.buildComboDoublePrep()
  local attack, direction = blademaster.selectAttackDoublePrep()
  local strike = blademaster.selectStrikeDoublePrep()
  local phase = blademaster.getPhaseDoublePrep()
  local combo = ""

  -- Airfist is its own full-balance attack (no infuse, no strike)
  if attack == "airfist" then
    return "airfist " .. target .. ";assess " .. target
  end

  -- Infuse: Ice for break/mangle + final prep (strip caloric), Lightning for normal prep
  if phase == "leg_break" or phase == "mangle" then
    combo = blademaster.infuseCmd("ice")
  elseif phase == "leg_prep" and blademaster.checkWillPrepBothLegs() then
    combo = blademaster.infuseCmd("ice")
  else
    combo = blademaster.infuseCmd("lightning")
  end

  if attack == "raze" then
    combo = combo .. "raze " .. target
    if strike then
      combo = combo .. " " .. strike
    end
  elseif attack == "balanceslash" then
    -- Balanceslash to extend prone time (no direction needed)
    combo = combo .. "balanceslash " .. target
    if strike then
      combo = combo .. " " .. strike
    end
  elseif attack == "legslash" then
    combo = combo .. "legslash " .. target .. " " .. direction
    if strike then
      combo = combo .. " " .. strike
    end
  end

  return combo
end

function blademaster.dispatch.runDoublePrep()
  -- Guards handled by blademaster.run() — safe defaults, target, rebound, attackInFlight

  local phase = blademaster.getPhaseDoublePrep()
  local phaseLabel = blademaster.getPhaseLabelDoublePrep()
  local targetHP = tonumber(ataxiaTemp.targetHP) or 100

  -- Reset prone timer if not in mangle phase or target not prone
  if phase ~= "mangle" or not blademaster.hasAff("prone") then
    blademaster.resetProneTimer()
  end

  -- Debounced echo (DWB pattern: 0.3s guard prevents spam on rapid mashing)
  if blademaster.shouldEcho() then
    cecho("\n<cyan>[BM " .. phaseLabel .. "<cyan>] Target: " .. tostring(target) .. " | HP: " .. targetHP .. "% | Track: " .. blademaster.getTrackingSystem())
    cecho("\n<cyan>[BM " .. phaseLabel .. "<cyan>] Legs: LL=" .. string.format("%.1f", blademaster.getLL()) .. "% RL=" .. string.format("%.1f", blademaster.getRL()) .. "%")
    cecho("\n<cyan>[BM " .. phaseLabel .. "<cyan>] Dmg: P=" .. string.format("%.1f", blademaster.state.legPrimaryDamage) .. "% S=" .. string.format("%.1f", blademaster.state.legSecondaryDamage) .. "%")

    if phase == "leg_prep" then
      local legPath = blademaster.calculateLegPath()
      if blademaster.checkWillPrepBothLegs() then
        if tmounted and blademaster.hasAff("hamstring") then
          cecho("\n<magenta>*** DISMOUNT - KNEES to dismount before double-break! ***")
        else
          cecho("\n<blue>*** FINAL PREP - ICE infuse to strip caloric! ***")
        end
      elseif legPath.hitsToDouble > 0 then
        cecho("\n<yellow>" .. legPath.explanation)
      end
    elseif phase == "leg_break" then
      cecho("\n<blue>*** LEG BREAK - ICE infuse + KNEES for prone! ***")
    elseif phase == "mangle" then
      local RL = blademaster.getRL()
      local LL = blademaster.getLL()
      if RL < 200 then
        cecho("\n<red>*** MANGLE - Legslash RIGHT + STERNUM (RL=" .. string.format("%.1f", RL) .. "%/200%) ***")
      else
        cecho("\n<red>*** MANGLE - Legslash LEFT + STERNUM (RL mangled, LL=" .. string.format("%.1f", LL) .. "%) ***")
      end
    end

    local parried = blademaster.getParried()
    local shin = blademaster.getShin()
    local attack, _ = blademaster.selectAttackDoublePrep()
    cecho("\n<cyan>[BM " .. phaseLabel .. "<cyan>] Parried: " .. parried .. " | Shin: " .. shin)
    if attack == "airfist" then
      cecho(" | <green>AIRFIST!")
    end
  end

  -- Increment attack count in mangle phase
  if phase == "mangle" and blademaster.state.proneTimerActive then
    blademaster.state.proneAttackCount = blademaster.state.proneAttackCount + 1
  end

  -- Build and send via centralized wrapper
  local cmd = combatQueue and combatQueue() or ""
  cmd = cmd .. blademaster.buildComboDoublePrep()
  cmd = cmd .. ";assess " .. target
  blademaster.sendAttack(cmd)
end

-- Aliases for Double-Prep (thin wrappers → unified dispatch)
function bmd()
  blademaster.warnModeFlap("double")
  blademaster.state.mode = "double"
  blademaster.markManual()
  blademaster.run()
end

function bmdispatch()
  blademaster.warnModeFlap("double")
  blademaster.state.mode = "double"
  blademaster.markManual()
  blademaster.run()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  STRATEGY 2: QUAD-PREP (ARMS + LEGS)
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function blademaster.getPhaseQuadPrep()
  -- 6-phase system (Ice Path):
  -- 1. arm_prep: Both arms < 90% (Lightning)
  -- 2. leg_prep: Arms prepped, both legs < 90% (Lightning)
  -- 3. flamefist: All 4 limbs prepped, negate rebounding before breaks
  -- 4. arm_break: Flamefist done, arms not broken (Ice)
  -- 5. leg_break: Arms broken, legs prepped, legs not broken (Ice) — always RIGHT
  -- 6. mangle: PRONE (Ice + Sternum) — always legslash RIGHT (curing applies left first)

  local armsPrepped = blademaster.checkBothArmsPrepped()
  local armsBroken = blademaster.checkBothArmsBroken()
  local legsPrepped = blademaster.checkBothLegsPrepped()

  -- Phase 6: MANGLE - If prone, stay in mangle for max damage
  if blademaster.hasAff("prone") then
    return "mangle"
  end

  -- Phase 5: LEG BREAK
  if armsBroken and legsPrepped then
    return "leg_break"
  end

  -- Phase 4: ARM BREAK (only after flamefist done)
  if armsPrepped and legsPrepped and not armsBroken and blademaster.state.flamefistDone then
    return "arm_break"
  end

  -- Phase 3: FLAMEFIST (all 4 limbs prepped, flamefist not yet done)
  if armsPrepped and legsPrepped and not blademaster.state.flamefistDone then
    return "flamefist"
  end

  -- Phase 2: LEG PREP
  if armsPrepped and not legsPrepped then
    return "leg_prep"
  end

  -- Phase 1: ARM PREP
  return "arm_prep"
end

function blademaster.getPhaseLabelQuadPrep()
  local phase = blademaster.getPhaseQuadPrep()
  local labels = {
    arm_prep = "<yellow>Arm Prep",
    leg_prep = "<yellow>Leg Prep",
    flamefist = "<orange>Flamefist",
    arm_break = "<blue>Arm Break",
    leg_break = "<blue>Leg Break",
    mangle = "<red>Mangle",
  }
  return labels[phase] or "<grey>Unknown"
end

function blademaster.selectStrikeQuadPrep()
  local phase = blademaster.getPhaseQuadPrep()

  -- FLAMEFIST: No strike (standalone ability)
  if phase == "flamefist" then
    return nil
  end

  -- MANGLE: Always STERNUM
  if phase == "mangle" then
    return "sternum"
  end

  -- LEG BREAK: KNEES for prone
  if phase == "leg_break" then
    return "knees"
  end

  -- ARM BREAK: Ice afflictions
  if phase == "arm_break" then
    return blademaster.selectIceStrike()
  end

  -- PREP PHASES: Standard prep strikes
  return blademaster.selectPrepStrike()
end

function blademaster.selectAttackQuadPrep()
  local phase = blademaster.getPhaseQuadPrep()

  -- FLAMEFIST: Negates rebounding — use even through rebounding, but raze shield
  if phase == "flamefist" then
    if blademaster.hasAff("shield") or (tAffs and tAffs.shield) then
      return "raze", nil
    end
    return "flamefist", nil
  end

  -- V1 fallback: GMCP balance fires before text trigger in the same data chunk,
  -- so haveAffV3("rebounding") may return false even when rebounding is active.
  -- The tAffs fallback catches this timing gap. DO NOT remove.
  if blademaster.hasAff("shield") or blademaster.hasAff("rebounding") or (tAffs and (tAffs.shield or tAffs.rebounding)) then
    return "raze", nil
  end

  -- Airfist is its own full-balance attack (use during prep phases)
  if phase == "arm_prep" then
    local needsAF, _ = blademaster.needsAirfist("arm")
    if needsAF then
      return "airfist", nil
    end
    return "armslash", blademaster.getFocusArm()
  end

  if phase == "leg_prep" then
    local needsAF, _ = blademaster.needsAirfist("leg")
    if needsAF then
      return "airfist", nil
    end
    return "legslash", blademaster.getFocusLeg()
  end

  if phase == "arm_break" then
    return "armslash", blademaster.getFocusArm()
  end

  -- LEG BREAK: Always RIGHT (curing applies to left first, so right stays broken longer)
  if phase == "leg_break" then
    return "legslash", "right"
  end

  -- MANGLE: Always RIGHT + STERNUM (curing applies to left first)
  if phase == "mangle" then
    return "legslash", "right"
  end

  return "legslash", blademaster.getFocusLeg()
end

function blademaster.buildComboQuadPrep()
  local attack, direction = blademaster.selectAttackQuadPrep()
  local strike = blademaster.selectStrikeQuadPrep()
  local phase = blademaster.getPhaseQuadPrep()
  local combo = ""

  -- Airfist is its own full-balance attack (no infuse, no strike)
  if attack == "airfist" then
    return "airfist " .. target .. ";assess " .. target
  end

  -- Flamefist is its own full-balance attack (no infuse, no strike)
  if attack == "flamefist" then
    blademaster.state.flamefistDone = true
    return "flamefist " .. target .. ";assess " .. target
  end

  -- Infuse: Ice for break/mangle + final prep, Lightning for normal prep
  -- EXCEPTION: Use Ice on final prep attacks to strip caloric before break
  if phase == "arm_break" or phase == "leg_break" or phase == "mangle" then
    combo = blademaster.infuseCmd("ice")
  elseif phase == "arm_prep" and blademaster.checkWillPrepBothArms() then
    combo = blademaster.infuseCmd("ice")
  elseif phase == "leg_prep" and blademaster.checkWillPrepBothLegs() then
    combo = blademaster.infuseCmd("ice")
  else
    combo = blademaster.infuseCmd("lightning")
  end

  if attack == "raze" then
    combo = combo .. "raze " .. target
    if strike then
      combo = combo .. " " .. strike
    end
  elseif attack == "balanceslash" then
    -- Balanceslash to extend prone time (no direction needed)
    combo = combo .. "balanceslash " .. target
    if strike then
      combo = combo .. " " .. strike
    end
  elseif attack == "armslash" then
    combo = combo .. "armslash " .. target .. " " .. direction
    if strike then
      combo = combo .. " " .. strike
    end
  elseif attack == "legslash" then
    combo = combo .. "legslash " .. target .. " " .. direction
    if strike then
      combo = combo .. " " .. strike
    end
  end

  return combo
end

function blademaster.dispatch.runQuadPrep()
  -- Guards handled by blademaster.run()

  local phase = blademaster.getPhaseQuadPrep()
  local phaseLabel = blademaster.getPhaseLabelQuadPrep()
  local targetHP = tonumber(ataxiaTemp.targetHP) or 100

  -- Reset prone timer if not in mangle phase or target not prone
  if phase ~= "mangle" or not blademaster.hasAff("prone") then
    blademaster.resetProneTimer()
  end

  -- Debounced echo
  if blademaster.shouldEcho() then
    cecho("\n<cyan>[BMQ " .. phaseLabel .. "<cyan>] Target: " .. tostring(target) .. " | HP: " .. targetHP .. "% | Track: " .. blademaster.getTrackingSystem())
    cecho("\n<cyan>[BMQ " .. phaseLabel .. "<cyan>] Arms: LA=" .. string.format("%.1f", blademaster.getLA()) .. "% RA=" .. string.format("%.1f", blademaster.getRA()) .. "%")
    cecho("\n<cyan>[BMQ " .. phaseLabel .. "<cyan>] Legs: LL=" .. string.format("%.1f", blademaster.getLL()) .. "% RL=" .. string.format("%.1f", blademaster.getRL()) .. "%")

    if phase == "arm_prep" then
      local armPath = blademaster.calculateArmPath()
      if blademaster.checkWillPrepBothArms() then
        cecho("\n<blue>*** FINAL ARM PREP - ICE infuse to strip caloric! ***")
      elseif armPath.hitsToDouble > 0 then
        cecho("\n<yellow>" .. armPath.explanation)
      else
        cecho("\n<green>*** ARMS READY ***")
      end
    elseif phase == "leg_prep" then
      local legPath = blademaster.calculateLegPath()
      if blademaster.checkWillPrepBothLegs() then
        cecho("\n<blue>*** FINAL LEG PREP - ICE infuse to strip caloric! ***")
      elseif legPath.hitsToDouble > 0 then
        cecho("\n<yellow>" .. legPath.explanation)
      else
        cecho("\n<green>*** LEGS READY ***")
      end
    elseif phase == "flamefist" then
      cecho("\n<orange>*** FLAMEFIST - Negate rebounding before breaks! ***")
    elseif phase == "arm_break" then
      cecho("\n<blue>*** ARM BREAK - ICE infuse, break both arms! ***")
    elseif phase == "leg_break" then
      cecho("\n<blue>*** LEG BREAK - ICE infuse + KNEES, always RIGHT! ***")
    elseif phase == "mangle" then
      local RL = blademaster.getRL()
      cecho("\n<red>*** MANGLE - Legslash RIGHT + STERNUM (RL=" .. string.format("%.1f", RL) .. "%) ***")
    end

    local parried = blademaster.getParried()
    local shin = blademaster.getShin()
    local attack, _ = blademaster.selectAttackQuadPrep()
    cecho("\n<cyan>[BMQ " .. phaseLabel .. "<cyan>] Parried: " .. parried .. " | Shin: " .. shin)
    if attack == "airfist" then
      cecho(" | <green>AIRFIST!")
    elseif attack == "flamefist" then
      cecho(" | <orange>FLAMEFIST!")
    end
  end

  -- Increment attack count in mangle phase
  if phase == "mangle" and blademaster.state.proneTimerActive then
    blademaster.state.proneAttackCount = blademaster.state.proneAttackCount + 1
  end

  -- Build and send via centralized wrapper
  local cmd = combatQueue and combatQueue() or ""
  cmd = cmd .. blademaster.buildComboQuadPrep()
  cmd = cmd .. ";assess " .. target
  blademaster.sendAttack(cmd)
end

-- Aliases for Quad-Prep (thin wrappers → unified dispatch)
function bmdq()
  blademaster.warnModeFlap("quad")
  blademaster.state.mode = "quad"
  blademaster.markManual()
  blademaster.run()
end

function bmdispatchquad()
  blademaster.warnModeFlap("quad")
  blademaster.state.mode = "quad"
  blademaster.markManual()
  blademaster.run()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  STRATEGY 3: BROKENSTAR (INSTANT KILL)
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function blademaster.resetBrokenstarState()
  blademaster.state.isImpaled = false
  blademaster.state.impaleslashDone = false
  blademaster.state.secondImpale = false
  blademaster.state.bleedingReady = false
  blademaster.state.targetBleeding = 0
  blademaster.state.withdrawDone = false
  blademaster.state.bladetwistCount = 0
  blademaster.state.attackInFlight = false
end

function blademaster.getPhaseBrokenstar()
  -- 9-phase system for instant kill with upper body prep:
  -- 1. upper_prep: Centreslash up to prep torso/head (90%+)
  -- 2. leg_prep: Legslash to prep both legs (90%+)
  -- 3. upper_break: Centreslash up to break torso/head (100%+)
  -- 4. leg_break: Legslash + KNEES to break legs + prone (100%+)
  -- 5. impale: Impale the prone target
  -- 6. impaleslash: Slash arteries for bleeding
  -- 7. bladetwist: Twist until 700 bleeding
  -- 8. withdraw: Withdraw blade (if still impaled)
  -- 9. brokenstar: Execute instant kill

  local upperPrepped = blademaster.checkUpperPrepped()
  local upperBroken = blademaster.checkUpperBroken()
  local legsPrepped = blademaster.checkBothLegsPrepped()
  local legsBroken = blademaster.checkBothLegsBroken()

  -- Phase 9: BROKENSTAR (execute kill)
  -- Can brokenstar if: withdrew blade OR target not impaled (writhed free + stood up)
  if blademaster.state.bleedingReady and (blademaster.state.withdrawDone or not blademaster.state.isImpaled) then
    return "brokenstar"
  end

  -- Phase 8: WITHDRAW (pull blade out) - only if still impaled
  if blademaster.state.bleedingReady and blademaster.state.isImpaled then
    return "withdraw"
  end

  -- Phase 7: BLADETWIST (build bleeding) - requires being impaled!
  if blademaster.state.impaleslashDone and blademaster.state.isImpaled then
    return "bladetwist"
  end

  -- Phase 6: IMPALESLASH (slash arteries)
  if blademaster.state.isImpaled and not blademaster.state.impaleslashDone then
    return "impaleslash"
  end

  -- Phase 5: IMPALE (first impale or re-impale after writhe)
  -- Can impale if: both legs broken OR target is prone (from writhe while prone)
  local targetProne = blademaster.hasAff("prone")
  local canImpale = legsBroken or targetProne
  if canImpale and not blademaster.state.isImpaled then
    return "impale"
  end

  -- Phase 4: LEG BREAK (upper must be broken first!)
  if upperBroken and (legsPrepped or blademaster.checkWillDoubleBreakLegs()) then
    return "leg_break"
  end

  -- Phase 3: UPPER BREAK (legs must be prepped first!)
  if legsPrepped and (upperPrepped or blademaster.checkWillBreakUpper()) then
    return "upper_break"
  end

  -- Phase 2: LEG PREP (upper must be prepped first!)
  if upperPrepped and not legsPrepped then
    return "leg_prep"
  end

  -- Phase 1: UPPER PREP (default - prep torso/head first)
  return "upper_prep"
end

function blademaster.getPhaseLabelBrokenstar()
  local phase = blademaster.getPhaseBrokenstar()
  local labels = {
    upper_prep = "<yellow>Upper Prep",
    leg_prep = "<yellow>Leg Prep",
    upper_break = "<blue>Upper Break",
    leg_break = "<blue>Leg Break",
    impale = "<cyan>Impale",
    impaleslash = "<magenta>Impaleslash",
    bladetwist = "<red>Bladetwist",
    withdraw = "<yellow>Withdraw",
    brokenstar = "<green>BROKENSTAR",
  }
  return labels[phase] or "<grey>Unknown"
end

function blademaster.selectStrikeBrokenstar()
  local phase = blademaster.getPhaseBrokenstar()

  -- UPPER PREP: Standard prep strikes (hamstring > paralysis > etc)
  if phase == "upper_prep" then
    return blademaster.selectPrepStrike()
  end

  -- UPPER BREAK: Ice afflictions (clumsiness first since ice doesn't give it)
  if phase == "upper_break" then
    return blademaster.selectIceStrike()
  end

  -- LEG BREAK: KNEES for prone (critical - need prone for guaranteed impale!)
  if phase == "leg_break" then
    return "knees"
  end

  -- LEG PREP: Check if we need to dismount before double-break
  if phase == "leg_prep" then
    -- Dismount during final prep hit if mounted + hamstrung
    if tmounted and blademaster.hasAff("hamstring") and blademaster.checkWillPrepBothLegs() then
      return "knees"  -- Dismount now, so KNEES on double-break will prone
    end
    return blademaster.selectPrepStrike()
  end

  -- Impale phases and beyond: No strike needed
  return nil
end

function blademaster.selectAttackBrokenstar()
  local phase = blademaster.getPhaseBrokenstar()

  -- V1 fallback: GMCP balance fires before text trigger in the same data chunk,
  -- so haveAffV3("rebounding") may return false even when rebounding is active.
  -- The tAffs fallback catches this timing gap. DO NOT remove.
  if blademaster.hasAff("shield") or blademaster.hasAff("rebounding") or (tAffs and (tAffs.shield or tAffs.rebounding)) then
    return "raze"
  end

  -- Airfist during leg prep if needed
  if phase == "leg_prep" then
    local needsAF, _ = blademaster.needsAirfist("leg")
    if needsAF then
      return "airfist"
    end
  end

  return phase  -- Return the phase name as the attack type
end

function blademaster.buildComboBrokenstar()
  local phase = blademaster.getPhaseBrokenstar()
  local attack = blademaster.selectAttackBrokenstar()
  local strike = blademaster.selectStrikeBrokenstar()
  local combo = ""

  -- Handle raze for shield/rebounding
  if attack == "raze" then
    combo = "raze " .. target
    if strike then
      combo = combo .. " " .. strike
    end
    combo = combo .. ";assess " .. target
    return combo
  end

  -- Airfist is its own full-balance attack (no infuse, no strike)
  if attack == "airfist" then
    return "airfist " .. target .. ";assess " .. target
  end

  if phase == "upper_prep" then
    -- Lightning infuse for prep, Ice on final prep + break
    local direction = blademaster.getCentreslashDirection()
    if blademaster.checkWillPrepUpper() then
      combo = blademaster.infuseCmd("ice")
    else
      combo = blademaster.infuseCmd("lightning")
    end
    combo = combo .. "centreslash " .. target .. " " .. direction
    if strike then
      combo = combo .. " " .. strike
    end

  elseif phase == "upper_break" then
    -- Ice infuse for break, use dynamic direction
    local direction = blademaster.getCentreslashDirection()
    combo = blademaster.infuseCmd("ice") .. "centreslash " .. target .. " " .. direction
    if strike then
      combo = combo .. " " .. strike
    end

  elseif phase == "leg_prep" then
    -- Lightning infuse for prep, Ice on final prep
    if blademaster.checkWillPrepBothLegs() then
      combo = blademaster.infuseCmd("ice")
    else
      combo = blademaster.infuseCmd("lightning")
    end
    local focusLeg = blademaster.getFocusLeg()
    combo = combo .. "legslash " .. target .. " " .. focusLeg
    if strike then
      combo = combo .. " " .. strike
    end

  elseif phase == "leg_break" then
    -- Ice infuse for break + KNEES to prone
    combo = blademaster.infuseCmd("ice")
    local focusLeg = blademaster.getFocusLeg()
    combo = combo .. "legslash " .. target .. " " .. focusLeg
    if strike then
      combo = combo .. " " .. strike
    end

  elseif phase == "impale" then
    -- Impale the prone target
    combo = "impale " .. target

  elseif phase == "impaleslash" then
    -- Impaleslash to start bleeding
    combo = "impaleslash " .. target

  elseif phase == "bladetwist" then
    -- Bladetwist to build bleeding
    -- Count is incremented by trigger when bladetwist actually fires (not on button press)
    -- On 3rd+ bladetwist, add discern to check bleeding
    if blademaster.state.bladetwistCount >= 2 then
      combo = "bladetwist;discern " .. target
    else
      combo = "bladetwist;assess " .. target
    end
    return combo  -- Skip the assess at end since we already have it

  elseif phase == "withdraw" then
    -- Withdraw blade before brokenstar
    combo = "withdraw " .. target

  elseif phase == "brokenstar" then
    -- Execute the kill!
    combo = "brokenstar " .. target
  end

  -- Add assess for most phases (except bladetwist which has it built in)
  if phase ~= "bladetwist" then
    combo = combo .. ";assess " .. target
  end

  return combo
end

function blademaster.dispatch.runBrokenstar()
  -- Guards handled by blademaster.run()

  local phase = blademaster.getPhaseBrokenstar()
  local phaseLabel = blademaster.getPhaseLabelBrokenstar()
  local targetHP = tonumber(ataxiaTemp.targetHP) or 100

  -- Debounced echo
  if blademaster.shouldEcho() then
    cecho("\n<cyan>[BMBS " .. phaseLabel .. "<cyan>] Target: " .. tostring(target) .. " | HP: " .. targetHP .. "% | Track: " .. blademaster.getTrackingSystem())
    cecho("\n<cyan>[BMBS " .. phaseLabel .. "<cyan>] Upper: T=" .. string.format("%.1f", blademaster.getTorso()) .. "% H=" .. string.format("%.1f", blademaster.getHead()) .. "%")
    cecho("\n<cyan>[BMBS " .. phaseLabel .. "<cyan>] Legs: LL=" .. string.format("%.1f", blademaster.getLL()) .. "% RL=" .. string.format("%.1f", blademaster.getRL()) .. "%")

    if phase == "upper_prep" then
      local direction = blademaster.getCentreslashDirection()
      if blademaster.checkWillPrepUpper() then
        cecho("\n<blue>*** FINAL UPPER PREP - ICE infuse + centreslash " .. direction .. "! ***")
      else
        cecho("\n<yellow>*** UPPER PREP - Centreslash " .. direction .. " (hitting " .. (direction == "up" and "torso" or "head") .. " as primary) ***")
      end
    elseif phase == "upper_break" then
      local direction = blademaster.getCentreslashDirection()
      cecho("\n<blue>*** UPPER BREAK - Centreslash " .. direction .. " to break torso/head! ***")
    elseif phase == "leg_prep" then
      local legPath = blademaster.calculateLegPath()
      if blademaster.checkWillPrepBothLegs() then
        if tmounted and blademaster.hasAff("hamstring") then
          cecho("\n<magenta>*** DISMOUNT - KNEES to dismount before double-break! ***")
        else
          cecho("\n<blue>*** FINAL LEG PREP - ICE infuse to strip caloric! ***")
        end
      elseif legPath.hitsToDouble > 0 then
        cecho("\n<yellow>" .. legPath.explanation)
      end
    elseif phase == "leg_break" then
      cecho("\n<blue>*** LEG BREAK - Double-break legs + KNEES to prone! ***")
    elseif phase == "impale" then
      cecho("\n<cyan>*** IMPALE - Impale the prone target! ***")
    elseif phase == "impaleslash" then
      cecho("\n<magenta>*** IMPALESLASH - Slash arteries for bleeding! ***")
    elseif phase == "bladetwist" then
      local bleedColor = blademaster.state.targetBleeding >= 700 and "<green>" or "<yellow>"
      local twistNum = blademaster.state.bladetwistCount + 1
      local discernNote = twistNum >= 3 and " <cyan>(+discern)" or ""
      cecho("\n<red>*** BLADETWIST #" .. twistNum .. " - Building bleeding (" .. bleedColor .. blademaster.state.targetBleeding .. "/700<red>)" .. discernNote .. " ***")
    elseif phase == "withdraw" then
      cecho("\n<yellow>*** WITHDRAW - Pull blade out! ***")
    elseif phase == "brokenstar" then
      cecho("\n<green>*** BROKENSTAR - EXECUTE INSTANT KILL! ***")
    end

    -- State tracking display
    cecho("\n<cyan>[BMBS " .. phaseLabel .. "<cyan>] Impaled: " .. (blademaster.state.isImpaled and "<green>YES" or "<red>NO"))
    cecho("<cyan> | Slashed: " .. (blademaster.state.impaleslashDone and "<green>YES" or "<red>NO"))
    local bleedColor = blademaster.state.targetBleeding >= 700 and "<green>" or (blademaster.state.targetBleeding >= 300 and "<yellow>" or "<red>")
    cecho("<cyan> | Bleed: " .. bleedColor .. blademaster.state.targetBleeding)
    cecho("<cyan> | Withdrawn: " .. (blademaster.state.withdrawDone and "<green>YES" or "<red>NO"))

    local parried = blademaster.getParried()
    local shin = blademaster.getShin()
    local attack = blademaster.selectAttackBrokenstar()
    cecho("\n<cyan>[BMBS " .. phaseLabel .. "<cyan>] Parried: " .. parried .. " | Shin: " .. shin)
    if attack == "airfist" then
      cecho(" | <green>AIRFIST!")
    end
  end

  -- Build and send via centralized wrapper
  local cmd = combatQueue and combatQueue() or ""
  cmd = cmd .. blademaster.buildComboBrokenstar()
  blademaster.sendAttack(cmd)
end

-- Aliases for Brokenstar (thin wrappers → unified dispatch)
function bmbs()
  blademaster.warnModeFlap("brokenstar")
  blademaster.state.mode = "brokenstar"
  blademaster.markManual()
  blademaster.run()
end

function bmdispatchbs()
  blademaster.warnModeFlap("brokenstar")
  blademaster.state.mode = "brokenstar"
  blademaster.markManual()
  blademaster.run()
end

-- Reset all state
function bmreset()
  blademaster.fullReset()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  STRATEGY 4: GROUP (POMMELSTRIKE LOCK)
--
--  Priority:
--  1. Hamstring (hamstring)
--  2. Paralysis (neck)
--  3. Asthma (throat)
--  4. If asthma: Slickness (underarm)
--  5. If impatience+slickness: Anorexia (stomach), else skip to #6
--  6. getLockingAffliction() class aff
--  7. Hypochondria (chest)
--  8. Sternum (damage / maintain lock)
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Map getLockingAffliction() return values to pommelstrike strikes
blademaster.lockAffToStrike = {
  paralyse    = "neck",
  weariness   = "shoulder",
  plague      = "eyes",
  stupid      = "temple",
  reckless    = "groin",
}

function blademaster.selectStrikeGroup()
  local has = blademaster.hasAff

  -- 1. Hamstring
  if not has("hamstring") then
    return "hamstring"
  end

  -- 2. Paralysis
  if not has("paralysis") then
    return "neck"
  end

  -- 3. Asthma
  if not has("asthma") then
    return "throat"
  end

  -- 4. Slickness (gated behind asthma)
  if not has("slickness") then
    return "underarm"
  end

  -- 5. Anorexia (gated behind impatience + slickness)
  if has("impatience") and has("slickness") and not has("anorexia") then
    return "stomach"
  end

  -- 6. Class locking affliction
  if getLockingAffliction then
    local lockAff = getLockingAffliction()
    if lockAff then
      local strike = blademaster.lockAffToStrike[lockAff]
      if strike then
        -- Check the actual affliction name (map getLockingAffliction names to aff names)
        local affName = ({
          paralyse = "paralysis", weariness = "weariness", plague = "plague",
          stupid = "stupidity", reckless = "recklessness",
        })[lockAff] or lockAff
        if not has(affName) then
          return strike
        end
      end
    end
  end

  -- 7. Hypochondria
  if not has("hypochondria") then
    return "chest"
  end

  -- 8. All lock affs present — sternum for damage
  return "sternum"
end

function blademaster.buildComboGroup()
  local combo = ""

  -- V1 fallback for rebounding/shield (GMCP timing gap)
  if blademaster.hasAff("shield") or blademaster.hasAff("rebounding") or (tAffs and (tAffs.shield or tAffs.rebounding)) then
    local strike = blademaster.selectStrikeGroup()
    combo = "raze " .. target
    if strike then
      combo = combo .. " " .. strike
    end
    combo = combo .. ";assess " .. target
    return combo
  end

  local strike = blademaster.selectStrikeGroup()
  combo = blademaster.infuseCmd("ice") .. "pommelstrike " .. target .. " " .. strike .. ";assess " .. target
  return combo
end

function blademaster.dispatch.runGroup()
  local targetHP = tonumber(ataxiaTemp.targetHP) or 100
  local strike = blademaster.selectStrikeGroup()

  -- Debounced echo
  if blademaster.shouldEcho() then
    cecho("\n<cyan>[BM <magenta>Group<cyan>] Target: " .. tostring(target) .. " | HP: " .. targetHP .. "% | Track: " .. blademaster.getTrackingSystem())
    cecho("\n<cyan>[BM <magenta>Group<cyan>] Strike: <yellow>" .. strike .. "<cyan> | Pommelstrike + Ice")

    -- Show lock status
    local has = blademaster.hasAff
    local function affTag(aff, label)
      return (has(aff) and "<green>" or "<red>") .. label
    end
    cecho("\n<cyan>[BM <magenta>Group<cyan>] " ..
      affTag("paralysis", "PAR") .. " " ..
      affTag("asthma", "AST") .. " " ..
      affTag("slickness", "SLI") .. " " ..
      affTag("anorexia", "ANO") .. " " ..
      affTag("impatience", "IMP") .. " " ..
      affTag("hypochondria", "HYP"))
  end

  -- Build and send
  local cmd = combatQueue and combatQueue() or ""
  cmd = cmd .. blademaster.buildComboGroup()
  blademaster.sendAttack(cmd)
end

-- Aliases for Group
function bmgroup()
  blademaster.warnModeFlap("group")
  blademaster.state.mode = "group"
  blademaster.markManual()
  blademaster.run()
end

--------------------------------------------------------------------------------
-- STATUS DISPLAYS
--------------------------------------------------------------------------------

function blademaster.dispatch.statusDoublePrep()
  tAffs = tAffs or {}
  ataxiaTemp = ataxiaTemp or {}

  local phase = blademaster.getPhaseDoublePrep()
  local phaseLabel = blademaster.getPhaseLabelDoublePrep()
  local targetHP = tonumber(ataxiaTemp.targetHP) or 100

  local function progressBar(pct, width)
    width = width or 10
    local filled = math.floor((pct / 100) * width)
    if filled > width then filled = width end
    local empty = width - filled
    return string.rep("#", filled) .. string.rep("-", empty)
  end

  local LL, RL = blademaster.getLL(), blademaster.getRL()
  local threshold = blademaster.config.prepThreshold

  cecho("\n<cyan>+============================================+")
  cecho("\n<cyan>|     <white>BLADEMASTER DOUBLE-PREP (LEGS)<cyan>        |")
  cecho("\n<cyan>+============================================+")
  cecho("\n<cyan>| <white>Target: <yellow>" .. tostring(target or "None") .. " <grey>(HP: " .. targetHP .. "%)<cyan>")
  cecho("\n<cyan>| <white>Phase: " .. phaseLabel .. " <grey>| Track: " .. blademaster.getTrackingSystem() .. "<cyan>")
  cecho("\n<cyan>+--------------------------------------------+")
  cecho("\n<cyan>| <white>LEG STATUS:<cyan>")
  cecho("\n<cyan>|   <white>L Leg: " .. (LL >= 100 and "<green>BROKEN " or (LL >= threshold and "<yellow>READY  " or "<red>       ")) .. string.format("%5.1f%%", LL) .. " [" .. progressBar(LL) .. "]")
  cecho("\n<cyan>|   <white>R Leg: " .. (RL >= 100 and "<green>BROKEN " or (RL >= threshold and "<yellow>READY  " or "<red>       ")) .. string.format("%5.1f%%", RL) .. " [" .. progressBar(RL) .. "]")
  cecho("\n<cyan>+--------------------------------------------+")
  cecho("\n<cyan>| <white>STRATEGY:<cyan>")
  cecho("\n<cyan>|   <grey>1. LEG PREP: Legslash alternating (Lightning)")
  cecho("\n<cyan>|   <grey>2. LEG BREAK: Double-break legs + KNEES (Ice)")
  cecho("\n<cyan>|   <grey>3. MANGLE: Legslash right + STERNUM (Ice)")
  cecho("\n<cyan>+============================================+\n")
end

function blademaster.dispatch.statusQuadPrep()
  tAffs = tAffs or {}
  ataxiaTemp = ataxiaTemp or {}

  local phase = blademaster.getPhaseQuadPrep()
  local phaseLabel = blademaster.getPhaseLabelQuadPrep()
  local targetHP = tonumber(ataxiaTemp.targetHP) or 100

  local function progressBar(pct, width)
    width = width or 10
    local filled = math.floor((pct / 100) * width)
    if filled > width then filled = width end
    local empty = width - filled
    return string.rep("#", filled) .. string.rep("-", empty)
  end

  local LA, RA = blademaster.getLA(), blademaster.getRA()
  local LL, RL = blademaster.getLL(), blademaster.getRL()
  local threshold = blademaster.config.prepThreshold

  cecho("\n<cyan>+============================================+")
  cecho("\n<cyan>|     <white>BLADEMASTER QUAD-PREP (ARMS+LEGS)<cyan>     |")
  cecho("\n<cyan>+============================================+")
  cecho("\n<cyan>| <white>Target: <yellow>" .. tostring(target or "None") .. " <grey>(HP: " .. targetHP .. "%)<cyan>")
  cecho("\n<cyan>| <white>Phase: " .. phaseLabel .. " <grey>| Track: " .. blademaster.getTrackingSystem() .. "<cyan>")
  cecho("\n<cyan>+--------------------------------------------+")
  cecho("\n<cyan>| <white>ARM STATUS:<cyan>")
  cecho("\n<cyan>|   <white>L Arm: " .. (LA >= 100 and "<green>BROKEN " or (LA >= threshold and "<yellow>READY  " or "<red>       ")) .. string.format("%5.1f%%", LA) .. " [" .. progressBar(LA) .. "]")
  cecho("\n<cyan>|   <white>R Arm: " .. (RA >= 100 and "<green>BROKEN " or (RA >= threshold and "<yellow>READY  " or "<red>       ")) .. string.format("%5.1f%%", RA) .. " [" .. progressBar(RA) .. "]")
  cecho("\n<cyan>+--------------------------------------------+")
  cecho("\n<cyan>| <white>LEG STATUS:<cyan>")
  cecho("\n<cyan>|   <white>L Leg: " .. (LL >= 100 and "<green>BROKEN " or (LL >= threshold and "<yellow>READY  " or "<red>       ")) .. string.format("%5.1f%%", LL) .. " [" .. progressBar(LL) .. "]")
  cecho("\n<cyan>|   <white>R Leg: " .. (RL >= 100 and "<green>BROKEN " or (RL >= threshold and "<yellow>READY  " or "<red>       ")) .. string.format("%5.1f%%", RL) .. " [" .. progressBar(RL) .. "]")
  cecho("\n<cyan>+--------------------------------------------+")
  cecho("\n<cyan>| <white>STRATEGY (Ice Path):<cyan>")
  cecho("\n<cyan>|   <grey>1. ARM PREP: Armslash alternating (Lightning)")
  cecho("\n<cyan>|   <grey>2. LEG PREP: Legslash alternating (Lightning)")
  cecho("\n<cyan>|   <grey>3. FLAMEFIST: Negate rebounding before breaks")
  cecho("\n<cyan>|   <grey>4. ARM BREAK: Double-break arms (Ice)")
  cecho("\n<cyan>|   <grey>5. LEG BREAK: Double-break legs + KNEES, RIGHT (Ice)")
  cecho("\n<cyan>|   <grey>6. MANGLE: Legslash RIGHT + STERNUM (Ice)")
  cecho("\n<cyan>+============================================+\n")
end

-- Status aliases
function bmstatus()
  blademaster.dispatch.statusDoublePrep()
end

function bmstatusq()
  blademaster.dispatch.statusQuadPrep()
end

--------------------------------------------------------------------------------
-- PRONE TIMER (Double-Prep balanceslash mechanic)
--------------------------------------------------------------------------------

function blademaster.resetProneTimer()
  blademaster.state.proneTimerStart = nil
  blademaster.state.proneAttackCount = 0
  blademaster.state.proneTimerActive = false
end

function blademaster.onLegSalveDetected()
  -- Only start timer if both legs broken AND target is prone
  if not blademaster.checkBothLegsBroken() then return end
  if not blademaster.hasAff("prone") then return end

  -- Only start if not already active
  if not blademaster.state.proneTimerActive then
    blademaster.state.proneTimerStart = os.time()
    blademaster.state.proneAttackCount = 0
    blademaster.state.proneTimerActive = true
    cecho("\n<magenta>[BM] Prone timer started - 9 second window, switching to BALANCESLASH on attack #4")
  end
end

--------------------------------------------------------------------------------
-- DAMAGE TRACKING
--------------------------------------------------------------------------------

blademaster.damageCapture = {
  pendingPrimary = nil,
  pendingLimb = nil,
  pendingType = nil,
  lastCaptureTime = 0,
}

function blademaster.onHamstringApplied()
  blademaster.state.lastHamstringTime = os.time()
end

function blademaster.captureLegDamage(damage, side)
  damage = tonumber(damage) or 0
  local now = os.time()

  if blademaster.damageCapture.pendingPrimary and
     blademaster.damageCapture.pendingType == "leg" and
     (now - blademaster.damageCapture.lastCaptureTime) < 2 then
    blademaster.state.legSecondaryDamage = damage
    blademaster.state.legPrimaryDamage = blademaster.damageCapture.pendingPrimary
    blademaster.state.lastPrimaryLeg = blademaster.damageCapture.pendingLimb
    blademaster.damageCapture.pendingPrimary = nil
    blademaster.damageCapture.pendingLimb = nil
    blademaster.damageCapture.pendingType = nil
  else
    blademaster.damageCapture.pendingPrimary = damage
    blademaster.damageCapture.pendingLimb = side
    blademaster.damageCapture.pendingType = "leg"
    blademaster.damageCapture.lastCaptureTime = now
  end
end

function blademaster.captureArmDamage(damage, side)
  damage = tonumber(damage) or 0
  local now = os.time()

  if blademaster.damageCapture.pendingPrimary and
     blademaster.damageCapture.pendingType == "arm" and
     (now - blademaster.damageCapture.lastCaptureTime) < 2 then
    blademaster.state.armSecondaryDamage = damage
    blademaster.state.armPrimaryDamage = blademaster.damageCapture.pendingPrimary
    blademaster.state.lastPrimaryArm = blademaster.damageCapture.pendingLimb
    blademaster.damageCapture.pendingPrimary = nil
    blademaster.damageCapture.pendingLimb = nil
    blademaster.damageCapture.pendingType = nil
  else
    blademaster.damageCapture.pendingPrimary = damage
    blademaster.damageCapture.pendingLimb = side
    blademaster.damageCapture.pendingType = "arm"
    blademaster.damageCapture.lastCaptureTime = now
  end
end

function blademaster.captureUpperDamage(damage, limb)
  -- Centreslash hits torso and head with DIFFERENT damage values
  -- Torso gets more damage (primary), head gets less (secondary)
  damage = tonumber(damage) or 0
  if limb == "torso" then
    blademaster.state.torsoDamage = damage
  elseif limb == "head" then
    blademaster.state.headDamage = damage
  end
end

-- Brokenstar trigger callbacks
function blademaster.onImpaleSuccess()
  -- ALWAYS set isImpaled = true when we impale (first, re-impale, any impale)
  local wasImpaled = blademaster.state.isImpaled
  blademaster.state.isImpaled = true

  -- Track if this is a re-impale (impaleslash already done = skip to bladetwist)
  if blademaster.state.impaleslashDone then
    cecho("\n<green>[BM] RE-IMPALE confirmed! Continuing bladetwists...")
  elseif not wasImpaled then
    cecho("\n<cyan>[BM] First impale confirmed!")
  end
end

function blademaster.onImpaleslashSuccess()
  blademaster.state.impaleslashDone = true
  blademaster.state.bladetwistCount = 0  -- Reset count for new bladetwist cycle
  cecho("\n<magenta>[BM] Impaleslash confirmed - arteries slashed!")
end

function blademaster.onBleedingReady()
  blademaster.state.bleedingReady = true
  cecho("\n<green>[BM] BLEEDING AT 700+ - BROKENSTAR READY!")
end

function blademaster.onBleedingUpdate(bleedValue)
  bleedValue = tonumber(bleedValue) or 0
  blademaster.state.targetBleeding = bleedValue
  -- Also set bleedingReady if we hit 700+
  if bleedValue >= 700 then
    blademaster.state.bleedingReady = true
  end
end

function blademaster.onTargetUnimpaled()
  -- Target escaped impale - need to re-impale before bladetwist
  -- If prone: FREE RE-IMPALE - they can't dodge while prone (regardless of leg status!)
  -- If standing + legs broken: Can re-impale
  -- If standing + legs healed: Back to leg prep

  blademaster.state.isImpaled = false
  blademaster.state.withdrawDone = false
  -- Keep bleedingReady and targetBleeding - we built that progress!
  -- Keep impaleslashDone = true so we skip impaleslash after re-impale

  local targetProne = blademaster.hasAff("prone")
  local legsBroken = blademaster.checkBothLegsBroken()

  -- Can re-impale if prone OR both legs broken
  if targetProne then
    cecho("\n<green>[BM] Target writhed free but STILL PRONE - FREE RE-IMPALE!")
    -- Phase will go to impale (canImpale = prone)
  elseif legsBroken then
    cecho("\n<red>[BM] Target writhed free and standing - RE-IMPALE! (legs still broken)")
    -- Phase will go to impale (canImpale = legsBroken)
  else
    cecho("\n<red>[BM] Target writhed free and standing - back to leg prep")
    -- Reset bleeding and impaleslash since we have to restart completely
    blademaster.state.impaleslashDone = false
    blademaster.state.bleedingReady = false
    blademaster.state.targetBleeding = 0
  end
end

function blademaster.onWithdrawSuccess()
  blademaster.state.withdrawDone = true
  blademaster.state.isImpaled = false  -- No longer impaled after withdraw
  cecho("\n<yellow>[BM] Blade withdrawn - BROKENSTAR READY!")
end

function blademaster.onBladetwistSuccess()
  -- Increment count only when bladetwist actually fires (not on button spam)
  blademaster.state.bladetwistCount = blademaster.state.bladetwistCount + 1
end

function blademaster.onTargetStandUp(who)
  -- Only care if it's our target and we were in brokenstar route
  if who == target and blademaster.state.impaleslashDone then
    local bleedColor = blademaster.state.targetBleeding >= 700 and "<green>" or "<yellow>"
    cecho("\n<yellow>[BM] Target stood up! Bleed: " .. bleedColor .. blademaster.state.targetBleeding .. "<yellow> | Twists: " .. blademaster.state.bladetwistCount)
  end
end

function blademaster.registerDamageTriggers()
  if tempRegexTrigger then
    -- Kill existing triggers
    if blademaster.legDamageTriggerID then
      killTrigger(blademaster.legDamageTriggerID)
    end
    if blademaster.armDamageTriggerID then
      killTrigger(blademaster.armDamageTriggerID)
    end
    if blademaster.upperDamageTriggerID then
      killTrigger(blademaster.upperDamageTriggerID)
    end
    if blademaster.legSalveTriggerID then
      killTrigger(blademaster.legSalveTriggerID)
    end
    if blademaster.impaleTriggerID then
      killTrigger(blademaster.impaleTriggerID)
    end
    if blademaster.impaleslashTriggerID then
      killTrigger(blademaster.impaleslashTriggerID)
    end
    if blademaster.bleedingReadyTriggerID then
      killTrigger(blademaster.bleedingReadyTriggerID)
    end
    if blademaster.withdrawTriggerID then
      killTrigger(blademaster.withdrawTriggerID)
    end
    if blademaster.writheTriggerID then
      killTrigger(blademaster.writheTriggerID)
    end
    if blademaster.bleedingUpdateTriggerID then
      killTrigger(blademaster.bleedingUpdateTriggerID)
    end
    if blademaster.standUpTriggerID then
      killTrigger(blademaster.standUpTriggerID)
    end
    if blademaster.bladetwistTriggerID then
      killTrigger(blademaster.bladetwistTriggerID)
    end

    -- Leg damage trigger
    blademaster.legDamageTriggerID = tempRegexTrigger(
      "^As you carve into .+, you perceive that you have dealt (\\d+\\.?\\d*)% damage to \\w+ (left|right) leg",
      function()
        blademaster.captureLegDamage(matches[2], matches[3])
      end
    )

    -- Arm damage trigger
    blademaster.armDamageTriggerID = tempRegexTrigger(
      "^As you carve into .+, you perceive that you have dealt (\\d+\\.?\\d*)% damage to \\w+ (left|right) arm",
      function()
        blademaster.captureArmDamage(matches[2], matches[3])
      end
    )

    -- Upper body damage trigger (torso/head from centreslash up)
    blademaster.upperDamageTriggerID = tempRegexTrigger(
      "^As you carve into .+, you perceive that you have dealt (\\d+\\.?\\d*)% damage to \\w+ (torso|head)",
      function()
        blademaster.captureUpperDamage(matches[2], matches[3])
      end
    )

    -- Leg salve trigger (starts prone timer for balanceslash mechanic)
    -- Pattern matches: "takes some salve from a vial and rubs it on his/her/faes/its legs"
    blademaster.legSalveTriggerID = tempRegexTrigger(
      "takes some salve from a vial and rubs it on \\w+ legs",
      function()
        blademaster.onLegSalveDetected()
      end
    )

    -- Brokenstar triggers
    -- Impale success: "You draw your blade back and plunge it deep into the body of <target> impaling <pronoun> to the hilt."
    blademaster.impaleTriggerID = tempRegexTrigger(
      "^You draw your blade back and plunge it deep into the body of ([\\w'\\-]+) impaling [\\w'\\-]+ to the hilt\\.$",
      function()
        blademaster.onImpaleSuccess()
      end
    )

    -- Impaleslash success: "steady in your grip, you drag its razor edge across arteries within <target>'s abdomen"
    blademaster.impaleslashTriggerID = tempRegexTrigger(
      "steady in your grip, you drag its razor edge across arteries within ([\\w'\\-]+)'s abdomen\\.$",
      function()
        blademaster.onImpaleslashSuccess()
      end
    )

    -- Bleeding ready (700+): "You observe heavy torrents of lifeblood spilling from <target>'s near-fatal wounds."
    blademaster.bleedingReadyTriggerID = tempRegexTrigger(
      "^You observe heavy torrents of lifeblood spilling from ([\\w'\\-]+)'s near-fatal wounds\\.$",
      function()
        blademaster.onBleedingReady()
      end
    )

    -- Withdraw success: Need a pattern for when blade is withdrawn
    -- TODO: Add the correct withdraw pattern when known
    blademaster.withdrawTriggerID = tempRegexTrigger(
      "^You wrench your blade free of ([\\w'\\-]+)",
      function()
        blademaster.onWithdrawSuccess()
      end
    )

    -- Writhe escape: "manages to writhe faenself free of the weapon which impaled faen"
    blademaster.writheTriggerID = tempRegexTrigger(
      "manages to writhe \\w+self free of the weapon which impaled",
      function()
        blademaster.onTargetUnimpaled()
      end
    )

    -- Bleeding update: "You observe ... [280]" - captures actual bleeding value
    -- Patterns: "sluggish bleeding" [<400], "rivers of blood" [400-699], "heavy torrents" [700-899], "shortly bleed to death" [900+]
    blademaster.bleedingUpdateTriggerID = tempRegexTrigger(
      "You observe .+ \\[(\\d+)\\]",
      function()
        blademaster.onBleedingUpdate(matches[2])
      end
    )

    -- Target stands up: "Mystor stands up." - discern to check bleeding
    blademaster.standUpTriggerID = tempRegexTrigger(
      "^([\\w]+) stands up\\.$",
      function()
        blademaster.onTargetStandUp(matches[2])
      end
    )

    -- Bladetwist success: Increment count when bladetwist actually fires
    -- Pattern: "[|] [|] [|] BLADETWIST [|] BLADETWIST [|] BLADETWIST [|] [|] [|]"
    blademaster.bladetwistTriggerID = tempRegexTrigger(
      "BLADETWIST \\[\\|\\] BLADETWIST \\[\\|\\] BLADETWIST",
      function()
        blademaster.onBladetwistSuccess()
      end
    )

    cecho("\n<green>[BM] Triggers registered (leg/arm/upper damage + leg salve + brokenstar + writhe + bleeding + standUp + bladetwist)!")
  else
    cecho("\n<yellow>[BM] tempRegexTrigger not available - create triggers manually")
  end
end

blademaster.registerDamageTriggers()

--------------------------------------------------------------------------------
-- GMCP BALANCE HANDLER (DWC pattern: clears attackInFlight on balance return)
--------------------------------------------------------------------------------

if blademaster._balHandler then
  killAnonymousEventHandler(blademaster._balHandler)
end
blademaster._balHandler = registerAnonymousEventHandler("gmcp.Char.Vitals", function()
  if gmcp.Char.Vitals.bal == "1" then
    blademaster.state.attackInFlight = false
  end
end)

--------------------------------------------------------------------------------
-- INLINE ALIAS REGISTRATION (Shaman pattern: tempAlias with cleanup on reload)
--------------------------------------------------------------------------------

if blademaster._aliases then
  for _, id in pairs(blademaster._aliases) do
    if id and killAlias then
      pcall(killAlias, id)
    end
  end
end
blademaster._aliases = {}

if tempAlias then
  -- v4.7.275: these delegate to the named functions instead of re-implementing them, so the
  -- markManual() stamp that drives blademaster.retryTick cannot be missed by whichever entry
  -- point the user happens to have bound.
  blademaster._aliases.bmd = tempAlias("^bmd$", function() bmd() end)

  blademaster._aliases.bmdq = tempAlias("^bmdq$", function() bmdq() end)

  blademaster._aliases.bmbs = tempAlias("^bmbs$", function() bmbs() end)

  blademaster._aliases.bmgroup = tempAlias("^bmgroup$", function() bmgroup() end)

  blademaster._aliases.bmreset = tempAlias("^bmreset$", function()
    blademaster.fullReset()
  end)

  blademaster._aliases.bmretry = tempAlias("^bmretry(?: (on|off|\\d+))?$", function()
    local arg = matches[2]
    if arg == "on" then
      blademaster.state.autoRetry = true
    elseif arg == "off" then
      blademaster.state.autoRetry = false
      blademaster.state.lastManualAt = nil
    elseif tonumber(arg) then
      blademaster.config.retryWindow = tonumber(arg)
    else
      blademaster.state.autoRetry = not blademaster.state.autoRetry
      if not blademaster.state.autoRetry then blademaster.state.lastManualAt = nil end
    end
    cecho("\n<cyan>[BM]<reset> Prompt retry: "
      .. (blademaster.state.autoRetry and "<green>ON" or "<red>OFF")
      .. "<reset> (window " .. blademaster.config.retryWindow .. "s)")
  end)

  blademaster._aliases.bmstatus = tempAlias("^bmstatus$", function()
    blademaster.dispatch.statusDoublePrep()
  end)

  blademaster._aliases.bmstatusq = tempAlias("^bmstatusq$", function()
    blademaster.dispatch.statusQuadPrep()
  end)
end

cecho("\n<green>[BM] Blademaster Dispatch loaded<reset> (mode: " .. blademaster.state.mode .. ")")
