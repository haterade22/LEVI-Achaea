--[[
================================================================================
SHIKUDO UNIFIED OFFENSE SYSTEM
================================================================================

Consolidated offense system with three modes:
  1. DISPATCH - Limb-based kill (prep legs + head â†’ sweep â†’ dispatch)
  2. LOCK     - Pure affliction lock (softlock â†’ hardlock â†’ truelock)
  3. RIFTLOCK - Blackout burst strategy (Mystor's insights)

Usage:
  shikudo.setMode("dispatch")  -- Switch to dispatch mode
  shikudo.setMode("lock")      -- Switch to lock mode
  shikudo.setMode("riftlock")  -- Switch to riftlock mode
  shikudo.dispatch()           -- Execute current mode's offense
  shikudo.status()             -- Show status for current mode

Quick Commands:
  skdispatch() / levishikudodispatch() - Dispatch mode
  sklock() / shikudolock()             - Lock mode
  skriftlock() / shikudoriftlock()     - Riftlock mode
  skstatus()                           - Status display

================================================================================
]]--

shikudo = shikudo or {}

--------------------------------------------------------------------------------
-- MODE SELECTION
--------------------------------------------------------------------------------

shikudo.mode = shikudo.mode or "dispatch"  -- Default mode

function shikudo.setMode(mode)
  local validModes = {dispatch = true, lock = true, riftlock = true}
  if validModes[mode] then
    shikudo.mode = mode
    cecho("\n<cyan>[Shikudo] Mode set to: <yellow>" .. mode:upper())
  else
    cecho("\n<red>[Shikudo] Invalid mode. Use: dispatch, lock, or riftlock")
  end
end

--------------------------------------------------------------------------------
-- SHARED STATE
--------------------------------------------------------------------------------

shikudo.state = shikudo.state or {
  -- Dispatch state
  phase = "PREP",
  hyperfocus = nil,
  -- Lock state
  lockPhase = "SOFTLOCK",
  -- Riftlock state
  riftPhase = "OAK_SETUP",
  lastBlackout = 0,
  blackoutActive = false,
}

--------------------------------------------------------------------------------
-- SHARED CONSTANTS
--------------------------------------------------------------------------------

shikudo.formAttacks = {
  Tykonos = {kicks = {"risingkick"}, staff = {"thrust", "sweep"}},
  Willow = {kicks = {"flashheel"}, staff = {"dart", "hiru", "hiraku", "sweep"}},
  Rain = {kicks = {"frontkick"}, staff = {"ruku", "kuro", "hiru"}},
  Oak = {kicks = {"risingkick"}, staff = {"livestrike", "nervestrike", "ruku", "kuro"}},
  Gaital = {kicks = {"spinkick", "flashheel", "dawnkick"}, staff = {"needle", "sweep", "ruku", "jinzuku", "kuro"}},
  Maelstrom = {kicks = {"risingkick", "crescent"}, staff = {"ruku", "livestrike", "jinzuku", "sweep"}}
}

shikudo.transitions = {
  Tykonos = {"Willow"},
  Willow = {"Rain"},
  Rain = {"Tykonos", "Oak"},
  Oak = {"Willow", "Gaital"},
  Gaital = {"Rain", "Maelstrom"},
  Maelstrom = {"Oak"}
}

shikudo.maxKata = {
  Tykonos = 12, Willow = 12, Rain = 24, Oak = 12, Gaital = 12, Maelstrom = 12
}

--------------------------------------------------------------------------------
-- LIMB DAMAGE TRACKING (from 002_Shikudo_Limb_Counter.lua)
--------------------------------------------------------------------------------

function shikudo_addDamage(attack, limb)
  local limbs = {
    ["head"] = "H", ["torso"] = "T",
    ["left leg"] = "LL", ["right leg"] = "RL",
    ["left arm"] = "LA", ["right arm"] = "RA",
  }
  local l = limbs[limb]
  if not l then return end

  if not shikudo_limbDamage or not shikudo_limbDamage[attack] then
    ataxiaEcho("Formula for " .. attack .. " not calculated?")
    return
  end

  local x = shikudo_limbDamage[attack]
  if ataxia.defences.hyperfocus and ataxiaTemp.hyperLimb == limb then
    x = x / 2
  end

  tLimbs[l] = tLimbs[l] + x

  if tLimbs[l] > 99.8 then
    cecho("\n<red> -= " .. limb .. " broke! =-")
    if limb == "head" then tAffs.stupidity = true end
    target_limbBroke(limb)
    targetLimbs_updateTimers(limb)
  else
    targetLimbs_updateTimers(limb)
  end
end

function shikudo_breakPoint(health)
  shikudo_limbDamage = {}
  local staffMod = ataxia.shikudoLevel or 1

  shikudo_limbDamage.dart = math.floor((.0440 * health + 156) * staffMod)
  shikudo_limbDamage.spinkicktorso = math.floor((.0910 * health + 145) * staffMod)
  shikudo_limbDamage.spinkickhead = math.floor((.2700 * health + 457) * staffMod)
  shikudo_limbDamage.thrust = math.floor((.111 * health + 187) * staffMod)
  shikudo_limbDamage.needle = math.floor((.1057 * health + 295) * staffMod)
  shikudo_limbDamage.risingkick = math.floor((.0451 * health + 261) * staffMod)
  shikudo_limbDamage.flashheel = math.floor((.0451 * health + 261) * staffMod)
  shikudo_limbDamage.frontkick = math.floor((.0451 * health + 261) * staffMod)
  shikudo_limbDamage.kuro = math.floor((.0451 * health + 261) * staffMod)
  shikudo_limbDamage.jinzuku = math.floor((.0451 * health + 261) * staffMod)
  shikudo_limbDamage.ruku = math.floor((.0451 * health + 261) * staffMod)
  shikudo_limbDamage.hiraku = math.floor((.04260 * health + 290) * staffMod)
  shikudo_limbDamage.hiru = math.floor((.04260 * health + 290) * staffMod)
  shikudo_limbDamage.livestrike = math.floor((.0775 * health + 360) * staffMod)
  shikudo_limbDamage.nervestrike = math.floor((.0775 * health + 360) * staffMod)

  for atk, dmg in pairs(shikudo_limbDamage) do
    shikudo_limbDamage[atk] = (shikudo_limbDamage[atk] / health) * 100
    shikudo_limbDamage[atk] = tonumber(string.format("%2.2f", shikudo_limbDamage[atk]))
  end
  cecho("  <red>" .. utf8.char(186) .. "<yellow>" .. utf8.char(186) .. "<green>" .. utf8.char(186))
end

function shikudo_findCombo(queuedAttack)
  local sp = ataxia.settings.separator or "::"
  local shikSplit = string.split(queuedAttack, sp)
  local shikudoCombo = false
  for _, com in pairs(shikSplit) do
    if com:find("combo") then
      shikudoCombo = string.split(com)
      break
    end
  end

  if shikudoCombo then
    ataxiaTemp.shikCombo = {}
    local kicks = {"flashheel", "risingkick", "frontkick", "spinkick", "crescent"}
    local staff = {"shatter", "thrust", "dart", "hiraku", "hiru", "ruku", "kuro", "livestrike", "nervestrike", "needle", "jinzuku"}
    local hit = ""
    for num, act in pairs(shikudoCombo) do
      if table.contains(kicks, act) then
        ataxiaTemp.shikCombo.kick = act
      elseif table.contains(staff, act) then
        if shikudoCombo[num + 1] == "light" then
          hit = act .. " light"
        else
          hit = act
        end
        if ataxiaTemp.shikCombo.attackone then
          ataxiaTemp.shikCombo.attacktwo = hit
        else
          ataxiaTemp.shikCombo.attackone = hit
        end
      end
    end
    if table.contains(shikudoCombo, "sweep") then
      ataxiaTemp.shikCombo.attackone = "sweep"
      ataxiaTemp.shikCombo.attacktwo = "sweep"
    end
    if not ataxiaBasher.enabled then
      cecho("\n<a_darkblue>[<DimGrey>" .. shikudoCombo[2]:upper() .. "<a_darkblue>]: ")
      cecho("<DimGrey>" .. (ataxiaTemp.shikCombo.kick and ataxiaTemp.shikCombo.kick .. " - " or ""))
      cecho("<DimGrey>" .. (ataxiaTemp.shikCombo.attackone and ataxiaTemp.shikCombo.attackone .. " - " or ""))
      cecho("<DimGrey>" .. (ataxiaTemp.shikCombo.attacktwo and ataxiaTemp.shikCombo.attacktwo .. "." or "."))
    end
  end
end

function shikudo_lightAttack(atkName)
  if ataxiaTemp.shikCombo.attackone and ataxiaTemp.shikCombo.attackone:find(atkName) then
    if ataxiaTemp.shikCombo.attackone:find("light") then
      return true
    end
    ataxiaTemp.shikCombo.attackone = nil
  elseif ataxiaTemp.shikCombo.attacktwo and ataxiaTemp.shikCombo.attacktwo:find(atkName) then
    if ataxiaTemp.shikCombo.attacktwo:find("light") then
      return true
    end
    ataxiaTemp.shikCombo.attacktwo = nil
  end
  return false
end

--------------------------------------------------------------------------------
-- FORM HELPERS (from 003_Shikudo_Extras.lua)
--------------------------------------------------------------------------------

function shikudo_checkForms()
  local k = ataxia.vitals.kata
  local f = ataxia.vitals.form:lower()
  local nextForm = {
    tykonos = {"Willow"},
    willow = {"Rain"},
    rain = {"Tykonos", "Oak"},
    oak = {"Willow", "Gaital"},
    gaital = {"Rain", "Maelstrom"},
    maelstrom = {"Oak"},
  }
  if k > 5 or k == 0 then
    cecho("\n<orange>[<green>" .. ataxia.vitals.form .. "<orange>]: <NavajoWhite>" .. table.concat(nextForm[f], " -- ") .. "")
  end
end

--------------------------------------------------------------------------------
-- SHARED UTILITY FUNCTIONS
--------------------------------------------------------------------------------

-- Safe limb damage getter
function shikudo.getLimbDamage(limb)
  if not target or not lb or not lb[target] or not lb[target].hits then
    return 0
  end
  return lb[target].hits[limb] or 0
end

-- Get attack damage (with hyperfocus adjustment)
function shikudo.getAttackDamage(attack, targetLimb)
  local defaults = {
    kuro = 9.2, thrust = 14.5, needle = 10.6, nervestrike = 13.4,
    hiru = 4.3, hiraku = 4.3, livestrike = 7.8, ruku = 4.5,
    dart = 4.4, flashheel = 9.2, risingkick = 9.2, frontkick = 9.2,
    spinkick = 27.0
  }
  local baseDamage
  if shikudo_limbDamage and shikudo_limbDamage[attack] then
    baseDamage = shikudo_limbDamage[attack]
  else
    baseDamage = defaults[attack] or 10
  end

  if targetLimb and shikudo.state.hyperfocus == targetLimb then
    return baseDamage / 2
  end
  return baseDamage
end

-- How many hits until limb is prepped?
function shikudo.hitsToPrep(limb, attack)
  local current = shikudo.getLimbDamage(limb)
  local dmg = shikudo.getAttackDamage(attack, limb)
  local threshold = 100 - dmg

  if current >= threshold then
    return 0
  elseif current + dmg >= threshold then
    return 1
  else
    return 2
  end
end

function shikudo.isLimbPrepped(limb, attack)
  return shikudo.hitsToPrep(limb, attack) == 0
end

function shikudo.getLegPrepThreshold(leg)
  local legName = leg or "left leg"
  local kuro = shikudo_limbDamage and shikudo_limbDamage.kuro or 9.2
  if shikudo.state.hyperfocus == legName then
    kuro = kuro / 2
  end
  return 100 - kuro
end

function shikudo.getHeadPrepThreshold()
  local form = ataxia.vitals.form or "Rain"
  local dmg
  if form == "Oak" then
    dmg = shikudo_limbDamage and shikudo_limbDamage.nervestrike or 7.8
  elseif form == "Gaital" then
    dmg = shikudo_limbDamage and shikudo_limbDamage.needle or 10.6
  else
    dmg = shikudo_limbDamage and shikudo_limbDamage.hiru or 4.3
  end
  if shikudo.state.hyperfocus == "head" then
    dmg = dmg / 2
  end
  return 100 - dmg
end

function shikudo.isLegPreppedByName(leg)
  local limbName = (leg == "left" or leg == "LL") and "left leg" or "right leg"
  local threshold = shikudo.getLegPrepThreshold(limbName)
  return shikudo.getLimbDamage(limbName) >= threshold
end

function shikudo.areBothLegsPrepped()
  local leftThreshold = shikudo.getLegPrepThreshold("left leg")
  local rightThreshold = shikudo.getLegPrepThreshold("right leg")
  return shikudo.getLimbDamage("left leg") >= leftThreshold and shikudo.getLimbDamage("right leg") >= rightThreshold
end

function shikudo.isDynamicHeadPrepped()
  return shikudo.getLimbDamage("head") >= shikudo.getHeadPrepThreshold()
end

function shikudo.getFocusLeg()
  local ll = shikudo.getLimbDamage("left leg")
  local rl = shikudo.getLimbDamage("right leg")
  return ll <= rl and "left" or "right"
end

function shikudo.getOffLeg()
  local ll = shikudo.getLimbDamage("left leg")
  local rl = shikudo.getLimbDamage("right leg")
  return ll >= rl and "left" or "right"
end

function shikudo.setHyperfocus(limb)
  if limb == "none" or limb == nil then
    shikudo.state.hyperfocus = nil
    cecho("\n<yellow>[Shikudo] Hyperfocus: NONE")
  else
    local normalized = limb
    if limb == "left leg" or limb == "leftleg" or limb == "ll" then
      normalized = "left leg"
    elseif limb == "right leg" or limb == "rightleg" or limb == "rl" then
      normalized = "right leg"
    end
    shikudo.state.hyperfocus = normalized
    cecho("\n<yellow>[Shikudo] Hyperfocus: " .. normalized)
  end
end

--------------------------------------------------------------------------------
-- LOCK CHECKS (shared between lock and riftlock modes)
--------------------------------------------------------------------------------

function shikudo.checkSoftlock()
  return tAffs.asthma and tAffs.anorexia and tAffs.slickness
end

function shikudo.checkVenomlock()
  return shikudo.checkSoftlock() and tAffs.paralysis
end

function shikudo.checkHardlock()
  return shikudo.checkVenomlock() and tAffs.impatience
end

function shikudo.checkTruelock()
  return shikudo.checkHardlock() and tAffs.weariness
end

--------------------------------------------------------------------------------
-- DISPATCH CHECKS
--------------------------------------------------------------------------------

function shikudo.checkDispatchReady()
  local prone = tAffs.prone
  local ll = shikudo.getLimbDamage("left leg")
  local rl = shikudo.getLimbDamage("right leg")
  local h = shikudo.getLimbDamage("head")
  local legBroken = (ll >= 100 or rl >= 100)
  local headBroken = (h >= 100 or tAffs.damagedhead)
  local windpipe = (tAffs.damagedwindpipe or tAffs.crushedthroat)
  return prone and legBroken and headBroken and windpipe
end

--------------------------------------------------------------------------------
-- TELEPATHY SELECTION (RAIN FORM ONLY for EQ bonus)
--------------------------------------------------------------------------------

function shikudo.selectTelepathy()
  local form = ataxia.vitals.form or "Oak"
  local kata = ataxia.vitals.kata or 0

  if not ataxia.balances.eq then
    return nil
  end

  -- Mindlock can be established in any form
  if not mindlocked then
    return "mindlock " .. target
  end

  -- All other telepathy - RAIN ONLY for EQ balance bonus!
  if form ~= "Rain" then
    return nil
  end

  -- RIFTLOCK MODE: Blackout burst
  if shikudo.mode == "riftlock" then
    if kata >= 9 and not shikudo.state.blackoutActive then
      local now = os.time()
      if (now - shikudo.state.lastBlackout) >= 10 then
        shikudo.state.lastBlackout = now
        shikudo.state.blackoutActive = true
        return "blackout " .. target
      end
    end
    if shikudo.state.blackoutActive and not tAffs.paralysis then
      return "paralyse " .. target
    end
  end

  -- Impatience for hardlock
  if shikudo.checkSoftlock() and not tAffs.impatience then
    return "impatience " .. target
  end

  -- Batter for mental pressure
  if shikudo.checkSoftlock() then
    return "batter " .. target
  end

  -- Paralyse as backup
  if not tAffs.paralysis and mindlocked then
    return "paralyse " .. target
  end

  return nil
end

--------------------------------------------------------------------------------
-- KICK SELECTION (mode-aware)
--------------------------------------------------------------------------------

function shikudo.selectKick()
  local form = ataxia.vitals.form or "Oak"
  local parried = ataxiaTemp.parriedLimb or "none"

  ataxiaTemp.kickTarget = nil

  if form == "Rain" then
    local lastArm = ataxiaTemp.lastFrontkickArm or "left"
    local wasParried = ataxiaTemp.frontkickWasParried or false
    ataxiaTemp.frontkickWasParried = false

    if wasParried then
      local newArm = lastArm == "left" and "right" or "left"
      ataxiaTemp.kickTarget = newArm .. " arm"
      ataxiaTemp.lastFrontkickArm = newArm
      return "frontkick " .. newArm
    end

    -- Balance arm hits
    local la = shikudo.getLimbDamage("left arm")
    local ra = shikudo.getLimbDamage("right arm")
    local targetArm = la <= ra and "left" or "right"
    ataxiaTemp.kickTarget = targetArm .. " arm"
    ataxiaTemp.lastFrontkickArm = targetArm
    return "frontkick " .. targetArm

  elseif form == "Oak" then
    if tAffs.prone then
      ataxiaTemp.kickTarget = "head"
      return "risingkick head"
    end
    local headPrepped = shikudo.isDynamicHeadPrepped()
    if headPrepped then
      ataxiaTemp.kickTarget = "torso"
      return "risingkick torso"
    end
    ataxiaTemp.kickTarget = "head"
    return "risingkick head"

  elseif form == "Gaital" then
    if tAffs.prone then
      ataxiaTemp.kickTarget = "head"
      return "spinkick"
    end
    local ll = shikudo.getLimbDamage("left leg")
    local rl = shikudo.getLimbDamage("right leg")
    local targetLeg = ll >= rl and "left" or "right"
    ataxiaTemp.kickTarget = targetLeg .. " leg"
    return "flashheel " .. targetLeg

  elseif form == "Willow" then
    local lastLeg = ataxiaTemp.lastFlashheelLeg or "left"
    local wasParried = ataxiaTemp.flashheelWasParried or false
    ataxiaTemp.flashheelWasParried = false

    if wasParried then
      local newLeg = lastLeg == "left" and "right" or "left"
      ataxiaTemp.kickTarget = newLeg .. " leg"
      ataxiaTemp.lastFlashheelLeg = newLeg
      return "flashheel " .. newLeg
    end

    ataxiaTemp.kickTarget = "left leg"
    ataxiaTemp.lastFlashheelLeg = "left"
    return "flashheel left"

  elseif form == "Maelstrom" then
    if tAffs.prone and (tonumber(ataxiaTemp.targetHP) or 100) <= 50 then
      ataxiaTemp.kickTarget = "torso"
      return "crescent"
    end
    ataxiaTemp.kickTarget = "head"
    return "risingkick head"

  else -- Tykonos
    ataxiaTemp.kickTarget = "torso"
    return "risingkick torso"
  end
end

--------------------------------------------------------------------------------
-- STAFF SELECTION (mode-aware)
--------------------------------------------------------------------------------

function shikudo.selectStaff(slot)
  local form = ataxia.vitals.form or "Oak"
  local mode = shikudo.mode

  if form == "Rain" then
    return shikudo.selectRainStaff(slot)
  elseif form == "Oak" then
    return shikudo.selectOakStaff(slot)
  elseif form == "Gaital" then
    return shikudo.selectGaitalStaff(slot)
  elseif form == "Willow" then
    return shikudo.selectWillowStaff(slot)
  elseif form == "Maelstrom" then
    return shikudo.selectMaelstromStaff(slot)
  else
    return "thrust torso"
  end
end

function shikudo.selectRainStaff(slot)
  local mode = shikudo.mode
  local parried = ataxiaTemp.parriedLimb or "none"
  local focusLeg = shikudo.getFocusLeg()
  local offLeg = shikudo.getOffLeg()

  -- Lock/Riftlock: Focus on afflictions
  if mode == "lock" or mode == "riftlock" then
    if slot == 1 then
      if not tAffs.weariness then return "kuro " .. focusLeg end
      if not tAffs.clumsiness then return "ruku left" end
      if not tAffs.slickness then return "ruku torso" end
      return "hiru"
    else
      if not tAffs.lethargy then return "kuro " .. offLeg end
      if not tAffs.clumsiness then return "ruku right" end
      return "hiru"
    end
  end

  -- Dispatch: Focus on leg prep
  local leftHits = shikudo.hitsToPrep("left leg", "kuro")
  local rightHits = shikudo.hitsToPrep("right leg", "kuro")

  if slot == 1 then
    ataxiaTemp.slot1Target = nil
    local focusLegHits = (focusLeg == "left") and leftHits or rightHits

    if focusLegHits >= 1 and parried ~= (focusLeg .. " leg") then
      ataxiaTemp.slot1Target = focusLeg .. " leg"
      return "kuro " .. focusLeg
    end
    ataxiaTemp.slot1Target = "torso"
    return "ruku torso"
  else
    local slot1Hit = ataxiaTemp.slot1Target or "none"
    local offLegHits = (focusLeg == "left") and rightHits or leftHits

    if offLegHits >= 1 and slot1Hit ~= (offLeg .. " leg") and parried ~= (offLeg .. " leg") then
      return "kuro " .. offLeg
    end
    return "hiru"
  end
end

function shikudo.selectOakStaff(slot)
  local mode = shikudo.mode
  local parried = ataxiaTemp.parriedLimb or "none"
  local focusLeg = shikudo.getFocusLeg()
  local headPrepped = shikudo.isDynamicHeadPrepped()

  -- Lock/Riftlock: Focus on afflictions
  if mode == "lock" or mode == "riftlock" then
    if slot == 1 then
      if not tAffs.paralysis then return "nervestrike" end
      if not tAffs.asthma then return "livestrike" end
      if not tAffs.slickness then return "ruku torso" end
      if not tAffs.weariness then return "kuro " .. focusLeg end
      return "nervestrike"
    else
      if not tAffs.clumsiness then return "ruku left" end
      if not tAffs.weariness then return "kuro " .. shikudo.getOffLeg() end
      return "livestrike"
    end
  end

  -- Dispatch: Focus on head prep
  local headHits = shikudo.hitsToPrep("head", "nervestrike")

  if slot == 1 then
    ataxiaTemp.slot1Target = nil
    if headPrepped then
      ataxiaTemp.slot1Target = focusLeg .. " leg"
      return "kuro " .. focusLeg
    end
    if headHits >= 1 and parried ~= "head" then
      ataxiaTemp.slot1Target = "head"
      return "nervestrike"
    end
    ataxiaTemp.slot1Target = "torso"
    return "livestrike"
  else
    local slot1Hit = ataxiaTemp.slot1Target or "none"
    if headHits >= 2 and slot1Hit ~= "head" and parried ~= "head" then
      return "nervestrike"
    end
    if not tAffs.asthma then return "livestrike" end
    return "ruku torso"
  end
end

function shikudo.selectGaitalStaff(slot)
  local ll = shikudo.getLimbDamage("left leg")
  local rl = shikudo.getLimbDamage("right leg")
  local h = shikudo.getLimbDamage("head")
  local headBroken = (h >= 100 or tAffs.damagedhead)
  local hasWindpipe = (tAffs.damagedwindpipe or tAffs.crushedthroat)
  local bothLegsPrepped = shikudo.areBothLegsPrepped()
  local headPrepped = shikudo.isDynamicHeadPrepped()

  if slot == 1 then
    ataxiaTemp.slot1Target = nil
  end

  -- Sweep when ready
  if not tAffs.prone and bothLegsPrepped and headPrepped then
    if slot == 1 then
      ataxiaTemp.slot1Target = "sweep"
      return "sweep"
    else
      return nil
    end
  end

  -- Needle for head/windpipe
  if tAffs.prone then
    if slot == 1 then
      ataxiaTemp.slot1Target = "head"
      return "needle"
    else
      return "needle"
    end
  end

  -- Prep legs/head
  if slot == 1 then
    if not shikudo.isLegPreppedByName("left") then
      ataxiaTemp.slot1Target = "left leg"
      return "kuro left"
    end
    ataxiaTemp.slot1Target = "head"
    return "needle"
  else
    if not shikudo.isLegPreppedByName("right") then
      return "kuro right"
    end
    return "needle"
  end
end

function shikudo.selectWillowStaff(slot)
  local headHits = shikudo.hitsToPrep("head", "hiru")

  if slot == 1 then
    ataxiaTemp.slot1Target = nil
    if headHits >= 1 then
      ataxiaTemp.slot1Target = "head"
      return "hiru"
    end
    ataxiaTemp.slot1Target = "torso"
    return "dart torso"
  else
    if headHits >= 2 then
      return "hiraku"
    end
    return "dart torso"
  end
end

function shikudo.selectMaelstromStaff(slot)
  if not tAffs.prone and shikudo.areBothLegsPrepped() and shikudo.isDynamicHeadPrepped() then
    if slot == 1 then return "sweep" else return nil end
  end

  if slot == 1 then
    if not tAffs.asthma then return "livestrike" end
    if not tAffs.slickness then return "ruku torso" end
    return "jinzuku"
  else
    if not tAffs.slickness then return "ruku torso" end
    if not tAffs.addiction then return "jinzuku" end
    return "livestrike"
  end
end

--------------------------------------------------------------------------------
-- TRANSITION LOGIC (mode-aware)
--------------------------------------------------------------------------------

function shikudo.shouldTransition()
  local form = ataxia.vitals.form or "Oak"
  local kata = ataxia.vitals.kata or 0
  local mode = shikudo.mode

  if kata < 5 then return nil end

  local maxKata = shikudo.maxKata[form] or 12

  -- Dispatch mode
  if mode == "dispatch" then
    local legsPrepped = shikudo.areBothLegsPrepped()
    local headPrepped = shikudo.isDynamicHeadPrepped()

    if legsPrepped and headPrepped then
      if form == "Oak" then return "Gaital" end
      if form == "Rain" then return "Oak" end
      if form == "Willow" then return "Rain" end
    end

    if kata >= maxKata - 3 then
      if form == "Willow" then return "Rain" end
      if form == "Rain" then return "Oak" end
      if form == "Oak" then return "Willow" end
      if form == "Gaital" then return "Maelstrom" end
      if form == "Maelstrom" then return "Oak" end
    end
  end

  -- Lock/Riftlock mode
  if mode == "lock" or mode == "riftlock" then
    -- Prioritize Rain for telepathy bonus
    if form ~= "Rain" and form ~= "Willow" then
      if kata >= 5 then
        if form == "Oak" then return "Willow" end
        if form == "Gaital" then return "Rain" end
        if form == "Maelstrom" then return "Oak" end
      end
    end

    if form == "Willow" and kata >= 5 then
      return "Rain"
    end

    if kata >= maxKata - 3 then
      if form == "Rain" then return "Oak" end
      if form == "Oak" then return "Willow" end
    end
  end

  return nil
end

--------------------------------------------------------------------------------
-- COMBO BUILDER
--------------------------------------------------------------------------------

function shikudo.buildCombo(transition)
  local form = ataxia.vitals.form or "Oak"
  local kick = shikudo.selectKick()
  local staff1 = shikudo.selectStaff(1)
  local staff2 = shikudo.selectStaff(2)

  if staff1 == "sweep" then
    local combo = "combo $tar sweep"
    if kick then combo = combo .. " " .. kick end
    if transition then combo = combo .. " transition " .. transition:lower() end
    return combo
  end

  local combo = "combo $tar"

  -- Oak: staff first (nervestrike paralysis prevents parry)
  if form == "Oak" then
    if staff1 then combo = combo .. " " .. staff1 end
    if staff2 then combo = combo .. " " .. staff2 end
    if kick then combo = combo .. " " .. kick end
  else
    if kick then combo = combo .. " " .. kick end
    if staff1 then combo = combo .. " " .. staff1 end
    if staff2 then combo = combo .. " " .. staff2 end
  end

  if transition then
    combo = combo .. " transition " .. transition:lower()
  end

  return combo
end

--------------------------------------------------------------------------------
-- MAIN DISPATCH FUNCTION
--------------------------------------------------------------------------------

function shikudo.dispatch()
  -- Initialize globals
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}
  ataxia.balances = ataxia.balances or {}
  ataxia.settings = ataxia.settings or {}
  ataxia.settings.separator = ataxia.settings.separator or ";"
  ataxiaTemp = ataxiaTemp or {}
  tAffs = tAffs or {}
  tLimbs = tLimbs or {H = 0, T = 0, LL = 0, RL = 0, LA = 0, RA = 0}

  local form = ataxia.vitals.form or "Oak"
  local kata = ataxia.vitals.kata or 0
  local mode = shikudo.mode

  -- Debug output
  cecho("\n<cyan>[Shikudo:" .. mode:upper() .. "] Target: <yellow>" .. tostring(target))
  cecho(" <cyan>| Form: <yellow>" .. form)
  cecho(" <cyan>| Kata: <yellow>" .. kata)

  -- Safety check
  if not target or target == "" then
    cecho("\n<red>[Shikudo] No target set! Use: tar <name>")
    return
  end

  local cmd = ""
  if combatQueue then
    cmd = combatQueue()
  end

  -- DISPATCH MODE: Check kill condition
  if mode == "dispatch" and shikudo.checkDispatchReady() then
    local isMhaldorian = tCity == "Mhaldor" or tCity == "(Mhaldor)"
    if isMhaldorian then
      cmd = cmd .. "wield staff489282;incapacitate " .. target
      cecho("\n<yellow>*** INCAPACITATE (Mhaldorian) ***")
    else
      cmd = cmd .. "wield staff489282;dispatch " .. target
      cecho("\n<red>*** DISPATCH KILL ***")
    end
    send("queue addclear free " .. cmd)
    return
  end

  -- SHIELD CHECK
  if tAffs.shield then
    local kick = shikudo.selectKick()
    cmd = cmd .. "wield staff489282;combo " .. target .. " shatter " .. kick
    send("queue addclear free " .. cmd)
    return
  end

  -- MOUNTED CHECK (Rain has faster Kai Surge)
  if (tmounted or tAffs.mounted) and form == "Rain" then
    local kai = ataxia.vitals.kai or 0
    if kai >= 31 then
      cmd = cmd .. "kai surge " .. target .. ";"
      cecho("\n<magenta>[Shikudo] KAI SURGE (dismount)")
    end
  end

  -- BUILD ATTACK
  local transition = shikudo.shouldTransition()
  local attack = shikudo.buildCombo(transition)
  attack = attack:gsub("%$tar", target)

  cmd = cmd .. "wield staff489282;" .. attack

  -- TELEPATHY (mode-aware)
  if mode == "lock" or mode == "riftlock" then
    local telepathy = shikudo.selectTelepathy()
    if telepathy then
      cmd = cmd .. ";" .. telepathy
      if telepathy:find("blackout") then
        cecho("\n<red>*** BLACKOUT - OPPONENT CANNOT SEE ***")
      elseif telepathy:find("paralyse") and shikudo.state.blackoutActive then
        cecho("\n<red>*** HIDDEN PARALYSE (under blackout) ***")
      else
        cecho("\n<magenta>[Shikudo] Telepathy: " .. telepathy)
      end
    end
  end

  -- Transition notification
  if transition then
    cecho("\n<yellow>[Shikudo] Transitioning to " .. transition)
    if form == "Rain" and transition == "Oak" then
      shikudo.state.blackoutActive = false
    end
  end

  send("queue addclear free " .. cmd)
end

--------------------------------------------------------------------------------
-- STATUS DISPLAY
--------------------------------------------------------------------------------

function shikudo.status()
  tAffs = tAffs or {}
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}

  local form = ataxia.vitals.form or "Unknown"
  local kata = ataxia.vitals.kata or 0
  local maxKata = shikudo.maxKata[form] or 12
  local mode = shikudo.mode

  cecho("\n<cyan>â•”â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•—")
  cecho("\n<cyan>â•‘         <white>SHIKUDO STATUS<cyan>                       â•‘")
  cecho("\n<cyan>â• â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•£")
  cecho("\n<cyan>â•‘ <white>Mode: <yellow>" .. mode:upper())
  cecho("\n<cyan>â•‘ <white>Target: <yellow>" .. tostring(target or "None"))
  cecho("\n<cyan>â•‘ <white>Form: <green>" .. form .. " <grey>(" .. kata .. "/" .. maxKata .. " kata)")
  cecho("\n<cyan>â•‘ <white>Hyperfocus: " .. (shikudo.state.hyperfocus and shikudo.state.hyperfocus or "none"))

  if mode == "dispatch" then
    cecho("\n<cyan>â• â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•£")
    cecho("\n<cyan>â•‘ <white>LIMB DAMAGE:")
    cecho("\n<cyan>â•‘   <white>Head: <yellow>" .. string.format("%.1f%%", shikudo.getLimbDamage("head")))
    cecho("\n<cyan>â•‘   <white>L Leg: <yellow>" .. string.format("%.1f%%", shikudo.getLimbDamage("left leg")))
    cecho("\n<cyan>â•‘   <white>R Leg: <yellow>" .. string.format("%.1f%%", shikudo.getLimbDamage("right leg")))
    cecho("\n<cyan>â•‘ <white>KILL CONDITIONS:")
    cecho("\n<cyan>â•‘   <white>Prone: " .. (tAffs.prone and "<green>YES" or "<red>NO"))
    cecho("\n<cyan>â•‘   <white>Leg Broken: " .. ((shikudo.getLimbDamage("left leg") >= 100 or shikudo.getLimbDamage("right leg") >= 100) and "<green>YES" or "<red>NO"))
    cecho("\n<cyan>â•‘   <white>Head Broken: " .. ((shikudo.getLimbDamage("head") >= 100 or tAffs.damagedhead) and "<green>YES" or "<red>NO"))
    cecho("\n<cyan>â•‘   <white>Windpipe: " .. ((tAffs.damagedwindpipe or tAffs.crushedthroat) and "<green>YES" or "<red>NO"))
    cecho("\n<cyan>â•‘   <white>DISPATCH READY: " .. (shikudo.checkDispatchReady() and "<green>*** YES ***" or "<red>NO"))
  end

  if mode == "lock" or mode == "riftlock" then
    cecho("\n<cyan>â• â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•£")
    cecho("\n<cyan>â•‘ <white>LOCK STATUS:")
    cecho("\n<cyan>â•‘   <white>Softlock: " .. (shikudo.checkSoftlock() and "<green>LOCKED" or "<yellow>BUILDING"))
    cecho("\n<cyan>â•‘     " .. (tAffs.asthma and "<green>[X]" or "<red>[ ]") .. " asthma")
    cecho("  " .. (tAffs.anorexia and "<green>[X]" or "<red>[ ]") .. " anorexia")
    cecho("  " .. (tAffs.slickness and "<green>[X]" or "<red>[ ]") .. " slickness")
    cecho("\n<cyan>â•‘   <white>Venomlock: " .. (shikudo.checkVenomlock() and "<green>LOCKED" or "<yellow>PENDING"))
    cecho("\n<cyan>â•‘     " .. (tAffs.paralysis and "<green>[X]" or "<red>[ ]") .. " paralysis")
    cecho("\n<cyan>â•‘   <white>Hardlock: " .. (shikudo.checkHardlock() and "<green>LOCKED" or "<yellow>PENDING"))
    cecho("\n<cyan>â•‘     " .. (tAffs.impatience and "<green>[X]" or "<red>[ ]") .. " impatience")
    cecho("\n<cyan>â•‘   <white>Truelock: " .. (shikudo.checkTruelock() and "<green>LOCKED" or "<yellow>PENDING"))
    cecho("\n<cyan>â•‘     " .. (tAffs.weariness and "<green>[X]" or "<red>[ ]") .. " weariness")
  end

  if mode == "riftlock" then
    cecho("\n<cyan>â• â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•£")
    cecho("\n<cyan>â•‘ <white>RIFTLOCK:")
    cecho("\n<cyan>â•‘   <white>Blackout Active: " .. (shikudo.state.blackoutActive and "<red>YES - OPPONENT BLIND" or "<grey>No"))
    cecho("\n<cyan>â•‘   <white>Burst Ready: " .. ((form == "Rain" and kata >= 9 and mindlocked) and "<green>YES" or "<yellow>NO"))
  end

  cecho("\n<cyan>â•šâ•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?")
end

--------------------------------------------------------------------------------
-- RESET FUNCTION
--------------------------------------------------------------------------------

function shikudo.reset()
  shikudo.state.blackoutActive = false
  shikudo.state.lastBlackout = 0
  shikudo.state.phase = "PREP"
  shikudo.state.lockPhase = "SOFTLOCK"
  shikudo.state.riftPhase = "OAK_SETUP"
  cecho("\n<cyan>[Shikudo] State reset")
end

--------------------------------------------------------------------------------
-- CONVENIENCE ALIASES
--------------------------------------------------------------------------------

-- Mode-specific dispatch
function skdispatch()
  shikudo.setMode("dispatch")
  shikudo.dispatch()
end

function sklock()
  shikudo.setMode("lock")
  shikudo.dispatch()
end

function skriftlock()
  shikudo.setMode("riftlock")
  shikudo.dispatch()
end

-- Legacy compatibility
function levishikudodispatch()
  shikudo.setMode("dispatch")
  shikudo.dispatch()
end

function shikudolock()
  shikudo.setMode("lock")
  shikudo.dispatch()
end

function shikudoriftlock()
  shikudo.setMode("riftlock")
  shikudo.dispatch()
end

-- Status
function skstatus()
  shikudo.status()
end

function sklstatus()
  shikudo.setMode("lock")
  shikudo.status()
end

function srlstatus()
  shikudo.setMode("riftlock")
  shikudo.status()
end

-- Reset
function skreset()
  shikudo.reset()
end

function srlreset()
  shikudo.reset()
end
