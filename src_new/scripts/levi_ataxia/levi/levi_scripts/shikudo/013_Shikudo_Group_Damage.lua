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

-- SHIKUDO GROUP DAMAGE ROUTE (v4.7.456; no combos since 2026-11-02). The user, after the 2026-10-27
-- group fight: "We would also need to add a pure damage route for group combat for shikudo." In a
-- group the lock (007) rarely holds, so this route hits as hard as it can every round, and takes a kill
-- when one is open.
--
-- THE RULE (the user, 2026-11-02): "It should do mind crush in rain when doing srd for damage. If we
-- cannot mind crush then kai choke. No combos in srd as, once again it is for damage."
--
-- WHY THE OLD RIDER WENT. This route used to send `combo <t> ...; <rider>` as one round. A combo needs
-- equilibrium up, and MIND CRUSH and KAI CHOKE need balance up, so the two cannot share a flush in either
-- order (kb/raw/live/probes_2026-11-01.txt, kb/CONFLICTS.md #56). The game held the rider in its BALANCE
-- queue, which `queue addclear free` does not clear, so a held rider could fire after a target switch.
-- The basher learned the same thing at v4.7.459 (basher/002, MIND CRUSH, THE INT MONK'S ATTACK).
--
-- ONE ROUND = ONE `queue addclear free` entry. `free` waits for balance and equilibrium, which is
-- what each of these attacks needs. The first that applies:
--   1. DISPATCH when 006 says it is ready (prone, damaged head, crushed throat; Shikudo.wiki:369). Any
--      form. A Mhaldorian gets INCAPACITATE, as in 006.
--   2. CRESCENT alone, only if we are already in Maelstrom and she is prone at half health or less.
--      The user said yes to this kill on 2026-10-27. This route never moves to Maelstrom.
--   3. Not in Rain: `adopt rain form`, alone. It needs no kata, and it spends balance (about 4.1 s), so a
--      crush in the same round would be refused and held. Rain is the point: it makes equilibrium about 15%
--      cheaper (our MIND CRUSH: 2.45 s against 2.89 s; the 2.89 is the wiki's 3.40 through the Aldar
--      Diadem, ataxia_eqFactor), and the form stays at kata 0. A crush saves about 0.44 s in Rain, so the
--      4.1 s ADOPT pays back after about 10 crushes.
--   4. MIND CRUSH. If we cannot, KAI CHOKE. If we can do neither, nothing goes out, and one line says why.
--
-- A SHIELD CHANGES NOTHING: MIND CRUSH passes a target's shield (the user, 2026-11-02), so this route has
-- no shatter and no combo other than the Crescent kill.
--
-- "CANNOT" FOR A CRUSH: it costs 150 mana, and we keep the `manause` floor (sipping, default 30%) after it,
-- because mana is the curing pool (shikudo.manaAllows, 006). An unknown mana does not block a crush.
-- "CANNOT" FOR A CHOKE: kai is short (ataxia_kaiAfford), or the target is thought to hold its breath.
--
-- HELD BREATH: no captured line says a target holds its breath. Until one is, a KAI CHOKE cast line
-- (leviatax/004 -> shikudoDmg.chokeCast) with no landing line (highlighting/063) within BREATH_WAIT
-- seconds marks the target for BREATH_HOLD seconds. The echo asks to keep the lines, so the real one
-- can be captured.
--
-- `srd` runs this route (alias shikudo/009); `sr` stays the lock (007). The user: "sr should be
-- lock, srd should be damage".

shikudoDmg = shikudoDmg or {}
shikudoDmg.state = shikudoDmg.state or { breathHeld = {} }
shikudoDmg.config = shikudoDmg.config or {
  assessEachRound = true, -- with the Health Inspector trait only (shikudo.assessSuffix, 006)
}

local BREATH_WAIT = 1.2
local BREATH_HOLD = 10
local MIND_CRUSH_MANA = 150

ataxiaTemp = ataxiaTemp or {}

local function has(aff)
  if haveAff then return haveAff(aff) and true or false end
  return tAffs ~= nil and tAffs[aff] and true or false
end

local function now() return (getEpoch and getEpoch()) or 0 end

local function formNow()
  return ataxia_shikudoForm(ataxia.vitals and ataxia.vitals.form) or "Oak"
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

-- Is the target thought to hold its breath? (the KAI CHOKE fallback above)
function shikudoDmg.breathHeld(t)
  local until_ = type(t) == "string" and shikudoDmg.state.breathHeld[t:lower()]
  return until_ ~= nil and until_ ~= false and now() < until_
end

-- Can we pay for a MIND CRUSH and still hold the mana floor? Unknown mana answers yes.
function shikudoDmg.canCrush()
  return shikudo.manaAllows(MIND_CRUSH_MANA)
end

-- Can we KAI CHOKE this target?
function shikudoDmg.canChoke(t)
  local afford = ataxia_kaiAfford and ataxia_kaiAfford("choke", 0, t)
  return (afford and not shikudoDmg.breathHeld(t)) and true or false
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
    cecho("\n<yellow>[SK] KAI CHOKE did not land on " .. t .. " -- breath held? No choke for "
      .. BREATH_HOLD .. "s (keep these lines)")
  end)
end

-- Build the round. Returns the line (without "queue addclear free " and combatQueue's prefix) and its
-- kind: "dispatch", "incapacitate", "crescent", "adopt", "crush" or "choke". With a target
-- but nothing we can pay for, it returns nil and "none". Sends nothing.
function shikudoDmg.buildRound()
  if type(target) ~= "string" or target == "" then return nil end
  local sep = ";"
  local wield = "wield " .. shikudo.staffRef() .. sep
  local form = formNow()

  if shikudo.checkDispatchReady and shikudo.checkDispatchReady() then
    if shikudo.targetIsMhaldorian() then
      return wield .. "incapacitate " .. target, "incapacitate"
    end
    return wield .. "dispatch " .. target, "dispatch"
  end

  local assess = shikudo.assessSuffix(shikudoDmg.config.assessEachRound, sep)

  -- Alone: the kick drops us into Tykonos at once (Shikudo.wiki:358). A one-attack combo is legal.
  if form == "Maelstrom" and shikudoDmg.crescentReady() then
    return wield .. "combo " .. target .. " crescent", "crescent"
  end

  if form ~= "Rain" then return wield .. "adopt rain form", "adopt" end

  if shikudoDmg.canCrush() then return "mind crush " .. target .. assess, "crush" end
  if shikudoDmg.canChoke(target) then return "kai choke " .. target .. assess, "choke" end
  return nil, "none"
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
  local line, kind = shikudoDmg.buildRound()
  if not line then
    if kind == "none" then say("\n<yellow>[SKD] No attack: mana at its floor, and no kai choke") end
    return
  end
  send("queue addclear free " .. cmd .. line)
  local note = (kind == "dispatch" and "<red>DISPATCH") or (kind == "incapacitate" and "<yellow>INCAPACITATE")
    or (kind == "crescent" and "<red>CRESCENT")
    or (kind == "adopt" and "<cyan>adopt Rain") or (kind == "choke" and "<cyan>kai choke") or "<cyan>mind crush"
  say("\n<cyan>[SKD] " .. note)
end

-- The `srd` alias. Like `sr`, it needs a Shikudo Form charstat: a Tekura monk has none.
function shikudoDmg.group()
  if not (ataxia and ataxia.vitals and ataxia.vitals.form) then
    if ataxiaEcho then ataxiaEcho("srd: no Shikudo form read -- the group damage route needs Shikudo.") end
    return
  end
  return shikudoDmg.dispatch()
end
