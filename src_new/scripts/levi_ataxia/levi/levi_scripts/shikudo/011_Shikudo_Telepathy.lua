--[[mudlet
type: script
name: CC_Shikudo_Telepathy
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
  OFFENSIVE SYSTEM - Shikudo dispatch with Telepathy (alias vv -> shikudo.dispatchMind())

  REQUIRED READING before modifying:
  - .claude/classes/lock_types.md (lock definitions)
  - .claude/classes/monk.md and kb/combat/shikudo.md (Shikudo, Telepathy, Mystor's fights)
  - shikudo/006 (the dispatch offense: every round vv sends that is not a MIND round is 006's)
  - monk/004_Kai_And_Kata.lua (the kata lapse guard)

  vv is the dispatch offense (zz) with Telepathy between its combos, played as Mystor plays it
  (v4.7.420). His five fights with command echoes (kb/raw/logs/2026-10-11_mystor_*) show:
    * A MIND round goes out ALONE. Of 369 rounds his client sent, 270 were combos, 87 a MIND
      command alone, 11 a MIND LOCK beside a combo and one something else. A lock spends no
      equilibrium (the prompt after "mind lock Agathon/combo ..." at FceAmb0o:338 still has it:
      "[-|E]", :351), so no equilibrium spender ever rode a combo. HELP 4.6: an equilibrium ability
      usually needs balance as well (kb/mechanics/balance-and-queueing.md:16).
    * Mostly in Rain, in BURSTS: 54 of 76 MIND rounds were in Rain, at kata 9-12 -- impatience,
      then paralyse again and again as it is cured, then the combo (FceAmb0o:2600-2964: one
      impatience and seven paralyses, all at [Rain]:9). MIND adds no kata.
    * impatience 31, paralyse 27, disrupt 12 rounds; MIND BATTER, then MIND SCYTHE, finished an
      Infernal (c.iJVmpL:4107, :4227).
  Each round is ONE `queue addclear free` entry, as every 006 round is. `free` waits for
  equilibrium AND balance (HELP 4.6.1), and his MIND rounds fired on the second of the two to come
  back (FceAmb0o:2597-2600). zz, xx and sk stay combo-only until vv is proven live.

  MIND BLACKOUT is wired and OFF (shikudo.tele.blackout): our own success line has never been
  captured, nor whether it needs a lock in the room (kb/CONFLICTS.md #7), nor whether the game
  takes it with a target. Turn it on only after that live test.

  MIND SCYTHE, with the MIND BATTER that sets it up, is wired and OFF too (shikudo.tele.scythe,
  v4.7.420 review). The lock question is the same as blackout's: the wiki marks the abilities a
  lock is NOT needed for with (*) (Telepathy.wiki:6), and Scythe has none and takes no target
  (:426-429), as blackout (:415-418); the user's exceptions name only Radiance and Sapience
  (players file:16-18); and the one scythe in the logs was cast with a lock held (finished
  c.iJVmpL:1715, scythe :4227, lost only after the kill :4233-4234). A scythe the game refuses
  changes nothing we read, and nothing reads "You require a mindlock to perform that ability."
  (MIND PRINT and SAPIENCE, LcJC-rJ5:7-10), so vv would pick it again on every press. Both wait on
  a mangledhead recorder as well (see the picker), so nothing goes out today either way.
]]

shikudo = shikudo or {}

-- Options (v4.7.420). Runtime only, as shikudo.config is (006): `shikudo` is not saved, and a
-- reload keeps what is set.
shikudo.tele = shikudo.tele or {}
local TELE_DEFAULTS = {
  manaFloor = 25,          -- % of max mana under which no MIND round goes out
  burstMax = 4,            -- MIND rounds that RUN in a Rain burst before a combo must go out
  burstKata = 9,           -- the chain at which a Rain burst starts (Mystor: 9-12)
  lapseGuard = 12,         -- no MIND round once the chain's last strike is this many seconds old:
                           -- MIND adds no kata, and the chain lapses at about 17-20 s (vNTjvghY:5967)
  blackout = false,        -- MIND BLACKOUT: see the header
  scythe = false,          -- MIND SCYTHE and the MIND BATTER that sets it up: see the header
  blackoutManaFloor = 40,  -- % of max mana; MIND BLACKOUT costs 800 (Telepathy.wiki:419)
  blackoutSecs = 4,        -- blackout lasts 4 s, cured by time (AFFLICTION SHOW blackout)
  -- MIND PARALYSE as Rain filler is pressure, and an Apostate ate magnesium right after it
  -- (LcJC-rJ5:3124-3141, :3273-3286), as in 007. Class names are lower-case ataxiaNDB_getClass values.
  classSkip = { apostate = { paralyse = true } },
  -- shield: an item to WIELD on a MIND round, as Mystor wields a Shield of Absorption
  -- (FceAmb0o:2600-2605). Unset, nothing is wielded: whether the wield costs balance is unknown.
}
for k, v in pairs(TELE_DEFAULTS) do
  if shikudo.tele[k] == nil then shikudo.tele[k] = v end
end

-- The target's tree: trigger 389 sets tBals.tree false and re-arms it 13 s later, and stamps
-- ataxiaTemp.targetTreeAt. Their trees came 13-16 s apart (FceAmb0o:359 onwards).
local TREE_COOLDOWN = 13

-- shikudo.teleState() -> a snapshot of everything the picker reads, so the picker is pure.
--   form, kata     ours (charstats); form as charstats names it ("Rain"), nil when unknown
--   eq             our equilibrium at the press. Read for the echo only: the `free` queue waits
--                  for it whatever the round is, so it changes WHEN a round runs, never WHICH
--   mpp            our mana, % of max
--   has(aff)       the target's afflictions through 006's read (haveAff, else tAffs)
--   prone          has("prone")
--   treeUp         their tree is available (tBals.tree is not false)
--   treeLeft       seconds left on their tree's cooldown, only while tBals.tree is false: 016
--                  resets tBals.tree on a target switch but not the stamp, so a stamp read while
--                  the tree is up may be the last target's. nil when unknown
--   blackoutAge    seconds since our own blackout ran, nil before one
--   burst          MIND rounds that ran since the last combo (ataxiaTemp.shikTele)
--   class          the target's class, lower case (ataxiaNDB_getClass, as 007's skip reads it)
--   atRisk         ataxia_kataAtRisk(lapseGuard) (monk/004): a live chain whose last strike is
--                  older than the guard. False when the kata reads 0 -- after the lapse line or a
--                  form change there is no chain to save
--   kataIdle       seconds since the last chain line (ataxiaTemp.kataAt), for display only
--   halfHealth     a fresh ASSESS of this target at half health or less: 006's Crescent test,
--                  ataxia_assessAtMostHalf(5) (monk/004)
function shikudo.teleState()
  local v = (ataxia and ataxia.vitals) or {}
  local tele = (ataxiaTemp and ataxiaTemp.shikTele) or {}
  local now = getEpoch()
  local treeLeft
  if tBals and tBals.tree == false and ataxiaTemp and ataxiaTemp.targetTreeAt then
    treeLeft = math.max(0, TREE_COOLDOWN - (now - ataxiaTemp.targetTreeAt))
  end
  local cls = ataxiaNDB_getClass and target and ataxiaNDB_getClass(target)
  local kataAt = ataxiaTemp and ataxiaTemp.kataAt
  return {
    target = target,
    form = ataxia_shikudoForm(v.form),
    kata = tonumber(v.kata) or 0,
    eq = v.eq == true,
    mpp = tonumber(v.mpp),
    has = shikudo.has,
    prone = shikudo.has("prone"),
    treeUp = not (tBals and tBals.tree == false),
    treeLeft = treeLeft,
    blackoutAge = tele.blackoutAt and (now - tele.blackoutAt) or nil,
    burst = tele.burst or 0,
    class = type(cls) == "string" and cls:lower() or nil,
    atRisk = ataxia_kataAtRisk(shikudo.tele.lapseGuard),
    kataIdle = kataAt and (now - kataAt) or nil,
    halfHealth = ataxia_assessAtMostHalf(5),
  }
end

-- MIND SCYTHE needs "a mangled head and at least two of: stupidity, impatience, dizziness,
-- epilepsy, or confusion" (Telepathy.wiki:433). MIND BATTER gives three of them at once (:444).
local SCYTHE_AFFS = { "stupidity", "impatience", "dizziness", "epilepsy", "confusion" }
-- The lock pieces a tree would otherwise cure: BAIT gives the tree a blackout to take instead.
local LOCK_PIECES = { "asthma", "slickness", "anorexia", "paralysis", "impatience" }

local function count(has, list)
  local n = 0
  for _, aff in ipairs(list) do
    if has(aff) then n = n + 1 end
  end
  return n
end

-- shikudo.telepathyPick(s[, cfg]) -> cmd, why. PURE: reads only the snapshot `s`
-- (shikudo.teleState()) and `cfg` (default shikudo.tele). cmd is the MIND command for this round,
-- or nil for a combo; why says which rule decided, for the echo.
-- No round at all without a target, under the mana floor, or while the chain needs a strike
-- (MIND adds no kata). None either in a kill window, since the kills are combos: she lies down in
-- Gaital (the needle, the spinkick and DISPATCH), or she lies down in Maelstrom with a fresh ASSESS
-- at half health or less, where 006 kicks CRESCENT (selectKick), which slays a prone foe at half
-- health (Shikudo.wiki:358; v4.7.420 review). No equilibrium gate, as in 007 (v4.7.420
-- review): the round waits for equilibrium on the `free` queue whatever it is, so a gate only
-- swapped a MIND round for a combo that ran at the same moment -- and ended every burst after one
-- round whenever the key was pressed early. No lock first: the affliction MIND abilities need only
-- the target in the room (players file:8-16). The two that may need one, SCYTHE and BLACKOUT, are
-- each behind their own setting, off (see the header).
-- Then, in order:
--   1. MIND SCYTHE with a mangled head and two of the five (Mystor's finish, c.iJVmpL:4227).
--   2. MIND BATTER with a mangled head and fewer: it gives the scythe its two (c.iJVmpL:4107).
--      Both only with shikudo.tele.scythe: batter is here to set up the scythe, so without it
--      batter has no claim to go before the lock-closing impatience. Both wait on a recorder
--      too: nothing records a target's mangledhead yet (trigger 632 records damagedhead at 100%
--      head damage and concussion at 200%), so today neither goes out.
--   3. Inside our own blackout: nil, so the combo it hides goes out ("You can blackout, and then
--      combo 1 time. And the combo is hidden.", players file:34-35).
--   4. MIND IMPATIENCE when asthma, slickness and anorexia are on without it: no FOCUS, the lock
--      closes.
--   5. With shikudo.tele.blackout, in Rain: MIND BLACKOUT that STICKS -- she is paralysed or her
--      tree is down for the whole of it -- or as BAIT while her tree is up and two lock pieces are
--      on, so the tree takes the blackout and not a piece ("you give it once, they usually touch
--      tree to cure and we give it again", players file:8). Rain, because the hidden combo waits
--      for our equilibrium and Rain gives it back quickest (0.72 of the wiki's time, against 0.85
--      elsewhere: kb/combat/shikudo.md).
--   6. MIND DISRUPT when confused and not disrupted: only CONCENTRATE gives equilibrium back, and
--      confusion makes it fail (Mystor, confuse then disrupt: FceAmb0o:6309, :6361).
--   7. A Rain burst at kata burstKata+, while fewer than burstMax MIND rounds have run since the
--      last combo: impatience, else paralyse -- not once she is paralysed, nor where classSkip
--      says so.
function shikudo.telepathyPick(s, cfg)
  cfg = cfg or shikudo.tele
  local has, t = s.has, s.target
  if type(t) ~= "string" or t == "" then return nil, "no target" end
  if (s.mpp or 0) < cfg.manaFloor then return nil, "mana under " .. cfg.manaFloor .. "%" end
  if s.atRisk then return nil, "the chain needs a strike before it lapses" end
  if s.form == "Gaital" and s.prone then return nil, "she is down in Gaital: the kill comes first" end
  if s.form == "Maelstrom" and s.prone and s.halfHealth then
    return nil, "she is down at half health in Maelstrom: CRESCENT kills her"
  end

  if cfg.scythe and has("mangledhead") then
    if count(has, SCYTHE_AFFS) >= 2 then
      return "mind scythe " .. t, "mangled head and two of the scythe's afflictions"
    end
    return "mind batter " .. t, "mangled head: batter gives the scythe its afflictions"
  end

  if s.blackoutAge and s.blackoutAge < cfg.blackoutSecs then
    return nil, "our blackout hides this combo"
  end

  if has("asthma") and has("slickness") and has("anorexia") and not has("impatience") then
    return "mind impatience " .. t, "closes the lock: no FOCUS"
  end

  if cfg.blackout and s.form == "Rain" and (s.mpp or 0) >= cfg.blackoutManaFloor then
    if has("paralysis") or (s.treeLeft or 0) >= cfg.blackoutSecs then
      return "mind blackout", "blackout sticks: she cannot tree it off"
    end
    if s.treeUp and count(has, LOCK_PIECES) >= 2 then
      return "mind blackout", "blackout as bait for her tree"
    end
  end

  if has("confusion") and not has("disrupted") then
    return "mind disrupt " .. t, "confused: she cannot CONCENTRATE back her equilibrium"
  end

  if s.form == "Rain" and (s.kata or 0) >= cfg.burstKata and (s.burst or 0) < cfg.burstMax then
    local burst = "Rain burst " .. ((s.burst or 0) + 1) .. "/" .. cfg.burstMax
    if not has("impatience") then return "mind impatience " .. t, burst end
    local skip = s.class and cfg.classSkip and cfg.classSkip[s.class]
    if not has("paralysis") and not (skip and skip.paralyse) then
      return "mind paralyse " .. t, burst
    end
  end

  return nil, "no MIND command fits"
end

--------------------------------------------------------------------------------
-- THE ROUND
--------------------------------------------------------------------------------

-- vv's own state, on ataxiaTemp (never saved):
--   at, cmd, form  the last MIND round queued: when, what, and in which form
--   burst          MIND rounds that RAN since a combo last ran
--   blackoutAt     when our last MIND BLACKOUT ran
--   pending        the MIND round queued and not yet run: { key, blackout, committed }
--   runLine        the game's run line has been read for one of our rounds (shikudo.onTeleQueueRan)
-- The burst and the blackout move when a round RUNS, not when vv is pressed: every press sends
-- `queue addclear free`, which replaces a round still waiting, so counting presses made the round
-- that ran depend on how often the key was pressed (CLAUDE.md, "Counter Incrementing"; 007's
-- v4.7.420 review). Until a run line has been read the press is all there is, and counts.
local function teleRun()
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.shikTele = ataxiaTemp.shikTele or { burst = 0 }
  return ataxiaTemp.shikTele
end

-- A round as the run line prints it may differ in case, and the server's wrap moves spaces, so
-- rounds are compared lower-cased with the whitespace dropped (as 007 does).
local function runKey(s)
  return (tostring(s or ""):lower():gsub("%s+", ""))
end

-- A MIND round ran: one more in the burst, and a blackout opens its window.
local function commit(st, p)
  st.burst = (st.burst or 0) + 1
  if p.blackout then st.blackoutAt = getEpoch() end
  p.committed = true
end

-- A combo goes on the free queue, replacing whatever it held, so the pending MIND round will never
-- run. The burst ends when that combo RUNS: ended here, a second press before it ran would find the
-- burst empty and swap the combo back for a MIND round, so the cap would never let a combo out.
local function comboQueued(st)
  st.pending = nil
  if not st.runLine then st.burst = 0 end
end

-- The game ran a queued command. `ran` is what follows "command: " on the run line -- only its
-- FIRST row when the server wraps it, as 007's shikudoLock.onQueueRan reads it.
--   * Our pending MIND round, which the run line STARTS with: it ran.
--   * Any round with a combo in it (006's, 007's, the combo behind a blackout): a combo ran, and
--     the burst is over. A combo round's first row always reaches its "combo": column 76 with
--     combatQueue()'s "g body;g gold;stand;" and "wield staff;", against a wrap of 119-124.
-- True when it was our pending MIND round. Any other run line moves nothing.
function shikudo.onTeleQueueRan(ran)
  local st = teleRun()
  local key = runKey(ran)
  if key == "" then return false end
  local p = st.pending
  if p and p.key:sub(1, #key) == key then
    st.pending, st.runLine = nil, true
    if not p.committed then commit(st, p) end
    return true
  end
  if tostring(ran):lower():find("%f[%a]combo%f[%A]") then
    st.burst, st.runLine = 0, true
  end
  return false
end

-- The run line, read with the pattern clean-up/001_Queue_Scanning.lua:34 uses (queue_Scan raises
-- no event to listen for). The trigger lives for the session; its id is kept on ataxiaTemp, never
-- saved (a saved id names a stranger's trigger after a restart), and a reload kills the old one
-- first, as 007 does with its own.
shikudo.TELE_RAN_PATTERN = [[^\[System\]\: Running queued \w+ command: (.+)]]
ataxiaTemp = ataxiaTemp or {}
if ataxiaTemp.shikTeleRunTrigger and killTrigger then
  pcall(killTrigger, ataxiaTemp.shikTeleRunTrigger)
end
ataxiaTemp.shikTeleRunTrigger = nil
if tempRegexTrigger then
  ataxiaTemp.shikTeleRunTrigger = tempRegexTrigger(shikudo.TELE_RAN_PATTERN, function()
    shikudo.onTeleQueueRan(matches[2])
  end)
end

-- shikudo.dispatchMind(): the vv round (alias 153).
--   * No target: say so and stop. reboundHold may hold the round, and calls this again when it
--     lets go (the integration every dispatch uses, 006 included).
--   * The kill (checkDispatchReady) and a shield (tAffs.shield, the read 006's round uses) go to
--     shikudo.dispatch(): DISPATCH, or SHATTER first. Every rebound in the logs is a combo into a
--     fresh shield, which bounced whole and cost 1.44 s of equilibrium (c.iJVmpL:218-222,
--     FceAmb0o:2411-2416); a MIND command into one is unseen, and the shield goes first either way.
--   * A MIND pick goes out as its OWN round:
--       queue addclear free <combatQueue()>[wield <shield>;]mind ...[;assess <t>]
--     ending with ASSESS when 006's rounds do (shikudo.config.assessEachRound), as Mystor's every
--     round does (FceAmb0o:2600). Never a transition: the next combo carries it inline (006).
--   * No pick: shikudo.dispatch(), the combo.
function shikudo.dispatchMind()
  ataxia = ataxia or {}
  ataxia.vitals = ataxia.vitals or {}
  ataxia.settings = ataxia.settings or {}
  ataxia.settings.separator = ataxia.settings.separator or ";"
  tAffs = tAffs or {}
  if not target or target == "" then
    cecho("\n<red>[Shikudo vv] No target set! Use: tar NAME")
    return
  end
  if reboundHold and reboundHold.gate(shikudo.dispatchMind) then return end
  -- A dead target gets nothing; a MIND round reaches out of the room, so only the death is checked
  -- here, and 006's dispatch checks the room for a combo (v4.7.456).
  if not shikudo.guardTarget(target, true) then return end
  local st = teleRun()

  if shikudo.checkDispatchReady() then
    comboQueued(st)
    return shikudo.dispatch()
  end
  if tAffs.shield then
    comboQueued(st)
    cecho("\n<dim_grey>[Shikudo vv] combo: her shield goes first")
    return shikudo.dispatch()
  end

  local s = shikudo.teleState()
  local cmd, why = shikudo.telepathyPick(s)
  if not cmd then
    comboQueued(st)
    cecho("\n<dim_grey>[Shikudo vv] combo: " .. why)
    return shikudo.dispatch()
  end

  -- combatQueue() runs only on a MIND round: 006's dispatch runs it for a combo, and twice would
  -- send its cures and calls twice. It can drop a Deliverance target for a new one (ataxia/003),
  -- and this pick was for the old one, so the new target gets 006's round instead.
  local prefix = combatQueue and combatQueue() or ""
  if target ~= s.target then
    comboQueued(st)
    return shikudo.dispatch()
  end

  local cfg, sep = shikudo.tele, ataxia.settings.separator
  local wield = (type(cfg.shield) == "string" and cfg.shield ~= "") and ("wield " .. cfg.shield .. sep) or ""
  local body = prefix .. wield .. cmd
  -- Only with the Health Inspector trait (shikudo.assessSuffix, 006).
  body = body .. shikudo.assessSuffix(not (shikudo.config and shikudo.config.assessEachRound == false), sep)
  local p = { key = runKey(body), blackout = cmd == "mind blackout" }
  st.at, st.cmd, st.form, st.pending = getEpoch(), cmd, s.form, p
  if not st.runLine then commit(st, p) end
  send("queue addclear free " .. body)
  -- MIND BLACKOUT hides the combo that follows it, so that combo is queued now, behind it: `queue
  -- add free` appends, and the combo runs the moment our equilibrium is back. 006 builds it and
  -- sends nothing; a press inside the window sends a fresh one in its place (rule 3 above).
  local hidden = p.blackout and shikudo.buildRound and shikudo.buildRound()
  if hidden then send("queue add free " .. hidden) end
  cecho("\n<magenta>[Shikudo vv] " .. cmd .. (hidden and ", then the combo it hides" or "")
    .. " <dim_grey>(" .. why .. (s.eq and "" or "; waits for equilibrium") .. ")")
end
