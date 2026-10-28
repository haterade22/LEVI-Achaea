--[[mudlet
type: script
name: RW 2H Logic
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- RuneWarden
- 2H Runie
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
===============================================================================
                    RUNEWARDEN TWO HANDED OFFENSE (rw2h, v4.7.465)
===============================================================================
The user's model (2026-10-28) -- 2H is HEALTH PRESSURE: high damage, slow attacks, stack
fractures, DEVASTATE. The victim must choose between sipping health and applying health to
cure fractures.

EVERY ROUND: BATTLEFURY PERCEIVE first, decide after its answer. Perceive shows the parried limb
and the exact fracture counts. A fracture type with no stacks prints no line, so the header line
clears the counts and the parry, and the lines that follow fill them in again.

FRACTURES (limb -> fracture -> relapse):
  head  -> skull fractures -> nausea, slower sips   ("deadly": hit the head whenever unparried)
  torso -> cracked ribs    -> sensitivity           (at least one: more damage)
  arms  -> wrist fractures -> lethargy              (one: slows their balance; attunes SLEIZAK)
  legs  -> torn tendons    -> clumsiness            (the finisher)

FOCUS (battlefury, the NEXT attack):
  SPEED     more limb damage, 1 fracture
  PRECISION less limb damage, 2 fractures
  The user's plan: SPEED hits take health until the victim SIPS. A sip means they are below the
  health they want and put health OVER curing fractures -- so stack fractures with PRECISION and
  keep the stacks up. When they switch to APPLYING health (curing fractures), back to SPEED until
  the next sip. The latest event decides: a drink (trigger 394 -> rw2h.onTargetSipped) sets
  PRECISION, an apply (trigger 153 -> rw2h.onTargetApplied) sets SPEED. A new target starts SPEED.
  The drink line does not name the elixir, so a mana sip counts too (394 already reads every
  target drink as health). Breaking a limb uses PRECISION when the
  recorded precision hit still breaks it, else SPEED. Damage is recorded per weapon AND per focus
  (rw2h.recordHit).

KILL PATHS:
  impale (default): head/torso/wrist setup -> 6 torn tendons -> DEVASTATE LEGS (level-3 break)
                    + BATTLEFURY UPSET (prone) -> IMPALE -> DISEMBOWEL
  overwhelm:        warhammer. Prone by 6 tendons + devastate + upset ("tendons", default), or
                    by breaking a leg + upset ("break"). Then break the head (prep it with
                    SPEED), stack skull fractures, BATTLEFURY OVERWHELM at 5, then BRAIN.
  Shared: DISEMBOWEL while impaled, BISECT at <= bisectAt% (no shield), CARVE/SPLINTER to raze.

RUNEBLADE: core hugalaz, configuration sowulu isaz sleizak (EMPOWER PRIORITY SET on each weapon
change). Isaz attunes on ENGAGE, which the first attack sends.
===============================================================================
]]--

rw2h = rw2h or {}

rw2h.config = rw2h.config or {
  empower            = "sowulu isaz sleizak",
  headMin            = 2,   -- skull fractures to keep up while the head is unparried
  ribsMin            = 1,   -- cracked ribs: sensitivity
  wristMin           = 1,   -- wrist fractures: lethargy
  tendonsToDevastate = 6,
  skullToOverwhelm   = 5,
  bisectAt           = 20,  -- BISECT slays an adventurer at <= 20% health
  overwhelmProne     = "tendons",  -- or "break"
  perceiveTimeout    = 1.0,
  -- Bastard venoms, first one the target lacks. The Infernal 2H list without curare: the user,
  -- 2026-10-28, "there is no way to stick curare" for 2H.
  venoms = {
    { venom = "euphorbia", aff = "nausea" },
    { venom = "kalmia",    aff = "asthma" },
    { venom = "xentio",    aff = "clumsiness" },
    { venom = "prefarar",  aff = "sensitivity" },
    { venom = "gecko",     aff = "slickness", needs = "asthma" },
  },
}

rw2h.state = rw2h.state or { mode = "impale", dmg = {} }

local LIMBS = { "head", "torso", "left arm", "right arm", "left leg", "right leg" }

--------------------------------------------------------------------------------
-- Reads
--------------------------------------------------------------------------------

function rw2h.hasAff(aff)
  if affConfigV3 and affConfigV3.enabled and haveAffV3 then return haveAffV3(aff) end
  return (tAffs and tAffs[aff]) and true or false
end

function rw2h.frac(kind)
  return (ataxiaTemp.fractures and tonumber(ataxiaTemp.fractures[kind])) or 0
end

function rw2h.parried(limb)
  return ataxiaTemp.parriedLimb == limb
end

function rw2h.hits(limb)
  return (lb and lb[target] and lb[target].hits and tonumber(lb[target].hits[limb])) or 0
end

function rw2h.isBroken(limb)
  local key = limb:gsub(" ", "")
  return rw2h.hits(limb) >= 100 or rw2h.hasAff("damaged" .. key) or rw2h.hasAff("mangled" .. key)
    or rw2h.hasAff("broken" .. key)
end

function rw2h.legBroken()
  return rw2h.isBroken("left leg") or rw2h.isBroken("right leg")
end

-- The first unparried limb of a pair (left first).
function rw2h.side(part)
  if rw2h.parried("left " .. part) then return "right " .. part end
  return "left " .. part
end

--------------------------------------------------------------------------------
-- Damage per weapon and focus. limb/004 calls recordHit with the PERCEIVE'd damage of each hit;
-- the focus is the one the game confirmed for that hit (ataxiaTemp.thfocus, trigger 695).
--------------------------------------------------------------------------------

function rw2h.recordHit(amount)
  local w = rw2h.state.lastWeapon
  amount = tonumber(amount)
  if not w or not amount then return end
  rw2h.state.dmg = rw2h.state.dmg or {}
  rw2h.state.dmg[w .. ":" .. (ataxiaTemp.thfocus or "none")] = amount
end

-- nil when we have never seen this weapon hit with this focus.
function rw2h.hitDamage(weapon, focus)
  return rw2h.state.dmg and rw2h.state.dmg[weapon .. ":" .. focus]
end

-- The target drank (trigger 394): they want health over fracture cures -> stack with PRECISION.
function rw2h.onTargetSipped()
  rw2h.state.stackFocus = "precision"
end

-- The target applied health to cure fractures (trigger 153) -> back to SPEED until they sip.
function rw2h.onTargetApplied()
  rw2h.state.stackFocus = "speed"
end

function rw2h.stackFocus()
  return rw2h.state.stackFocus or "speed"
end

-- PRECISION if a recorded precision hit still breaks the limb (2 fractures and the break), else
-- SPEED (the bigger hit). An unknown precision number never counts as breaking.
function rw2h.breakFocus(limb, weapon)
  local p = rw2h.hitDamage(weapon, "precision")
  if p and rw2h.hits(limb) + p >= 100 then return "precision" end
  return "speed"
end

--------------------------------------------------------------------------------
-- Command building
--------------------------------------------------------------------------------

local function newRound()
  return { parts = {}, reason = "" }
end

local function add(r, cmd) r.parts[#r.parts + 1] = cmd end

local function weaponId(w)
  return ataxia.getWeapon(w)
end

-- Wield the weapon; set the empower priority when the weapon changes.
local function use(r, w)
  local id = weaponId(w)
  add(r, "wield " .. id)
  if rw2h.state.empoweredFor ~= id then
    add(r, "empower priority set " .. rw2h.config.empower)
    r.empoweredFor = id
  end
  r.weapon = w
end

function rw2h.pickVenom()
  for _, v in ipairs(rw2h.config.venoms) do
    if not rw2h.hasAff(v.aff) and (not v.needs or rw2h.hasAff(v.needs)) then return v.venom end
  end
  return nil
end

local function venom(r)
  if r.weapon ~= "bastard" then return end
  local v = rw2h.pickVenom()
  if not v then return end
  local id = weaponId("bastard")
  add(r, "wipe " .. id)
  add(r, "envenom " .. id .. " with " .. v)
end

local function focus(r, f)
  add(r, "battlefury focus " .. f)
  r.focus = f
end

-- One limb hit: overhand (head), underhand (torso), hew/pulverise (arm or leg).
local function hitLimb(r, limb, f)
  local t = target
  if f then focus(r, f) end
  venom(r)
  if limb == "head" then
    add(r, "overhand " .. t)
  elseif limb == "torso" then
    add(r, "underhand " .. t)
  elseif r.weapon == "warhammer" then
    add(r, "pulverise " .. t .. " " .. limb)
  else
    add(r, "hew " .. t .. " " .. limb)
  end
  r.limb = limb
end

-- Which limb to stack a fracture on: head (unparried, below headMin), one cracked rib, one wrist
-- fracture, then the legs (the finisher). A parried limb is skipped.
function rw2h.pickStackLimb()
  local c = rw2h.config
  if not rw2h.parried("head") and rw2h.frac("skullfractures") < c.headMin then return "head", "skull fractures" end
  if not rw2h.parried("torso") and rw2h.frac("crackedribs") < c.ribsMin then return "torso", "one cracked rib" end
  if rw2h.frac("wristfractures") < c.wristMin then return rw2h.side("arm"), "one wrist fracture" end
  return rw2h.side("leg"), "torn tendons"
end

local function stack(r, prefix)
  local limb, why = rw2h.pickStackLimb()
  hitLimb(r, limb, (not r.noFocus) and rw2h.stackFocus() or nil)
  r.reason = (prefix or "") .. why .. " -> " .. limb
end

--------------------------------------------------------------------------------
-- Decisions. Each returns a round; the caller adds the queue prefix and ASSESS.
--------------------------------------------------------------------------------

local function decideShared(r)
  local t = target
  if rw2h.hasAff("impaled") then
    use(r, "bastard"); add(r, "disembowel " .. t); r.reason = "DISEMBOWEL"
    return true
  end
  local shield = rw2h.hasAff("shield") or (tAffs and tAffs.shield)
  local reb = rw2h.hasAff("rebounding") or (tAffs and tAffs.rebounding)
  if not shield and ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= rw2h.config.bisectAt then
    use(r, "bastard"); add(r, "bisect " .. t); r.reason = "BISECT at " .. ataxiaTemp.lastAssess .. "%"
    return true
  end
  if shield or reb then
    if rw2h.state.mode == "overwhelm" then
      use(r, "warhammer"); focus(r, "speed"); add(r, "splinter " .. t)
    else
      use(r, "bastard"); focus(r, "speed"); add(r, "carve " .. t)
    end
    r.reason = "raze (" .. (shield and "shield " or "") .. (reb and "rebounding" or "") .. ")"
    return true
  end
  return false
end

function rw2h.decideImpale(r)
  local t = target
  use(r, "bastard")
  if rw2h.hasAff("prone") then
    venom(r); add(r, "impale " .. t); r.reason = "IMPALE (prone)"
    return
  end
  if rw2h.frac("torntendons") >= rw2h.config.tendonsToDevastate then
    venom(r); add(r, "devastate " .. t .. " legs"); add(r, "battlefury upset " .. t)
    r.reason = "DEVASTATE LEGS + UPSET (" .. rw2h.frac("torntendons") .. " tendons)"
    return
  end
  if rw2h.legBroken() then
    -- UPSET spends battlefury balance, so this round's hit goes without a focus.
    add(r, "battlefury upset " .. t); r.noFocus = true
    stack(r, "UPSET, then ")
    return
  end
  stack(r)
end

function rw2h.decideOverwhelm(r)
  local t = target
  local c = rw2h.config
  use(r, "warhammer")
  local prone = rw2h.hasAff("prone")
  if prone and rw2h.state.overwhelmPrimed then
    add(r, "brain " .. t); r.reason = "BRAIN"; r.brain = true
    return
  end
  if prone and rw2h.frac("skullfractures") >= c.skullToOverwhelm then
    add(r, "battlefury overwhelm " .. t); r.reason = "OVERWHELM (" .. rw2h.frac("skullfractures") .. " skull)"
    r.overwhelm = true
    return
  end
  if prone then
    if not rw2h.parried("head") then
      if not rw2h.isBroken("head") then
        hitLimb(r, "head", rw2h.breakFocus("head", "warhammer")); r.reason = "break the head"
      else
        hitLimb(r, "head", "precision"); r.reason = "skull fractures for OVERWHELM"
      end
      return
    end
    stack(r, "head parried: ")
    return
  end
  if c.overwhelmProne == "tendons" and rw2h.frac("torntendons") >= c.tendonsToDevastate then
    add(r, "devastate " .. t .. " legs"); add(r, "battlefury upset " .. t)
    r.reason = "DEVASTATE LEGS + UPSET"
    return
  end
  if rw2h.legBroken() then
    add(r, "battlefury upset " .. t); r.noFocus = true
    stack(r, "UPSET, then ")
    return
  end
  if c.overwhelmProne == "break" then
    local leg = rw2h.side("leg")
    hitLimb(r, leg, rw2h.breakFocus(leg, "warhammer")); r.reason = "break " .. leg
    return
  end
  stack(r)
end

-- The whole round as one command string, or nil.
function rw2h.decide()
  local r = newRound()
  if not decideShared(r) then
    if rw2h.state.mode == "overwhelm" then rw2h.decideOverwhelm(r) else rw2h.decideImpale(r) end
  end
  add(r, "assess " .. target)
  return r
end

--------------------------------------------------------------------------------
-- Perceive, then decide
--------------------------------------------------------------------------------

local function arm(fnName, ...)
  local s = rw2h.state
  s.triggers = s.triggers or {}
  local id = fnName(...)
  s.triggers[#s.triggers + 1] = id
  return id
end

local function disarmPerceive()
  local s = rw2h.state
  for _, id in ipairs(s.triggers or {}) do killTrigger(id) end
  s.triggers = {}
  if s.perceiveTimer then killTimer(s.perceiveTimer); s.perceiveTimer = nil end
  s.awaiting = false
end

-- The header line of OUR perceive: a fresh snapshot starts here.
function rw2h.onPerceiveHeader(name)
  local s = rw2h.state
  if not s.awaiting or not name or name:lower() ~= (target or ""):lower() then return end
  ataxiaTemp.fractures = { skullfractures = 0, wristfractures = 0, torntendons = 0, crackedribs = 0 }
  ataxiaTemp.parriedLimb = "none"
  s.headerSeen = true
  if tempPromptTrigger then
    arm(tempPromptTrigger, function() rw2h.onPerceiveDone() end, 1)
  end
end

-- The perceive answer is complete (the prompt after it): decide now.
function rw2h.onPerceiveDone()
  local s = rw2h.state
  if not s.awaiting then return end
  disarmPerceive()
  s.perceivedFor = target
  rw2h.dispatch()
end

function rw2h.perceive()
  local s = rw2h.state
  s.awaiting, s.headerSeen = true, false
  arm(tempRegexTrigger, "^Narrowing your gaze upon (\\w+), you take stock of \\w+ current injuries\\.$",
    function() rw2h.onPerceiveHeader(matches[2]) end)
  s.perceiveTimer = tempTimer(rw2h.config.perceiveTimeout, function()
    if not rw2h.state.awaiting then return end
    rw2h.echo("<orange>no PERCEIVE answer -- deciding on the last known state")
    rw2h.onPerceiveDone()
  end)
  send("battlefury perceive " .. target, false)
end

--------------------------------------------------------------------------------
-- Dispatch
--------------------------------------------------------------------------------

function rw2h.echo(text)
  cecho("\n<dark_orchid>[<light_slate_blue>2H<dark_orchid>]<lavender> " .. text)
end

function rw2h.setMode(mode)
  if mode ~= "impale" and mode ~= "overwhelm" then
    return rw2h.echo("Modes: impale, overwhelm.")
  end
  rw2h.state.mode = mode
  rw2h.echo("Mode: <white>" .. mode)
end

function rw2h.sendAttack(atk)
  if not engaged then
    send("queue addclearfull free " .. atk .. ";engage " .. target)
    engaged = true
  else
    send("queue addclearfull free " .. atk)
  end
end

function rw2h.dispatch()
  local s = rw2h.state
  if not target or target == "" then return ataxiaEcho("No target set!") end
  if gmcp.Char.Vitals.bal ~= "1" then return end
  if not (ataxia.playersHere and table.contains(ataxia.playersHere, target)) then return end
  if s.awaiting then return end
  if reboundHold and reboundHold.gate(rw2h.dispatch) then return end

  if s.lastTarget ~= target then
    s.lastTarget, s.overwhelmPrimed, s.perceivedFor, s.stackFocus = target, false, nil, nil
  end
  if not lb[target] then lb[target] = { hits = {} } end
  lb[target].hits = lb[target].hits or {}
  for _, limb in ipairs(LIMBS) do lb[target].hits[limb] = lb[target].hits[limb] or 0 end
  ataxiaTemp.fractures = ataxiaTemp.fractures
    or { skullfractures = 0, wristfractures = 0, torntendons = 0, crackedribs = 0 }

  -- Perceive first; the answer calls dispatch again.
  if s.perceivedFor ~= target then return rw2h.perceive() end
  s.perceivedFor = nil

  if getLockingAffliction then getLockingAffliction() end
  if checkTargetLocks then checkTargetLocks() end

  local r = rw2h.decide()
  local sp = ataxia.settings.separator or ";"
  rw2h.sendAttack(combatQueue() .. table.concat(r.parts, sp))
  s.lastWeapon = r.weapon
  if r.empoweredFor then s.empoweredFor = r.empoweredFor end
  if r.overwhelm then s.overwhelmPrimed = true end
  if r.brain then s.overwhelmPrimed = false end
  rw2h.echo(string.format("<white>%s<dim_grey> | SF %d CR %d WF %d TT %d | parry %s%s",
    r.reason, rw2h.frac("skullfractures"), rw2h.frac("crackedribs"), rw2h.frac("wristfractures"),
    rw2h.frac("torntendons"), ataxiaTemp.parriedLimb or "none", r.focus and (" | " .. r.focus) or ""))
end

-- Manual limb hit for the q<limb>/a<limb> aliases: perceive is skipped, the limb is yours; the
-- focus follows the same SPEED/PRECISION rule as the automatic offence.
function rw2h.manual(code, weapon)
  local map = { ll = "left leg", rl = "right leg", la = "left arm", ra = "right arm", hh = "head", tt = "torso" }
  local limb = map[code]
  if not limb or not target then return end
  local r = newRound()
  if not decideShared(r) then
    use(r, weapon)
    hitLimb(r, limb, rw2h.stackFocus())
  end
  add(r, "assess " .. target)
  rw2h.sendAttack(combatQueue() .. table.concat(r.parts, ataxia.settings.separator or ";"))
  rw2h.state.lastWeapon = r.weapon
  if r.empoweredFor then rw2h.state.empoweredFor = r.empoweredFor end
end
