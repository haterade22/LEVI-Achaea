--[[mudlet
type: script
name: Magi Offense
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Mage
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
  OFFENSIVE SYSTEM - Magi (Unified)

  REQUIRED READING before modifying:
  - .claude/classes/lock_types.md (lock definitions)
  - .claude/classes/magi.md (class mechanics)

  Modes: fire, water, lock, salve, group
  Dispatch: zz alias → magi.offense.dispatch()

  Based on xMagi reference (Aegoth/Tabethys) + our V3 affliction tracking.
  Resonance system: 4 elements (air/fire/water/earth) at levels 0-3.
  Each cast builds resonance. At level 3, use emanation to spend it.

  Kill routes:
    fire  → burns → conflagrate → destroy/stormhammer
    water → freeze → hypothermia → glaciate
    lock  → kelp stack → truelock via resonance affs
    salve → salve-pressure via earth/fire resonance
    group → stormhammer multi-target + damage
]]--

----------------------------------------------------------------
-- Namespace (extends magi table from 001_Resonance.lua)
----------------------------------------------------------------
magi = magi or {}
magi.offense = magi.offense or {}

magi.offense.state = magi.offense.state or {}
local _sd = {
  mode = "fire",
  burns = 0,
  conflagrated = false,
  scalded = false,
  scaldedTimer = nil,
  calcifiedTorso = false,
  calcifiedSkull = false,
  shalestorm = false,
  scintillaSpark = false,
  scintillaTimer = nil,
  firestorm = false,
  hypothermia = false,
  frozen = false,
  shivering = false,
  partyrelay = true,
  debug = false,
}
for k, v in pairs(_sd) do
  if magi.offense.state[k] == nil then magi.offense.state[k] = v end
end

magi.offense.config = {
  destroyThreshold = 35,
  stormhammerThreshold = 25,
  scaldedDuration = 20,
  useArachnideye = false,   -- artefact toggle: arachnideye trample prefix
  useWebbomb = false,        -- artefact toggle: webbomb prefix
}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

function magi.offense.hasAff(aff)
  if haveAff then return haveAff(aff) end
  return tAffs and tAffs[aff]
end

function magi.offense.getAffProb(aff)
  if getAffProbabilityV3 then return getAffProbabilityV3(aff) end
  if tAffs and tAffs[aff] then return 1.0 end
  return 0.0
end

function magi.offense.hasShield()
  return haveAff("rebounding") or (tAffs and tAffs.rebounding)
      or haveAff("shield") or (tAffs and tAffs.shield)
end

function magi.offense.targetShielded()
  return haveAff("shield") or (tAffs and tAffs.shield)
end

function magi.offense.echo(text)
  cecho("\n<dark_orchid>[<cornflower_blue>Magi<dark_orchid>]<lavender> " .. text)
end

function magi.offense.debugEcho(text)
  if magi.offense.state.debug then
    magi.offense.echo("<dim_grey>" .. text)
  end
end

function magi.offense.ptRelay(msg)
  if magi.offense.state.partyrelay and partyrelay and not ataxia.afflictions.aeon then
    send("pt " .. msg, false)
  end
end

-- Count broken limbs on target
function magi.offense.countBrokenLimbs()
  local count = 0
  local limbs = {"brokenleftleg", "brokenrightleg", "brokenleftarm", "brokenrightarm"}
  for _, limb in ipairs(limbs) do
    if magi.offense.hasAff(limb) then count = count + 1 end
  end
  return count
end

-- Target health percentage (from assess or GMCP)
function magi.offense.getTargetHP()
  if targetHealth then return targetHealth end
  if php then return php end
  return 100
end

----------------------------------------------------------------
-- Scalded Timer
----------------------------------------------------------------

function magi.offense.setScalded()
  local st = magi.offense.state
  st.scalded = true
  if st.scaldedTimer then killTimer(st.scaldedTimer) end
  st.scaldedTimer = tempTimer(magi.offense.config.scaldedDuration, function()
    magi.offense.state.scalded = false
    magi.offense.state.scaldedTimer = nil
    magi.offense.debugEcho("Scalded expired")
  end)
end

----------------------------------------------------------------
-- Reset (on target change, death, etc.)
----------------------------------------------------------------

function magi.offense.reset()
  local st = magi.offense.state
  st.burns = 0
  st.conflagrated = false
  st.scalded = false
  st.calcifiedTorso = false
  st.calcifiedSkull = false
  st.shalestorm = false
  st.scintillaSpark = false
  if st.scintillaTimer then killTimer(st.scintillaTimer); st.scintillaTimer = nil end
  st.hypothermia = false
  st.frozen = false
  st.shivering = false
  if st.scaldedTimer then killTimer(st.scaldedTimer); st.scaldedTimer = nil end
end

----------------------------------------------------------------
-- Meteorite Shield Breaking (4 variants from xMagi reference)
----------------------------------------------------------------

function magi.offense.selectMeteorite()
  local r = magi.resonance
  local st = magi.offense.state
  local fireWillBurn = (r.fire > 0) and (r.fire < 3)

  if fireWillBurn then
    return "cast meteorite flaming at " .. target
  elseif r.earth < 3 or st.calcifiedTorso then
    return "cast meteorite pure at " .. target
  elseif r.water < 3 then
    return "cast meteorite frozen at " .. target
  else
    return "cast erode at " .. target .. " shield"
  end
end

----------------------------------------------------------------
-- Unified Decision Tree (based on xMagi reference)
----------------------------------------------------------------

function magi.offense.selectSpell()
  local r = magi.resonance
  local st = magi.offense.state
  local mode = st.mode
  local hp = magi.offense.getTargetHP()

  -- Pre-compute conditions (from xMagi reference)
  local fireWillBurn = (r.fire > 0) and (r.fire < 3)
  local freso = (r.water >= 2) and (r.air >= 2) -- freeze resonance threshold
  local asthma = magi.offense.getAffProb("asthma")
  local scalded = st.scalded
  local burning = st.burns
  local caloric = not magi.offense.hasAff("nocaloric") -- direct: nocaloric aff = caloric defense is down
  local frostbite = magi.offense.getAffProb("frostbite")
  local shivering = magi.offense.getAffProb("shivering")
  local weariness = magi.offense.getAffProb("weariness")
  local nausea = magi.offense.getAffProb("nausea")
  local dehydrateWillFreeze = (nausea >= 0.5) and (weariness < 0.5)

  -- Stale state paranoia (from xMagi reference)
  if magi.offense.getAffProb("burning") == 0 then
    st.burns = 0
    st.conflagrated = false
    burning = 0
  end

  local emearth = (not st.calcifiedTorso) and (r.earth == 3)
    and (frostbite >= 0.5 or burning > 1 or shivering >= 0.5 or not caloric)

  --=== PRIORITY 1: DESTROY (conflagrated + low HP) ===--
  if st.conflagrated and hp < magi.offense.config.destroyThreshold then
    return "cast destroy at " .. target
  end

  --=== PRIORITY 2: SHIELD STRIP (meteorite variants) ===--
  if magi.offense.targetShielded() then
    return magi.offense.selectMeteorite()
  end

  --=== PRIORITY 3: GLACIATE (hypothermia + dual resonance) ===--
  local frozen = magi.offense.getAffProb("frozen") >= 0.5
  local hypothermia = st.hypothermia or magi.offense.getAffProb("hypothermia") >= 0.5
  if mode ~= "fire" and hypothermia and freso then
    return "cast glaciate at " .. target
  end

  --=== PRIORITY 4: STORMHAMMER (low HP kill) ===--
  if hp <= magi.offense.config.stormhammerThreshold then
    if magi.storm and magi.storm.fire then
      magi.storm.selectTargets()
      magi.storm.fire()
      return nil -- storm.fire sends directly
    else
      return "cast stormhammer at " .. target
    end
  end

  --=== PRIORITY 5: SHALESTORM+SCINTILLA (free calcify when shalestorm active) ===--
  -- Gates: skip when burns maxed (5), skip when conflagrate ready (burns>=2 + fire>=2)
  -- so the burning path at Priority 12 can fire conflagrate instead
  if st.shalestorm and not st.calcifiedTorso and not st.scintillaSpark
     and r.earth >= 2
     and burning < 5
     and not (burning >= 2 and r.fire >= 2) then
    return "staffcast scintilla at " .. target
  end

  --=== PRIORITY 6: EMANATION EARTH (earth capped + conditions met) ===--
  if emearth then
    return "cast emanation at " .. target .. " earth"
  end

  --=== PRIORITY 7: HYPOTHERMIA (frozen + dual resonance) ===--
  if mode ~= "fire" and frozen and not hypothermia and freso then
    return "cast hypothermia at " .. target
  end

  --=== PRIORITY 8: MUDSLIDE (asthma + water==2) ===--
  if asthma >= 0.5 and r.water == 2 then
    return "cast mudslide at " .. target
  end

  --=== MODE-SPECIFIC BRANCHES ===--
  if mode == "lock" then
    return magi.offense.selectLockSpell()
  end
  if mode == "salve" then
    return magi.offense.selectSalveSpell()
  end
  if mode == "group" then
    return magi.offense.selectGroupSpell()
  end

  --=== PRIORITY 9: MAGMA (not scalded) ===--
  if not scalded then
    return "cast magma at " .. target
  end

  --=== PRIORITY 10: FREEZE (shivering + broken limb) ===--
  if mode ~= "fire" and shivering >= 0.5 and magi.offense.countBrokenLimbs() >= 1 then
    return "cast freeze at " .. target
  end

  --=== PRIORITY 11: CALCIFIED PATH ===--
  if st.calcifiedTorso and (frostbite >= 0.5 or not caloric) then
    if dehydrateWillFreeze and fireWillBurn then
      return "cast dehydrate at " .. target
    else
      return "cast freeze at " .. target
    end
  end

  --=== PRIORITY 12: BURNING PATH (burns management) ===--
  if burning > 0 then
    return magi.offense.selectBurningSpell()
  end

  --=== PRIORITY 13: SHALESTORM (earth >= 2, not active) ===--
  if not st.shalestorm and r.earth >= 2 then
    return "cast shalestorm at " .. target
  end

  --=== FALLBACK ===--
  return magi.offense.selectFallback()
end

----------------------------------------------------------------
-- Burning sub-tree (from xMagi reference)
----------------------------------------------------------------

function magi.offense.selectBurningSpell()
  local r = magi.resonance
  local st = magi.offense.state
  local burning = st.burns
  local fireWillBurn = (r.fire > 0) and (r.fire < 3)
  local frostbite = magi.offense.getAffProb("frostbite")
  local weariness = magi.offense.getAffProb("weariness")
  local nausea = magi.offense.getAffProb("nausea")
  local caloric = not magi.offense.hasAff("nocaloric")
  local dehydrateWillFreeze = (nausea >= 0.5) and (weariness < 0.5)

  -- Conflagrate when ready (requires burns >= 2, fire >= 2)
  if burning >= 2 and r.fire >= 2 and not st.conflagrated then
    return "cast conflagrate at " .. target
  end

  -- Dehydrate for freeze + burn combo
  if (not caloric or frostbite >= 0.5) and dehydrateWillFreeze and fireWillBurn then
    return "cast dehydrate at " .. target
  end

  -- Fulminate to build air+fire
  if r.air == 0 and r.water == 2 and fireWillBurn then
    return "cast fulminate at " .. target
  end

  -- Dehydrate if weariness is present (stacks burns)
  if fireWillBurn and weariness >= 0.5 then
    return "cast dehydrate at " .. target
  end

  -- Emanation fire at cap
  if r.fire == 3 then
    return "cast emanation at " .. target .. " fire"
  end

  -- Earth building
  if r.earth == 1 then
    if fireWillBurn then
      return "cast magma at " .. target
    else
      return "cast bombard at " .. target
    end
  end

  -- Emanation water at cap
  if r.water == 3 then
    return "cast emanation at " .. target .. " water"
  end

  -- Default: dehydrate (builds burns + water)
  return "cast dehydrate at " .. target
end

----------------------------------------------------------------
-- Lock sub-tree
----------------------------------------------------------------

function magi.offense.selectLockSpell()
  local r = magi.resonance
  local st = magi.offense.state

  -- Horripilation for waterbond/blistered if not present
  if not magi.offense.hasAff("waterbond") and not magi.offense.hasAff("blistered")
     and not st.calcifiedTorso and not magi.offense.hasAff("paralysis")
     and not magi.offense.hasAff("anorexia") then
    if r.fire == 2 then
      return "cast fulminate at " .. target
    else
      return "staffcast horripilation " .. target
    end
  end

  -- Scalded path for calcify
  if not st.scalded then
    return "cast magma at " .. target
  end

  -- Scintilla for calcify at earth major
  if r.earth == 3 and not st.calcifiedTorso then
    return "staffcast scintilla at " .. target
  end

  -- Emanation earth at cap (if calcified)
  if r.earth == 3 and st.calcifiedTorso then
    return "cast emanation at " .. target .. " earth"
  end

  -- Build earth
  if r.earth < 2 then
    if not magi.offense.hasAff("clumsiness") then
      return "cast bombard at " .. target
    else
      return "cast mudslide at " .. target
    end
  end

  -- Build air
  if r.air < 3 then
    return "cast fulminate at " .. target
  end

  -- Emanation air at cap
  if r.air == 3 then
    return "cast emanation at " .. target .. " air"
  end

  return "cast dehydrate at " .. target
end

----------------------------------------------------------------
-- Salve mode sub-tree (earth/fire resonance for salve-curable affs)
----------------------------------------------------------------

function magi.offense.selectSalveSpell()
  local r = magi.resonance
  local st = magi.offense.state

  -- Emanation earth at cap (salve-curable affs: broken limbs, cracked ribs)
  if r.earth == 3 then
    return "cast emanation at " .. target .. " earth"
  end

  -- Scalded for salve pressure (salve balance lock)
  if not st.scalded then
    return "cast magma at " .. target
  end

  -- Scintilla for calcified torso (blocks restoration salve)
  if r.earth >= 2 and not st.calcifiedTorso then
    return "staffcast scintilla at " .. target
  end

  -- Build earth resonance (earth affs are salve-cured: limb breaks, paralysis, cracked ribs)
  if r.earth < 3 then
    return "cast bombard at " .. target
  end

  -- Emanation fire at cap (scalded/ablaze are salve-pressure)
  if r.fire == 3 then
    return "cast emanation at " .. target .. " fire"
  end

  -- Build fire for scalded pressure
  return "cast dehydrate at " .. target
end

----------------------------------------------------------------
-- Group mode sub-tree (damage + stormhammer multi-target)
----------------------------------------------------------------

function magi.offense.selectGroupSpell()
  local r = magi.resonance
  local st = magi.offense.state
  local hp = magi.offense.getTargetHP()

  -- Stormhammer at higher threshold for group (50% instead of 25%)
  if hp <= 50 then
    if magi.storm and magi.storm.fire then
      magi.storm.selectTargets()
      magi.storm.fire()
      return nil
    else
      return "cast stormhammer at " .. target
    end
  end

  -- Emanation fire at cap (damage)
  if r.fire == 3 then
    return "cast emanation at " .. target .. " fire"
  end

  -- Emanation earth at cap (limb breaks for group pressure)
  if r.earth == 3 then
    return "cast emanation at " .. target .. " earth"
  end

  -- Shalestorm for AoE earth damage
  if not st.shalestorm and r.earth >= 2 then
    return "cast shalestorm at " .. target
  end

  -- Magma for damage + scalded
  if not st.scalded then
    return "cast magma at " .. target
  end

  -- Dehydrate for burn stacking + damage
  return "cast dehydrate at " .. target
end

----------------------------------------------------------------
-- Fallback sub-tree
----------------------------------------------------------------

function magi.offense.selectFallback()
  local r = magi.resonance
  local st = magi.offense.state

  -- Shalestorm if earth allows
  if not st.shalestorm then
    if r.earth >= 2 then
      return "cast shalestorm at " .. target
    else
      return "cast bombard at " .. target
    end
  end

  -- Emanation fire at cap
  if r.fire == 3 then
    return "cast emanation at " .. target .. " fire"
  end

  -- Build resonance
  if r.earth < 3 and r.fire < 3 then
    return "cast magma at " .. target
  end

  return "cast dehydrate at " .. target
end

----------------------------------------------------------------
-- Send Attack
----------------------------------------------------------------

function magi.offense.sendAttack(spell)
  if not spell then return end

  local sep = ataxia.settings and ataxia.settings.separator or "::"
  local staff = magi.staff or "staff569815"
  local prefix = ""

  -- Optional utility prefix (free actions, don't consume spell balance)
  if magi.offense.config.useArachnideye and not magi.offense.hasAff("prone") then
    prefix = "arachnideye trample " .. target .. sep
  elseif magi.offense.config.useWebbomb and not magi.offense.hasAff("entangled") then
    prefix = "webbomb " .. target .. sep
  end

  local cmd = prefix .. "stand" .. sep .. "wield " .. staff .. " shield"
  cmd = cmd .. sep .. spell .. sep .. "assess " .. target

  send("queue addclearfull freestand " .. cmd)

  magi.offense.debugEcho("Sent: " .. spell)
end

----------------------------------------------------------------
-- Main Dispatch
----------------------------------------------------------------

function magi.offense.dispatch()
  -- Guard: class check
  if gmcp and gmcp.Char and gmcp.Char.Status and gmcp.Char.Status.class ~= "Magi" then
    return
  end

  -- Guard: balance + equilibrium
  if gmcp and gmcp.Char and gmcp.Char.Vitals then
    if gmcp.Char.Vitals.bal ~= "1" or gmcp.Char.Vitals.eq ~= "1" then
      return
    end
  end

  -- Guard: aeon
  if ataxia and ataxia.afflictions and ataxia.afflictions.aeon then
    magi.offense.echo("<red>In aeon - cannot attack")
    return
  end

  -- Guard: no target
  if not target or target == "" then
    magi.offense.echo("<red>No target set")
    return
  end

  -- Update resonance from GMCP
  if get_resonance then get_resonance() end

  -- Sync firestorm state from legacy global
  if magi.firestorm ~= nil then
    magi.offense.state.firestorm = magi.firestorm
  end

  -- Select and send
  local spell = magi.offense.selectSpell()
  magi.offense.sendAttack(spell)
end

----------------------------------------------------------------
-- Mode Management
----------------------------------------------------------------

function magi.offense.setMode(mode)
  local valid = {fire = true, water = true, lock = true, salve = true, group = true}
  if valid[mode] then
    if magi.offense.state.mode ~= mode then
      magi.offense.echo("<gold>Mode set to: <white>" .. mode)
    end
    magi.offense.state.mode = mode
  else
    magi.offense.echo("<red>Invalid mode: " .. tostring(mode) .. " (fire/water/lock/salve/group)")
  end
end

function magi.offense.status()
  local st = magi.offense.state
  local r = magi.resonance or {fire=0, water=0, earth=0, air=0}

  magi.offense.echo("<gold>--- Magi Offense Status ---")
  cecho("\n <cornflower_blue>Mode: <white>" .. st.mode)
  cecho("\n <cornflower_blue>Resonance: <red>F:" .. r.fire .. " <dodger_blue>W:" .. r.water .. " <saddle_brown>E:" .. r.earth .. " <light_sky_blue>A:" .. r.air)
  cecho("\n <cornflower_blue>Burns: <orange_red>" .. st.burns .. (st.conflagrated and " <red>[CONFLAGRATED]" or ""))
  cecho("\n <cornflower_blue>Scalded: " .. (st.scalded and "<orange_red>YES" or "<dim_grey>no"))
  cecho("\n <cornflower_blue>Calcify: " .. (st.calcifiedTorso and "<red>TORSO" or "<dim_grey>-") .. " " .. (st.calcifiedSkull and "<red>SKULL" or "<dim_grey>-"))
  cecho("\n <cornflower_blue>Shalestorm: " .. (st.shalestorm and "<green>ACTIVE" or "<dim_grey>no"))
  local dispHypo = st.hypothermia or magi.offense.getAffProb("hypothermia") >= 0.5
  local dispFrozen = magi.offense.getAffProb("frozen") >= 0.5
  cecho("\n <cornflower_blue>Hypothermia: " .. (dispHypo and "<dodger_blue>YES" or "<dim_grey>no"))
  cecho("\n <cornflower_blue>Frozen: " .. (dispFrozen and "<dodger_blue>YES" or "<dim_grey>no"))
  cecho("\n <cornflower_blue>Arachnideye: " .. (magi.offense.config.useArachnideye and "<green>ON" or "<dim_grey>off"))
  cecho("\n <cornflower_blue>Webbomb: " .. (magi.offense.config.useWebbomb and "<green>ON" or "<dim_grey>off"))
  echo("\n")
end

----------------------------------------------------------------
-- Vibration Auto-Management
----------------------------------------------------------------

function magi.offense.setupVibes()
  if not ataxia_isClass or not ataxia_isClass("magi") then
    magi.offense.echo("<red>Not currently Magi class.")
    return
  end

  -- Default PvP vibe set
  local wantedVibes = {"dissonance", "energise", "creeps", "palpitation",
                       "tremors", "disorientation", "plague", "lullaby"}

  -- Use existing ataxia.magi.vibes system
  ataxia.magi = ataxia.magi or {}
  ataxia.magi.vibes = ataxia.magi.vibes or {}

  -- Set wanted vibes
  ataxia.magi.vibes = {}
  for _, vibe in ipairs(wantedVibes) do
    table.insert(ataxia.magi.vibes, vibe)
  end

  magi.offense.echo("<gold>PvP vibes set: <white>" .. table.concat(wantedVibes, ", "))
  magi.offense.echo("<dim_grey>Type 'evibe' to embed them.")
end

----------------------------------------------------------------
-- Backward Compatibility Wrappers
----------------------------------------------------------------

-- These map old function names to new dispatch with mode set
MagiMain = function()
  magi.offense.setMode("fire")
  magi.offense.dispatch()
end

MagiLock = function()
  magi.offense.setMode("lock")
  magi.offense.dispatch()
end

MagiWaterFocus = function()
  magi.offense.setMode("water")
  magi.offense.dispatch()
end

MagiFireNew = function()
  magi.offense.setMode("fire")
  magi.offense.dispatch()
end

MagiSalveFocus = function()
  magi.offense.setMode("salve")
  magi.offense.dispatch()
end

-- Legacy globals kept for trigger compat
tburns = 0
tfirelash = false
timmolation = false

----------------------------------------------------------------
-- Target change reset handler
----------------------------------------------------------------

if magi.offense._targetHandler then
  killAnonymousEventHandler(magi.offense._targetHandler)
end
magi.offense._targetHandler = registerAnonymousEventHandler("changed target", function()
  magi.offense.reset()
end)
