--[[mudlet
type: script
name: Shikudo Group Damage
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

-- SHIKUDO GROUP DAMAGE ROUTE (v4.7.456). The user, after the 2026-10-27 group fight: "We would also
-- need to add a pure damage route for group combat for shikudo." In a group the lock (007) rarely
-- holds -- five players cure through it and the target changes every few seconds -- so this route
-- hits as hard as it can every round, and takes a kill when one is open.
--
-- The user's rules for equilibrium: "If in rain form we can kai choke (if they are not holding
-- breath) or mind crush. We should prioritize combos elsewise as they do damage and give
-- afflictions." And yes to both instant kills, Crescent and Dispatch.
--
-- ONE ROUND = ONE `queue addclear free` entry (as 006 and 007 send):
--   combatQueue() .. wield <staff id> ; [transition to <form> form ;] <attack> [; <eq rider>] [; assess]
--
-- THE ATTACK, first that applies:
--   1. DISPATCH when 006 says it is ready (prone, damaged head, crushed throat; Shikudo.wiki:369).
--      Any form, outside a combo, no assess. A Mhaldorian gets INCAPACITATE, as in 006.
--   2. SHATTER first when the target has a shield, with this form's kick.
--   3. The form's damage combo (every attack legal in its form, Shikudo.wiki):
--        Oak        risingkick torso livestrike ruku torso   (31.8% torso a round in the log, with
--                   asthma and slickness; a damaged torso makes KAI CHOKE hit harder, Kaido.wiki:289)
--        Maelstrom  the same, or CRESCENT alone once she is prone at half health or less
--        Gaital     standing: sweep spinkick; prone: needle spinkick ruku torso (spinkick on a prone
--                   target strikes the head, "significantly more damage"; needle crushes the throat
--                   Dispatch needs)
--        Rain       frontkick <side> kuro <side> ruku torso, plus the EQ rider
--        Willow     flashheel <side> hiru hiraku           (only on the way to Rain)
--        Tykonos    risingkick torso thrust torso thrust torso (only on the way to Willow)
-- THE EQ RIDER, RAIN ONLY: KAI CHOKE when kai affords it (ataxia_kaiAfford) and the target is not
-- thought to hold its breath; MIND CRUSH otherwise.
-- THE FORM LOOP (each step a legal transition, Shikudo.wiki): Oak -> Gaital -> Maelstrom (when the
-- target is known at 60% or less) or Rain; Maelstrom -> Oak; Rain -> Oak; Willow -> Rain;
-- Tykonos -> Willow. When to leave is monk/004's policy (ataxia_kataShouldLeave; `skata`), except
-- Willow and Tykonos, which leave as soon as a transition is legal. The transition goes FIRST in
-- the command, so it is judged on the chain before the combo (strikes 0), as 007 does.
--
-- HELD BREATH: no captured line says a target holds its breath. Until one is, a KAI CHOKE cast line
-- (leviatax/004 -> shikudoDmg.chokeCast) with no landing line (highlighting/063) within
-- BREATH_WAIT seconds marks the target for BREATH_HOLD seconds, and the rider is MIND CRUSH. The
-- echo asks to keep the lines, so the real one can be captured.
--
-- `srd` runs this route (alias shikudo/009); `sr` stays the lock (007). The user: "sr should be
-- lock, srd should be damage".

shikudoDmg = shikudoDmg or {}
shikudoDmg.state = shikudoDmg.state or { side = "left", breathHeld = {} }
shikudoDmg.config = shikudoDmg.config or {
  assessEachRound = true, -- with the Health Inspector trait only (shikudo.assessSuffix, 006)
  maelstromAt = 60,       -- Gaital leads to Maelstrom (and its Crescent) at or below this health %
}

local BREATH_WAIT = 1.2
local BREATH_HOLD = 10

ataxiaTemp = ataxiaTemp or {}

local function has(aff)
  if haveAff then return haveAff(aff) and true or false end
  return tAffs ~= nil and tAffs[aff] and true or false
end

local function now() return (getEpoch and getEpoch()) or 0 end

local function formNow()
  return ataxia_shikudoForm(ataxia.vitals and ataxia.vitals.form) or "Oak"
end

-- The side this round's frontkick, kuro and flashheel use. It alternates each combo, so both arms
-- and both legs take the prone and weariness hits.
local function side()
  return shikudoDmg.state.side
end
local function flipSide()
  shikudoDmg.state.side = (shikudoDmg.state.side == "left") and "right" or "left"
end

-- The target's health, as a percentage, when we know it: a fresh ASSESS of this target (698), else
-- the server's own target health (IRE.Target.Info.hpperc) when it names our target. nil = unknown.
function shikudoDmg.targetHealth()
  local t = ataxiaTemp
  if t.lastAssessAt and type(t.lastAssessWho) == "string" and type(target) == "string"
     and t.lastAssessWho:lower() == target:lower() and now() - t.lastAssessAt <= 5 then
    local hp, max = tonumber(t.lastAssessHp), tonumber(t.lastAssessMax)
    if hp and max and max > 0 then return hp * 100 / max end
  end
  local ti = gmcp and gmcp.IRE and gmcp.IRE.Target and gmcp.IRE.Target.Info
  if type(ti) == "table" and type(target) == "string" and type(ti.short_desc) == "string"
     and ti.short_desc:lower():find(target:lower(), 1, true) then
    local p = tonumber((tostring(ti.hpperc or ""):gsub("%%", "")))
    if p and p >= 0 then return p end
  end
  return nil
end

-- Crescent kills a prone foe "if that foe has half their health or less"; otherwise it is dodged
-- and recovery is "greatly increased", and the monk drops to Tykonos either way (Shikudo.wiki:358).
-- So only a known health of 50% or less passes.
function shikudoDmg.crescentReady()
  if not has("prone") then return false end
  if ataxia_assessAtMostHalf and ataxia_assessAtMostHalf(5) then return true end
  local hp = shikudoDmg.targetHealth()
  return hp ~= nil and hp <= 50
end

-- The next form of the loop, or nil to stay.
function shikudoDmg.nextForm(form, kata)
  kata = tonumber(kata) or 0
  if form == "Willow" or form == "Tykonos" then
    if kata < ataxia_KATA.min then return nil end
    return (form == "Willow") and "Rain" or "Willow"
  end
  if not ataxia_kataShouldLeave(form, kata, 0) then return nil end
  if form == "Oak" then return "Gaital" end
  if form == "Gaital" then
    local hp = shikudoDmg.targetHealth()
    return (hp and hp <= shikudoDmg.config.maelstromAt) and "Maelstrom" or "Rain"
  end
  if form == "Maelstrom" or form == "Rain" then return "Oak" end
  return nil
end

-- The combo for `form` (the form this round strikes in), without the "combo <target>" prefix.
function shikudoDmg.comboFor(form)
  local s = side()
  if form == "Oak" then
    return "risingkick torso livestrike ruku torso"
  elseif form == "Maelstrom" then
    -- Alone: the kick drops us into Tykonos at once (Shikudo.wiki:358), where livestrike and ruku
    -- are not attacks. A one-attack combo is legal (006 sends "combo <t> sweep").
    if shikudoDmg.crescentReady() then return "crescent", "crescent" end
    return "risingkick torso livestrike ruku torso"
  elseif form == "Gaital" then
    if has("prone") then return "needle spinkick ruku torso" end
    return "sweep spinkick"
  elseif form == "Rain" then
    return "frontkick " .. s .. " kuro " .. s .. " ruku torso"
  elseif form == "Willow" then
    return "flashheel " .. s .. " hiru hiraku"
  end
  return "risingkick torso thrust torso thrust torso" -- Tykonos
end

-- The kick SHATTER goes with in `form`.
local SHATTER_KICK = {
  Oak = "risingkick torso", Maelstrom = "risingkick torso", Tykonos = "risingkick torso",
  Gaital = "spinkick", Rain = "frontkick left", Willow = "flashheel left",
}

-- Is the target thought to hold its breath? (the KAI CHOKE fallback above)
function shikudoDmg.breathHeld(t)
  local until_ = type(t) == "string" and shikudoDmg.state.breathHeld[t:lower()]
  return until_ ~= nil and until_ ~= false and now() < until_
end

-- The Rain rider: "kai choke <t>" or "mind crush <t>".
function shikudoDmg.eqRider(t)
  local afford = ataxia_kaiAfford and ataxia_kaiAfford("choke", 0, t)
  if afford and not shikudoDmg.breathHeld(t) then return "kai choke " .. t, "choke" end
  return "mind crush " .. t, "crush"
end

-- leviatax/004: our KAI CHOKE cast line. With no landing line (highlighting/063) within BREATH_WAIT
-- seconds, the target is taken to hold its breath for BREATH_HOLD seconds.
function shikudoDmg.chokeCast(t)
  if type(t) ~= "string" then return end
  local castAt = now()
  shikudoDmg.state.lastChokeAt = castAt
  if not tempTimer then return end
  tempTimer(BREATH_WAIT, function()
    local landed = tonumber(ataxiaTemp.kaiChokeLandedAt) or 0
    if landed >= castAt then return end
    shikudoDmg.state.breathHeld[t:lower()] = now() + BREATH_HOLD
    cecho("\n<yellow>[SK] KAI CHOKE did not land on " .. t .. " -- breath held? MIND CRUSH for "
      .. BREATH_HOLD .. "s (keep these lines)")
  end)
end

-- Build the round. Returns the line (without "queue addclear free " and combatQueue's prefix), its
-- kind ("dispatch", "incapacitate", "shatter", "crescent", "combo"), the transition (or nil) and
-- the rider kind (or nil). Sends nothing.
function shikudoDmg.buildRound()
  if type(target) ~= "string" or target == "" then return nil end
  local sep = ";"
  local wield = "wield " .. shikudo.staffRef() .. sep
  local form = formNow()

  if shikudo.checkDispatchReady and shikudo.checkDispatchReady() then
    if tCity == "Mhaldor" or tCity == "(Mhaldor)" then
      return wield .. "incapacitate " .. target, "incapacitate"
    end
    return wield .. "dispatch " .. target, "dispatch"
  end

  local assess = shikudo.assessSuffix(shikudoDmg.config.assessEachRound, sep)
  if has("shield") or (tAffs and tAffs.shield) then
    return wield .. "combo " .. target .. " shatter " .. (SHATTER_KICK[form] or "risingkick torso")
      .. assess, "shatter"
  end

  -- A Crescent that is ready is never traded for a transition out of Maelstrom.
  local nextForm = not (form == "Maelstrom" and shikudoDmg.crescentReady())
    and shikudoDmg.nextForm(form, ataxia.vitals and ataxia.vitals.kata) or nil
  local trans = nextForm and ("transition to " .. nextForm:lower() .. " form" .. sep) or ""
  local roundForm = nextForm or form
  local combo, special = shikudoDmg.comboFor(roundForm)
  local line = wield .. trans .. "combo " .. target .. " " .. combo
  local rider
  if roundForm == "Rain" then
    local cmd
    cmd, rider = shikudoDmg.eqRider(target)
    line = line .. sep .. cmd
  end
  return line .. assess, special or "combo", nextForm, rider
end

-- One echo per changed round, so a held key does not flood the screen.
local function say(s)
  if s ~= shikudoDmg.state.lastSay then
    cecho(s)
    shikudoDmg.state.lastSay = s
  end
end

function shikudoDmg.dispatch()
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}
  ataxia.settings = ataxia.settings or {}
  tAffs = tAffs or {}
  if type(target) ~= "string" or target == "" then
    cecho("\n<red>[SKD] No target set! Use: tar NAME")
    return
  end
  if reboundHold and reboundHold.gate(shikudoDmg.dispatch) then return end
  if not shikudo.guardTarget(target) then return end
  local cmd = combatQueue and combatQueue() or ""
  local line, kind, nextForm, rider = shikudoDmg.buildRound()
  if not line then return end
  send("queue addclear free " .. cmd .. line)
  if kind == "combo" or kind == "crescent" then flipSide() end
  local note = (kind == "dispatch" and "<red>DISPATCH") or (kind == "incapacitate" and "<yellow>INCAPACITATE")
    or (kind == "crescent" and "<red>CRESCENT") or (kind == "shatter" and "<cyan>shatter")
    or "<cyan>combo"
  say("\n<cyan>[SKD] " .. note .. "<cyan>"
    .. (nextForm and (" | to " .. nextForm) or "")
    .. (rider and (" | " .. (rider == "choke" and "kai choke" or "mind crush")) or ""))
end

-- The `srd` alias. Like `sr`, it needs a Shikudo Form charstat: a Tekura monk has none.
function shikudoDmg.group()
  if not (ataxia and ataxia.vitals and ataxia.vitals.form) then
    if ataxiaEcho then ataxiaEcho("srd: no Shikudo form read -- the group damage route needs Shikudo.") end
    return
  end
  return shikudoDmg.dispatch()
end
