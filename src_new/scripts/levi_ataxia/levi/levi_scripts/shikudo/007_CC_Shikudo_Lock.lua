--[[mudlet
type: script
name: CC_Shikudo Lock
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

--[[
  OFFENSIVE SYSTEM - Shikudo lock (alias sr -> shikudoLock.dispatch())

  REQUIRED READING before modifying:
  - .claude/classes/lock_types.md (lock definitions)
  - .claude/classes/monk.md and kb/combat/shikudo.md (Shikudo mechanics, Mystor's fights)
  - monk/004_Kai_And_Kata.lua (kai costs, the kata caps, the ASSESS reading this file uses)

  Lock progression (the phase this file reports):
    Softlock:   asthma + anorexia + slickness
    Venomlock:  softlock + paralysis
    Hardlock:   venomlock + impatience (Telepathy)
    Truelock:   hardlock + weariness (blocks Fitness) -> KILL

  The route is Mystor's, counted over his six fights (v4.7.420; kb/raw/logs/2026-10-11_mystor_*):
  Rain (weariness, clumsiness and the arm prep) -> Oak (asthma AND slickness in one combo) -> Willow
  (anorexia from hiraku), with MIND IMPATIENCE before hiraku lands so FOCUS cannot cure the anorexia.
  He never entered Tykonos. Both of his lock wins ended in KAI CHOKE, one per equilibrium, after MIND
  CONFUSE and MIND DISRUPT (FceAmb0o:6309-6443, vNTjvghY:8840-9020).

  Each round is ONE `queue addclear free` entry, and a MIND round goes out INSTEAD of a combo:
  Mystor chained a MIND affliction onto a combo in 0 of 274 rounds, and HELP 4.6 says an
  equilibrium ability usually needs balance as well (kb/mechanics/balance-and-queueing.md:16-17).
  What the next round is planned from (the last round, the MIND run, the prelude count, the choke
  latch, the alternated sides) moves when the game's run line shows a round RAN
  (shikudoLock.onQueueRan), never on the key press: each press replaces the round still queued.
]]--

shikudoLock = shikudoLock or {}
-- The round history below moves when the GAME RUNS a round, not when `sr` queues one: every press
-- sends `queue addclear free`, which replaces a round still waiting on equilibrium, balance,
-- paralysis or a stun (HELP 4.6.1), so counting presses made the round that ran depend on how often
-- the key was pressed (v4.7.420 review; CLAUDE.md, "Counter Incrementing (Button Spam Issue)").
shikudoLock.state = {
  phase = "SOFTLOCK",     -- SOFTLOCK, VENOMLOCK, HARDLOCK, TRUELOCK, KILL
  lastRound = nil,        -- the last round the game ran: "combo", "shatter", "mind" or "choke"
  mindRun = 0,            -- MIND rounds run in a row; a combo, a shatter or a choke resets it
  prelude = 0,            -- KILL prelude rounds (confuse, disrupt) run this lock
  choking = false,        -- a KAI CHOKE ran this lock: no more prelude, choke every round
  alt = {},               -- pickSide's alternation, per kind ("arm", "leg"), when lb has no reading
  roundAlt = {},          -- the sides pickSide alternated to for the round being built
  pending = nil,          -- the round queued and not yet run: committed by shikudoLock.onQueueRan
  runLine = false,        -- the game's run line has matched one of our rounds; until then a round
                          -- counts when it is queued, so the caps still hold if it never prints
}

--------------------------------------------------------------------------------
-- CONFIG VALUES (can be adjusted)
--------------------------------------------------------------------------------

shikudoLock.config = {
  rainKata = 10,          -- Rain is left for Oak at this chain once weariness and clumsiness are on:
                          -- "me shooting for 10 kata in rain with 2x arm prep" (players file:22)
  assessMaxAge = 5,       -- seconds an ASSESS stays fresh enough for Crescent
  assessEachRound = true, -- end every round with ASSESS, as both players' aliases do (vNTjvghY:418)
  maxMindRounds = 2,      -- MIND rounds in a row before a combo must go out
  maxPrelude = 3,         -- KILL prelude rounds at most before the first KAI CHOKE
  chokePrelude = true,    -- confuse, then disrupt, before the chokes (FceAmb0o:6309, :6361)
  chainTelepathy = false, -- MIND after the combo in one round: never seen, see the header
  rainTelepathy = true,   -- MIND filler in Rain (58 of Mystor's 79 MIND affliction rounds were in Rain)
  lapseGuard = 12,        -- no MIND round once the chain is this many seconds past its last strike:
                          -- MIND adds no kata, and the chain lapses at about 17-20 s (vNTjvghY:5967).
                          -- Not for a round that transitions: that resets the chain anyway.
  -- MIND PARALYSE as Rain FILLER is pressure, and an Apostate ate magnesium right after it
  -- (LcJC-rJ5:3124-3141, :3273-3286). Class names are lower-case ataxiaNDB_getClass values.
  classSkip = { apostate = { paralyse = true } },
}

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------------------

-- Target afflictions through haveAff (the V3 tracker), else the tAffs mirror while V3 loads: the
-- public read API, as 006 reads them.
local function has(aff)
  if haveAff then return haveAff(aff) and true or false end
  return tAffs ~= nil and tAffs[aff] and true or false
end

-- Our form as charstats names it ("Rain"); Oak when unknown, as this offense always assumed.
local function formNow()
  return ataxia_shikudoForm(ataxia.vitals and ataxia.vitals.form) or "Oak"
end

-- Our kai (0-100) through monk/004, nil when no charstats this session has carried it.
function shikudoLock.getKai()
  return ataxia_kai()
end

-- KAI CHOKE is the lock's kill: 10 kai and 50 mana (Kaido.wiki:286), measured as 10 a choke in
-- Mystor's kill, K:95% -> 85% -> 75% (FceAmb0o:6382-6427). Unknown kai is not affordable.
function shikudoLock.canKaiChoke()
  return (ataxia_kaiAfford("choke", 0, target))
end

-- The kai for the [LOCK] line and the status box: "?" until charstats has carried it.
function shikudoLock.kaiLabel()
  local kai = shikudoLock.getKai()
  if shikudoLock.canKaiChoke() then
    return "<green>" .. kai .. " KAI CHOKE READY"
  end
  return "<yellow>" .. (kai and tostring(kai) or "?")
end

function shikudoLock.getPhaseLabel()
  -- Colored phase labels for consistent output
  local phase = shikudoLock.state.phase
  local labels = {
    SOFTLOCK = "<yellow>SOFTLOCK",
    VENOMLOCK = "<orange>VENOMLOCK",
    HARDLOCK = "<magenta>HARDLOCK",
    TRUELOCK = "<red>TRUELOCK",
    KILL = "<green>KILL",
  }
  return labels[phase] or "<grey>Unknown"
end

--------------------------------------------------------------------------------
-- LOCK CONDITION CHECKS
--------------------------------------------------------------------------------

function shikudoLock.checkSoftlock()
  return has("asthma") and has("anorexia") and has("slickness")
end

function shikudoLock.checkVenomlock()
  return shikudoLock.checkSoftlock() and has("paralysis")
end

function shikudoLock.checkHardlock()
  return shikudoLock.checkVenomlock() and has("impatience")
end

function shikudoLock.checkTruelock()
  return shikudoLock.checkHardlock() and has("weariness")
end

function shikudoLock.updatePhase()
  if shikudoLock.checkTruelock() then
    shikudoLock.state.phase = "KILL"
  elseif shikudoLock.checkHardlock() then
    shikudoLock.state.phase = "TRUELOCK"
  elseif shikudoLock.checkVenomlock() then
    shikudoLock.state.phase = "HARDLOCK"
  elseif shikudoLock.checkSoftlock() then
    shikudoLock.state.phase = "VENOMLOCK"
  else
    shikudoLock.state.phase = "SOFTLOCK"
  end
end

--------------------------------------------------------------------------------
-- FORM HELPERS
--------------------------------------------------------------------------------

function shikudoLock.inForm(...)
  local currentForm = ataxia.vitals.form or "Oak"
  for _, form in ipairs({...}) do
    if currentForm == form then
      return true
    end
  end
  return false
end

function shikudoLock.hasAbility(ability)
  local form = ataxia.vitals.form or "Oak"
  local formAbilities = {
    Tykonos = {"thrust", "sweep", "risingkick"},
    Willow = {"dart", "hiru", "hiraku", "flashheel"},
    Rain = {"kuro", "hiru", "ruku", "frontkick"},
    Oak = {"kuro", "nervestrike", "livestrike", "ruku", "risingkick"},
    Gaital = {"needle", "sweep", "kuro", "ruku", "jinzuku", "spinkick", "flashheel", "dawnkick"},
    Maelstrom = {"ruku", "livestrike", "jinzuku", "sweep", "risingkick", "crescent"}
  }

  local abilities = formAbilities[form] or {}
  for _, a in ipairs(abilities) do
    if a == ability then
      return true
    end
  end
  return false
end

--------------------------------------------------------------------------------
-- LIMB HELPERS
--------------------------------------------------------------------------------

-- lb[target].hits, the trigger-fed limb damage (006's shikudo.getLimbDamage reads the same
-- table); nil when there is no reading.
local function limbHit(name)
  if not target or not lb or not lb[target] or not lb[target].hits then return nil end
  return tonumber(lb[target].hits[name])
end

-- The side ("left" or "right") of the arms or legs to strike: the one with less damage, so both
-- get prepped ("2x arm prep", players file:22). With no reading, or a tie, it alternates, as
-- Mystor's flashheels do (vNTjvghY:8024 right, :8053 left, :8081 right) -- per round the game
-- RUNS: the side goes in state.roundAlt and becomes state.alt only when this round runs, so a
-- second press before then picks the same side.
function shikudoLock.pickSide(kind)
  local l, r = limbHit("left " .. kind), limbHit("right " .. kind)
  if l and r and l ~= r then
    return l < r and "left" or "right"
  end
  local st = shikudoLock.state
  local side = st.alt[kind] == "left" and "right" or "left"
  st.roundAlt[kind] = side
  return side
end

-- The leg to FLASHHEEL. A flashheel BREAKS the leg it lands on ("break said limb with a single
-- blow", Shikudo.wiki:127; trigger 577 records broken<side>leg), so kick the one not broken yet:
-- a second break is a second mending, on the salve balance epidermal needs to cure anorexia. With
-- neither or both broken: `leg`, this combo's pick, else pickSide.
function shikudoLock.flashLeg(leg)
  local left, right = has("brokenleftleg"), has("brokenrightleg")
  if left and not right then return "right" end
  if right and not left then return "left" end
  return leg or shikudoLock.pickSide("leg")
end

-- CRESCENT "may only be performed against a foe who lies prone", kills one at half health or
-- less, and above half is dodged with "greatly increased" recovery and drops us into Tykonos
-- (Shikudo.wiki:358). So: prone, and a fresh ASSESS of this target at half or less, from the raw
-- numbers (monk/004: the floored percentage reads 3540/7000 as 50). KILL is no gate: the truelock
-- comes at high health (87.30% at FceAmb0o:6368).
function shikudoLock.crescentReady()
  return has("prone") and ataxia_assessAtMostHalf(shikudoLock.config.assessMaxAge)
end

--------------------------------------------------------------------------------
-- FORM TRANSITION LOGIC
--------------------------------------------------------------------------------

-- Mystor's route, counted over his six logs (kb/raw/logs/2026-10-11_mystor_*), 56 transitions:
-- Rain->Oak 17, Oak->Gaital 13, Gaital->Rain 11, Oak->Willow 6, Willow->Rain 5, Gaital->Maelstrom
-- 2, Maelstrom->Oak 2, and never Tykonos. At all six Oak->Willow moves his client's model of the
-- target had asthma AND slickness on and anorexia OFF (Willow entries vNTjvghY:7980, :8448;
-- FceAmb0o:4611, :6234; LcJC-rJ5:1065, :2245), so anorexia comes LAST. The v4.7.417 route went for
-- anorexia first and, when it was cured before Rain reached 5, took Rain -> Tykonos -> Willow and
-- never saw Oak (livestrike, nervestrike) again.
-- The transition goes BEFORE this round's combo, so it is judged on the chain now (strikes 0):
-- below 5 the game refuses it (Shikudo.wiki:116), and the caps are monk/004's policy (`skata`).
function shikudoLock.shouldTransition()
  local form = formNow()
  local kata = tonumber(ataxia.vitals.kata) or 0
  if kata < ataxia_KATA.min then
    return nil
  end

  local oakHalf = has("asthma") and has("slickness")
  local capped = ataxia_kataShouldLeave(form, kata, 0)

  if form == "Rain" then
    -- Out once the arm prep is in ("10 kata in rain with 2x arm prep", players file:22), at the
    -- cap, or at once mid-lock: with anorexia on, Oak's asthma and slickness are what is missing.
    if has("anorexia") or capped
      or (kata >= shikudoLock.config.rainKata and has("weariness") and has("clumsiness")) then
      return "Oak"
    end
  elseif form == "Oak" then
    -- Willow is for anorexia: DART, SWEEP, HIRU, FLASHHEEL, HIRAKU (Shikudo.wiki:89), no kuro and
    -- no nervestrike. With anorexia already on it would only leave behind the weariness and the
    -- paralysis the lock still needs, so Oak holds to its cap and goes round by Gaital and Rain
    -- (v4.7.420 review; Mystor never entered Willow with anorexia on).
    if oakHalf and not has("anorexia") then return "Willow" end
    if capped then return "Gaital" end
  elseif form == "Willow" then
    -- Back round to Oak once the Oak half has dropped, or at the cap.
    if not oakHalf or capped then return "Rain" end
  elseif form == "Gaital" then
    return "Rain"
  elseif form == "Maelstrom" then
    return "Oak"
  elseif form == "Tykonos" then
    return "Willow" -- its only exit
  end
  return nil
end

--------------------------------------------------------------------------------
-- KICK SELECTION
--------------------------------------------------------------------------------

-- The combo's kick in `form` (default: ours). `arm` and `leg` are this combo's sides: buildCombo
-- picks each ONCE, so the frontkick and the ruku land on the same arm, as Mystor's do
-- (vNTjvghY:932-938).
function shikudoLock.selectKick(form, arm, leg)
  form = form or formNow()

  if form == "Willow" then
    -- FLASHHEEL, Willow's only kick (Shikudo.wiki:89). It BREAKS the leg: the one not yet broken.
    return "flashheel " .. shikudoLock.flashLeg(leg)

  elseif form == "Gaital" then
    -- SPINKICK on a prone target (head damage); otherwise FLASHHEEL, which BREAKS the leg.
    if has("prone") then
      return "spinkick"
    end
    return "flashheel " .. shikudoLock.flashLeg(leg)

  elseif form == "Rain" then
    -- FRONTKICK to the arm: damage, and it throws the target prone (vNTjvghY:933).
    return "frontkick " .. (arm or shikudoLock.pickSide("arm"))

  elseif form == "Maelstrom" and shikudoLock.crescentReady() then
    return "crescent"
  end

  -- Oak, Tykonos, and Maelstrom otherwise: RISINGKICK TORSO, Mystor's kick in his lock windows
  -- (vNTjvghY:7918, FceAmb0o:6124). Torso damage raises KAI CHOKE's damage (Kaido.wiki:289).
  return "risingkick torso"
end

--------------------------------------------------------------------------------
-- STAFF STRIKE SELECTION - AFFLICTION PRIORITY
--------------------------------------------------------------------------------

-- Per form: `want` lists { affliction, strike } in the order the lock needs them, each strike
-- taken only while its affliction is missing; `fill` is what the form strikes otherwise. %arm and
-- %leg are this combo's sides. Mystor's combos (players file:23; kb/combat/shikudo.md, "Mystor's
-- six arena fights"):
--   Rain       frontkick <arm> + kuro <leg> + ruku <arm>: weariness, clumsiness, the arm prep
--   Oak        risingkick torso + livestrike + ruku torso: asthma AND slickness in one combo
--              (vNTjvghY:8281, FceAmb0o:6124)
--   Willow     flashheel + hiraku + hiru (vNTjvghY:7976): hiraku gives the anorexia
--   Maelstrom  risingkick + jinzuku + ruku
-- Rain gives no slickness of its own: Oak puts it on together with asthma.
shikudoLock.STAFF = {
  Rain = {
    want = { { "weariness", "kuro %leg" }, { "clumsiness", "ruku %arm" } },
    fill = { "kuro %leg", "ruku %arm" },
  },
  Oak = {
    want = { { "asthma", "livestrike" }, { "slickness", "ruku torso" }, { "paralysis", "nervestrike" },
      { "weariness", "kuro %leg" }, { "clumsiness", "ruku %arm" } },
    fill = { "livestrike", "ruku torso" },
  },
  Willow = { want = {}, fill = { "hiraku", "hiru" } },
  Maelstrom = {
    want = { { "asthma", "livestrike" }, { "slickness", "ruku torso" }, { "addiction", "jinzuku" } },
    fill = { "jinzuku", "ruku torso" },
  },
  Gaital = {
    want = { { "slickness", "ruku torso" }, { "weariness", "kuro %leg" }, { "addiction", "jinzuku" },
      { "clumsiness", "ruku %arm" } },
    fill = { "ruku torso", "kuro %leg" },
  },
  Tykonos = { want = {}, fill = { "thrust left leg", "thrust right leg" } },
}

-- The combo's two staff strikes in `form`: the wanted ones first, then the form's fill, never the
-- same strike twice (v4.7.417 sent "hiraku hiraku" in Willow, and "ruku torso ruku torso" or
-- "jinzuku jinzuku" in Maelstrom).
function shikudoLock.pickStaff(form, arm, leg)
  local spec = shikudoLock.STAFF[form] or shikudoLock.STAFF.Oak
  arm = arm or shikudoLock.pickSide("arm")
  leg = leg or shikudoLock.pickSide("leg")
  local picks, seen = {}, {}
  local function take(strike)
    strike = strike:gsub("%%arm", arm):gsub("%%leg", leg)
    if #picks < 2 and not seen[strike] then
      picks[#picks + 1] = strike
      seen[strike] = true
    end
  end
  for _, w in ipairs(spec.want) do
    if not has(w[1]) then take(w[2]) end
  end
  for _, strike in ipairs(spec.fill) do take(strike) end
  return picks[1], picks[2]
end

--------------------------------------------------------------------------------
-- TELEPATHY INTEGRATION
--------------------------------------------------------------------------------

-- Whether config.classSkip forbids MIND `ability` against the target's class (ataxiaNDB_getClass,
-- the reader deffing/006 uses; "Unknown" for a name the database lacks).
local function classSkips(ability)
  local cls = ataxiaNDB_getClass and target and ataxiaNDB_getClass(target)
  local skip = type(cls) == "string" and shikudoLock.config.classSkip[cls:lower()]
  return skip and skip[ability] and true or false
end

-- The MIND command for this round in `form` (default: ours; dispatch passes the form the round
-- transitions into), and whether it is CRITICAL. No equilibrium gate, as for the KILL prelude: the
-- round waits for equilibrium AND balance on the `free` queue (HELP 4.6.1), so equilibrium at the
-- press says nothing about what will run, and a gate only swapped a critical MIND command for a
-- combo that ran at the same moment, landing hiraku before impatience (v4.7.420 review).
--  * MIND commands, never the bare words sent before v4.7.417, and no lock first: the affliction
--    MIND abilities need only the target in the room; a lock is for a target outside it and for a
--    few skills such as Sapience (the user and Mystor, 2026-10-11; players file:16-18).
--  * CRITICAL, as soon as the lock is forming: IMPATIENCE, so FOCUS cannot cure the anorexia hiraku
--    is about to give. Mystor sends it before hiraku (FceAmb0o:5937 in Maelstrom, vNTjvghY:8444 on
--    his way into Willow).
--  * CRITICAL, with the softlock and impatience on: PARALYSE, the venomlock piece. With anorexia on
--    it cannot be eaten off, and paralysis blocks the tree.
--  * Rain filler (config.rainTelepathy): impatience, paralyse, disrupt. 58 of Mystor's 79 MIND
--    affliction rounds were in Rain, where equilibrium is quickest (0.72 of the wiki's time against
--    0.85 elsewhere, kb/combat/shikudo.md).
-- MIND BATTER is gone: Mystor sent it once, just before a MIND SCYTHE, never in a lock.
function shikudoLock.selectTelepathy(form)
  form = form or formNow()

  if not has("impatience") and (has("asthma") or has("slickness") or has("anorexia")) then
    return "mind impatience " .. target, true
  end
  if shikudoLock.checkSoftlock() and has("impatience") and not has("paralysis") then
    return "mind paralyse " .. target, true
  end

  if shikudoLock.config.rainTelepathy and form == "Rain" then
    if not has("impatience") then
      return "mind impatience " .. target, false
    end
    if not has("paralysis") and not classSkips("paralyse") then
      return "mind paralyse " .. target, false
    end
    if not has("disrupted") then
      return "mind disrupt " .. target, false
    end
  end
  return nil
end

-- The KILL prelude, before the first KAI CHOKE: confuse, then disrupt (FceAmb0o:6309, :6361;
-- vNTjvghY:8916). A disrupted target has no equilibrium, and only CONCENTRATE brings it back, which
-- confusion makes fail. No equilibrium gate: the round waits for it on the `free` queue, and what
-- comes next does not depend on it -- a gate would turn any press made while it is down into the
-- choke and skip the prelude.
function shikudoLock.selectPrelude()
  if not has("confusion") then
    return "mind confuse " .. target
  end
  if not has("disrupted") then
    return "mind disrupt " .. target
  end
  return nil
end

--------------------------------------------------------------------------------
-- COMBO BUILDER
--------------------------------------------------------------------------------

-- The combo for `form` (default: ours), with $tar for the target. dispatch passes the form the
-- round transitions INTO, since the transition goes first. The arm and the leg are picked ONCE, so
-- the kick and the staff strikes agree on them (Rain: frontkick and ruku on one arm).
function shikudoLock.buildCombo(form)
  form = form or formNow()
  local arm, leg = shikudoLock.pickSide("arm"), shikudoLock.pickSide("leg")
  local kick = shikudoLock.selectKick(form, arm, leg)
  local staff1, staff2 = shikudoLock.pickStaff(form, arm, leg)

  -- Normal combo: kick + staff1 + staff2
  local combo = "combo $tar"
  if kick then combo = combo .. " " .. kick end
  if staff1 then combo = combo .. " " .. staff1 end
  if staff2 then combo = combo .. " " .. staff2 end

  return combo
end

--------------------------------------------------------------------------------
-- MAIN DISPATCH FUNCTION
--------------------------------------------------------------------------------

-- Rounds that spent balance on a combo (a SHATTER rides inside one).
local COMBO_ROUNDS = { combo = true, shatter = true }

-- A round as the run line prints it may differ in case, and the server's wrap moves spaces, so
-- rounds are compared lower-cased with the whitespace dropped.
local function runKey(s)
  return (tostring(s or ""):lower():gsub("%s+", ""))
end

-- What a round that RAN does to the history the next round is planned from.
local function commitRound(p)
  local st = shikudoLock.state
  st.mindRun = p.kind == "mind" and st.mindRun + 1 or 0
  st.lastRound = p.kind
  if p.prelude then st.prelude = st.prelude + 1 end
  if p.kind == "choke" then st.choking = true end
  for kind, side in pairs(p.alt) do st.alt[kind] = side end
end

-- An action echo ("[LOCK] Telepathy: ...", "KAI CHOKE", ...) that is not the same as the last one,
-- or any with config.verbose: a held key re-sends the same round many times a second.
local function lockSay(s)
  local st = shikudoLock.state
  if shikudoLock.config.verbose or s ~= st.lastSay then
    cecho(s)
    st.lastSay = s
  end
end

-- Send one round as ONE `queue addclear free` entry (free waits for equilibrium AND balance,
-- HELP 4.6.1). It is PENDING until the game's run line shows it ran (shikudoLock.onQueueRan); a
-- later press replaces it, on the server and here. With config.assessEachRound it ends with
-- ASSESS, as both players' aliases do (vNTjvghY:418; attacker log :949): that keeps Crescent's
-- reading fresh. `prelude` marks a KILL prelude round.
local function sendRound(kind, line, prelude)
  local st = shikudoLock.state
  -- Only with the Health Inspector trait (shikudo.assessSuffix, 006).
  line = line .. shikudo.assessSuffix(shikudoLock.config.assessEachRound, ataxia.settings.separator)
  local p = { kind = kind, prelude = prelude, alt = st.roundAlt, key = runKey(line) }
  if not st.runLine then
    -- No run line has matched a round yet (queue alerts off, or a wording we do not read): count
    -- the round now, at the press, so the MIND cap and the prelude limit still hold.
    commitRound(p)
    p.committed = true
  end
  st.pending = p
  send("queue addclear free " .. line)
end

-- The game ran a queued command. `ran` is what follows "command: " on the run line -- only its
-- FIRST row when the server wraps it, as it does every combo: 39 columns of prefix, then about 95
-- of round with combatQueue()'s "g body;g gold;stand;", against this user's 119-124 (CLAUDE.md,
-- v4.7.351). So the pending round is ours when it STARTS with `ran`. A press that crosses a run
-- line in flight can lose one round's count; the caps bound what that costs.
function shikudoLock.onQueueRan(ran)
  local st = shikudoLock.state
  local p = st.pending
  if not p then return false end
  local key = runKey(ran)
  if key == "" or p.key:sub(1, #key) ~= key then return false end
  st.pending = nil
  st.runLine = true
  if not p.committed then commitRound(p) end
  return true
end

-- The run line, read with the pattern clean-up/001_Queue_Scanning.lua:34 uses (queue_Scan raises
-- no event to listen for). The trigger lives for the session; its id is kept on ataxiaTemp, never
-- saved (a saved id names a stranger's trigger after a restart), and a reload kills the old one
-- first, as monk/004 does for its send watcher.
shikudoLock.RAN_PATTERN = [[^\[System\]\: Running queued \w+ command: (.+)]]
ataxiaTemp = ataxiaTemp or {}
if ataxiaTemp.shikLockRunTrigger and killTrigger then
  pcall(killTrigger, ataxiaTemp.shikLockRunTrigger)
end
ataxiaTemp.shikLockRunTrigger = nil
if tempRegexTrigger then
  ataxiaTemp.shikLockRunTrigger = tempRegexTrigger(shikudoLock.RAN_PATTERN, function()
    shikudoLock.onQueueRan(matches[2])
  end)
end

-- The round planner. In order:
--   SHIELD  shatter it first: a round sent into a fresh shield rebounds whole and costs
--           equilibrium (FceAmb0o:2415; seen so far only for combos).
--   KILL    truelocked and KAI CHOKE affordable: up to config.maxPrelude MIND rounds (confuse,
--           then disrupt), then KAI CHOKE alone every round -- no combo, no transition -- until the
--           lock breaks. Mystor's two lock wins: confuse, disrupt, three chokes from 87% health
--           (FceAmb0o:6309-6443); impatience, paralyse, disrupt, two chokes (vNTjvghY:8840-9020).
--   MIND    a MIND command INSTEAD of the combo when it is critical, or the last round was a
--           combo; at most config.maxMindRounds in a row, and never once the chain is near its lapse
--           (MIND adds no kata) -- unless the round transitions: "Transitioning will reset your kata
--           chain" (Shikudo.wiki:116), so a combo would save nothing, and if the chain lapsed first
--           the refused transition would leave the new form's strikes to go out in the old one. It
--           may carry the transition (vNTjvghY:8444).
--   COMBO   otherwise, with the transition FIRST: "transition to <form> form", the wording the logs
--           show 56 times; "transition to the" appears in none, and the v4.7.417 lock appended it
--           AFTER the combo. The combo is built for the form we transition into.
function shikudoLock.dispatch()
  -- Initialize if missing
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}
  ataxia.balances = ataxia.balances or {}
  ataxia.settings = ataxia.settings or {}
  ataxia.settings.separator = ataxia.settings.separator or ";"
  ataxiaTemp = ataxiaTemp or {}
  tAffs = tAffs or {}

  -- Update current phase. A lock that broke takes its prelude and its chokes with it.
  shikudoLock.updatePhase()
  local st, cfg = shikudoLock.state, shikudoLock.config
  if st.phase ~= "KILL" then
    st.choking = false
    st.prelude = 0
  end
  st.roundAlt = {} -- this round's alternated sides; sendRound hands them to the pending round

  -- Phase-based output with Kai energy
  local shownForm = ataxia.vitals.form or "Unknown"
  local kata = ataxia.vitals.kata or 0
  local phaseLabel = shikudoLock.getPhaseLabel()

  -- The status prints only when it CHANGES (or with config.verbose): one press per prompt printed
  -- two lines a prompt, about 400 of them in the 2026-10-27 group log (v4.7.456).
  local status = "\n<cyan>[LOCK] " .. phaseLabel .. " <cyan>| Target: <white>" .. tostring(target)
    .. " <cyan>| Form: <white>" .. shownForm
    .. " <cyan>| Kata: <white>" .. kata
    .. " <cyan>| Kai: " .. shikudoLock.kaiLabel()
    .. "\n<cyan>[LOCK] Affs: "
    .. (has("asthma") and "<green>asthma " or "<red>asthma ")
    .. (has("anorexia") and "<green>anorexia " or "<red>anorexia ")
    .. (has("slickness") and "<green>slickness " or "<red>slickness ")
    .. (has("paralysis") and "<green>para " or "<red>para ")
    .. (has("impatience") and "<green>impat " or "<red>impat ")
    .. (has("weariness") and "<green>weary" or "<red>weary")
  if cfg.verbose or status ~= st.lastStatus then
    cecho(status)
    st.lastStatus = status
  end

  -- Safety check. NAME, not <name>: cecho reads any <word> as a colour tag, and our palette
  -- (misc_scripts/007) has no "name".
  if not target or target == "" then
    cecho("\n<red>[LOCK] No target set! Use: tar NAME")
    return
  end
  -- Dead or not in the room: nothing is sent (shikudo.guardTarget, 006; v4.7.456).
  if shikudo.guardTarget and not shikudo.guardTarget(target) then return end

  -- Handle combatQueue (it ends with the separator, as every part below does)
  local sep = ataxia.settings.separator
  local cmd = ""
  if combatQueue then
    cmd = combatQueue()
  end
  local form = formNow()

  -- SHIELD CHECK. Never a crescent here: it is a kill, and a shatter round is not one.
  if has("shield") or tAffs.shield then
    local kick = shikudoLock.selectKick(form)
    if kick == "crescent" then kick = "risingkick torso" end
    sendRound("shatter", cmd .. "wield " .. shikudo.staffRef() .. sep .. "combo " .. target .. " shatter " .. kick)
    return
  end

  -- KILL: the prelude, then KAI CHOKE every round. The prelude count and the choke latch move when
  -- the round runs (commitRound), so pressing again while one waits sends the same round.
  if st.phase == "KILL" and shikudoLock.canKaiChoke() then
    local prelude = cfg.chokePrelude and not st.choking and st.prelude < cfg.maxPrelude
      and shikudoLock.selectPrelude()
    if prelude then
      lockSay("\n<magenta>[LOCK] Kill prelude: " .. prelude)
      sendRound("mind", cmd .. prelude, true)
      return
    end
    lockSay("\n<green>[LOCK] KAI CHOKE")
    sendRound("choke", cmd .. "kai choke " .. target)
    return
  end

  -- The transition goes first, so the round is built for the form it leads into
  local nextForm = shikudoLock.shouldTransition()
  local trans = ""
  if nextForm then
    trans = "transition to " .. nextForm:lower() .. " form" .. sep
    lockSay("\n<yellow>[LOCK] Transitioning to " .. nextForm)
  end
  local roundForm = nextForm or form

  -- A MIND round instead of the combo
  local mind, critical = shikudoLock.selectTelepathy(roundForm)
  if mind and not cfg.chainTelepathy and (critical or COMBO_ROUNDS[st.lastRound])
    and st.mindRun < cfg.maxMindRounds and (nextForm or not ataxia_kataAtRisk(cfg.lapseGuard)) then
    lockSay("\n<magenta>[LOCK] Telepathy: " .. mind)
    sendRound("mind", cmd .. trans .. mind)
    return
  end

  -- The combo. A MIND command rides after it only with config.chainTelepathy.
  -- The staff's item id, never the bare keyword: "wield staff" also took the user's illusion
  -- staff and the combo was refused (v4.7.456; shikudo.staffRef, 006).
  local line = cmd .. "wield " .. shikudo.staffRef() .. sep .. trans .. shikudoLock.buildCombo(roundForm):gsub("%$tar", target)
  if mind and cfg.chainTelepathy then
    line = line .. sep .. mind
    lockSay("\n<magenta>[LOCK] Telepathy (chained): " .. mind)
  end
  sendRound("combo", line)
end

--------------------------------------------------------------------------------
-- STATUS COMMAND
--------------------------------------------------------------------------------

function shikudoLock.status()
  -- Initialize if missing
  tAffs = tAffs or {}
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}

  local form = ataxia.vitals.form or "Unknown"
  local kata = ataxia.vitals.kata or 0
  -- The chain at which this form is left (monk/004; `skata` overrides it): policy, not a game cap.
  local cap = ataxia_kataLeaveAfter(form)

  -- Update phase
  shikudoLock.updatePhase()
  local phaseLabel = shikudoLock.getPhaseLabel()

  cecho("\n<cyan>+============================================+")
  cecho("\n<cyan>|         <white>SHIKUDO LOCK STATUS<cyan>                |")
  cecho("\n<cyan>+============================================+")

  cecho("\n<cyan>| <white>Phase: " .. phaseLabel)
  cecho("\n<cyan>| <white>Form: <yellow>" .. form .. " <white>(<yellow>" .. kata .. "/" .. (cap or "?")
    .. " kata<white>)")
  cecho("\n<cyan>| <white>Kai: " .. shikudoLock.kaiLabel())
  cecho("\n<cyan>| <white>Mindlock: " .. (mindlocked and "<green>ACTIVE" or "<red>INACTIVE"))

  cecho("\n<cyan>+--------------------------------------------+")
  cecho("\n<cyan>| <white>LOCK PROGRESS:")

  -- Softlock
  local soft = shikudoLock.checkSoftlock()
  cecho("\n<cyan>|   <white>Softlock:   " .. (soft and "<green>[LOCKED]" or "<yellow>[BUILDING]"))
  cecho("\n<cyan>|     " .. (has("asthma") and "<green>[X]" or "<red>[ ]") .. " asthma")
  cecho("  " .. (has("anorexia") and "<green>[X]" or "<red>[ ]") .. " anorexia")
  cecho("  " .. (has("slickness") and "<green>[X]" or "<red>[ ]") .. " slickness")

  -- Venomlock
  local venom = shikudoLock.checkVenomlock()
  cecho("\n<cyan>|   <white>Venomlock:  " .. (venom and "<green>[LOCKED]" or (soft and "<yellow>[NEXT]" or "<dim_grey>[PENDING]")))
  cecho("\n<cyan>|     " .. (has("paralysis") and "<green>[X]" or "<red>[ ]") .. " paralysis")

  -- Hardlock
  local hard = shikudoLock.checkHardlock()
  cecho("\n<cyan>|   <white>Hardlock:   " .. (hard and "<green>[LOCKED]" or (venom and "<yellow>[NEXT]" or "<dim_grey>[PENDING]")))
  cecho("\n<cyan>|     " .. (has("impatience") and "<green>[X]" or "<red>[ ]") .. " impatience <dim_grey>(Telepathy)")

  -- Truelock
  local true_lock = shikudoLock.checkTruelock()
  cecho("\n<cyan>|   <white>Truelock:   " .. (true_lock and "<green>[LOCKED]" or (hard and "<yellow>[NEXT]" or "<dim_grey>[PENDING]")))
  cecho("\n<cyan>|     " .. (has("weariness") and "<green>[X]" or "<red>[ ]")
    .. " weariness <dim_grey>(blocks Fitness)")

  cecho("\n<cyan>+--------------------------------------------+")
  cecho("\n<cyan>| <white>PRESSURE AFFS:")
  cecho("\n<cyan>|   " .. (has("clumsiness") and "<green>[X]" or "<dim_grey>[ ]") .. " clumsiness")
  cecho("  " .. (has("dizziness") and "<green>[X]" or "<dim_grey>[ ]") .. " dizziness")
  cecho("  " .. (has("epilepsy") and "<green>[X]" or "<dim_grey>[ ]") .. " epilepsy")
  cecho("\n<cyan>|   " .. (has("addiction") and "<green>[X]" or "<dim_grey>[ ]") .. " addiction")
  cecho("  " .. (has("stupidity") and "<green>[X]" or "<dim_grey>[ ]") .. " stupidity")

  cecho("\n<cyan>+============================================+")

  if true_lock then
    cecho("\n<green>*** TARGET IS TRUELOCKED - KAI CHOKE (after MIND CONFUSE, DISRUPT) ***")
  elseif hard then
    cecho("\n<yellow>*** HARDLOCKED - Apply weariness for truelock ***")
  elseif venom then
    cecho("\n<yellow>*** VENOMLOCKED - Use Telepathy for impatience ***")
  elseif soft then
    cecho("\n<yellow>*** SOFTLOCKED - Apply paralysis ***")
  end
end

-- Aliases for convenience
function shikudolock()
  shikudoLock.dispatch()
end

function sklstatus()
  shikudoLock.status()
end

function sklockstatus()
  shikudoLock.status()
end
