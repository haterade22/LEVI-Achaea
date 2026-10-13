--[[mudlet
type: script
name: CC_Shikudo_Dispatch
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Shikudo Script - Levi
- Shikudo
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[mudlet
type: script
name: CC_Shikudo
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Shikudo Script - Levi
- Shikudo
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- Shikudo Dispatch Kill Logic System
-- Focused on: Rain prep → Gaital kill → DISPATCH
-- Kill requires (wiki Dispatch, Shikudo.wiki:369): prone + damaged head + crushed windpipe (needle).
-- No leg: a broken leg only keeps her down (v4.7.420; the logged Dispatch had the kicked leg at
-- 8.4%, attacker log :2654, :2664).

shikudo = shikudo or {}
shikudo.state = {
  phase = "PREP",  -- PREP, PRONE, KILL
  -- The hyperfocused limb is not kept here: shikudo.hyperLimb() reads ataxiaTemp.hyperLimb (v4.7.420).
}

-- Options (v4.7.420). Runtime only: `shikudo` is not a saved table, and a reload keeps what is set.
shikudo.config = shikudo.config or {}
-- ASSESS after every combo and shatter round, as the monk in log 1 did ("... / assess", attacker
-- log :53) and Mystor does ("combo Agathon needle spinkick kuro right/assess Agathon",
-- LcJC-rJ5:5797). It keeps trigger 698's reading fresh for Crescent, which wants one at most 5 s
-- old; 698 then prints an HP bar each round. Never on the kill round.
if shikudo.config.assessEachRound == nil then shikudo.config.assessEachRound = true end

-- Available attacks per form
shikudo.formAttacks = {
  Tykonos = {
    kicks = {"risingkick"},
    staff = {"thrust", "sweep"}
  },
  Willow = {
    kicks = {"flashheel"},
    staff = {"dart", "hiru", "hiraku", "sweep"}
  },
  Rain = {
    kicks = {"frontkick"},
    staff = {"ruku", "kuro", "hiru"}
  },
  Oak = {
    kicks = {"risingkick"},
    staff = {"livestrike", "nervestrike", "ruku", "kuro"}
  },
  Gaital = {
    kicks = {"spinkick", "flashheel", "dawnkick"},
    staff = {"needle", "sweep", "ruku", "jinzuku", "kuro"}
  },
  Maelstrom = {
    kicks = {"risingkick", "crescent"},
    staff = {"ruku", "livestrike", "jinzuku", "sweep"}
  }
}

-- Form transition paths (from → available destinations)
shikudo.transitions = {
  Tykonos = {"Willow"},
  Willow = {"Rain"},
  Rain = {"Tykonos", "Oak"},
  Oak = {"Willow", "Gaital"},
  Gaital = {"Rain", "Maelstrom"},
  Maelstrom = {"Oak"}
}

-- When to leave each form: the shared kata policy, ataxia_KATA / ataxia_kataShouldLeave (monk/004),
-- with `skata` to override it. v4.7.420: the per-form table that stood here was only displayed; the
-- decisions were literals in shouldTransition, so editing it changed nothing.

--------------------------------------------------------------------------------
-- KILL CONDITION CHECKS
--------------------------------------------------------------------------------

function shikudo.checkDispatchReady()
  -- "If your foe is prone with a damaged head and windpipe" (Shikudo.wiki:369): three conditions.
  -- v4.7.420: no leg. It demanded a leg at 100%, which blocks a legal Dispatch once she restores
  -- her legs; the logged kill went out with the kicked leg at 8.4% (attacker log :2654, :2664).
  return shikudo.has("prone") and shikudo.headDamaged()
    and (shikudo.has("crushedthroat") or shikudo.has("damagedwindpipe"))
end

function shikudo.checkReadyForProne()
  -- At least one leg prepped enough to sweep + break
  local ll = shikudo.getLimbDamage("left leg")
  local rl = shikudo.getLimbDamage("right leg")
  return (ll >= 90 or rl >= 90)
end

function shikudo.checkLegsPrepped()
  -- Both legs have some damage for sweep effectiveness
  local ll = shikudo.getLimbDamage("left leg")
  local rl = shikudo.getLimbDamage("right leg")
  return (ll >= 70 and rl >= 70)
end

function shikudo.checkHeadPrepped()
  -- Head has enough damage to break with needle + spinkick burst
  return (shikudo.getLimbDamage("head") >= 70)
end

--------------------------------------------------------------------------------
-- DYNAMIC PREP THRESHOLDS (based on actual damage per hit)
-- "Prepped" = ONE HIT away from breaking (100%)
-- Uses lb[target].hits["limb"] for limb damage tracking
--------------------------------------------------------------------------------

-- Helper to safely get limb damage from lb[target].hits
function shikudo.getLimbDamage(limb)
  if not target or not lb or not lb[target] or not lb[target].hits then
    return 0
  end
  return lb[target].hits[limb] or 0
end

--------------------------------------------------------------------------------
-- STATE READS (v4.7.420)
-- One read per fact, so the kick, the staff strikes and the kill gate agree within a round.
--------------------------------------------------------------------------------

-- A target affliction, read only: the V3 tracker through haveAff (which falls back to tAffs while
-- V3 loads), else tAffs.
function shikudo.has(aff)
  if type(haveAff) == "function" then return haveAff(aff) and true or false end
  return (tAffs and tAffs[aff]) and true or false
end

-- Is the leg broken? A landed FLASHHEEL breaks the leg at any limb damage: "you will be able to
-- break said limb with a single blow" (Shikudo.wiki:127), and the bone-crunch line follows every
-- landed flashheel in the 2026-10-11 log, at 8.4% (attacker :70-73). Trigger 577 records it as
-- broken<side>leg; 006 used to call a leg broken only at 100% limb damage, so it never saw one.
-- A leg at 100% is damaged as well. `side` is "left" or "right".
function shikudo.legBroken(side)
  return shikudo.has("broken" .. side .. "leg") or shikudo.has("damaged" .. side .. "leg")
    or shikudo.getLimbDamage(side .. " leg") >= 100
end

-- The head as Dispatch needs it: damaged (Shikudo.wiki:369).
function shikudo.headDamaged()
  return shikudo.getLimbDamage("head") >= 100 or shikudo.has("damagedhead")
end

-- Is she still down at our next combo, even after one mend? Both legs broken, or a leg at 100%
-- (which takes restoration, not one mend). Unconfirmed from her side: whether a target with ONE
-- broken leg can stand has not been seen (our own STAND is refused with one, v4.7.416).
function shikudo.staysDown()
  return (shikudo.legBroken("left") and shikudo.legBroken("right"))
    or shikudo.getLimbDamage("left leg") >= 100 or shikudo.getLimbDamage("right leg") >= 100
    or shikudo.has("damagedleftleg") or shikudo.has("damagedrightleg")
end

-- The limb we HYPERFOCUS: strikes on it bypass her parry and deal half damage to it
-- (Shikudo.wiki:336). Trigger shikudo/003 writes ataxiaTemp.hyperLimb; 006 read
-- shikudo.state.hyperfocus, which only the uncalled setHyperfocus wrote, so the halving never
-- applied. nil once GMCP's defence list is known and no longer holds hyperfocus (deffing/001's
-- lostDef names it; Mystor's client prints "-Def: hyperfocus.", EveP2TVe:1054). The set and remove
-- lines are uncaptured, so a wrong guess here costs the halving, never an illegal combo.
function shikudo.hyperLimb()
  local l = ataxiaTemp and ataxiaTemp.hyperLimb
  if type(l) ~= "string" or l == "" or l == "none" then return nil end
  local d = ataxia and ataxia.defences
  if type(d) == "table" and next(d) ~= nil and not d.hyperfocus then return nil end
  return l
end

-- The limb she parries: a PERCEIVED parry first (trigger 148, "<T> is attempting to parry blows
-- directed at her <limb>."), else the limb of the last strike she parried (187 and parry/001 set
-- one of these true and the rest false). Read fresh every round: 006 cleared a was-parried flag on
-- every keypress, so a switch away from the parry lasted one press. Hyperfocus bypasses the parry
-- on its own limb (Shikudo.wiki:336), so that limb counts as open. The tp* globals are shared with
-- other classes' parry triggers and survive a target change: a stale one only steers a kick to
-- the other limb.
local PARRY_FLAGS = {
  { "tph", "head" }, { "tpto", "torso" }, { "tpll", "left leg" },
  { "tprl", "right leg" }, { "tpla", "left arm" }, { "tpra", "right arm" },
}
function shikudo.parriedLimb()
  local p = ataxiaTemp and ataxiaTemp.parriedLimb
  if type(p) ~= "string" or p == "" or p == "none" then
    p = nil
    for _, f in ipairs(PARRY_FLAGS) do
      if _G[f[1]] == true then p = f[2]; break end
    end
  end
  if p and p == shikudo.hyperLimb() then return nil end
  return p
end

-- The staff to WIELD: ataxia.settings.shikudoStaff (alias skstaff), else the bare keyword "staff",
-- which the user's own alias sends (attacker log :53). It was the literal staff489282, one
-- player's item id, in four places.
function shikudo.staffRef()
  local s = ataxia and ataxia.settings and ataxia.settings.shikudoStaff
  if type(s) == "string" and s ~= "" then return s end
  return "staff"
end

-- shikudo.staffCommand(arg): the `skstaff` alias (aliases shikudo/007). `skstaff` shows the staff
-- the offense wields, `skstaff <item>` sets it (an item id such as staff489282, or a keyword), and
-- `skstaff clear` goes back to the bare keyword. Saved with the settings; with no setting nothing
-- is saved, so a later default can still change.
function shikudo.staffCommand(arg)
  ataxia.settings = ataxia.settings or {}
  if arg == "" then arg = nil end
  -- Placeholders in capitals: cecho reads any <word> as a colour tag.
  if not arg then
    local set = ataxia.settings.shikudoStaff
    ataxiaEcho("Shikudo wields <cyan>" .. shikudo.staffRef() .. "<reset>"
      .. (set and "" or " (the bare keyword)") .. ". Change it: skstaff ITEM | skstaff clear")
    return
  end
  if arg:lower() == "clear" then
    ataxia.settings.shikudoStaff = nil
    ataxiaEcho("Shikudo wields <cyan>staff<reset>, the bare keyword, again.")
  else
    ataxia.settings.shikudoStaff = arg
    ataxiaEcho("Shikudo wields <cyan>" .. arg .. "<reset>.")
  end
  if ataxia_saveSettings then ataxia_saveSettings(false) end
end

-- Get damage for a specific attack (from shikudo_limbDamage table or defaults)
-- If targetLimb is provided and matches hyperfocus, damage is HALVED
-- Defaults (v4.7.420), from raw damage lines: flashheel, frontkick and kuro 8.4% (attacker log
-- :71, :361, :76; Mystor's client shows "[+8.4%]"), needle 13.4% (attacker :2659). Spinkick stays
-- 27: Mystor's +15% on a prone head (LcJC-rJ5:5803) was most likely halved by hyperfocus, as his
-- needle was (6.7 = 13.4 / 2; his client logs "-Def: hyperfocus." in two other fights).
function shikudo.getAttackDamage(attack, targetLimb)
  local defaults = {
    kuro = 8.4, thrust = 14.5, needle = 13.4, nervestrike = 13.4,
    hiru = 4.3, hiraku = 4.3, livestrike = 7.8, ruku = 4.5,
    dart = 4.4, flashheel = 8.4, risingkick = 9.2, frontkick = 8.4,
    spinkick = 27.0  -- Massive damage on prone
  }
  local baseDamage
  if shikudo_limbDamage and shikudo_limbDamage[attack] then
    baseDamage = shikudo_limbDamage[attack]
  else
    baseDamage = defaults[attack] or 10  -- Default to 10% if unknown
  end

  -- HYPERFOCUS: If attacking a hyperfocused limb, damage is HALVED (Shikudo.wiki:336)
  if targetLimb and targetLimb == shikudo.hyperLimb() then
    return baseDamage / 2
  end

  return baseDamage
end

-- CORE FUNCTION: How many hits until this limb is prepped?
-- Returns: 0 = already prepped, 1 = one hit preps it, 2+ = needs multiple
-- Note: Accounts for hyperfocus (halved damage if hyperfocused on this limb)
function shikudo.hitsToPrep(limb, attack)
  local current = shikudo.getLimbDamage(limb)
  local dmg = shikudo.getAttackDamage(attack, limb)  -- Pass limb for hyperfocus check
  local threshold = 100 - dmg  -- "Prepped" = one hit from break

  if current >= threshold then
    return 0  -- Already prepped
  elseif current + dmg >= threshold then
    return 1  -- One hit will prep it
  else
    return 2  -- Needs 2+ hits
  end
end

-- Convenience: Is limb already prepped for this attack?
function shikudo.isLimbPrepped(limb, attack)
  return shikudo.hitsToPrep(limb, attack) == 0
end

-- Convenience: Will ONE hit prep this limb?
function shikudo.willOneHitPrep(limb, attack)
  return shikudo.hitsToPrep(limb, attack) == 1
end

-- The prep thresholds take their damage from getAttackDamage, so the defaults and the hyperfocus
-- halving live in one place (v4.7.420: the head threshold used nervestrike 7.8 while hitsToPrep
-- used 13.4).
function shikudo.getLegPrepThreshold(leg)
  -- Use kuro damage as the baseline (safest threshold for legs)
  return 100 - shikudo.getAttackDamage("kuro", leg or "left leg")
end

function shikudo.getHeadPrepThreshold()
  -- Head threshold depends on form (different attacks do different damage)
  local form = ataxia.vitals.form or "Rain"
  local attack = (form == "Oak" and "nervestrike") or (form == "Gaital" and "needle") or "hiru"
  return 100 - shikudo.getAttackDamage(attack, "head")
end

function shikudo.isLegPrepped(leg)
  local limbName = (leg == "left" or leg == "LL") and "left leg" or "right leg"
  local threshold = shikudo.getLegPrepThreshold(limbName)
  return shikudo.getLimbDamage(limbName) >= threshold
end

function shikudo.areBothLegsPrepped()
  local leftThreshold = shikudo.getLegPrepThreshold("left leg")
  local rightThreshold = shikudo.getLegPrepThreshold("right leg")
  return shikudo.getLimbDamage("left leg") >= leftThreshold and shikudo.getLimbDamage("right leg") >= rightThreshold
end

-- LESSON FROM BLADEMASTER: Always hit the LOWER damage leg to balance prep
-- This ensures both legs prep at roughly the same rate
function shikudo.getFocusLeg()
  local ll = shikudo.getLimbDamage("left leg")
  local rl = shikudo.getLimbDamage("right leg")

  -- Return the leg with LESS damage (needs more prep)
  if ll <= rl then
    return "left"
  else
    return "right"
  end
end

-- Get the off-leg (the one that got less focus, higher damage)
function shikudo.getOffLeg()
  local ll = shikudo.getLimbDamage("left leg")
  local rl = shikudo.getLimbDamage("right leg")

  -- Return the leg with MORE damage (got secondary hits)
  if ll >= rl then
    return "left"
  else
    return "right"
  end
end

function shikudo.isDynamicHeadPrepped()
  return shikudo.getLimbDamage("head") >= shikudo.getHeadPrepThreshold()
end

-- Does this Gaital round SWEEP her down? selectGaitalStaff's PHASE 1: she stands, she is not
-- mounted (a sweep may only dismount a rider), and both legs and the head are prepped. The kick
-- pushes a leg to 100% beside the sweep and shouldTransition keeps Gaital for it, so all three ask
-- this one question (v4.7.420).
function shikudo.gaitalSweeps()
  return not shikudo.has("prone") and not (tmounted or (tAffs and tAffs.mounted))
    and shikudo.areBothLegsPrepped() and shikudo.isDynamicHeadPrepped()
end

--------------------------------------------------------------------------------
-- HYPERFOCUS MANAGEMENT
-- Hyperfocus bypasses parry but HALVES damage to that limb
-- IMPORTANT: Hyperfocus costs 3.4s balance, so we ALWAYS hyperfocus HEAD
-- and keep it there for the entire fight. No switching!
--------------------------------------------------------------------------------

-- Set hyperfocus state. v4.7.420: it writes ataxiaTemp.hyperLimb, the field trigger shikudo/003
-- writes and shikudo.hyperLimb() reads (it wrote shikudo.state.hyperfocus, which the trigger never
-- touched). Nothing calls it today; it is kept for a manual reset.
function shikudo.setHyperfocus(limb)
  ataxiaTemp = ataxiaTemp or {}
  if limb == "none" or limb == nil then
    ataxiaTemp.hyperLimb = nil
    cecho("\n<yellow>[Shikudo] Hyperfocus: NONE")
  else
    -- Normalize limb names
    local normalized = limb
    if limb == "left leg" or limb == "leftleg" or limb == "ll" then
      normalized = "left leg"
    elseif limb == "right leg" or limb == "rightleg" or limb == "rl" then
      normalized = "right leg"
    end
    ataxiaTemp.hyperLimb = normalized
    cecho("\n<yellow>[Shikudo] Hyperfocus: " .. normalized)
  end
end

-- Check if hyperfocus is already set to head (our target)
function shikudo.isHyperfocusSet()
  return shikudo.hyperLimb() == "head"
end

-- Get the hyperfocus command for combat start
-- We ALWAYS want hyperfocus head - set once at fight start
-- Returns: "hyperfocus head" if not set, nil if already set
function shikudo.getHyperfocusCommand()
  -- If already hyperfocused on head, no command needed
  if shikudo.hyperLimb() == "head" then
    return nil
  end

  -- Set hyperfocus to head at combat start (costs 3.4s balance but worth it)
  return "hyperfocus head"
end

-- Reset hyperfocus state (call when combat ends)
function shikudo.resetHyperfocus()
  if ataxiaTemp then ataxiaTemp.hyperLimb = nil end
end

--------------------------------------------------------------------------------
-- FORM TRANSITION LOGIC
-- Flow: Willow → Rain → Oak → Gaital (when ready)
-- Only go to Gaital when BOTH legs AND head are prepped
--------------------------------------------------------------------------------

-- The strikes an inline transition follows: a kick and two staff strikes, or a SWEEP and its kick
-- (the sweep takes both arms), which the chain counts as two: "Kata is 1" after the sweep, "Kata
-- is 2" after the flashheel, "a kata chain of 2 actions" (c.iJVmpL:3868-3872).
local STRIKES, SWEEP_STRIKES = 3, 2

-- shikudo.shouldTransition([strikes]) -> the form this combo's inline transition names, or nil.
-- `strikes` is how many strikes the combo lands, default STRIKES; buildRound passes SWEEP_STRIKES
-- for a sweep round (v4.7.420 review: it judged every round with 3, so a sweep round left a form
-- one chain early, or sent a transition the game refuses).
function shikudo.shouldTransition(strikes)
  local kata = ataxia.vitals.kata or 0
  local form = ataxia.vitals.form
  strikes = strikes or STRIKES

  -- v4.7.420: an inline `combo ... transition <form>` is judged on the chain AFTER the combo's
  -- strikes (the chain line, then the refusal: attacker log :960-961), so it is legal once
  -- kata + strikes reaches 5. It was judged on the chain before the combo, a combo late.
  if kata + strikes < ataxia_KATA.min then
    return nil  -- Need a chain of 5 after this combo to transition
  end

  -- A form's cap: the shared kata policy (monk/004, ataxia_KATA; `skata` overrides it). Leave once
  -- the chain after this combo reaches it. Policy, not a game limit: no stumble has been seen.
  -- Tykonos never stumbles, so it leaves as soon as a transition is legal.
  local atCap = ataxia_kataShouldLeave(form, kata, strikes)

  local legsPrepped = shikudo.areBothLegsPrepped()
  local headPrepped = shikudo.isDynamicHeadPrepped()

  -- ═══════════════════════════════════════════════════════════════════════════
  -- GAITAL: KILL FORM - Only enter when ready, cycle out if stuck
  -- ═══════════════════════════════════════════════════════════════════════════
  if form == "Gaital" then
    -- She is down, or this round sweeps her down: the needle, the spinkick and Dispatch all happen
    -- here, so Gaital stays, past the cap if it must (v4.7.420: this returned Maelstrom at kata 9
    -- mid-kill once her legs stopped reading prepped; the review found the sweep round itself
    -- leaving at a chain of 9 or more, the round that puts her down).
    if shikudo.has("prone") or shikudo.gaitalSweeps() then return nil end
    -- Standing, the prep not there for a sweep, and at the cap: cycle out (Maelstrom -> Oak ->
    -- back to Gaital).
    if atCap then
      return "Maelstrom"
    end
    return nil
  end

  -- ═══════════════════════════════════════════════════════════════════════════
  -- PRIORITY 0: ALL LIMBS READY → Go to Gaital for kill
  -- Only go to Gaital when BOTH legs AND head are prepped
  -- ═══════════════════════════════════════════════════════════════════════════
  if legsPrepped and headPrepped then
    if form == "Oak" then return "Gaital" end
    if form == "Rain" then return "Oak" end
    if form == "Willow" then return "Rain" end
    if form == "Tykonos" then return "Willow" end
    if form == "Maelstrom" then return "Oak" end
  end

  -- ═══════════════════════════════════════════════════════════════════════════
  -- WILLOW: Stay to the cap (12 after the combo by default)
  -- Willow is HEAD prep form (hiru, hiraku) - kicks hit legs
  -- ═══════════════════════════════════════════════════════════════════════════
  if form == "Willow" then
    if atCap then
      return "Rain"
    end
    return nil
  end

  -- ═══════════════════════════════════════════════════════════════════════════
  -- RAIN: Primary LEG prep form. Rain allows twice the normal chain (Shikudo.wiki:173); the
  -- policy leaves at 15 after the combo, as Mystor does (11 of 19 stints), not the old 24.
  -- Can also prep head with hiru - no rush to leave
  -- ═══════════════════════════════════════════════════════════════════════════
  if form == "Rain" then
    if atCap then
      return "Oak"  -- Safety transition before stumble
    end
    -- If legs are prepped, can go to Oak for head prep
    if legsPrepped and kata >= 9 then
      return "Oak"  -- Legs done, Oak has nervestrike for head
    end
    return nil  -- Stay and continue prepping
  end

  -- ═══════════════════════════════════════════════════════════════════════════
  -- OAK: HEAD prep form (nervestrike) - Go to Gaital when legs are ready
  -- Gaital can finish head prep with needle - don't cycle to Willow if legs done!
  -- ═══════════════════════════════════════════════════════════════════════════
  if form == "Oak" then
    if atCap then
      -- DEBUG: Show what legsPrepped evaluates to
      local ll = shikudo.getLimbDamage("left leg")
      local rl = shikudo.getLimbDamage("right leg")
      local leftThresh = shikudo.getLegPrepThreshold("left leg")
      local rightThresh = shikudo.getLegPrepThreshold("right leg")
      cecho("\n<grey>[Oak DEBUG] LL:" .. ll .. " >= " .. leftThresh .. "? " .. tostring(ll >= leftThresh))
      cecho(" | RL:" .. rl .. " >= " .. rightThresh .. "? " .. tostring(rl >= rightThresh))
      cecho(" | legsPrepped=" .. tostring(legsPrepped))

      -- PRIORITY 1: All limbs prepped → Gaital for kill
      if legsPrepped and headPrepped then
        return "Gaital"
      end

      -- PRIORITY 2: Both legs PREPPED → Gaital (can finish head with needle)
      -- Don't waste time cycling to Willow when legs are already done!
      if legsPrepped then
        return "Gaital"  -- Gaital has needle to prep head
      end

      -- PRIORITY 3: Both legs close + head close → Gaital
      local ll = shikudo.getLimbDamage("left leg")
      local rl = shikudo.getLimbDamage("right leg")
      local h = shikudo.getLimbDamage("head")
      local bothLegsClose = ll >= 85 and rl >= 85
      local headClose = h >= 85

      if bothLegsClose and headClose then
        return "Gaital"  -- Both legs and head close enough
      end

      -- FALLBACK: Not ready - cycle to Willow to continue prep
      return "Willow"
    end
    return nil  -- Stay and continue head prep
  end

  -- ═══════════════════════════════════════════════════════════════════════════
  -- OTHER FORMS: Route toward the main flow
  -- ═══════════════════════════════════════════════════════════════════════════
  if form == "Tykonos" then
    if atCap then return "Willow" end
    return nil
  end

  if form == "Maelstrom" then
    if atCap then return "Oak" end
    return nil
  end

  return nil
end

function shikudo.getPathToGaital(currentForm)
  -- Returns next form to transition to on path to Gaital
  local paths = {
    Tykonos = "Willow",
    Willow = "Rain",
    Rain = "Oak",
    Oak = "Gaital",
    Gaital = nil,  -- Already there
    Maelstrom = "Oak"
  }
  return paths[currentForm]
end

--------------------------------------------------------------------------------
-- KICK SELECTION
--------------------------------------------------------------------------------

-- Which leg to FLASHHEEL (v4.7.420). Every landed flashheel BREAKS the leg and adds about 8.4%
-- damage (Shikudo.wiki:127; attacker log :70-73), so the only choices are which leg, and whether to
-- take it to 100% (damaged: restoration, not one mend). Both players flashheel every Willow and
-- Gaital combo, to keep her down and mending (attacker log :53, :892, :1110, :2462-2653; Mystor
-- alternates legs). The leg is ranked, in order:
--   1. not the leg she parries;
--   2. not to 100% unless pushToDamaged (the sweep round, or she is down);
--   3. a leg that is not broken now: a fresh break is one more mend before she stands;
--   4. when pushing, a leg this kick takes to 100%, then one it leaves short, and last a leg
--      already at 100%, which the kick cannot take there: with the left leg at 100.8 the logged
--      push went right (attacker log :2474, :2560-2561);
--   5. the leg with more damage (both players focus one leg);
--   6. left on a tie.
function shikudo.flashheelKick(pushToDamaged)
  local parried = shikudo.parriedLimb()
  local best, bestKey
  for _, side in ipairs({ "left", "right" }) do
    local limb = side .. " leg"
    local dmg = shikudo.getLimbDamage(limb)
    local brink = dmg < 100 and dmg + shikudo.getAttackDamage("flashheel", limb) >= 100
    -- Item 4: 0 takes the leg to 100%, 1 leaves it short, 2 finds it there already. v4.7.420
    -- review: it scored a leg at 100% like a brink leg, so with both legs reading broken the
    -- damage tie-break kicked the leg already there.
    local push = 0
    if pushToDamaged then
      if dmg >= 100 then push = 2 elseif not brink then push = 1 end
    end
    -- Lower is better, compared item by item.
    local key = {
      parried == limb and 1 or 0,
      (brink and not pushToDamaged) and 1 or 0,
      shikudo.legBroken(side) and 1 or 0,
      push,
      -dmg,
    }
    local better = bestKey == nil
    if not better then
      for i = 1, #key do
        if key[i] ~= bestKey[i] then better = key[i] < bestKey[i]; break end
      end
    end
    if better then best, bestKey = side, key end
  end
  ataxiaTemp.kickTarget = best .. " leg"
  ataxiaTemp.lastFlashheelLeg = best
  return "flashheel " .. best
end

function shikudo.selectKick()
  local form = ataxia.vitals.form or "Rain"
  local parried = shikudo.parriedLimb() or "none"

  -- Initialize kickTarget for staff coordination
  ataxiaTemp.kickTarget = nil

  if form == "Rain" then
    -- FRONTKICK targets ARMS (different from legs/head). Keep the last arm across presses and
    -- switch only when she parries that arm (v4.7.420: a was-parried flag cleared on every
    -- keypress sent the next press straight back into the parry).
    local arm = ataxiaTemp.lastFrontkickArm or "left"
    if parried == arm .. " arm" then arm = (arm == "left") and "right" or "left" end
    ataxiaTemp.lastFrontkickArm = arm
    ataxiaTemp.kickTarget = arm .. " arm"
    return "frontkick " .. arm

  elseif form == "Oak" then
    -- OAK: Kick selection - be smart about head vs torso
    -- CRITICAL: Don't break head before legs are prepped!
    -- Staff does nervestrikes (2 slots = up to 13.4% damage to head)
    -- If nervestrikes will prep head, risingkick would BREAK it - kick torso instead
    local headHits = shikudo.hitsToPrep("head", "risingkick")
    local headHitsNerve = shikudo.hitsToPrep("head", "nervestrike")
    local legsPrepped = shikudo.areBothLegsPrepped()
    local headPrepped = shikudo.isDynamicHeadPrepped()

    if tAffs.prone then
      ataxiaTemp.kickTarget = "head"
      return "risingkick head"  -- Stuns if prone
    end

    -- If head is already prepped, kick torso to avoid breaking it
    if headPrepped then
      ataxiaTemp.kickTarget = "torso"
      return "risingkick torso"
    end

    -- If 1-2 nervestrikes will prep head (staff will do this combo), kick torso
    -- This prevents: nervestrike→prep, then risingkick→break
    if headHitsNerve <= 2 then
      ataxiaTemp.kickTarget = "torso"
      return "risingkick torso"
    end

    -- Head needs 3+ nervestrikes - safe to kick head (won't over-prep)
    if headHits >= 1 and parried ~= "head" then
      ataxiaTemp.kickTarget = "head"
      return "risingkick head"
    end

    -- Default to torso
    ataxiaTemp.kickTarget = "torso"
    return "risingkick torso"

  elseif form == "Gaital" then
    -- SPINKICK hits the head of a prone foe much harder (Shikudo.wiki:298). Mystor finishes the head
    -- with it: "combo Agathon needle spinkick kuro right" -- Needle +6.7%, Spinkick Head +15% to
    -- 100%, then DISPATCH (LcJC-rJ5:5797-5803, :5852). It takes the flashheel's place, so only while
    -- she stays down without a fresh break, and only when one needle will not finish the head alone.
    if shikudo.has("prone") and parried ~= "head" and not shikudo.headDamaged()
        and shikudo.getLimbDamage("head") + shikudo.getAttackDamage("needle", "head") < 100
        and shikudo.staysDown() then
      ataxiaTemp.kickTarget = "head"
      return "spinkick"
    end
    -- FLASHHEEL, pushed to 100% while she is down or this round sweeps (selectGaitalStaff's
    -- PHASE 1, shikudo.gaitalSweeps), as both players do: Mystor's sweep round took the left leg
    -- to 100% (c.iJVmpL:3867-3869), and the user's is "sweep flashheel left" (attacker log :2404).
    return shikudo.flashheelKick(shikudo.has("prone") or shikudo.gaitalSweeps())

  elseif form == "Willow" then
    -- FLASHHEEL. 006 never sweeps in Willow, so it keeps a leg short of 100% while the other leg
    -- can take the kick: she would only restore it before the kill. (v4.7.420: the "safe to break"
    -- planning this replaces sent a flashheel in every branch anyway, and its urgent-transition
    -- flag had no reader.)
    return shikudo.flashheelKick(false)

  elseif form == "Maelstrom" then
    -- CRESCENT if target is prone and low health
    -- v4.7.417: the health comes from ASSESS (trigger 698). v4.7.420: from its RAW numbers, of this
    -- target, at most 5 s old (ataxia_assessAtMostHalf, monk/004): the floored percentage let
    -- 3540/7000 (50.6%) through, and Crescent kills only at half health or less (Shikudo.wiki:358).
    if shikudo.has("prone") and ataxia_assessAtMostHalf(5) then
      ataxiaTemp.kickTarget = "torso"
      return "crescent"  -- Finishing move
    end
    ataxiaTemp.kickTarget = "head"
    return "risingkick head"

  else -- Tykonos
    -- RISINGKICK to the head of a prone foe stuns them (Shikudo.wiki:138), as Oak already does.
    if shikudo.has("prone") and parried ~= "head" then
      ataxiaTemp.kickTarget = "head"
      return "risingkick head"
    end

    -- RISINGKICK targets head or torso
    local headHits = shikudo.hitsToPrep("head", "risingkick")

    if headHits >= 2 and parried ~= "head" then
      ataxiaTemp.kickTarget = "head"
      return "risingkick head"
    elseif headHits == 1 and parried ~= "head" then
      ataxiaTemp.kickTarget = "head"
      return "risingkick head"
    else
      ataxiaTemp.kickTarget = "torso"
      return "risingkick torso"
    end
  end
end

--------------------------------------------------------------------------------
-- STAFF STRIKE SELECTION
--------------------------------------------------------------------------------

function shikudo.selectStaff(slot)
  local form = ataxia.vitals.form or "Rain"
  local parried = shikudo.parriedLimb() or "none"

  -- Slot 1 = primary attack, Slot 2 = secondary attack

  if form == "Rain" then
    return shikudo.selectRainStaff(slot, parried)
  elseif form == "Oak" then
    return shikudo.selectOakStaff(slot, parried)
  elseif form == "Gaital" then
    return shikudo.selectGaitalStaff(slot, parried)
  elseif form == "Willow" then
    return shikudo.selectWillowStaff(slot, parried)
  elseif form == "Maelstrom" then
    return shikudo.selectMaelstromStaff(slot, parried)
  else -- Tykonos
    return shikudo.selectTykonosStaff(slot, parried)
  end
end

function shikudo.selectTykonosStaff(slot, parried)
  -- Tykonos: THRUST (any limb), SWEEP
  -- SLOT COORDINATION: Don't hit the same limb twice if it only needs 1 hit
  -- LESSON FROM BLADEMASTER: Use getFocusLeg() for balanced prep
  -- IMPORTANT: Use LIGHT modifier to avoid breaking prepped legs when head not ready

  local leftHits = shikudo.hitsToPrep("left leg", "thrust")
  local rightHits = shikudo.hitsToPrep("right leg", "thrust")
  local headHits = shikudo.hitsToPrep("head", "thrust")
  local kickHitsHead = ataxiaTemp.kickTarget == "head"
  local focusLeg = shikudo.getFocusLeg()
  local offLeg = shikudo.getOffLeg()
  local headPrepped = shikudo.isDynamicHeadPrepped()
  local isMounted = tmounted or tAffs.mounted

  -- If all prepped, use LIGHT or sweep
  if leftHits == 0 and rightHits == 0 and headHits == 0 then
    if not tAffs.prone and not isMounted then
      if slot == 1 then
        ataxiaTemp.slot1Target = "sweep"
        return "sweep"  -- Sweep uses both arm balances
      else
        return nil  -- No second staff with sweep
      end
    else
      if slot == 1 then
        ataxiaTemp.slot1Target = "torso"
        return "thrust light torso"
      else
        return "thrust light head"
      end
    end
  end

  if slot == 1 then
    ataxiaTemp.slot1Target = nil  -- Reset tracking
    local focusLegHits = (focusLeg == "left") and leftHits or rightHits
    local offLegHits = (focusLeg == "left") and rightHits or leftHits
    local focusLegName = focusLeg .. " leg"
    local offLegName = offLeg .. " leg"

    -- LEGS first - use getFocusLeg for balanced prep
    -- SAFETY: If leg is prepped (hits == 0) and head NOT prepped, use LIGHT to avoid break
    if focusLegHits >= 1 and parried ~= focusLegName then
      ataxiaTemp.slot1Target = focusLegName
      return "thrust " .. focusLegName
    elseif offLegHits >= 1 and parried ~= offLegName then
      ataxiaTemp.slot1Target = offLegName
      return "thrust " .. offLegName

    -- HEAD
    elseif headHits >= 1 and parried ~= "head" then
      if headHits == 1 and kickHitsHead then
        ataxiaTemp.slot1Target = "torso"
        return "thrust light torso"  -- Kick preps head
      else
        ataxiaTemp.slot1Target = "head"
        return "thrust head"
      end

    -- FALLBACK: All limbs prepped - use LIGHT modifier!
    else
      ataxiaTemp.slot1Target = "torso"
      return "thrust light torso"
    end

  else  -- slot == 2
    local slot1Hit = ataxiaTemp.slot1Target or "none"
    local focusLegHits = (focusLeg == "left") and leftHits or rightHits
    local offLegHits = (focusLeg == "left") and rightHits or leftHits
    local focusLegName = focusLeg .. " leg"
    local offLegName = offLeg .. " leg"

    -- LEGS - use offLeg first (to balance), but NOT the same one slot 1 hit!
    if offLegHits >= 1 and slot1Hit ~= offLegName and parried ~= offLegName then
      return "thrust " .. offLegName
    elseif focusLegHits >= 1 and slot1Hit ~= focusLegName and parried ~= focusLegName then
      return "thrust " .. focusLegName

    -- HEAD if legs done
    elseif headHits >= 1 and slot1Hit ~= "head" and not kickHitsHead and parried ~= "head" then
      return "thrust head"

    -- FALLBACK to torso with LIGHT
    else
      return "thrust light torso"
    end
  end
end

function shikudo.selectRainStaff(slot, parried)
  -- Rain: KURO (legs), HIRU (head), RUKU (arms/torso)
  -- Rain's PRIMARY JOB is LEG PREP
  -- SLOT COORDINATION: Don't hit the same limb twice if it only needs 1 hit
  -- LESSON FROM BLADEMASTER: Always hit the LOWER damage leg first (getFocusLeg)

  local leftHits = shikudo.hitsToPrep("left leg", "kuro")
  local rightHits = shikudo.hitsToPrep("right leg", "kuro")
  local headHits = shikudo.hitsToPrep("head", "hiru")
  local focusLeg = shikudo.getFocusLeg()  -- Which leg needs more work?
  local offLeg = shikudo.getOffLeg()      -- Which leg has more damage?

  if slot == 1 then
    ataxiaTemp.slot1Target = nil  -- Reset tracking

    -- LEGS FIRST (Rain's primary job) - hit the FOCUS leg (lower damage)
    local focusLegHits = (focusLeg == "left") and leftHits or rightHits
    local offLegHits = (focusLeg == "left") and rightHits or leftHits

    if focusLegHits >= 1 and parried ~= (focusLeg .. " leg") then
      ataxiaTemp.slot1Target = focusLeg .. " leg"
      return "kuro " .. focusLeg
    elseif offLegHits >= 1 and parried ~= (offLeg .. " leg") then
      ataxiaTemp.slot1Target = offLeg .. " leg"
      return "kuro " .. offLeg

    -- LEGS PREPPED, work on head
    elseif headHits >= 1 and parried ~= "head" then
      ataxiaTemp.slot1Target = "head"
      return "hiru"
    else
      -- All prepped → afflictions (use LIGHT to avoid accidental damage)
      ataxiaTemp.slot1Target = "torso"
      if not tAffs.slickness then
        return "ruku light torso"
      else
        return "hiru light"
      end
    end

  else  -- slot == 2
    local slot1Hit = ataxiaTemp.slot1Target or "none"

    -- LEGS - Rain's PRIMARY job is leg prep, not head!
    local focusLegHits = (focusLeg == "left") and leftHits or rightHits
    local offLegHits = (focusLeg == "left") and rightHits or leftHits
    local offLegName = offLeg .. " leg"
    local focusLegName = focusLeg .. " leg"

    -- PRIORITY 1: Hit off leg if it needs work
    if offLegHits >= 1 and slot1Hit ~= offLegName and parried ~= offLegName then
      return "kuro " .. offLeg
    end

    -- PRIORITY 2: If off leg is prepped but focus leg needs 2+ hits, double-hit focus leg
    -- This is the key fix: when one leg is prepped, double-hit the unprepped leg!
    if offLegHits == 0 and focusLegHits >= 2 and parried ~= focusLegName then
      return "kuro " .. focusLeg  -- Double-hit the unprepped leg
    end

    -- PRIORITY 3: Hit focus leg if it needs work and slot 1 didn't hit it
    if focusLegHits >= 1 and slot1Hit ~= focusLegName and parried ~= focusLegName then
      return "kuro " .. focusLeg
    end

    -- HEAD only if BOTH legs are prepped
    if leftHits == 0 and rightHits == 0 then
      if headHits >= 1 and slot1Hit ~= "head" and parried ~= "head" then
        return "hiru"
      end
    end

    -- FALLBACK to afflictions/arms/torso (use LIGHT where appropriate)
    if not tAffs.slickness then
      return "ruku torso"
    elseif not tAffs.clumsiness then
      return "ruku left"
    else
      return "hiru light"
    end
  end
end

function shikudo.selectOakStaff(slot, parried)
  -- Oak: KURO (legs), NERVESTRIKE (head), LIVESTRIKE (torso), RUKU
  -- By the time we're in Oak, head should be close to prepped
  -- If head IS prepped, focus on finishing legs with kuro
  -- SLOT COORDINATION: Don't hit the same limb twice if it only needs 1 hit
  -- LESSON FROM BLADEMASTER: Use getFocusLeg() for balanced leg hits

  local leftHits = shikudo.hitsToPrep("left leg", "kuro")
  local rightHits = shikudo.hitsToPrep("right leg", "kuro")
  local headHits = shikudo.hitsToPrep("head", "nervestrike")
  local kickHitsHead = ataxiaTemp.kickTarget == "head"
  local focusLeg = shikudo.getFocusLeg()
  local offLeg = shikudo.getOffLeg()
  local headPrepped = shikudo.isDynamicHeadPrepped()
  local legsPrepped = shikudo.areBothLegsPrepped()

  if slot == 1 then
    ataxiaTemp.slot1Target = nil  -- Reset tracking
    local focusLegHits = (focusLeg == "left") and leftHits or rightHits
    local offLegHits = (focusLeg == "left") and rightHits or leftHits

    -- PRIORITY 1: If head is prepped, FOCUS ON LEGS
    if headPrepped then
      if focusLegHits >= 1 and parried ~= (focusLeg .. " leg") then
        ataxiaTemp.slot1Target = focusLeg .. " leg"
        return "kuro " .. focusLeg
      elseif offLegHits >= 1 and parried ~= (offLeg .. " leg") then
        ataxiaTemp.slot1Target = offLeg .. " leg"
        return "kuro " .. offLeg
      elseif not tAffs.asthma then
        ataxiaTemp.slot1Target = "torso"
        return "livestrike"
      else
        -- All limbs prepped, light nervestrike for paralysis
        ataxiaTemp.slot1Target = "head"
        return "nervestrike light"
      end
    end

    -- PRIORITY 2: Head not prepped - nervestrike to finish it
    if headHits >= 1 and parried ~= "head" then
      ataxiaTemp.slot1Target = "head"
      return "nervestrike"
    end

    -- FALLBACK: Work on legs
    if focusLegHits >= 1 and parried ~= (focusLeg .. " leg") then
      ataxiaTemp.slot1Target = focusLeg .. " leg"
      return "kuro " .. focusLeg
    else
      ataxiaTemp.slot1Target = "head"
      return "nervestrike light"
    end

  else  -- slot == 2
    local slot1Hit = ataxiaTemp.slot1Target or "none"
    local focusLegName = focusLeg .. " leg"
    local offLegName = offLeg .. " leg"
    local focusLegHits = (focusLeg == "left") and leftHits or rightHits
    local offLegHits = (focusLeg == "left") and rightHits or leftHits

    -- PRIORITY 1: If head is prepped, focus on legs
    if headPrepped then
      if offLegHits >= 1 and slot1Hit ~= offLegName and parried ~= offLegName then
        return "kuro " .. offLeg
      elseif focusLegHits >= 1 and slot1Hit ~= focusLegName and parried ~= focusLegName then
        return "kuro " .. focusLeg
      elseif not tAffs.asthma then
        return "livestrike"
      else
        return "nervestrike light"
      end
    end

    -- PRIORITY 2: Head needs 2+ hits - double nervestrike
    if headHits >= 2 and parried ~= "head" then
      return "nervestrike"
    end

    -- PRIORITY 3: Head needs 1 hit (slot 1 did it) - now hit legs
    if offLegHits >= 1 and slot1Hit ~= offLegName and parried ~= offLegName then
      return "kuro " .. offLeg
    elseif focusLegHits >= 1 and slot1Hit ~= focusLegName and parried ~= focusLegName then
      return "kuro " .. focusLeg

    -- FALLBACK to afflictions/arms/torso
    elseif not tAffs.asthma then
      return "livestrike"
    elseif not tAffs.clumsiness then
      return "ruku left"
    elseif not tAffs.slickness then
      return "ruku torso"
    else
      return "nervestrike light"
    end
  end
end

-- One NEEDLE crushes the windpipe: "with a single thrust of your weapon" (Shikudo.wiki:287); in the
-- logged Dispatch, "flashheel left needle jinzuku" crushed it with one (attacker log :2566,
-- :2658-2662). A second needle only adds head damage, so slot 2 needles only while slot 1's needle,
-- and a spinkick in this combo, leave the head short of 100%. Otherwise slickness (ruku torso: no
-- salve, so no mending to stand and none for the throat, which is cured by mending on the head),
-- then addiction (jinzuku), then weariness on a leg that is not broken (kuro).
function shikudo.needleSecond()
  if not shikudo.headDamaged() then
    local add = shikudo.getAttackDamage("needle", "head")
    if ataxiaTemp.kickTarget == "head" then add = add + shikudo.getAttackDamage("spinkick", "head") end
    if shikudo.getLimbDamage("head") + add < 100 then return "needle" end
  end
  if not shikudo.has("slickness") then return "ruku torso" end
  if not shikudo.has("addiction") then return "jinzuku" end
  return "kuro " .. (shikudo.legBroken("left") and "right" or "left")
end

function shikudo.selectGaitalStaff(slot, parried)
  -- Gaital: NEEDLE (head/windpipe), SWEEP (prone), KURO (legs)
  -- KILL FORM - breaking legs is INTENDED here
  -- SLOT COORDINATION: Still track to avoid hitting same unbroken leg twice
  -- Prone is read through shikudo.has here and in the Gaital kick, so kick and staff agree.

  local bothLegsPrepped = shikudo.areBothLegsPrepped()
  local headPrepped = shikudo.isDynamicHeadPrepped()
  local isMounted = tmounted or tAffs.mounted

  if slot == 1 then
    ataxiaTemp.slot1Target = nil  -- Reset tracking
  end

  -- LESSON FROM BLADEMASTER: SWEEP on mounted target might dismount instead of proning!
  -- If mounted, use needle/kuro first to dismount, then sweep next combo
  if isMounted and bothLegsPrepped and headPrepped then
    if slot == 1 then
      -- Dismount with leg attack (flashheel kick will dismount)
      -- Use needle to work on windpipe while kick dismounts
      ataxiaTemp.slot1Target = "head"
      return "needle"
    else
      return shikudo.needleSecond()
    end
  end

  -- PHASE 0: Not prone and limbs need prep -> prep first, don't sweep yet
  -- Only sweep when BOTH legs AND head are prepped
  if not shikudo.has("prone") and not isMounted and (not bothLegsPrepped or not headPrepped) then
    local leftPreppedNow = shikudo.isLegPrepped("left")
    local rightPreppedNow = shikudo.isLegPrepped("right")

    if slot == 1 then
      -- Prep legs first, then head
      if not leftPreppedNow and parried ~= "left leg" then
        ataxiaTemp.slot1Target = "left leg"
        return "kuro left"
      elseif not rightPreppedNow and parried ~= "right leg" then
        ataxiaTemp.slot1Target = "right leg"
        return "kuro right"
      elseif not headPrepped and parried ~= "head" then
        ataxiaTemp.slot1Target = "head"
        return "needle"
      else
        -- Fallback - prep what we can
        ataxiaTemp.slot1Target = "head"
        return "needle"
      end
    else
      local slot1Hit = ataxiaTemp.slot1Target or "none"
      -- Slot 2: prep the other limb that needs work
      if not rightPreppedNow and slot1Hit ~= "right leg" and parried ~= "right leg" then
        return "kuro right"
      elseif not leftPreppedNow and slot1Hit ~= "left leg" and parried ~= "left leg" then
        return "kuro left"
      elseif not headPrepped and slot1Hit ~= "head" and parried ~= "head" then
        return "needle"
      else
        return "needle"  -- Fallback to head work
      end
    end
  end

  -- PHASE 1: Not prone + ALL limbs prepped → SWEEP to prone them
  -- Only sweep when BOTH legs AND head are ready for kill sequence. The kick and shouldTransition
  -- ask the same question (shikudo.gaitalSweeps).
  if shikudo.gaitalSweeps() then
    if slot == 1 then
      ataxiaTemp.slot1Target = "sweep"
      return "sweep"  -- Prones target, kick breaks prepped leg
    else
      return nil  -- SWEEP uses both arm balances - no second staff!
    end
  end

  -- PHASE 2: she is down. Head and throat; the kick keeps her down (Dispatch needs no leg,
  -- Shikudo.wiki:369). v4.7.420: a prone target whose legs did not read prepped got kuro to the
  -- legs instead, spending the prone window on a condition the kill does not have.
  if shikudo.has("prone") then
    if slot == 1 then
      ataxiaTemp.slot1Target = "head"
      return "needle"
    end
    return shikudo.needleSecond()
  end

  -- Fallback: build toward kill conditions
  if slot == 1 then
    if not shikudo.has("prone") then
      ataxiaTemp.slot1Target = "sweep"
      return "sweep"
    end
    ataxiaTemp.slot1Target = "head"
    return "needle"
  else
    return shikudo.needleSecond()
  end
end

function shikudo.selectWillowStaff(slot, parried)
  -- Willow: DART (fast), HIRU (head), HIRAKU (head)
  -- Willow's staff focuses on HEAD, kick does legs
  -- SLOT COORDINATION: Don't hit head twice if it only needs 1 hit

  local headHits = shikudo.hitsToPrep("head", "hiru")

  if slot == 1 then
    ataxiaTemp.slot1Target = nil  -- Reset tracking

    -- HEAD: Primary focus in Willow
    if headHits >= 1 and parried ~= "head" then
      ataxiaTemp.slot1Target = "head"
      return "hiru"
    else
      ataxiaTemp.slot1Target = "torso"
      return "dart torso"
    end

  else  -- slot == 2
    local slot1Hit = ataxiaTemp.slot1Target or "none"

    -- HEAD if still needs work - but NOT if slot 1 just hit it and it only needed 1
    if headHits >= 2 and parried ~= "head" then
      return "hiraku"  -- Continue head work
    elseif headHits >= 1 and slot1Hit ~= "head" and parried ~= "head" then
      return "hiraku"

    -- HIRAKU on a prone foe also stuns (Shikudo.wiki:160); LIGHT spares a prepped head. Mystor
    -- sends it ("flashheel right hiraku light hiru light", vNTjvghY:7976).
    elseif shikudo.has("prone") and parried ~= "head" then
      return "hiraku light"

    -- FALLBACK to torso
    else
      return "dart torso"
    end
  end
end

function shikudo.selectMaelstromStaff(slot, parried)
  -- Maelstrom: RUKU, LIVESTRIKE, JINZUKU, SWEEP
  -- Affliction focused - doesn't hit legs with staff
  -- SLOT COORDINATION: Track for consistency

  if slot == 1 then
    ataxiaTemp.slot1Target = nil  -- Reset tracking
  end

  -- Check for sweep conditions (uses both arms, only kick allowed)
  if not tAffs.prone and shikudo.areBothLegsPrepped() and shikudo.isDynamicHeadPrepped() then
    if slot == 1 then
      ataxiaTemp.slot1Target = "sweep"
      return "sweep"
    else
      return nil  -- Sweep uses both arm balances
    end
  end

  -- Affliction priority
  if slot == 1 then
    if not tAffs.asthma then
      ataxiaTemp.slot1Target = "torso"
      return "livestrike"
    elseif not tAffs.slickness then
      ataxiaTemp.slot1Target = "torso"
      return "ruku torso"
    else
      ataxiaTemp.slot1Target = "torso"
      return "jinzuku"
    end
  else
    if not tAffs.slickness then
      return "ruku torso"
    elseif not tAffs.addiction then
      return "jinzuku"
    else
      return "livestrike light"
    end
  end
end

--------------------------------------------------------------------------------
-- COMBO BUILDER
--------------------------------------------------------------------------------

-- This combo's kick and two staff strikes, chosen in that order: the staff reads the kick's limb
-- (ataxiaTemp.kickTarget), and slot 2 reads slot 1's (ataxiaTemp.slot1Target).
local function selectStrikes()
  local kick = shikudo.selectKick()
  local staff1 = shikudo.selectStaff(1)
  return kick, staff1, shikudo.selectStaff(2)
end

-- shikudo.buildCombo(transition[, kick, staff1, staff2]) -> "combo $tar ...", `transition` inline.
-- It chooses the strikes unless they are given: buildRound chooses them first, so that it can judge
-- the transition on the strikes this combo lands (v4.7.420).
function shikudo.buildCombo(transition, kick, staff1, staff2)
  local form = ataxia.vitals.form
  if kick == nil then kick, staff1, staff2 = selectStrikes() end

  -- Handle sweep (uses both arm balances, limited combo)
  if staff1 == "sweep" then
    local combo
    if kick then
      combo = "combo $tar sweep " .. kick
    else
      combo = "combo $tar sweep"
    end
    -- Add inline transition if provided
    if transition then
      combo = combo .. " transition " .. transition:lower()
    end
    return combo
  end

  -- OAK: staff1 + staff2 + kick (nervestrike first for paralysis)
  -- OTHER FORMS: kick + staff1 + staff2
  local combo = "combo $tar"
  if form == "Oak" then
    -- Staff first, kick last
    if staff1 then combo = combo .. " " .. staff1 end
    if staff2 then combo = combo .. " " .. staff2 end
    if kick then combo = combo .. " " .. kick end
  else
    -- Normal order: kick first
    if kick then combo = combo .. " " .. kick end
    if staff1 then combo = combo .. " " .. staff1 end
    if staff2 then combo = combo .. " " .. staff2 end
  end

  -- Add inline transition if provided
  if transition then
    combo = combo .. " transition " .. transition:lower()
  end

  return combo
end

--------------------------------------------------------------------------------
-- ROUND BUILDER
--------------------------------------------------------------------------------

-- The tables a round reads, created when a fresh profile or a reload has not made them yet.
local function ensureState()
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}
  ataxia.settings = ataxia.settings or {}
  ataxia.settings.separator = ataxia.settings.separator or ";"
  ataxia.playersHere = ataxia.playersHere or {}
  ataxiaTemp = ataxiaTemp or {}
  tAffs = tAffs or {}
end

-- shikudo.buildRound() -> cmd, kind, transition (v4.7.420)
--   cmd         the round, WITHOUT the queue verb and without combatQueue()'s prefix:
--                 "wield <staff>;dispatch <t>"                                  kind "dispatch"
--                 "wield <staff>;incapacitate <t>"   (a Mhaldorian)             kind "incapacitate"
--                 "wield <staff>;combo <t> shatter <kick>;assess <t>"           kind "shatter"
--                 "wield <staff>;combo <t> <strikes>[ transition <form>];assess <t>"   kind "combo"
--               The kill never carries an ASSESS; shatter and combo do while
--               shikudo.config.assessEachRound is on.
--   kind        as above.
--   transition  the form the combo's inline transition names, or nil.
-- nil when there is no target. It NEVER SENDS, and never calls combatQueue(), which can itself send
-- `cq all`: shikudo.dispatch() puts "queue addclear free " and that prefix on, and
-- shikudo.dispatchMind (011) queues the round behind a MIND command. Like any round it moves the
-- per-round state the next one reads (ataxiaTemp.kickTarget, slot1Target, lastFrontkickArm,
-- lastFlashheelLeg), and shouldTransition prints its Oak debug line.
function shikudo.buildRound()
  ensureState()
  if not target or target == "" then return nil end
  local wield = "wield " .. shikudo.staffRef() .. ";"
  local assess = shikudo.config.assessEachRound and (";assess " .. target) or ""

  -- KILL CHECK: All conditions met?
  if shikudo.checkDispatchReady() then
    -- SAFETY: Use INCAPACITATE for Mhaldorians (avoid friendly fire)
    if tCity == "Mhaldor" or tCity == "(Mhaldor)" then
      return wield .. "incapacitate " .. target, "incapacitate"
    end
    return wield .. "dispatch " .. target, "dispatch"
  end

  -- SHIELD CHECK
  if tAffs.shield then
    return wield .. "combo " .. target .. " shatter " .. shikudo.selectKick() .. assess, "shatter"
  end

  -- The strikes first, then the transition the combo carries inline: it is judged on the chain
  -- after the strikes the combo lands, two in a sweep round (v4.7.420 review).
  local kick, staff1, staff2 = selectStrikes()
  local transition = shikudo.shouldTransition(staff1 == "sweep" and SWEEP_STRIKES or STRIKES)
  local attack = shikudo.buildCombo(transition, kick, staff1, staff2):gsub("%$tar", target)
  return wield .. attack .. assess, "combo", transition
end

--------------------------------------------------------------------------------
-- MAIN DISPATCH FUNCTION
--------------------------------------------------------------------------------

function shikudo.dispatch()
  -- Initialize if missing
  ensureState()

  -- Debug: Show what we have
  cecho("\n<cyan>[Shikudo] Target: " .. tostring(target))
  cecho(" | Form: " .. tostring(ataxia.vitals.form))
  cecho(" | Kata: " .. tostring(ataxia.vitals.kata))
  cecho(" | Hyperfocus: " .. tostring(shikudo.hyperLimb() or "none"))
  cecho("\n<cyan>[Shikudo] Limbs - H:" .. shikudo.getLimbDamage("head") .. " LL:" .. shikudo.getLimbDamage("left leg") .. " RL:" .. shikudo.getLimbDamage("right leg"))
  cecho(" | Ready for Prone: " .. (shikudo.checkReadyForProne() and "YES" or "NO"))

  -- Safety check - skip if no target
  if not target or target == "" then
    cecho("\n<red>[Shikudo] No target set! Use: tar <name>")
    return
  end

  -- Rebound hold gate
  if reboundHold and reboundHold.gate(shikudo.dispatch) then return end

  -- Skip player check for now during testing (can re-enable later)
  -- if not table.contains(ataxia.playersHere, target) then
  --   cecho("\n<red>[Shikudo] Target not in room")
  --   return
  -- end

  local form = ataxia.vitals.form or "Rain"  -- Default to Rain if not set
  local kata = ataxia.vitals.kata or 0

  -- Handle combatQueue - use empty string if function doesn't exist. It runs BEFORE the round is
  -- built, as it always has: it can act on the target (a Deliverance target is dropped for a new one).
  local cmd = ""
  if combatQueue then
    cmd = combatQueue()
  end

  -- HYPERFOCUS: User sets this manually before combat
  -- (Removed automatic hyperfocus - user will do this manually)

  local round, kind, transition = shikudo.buildRound()
  if not round then return end
  send("queue addclear free " .. cmd .. round)

  if kind == "incapacitate" then
    cecho("\n<yellow>*** INCAPACITATE (Mhaldorian) ***")
  elseif kind == "dispatch" then
    cecho("\n<red>*** DISPATCH KILL ***")
  elseif transition then
    cecho("\n<yellow>[Shikudo] Transitioning to " .. transition .. " after this combo")
  end

  -- Debug output
  if ataxia.debug and kind == "combo" then
    cecho("\n<cyan>[Shikudo] Form: " .. form .. " | Kata: " .. kata)
    cecho("\n<cyan>[Shikudo] H:" .. shikudo.getLimbDamage("head") .. " LL:" .. shikudo.getLimbDamage("left leg") .. " RL:" .. shikudo.getLimbDamage("right leg"))
    if transition then
      cecho("\n<yellow>[Shikudo] Transitioning to " .. transition)
    end
  end
end

-- Alias for backwards compatibility
function levishikudodispatch()
  shikudo.dispatch()
end

--------------------------------------------------------------------------------
-- STATUS COMMAND
--------------------------------------------------------------------------------

function shikudo.status()
  -- Initialize if missing
  tAffs = tAffs or {}
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}

  local form = ataxia.vitals.form or "Unknown"
  local kata = ataxia.vitals.kata or 0
  local maxKata = ataxia_kataLeaveAfter(form) or "?"  -- the policy cap (monk/004); nil for no form

  -- Get dynamic thresholds
  local legThreshold = shikudo.getLegPrepThreshold()
  local headThreshold = shikudo.getHeadPrepThreshold()
  local leftPrepped = shikudo.isLegPrepped("left")
  local rightPrepped = shikudo.isLegPrepped("right")
  local bothLegsPrepped = shikudo.areBothLegsPrepped()
  local headPrepped = shikudo.isDynamicHeadPrepped()

  local hyperfocus = shikudo.hyperLimb() or "none"
  local focusLeg = shikudo.getFocusLeg()
  local isMounted = tmounted or tAffs.mounted

  cecho("\n<cyan>╔══════════════════════════════════════════╗")
  cecho("\n<cyan>║         <white>SHIKUDO STATUS<cyan>                  ║")
  cecho("\n<cyan>╠══════════════════════════════════════════╣")
  cecho("\n<cyan>║ <white>Target: <yellow>" .. tostring(target or "None") .. (isMounted and " <red>[MOUNTED]" or "") .. "<cyan>")
  cecho("\n<cyan>║ <white>Form: <green>" .. form .. " <grey>(" .. kata .. "/" .. maxKata .. " kata)<cyan>")
  cecho("\n<cyan>║ <white>Hyperfocus: " .. (hyperfocus == "head" and "<green>HEAD" or "<yellow>" .. hyperfocus) .. "<cyan>")
  cecho("\n<cyan>╠══════════════════════════════════════════╣")
  cecho("\n<cyan>║ <white>DYNAMIC THRESHOLDS (1 hit from break):<cyan>")
  cecho("\n<cyan>║   <white>Leg Prep: <yellow>" .. string.format("%.1f%%", legThreshold) .. "<cyan>")
  cecho("\n<cyan>║   <white>Head Prep: <yellow>" .. string.format("%.1f%%", headThreshold) .. "<cyan>")
  cecho("\n<cyan>╠══════════════════════════════════════════╣")
  cecho("\n<cyan>║ <white>LIMB DAMAGE:<cyan>")
  cecho("\n<cyan>║   <white>Head: " .. (headPrepped and "<green>" or "<red>") .. string.format("%.1f%%", shikudo.getLimbDamage("head")) .. (headPrepped and " PREPPED" or ""))
  -- Show focus leg indicator (arrow points to leg being targeted)
  local leftArrow = (focusLeg == "left" and not leftPrepped) and " <yellow><-" or ""
  local rightArrow = (focusLeg == "right" and not rightPrepped) and " <yellow><-" or ""
  cecho("\n<cyan>║   <white>L Leg: " .. (leftPrepped and "<green>" or "<red>") .. string.format("%.1f%%", shikudo.getLimbDamage("left leg")) .. (leftPrepped and " PREPPED" or "") .. leftArrow)
  cecho("\n<cyan>║   <white>R Leg: " .. (rightPrepped and "<green>" or "<red>") .. string.format("%.1f%%", shikudo.getLimbDamage("right leg")) .. (rightPrepped and " PREPPED" or "") .. rightArrow)
  cecho("\n<cyan>╠══════════════════════════════════════════╣")
  cecho("\n<cyan>║ <white>KILL CONDITIONS:<cyan>")
  cecho("\n<cyan>║   <white>Prone: " .. (shikudo.has("prone") and "<green>YES" or "<red>NO"))
  cecho("\n<cyan>║   <white>Head Broken: " .. (shikudo.headDamaged() and "<green>YES" or "<red>NO"))
  cecho("\n<cyan>║   <white>Windpipe: " .. ((shikudo.has("damagedwindpipe") or shikudo.has("crushedthroat")) and "<green>YES" or "<red>NO"))
  cecho("\n<cyan>║   <white>DISPATCH READY: " .. (shikudo.checkDispatchReady() and "<green>*** YES ***" or "<red>NO"))
  cecho("\n<cyan>╠══════════════════════════════════════════╣")
  cecho("\n<cyan>║ <white>PREP STATUS:<cyan>")
  -- Not a kill condition (v4.7.420): a broken leg keeps her down while the head and throat go.
  cecho("\n<cyan>║   <white>Leg broken (holds her down): " .. ((shikudo.legBroken("left") or shikudo.legBroken("right")) and "<green>YES" or "<red>NO"))
  cecho("\n<cyan>║   <white>Focus Leg: <yellow>" .. focusLeg:upper() .. " <grey>(lower damage, hit first)")
  cecho("\n<cyan>║   <white>Both Legs Prepped: " .. (bothLegsPrepped and "<green>YES" or "<yellow>NO"))
  cecho("\n<cyan>║   <white>Head Prepped: " .. (headPrepped and "<green>YES" or "<yellow>NO"))
  cecho("\n<cyan>║   <white>Ready for Gaital: " .. ((bothLegsPrepped and headPrepped) and "<green>YES" or "<yellow>NO"))
  cecho("\n<cyan>╚══════════════════════════════════════════╝\n")
end

-- Alias: skstatus
function skstatus()
  shikudo.status()
end
