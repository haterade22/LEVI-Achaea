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

  Modes: fire, water, lock, salve, group, waterroute
  Dispatch: zz alias → magi.offense.dispatch()
  Keys: zz salve, xx fire, cc lock, vv water, sr group, ww waterroute (v4.7.421)

  Based on xMagi reference (Aegoth/Tabethys) + our V3 affliction tracking.
  Resonance system: 4 elements (air/fire/water/earth) at levels 0-3.
  Each cast builds resonance. At level 3, use emanation to spend it.

  Kill routes:
    fire  → burns → conflagrate → destroy/stormhammer
    water -> no branch of its own: it runs the fire tree (the water route is waterroute)
    lock  → kelp stack → truelock via resonance affs
    salve → salve-pressure via earth/fire resonance
    group → stormhammer multi-target + damage
    waterroute -> Tabethys: magma, dehydrate x2, fulminate, the mudslide bonk; then emanate
                  water, freeze until frozen, glaciate (selectWaterRouteSpell)
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
  hypothermia = false,  -- set by magi_offense_tracking/005; read by nothing now (P3, P7, status read V3)
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
  -- Water route (ww, v4.7.421): glaciate a frozen target whose health is unknown or at most this
  -- percentage, else lay hypothermia first. 100 = glaciate first, Tabethys's usual finisher;
  -- false = always hypothermia first ('mm glaciate off'). kb/ holds no figure for glaciate's
  -- damage (kb/CONFLICTS.md #27), so lower it only from logged glaciates ('mm glaciate <pct>').
  glaciateKillAt = 100,
  -- Compact echoes (v4.7.429, after Tabethys's system, kb/raw/logs/2026-10-19_tabethys_*): one
  -- `You: <Spell> -> <Target>` line per round sent, one `<Plane>: <Stage> -> <Target>` line per
  -- resonance that lands, and a stage word on the Magi prompt. Display only. `mm echo` toggles all
  -- three. Not saved, like the toggles above.
  compactEcho = true,
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

----------------------------------------------------------------
-- Compact echoes (v4.7.429)
----------------------------------------------------------------
-- Copied in design from Tabethys's system (o6UKnyyy log): "You: Magma -> Kalys",
-- "Earth: Brokenrightarm -> Kalys", "Fire: Scalded > Burning -> Kalys". The game line stays on
-- screen; the echo goes on its own line after it. The colours are the ones `mm` status uses.
local PLANE_COLOUR = {
  Fire = "red", Water = "dodger_blue", Earth = "saddle_brown", Air = "light_sky_blue",
}

function magi.offense.compactOn()
  return magi.offense.config.compactEcho ~= false
end

-- One landed resonance (022_Resonance_Afflictions, 014_Temperance, 022_Increase_Burning). The
-- callers check the name first, so this only ever names our target.
function magi.offense.resoEcho(plane, stage, tgt)
  if not magi.offense.compactOn() then return end
  cecho("\n<" .. (PLANE_COLOUR[plane] or "white") .. ">" .. plane .. ": <white>" .. stage
    .. " <dim_grey>-> <NavajoWhite>" .. tostring(tgt or target))
end

-- "cast dehydrate at X" -> "Dehydrate", "cast emanation at X water" -> "Emanation water",
-- "staffcast horripilation X" -> "Horripilation", "cast meteorite at X flaming 4" ->
-- "Meteorite flaming 4". Every spell the tree sends names its target first after the spell word.
function magi.offense.spellLabel(spell)
  local s = spell:gsub("^staffcast ", ""):gsub("^cast ", "")
  local name, rest = s:match("^(%a+)%s*(.*)$")
  if not name then return spell end
  rest = rest:gsub("^at ", ""):gsub("^%S+%s*", "", 1)
  name = name:sub(1, 1):upper() .. name:sub(2)
  return rest ~= "" and (name .. " " .. rest) or name
end

-- The cast line, once per round SENT. A key press rebuilds and re-sends the round (queue
-- addclearfull replaces the one waiting), so the same round pressed again within 2 s is not a new
-- cast. The stamp is on ataxiaTemp: it is transient and must not ride the saved ataxia namespace.
local CAST_ECHO_REPEAT = 2

function magi.offense.castEcho(label, who)
  if not magi.offense.compactOn() then return end
  ataxiaTemp = ataxiaTemp or {}
  local key = label .. "|" .. tostring(who)
  local last = ataxiaTemp.magiCastEcho
  local now = getEpoch()
  if last and last.key == key and now - last.at < CAST_ECHO_REPEAT then return end
  ataxiaTemp.magiCastEcho = { key = key, at = now }
  cecho("\n<gold>You: <white>" .. label .. " <dim_grey>-> <NavajoWhite>" .. tostring(who))
end

-- The burns as the next round will read them: none when V3 holds no burning (the stale-burn
-- reset, which selectSpell writes only when it runs).
function magi.offense.liveBurns()
  if magi.offense.getAffProb("burning") == 0 then return 0 end
  return magi.offense.state.burns or 0
end

-- One word for what the next round does, NAMED FROM THE SPELL pickSpell picks (v4.7.430), so it
-- cannot disagree with the round: v4.7.429 re-implemented the tests and drifted. The water route
-- names its own step. nil without a target.
local SPELL_STAGE = {
  destroy = "destroy", meteorite = "shield", erode = "shield", glaciate = "glaciate",
  hypothermia = "hypothermia", mudslide = "bonk", scintilla = "calcify", conflagrate = "conflagrate",
  freeze = "freeze", shalestorm = "shalestorm",
}
function magi.offense.stageWord()
  if type(target) ~= "string" or target == "" or not magi.resonance then return nil end
  local spell = magi.offense.pickSpell()
  if spell == magi.offense.STORM then return "storm" end
  if spell == magi.offense.WATERROUTE then
    local _, step = magi.offense.waterRoutePick()
    return step
  end
  local name, rest = spell:gsub("^staffcast ", ""):gsub("^cast ", ""):match("^(%a+)(.*)$")
  if not name then return nil end
  if name == "emanation" then return "emanate " .. (rest:match("(%a+)%s*$") or "") end
  if SPELL_STAGE[name] then return SPELL_STAGE[name] end
  if name == "magma" and not magi.offense.state.scalded then return "scald" end
  local burns = magi.offense.liveBurns()
  if burns > 0 then return "burn " .. burns .. "/5" end
  return "build"
end

-- The Magi prompt's target line (318_Prompt_Trigger): the burns the next round will read, and the
-- stage word in brackets. tburns is not used: it holds a stale count until a round runs.
function magi.offense.promptEcho()
  local line = "Target: Burns " .. tostring(magi.offense.liveBurns())
  if magi.offense.compactOn() then
    local stage = magi.offense.stageWord()
    if stage then line = line .. " [" .. stage .. "]" end
  end
  cecho(line)
end

-- Count afflictions consuming target's mending/salve balance
-- Magi is a salve pressure class: freeze is stronger when mending is occupied
function magi.offense.countMendingAffs()
  local count = 0
  local st = magi.offense.state
  -- Broken limbs (each consumes a mending application)
  local limbs = {"brokenleftleg", "brokenrightleg", "brokenleftarm", "brokenrightarm"}
  for _, limb in ipairs(limbs) do
    if magi.offense.hasAff(limb) then count = count + 1 end
  end
  -- Burns (each burn level needs mending to cure)
  count = count + (st.burns or 0)
  -- Calcified (needs mending to cure)
  if st.calcifiedTorso then count = count + 1 end
  if st.calcifiedSkull then count = count + 1 end
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
  st.routeEarthNoted = nil   -- the water route's once-per-bonk earth note (v4.7.421)
  st.routeRefulminated = nil -- the water route's one re-fulminate per bonk (v4.7.421)
end

----------------------------------------------------------------
-- Meteorite Shield Breaking (4 variants from xMagi reference)
----------------------------------------------------------------

function magi.offense.selectMeteorite()
  local r = magi.resonance
  local st = magi.offense.state
  local fireWillBurn = (r.fire > 0) and (r.fire < 3)

  if fireWillBurn then
    return "cast meteorite at " .. target .. " flaming 4"
  elseif r.earth < 3 or st.calcifiedTorso then
    return "cast meteorite at " .. target .. " pure 4"
  elseif r.water < 3 then
    return "cast meteorite at " .. target .. " frozen 4"
  else
    return "cast erode at " .. target .. " maintain"
  end
end

----------------------------------------------------------------
-- Unified Decision Tree (based on xMagi reference)
----------------------------------------------------------------

-- What pickSpell returns in place of a command for the two picks that need more than a string:
-- the stormhammer (selectSpell sends it through magi.storm) and the water route (selectSpell runs
-- selectWaterRouteSpell, which echoes and stamps).
magi.offense.STORM = "<stormhammer>"
magi.offense.WATERROUTE = "<waterroute>"

-- THE DECISION, WITH NO SIDE EFFECTS (v4.7.430). selectSpell sends what this returns; stageWord
-- names it. v4.7.429's stage word copied the tests instead and drifted from them (in group mode it
-- said "storm" over a P7 hypothermia or a P8 mudslide). The stale-burn reset is READ here and
-- WRITTEN by selectSpell, so asking costs nothing.
function magi.offense.pickSpell()
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

  -- Stale state paranoia (from xMagi reference): no burning in V3 means no burns and no
  -- conflagration, whatever the counters say. selectSpell writes the counters back.
  local conflagrated = st.conflagrated
  if magi.offense.getAffProb("burning") == 0 then
    conflagrated = false
    burning = 0
  end

  local emearth = (not st.calcifiedTorso) and (r.earth == 3)
    and (frostbite >= 0.5 or burning > 1 or shivering >= 0.5 or not caloric)

  --=== PRIORITY 1: DESTROY (conflagrated + low HP) ===--
  if conflagrated and hp < magi.offense.config.destroyThreshold then
    return "cast destroy at " .. target
  end

  --=== PRIORITY 2: SHIELD STRIP (meteorite variants) ===--
  if magi.offense.targetShielded() then
    return magi.offense.selectMeteorite()
  end

  --=== WATER ROUTE (ww, v4.7.421) ===--
  -- Tabethys's rotation has its own selector, and it branches here because P3-P8 below would
  -- otherwise cast first: P3 glaciates only with hypothermia and water/air at 2+, P7 lays
  -- hypothermia first, and P8 mudslides on asthma at water 2 -- each a step of the route under a
  -- different gate -- while P4-P6 (stormhammer, scintilla, emanation earth) cast in its place.
  -- What still applies is above this line: the stale-burn reset (bookkeeping only), P1 DESTROY (it
  -- slays a conflagrated target at 40% health or less, Elementalism.wiki:144, and P1 casts it under
  -- destroyThreshold; the route never conflagrates, but a fire-mode round before ww can leave one)
  -- and P2's shield strip (no spell reaches a shielded target). dispatch's guards (class, balance
  -- and equilibrium, aeon, a target) ran before selectSpell.
  if mode == "waterroute" then
    return magi.offense.WATERROUTE
  end

  --=== PRIORITY 3: GLACIATE (frozen + hypothermia + dual resonance) ===--
  -- Glaciate does "terrible damage upon those that are already frozen" (Elementalism.wiki:218),
  -- so frozen is required; it was computed here and never tested. Hypothermia is read from V3,
  -- not the st.hypothermia LATCH: our hypothermia line sets the latch
  -- (magi_offense_tracking/005) and only a target change or `mm reset` clears it, so after the
  -- target applied caloric (frozen) and restoration (hypothermia) P3 kept casting glaciate at a
  -- target it does not hurt. The same V3 read lets P7 lay hypothermia again once it is cured.
  local frozen = magi.offense.getAffProb("frozen") >= 0.5
  local hypothermia = magi.offense.getAffProb("hypothermia") >= 0.5
  if frozen and hypothermia and freso then
    return "cast glaciate at " .. target
  end

  --=== PRIORITY 4: STORMHAMMER (low HP kill) ===--
  if hp <= magi.offense.config.stormhammerThreshold then
    return magi.offense.STORM
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
  if frozen and not hypothermia and freso then
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
  if shivering >= 0.5 and magi.offense.countMendingAffs() >= 1 then
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

-- The round's spell. Writes the stale-burn reset pickSpell only reads, then sends the two
-- picks that are not plain commands. nil when the stormhammer went out through magi.storm.
function magi.offense.selectSpell()
  local st = magi.offense.state
  if magi.offense.getAffProb("burning") == 0 then
    st.burns = 0
    st.conflagrated = false
    tburns = 0
  end
  local spell = magi.offense.pickSpell()
  if spell == magi.offense.WATERROUTE then
    return magi.offense.selectWaterRouteSpell()
  end
  if spell == magi.offense.STORM then
    if magi.storm and magi.storm.fire then
      magi.storm.selectTargets()
      magi.storm.fire()
      return nil -- storm.fire sends directly
    end
    return "cast stormhammer at " .. target
  end
  return spell
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
    return magi.offense.STORM   -- selectSpell sends it (v4.7.430: this sent it itself)
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
-- Water route sub-tree (ww, v4.7.421): Tabethys's rotation
----------------------------------------------------------------
-- kb/raw/players/magi-tabethys-2026-10-12.txt, curated in .claude/classes/magi.md ("Tabethys's
-- core rotation"): "magma, dehydrate, dehydrate, fulminate ... sets your water to 2 and earth to
-- 1, enabling the biggest of all bonks, the CAST MUDSLIDE for par, sli, ano, prone". Every pick
-- is read from the live state -- resonance (001_Resonance, 0-3 per plane) and the target as V3
-- holds it -- never from a step counter, so a cure, a fade or a second press re-derives the step.
-- One level per plane the spell draws on, per cast: Tabethys's log of a kill shows it (kb/CONFLICTS.md,
-- Resolved 2026-10-19; PLAYER, from their echoes). The route reads the levels the game reports, so only what the bonk
-- brings depends on that.

-- Tabethys's focus lock as a JOINT probability: paralysis (no tree), slickness (no salve) and
-- anorexia (no eating) held together in one V3 branch. Separate per-affliction tests overstate a
-- joint state while V3 branches: two 50% branches, each missing a different one, read 50% for every
-- affliction and 0% for the lock. getStateProbabilityV3 (affliction_tracking_core/007) is the joint
-- query getLockStatusV3 (008) builds Apostate's locks from. Asthma is left out on purpose: the
-- opener makes the target choose between asthma and fulminated (Tabethys), and either one left
-- standing feeds the lock; `mm` shows both. It is read for the status and the echoes, and gates
-- only the re-fulminate below: after the bonk the finisher itself adds the pressure.
local FOCUS_LOCK = { "paralysis", "slickness", "anorexia" }

function magi.offense.focusLockProb()
  if getStateProbabilityV3 then return getStateProbabilityV3(FOCUS_LOCK) end
  -- No V3: getAffProb reads tAffs, 0 or 1 each, so the product is "all three".
  local p = 1
  for _, aff in ipairs(FOCUS_LOCK) do p = p * magi.offense.getAffProb(aff) end
  return p
end

function magi.offense.focusLocked()
  return magi.offense.focusLockProb() >= 0.5
end

-- Whether we hold a health reading of THIS target. Trigger 698 stamps ataxiaTemp.lastAssessWho,
-- lastAssess and lastAssessAt for our target only, and every round ends in `assess <target>`
-- (sendAttack), so a live fight's stamp is seconds old. Names compare in any case, as isTargeted
-- does. A stamp older than ASSESS_MAX_AGE is from an earlier fight with the same name: 698's stamp
-- survives a target change (016_Targeting_Functions resets php and targetHealth, not ataxiaTemp).
local ASSESS_MAX_AGE = 30

function magi.offense.targetHPKnown()
  local t = ataxiaTemp
  local who = t and t.lastAssessWho
  if type(who) ~= "string" or type(target) ~= "string" or who:lower() ~= target:lower() then return false end
  if type(t.lastAssess) ~= "number" or type(t.lastAssessAt) ~= "number" then return false end
  return getEpoch() - t.lastAssessAt <= ASSESS_MAX_AGE
end

-- The health the route reads: 698's figure, the one that comes WITH the stamp, never getTargetHP.
-- getTargetHP returns targetHealth first, which general/001_Assess writes from any "You glance over"
-- line, whoever it names, so one manual assess of a bystander would put their health on our target.
-- nil when targetHPKnown() is false.
function magi.offense.routeTargetHP()
  if not magi.offense.targetHPKnown() then return nil end
  return ataxiaTemp.lastAssess
end

-- The pick, with no echo: returns the spell, the step ("opener", "bonk" or "finisher") and why.
function magi.offense.waterRoutePick()
  local r = magi.resonance
  local st = magi.offense.state
  local t = target
  local frozen = magi.offense.getAffProb("frozen") >= 0.5        -- as P3 computes it
  local slick = magi.offense.getAffProb("slickness") >= 0.5

  -- THE KILL: "freeze (frozen, stuttering) => glaciate (or hypothermia if they are somehow not in
  -- glaciate-kills-them-in-one range)". Glaciate needs only frozen ("terrible damage upon those
  -- that are already frozen", Elementalism.wiki:218), not P3's hypothermia and water/air 2+
  -- (kb/CONFLICTS.md #31). It comes before the major-water emanation: a frozen target is one
  -- caloric from losing it (unless slick or hypothermic), so the kill, or the hypothermia that
  -- holds frozen, does not wait, and the emanation's freeze level (:242) is wasted on a target
  -- already frozen.
  if frozen then
    local killAt = magi.offense.config.glaciateKillAt
    local hp = magi.offense.routeTargetHP()
    local known = hp ~= nil
    if killAt and (not known or hp <= killAt) then
      return "cast glaciate at " .. t, "finisher",
        known and ("frozen, health " .. hp .. "%, glaciate at " .. killAt .. "% or less") or "frozen, health unknown"
    end
    -- Hypothermia "removes their ability to heal their frozen state" (Elementalism.wiki:182).
    if magi.offense.getAffProb("hypothermia") < 0.5 then
      return "cast hypothermia at " .. t, "finisher",
        killAt and ("frozen, health " .. tostring(hp) .. "% over " .. killAt .. "%: hypothermia first")
        or "glaciate off: hypothermia first"
    end
    return "cast glaciate at " .. t, "finisher", "frozen and hypothermic"
  end

  -- AFTER THE BONK: the target is slick, so the freezes stick (shivering and frozen are cured by
  -- applying caloric, and slickness stops every salve). First keep fulminated up while the lock is
  -- not on: fulminated turns their FOCUS, the one cure the lock leaves, into paralysis ("Successful
  -- attempts to focus your mind to cure an affliction will cause you to be struck down with
  -- paralysis.", kb/raw/live/affliction_show/fulminated.txt). Down means haveAff says so (V3 under
  -- 30%), the test 021_Spell_Outcomes uses to decide a fulminate gives fulminated, so a recast it
  -- records ends this and none can loop in V3's 30-50% band. ONCE per bonk (st.routeRefulminated,
  -- stamped by selectWaterRouteSpell): a target that cures fulminated every round (tree, or a focus
  -- that turns into paralysis) would otherwise be fulminated forever while major water decays unspent
  -- and the freezes never come.
  if slick and st.routeRefulminated ~= t and not magi.offense.hasAff("fulminated")
    and not magi.offense.focusLocked() then
    return "cast fulminate at " .. t, "finisher", "fulminated is down and they are not locked"
  end
  -- "emanate water (stuttering + strips caloric)": major water, which the bonk's 2 -> 3 gives, is
  -- what the emanation needs and clears; it strips insulation (or adds a freeze level), disrupts and
  -- stutters (Elementalism.wiki:242). Major water before a bonk is spent the same way, and the
  -- opener then rebuilds water to 2: the bonk's anorexia comes from water growing 2 -> 3.
  if r.water == 3 then
    return "cast emanation at " .. t .. " water", slick and "finisher" or "opener", "major water"
  end
  -- "freeze (shivering), freeze (frozen, stuttering)": one stage a cast, insulation, then shivering,
  -- then frozen (Elementalism.wiki:304).
  if slick then
    return "cast freeze at " .. t, "finisher", "slick, not frozen yet"
  end

  -- OPENER. Scalded is read the way the moderate-fire trigger reads it (022_Resonance_Afflictions:
  -- the offense's own 20 s clock, or V3); MAGMA gives it (Elementalism.wiki:376).
  if not (st.scalded or magi.offense.hasAff("scalded")) then
    return "cast magma at " .. t, "opener", "not scalded"
  end
  -- DEHYDRATE draws on fire and water (Elementalism.wiki:325), so two of them take water to 2.
  if r.water < 2 then
    return "cast dehydrate at " .. t, "opener", "water " .. r.water .. " of 2"
  end
  -- FULMINATE at ANY fire level. The fire tree refuses it at fire 3 (fireWillBurn in
  -- selectBurningSpell); Tabethys casts it there on purpose, for fulminated and the asthma that
  -- minor air gives (Elementalism.wiki:62, :340), not for fire.
  if r.air == 0 then
    return "cast fulminate at " .. t, "opener", "air 0: fulminated + asthma"
  end

  -- BONK, at water 2 (water 3 never reaches here). The mudslide gives slickness and prone
  -- (Elementalism.wiki:364); the water it adds, 2 -> 3, gives anorexia (major water), and the
  -- earth, 1 -> 2, a short stun and paralysis (moderate earth, :62). Asthma is not required:
  -- Tabethys's opener "forces them to choose between fulminated and asthma", and either one left
  -- standing feeds the lock.
  return "cast mudslide at " .. t, "bonk", "water 2, earth " .. r.earth
end

-- "cast emanation at X water" -> "emanation water", "cast freeze at X" -> "freeze".
local function routeSpellName(spell)
  local name, rest = spell:match("^cast (%a+) at %S+%s*(.*)$")
  if not name then return spell end
  return rest ~= "" and (name .. " " .. rest) or name
end

local function routePct(p)
  return string.format("%d%%", math.floor(p * 100 + 0.5))
end

-- The route's spell for this round, echoed with its step and the lock, as the offenses echo a round.
function magi.offense.selectWaterRouteSpell()
  local st = magi.offense.state
  local spell, step, why = magi.offense.waterRoutePick()
  local lock = magi.offense.focusLockProb()
  magi.offense.echo("<gold>Route " .. step .. ": <white>" .. routeSpellName(spell) .. " <dim_grey>(" .. why .. ")"
    .. (lock >= 0.5 and " <green>LOCKED" or " <dim_grey>lock " .. routePct(lock)))
  -- At earth 1 the bonk's earth 1 -> 2 brings the paralysis that blocks the tree (moderate earth,
  -- Elementalism.wiki:62); at any other earth it lands without it. It is cast anyway: nothing in kb/
  -- confirms that magma can be cast again on a scalded target to put earth back on 1, so the route
  -- invents no earth-raising step. Said once per bonk: the note clears when the pick moves on.
  -- The one re-fulminate a bonk allows is spent when it is picked; a new bonk gives another.
  if step == "finisher" and spell:find("^cast fulminate ") then
    st.routeRefulminated = target
  elseif step == "bonk" then
    st.routeRefulminated = nil
  end
  if step == "bonk" then
    local earth = magi.resonance.earth
    local key = tostring(target) .. ":" .. earth
    if earth ~= 1 and st.routeEarthNoted ~= key then
      st.routeEarthNoted = key
      magi.offense.echo("<red>Bonk at earth " .. earth .. ": no paralysis from it (that needs earth 1 -> 2).")
    end
  else
    st.routeEarthNoted = nil
  end
  return spell
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

-- The whole round around one spell: the utility prefix, stand, the staff and shield, the spell,
-- then assess. sendAttack and the stormhammer (005 magi.storm.fire) both build it here, so a
-- stormhammer round stands and wields like every other round (v4.7.429: it sent the bare cast).
function magi.offense.buildRound(spell)
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
  return cmd .. sep .. spell .. sep .. "assess " .. target
end

function magi.offense.sendAttack(spell)
  if not spell then return end

  send("queue addclearfull freestand " .. magi.offense.buildRound(spell))

  magi.offense.castEcho(magi.offense.spellLabel(spell), target)
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
  -- waterroute (v4.7.421): Tabethys's rotation, run by ww. "water" stays what vv has always run.
  local valid = {fire = true, water = true, lock = true, salve = true, group = true, waterroute = true}
  if valid[mode] then
    if magi.offense.state.mode ~= mode then
      magi.offense.echo("<gold>Mode set to: <white>" .. mode)
    end
    magi.offense.state.mode = mode
  else
    magi.offense.echo("<red>Invalid mode: " .. tostring(mode) .. " (fire/water/lock/salve/group/waterroute)")
  end
end

function magi.offense.status()
  local st = magi.offense.state
  local r = magi.resonance or {fire=0, water=0, earth=0, air=0}

  magi.offense.echo("<gold>--- Magi Offense Status ---")
  cecho("\n <cornflower_blue>Mode: <white>" .. st.mode)
  cecho("\n <cornflower_blue>Resonance: <red>F:" .. r.fire .. " <dodger_blue>W:" .. r.water .. " <saddle_brown>E:" .. r.earth .. " <light_sky_blue>A:" .. r.air)
  -- The water route (ww, v4.7.421): the step the next round would take, the joint lock beside the
  -- two afflictions the opener makes them choose between, and where glaciate comes first.
  if st.mode == "waterroute" then
    if type(target) == "string" and target ~= "" then
      local spell, step, why = magi.offense.waterRoutePick()
      cecho("\n <cornflower_blue>Route step: <white>" .. step .. " <dim_grey>-- " .. routeSpellName(spell) .. " (" .. why .. ")")
    else
      cecho("\n <cornflower_blue>Route step: <dim_grey>no target")
    end
    local lock = magi.offense.focusLockProb()
    cecho("\n <cornflower_blue>Focus lock: " .. (lock >= 0.5 and "<green>YES" or "<dim_grey>no")
      .. " <dim_grey>(paralysis + slickness + anorexia together " .. routePct(lock)
      .. "; asthma " .. routePct(magi.offense.getAffProb("asthma"))
      .. ", fulminated " .. routePct(magi.offense.getAffProb("fulminated")) .. ")")
    local killAt = magi.offense.config.glaciateKillAt
    cecho("\n <cornflower_blue>Glaciate first: " .. (killAt
      and ("<white>at " .. killAt .. "% health or less, or unknown health")
      or "<dim_grey>off (hypothermia first)"))
  end
  cecho("\n <cornflower_blue>Burns: <orange_red>" .. st.burns .. (st.conflagrated and " <red>[CONFLAGRATED]" or ""))
  cecho("\n <cornflower_blue>Scalded: " .. (st.scalded and "<orange_red>YES" or "<dim_grey>no"))
  cecho("\n <cornflower_blue>Calcify: " .. (st.calcifiedTorso and "<red>TORSO" or "<dim_grey>-") .. " " .. (st.calcifiedSkull and "<red>SKULL" or "<dim_grey>-"))
  cecho("\n <cornflower_blue>Shalestorm: " .. (st.shalestorm and "<green>ACTIVE" or "<dim_grey>no"))
  -- Hypothermia as P3 and P7 read it, from V3. The st.hypothermia latch outlives a cure (only a
  -- target change or `mm reset` clears it), so showing it printed "Hypothermia: YES" beside a P7
  -- that was casting hypothermia again.
  local dispHypo = magi.offense.getAffProb("hypothermia") >= 0.5
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
