--[[
================================================================================
SHIKUDO RIFTLOCK OFFENSE SYSTEM
================================================================================

Based on Mystor's advanced Shikudo combat strategies.

CONCEPT: Use blackout to hide a devastating burst combo that sets up a lock.
The opponent CANNOT SEE what happens during blackout - no combat messages at all.

RIFTLOCK EXECUTION:
  1. Build 9+ kata in Rain
  2. Prep both arms (ruku for clumsiness)
  3. BLACKOUT (opponent goes blind)
  4. Mind PARALYSE (stops parry - they don't know!)
  5. Frontkick + Kuro + Ruku burst (all hidden)
  6. Transition to Oak with massive affliction stack
  7. Continue with asthma/slickness/impatience for lock

RESULT STATE AFTER BURST:
  - Limbs: LA damaged, RA damaged, RL damaged
  - Afflictions: clumsiness, healthleech, weariness, lethargy, paralysis
  - Opponent has NO IDEA what hit them

OAK CONTINUATION:
  - Asthma via livestrike (buried in kelp stack)
  - Slickness via ruku torso
  - Paralysis via nervestrike
  - Mind impatience for hardlock
  - Weariness maintained via kuro

SYNERGIES:
  - Telepathy is FASTER in Rain stance
  - Blackout hides ALL combat messages from opponent
  - Frontkick can prone (confusion via hiru if already prone)
  - Kai Surge is faster in Rain (for mounted targets)

================================================================================
]]--

shikudoRiftLock = shikudoRiftLock or {}
shikudoRiftLock.state = {
  phase = "OAK_SETUP",  -- OAK_SETUP, RAIN_PREP, BLACKOUT_BURST, OAK_CONTINUATION, LOCK_PRESSURE
  lastBlackout = 0,     -- Timestamp of last blackout
  blackoutActive = false, -- Are we in blackout window?
  burstReady = false,   -- Ready to execute burst?
  armsPrepped = false,  -- Both arms have damage?
}

-- Note: Uses global 'mindlocked' variable (set in 099_Login_Function.lua)

-- Max kata per form before stumble
shikudoRiftLock.maxKata = {
  Tykonos = 12,
  Willow = 12,
  Rain = 24,  -- Double chain - perfect for burst setup
  Oak = 12,
  Gaital = 12,
  Maelstrom = 12
}

-- Afflictions delivered by each attack
shikudoRiftLock.attackAffs = {
  -- Staff attacks
  kuro = {"weariness", "lethargy"},
  ruku_arm = {"clumsiness"},
  ruku_torso = {"slickness"},
  livestrike = {"asthma"},
  nervestrike = {"paralysis"},
  hiru = {"dizziness"},  -- confusion if prone
  hiraku = {"anorexia", "stuttering"},
  jinzuku = {"addiction"},
  -- Telepathy
  blackout = {"blackout"},
  paralyse = {"paralysis"},
  impatience = {"impatience"},
  batter = {"stupidity", "epilepsy", "dizziness"},
}

--------------------------------------------------------------------------------
-- LOCK CONDITION CHECKS (same as standard lock system)
--------------------------------------------------------------------------------

function shikudoRiftLock.checkSoftlock()
  return tAffs.asthma and tAffs.anorexia and tAffs.slickness
end

function shikudoRiftLock.checkVenomlock()
  return shikudoRiftLock.checkSoftlock() and tAffs.paralysis
end

function shikudoRiftLock.checkHardlock()
  return shikudoRiftLock.checkVenomlock() and tAffs.impatience
end

function shikudoRiftLock.checkTruelock()
  return shikudoRiftLock.checkHardlock() and tAffs.weariness
end

--------------------------------------------------------------------------------
-- RIFTLOCK-SPECIFIC CHECKS
--------------------------------------------------------------------------------

function shikudoRiftLock.getArmDamage(arm)
  if not target or not lb or not lb[target] or not lb[target].hits then
    return 0
  end
  local limbName = arm .. " arm"
  return lb[target].hits[limbName] or 0
end

function shikudoRiftLock.getLegDamage(leg)
  if not target or not lb or not lb[target] or not lb[target].hits then
    return 0
  end
  local limbName = leg .. " leg"
  return lb[target].hits[limbName] or 0
end

function shikudoRiftLock.areBothArmsPrepped()
  -- Arms are "prepped" when they have some damage for clumsiness stack
  -- Don't need to break them, just need damage for affliction delivery
  local la = shikudoRiftLock.getArmDamage("left")
  local ra = shikudoRiftLock.getArmDamage("right")
  return (la >= 15 and ra >= 15)  -- ~2 ruku hits each
end

function shikudoRiftLock.isReadyForBurst()
  local kata = ataxia.vitals.kata or 0
  local form = ataxia.vitals.form or "Oak"

  -- Need 9+ kata in Rain for double kuro/ruku burst
  if form ~= "Rain" then return false end
  if kata < 9 then return false end

  -- Need mindlock established
  if not mindlocked then return false end

  return true
end

function shikudoRiftLock.canBlackout()
  -- Check if we have EQ for telepathy
  if not ataxia.balances.eq then return false end

  -- Check cooldown (blackout has internal cooldown)
  local now = os.time()
  if (now - shikudoRiftLock.state.lastBlackout) < 10 then
    return false
  end

  return true
end

--------------------------------------------------------------------------------
-- PHASE DETECTION AND UPDATE
--------------------------------------------------------------------------------

function shikudoRiftLock.updatePhase()
  local form = ataxia.vitals.form or "Oak"
  local kata = ataxia.vitals.kata or 0

  -- Check lock progress
  if shikudoRiftLock.checkTruelock() then
    shikudoRiftLock.state.phase = "LOCK_PRESSURE"
    return
  end

  -- If in blackout burst window
  if shikudoRiftLock.state.blackoutActive then
    shikudoRiftLock.state.phase = "BLACKOUT_BURST"
    return
  end

  -- Phase based on form and conditions
  if form == "Rain" then
    if shikudoRiftLock.isReadyForBurst() and shikudoRiftLock.canBlackout() then
      shikudoRiftLock.state.phase = "BLACKOUT_BURST"
    else
      shikudoRiftLock.state.phase = "RAIN_PREP"
    end
  elseif form == "Oak" then
    -- Check if we're in continuation (after burst) or setup (before)
    if tAffs.weariness and tAffs.clumsiness then
      shikudoRiftLock.state.phase = "OAK_CONTINUATION"
    else
      shikudoRiftLock.state.phase = "OAK_SETUP"
    end
  else
    -- Other forms - route to Oak or Rain
    shikudoRiftLock.state.phase = "OAK_SETUP"
  end
end

function shikudoRiftLock.getPhaseColor()
  local phase = shikudoRiftLock.state.phase
  if phase == "BLACKOUT_BURST" then return "<red>"
  elseif phase == "LOCK_PRESSURE" then return "<green>"
  elseif phase == "OAK_CONTINUATION" then return "<yellow>"
  elseif phase == "RAIN_PREP" then return "<cyan>"
  else return "<white>"
  end
end

--------------------------------------------------------------------------------
-- FORM TRANSITION LOGIC
--------------------------------------------------------------------------------

function shikudoRiftLock.shouldTransition()
  local form = ataxia.vitals.form or "Oak"
  local kata = ataxia.vitals.kata or 0
  local phase = shikudoRiftLock.state.phase

  if kata < 5 then
    return nil  -- Need at least 5 kata to transition
  end

  -- OAK_SETUP: Build hindrance (par/clumsy), then go to Rain when ready
  if phase == "OAK_SETUP" and form == "Oak" then
    -- Stay in Oak until we have good affliction pressure
    if tAffs.paralysis and tAffs.clumsiness then
      -- Ready to go to Rain for burst setup
      if kata >= 5 then
        return "Willow"  -- Oak -> Willow -> Rain
      end
    end
    -- Near kata limit, cycle to Willow
    if kata >= 9 then
      return "Willow"
    end
    return nil
  end

  -- WILLOW: Just passing through to Rain
  if form == "Willow" then
    if kata >= 5 then
      return "Rain"
    end
    return nil
  end

  -- RAIN_PREP: Stay until ready for burst
  if phase == "RAIN_PREP" and form == "Rain" then
    -- Rain has 24 kata - plenty of room
    if kata >= 21 then
      return "Oak"  -- Safety transition
    end
    -- Stay in Rain for burst setup
    return nil
  end

  -- After burst, transition to Oak for continuation
  if phase == "BLACKOUT_BURST" or shikudoRiftLock.state.blackoutActive then
    if form == "Rain" and kata >= 5 then
      return "Oak"  -- Go to Oak for continuation
    end
  end

  -- OAK_CONTINUATION: Stay and apply lock pressure
  if phase == "OAK_CONTINUATION" and form == "Oak" then
    if kata >= 9 then
      return "Willow"  -- Cycle if stuck
    end
    return nil
  end

  -- LOCK_PRESSURE: Stay in current form for damage
  if phase == "LOCK_PRESSURE" then
    if kata >= 9 then
      if form == "Oak" then return "Gaital" end
      if form == "Gaital" then return "Rain" end
      if form == "Rain" then return "Oak" end
    end
    return nil
  end

  -- Route other forms toward Oak
  if form == "Tykonos" then return "Willow" end
  if form == "Gaital" then return "Rain" end
  if form == "Maelstrom" then return "Oak" end

  return nil
end

--------------------------------------------------------------------------------
-- KICK SELECTION
--------------------------------------------------------------------------------

function shikudoRiftLock.selectKick()
  local form = ataxia.vitals.form or "Oak"
  local phase = shikudoRiftLock.state.phase

  if form == "Rain" then
    -- FRONTKICK targets arms - can prone on hit
    -- Alternate arms to spread clumsiness
    local lastArm = ataxiaTemp.lastFrontkickArm or "left"
    local la = shikudoRiftLock.getArmDamage("left")
    local ra = shikudoRiftLock.getArmDamage("right")

    -- Hit the arm with less damage
    if la <= ra then
      ataxiaTemp.lastFrontkickArm = "left"
      return "frontkick left"
    else
      ataxiaTemp.lastFrontkickArm = "right"
      return "frontkick right"
    end

  elseif form == "Oak" then
    -- RISINGKICK - head for damage, torso if head vulnerable
    if tAffs.prone then
      return "risingkick head"  -- Stuns if prone
    end
    return "risingkick head"

  elseif form == "Willow" then
    -- FLASHHEEL - leg damage (passing through form)
    return "flashheel left"

  elseif form == "Gaital" then
    -- SPINKICK on prone, FLASHHEEL otherwise
    if tAffs.prone then
      return "spinkick"
    end
    return "flashheel left"

  elseif form == "Maelstrom" then
    return "risingkick head"

  else -- Tykonos
    return "risingkick torso"
  end
end

--------------------------------------------------------------------------------
-- STAFF SELECTION
--------------------------------------------------------------------------------

function shikudoRiftLock.selectStaff(slot)
  local form = ataxia.vitals.form or "Oak"
  local phase = shikudoRiftLock.state.phase

  if form == "Oak" then
    return shikudoRiftLock.selectOakStaff(slot)
  elseif form == "Rain" then
    return shikudoRiftLock.selectRainStaff(slot)
  elseif form == "Willow" then
    return shikudoRiftLock.selectWillowStaff(slot)
  elseif form == "Gaital" then
    return shikudoRiftLock.selectGaitalStaff(slot)
  elseif form == "Maelstrom" then
    return shikudoRiftLock.selectMaelstromStaff(slot)
  else
    return "thrust torso"
  end
end

function shikudoRiftLock.selectOakStaff(slot)
  local phase = shikudoRiftLock.state.phase

  -- OAK_SETUP: Focus on paralysis + clumsiness for hindrance
  if phase == "OAK_SETUP" then
    if slot == 1 then
      -- NERVESTRIKE first for paralysis (prevents parry!)
      if not tAffs.paralysis then
        return "nervestrike"
      elseif not tAffs.clumsiness then
        return "ruku left"
      elseif not tAffs.asthma then
        return "livestrike"
      else
        return "nervestrike"  -- Maintain para
      end
    else
      -- Second slot: more hindrance
      if not tAffs.clumsiness then
        return "ruku right"
      elseif not tAffs.weariness then
        return "kuro left"
      elseif not tAffs.slickness then
        return "ruku torso"
      else
        return "kuro right"
      end
    end
  end

  -- OAK_CONTINUATION: Apply lock afflictions
  if phase == "OAK_CONTINUATION" then
    if slot == 1 then
      -- Priority: asthma > slickness > paralysis
      if not tAffs.asthma then
        return "livestrike"
      elseif not tAffs.slickness then
        return "ruku torso"
      elseif not tAffs.paralysis then
        return "nervestrike"
      else
        return "nervestrike"  -- Maintain para
      end
    else
      -- Stack more afflictions
      if not tAffs.weariness then
        return "kuro left"
      elseif not tAffs.clumsiness then
        return "ruku right"
      elseif not tAffs.slickness then
        return "ruku torso"
      else
        return "kuro right"
      end
    end
  end

  -- LOCK_PRESSURE: Pure damage
  if phase == "LOCK_PRESSURE" then
    return slot == 1 and "livestrike" or "nervestrike"
  end

  -- Default
  return slot == 1 and "nervestrike" or "kuro left"
end

function shikudoRiftLock.selectRainStaff(slot)
  local phase = shikudoRiftLock.state.phase
  local kata = ataxia.vitals.kata or 0

  -- RAIN_PREP: Build kata with kuro/ruku for affliction burst
  -- Strategy: Double kuro + double ruku at 9/10 kata for massive aff pressure

  if kata >= 9 then
    -- BURST TIME: Double up on affliction attacks
    if slot == 1 then
      if not tAffs.weariness then
        return "kuro left"
      else
        return "ruku left"  -- Clumsiness
      end
    else
      if not tAffs.lethargy then
        return "kuro right"
      else
        return "ruku right"  -- More clumsiness
      end
    end
  end

  -- Building kata: spread attacks for maximum affliction coverage
  if slot == 1 then
    -- Focus leg (lower damage)
    local ll = shikudoRiftLock.getLegDamage("left")
    local rl = shikudoRiftLock.getLegDamage("right")

    if ll <= rl then
      return "kuro left"
    else
      return "kuro right"
    end
  else
    -- Second slot: arms for clumsiness or head for dizziness
    if not tAffs.clumsiness then
      return "ruku left"
    elseif not tAffs.slickness then
      return "ruku torso"
    else
      return "hiru"  -- Dizziness
    end
  end
end

function shikudoRiftLock.selectWillowStaff(slot)
  -- Willow: passing through, focus on anorexia for lock
  if slot == 1 then
    if not tAffs.anorexia then
      return "hiraku"
    else
      return "hiru"
    end
  else
    return "hiraku"
  end
end

function shikudoRiftLock.selectGaitalStaff(slot)
  -- Gaital: damage pressure when locked
  if slot == 1 then
    if not tAffs.slickness then
      return "ruku torso"
    elseif not tAffs.weariness then
      return "kuro left"
    else
      return "needle"
    end
  else
    return "kuro right"
  end
end

function shikudoRiftLock.selectMaelstromStaff(slot)
  -- Maelstrom: affliction maintenance
  if slot == 1 then
    if not tAffs.asthma then
      return "livestrike"
    else
      return "ruku torso"
    end
  else
    return "jinzuku"
  end
end

--------------------------------------------------------------------------------
-- TELEPATHY SELECTION
-- IMPORTANT: Only use Telepathy in RAIN form - we get EQ balance decrease bonus!
--------------------------------------------------------------------------------

function shikudoRiftLock.selectTelepathy()
  local phase = shikudoRiftLock.state.phase
  local form = ataxia.vitals.form or "Oak"
  local kata = ataxia.vitals.kata or 0

  -- Check if we have EQ
  if not ataxia.balances.eq then
    return nil
  end

  -- CRITICAL: Only use Telepathy in RAIN form for the EQ balance bonus!
  -- Exception: mindlock can be established in any form (setup requirement)
  if form ~= "Rain" then
    -- Only establish mindlock outside of Rain (necessary setup)
    if not mindlocked then
      return "mindlock " .. target
    end
    return nil  -- Save all other telepathy for Rain
  end

  -- === IN RAIN FORM - Telepathy is FASTER here! ===

  -- PRIORITY 1: Establish mindlock if not done
  if not mindlocked then
    return "mindlock " .. target
  end

  -- BLACKOUT BURST: This is the key!
  -- When ready in Rain with 9+ kata, BLACKOUT then combo
  if phase == "BLACKOUT_BURST" or (kata >= 9 and shikudoRiftLock.canBlackout()) then
    if not shikudoRiftLock.state.blackoutActive then
      -- Fire blackout!
      shikudoRiftLock.state.lastBlackout = os.time()
      shikudoRiftLock.state.blackoutActive = true
      return "blackout " .. target
    else
      -- Under blackout - PARALYSE to stop parry!
      -- Opponent can't see this - devastating
      if not tAffs.paralysis then
        return "paralyse " .. target
      end
    end
  end

  -- IMPATIENCE for hardlock (when softlocked)
  if shikudoRiftLock.checkSoftlock() and not tAffs.impatience then
    return "impatience " .. target
  end

  -- BATTER for mental pressure
  if shikudoRiftLock.checkSoftlock() then
    return "batter " .. target
  end

  -- PARALYSE as backup
  if not tAffs.paralysis and mindlocked then
    return "paralyse " .. target
  end

  return nil
end

--------------------------------------------------------------------------------
-- COMBO BUILDER
--------------------------------------------------------------------------------

function shikudoRiftLock.buildCombo(transition)
  local form = ataxia.vitals.form or "Oak"
  local kick = shikudoRiftLock.selectKick()
  local staff1 = shikudoRiftLock.selectStaff(1)
  local staff2 = shikudoRiftLock.selectStaff(2)

  local combo = "combo $tar"

  -- OAK: staff first (nervestrike paralysis prevents parry)
  if form == "Oak" then
    if staff1 then combo = combo .. " " .. staff1 end
    if staff2 then combo = combo .. " " .. staff2 end
    if kick then combo = combo .. " " .. kick end
  else
    -- Other forms: kick first
    if kick then combo = combo .. " " .. kick end
    if staff1 then combo = combo .. " " .. staff1 end
    if staff2 then combo = combo .. " " .. staff2 end
  end

  -- Add inline transition
  if transition then
    combo = combo .. " transition " .. transition:lower()
  end

  return combo
end

--------------------------------------------------------------------------------
-- MAIN DISPATCH FUNCTION
--------------------------------------------------------------------------------

function shikudoRiftLock.dispatch()
  -- Initialize globals
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}
  ataxia.balances = ataxia.balances or {}
  ataxia.settings = ataxia.settings or {}
  ataxia.settings.separator = ataxia.settings.separator or ";"
  ataxiaTemp = ataxiaTemp or {}
  tAffs = tAffs or {}

  -- Update phase
  shikudoRiftLock.updatePhase()

  local form = ataxia.vitals.form or "Oak"
  local kata = ataxia.vitals.kata or 0
  local phase = shikudoRiftLock.state.phase
  local phaseColor = shikudoRiftLock.getPhaseColor()

  -- Debug output
  cecho("\n<cyan>[RIFTLOCK] Target: <yellow>" .. tostring(target))
  cecho(" <cyan>| Phase: " .. phaseColor .. phase)
  cecho(" <cyan>| Form: <yellow>" .. form)
  cecho(" <cyan>| Kata: <yellow>" .. kata)

  -- Affliction status
  cecho("\n<cyan>[RIFTLOCK] Affs: ")
  cecho(tAffs.paralysis and "<green>para " or "<red>para ")
  cecho(tAffs.clumsiness and "<green>clumsy " or "<red>clumsy ")
  cecho(tAffs.weariness and "<green>weary " or "<red>weary ")
  cecho(tAffs.asthma and "<green>asthma " or "<red>asthma ")
  cecho(tAffs.slickness and "<green>slick " or "<red>slick ")
  cecho(tAffs.impatience and "<green>impat" or "<red>impat")

  -- Safety check
  if not target or target == "" then
    cecho("\n<red>[RIFTLOCK] No target set! Use: tar <name>")
    return
  end

  -- Handle combatQueue
  local cmd = ""
  if combatQueue then
    cmd = combatQueue()
  end

  -- SHIELD CHECK
  if tAffs.shield then
    local kick = shikudoRiftLock.selectKick()
    cmd = cmd .. "wield staff;combo " .. target .. " shatter " .. kick
    send("queue addclear free " .. cmd)
    return
  end

  -- MOUNTED CHECK - use Kai Surge (faster in Rain!)
  if (tmounted or tAffs.mounted) and form == "Rain" then
    local kai = ataxia.vitals.kai or 0
    if kai >= 31 then
      cmd = cmd .. "kai surge " .. target .. ";"
      cecho("\n<magenta>[RIFTLOCK] KAI SURGE (dismount)")
    end
  end

  -- BUILD ATTACK
  local transition = shikudoRiftLock.shouldTransition()
  local attack = shikudoRiftLock.buildCombo(transition)
  attack = attack:gsub("%$tar", target)

  cmd = cmd .. "wield staff;" .. attack

  -- TELEPATHY INTEGRATION
  local telepathy = shikudoRiftLock.selectTelepathy()
  if telepathy then
    cmd = cmd .. ";" .. telepathy

    -- Special message for blackout
    if telepathy:find("blackout") then
      cecho("\n<red>*** BLACKOUT - OPPONENT CANNOT SEE ***")
    elseif telepathy:find("paralyse") and shikudoRiftLock.state.blackoutActive then
      cecho("\n<red>*** HIDDEN PARALYSE (under blackout) ***")
    else
      cecho("\n<magenta>[RIFTLOCK] Telepathy: " .. telepathy)
    end
  end

  -- Transition notification
  if transition then
    cecho("\n<yellow>[RIFTLOCK] Transitioning to " .. transition)

    -- Clear blackout flag when leaving Rain
    if form == "Rain" and transition == "Oak" then
      shikudoRiftLock.state.blackoutActive = false
    end
  end

  send("queue addclear free " .. cmd)
end

--------------------------------------------------------------------------------
-- STATUS COMMAND
--------------------------------------------------------------------------------

function shikudoRiftLock.status()
  -- Initialize
  tAffs = tAffs or {}
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}

  local form = ataxia.vitals.form or "Unknown"
  local kata = ataxia.vitals.kata or 0
  local maxKata = shikudoRiftLock.maxKata[form] or 12

  -- Update phase
  shikudoRiftLock.updatePhase()
  local phase = shikudoRiftLock.state.phase
  local phaseColor = shikudoRiftLock.getPhaseColor()

  cecho("\n<cyan>â•”â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•—")
  cecho("\n<cyan>â•‘         <white>SHIKUDO RIFTLOCK STATUS<cyan>             â•‘")
  cecho("\n<cyan>â• â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•£")

  cecho("\n<cyan>â•‘ <white>Phase: " .. phaseColor .. phase)
  cecho("\n<cyan>â•‘ <white>Form: <yellow>" .. form .. " <grey>(" .. kata .. "/" .. maxKata .. " kata)")
  cecho("\n<cyan>â•‘ <white>Mindlock: " .. (mindlocked and "<green>ACTIVE" or "<red>INACTIVE"))
  cecho("\n<cyan>â•‘ <white>Blackout Active: " .. (shikudoRiftLock.state.blackoutActive and "<red>YES - OPPONENT BLIND" or "<grey>No"))

  cecho("\n<cyan>â• â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•£")
  cecho("\n<cyan>â•‘ <white>BURST READINESS:")
  cecho("\n<cyan>â•‘   <white>In Rain: " .. (form == "Rain" and "<green>YES" or "<red>NO"))
  cecho("\n<cyan>â•‘   <white>Kata >= 9: " .. (kata >= 9 and "<green>YES (" .. kata .. ")" or "<yellow>NO (" .. kata .. "/9)"))
  cecho("\n<cyan>â•‘   <white>Can Blackout: " .. (shikudoRiftLock.canBlackout() and "<green>YES" or "<red>NO (cooldown)"))
  cecho("\n<cyan>â•‘   <white>BURST READY: " .. (shikudoRiftLock.isReadyForBurst() and shikudoRiftLock.canBlackout() and "<green>*** YES ***" or "<yellow>NO"))

  cecho("\n<cyan>â• â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•£")
  cecho("\n<cyan>â•‘ <white>HINDRANCE AFFLICTIONS:")
  cecho("\n<cyan>â•‘   " .. (tAffs.paralysis and "<green>[X]" or "<red>[ ]") .. " paralysis <grey>(stops parry)")
  cecho("\n<cyan>â•‘   " .. (tAffs.clumsiness and "<green>[X]" or "<red>[ ]") .. " clumsiness <grey>(miss attacks)")
  cecho("\n<cyan>â•‘   " .. (tAffs.weariness and "<green>[X]" or "<red>[ ]") .. " weariness <grey>(blocks Fitness)")
  cecho("\n<cyan>â•‘   " .. (tAffs.lethargy and "<green>[X]" or "<dim_grey>[ ]") .. " lethargy")

  cecho("\n<cyan>â• â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•£")
  cecho("\n<cyan>â•‘ <white>LOCK AFFLICTIONS:")

  -- Softlock
  local soft = shikudoRiftLock.checkSoftlock()
  cecho("\n<cyan>â•‘   <white>Softlock: " .. (soft and "<green>[LOCKED]" or "<yellow>[BUILDING]"))
  cecho("\n<cyan>â•‘     " .. (tAffs.asthma and "<green>[X]" or "<red>[ ]") .. " asthma")
  cecho("  " .. (tAffs.anorexia and "<green>[X]" or "<red>[ ]") .. " anorexia")
  cecho("  " .. (tAffs.slickness and "<green>[X]" or "<red>[ ]") .. " slickness")

  -- Venomlock
  local venom = shikudoRiftLock.checkVenomlock()
  cecho("\n<cyan>â•‘   <white>Venomlock: " .. (venom and "<green>[LOCKED]" or (soft and "<yellow>[NEXT]" or "<dim_grey>[PENDING]")))
  cecho("\n<cyan>â•‘     " .. (tAffs.paralysis and "<green>[X]" or "<red>[ ]") .. " paralysis")

  -- Hardlock
  local hard = shikudoRiftLock.checkHardlock()
  cecho("\n<cyan>â•‘   <white>Hardlock: " .. (hard and "<green>[LOCKED]" or (venom and "<yellow>[NEXT]" or "<dim_grey>[PENDING]")))
  cecho("\n<cyan>â•‘     " .. (tAffs.impatience and "<green>[X]" or "<red>[ ]") .. " impatience <grey>(Telepathy)")

  -- Truelock
  local truelock = shikudoRiftLock.checkTruelock()
  cecho("\n<cyan>â•‘   <white>Truelock: " .. (truelock and "<green>[LOCKED]" or (hard and "<yellow>[NEXT]" or "<dim_grey>[PENDING]")))
  cecho("\n<cyan>â•‘     " .. (tAffs.weariness and "<green>[X]" or "<red>[ ]") .. " weariness")

  cecho("\n<cyan>â• â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•£")
  cecho("\n<cyan>â•‘ <white>LIMB DAMAGE:")
  cecho("\n<cyan>â•‘   <white>L Arm: <yellow>" .. string.format("%.1f%%", shikudoRiftLock.getArmDamage("left")))
  cecho("  <white>R Arm: <yellow>" .. string.format("%.1f%%", shikudoRiftLock.getArmDamage("right")))
  cecho("\n<cyan>â•‘   <white>L Leg: <yellow>" .. string.format("%.1f%%", shikudoRiftLock.getLegDamage("left")))
  cecho("  <white>R Leg: <yellow>" .. string.format("%.1f%%", shikudoRiftLock.getLegDamage("right")))

  cecho("\n<cyan>â•šâ•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?")

  -- Phase-specific advice
  if phase == "OAK_SETUP" then
    cecho("\n<yellow>>>> Building hindrance (para/clumsy) before Rain burst")
  elseif phase == "RAIN_PREP" then
    cecho("\n<cyan>>>> Building kata for blackout burst...")
    if kata >= 9 then
      cecho("\n<green>>>> BURST READY! Next dispatch will BLACKOUT!")
    end
  elseif phase == "BLACKOUT_BURST" then
    cecho("\n<red>*** EXECUTING BLACKOUT BURST - OPPONENT BLIND ***")
  elseif phase == "OAK_CONTINUATION" then
    cecho("\n<yellow>>>> Applying lock afflictions after burst")
  elseif phase == "LOCK_PRESSURE" then
    cecho("\n<green>*** TARGET TRUELOCKED - PURE DAMAGE PRESSURE ***")
  end
end

--------------------------------------------------------------------------------
-- ALIASES
--------------------------------------------------------------------------------

function shikudoriftlock()
  shikudoRiftLock.dispatch()
end

function srlstatus()
  shikudoRiftLock.status()
end

function riftlockstatus()
  shikudoRiftLock.status()
end

-- Reset blackout state (call when target changes or combat ends)
function shikudoRiftLock.reset()
  shikudoRiftLock.state.blackoutActive = false
  shikudoRiftLock.state.lastBlackout = 0
  shikudoRiftLock.state.phase = "OAK_SETUP"
  cecho("\n<cyan>[RIFTLOCK] State reset")
end

function srlreset()
  shikudoRiftLock.reset()
end
