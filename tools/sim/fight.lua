--- fight.lua -- the whole-fight engine (plan step 7.2, stage 1): an attacker against a victim, event by event.
-- Pure Lua 5.1: no Mudlet calls, no files, no globals. tools/theorycraft.py and test_sim_fight.lua load it,
-- then call F.wire(forward, victim, attackers): forward.lua gives the random numbers (forward.lua:21), and
-- forward.lua itself stays byte-identical, because its bytes feed kb_sim.py's input hash.
--
-- It writes the event stream of tools/kb_events.py, version 1, in the "true" view: what really happened on the
-- engine's board. The names and kinds are kb_events' own: an eat is kind "cure" with args {channel, item}, a smoke
-- and a salve have args {item}, a class cure is kind "classcure" and its lockout's end is "recover <its name>", a
-- DSTAB prints its second-venom part, a DSTAB on a shield is "blocked.shield", and balance and equilibrium come back
-- as "recover bal" and "recover eq". Each event has a row (its place in the run), so kb_events.race() and census()
-- read a sim fight as they read a log (tools/test_theorycraft.py checks the race and the census keys).
-- Known differences: an item is the rule's word ("bloodroot", "epidermal to body"), where a log prints the game's
-- ("bloodroot leaf", the salve's location "body"); the engine has no miss, no refusal and no spend line. It writes no
-- prompt, and it writes world lines (side "W") that no log has: a "give", the hypochondria chain's steps and the soft
-- and true labels, and "sileris.unhardened" (an apply that slickness stopped), so kb_events.census() of a run has the
-- keys give, hypochondria, soft, true and sileris.unhardened (review ENG-2).
-- One attack name is the engine's own too: "flay", a FLAY that strips nothing and cannot whip (attackers.lua A.lines).
-- So are two parts: "impulse" (kind hypnosis), the suggestion of an IMPULSE, whose attack is "bite"; and "reaction",
-- a reaction that fired, with the venom in its args. A cure event carries "ssc", the case of the SSC delay before it
-- (victim.lua V.delay: "gain" or "return").
-- Every number comes from the rules table (kb/sim/rules.json); a run is a MODEL, not a log.

local F = {}
local R, V, A

-- kb_timing.py:778-779: a second line of one attack within BUNDLED is the same attack, and an attack DISENGAGED or
-- more after the last one starts a new engagement, so it pairs with nothing.
F.BUNDLED = 0.3
F.DISENGAGED = 10.0

--- Connect the three other files. Returns F, so a caller can write F = dofile(...).wire(...).
function F.wire(forward, victim, attackers)
  R, V, A = forward, victim, attackers
  return F
end

-- Each source has its own stream, as in forward.lua:30-40, so two runs with one seed see the same draws where
-- they did the same thing.
-- A new stream goes at the end, so the others keep their seeds.
local STREAMS = { "attacker", "eat", "smoke", "salve", "focus", "tree", "pick", "class", "ssc", "dagaz", "shield",
                  "sileris", "attackerEq" }
local MOD = 2147483647

-- a * b mod MOD, exact in doubles: b is split into 16-bit halves, so no product passes 2^47.
local function mulmod(a, b)
  local hi, lo = math.floor(b / 65536), b % 65536
  return ((a * hi) % MOD * 65536 + a * lo) % MOD
end

--- The seed of stream i. forward.lua's Park-Miller generator is linear, so streams seeded with seed * k + i * c are
--- shifted copies of one another: the k-th eat draw was the k-th gap draw plus a constant, and the two correlated
--- 0.78 over seeds (review TC-02). Four rounds of a square plus a constant mix the seed and i in a way that is not
--- linear. tools/test_theorycraft.py checks that the gap and eat draws do not correlate over 400 seeds.
function F.streamSeed(seed, i)
  local x = (seed * 7919 + i * 104729) % MOD
  for _ = 1, 4 do
    x = (mulmod(x, x) + 1013904223 + i) % MOD
    x = mulmod(x, 48271)
  end
  if x == 0 then x = i end
  return x
end

local function streams(seed)
  local out = {}
  for i, name in ipairs(STREAMS) do
    out[name] = R.rng(F.streamSeed(seed, i))
  end
  return out
end

local READY = { "eat", "smoke", "salve", "focus", "tree", "class", "bal", "eq" }
local CLASS_NAME = { fitness = "fitness", salt = "salt", accelerate = "accelerate" }

local function newState(start, model)
  -- waiting: a channel that was shut at the last moment with an affliction for it (curing, the SSC delay's case).
  -- pendingCase: the case of each pending action's delay. attEq: when the attacker's equilibrium is back (an IMPULSE).
  local s = { affs = {}, ready = {}, down = {}, defs = {}, pending = {}, soft = false, tru = false, waiting = {},
              pendingCase = {}, attEq = start.attackerEq or start.t0 }
  for i = 1, #(start.affs or {}) do s.affs[start.affs[i]] = true end
  for _, name in ipairs(READY) do
    local at = start.ready and start.ready[name] or start.t0
    s.ready[name] = at
    -- start.downAtStart: a fork's channel whose model clock ran out before t0. It comes back at t0, with its line, so
    -- a race over the log and the run sees the eat's return (review LUA-N2-6).
    s.down[name] = at > start.t0 or (start.downAtStart and start.downAtStart[name] and true) or false
  end
  -- An eat clock the run knows: one spent in the run, or a fork's last eat from the log. Without one, a race has no
  -- PHASE, as kb_events.race() has none before a log's first eat.
  s.eatSpent = (start.ready and start.ready.eat) ~= nil or (start.downFrom and start.downFrom.eat) ~= nil
  local defs = start.defs or {}
  s.defs.shield, s.defs.rebounding, s.defs.sileris = defs.shield or false, defs.rebounding or false, defs.sileris or false
  s.reboundingAt = start.reboundingAt
  -- Hypochondria up at the start runs its chain from start.chainAt (the gain line, in a fork) or from t0. A step due
  -- before t0 happened before the run: the board shows it, or it was cured, so it is skipped.
  if s.affs.hypochondria and model.chain and model.chain[1] then
    local at = start.chainAt or start.t0
    local step = 1
    while model.chain[step] and at + model.chain[step].at < start.t0 do step = step + 1 end
    if model.chain[step] then s.chain = { at = at, step = step } end
  end
  s.dagazNext = start.dagazNext
  return s
end

local function sortedAffs(affs)
  local out = {}
  for aff in pairs(affs) do out[#out + 1] = aff end
  table.sort(out)
  return out
end

local function snap(s, model, t)
  local shut = {}
  for _, ch in ipairs(V.CHANNELS) do shut[ch] = V.shut(s, ch, model, t) or false end
  local ready = {}
  for _, name in ipairs(READY) do ready[name] = s.ready[name] end
  return { ready = ready, shut = shut, affs = sortedAffs(s.affs), act = s.nextAct or false,
           shield = s.defs.shield, rebounding = s.defs.rebounding, sileris = s.defs.sileris,
           dagaz = s.dagazNext or false }
end

local function emit(out, s, model, env, t, side, kind, name, args, extra)
  local ev = { v = 1, src = env.src or "sim", t = t, side = side, kind = kind, name = name, args = args or {},
               view = "true", row = (env.rowBase or 0) + #out.events + 1 }
  if extra then
    for k, v in pairs(extra) do ev[k] = v end
  end
  if env.snap then ev.snap = snap(s, model, t) end
  out.events[#out.events + 1] = ev
  return ev
end

-- byOf: what brought each affliction ("impulse", "bite", "reaction"), from A.apply; by is the default.
local function landedEvents(out, s, model, env, t, landed, by, byOf)
  for i = 1, #landed do
    emit(out, s, model, env, t, "V", "gain", landed[i], nil, { by = (byOf and byOf[landed[i]]) or by })
    if landed[i] == "hypochondria" then s.chain = { at = t, step = 1 } end
  end
end

-- ---------------------------------------------------------------------------------------------
-- One moment: everything due at t, in a fixed order
-- ---------------------------------------------------------------------------------------------

local function recoveries(out, s, model, env, t)
  for _, name in ipairs(READY) do
    if s.down[name] and t >= s.ready[name] then
      s.down[name] = false
      -- The class lockout's end carries the class cure's name, as in a log ("recover salt").
      local line = (name == "class" and model.classcure and CLASS_NAME[model.classcure.kind]) or name
      emit(out, s, model, env, s.ready[name], "V", "recover", line)
    end
  end
end

local function timed(out, s, model, env, st, t)
  if s.reboundingAt and t >= s.reboundingAt then
    s.reboundingAt = nil
    s.defs.rebounding = true
    emit(out, s, model, env, t, "V", "defence", "rebounding.up")
  end
  if s.silerisAt and t >= s.silerisAt then
    s.silerisAt = nil
    -- An apply does not harden while slickness is on (rule defence.sileris.slickness_harden: 0 of 43 that hardened had
    -- slickness on at the mark; 5 of the 6 that never hardened had it on, az 3616 and Z5 4096, 4712, 4951, 5284).
    if not s.defs.sileris and not s.affs.slickness then
      s.defs.sileris = true
      emit(out, s, model, env, t, "V", "defence", "sileris.up")
    elseif not s.defs.sileris then
      -- No log line shows a lost apply; this world line says why no coating came (review R5-fork-1b).
      emit(out, s, model, env, t, "W", "defence", "sileris.unhardened", { "slickness" })
    end
  end
  if s.dagazNext and t >= s.dagazNext then
    local aff = V.pickRandom(s, model, env, st.dagaz, model.dagaz.first)
    s.dagazNext = t + V.clock(model.dagaz.period, env, st.dagaz)
    if aff then
      s.affs[aff] = nil
      emit(out, s, model, env, t, "V", "classcure", "dagaz")
      emit(out, s, model, env, t, "V", "lose", aff, nil, { by = "dagaz" })
    end
  end
  -- Every chain step due by now, not one per moment.
  while s.chain do
    local step = model.chain[s.chain.step]
    if not s.affs.hypochondria or not step then
      s.chain = nil
    elseif t < s.chain.at + step.at then
      break
    else
      s.chain.step = s.chain.step + 1
      if not s.affs[step.aff] then
        s.affs[step.aff] = true
        emit(out, s, model, env, t, "W", "timed", "hypochondria")
        emit(out, s, model, env, t, "V", "gain", step.aff, nil, { by = "hypochondria" })
      end
    end
  end
end

-- The gap after an action of this kind: env.gaps[kind] when the run gives one (tools/theorycraft.py --gap queue), else
-- env.gap.
local function gapOf(env, kind)
  return (env.gaps and env.gaps[kind]) or env.gap
end

-- When the next action runs: at `at`, or later when it is an IMPULSE and the attacker's equilibrium is not back.
local function nextAt(s, script, at)
  local nxt = script[s.index]
  if nxt and nxt.kind == "impulse" and s.attEq > at then return s.attEq end
  return at
end

local function attack(out, s, model, env, st, t, script)
  if not s.nextAct or t < s.nextAct then return end
  local act = script[s.index]
  if not act then
    s.nextAct = nil
    return
  end
  s.index = s.index + 1
  local eatKnown = s.eatSpent
  local eatPhase = s.ready.eat - t
  local eatDown = t < s.ready.eat
  if act.kind == "wait" then
    s.nextAct = nextAt(s, script, t + act.seconds)
  elseif act.kind == "give" then
    local result, landed, coat = A.apply(s, act, model)
    local ev = emit(out, s, model, env, t, "W", "give", "give", act.affs, { result = result, landed = landed, text = act.text })
    if coat then emit(out, s, model, env, t, "V", "defence", "sileris.down") end
    landedEvents(out, s, model, env, t, landed, "give")
    s.nextAct = nextAt(s, script, t + F.gapDraw(gapOf(env, "give"), env, st))
    ev.next = s.nextAct
  else
    local result, landed, coat, info = A.apply(s, act, model)
    local name, parts = A.lines(act, result, s, coat, info)
    local extra = { action = act.kind, result = result, landed = landed, phase = eatKnown and eatPhase or nil,
                    down = eatDown, text = act.text }
    if act.kind == "impulse" then
      -- The impulse spends the attacker's equilibrium whatever the bite met (rule attack.cost.own.impulse_eq).
      if not (model.attacker and model.attacker.impulseEq) then
        error("fight.lua: an impulse needs model.attacker.impulseEq (rule attack.cost.own.impulse_eq)")
      end
      s.attEq = t + V.clock(model.attacker.impulseEq, env, st.attackerEq)
      extra.eqBack = s.attEq
      extra.suggestion = act.suggestion
    end
    -- down: the eat is down at the strike, the sign of a PHASE of 0 (kb_events.signed; review LUA-N2-10).
    local ev = emit(out, s, model, env, t, "A", "attack", name, act.venoms, extra)
    local index = #out.events
    for i = 1, #parts do
      emit(out, s, model, env, t, parts[i].side, parts[i].kind, parts[i].name, parts[i].args, { part = true })
    end
    -- act: the action's number in the script (a wait and a give count too), so a race reads "RACE 1->3".
    out.strikes[#out.strikes + 1] = { t = t, name = name, kind = act.kind, phase = eatPhase, eatDown = eatDown,
                                      eatKnown = eatKnown, index = index, act = s.index - 1 }
    landedEvents(out, s, model, env, t, landed, act.kind, info and info.by)
    s.nextAct = nextAt(s, script, t + F.gapDraw(gapOf(env, act.kind), env, st))
    ev.next = s.nextAct
  end
  -- The eat down at this action: if it is the last action that runs, the run holds until that eat comes back.
  s.hold = s.down.eat and s.ready.eat or nil
  if not script[s.index] then
    -- A last wait still holds the run open: the tail starts when it ends.
    s.lastAct = (act.kind == "wait") and (t + act.seconds) or t
    s.nextAct = nil
  end
end

local function act(out, s, model, env, st, t, ch, case)
  local target = V.target(s, ch, model, env, st)
  if not target then return false end
  local cured, item, raised = V.act(s, ch, target, t, model, env, st)
  s.down[ch] = true
  if ch == "eat" then s.eatSpent = true end
  local cc = model.classcure
  local name, kind, args = ch, "cure", {}
  if ch == "class" then
    name, kind = CLASS_NAME[cc.kind], "classcure"
    if cc.spends_bal then s.down.bal = true end
    if cc.spends_eq then s.down.eq = true end
  elseif ch == "eat" then
    args = { "eat", item or "" }
  elseif ch == "salve" or ch == "smoke" then
    args = { item or "" }
  end
  emit(out, s, model, env, t, "V", kind, name, args, { item = item, ssc = case })
  if raised then return true end
  for i = 1, #cured do emit(out, s, model, env, t, "V", "lose", cured[i], nil, { by = name }) end
  return true
end

-- An empty draw table: V.target with it asks whether a channel has a target, and draws nothing.
local NODRAW = {}

-- Does the channel have something to act on now? Its shut state does not matter here.
local function hasTarget(s, ch, model, env)
  return V.target(s, ch, model, env, NODRAW) ~= nil
end

-- Server-side curing: an open channel with something to do acts after the reaction delay. The target is picked
-- again when it acts, so an affliction that lands during the delay can take the action.
-- The delay has two cases (victim.lua V.delay), split as kb/sim/events.json splits a log's eats by its 'down' flag.
-- "return": the channel was shut at the last moment with an affliction for it (its clock was down, or an affliction
-- shut it), so the affliction waited for the channel. "gain": the affliction is new at this moment. It landed on an open
-- channel, or it landed at the moment the channel came back, as a log's return line before the strike line in one packet
-- (kb_events.phase_at: down false). A channel that an affliction shut is a "return" when that blocker goes; no log
-- measures that case (rule ssc.delay.return).
local function curing(out, s, model, env, st, t)
  for _, ch in ipairs(V.CHANNELS) do
    local due = s.pending[ch]
    if due and t >= due then
      local case = s.pendingCase[ch]
      s.pending[ch], s.pendingCase[ch] = nil, nil
      if not V.shut(s, ch, model, t) then act(out, s, model, env, st, t, ch, case) end
    end
  end
  for _, ch in ipairs(V.CHANNELS) do
    if ch ~= "class" or model.classcure then
      local shut = V.shut(s, ch, model, t)
      local has = hasTarget(s, ch, model, env)
      if has and not shut and not s.pending[ch] then
        local case = s.waiting[ch] and "return" or "gain"
        s.pending[ch] = t + V.delay(model, env, st.ssc, case)
        s.pendingCase[ch] = case
      end
      s.waiting[ch] = (has and shut) and true or false
    end
  end
  -- A victim that keeps a shield raises it again after a FLAY strips it: a delay drawn from the logs (rule
  -- defence.shield.reraise: FLAY of the shield to the next shield line), then the first moment equilibrium and
  -- paralysis allow. It goes after the channels, and it waits while a class cure that needs equilibrium is pending,
  -- so the class cure takes equilibrium first (forward.lua:193-194: FITNESS goes before a shield; review ENG-1).
  -- The re-raise needs a FLAY: one in the run (the shield was up, then stripped) or the log's (start.shieldFrom). A
  -- fork whose shield is down with no FLAY on its way does not raise it (review R3-fork-1: X 1012 raised a shield at
  -- +5.83 that the log did not show for 43.9 s).
  local cc = model.classcure
  local classWaits = cc and cc.needs_eq and s.pending.class
  if s.defs.shield then s.shieldArmed = true end
  if env.defences.shield and not s.defs.shield and s.shieldArmed then
    if not s.pending.shield then
      s.pending.shield = t + V.clock(model.shield.reraise, env, st.shield)
    elseif t >= s.pending.shield and not classWaits and V.shieldOpen(s, model, env, t) then
      s.pending.shield = nil
      V.raiseShield(s, model, t)
      s.down.eq = true
      emit(out, s, model, env, t, "V", "defence", "shield.up")
    end
  end
end

local function labels(out, s, model, env, t)
  local classDown = model.classcure ~= nil and t < s.ready.class
  local soft, tru = V.labels(s.affs, model.labelBlocker, classDown)
  if soft ~= s.soft then
    s.soft = soft
    emit(out, s, model, env, t, "W", "label", "soft", { soft and "on" or "off" })
    if soft and not out.softAt then out.softAt = t end
  end
  if tru ~= s.tru then
    s.tru = tru
    emit(out, s, model, env, t, "W", "label", "true", { tru and "on" or "off" })
    if tru and not out.trueAt then out.trueAt = t end
  end
end

local function nextTime(s, t, model)
  local best = math.huge
  local function consider(at)
    if at and at > t and at < best then best = at end
  end
  consider(s.nextAct)
  for _, name in ipairs(READY) do consider(s.ready[name]) end
  for _, ch in ipairs(V.CHANNELS) do consider(s.pending[ch]) end
  consider(s.pending.shield)
  consider(s.reboundingAt)
  consider(s.silerisAt)
  consider(s.dagazNext)
  if s.chain and model.chain[s.chain.step] then consider(s.chain.at + model.chain[s.chain.step].at) end
  return best
end

-- ---------------------------------------------------------------------------------------------
-- One run
-- ---------------------------------------------------------------------------------------------

--- One attacker gap: the median, or a draw around it. No gap goes under env.gapFloor, or under BUNDLED when no floor is
--- given, and never under A.MIN_WAIT: a gap at or below 0 would set the next action at or before now, and no later
--- moment would run it (review LUA-N2-12). The floor holds for the median too (review R3-engine-5: --gap 0 --median).
function F.gapDraw(gap, env, st)
  local floor = math.max(env.gapFloor or F.BUNDLED, A.MIN_WAIT)
  return math.max(floor, V.clock({ median = gap, sd = env.gapSd or 0, min = floor }, env, st.attacker))
end

--- Run a script from a start. start = { t0, affs, ready, downAtStart, downFrom, defs, firstAt, firstFrom, dagazNext,
--- chainAt, reboundingAt, reboundingFrom, shieldFrom, silerisFrom }. A fork's times from the log:
---   downFrom       { channel = when the log spent it }: a channel still down at t0 comes back one clock after that,
---                  drawn from the part of the clock above the time already run (V.clockAfter; "class" is the class
---                  cure's lockout). One whose longest draw has run out comes back at t0, with its line.
---   firstFrom      the log's last attack; the first action comes one gap after it, drawn as every other gap.
---   shieldFrom     the log's FLAY of the shield; the victim raises it again one re-raise delay later (review LUA-N2-5).
---                  A shield down at the start with no shieldFrom stays down: only a FLAY starts a re-raise.
---   reboundingFrom the log's smoke for rebounding; the aura comes up one clock.rebounding later.
---   silerisFrom    the log's apply of the coating; it hardens one defence.sileris.harden later (review R3-fork-8).
---                  The engine never applies the coating itself.
--- None of them is ever before t0. out.startReady holds the clocks as the run starts, after those draws.
---   attackerEq     when the attacker's equilibrium is back (an IMPULSE needs it); t0 when not given.
--- env = { median, clockDraw, gap, gapSd, gapFloor, gaps, defences = { shield, rebounding }, tree, treePick, tail,
---         horizon, snap, src, rowBase }. gaps: the gap after each kind of action (dstab, bite, impulse, flay, give),
---         where it is not env.gap. Returns { events, strikes, races, softAt, trueAt, stopAt, firstAt, notRun,
---         hold, affs }. notRun counts the script's actions the horizon cut off; hold is the time the run then holds to
---         (the eat down at the last action that ran), or nil.
--- With no start.dagazNext, a Runewarden's first Dagaz tick is drawn uniformly over one period (rule
--- class.dagaz.phase), or put at half a period with env.median.
function F.run(start, script, model, env, seed)
  local st = streams(seed or 1)
  local s = newState(start, model)
  if model.dagaz and not s.dagazNext then
    local period = model.dagaz.period.median
    s.dagazNext = start.t0 + ((env.median and 0.5) or st.dagaz()) * period
  end
  for ch, from in pairs(start.downFrom or {}) do
    local c = (ch == "class") and model.classcure and model.classcure.lockout or model.clocks[ch]
    if c then
      s.ready[ch] = math.max(start.t0, from + V.clockAfter(c, env, st[ch], start.t0 - from))
      s.down[ch] = true
    end
  end
  -- A shield up at the start is armed: a FLAY at t0 strips it before the first curing pass sees it.
  s.shieldArmed = s.defs.shield and true or nil
  if start.shieldFrom and env.defences.shield and not s.defs.shield then
    s.shieldArmed = true
    s.pending.shield = math.max(start.t0, start.shieldFrom + V.clockAfter(model.shield.reraise, env, st.shield,
                                                                          start.t0 - start.shieldFrom))
  end
  if start.reboundingFrom and not s.defs.rebounding then
    s.reboundingAt = math.max(start.t0, start.reboundingFrom + V.clockAfter(model.clocks.rebounding, env, st.smoke,
                                                                            start.t0 - start.reboundingFrom))
  end
  if start.silerisFrom and model.sileris and not s.defs.sileris then
    s.silerisAt = math.max(start.t0, start.silerisFrom + V.clockAfter(model.sileris.harden, env, st.sileris,
                                                                      start.t0 - start.silerisFrom))
  end
  -- A channel down or shut at the start, with an affliction for it, has that affliction waiting (curing: "return").
  for _, ch in ipairs(V.CHANNELS) do
    if ch ~= "class" or model.classcure then
      local shut = s.down[ch] or V.shut(s, ch, model, start.t0) ~= nil
      s.waiting[ch] = (shut and hasTarget(s, ch, model, env)) and true or false
    end
  end
  local out = { events = {}, strikes = {}, startReady = {} }
  for _, name in ipairs(READY) do out.startReady[name] = s.ready[name] end
  local t = start.t0
  s.index = 1
  if start.firstFrom then
    s.nextAct = nextAt(s, script, math.max(start.t0, start.firstFrom + F.gapDraw(env.gap, env, st)))
  else
    s.nextAct = nextAt(s, script, start.firstAt or start.t0)
  end
  out.firstAt = s.nextAct
  local horizon = start.t0 + (env.horizon or 60)
  local tail = env.tail or 2.5
  local steps = 0
  while true do
    steps = steps + 1
    if steps > 100000 then error("fight.lua: no progress at t=" .. tostring(t)) end
    recoveries(out, s, model, env, t)
    timed(out, s, model, env, st, t)
    attack(out, s, model, env, st, t, script)
    curing(out, s, model, env, st, t)
    labels(out, s, model, env, t)
    -- After the last action the run holds for the tail, and until the eat down at that action comes back: its recovery
    -- line must be in the stream, or kb_events.race() cannot pair the last race that F.races pairs (review ENG-3, a
    -- short --tail). The hold passes the horizon (review R3-engine-3: an eat back after the horizon left the race
    -- unpaired in the fork and paired in F.races). A later eat does not hold it.
    if s.nextAct and s.nextAct > horizon and script[s.index] then
      -- The horizon cuts the script: the actions left never run, but the run still holds until the eat down at the last
      -- action that ran comes back, so a race paired before the horizon keeps its recovery line.
      out.notRun = #script - s.index + 1
      -- hold: when the eat down at the last action that ran comes back, or nil when none was down (review R4-docs-7).
      out.hold = s.hold
      s.nextAct = nil
      s.lastAct = horizon
    end
    local stopAt = horizon
    if not s.nextAct then
      stopAt = math.max(math.min(horizon, (s.lastAct or start.t0) + tail), s.hold or -math.huge)
    end
    local nextT = nextTime(s, t, model)
    if nextT > stopAt then
      out.stopAt = stopAt
      break
    end
    t = nextT
  end
  out.races = F.races(out.strikes)
  out.affs = sortedAffs(s.affs)
  return out
end

local function family(name)
  if string.sub(name, 1, 4) == "flay" then return "flay" end
  return name
end

--- The race of each DSTAB against the eat, as tools/kb_events.py race() reads it from a log. A strike of the same
--- family as the one before it, within BUNDLED, is the same attack (kb_events.attacks). A race starts at a DSTAB that
--- reached the victim (not one a shield blocked) and pairs with the next attack at least BUNDLED later: the strike
--- first when the eat is still down at that attack, the herb first when it is back. A pair is unpaired (no winner)
--- when the next attack is DISENGAGED or more away, or when the run knows no eat clock at it. from and to are the
--- actions' numbers in the script; down is whether the eat was down at the strike (the sign of a PHASE of 0).
function F.races(strikes)
  local hits = {}
  for i = 1, #strikes do
    local a = strikes[i]
    local last = hits[#hits]
    if not (last and family(last.s.name) == family(a.name) and a.t - last.s.t < F.BUNDLED) then
      hits[#hits + 1] = { n = i, s = a }
    end
  end
  local out = {}
  for k = 1, #hits do
    local a = hits[k].s
    if a.name == "dstab" then
      local j = k + 1
      while hits[j] and hits[j].s.t - a.t < F.BUNDLED do j = j + 1 end
      local b = hits[j] and hits[j].s
      local race = { from = a.act or hits[k].n, t = a.t, phase = a.eatKnown and a.phase or nil, down = a.eatDown }
      if b then
        race.to, race.gap = b.act or hits[j].n, b.t - a.t
        if b.t - a.t < F.DISENGAGED and b.eatKnown then
          race.phaseNext = b.phase
          race.winner = b.eatDown and "strike" or "herb"
          race.by = math.abs(b.phase)
        end
      end
      out[#out + 1] = race
    end
  end
  return out
end

return F
