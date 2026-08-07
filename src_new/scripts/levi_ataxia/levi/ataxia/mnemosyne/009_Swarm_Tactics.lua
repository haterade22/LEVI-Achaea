--[[mudlet
type: script
name: Mnemosyne Swarm Tactics
hierarchy:
- Levi_Ataxia
- Ataxia
- Mnemosyne
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    MNEMOSYNE SWARM TACTICS  (mnem swarm)
    ============================================================================
    Deep ripples pack 3-4+ roaming denizens per room; standing in the swarm eats
    every round. Stage 1 ships the PULL & FUNNEL loop:

      enter room, settled count >= threshold
        -> swing ONCE (aggro) and step back to the just-cleared room, as ONE
           queued line ("<attack>;<backdir>" -- atomic on balance, the same
           shape as the user's manual ragepull alias)
        -> in the funnel room: fight whatever follows (1-2 at a time)
        -> when the trickle stops, re-enter and re-assess; after MAX_PULLS the
           room is fought in place (no infinite ping-pong).

    Stage 2 adds the swarm-followed branches (outdoors fly-kite, indoors
    icewall+leap via bracers417868 / chitin greaves) -- their config keys exist
    but the branches are not wired yet.

    Division of labour: the EXPLORER (008) owns navigation and delegates each
    decidable tick here via S.onTick() (true = tick consumed). COMBAT stays the
    autobasher's; the pull rides ataxiaBasher_assembleAttack as a one-shot
    decorator (S.decorate) so battlerage/augment/culling are untouched. While a
    pull chain is queued server-side, ataxiaTemp.swarmHold gates
    ataxiaBasher_tryAttack so the next dispatch's `queue addclearfull` cannot
    wipe the chain. Tactical moves NEVER write explore.failed (they are walked
    edges -- condemning them would poison the sweep).

    SLEUTH boon recon: with mnemSleuth set, GO fires `fullsense` and the block
    is captured raw into S.recon (format learned from live logs; unparsed recon
    changes nothing). `mnem sense` re-scans on demand -- denizens ROAM, so any
    recon is a snapshot and the per-arrival assess stays authoritative.

    Loads after 004 (parsers/_captureLines) and 008 (explorer). See
    .claude/projects/mnemosyne/07-explorer.md for the full design.
    ============================================================================
]]--

ataxia.mnemosyne = ataxia.mnemosyne or {}
local M = ataxia.mnemosyne
M.swarm = M.swarm or {}
local S = M.swarm

local FOLLOW_WINDOW = 2     -- seconds to wait in the funnel room for followers. 4 -> 3 -> 2
                            -- (user, v4.7.156/157): chasers arrive QUICKLY, so a longer wait
                            -- only ever idles on mobs that were never coming. Safe because the
                            -- window is REFRESHED by combat -- anything that did follow and is
                            -- swinging keeps resetting it, so a real fight still holds us.
local WALL_WINDOW = 8       -- behind our own icewall: leakers trickle slower, wait longer
local MAX_PULLS = 3         -- pulls per room before giving up and fighting in place
local PULL_ARM_TIMEOUT = 2.5 -- armed decorator never consumed (no swing came) -> act plain
local HOLD_TIMEOUT = 8      -- swarmHold self-clears (a cq all can destroy the queued chain);
                            -- > slowest class balance so a legitimately-queued chain isn't
                            -- un-gated and wiped just before it fires
local SENSE_TIMEOUT = 2.0   -- fullsense capture: seconds of silence before flushing
local SENSE_DELAY = 3.0     -- on GO: wait out the wade-status/look burst (their captures
                            -- would force-finish ours and recon would store the wrong block)
local PANIC_COOLDOWN = 10   -- min seconds between Roll Hide panic tumbles
local RECOVER_TICK = 2      -- while hovering to recover, re-check HP this often
local RECOVER_MAX = 60      -- hard cap on a recovery hover (then land and hand back)
local EMERGENCY_COOLDOWN = 2 -- min seconds between vitals-driven emergency actions
local DISENGAGE_COOLDOWN = 10 -- min seconds between forced tactical disengages

-- Reload-safety: ataxiaTemp persists across a SYSUPDATE reload; a stranded hold or
-- armed decorator would silently gate the whole basher / decorate a random attack.
ataxiaTemp = ataxiaTemp or {}
ataxiaTemp.swarmHold = nil
ataxiaTemp.swarmPullDir = nil

S.state = "idle" -- idle | pulling | funnel | reenter
S.pulls = S.pulls or {}       -- [roomNum] = UNPRODUCTIVE pull count this ripple (progress refunds it)
S.noTactics = S.noTactics or {} -- [roomNum] = true -> fight in place (gave up)
S.entrySnap = S.entrySnap or {} -- [roomNum] = { n, id, hp } at the last pull, for the progress check
S.wallRaised = S.wallRaised or {} -- [roomNum] = true -> our icewall stands on its funnel edge
S.recon = S.recon or nil      -- { at=<epoch>, ripple=<n>, lines={...} } last fullsense

local function now()
  return (getEpoch and getEpoch()) or os.time()
end

function S._echo(msg)
  if M._exploreEcho then M._exploreEcho("<orange>[swarm]<reset> " .. tostring(msg))
  elseif M.echo then M.echo("[swarm] " .. tostring(msg)) end
end

-- Config lives with the rest of the mnem settings (ataxia.settings.reporting.swarm).
function S._cfg()
  local c = (M._cfg and M._cfg()) or {}
  if type(c.swarm) ~= "table" then c.swarm = {} end
  local s = c.swarm
  if s.enabled == nil then s.enabled = true end
  s.threshold = tonumber(s.threshold) or 3
  if s.icewall == nil then s.icewall = true end -- indoors: wall the door + leap it
  if s.kite == nil then s.kite = true end       -- outdoors swarm-followed: fly/land/hit
  if s.panic == nil then s.panic = true end     -- Roll Hide boon: tumble out at low HP
  -- 35%, not 40 (user, 2026-08-06: "we should set to do this around 35 percent health").
  s.panicAt = tonumber(s.panicAt) or 35         -- HP% that triggers the panic tumble
  -- Changing the default alone would change nothing: _cfg WRITES its defaults into the saved
  -- table, and `ataxia` is serialized wholesale, so a literal 40 is already stored. Hence the
  -- migration -- but ONE-SHOT, behind a persisted marker. `panicAt` is settable (`mnem swarm
  -- panic <n>`), and an unconditional rewrite would make 40 permanently untypeable: every
  -- _cfg() call, on every tick, would drag it back to 35 seconds after it was set.
  if not s.panicAt35 then
    s.panicAt35 = true
    if s.panicAt == 40 then s.panicAt = 35 end
  end
  -- ABSOLUTE HP floor (user, 2026-08-03: "we are entering critical health, like 3000").
  -- Percent and absolute answer different questions and BOTH matter: 40% is "this fight is
  -- going badly", 3000 is "the next hit can kill me". With a large max HP the percentage
  -- alone leaves an enormous buffer before it fires, and with a small one it fires far too
  -- early -- so whichever line is crossed FIRST wins. Set to 0 to use the percentage only.
  s.panicHp = tonumber(s.panicHp) or 3000
  s.bravadoThreshold = tonumber(s.bravadoThreshold) or 2 -- Bravado affix: hit-and-run this early
  if s.escape == nil then s.escape = true end   -- low-HP escape ladder (fly / retreat) instead of shield-in-place
  s.escapeAt = tonumber(s.escapeAt) or 35       -- HP% that triggers the escape
  s.recoverAt = tonumber(s.recoverAt) or 95     -- HP% at which a recovery hover may land (also needs aff-free)
  if s.recoverAt == 75 then s.recoverAt = 95 end -- migrate the short-lived v4.7.114 default
  s.bracersId = s.bracersId or "bracers417868"  -- Bracers of Frost (ICEWALL)
  s.meltId = s.meltId or "bracers151113"        -- Bracers of Flame (melt own wall)
  return s
end

-- The room brief's "(indoors)" flag, via gmcp Room.Info.details.
function S._indoors()
  local det = gmcp and gmcp.Room and gmcp.Room.Info and gmcp.Room.Info.details
  if type(det) ~= "table" then return false end
  for _, d in pairs(det) do
    if d == "indoors" then return true end
  end
  return false
end

local function hpp()
  return (ataxia and ataxia.vitals and tonumber(ataxia.vitals.hpp)) or 100
end

-- Fresh HP% straight from the GMCP payload. The vitals handler below fires on the
-- same event that UPDATES ataxia.vitals -- registration order could hand hpp() the
-- PREVIOUS prompt's value, and the emergency path can't afford a stale read.
local function hppFresh()
  local v = gmcp and gmcp.Char and gmcp.Char.Vitals
  local hp, max = tonumber(v and v.hp), tonumber(v and v.maxhp)
  if hp and max and max > 0 then return math.floor(hp / max * 100) end
  return hpp()
end

-- "Fully healed" for the recovery hover = aff-free too (user spec): broken limbs ARE
-- afflictions, so restoration cycles finish before we drop back in. Blindness/deafness/
-- curseward are deliberately KEPT as defences while bashing -- never hold the hover for
-- them (we'd float forever).
local AFF_IGNORE = { blindness = true, deafness = true, curseward = true, insomnia = true }

-- The bash curing profile (ataxia/008) PARKS the junk mental spray at priority 25 so it
-- cannot outbid a potash for the eating balance. The consequence here is that those affs
-- stay up indefinitely -- so an unmodified aff-free test would never pass and every hover
-- would burn its full RECOVER_MAX cap instead of landing the moment we were healed. A
-- parked affliction is one we have DECIDED not to cure; it must not hold the hover.
-- Only while the profile is actually active, so PvP behaviour is untouched.
local function parkedAff(k)
  if not (ataxia_bashProfileActive and ataxia_bashProfileActive()) then return false end
  if not ataxia_bashCuringPrios then return false end
  local floor = (ataxiaBashProfile and ataxiaBashProfile.PARKED) or 20
  local p = ataxia_bashCuringPrios()[k]
  return type(p) == "number" and p >= floor
end

function S._afflicted()
  local a = ataxia and ataxia.afflictions
  if type(a) ~= "table" then return false end
  for k, v in pairs(a) do
    if not AFF_IGNORE[k] and not parkedAff(k) then
      if k == "unknown" then
        if type(v) == "number" and v > 0 then return true end
      elseif v == true then
        return true
      end
    end
  end
  return false
end

-- Current server target's id + live hp% for the hit-and-run progress check.
-- Same data chain as the bashing HUD's mob bar: denizen-state hpp (fed per prompt
-- from gmcp.IRE.Target.Info, id-guarded) with a live-GMCP fallback; negative /
-- "-1" readings mean "no data", not 0%.
function S._targetHp()
  if type(target) ~= "number" then return nil, nil end
  if ataxiaBasher_dsGet then
    local ds = ataxiaBasher_dsGet(target)
    local hp = ds and tonumber(ds.hpp)
    if hp and hp >= 0 then return target, hp end
  end
  local info = gmcp and gmcp.IRE and gmcp.IRE.Target and gmcp.IRE.Target.Info
  if info and info.hpperc then
    -- Parens truncate gsub's count return -- tonumber(str, count) reads it as a BASE
    -- and errors (the live Psion battlerage failure; same trap, latent copy).
    local hp = tonumber((tostring(info.hpperc):gsub("%%", "")))
    if hp and hp >= 0 then return target, hp end
  end
  return target, nil
end

-- Threshold, optionally depth-scaled: at/past ripple `deepAt`, use `deepThreshold`.
function S.threshold()
  local s = S._cfg()
  local ripple = (M.run and tonumber(M.run.ripple)) or 0
  local t = s.threshold
  if s.deepAt and s.deepThreshold and ripple >= tonumber(s.deepAt) then
    t = tonumber(s.deepThreshold)
  end
  -- BRAVADO (v4.7.206, user rule): "we need to hit and run at two denizens instead of 3 as it
  -- can get pretty wild". The affix strips shields, prismatic barriers and blood barriers, so
  -- the hit-and-run IS the mitigation -- there is nothing else left to absorb a bad round, and
  -- as the user put it, "we will never know our health pool". CLAMPS DOWN only: a threshold
  -- already at 2 (or a deep-ripple 2) is left alone, and a higher one is pulled in rather than
  -- overwritten, so the setting still means something the rest of the time.
  if mnemBravado then t = math.min(tonumber(t) or 3, tonumber(s.bravadoThreshold) or 2) end
  return t
end

function S._enabled()
  return S._cfg().enabled == true
    and M.explore ~= nil and M.explore.on == true
    and ataxiaBasher ~= nil and ataxiaBasher.enabled == true
    and ataxiaBasher.manual == true -- areabash mid-tower would nextRoom() via the mapper
end

-- Validated direction back to the just-cleared room: must exist, be PLANAR (never
-- pull "up" into the holding room -- the first grid room's entry is `down`), and be
-- adjacency-verified against the reported-exit graph (a stale fromDir after a
-- non-explorer move must not route us somewhere random). Pure; unit-tested.
-- Returns shortBack, longBack, shortForward (funnel->swarm re-entry dir), or nil.
function S._backDir()
  local MAP = M.map
  local e = M.explore
  if not (MAP and e and e.fromRoom and e.fromDir and MAP.current) then return nil end
  if e.fromRoom == MAP.current then return nil end
  local fwd = MAP.normDir and MAP.normDir(e.fromDir)
  local back = fwd and MAP.OPPOSITE and MAP.OPPOSITE[fwd]
  if not back then return nil end
  if not (MAP.OFFSETS and MAP.OFFSETS[back]) then return nil end
  local room = MAP.rooms and MAP.rooms[MAP.current]
  if not (room and room.exits and room.exits[back] == e.fromRoom) then return nil end
  return MAP.shortDir(back), back, MAP.shortDir(fwd)
end

-- ---------------------------------------------------------------------------
-- Pull lifecycle
-- ---------------------------------------------------------------------------

-- Issue a plain tactical move (no swing) -- the fallback when the decorator is
-- never consumed, and the re-entry step. Rides M._tacticalArm so the explorer's
-- moving guard/timeout apply WITHOUT the condemn-on-failure behavior.
-- WHICH JUMP (v4.7.217). User: "when in bard, we should BACKFLIP (direction) instead of Leap
-- as it is faster balance." Acrobatics BACKFLIP recovers quicker than the chitin-greaves LEAP,
-- and in the tower every tactical move is a retreat we are making because something is going
-- badly -- the balance we get back is the balance we spend curing.
--
-- EXCEPT over a wall. The leaps in this module are not merely movement: the whole point of
-- several of them is to clear our OWN standing icewall, and greaves-LEAP is the ability we
-- have confirmed does that (in both directions -- it is why re-entry needs no melt). Whether
-- BACKFLIP crosses an icewall is NOT confirmed, and the cost of being wrong is not a slow
-- move, it is a silent no-op in the indoor low-HP escape -- the anti-death ladder livelocking
-- at crash HP, which is the exact failure the LEAP was introduced to fix.
--
-- So: backflip when the edge we are crossing has no wall we know about, leap when it does.
-- `wallRaised[room]` already records the walled edge's LONG dir (the panic tumble reads the
-- same field to avoid tumbling into our own ice). Unresolvable wall state falls back to LEAP:
-- the conservative answer is the one that still moves us.
function S.moveVerb(dirShort)
  local MAP = M.map
  local walled = S.wallRaised and MAP and MAP.current and S.wallRaised[MAP.current]
  if walled then
    local ws = (type(walled) == "string" and MAP.normDir and MAP.shortDir
      and MAP.shortDir(MAP.normDir(walled))) or nil
    if ws == nil or ws == dirShort then return "leap" end
  end
  local class = gmcp and gmcp.Char and gmcp.Char.Status and gmcp.Char.Status.class
  if class == "Bard" then return "backflip" end
  return "leap"
end

function S._tacticalGo(dirShort, why)
  if not (M._tacticalArm and dirShort) then return S.reset("no tactical mover") end
  M._tacticalArm(dirShort)
  local sep = (ataxia.settings and ataxia.settings.separator) or ";"
  -- JUMP, never walk (review CRITICAL): a tactical retreat can cross our OWN
  -- standing icewall -- the indoor low-HP escape retreats through the walled
  -- funnel edge, where a plain walk silently fails and the anti-death ladder
  -- livelocks at crash HP. A jump clears any wall (ours or an affix's) and is
  -- plain movement when there is none. Eq-gated; the tactical timeout still
  -- hands back to assess if the jump never lands. See S.moveVerb for which one.
  send("queue addclear free stand" .. sep .. S.moveVerb(dirShort) .. " " .. dirShort)
  if why then S._echo(why .. " -> <cyan>" .. dirShort .. "<reset>.") end
end

-- The escape suffix appended to the decorated attack, by mode:
--   pull:  ";<backdir>"                          -- plain step out
--   wall:  ";point <bracers> <LONG back>;leap <back>" -- raise the icewall on the exit
--          we came through, then LEAP over our own wall (chitin greaves; the manual
--          ragepull alias proves leap-over-own-wall works). One queue entry keeps the
--          order: swing -> wall -> leap, all on the same balance.
-- The wall PERSISTS across cycles (user-confirmed: LEAP clears our own wall in both
-- directions, so re-entry never melts it) -- follow-up escapes skip the point and go
-- leap-only, which fires a full balance-round sooner (point waits for balance, leap
-- only for eq). If the wall broke/expired the leap-only escape degrades to a plain
-- unwalled pull -- acceptable: denizens walk through icewalls anyway without
-- Maklak's Promise. S.wallRaised[room] tracks it, optimistic at send time; cleared
-- by the end-of-room melt (onTick) and each new ripple.
function S._escapeSuffix(sep)
  local s = S._cfg()
  if S.mode == "wall" then
    S.wallRaised = S.wallRaised or {}
    if S.swarmRoom and S.wallRaised[S.swarmRoom] then
      return sep .. "leap " .. S.backShort
    end
    if S.swarmRoom then
      -- Remember WHICH edge is walled (the LONG back dir): the panic tumble
      -- avoids it, and the memory only wipes on a genuine ripple boundary.
      S.wallRaised[S.swarmRoom] = S.backLong
      S._wallsRipple = (M.run and tonumber(M.run.ripple)) or 0
    end
    return sep .. "point " .. s.bracersId .. " " .. S.backLong .. sep .. "leap " .. S.backShort
  end
  -- ROLL HIDE: tumble instead of stepping (v4.7.223). A plain step-out is what lets the swarm
  -- follow us into the funnel room -- the whole reason the funnel branch and the fly-kite
  -- exist. Tumbling sheds them, so the pull stops being "move the fight" and becomes "end the
  -- fight", and the follower-handling branches simply never fire.
  --
  -- Safe inside the single queue entry, for the reason the wall chain already proves: the
  -- entry's commands do NOT all run on one balance -- `point` fires on the next balance and
  -- `leap` on equilibrium, draining across ~7s. So a balance-gated tumble is HELD by the queue
  -- until balance returns rather than being rejected, exactly like the point is.
  if mnemRollHide then return sep .. "tumble " .. S.backShort end
  return sep .. S.backShort
end

function S._beginPull(shortBack, longBack, shortFwd, count, mode)
  local MAP = M.map
  local cur = MAP and MAP.current
  if not cur then return false end
  S.pulls[cur] = (S.pulls[cur] or 0) + 1
  if S.pulls[cur] > MAX_PULLS then
    S.noTactics[cur] = true
    S._echo("<indian_red>" .. MAX_PULLS .. " pulls spent here<reset> -- fighting this room in place.")
    S.state = "idle"
    return false
  end
  -- Snapshot for the hit-and-run progress check on the NEXT assess of this room:
  -- pre-swing count + focused target hp (both improve when the cycle achieves anything).
  do
    local id, hp = S._targetHp()
    S.entrySnap[cur] = { n = count, id = id, hp = hp }
  end
  S.state = "pulling"
  S.mode = mode or "pull"
  S.swarmRoom, S.funnelRoom = cur, M.explore.fromRoom
  S.backShort, S.backLong, S.fwdShort = shortBack, longBack, shortFwd
  S.peakFollowers, S.announcedFollow = 0, false
  -- Arm the one-shot decorator: the next assembled attack gains the escape suffix.
  ataxiaTemp.swarmPullDir = shortBack
  if S._pullFallbackT then pcall(killTimer, S._pullFallbackT) end
  S._pullFallbackT = tempTimer(PULL_ARM_TIMEOUT, function()
    S._pullFallbackT = nil
    if S.state == "pulling" and ataxiaTemp.swarmPullDir then
      -- No swing came (shielded branch / no target / hard aff) -- escape without the hit.
      ataxiaTemp.swarmPullDir = nil
      local sep = (ataxia.settings and ataxia.settings.separator) or ";"
      if M._tacticalArm then M._tacticalArm(S.backShort) end
      send("queue addclear free stand" .. S._escapeSuffix(sep))
      S._echo("no swing came; escaping plain -> <cyan>" .. S.backShort .. "<reset>.")
    end
  end)
  S._echo("<yellow>" .. tostring(count) .. " denizens<reset> (>= " .. S.threshold() .. ") -- "
    .. (S.mode == "wall" and "hit once, WALL the door and leap it" or "hit once and pull back")
    .. " (" .. S.pulls[cur] .. "/" .. MAX_PULLS .. ").")
  return true
end

-- Called by S.decorate at the moment the pull chain is actually being sent.
function S._onPullSent()
  if S._pullFallbackT then pcall(killTimer, S._pullFallbackT); S._pullFallbackT = nil end
  -- Gate further dispatches: the next `queue addclearfull` would wipe the queued chain.
  ataxiaTemp.swarmHold = true
  if S._holdT then pcall(killTimer, S._holdT) end
  S._holdT = tempTimer(HOLD_TIMEOUT, function()
    S._holdT = nil
    ataxiaTemp.swarmHold = nil -- self-clear: a cq all (death/attacked) can destroy the chain
  end)
  -- The move rides the attack chain; arm the explorer's in-flight machinery so ticks
  -- hold and a lost move times out WITHOUT condemning the walked edge. HOLD_TIMEOUT (not
  -- the default 5s): the chain fires on balance regain, and a slow round must not have
  -- the timeout clear the hold while the chain is still legitimately queued.
  if M._tacticalArm and S.backShort then M._tacticalArm(S.backShort, HOLD_TIMEOUT) end
  -- Stale-target hygiene for the room change (re-derived next prompt)...
  found_target = false
  -- ...and the shield-retarget timer must not re-settarget the old mob cross-room.
  if ataxiaTemp.mobshieldtimer then pcall(killTimer, ataxiaTemp.mobshieldtimer); ataxiaTemp.mobshieldtimer = nil end
end

-- Attack-chain decorators, called from ataxiaBasher_assembleAttack just before its
-- send. (1) One-shot pull/wall escape: append the escape suffix and arm the hold.
-- (2) Persistent kite wrap while flying: "land;<attack>;fly" -- touch ground only
-- for the swing; if FLY turns out to need balance the trailing fly is rejected and
-- we simply fight grounded that round (degrades, never wedges).
function S.decorate(command, sep)
  if ataxiaTemp.swarmPullDir and S.state == "pulling"
     and M.map and M.map.current == S.swarmRoom then -- a forced move mid-arm would make the backdir bogus
    ataxiaTemp.swarmPullDir = nil
    local decorated = command .. S._escapeSuffix(sep)
    S._onPullSent()
    return decorated
  end
  if S.flying and S.state == "funnel"
     and M.map and M.map.current == S.funnelRoom then -- same guard as the pull: no stale wraps after a forced move
    return "land" .. sep .. command .. sep .. "fly"
  end
  return command
end

function S._clearHold()
  if S._holdT then pcall(killTimer, S._holdT); S._holdT = nil end
  ataxiaTemp.swarmHold = nil
end

function S._enterFunnel()
  S._clearHold()
  S.state = "funnel"
  S.funnelAt = now()
  -- Belt-and-braces: followers' names are already learned from the swarm room's
  -- Items.List, but a never-Listed spawn would be invisible to search_targets --
  -- one quicklook re-Lists the room (the watchdog's own nudge, known-safe).
  send("ql")
  S._echo("in the funnel room -- fighting what follows (window " .. FOLLOW_WINDOW .. "s).")
end

function S._beginReenter()
  S.state = "reenter"
  local followers = S.peakFollowers or 0
  if S.flying then send("land"); S.flying = nil end
  if S.mode == "wall" then
    -- The icewall STAYS (user-confirmed): chitin-greaves LEAP clears our own wall
    -- in BOTH directions, so re-entry is a single eq-gated jump -- no melt, no walk.
    -- The standing wall keeps pacing the swarm (a real barrier with Maklak's
    -- Promise) and lets follow-up escapes go leap-only (see _escapeSuffix). It is
    -- melted only when the tactic is done with the room (onTick's empty-room
    -- cleanup) so normal navigation can walk the edge again. If the wall already
    -- broke, the leap still lands -- it is plain movement without an obstacle.
    if not (M._tacticalArm and S.fwdShort) then return S.reset("no tactical mover") end
    M._tacticalArm(S.fwdShort)
    local sep = (ataxia.settings and ataxia.settings.separator) or ";"
    send("queue addclear free stand" .. sep .. "leap " .. S.fwdShort)
    S._echo("trickle over (peak followers: " .. followers .. ") -- leaping our wall back in -> <cyan>" .. S.fwdShort .. "<reset>.")
    return true
  end
  S._tacticalGo(S.fwdShort, "trickle over (peak followers: " .. followers .. ") -- re-entering")
  return true
end

-- Roll Hide panic: at panic HP with the boon up, tumble out -- the boon sheds ALL
-- pursuers.
--
-- DIRECTION: back into the room we just CLEARED, first choice (user, 2026-08-03:
-- "we should tumble out into the room we just cleared"). That room is the one place on
-- the grid we know is empty, and since Roll Hide drops every pursuer we arrive there
-- alone -- which is the whole point of tumbling rather than walking. `S._backDir()` is
-- the validated route to it (planar, adjacency-checked against the reported-exit graph,
-- never "up" into the holding room), and it is the same machinery the escape ladder's
-- indoor retreat already uses.
--
-- Only if there is no validated back-route do we fall back to the old heuristic: any
-- planar exit that is not toward the swarm room and not into our own icewall. That is
-- strictly worse -- an unexplored room can hold anything -- but it still beats dying in
-- place, which is what the fallback exists for.
function S._panicDir()
  local MAP = M.map
  -- The back edge is very often the WALLED one -- the indoor icewall tactic raises its wall
  -- on exactly that edge and LEAPS over it, so a plain `tumble <back>` would walk into our
  -- own ice and fail, wasting the panic and its 10s cooldown at the worst possible moment.
  -- (Caught by the existing fight-in-place test, which is why it was written.) Check the
  -- wall before preferring the cleared room; if it is walled, fall through to the heuristic
  -- below, which already excludes it.
  local walledLong = S.wallRaised and MAP and MAP.current and S.wallRaised[MAP.current]
  local walledShort = (type(walledLong) == "string" and MAP and MAP.shortDir
    and MAP.normDir and MAP.shortDir(MAP.normDir(walledLong))) or nil
  local back = S._backDir and select(1, S._backDir())
  if back and back ~= walledShort then return back end
  local room = MAP and MAP.rooms and MAP.current and MAP.rooms[MAP.current]
  if not (room and room.exits) then return nil end
  local fwd = S.fwdShort and MAP.normDir and MAP.normDir(S.fwdShort)
  -- Also avoid tumbling INTO our own standing icewall (fight-in-place panic in a
  -- walled room): wallRaised stores the walled edge's LONG dir for this room.
  local walled = S.wallRaised and MAP.current and S.wallRaised[MAP.current]
  walled = (type(walled) == "string" and MAP.normDir and MAP.normDir(walled)) or nil
  local fallback
  for d in pairs(room.exits) do
    if MAP.OFFSETS and MAP.OFFSETS[d] then
      if d ~= fwd and d ~= walled then return MAP.shortDir(d) end
      fallback = MAP.shortDir(d)
    end
  end
  return fallback
end

-- Is HP into panic territory? EITHER line triggers -- see the panicHp note in _cfg.
-- `hp` is a percentage; `ataxia.vitals.hp` is the absolute reading the floor compares.
function S._panicHpHit(hp)
  local s = S._cfg()
  hp = tonumber(hp) or hpp()
  if hp <= (tonumber(s.panicAt) or 40) then return true end
  local floor = tonumber(s.panicHp) or 0
  if floor <= 0 then return false end
  local raw = tonumber(ataxia and ataxia.vitals and ataxia.vitals.hp)
  -- A missing or blackout reading must never fake a panic: 0 here means "unknown", and
  -- the percentage branch above is already the general safety net.
  if not raw or raw <= 0 then return false end
  return raw <= floor
end

function S._maybePanic(hpNow)
  local hp = tonumber(hpNow) or hpp()
  local s = S._cfg()
  if s.panic == false or not mnemRollHide then return false end
  -- Already out and healing: a second tumble sheds nothing (Roll Hide shed them the first
  -- time) and only walks us further from the sweep. Without this the 10s cooldown was the
  -- only thing between a slow heal and a tumble every ten seconds, wandering the ripple.
  if S.state == "recovering" then return false end
  if not S._panicHpHit(hp) then return false end
  if S._lastPanicAt and (now() - S._lastPanicAt) < PANIC_COOLDOWN then return false end
  local dir = S._panicDir()
  if not dir then return false end
  S._lastPanicAt = now()
  send("cq all")
  if S.flying then
    -- TUMBLE is a ground action: land FIRST or the tumble is rejected mid-kite and the
    -- panic (plus its cooldown) is wasted exactly when it matters most.
    send("land")
    S.flying = nil
  end
  -- Tear down BEFORE queueing the escape: reset() flushes the queue when a tactic was
  -- active, and that flush must never land on top of our tumble.
  S.reset("panic tumble")
  -- Free-queued, not raw: at panic HP the balance is usually spent mid-round, and a raw
  -- tumble would be rejected. The free queue fires it the instant we're able -- and the
  -- hold is re-armed so the next attack dispatch's `queue addclearfull` (sub-second via
  -- gmcp vitals) cannot wipe the queued tumble while we wait. Self-clears in HOLD_TIMEOUT;
  -- a few gated swings while fleeing at panic HP is a feature, not a cost.
  ataxiaTemp.swarmHold = true
  if S._holdT then pcall(killTimer, S._holdT) end
  S._holdT = tempTimer(HOLD_TIMEOUT, function()
    S._holdT = nil
    ataxiaTemp.swarmHold = nil
  end)
  local sep = (ataxia.settings and ataxia.settings.separator) or ";"
  send("queue addclear free stand" .. sep .. "tumble " .. dir)
  -- HEAL WHERE WE LANDED, then go back in (user, 2026-08-06: "the denizens wont follow so we
  -- can use this to our advantage to heal up and then do hit and run tactics").
  --
  -- The tumble used to hand straight back to the explorer at `idle`, and the swarmHold
  -- self-cleared in HOLD_TIMEOUT -- so within about eight seconds we NAVIGATED BACK INTO THE
  -- ROOM WE HAD JUST FLED, still at panic HP. Roll Hide's whole value is that the room we land
  -- in is quiet; spending that on an immediate return threw the boon away.
  --
  -- So the tumble now enters the same recovery state the escape ladder uses -- navigation and
  -- attack dispatch held until recoverAt% AND affliction-free -- with recoverGround set,
  -- because unlike the hover this one is standing on the floor and is NOT untouchable.
  S.state = "recovering"
  S.recoverGround = true
  S.recoverStarted = now()
  S._armRecoverHold()
  -- Self-ticking, like the hover: a recovery must never wait on an outside event to notice
  -- it has healed.
  if M._scheduleTick then M._scheduleTick(RECOVER_TICK) end
  S._echo("<indian_red>PANIC (" .. hp .. "% hp)<reset> -- Roll Hide tumble <cyan>" .. dir
    .. "<reset> sheds all pursuers; healing to " .. s.recoverAt .. "% before going back in.")
  return true
end

-- ---------------------------------------------------------------------------
-- A TUMBLE THAT NEVER LANDED (v4.7.233)
-- ---------------------------------------------------------------------------
-- Death log, 2026-08-07:
--
--   You begin to tumble agilely to the north.
--   ... [ shiv PAR dis ]        <- paralysed, still in the room
--   ... You have been slain by a HaHaHa lancer.
--
-- "You begin to tumble agilely to the north." is the START of a two-stage action, not its
-- completion. Paralysis (or prone, or a stun) between the two halves cancels it and we simply
-- stay put -- and NOTHING checked. The panic tumble is a raw free-queued send with no
-- confirmation of any kind, so the one move the anti-death ladder depends on was the only move
-- in this module that could fail silently.
--
-- Confirmation is the ROOM CHANGING. Not a success line -- the game prints several depending
-- on how the tumble ends, and picking one to trust is how triggers ship dead here. If the room
-- number is the same `TUMBLE_CONFIRM` seconds later, the tumble did not happen: re-send it,
-- with `stand` in front (prone is one of the two things that cancels it) and bounded retries
-- so a genuinely stuck character cannot spin forever.
-- 5s, not 2 (v4.7.234). The user timed a REAL tumble: start 11:52:29.160, "You tumble out of
-- the room." at 11:52:33.178 -- FOUR SECONDS. The 2s window shipped in v4.7.233 would have
-- fired mid-tumble, re-sending a move that was working and landing us two rooms away or
-- burning the queue on a duplicate. A retry window shorter than the action it is guarding is
-- not a safety net, it is a second bug.
--
-- This is only the FALLBACK now: "You tumble out of the room." is the game's own completion
-- line and confirms it directly (trigger misc_alerts/005). The timer covers the case where
-- that line never arrives at all -- which is exactly the paralysis case that started this.
S.TUMBLE_CONFIRM = 5          -- seconds to allow a tumble to land before re-sending
S.TUMBLE_RETRIES = 2          -- re-sends before giving up and letting the ladder decide
S.PULL_RETRIES   = 2          -- re-sends of a lost tactical retreat before handing back

function S.onTumbleStart(dir)
  if type(dir) ~= "string" or dir == "" then return end
  if not (ataxiaBasher and ataxiaBasher.inMnemosyne) then return end
  local MAP = M.map
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.tumbleDir = dir
  ataxiaTemp.tumbleFrom = MAP and MAP.current
  ataxiaTemp.tumbleTries = tonumber(ataxiaTemp.tumbleTries) or 0
  if S._tumbleT then pcall(killTimer, S._tumbleT) end
  S._tumbleT = tempTimer(S.TUMBLE_CONFIRM, function()
    S._tumbleT = nil
    S._tumbleCheck()
  end)
end

function S._tumbleCheck()
  local MAP = M.map
  if not ataxiaTemp or not ataxiaTemp.tumbleDir then return end
  if not (ataxiaBasher and ataxiaBasher.inMnemosyne) then return S.onTumbleDone() end
  -- Moved: the tumble landed. Nothing to do.
  if not MAP or MAP.current ~= ataxiaTemp.tumbleFrom then return S.onTumbleDone() end

  local tries = (tonumber(ataxiaTemp.tumbleTries) or 0) + 1
  if tries > S.TUMBLE_RETRIES then
    S._echo("<indian_red>tumble failed " .. S.TUMBLE_RETRIES .. "x<reset> -- handing back to the ladder.")
    return S.onTumbleDone()
  end
  ataxiaTemp.tumbleTries = tries
  local sep = (ataxia.settings and ataxia.settings.separator) or ";"
  -- Free-queued and stand-first, exactly as the panic sends it: the two things that cancel a
  -- tumble are prone and a lost balance, and this covers both.
  send("queue addclear free stand" .. sep .. "tumble " .. ataxiaTemp.tumbleDir)
  S._echo("<indian_red>tumble did not land<reset> (still in the same room) -- retry "
    .. tries .. "/" .. S.TUMBLE_RETRIES .. " <cyan>" .. ataxiaTemp.tumbleDir .. "<reset>.")
  if S._tumbleT then pcall(killTimer, S._tumbleT) end
  S._tumbleT = tempTimer(S.TUMBLE_CONFIRM, function()
    S._tumbleT = nil
    S._tumbleCheck()
  end)
end

function S.onTumbleDone()
  if S._tumbleT then pcall(killTimer, S._tumbleT); S._tumbleT = nil end
  if ataxiaTemp then
    ataxiaTemp.tumbleDir, ataxiaTemp.tumbleFrom, ataxiaTemp.tumbleTries = nil, nil, nil
  end
end

-- Keep the attack-dispatch hold alive while we hover to recover -- refreshed every
-- recovery tick so the HOLD_TIMEOUT self-clear can't expose us mid-hover.
function S._armRecoverHold()
  ataxiaTemp.swarmHold = true
  if S._holdT then pcall(killTimer, S._holdT) end
  S._holdT = tempTimer(HOLD_TIMEOUT, function()
    S._holdT = nil
    ataxiaTemp.swarmHold = nil
  end)
end

-- Low-HP escape ladder (user-driven design after the cave-bat death: at low HP the
-- no-flee "shield in place" answer FAILS -- touch shield needs an arm, and broken arms
-- are exactly what a chip-down death looks like). Outdoors: FLY and hover untouchable
-- while curing (works with every limb broken); indoors: retreat to the previous cleared
-- room and cure while fighting the trickle. No route indoors -> the old shield behavior
-- stands. Triggers on HP alone -- the cave-bat death had only TWO mobs (below the swarm
-- threshold), so mob count must not gate this.
-- Deluge affix: every room is underwater -- FLY is impossible, so the escape ladder
-- and the fly-kite must take their GROUNDED branches instead of wedging on a
-- rejected fly (queued fly fails silently; the "recovering" state would then hover
-- on the ground, attack-gated, until the 60s cap).
-- Two things make flight unavailable in the tower:
--   * the DELUGE affix ("All rooms are underwater") -- run-wide;
--   * a denizen that DRAGS US BACK DOWN ("A tentacle shoots up from the ground,
--     wraps itself around you, and drags you back to earth.") -- per-ripple, because
--     the thing that yanked us lives on this ripple and will do it again.
-- Either way FLY is a trap rather than an escape, and the ladder must fall through
-- to the grounded retreat instead of wedging on a fly that never sticks.
function S._canFly() return not mnemDeluge and not S.grounded end

-- HOVERING to heal is only a plan if the air is safer than the ground. In an ABLAZE
-- room it is not: the fire keeps burning us at ~6% max HP a tick while we hang there
-- doing nothing but regenerate, so the hover spends its whole budget out-healing the
-- floor and lands no better off. (Contrast the Blazing affix, which smokes flyers for
-- ~511 asphyx/5s -- the hover was measured to out-heal THAT.) Prefer the grounded
-- retreat, which at least gets us out of the fire.
--
-- The kite is deliberately NOT gated on this: kiting lands for every swing anyway, so
-- it is not a way of avoiding the ground, and grounding a kite mid-swarm is worse.
function S._canHover()
  if not S._canFly() then return false end
  local M2 = ataxia and ataxia.mnemosyne
  if M2 and M2.roomAblaze and M2.roomAblaze() then return false end
  return true
end

function S._beginEscape(why)
  local s = S._cfg()
  if not S._indoors() and S._canHover() then
    S.state = "recovering"
    S.recoverStarted = now()
    S.flying = true
    local sep = (ataxia.settings and ataxia.settings.separator) or ";"
    send("queue addclear free stand" .. sep .. "fly")
    S._armRecoverHold()
    -- The hover loop is SELF-ticking; without this kick the next evaluation would
    -- wait on an outside event -- the exact starvation that killed the Pinnacle run.
    if M._scheduleTick then M._scheduleTick(RECOVER_TICK) end
    S._echo("<indian_red>LOW HP (" .. hpp() .. "%)<reset> -- <cyan>flying to recover<reset> (land at " .. s.recoverAt .. "%).")
    return true
  end
  local shortBack, longBack, shortFwd = S._backDir()
  if not shortBack then return false end -- indoors with no route: shield-in-place remains the fallback
  S.state = "pulling"
  S.mode = "pull"
  S.swarmRoom, S.funnelRoom = (M.map and M.map.current), M.explore.fromRoom
  S.backShort, S.backLong, S.fwdShort = shortBack, longBack, shortFwd
  S.peakFollowers, S.announcedFollow = 0, false
  -- HOLD THE ATTACK (v4.7.235). This is what killed us against Seasone: the hover branch above
  -- arms the hold, this one never did. `_tacticalGo` queues `stand;<jump> <dir>`, and the very
  -- next attack dispatch sends `queue addclearfull <attack>` -- which clears the FULL queue and
  -- throws the escape away. The death log shows THREE complete attack rounds between the
  -- disengage and "pull move lost": we were swinging while trying to leave, and the swings ate
  -- the retreat. Same shape as the lyre (v4.7.232) -- a queued action with nothing holding the
  -- dispatcher off it.
  S._armRecoverHold()
  -- `why` is passed by the caller now: this function is reached from the HP ladder AND from
  -- S.disengage, and reporting "LOW HP (97%)" on a tactical disengage made the log unreadable
  -- (97 was the mana column, and HP was nowhere near the escape threshold).
  S._tacticalGo(shortBack, why or ("<indian_red>LOW HP (" .. hpp() .. "%)<reset> -- retreating to recover"))
  return true
end

-- Already airborne (kiting): convert to a recovery hover in place -- no land/fly churn.
function S._convertToHover(hp)
  S.state = "recovering"
  S.recoverStarted = now()
  S._armRecoverHold()
  -- Kick the self-tick loop (see _beginEscape): a hover must never depend on
  -- outside events to notice it has healed -- or that its fly never happened.
  if M._scheduleTick then M._scheduleTick(RECOVER_TICK) end
  S._echo("<indian_red>LOW HP (" .. hp .. "%)<reset> -- staying airborne to recover.")
end

-- FORCED DISENGAGE (v4.7.215) -- leave the fight on a TACTICAL judgement, not an HP reading.
--
-- The escape ladder above is entirely reactive: it fires when HP is already low. That is the
-- right default, but it cannot answer an enemy whose kill pattern is "apply an unsurvivable
-- lock, then wait" -- by the time HP crosses escapeAt we are locked, and a locked character
-- cannot be relied on to execute an escape at all. Seasone's repeat phial bursts are exactly
-- that shape (see M.onSeasonePhials): burst one is survivable, burst two lands on a spent
-- tattoo and kills. The only winning move there is to leave BEFORE the second lock matures.
--
-- So callers that can RECOGNISE a losing pattern get to say "get out now" while we are still
-- healthy enough to obey. Everything downstream is the proven ladder -- fly-and-hover
-- outdoors, pull back to the cleared room indoors -- including its recovery gate
-- (recoverAt% AND affliction-free), which is what makes this a real disengage: we do not
-- come back until the lock is actually gone.
--
-- Returns true when we are (or already were) out. False means the caller must handle it:
-- disabled, on cooldown, or indoors with no route back -- and a caller that read the pattern
-- as lethal should treat that as its last chance to spend an emergency cure.
function S.disengage(reason)
  if not S._enabled() then return false end
  if S.state == "recovering" then return true end -- already out and healing; nothing to do
  if S._lastDisengageAt and (now() - S._lastDisengageAt) < DISENGAGE_COOLDOWN then return false end
  if S.flying then
    -- Mid-kite: convert in place. A land/fly churn here would put us on the ground for a
    -- round, which is the one thing a disengage exists to avoid.
    S._lastDisengageAt = now()
    S._convertToHover(hpp())
    S._echo("<indian_red>DISENGAGE<reset>" .. (reason and (" (" .. reason .. ")") or "")
      .. " -- holding altitude until clean.")
    return true
  end
  if S.state ~= "idle" then S.reset(reason or "disengage") end
  -- Stamp only on success: an indoor room with no validated route back returns false, and
  -- that attempt must not burn the cooldown that a later, movable moment depends on.
  if not S._beginEscape("<indian_red>DISENGAGE<reset>"
      .. (reason and (" (" .. reason .. ")") or "") .. " -- breaking off") then return false end
  S._lastDisengageAt = now()
  S._echo("<indian_red>DISENGAGE<reset>" .. (reason and (" (" .. reason .. ")") or "")
    .. " -- breaking off rather than trading.")
  return true
end

-- Explorer tick delegation. Returns true when the tick is consumed (the explorer
-- must not navigate/announce this tick); false hands back to the normal flow.
function S.onTick()
  local MAP = M.map
  local cur = MAP and MAP.current
  if not S._enabled() then
    if S.state ~= "idle" then S.reset("disabled") end
    return false
  end

  -- Roll Hide panic covers EVERY crowded situation, not just the funnel -- the worst HP
  -- floors are hit in the fight-in-place fallback (no-route / MAX_PULLS rooms) and
  -- mid-kite. Gated inside _maybePanic (boon, config, HP, cooldown, a valid exit).
  if (S.state ~= "idle"
      or ((M._roomHasDenizens and M._roomHasDenizens())
          and ((M._denizenCount and M._denizenCount()) or 0) >= S.threshold()))
     and S._maybePanic() then
    return true
  end

  -- Recovery hover: stay airborne and gated until FULLY healed -- recoverAt% (default 95)
  -- AND affliction-free (user spec: broken limbs must finish their restoration cycles
  -- before we drop back in) -- or the hard cap.
  if S.state == "recovering" then
    local s = S._cfg()
    -- A GROUND recovery (the Roll Hide tumble) is not untouchable the way the hover is. If
    -- something wanders into the room with us, standing there attack-gated at panic HP is
    -- strictly worse than fighting it -- hand back and let the basher swing.
    if S.recoverGround and M._roomHasDenizens and M._roomHasDenizens() then
      -- MOVE AGAIN, do not stand and fight (v4.7.233). The v4.7.218 rule handed straight back
      -- to the basher here, and the death log shows what that costs: "company arrived
      -- mid-recovery (43%) -- handing back", then "LOW HP (31%)" four seconds later, then
      -- dead. Handing back drops us into a mob-filled room at half health with the recovery
      -- abandoned -- the worst of both.
      --
      -- With Roll Hide up the answer is another tumble: it sheds pursuers outright, so the
      -- fight does not follow, and we keep healing somewhere quieter. Only when we cannot move
      -- (no boon, no route) is standing and fighting genuinely the better option -- and then
      -- it really is better than being attack-gated while something hits us.
      local dir = mnemRollHide and S._panicDir()
      if dir then
        local sep = (ataxia.settings and ataxia.settings.separator) or ";"
        send("queue addclear free stand" .. sep .. "tumble " .. dir)
        S.onTumbleStart(dir) -- confirm it actually lands; retry if it does not
        S.recoverStarted = now() -- the recovery continues where we land, not from zero
        S._armRecoverHold()
        if M._scheduleTick then M._scheduleTick(RECOVER_TICK) end
        S._echo("<indian_red>company mid-recovery (" .. hpp() .. "%)<reset> -- tumbling on <cyan>"
          .. dir .. "<reset> rather than trading.")
        return true
      end
      S.recoverGround = nil
      S._clearHold()
      S.state = "idle"
      S._echo("<grey>company arrived mid-recovery (" .. hpp() .. "%) and nowhere to go -- handing back.")
      return false
    end
    -- CONFIRM WITH DIAGNOSE (v4.7.233, user: "when tumbling we should ensure we heal to full
    -- and nothing on diagnose"). `S._afflicted()` reads our CLIENT-SIDE tracking, which is
    -- exactly the thing that is unreliable after a chaotic fight -- the death log has
    -- afflictions arriving faster than they were being cured. So the first time we believe we
    -- are clean, send one DIAGNOSE and require the NEXT tick to still agree; the existing
    -- affliction triggers fold its output back into ataxia.afflictions. One extra tick, once
    -- per recovery, and it is the difference between "we think we are clean" and "we are".
    local healed = hpp() >= s.recoverAt and not S._afflicted()
    if healed and not S.recoverDiagnosed then
      S.recoverDiagnosed = true
      send("diagnose")
      S._armRecoverHold()
      if M._scheduleTick then M._scheduleTick(RECOVER_TICK) end
      return true
    end
    if healed or (now() - (S.recoverStarted or 0)) > RECOVER_MAX then
      S.recoverDiagnosed = nil
      -- Only land if we are actually up: a ground recovery sending "land" every time is
      -- noise, and noise in the escape path is how a real refusal gets missed.
      if S.flying then send("land") end
      S.flying = nil
      S.recoverGround = nil
      S._clearHold()
      S.state = "idle"
      S._echo(healed and "<green>fully recovered<reset> (" .. hpp() .. "%, aff-free) -- landing and resuming."
        or "<grey>recover cap hit -- landing and handing back.")
      -- LANDING BLINDNESS (live catch 2026-07-27): while airborne, gmcp Char.Items
      -- reflects the SKY, so denizensHere is EMPTY. Handing this tick straight back
      -- made the explorer read the mob-filled ground room as "room clear" and queue
      -- a move that walked OUT of the fight the moment we touched down. Treat the
      -- landing like an ARRIVAL instead: consume the tick, open the settle window,
      -- and let the land's own Room/Items re-push drive the next decision on real
      -- ground data (the scheduled tick is the no-event backstop -- never wedges).
      if M.explore then M.explore.settling = true end
      if M._scheduleTick then M._scheduleTick() end
      return true
    end
    -- The escape's fly can be eaten just like the Pinnacle pull was (stupidity
    -- replaces queued commands with involuntary actions): S.flying is optimistic
    -- until the flight line confirms (trigger 022 -> S.onFlightUp). Grounded-but-
    -- gated is the worst of both worlds, so re-send each tick until we're really
    -- up. If this fly source's confirm line is unknown, the extra sends are
    -- harmless ("You are already flying.").
    if S.flying and not S.flightConfirmed then
      local sep = (ataxia.settings and ataxia.settings.separator) or ";"
      send("queue addclear free stand" .. sep .. "fly")
    end
    S._armRecoverHold()
    if M._scheduleTick then M._scheduleTick(RECOVER_TICK) end
    return true
  end

  -- Low-HP escape (HP-gated only; see _beginEscape). Already-airborne (kiting) just
  -- converts in place -- no land/fly churn.
  do
    local s = S._cfg()
    if s.escape ~= false and hpp() <= s.escapeAt then
      if S.flying then
        S._convertToHover(hpp())
        return true
      end
      if S.state ~= "idle" then S.reset("low-hp escape") end
      if S._beginEscape() then return true end
    end
  end

  if S.state == "pulling" then
    if cur == S.funnelRoom then
      S._enterFunnel()
      return true
    elseif cur ~= S.swarmRoom then
      S.reset("lost mid-pull")
      return false
    end
    return true -- still in the swarm room, chain pending -- hold navigation
  end

  if S.state == "funnel" then
    if cur ~= S.funnelRoom then S.reset("left the funnel room"); return false end
    if M._roomHasDenizens and M._roomHasDenizens() then
      local n = (M._denizenCount and M._denizenCount()) or 0
      if n > (S.peakFollowers or 0) then S.peakFollowers = n end
      local s = S._cfg()
      if n >= S.threshold() and s.kite and not S.flying and S._canFly()
         and S.mode ~= "wall" and not S._indoors() then
        -- The swarm followed us outdoors: fly-kite. The decorator turns every attack
        -- into land;<attack>;fly -- we touch ground only for the swing.
        S.flying = true
        local sep = (ataxia.settings and ataxia.settings.separator) or ";"
        send("queue addclear free stand" .. sep .. "fly")
        S._echo("<indian_red>the swarm followed (" .. n .. ")<reset> outdoors -- <cyan>FLY-KITE<reset> (land/hit/fly each balance).")
      elseif S.flying and n < S.threshold() then
        -- Thinned out: come down and finish the stragglers grounded.
        S.flying = nil
        send("land")
        S._echo("thinned to " .. n .. " -- landing to finish them.")
      elseif not S.announcedFollow then
        if n >= S.threshold() then
          S._echo("<indian_red>the swarm followed (" .. n .. ")<reset> -- "
            .. (S.mode == "wall" and "holding behind the wall" or "holding this room") .. ".")
        else
          S._echo(n .. " follower(s) -- basher on them.")
        end
      end
      S.announcedFollow = true
      S.funnelAt = now() -- fighting counts as activity; window restarts after the kill
      return true
    end
    local window = (S.mode == "wall") and WALL_WINDOW or FOLLOW_WINDOW
    local remain = (S.funnelAt or 0) + window - now()
    if remain > 0 then
      if M._scheduleTick then M._scheduleTick(remain + 0.1) end
      return true
    end
    return S._beginReenter()
  end

  if S.state == "reenter" then
    if cur == S.swarmRoom then
      S.state = "idle" -- fall through to a fresh assess of the (changed) room
    elseif cur ~= S.funnelRoom then
      S.reset("lost mid-reenter")
      return false
    else
      return true -- move pending / retrying
    end
  end

  -- idle: assess the room we're standing in
  if not (M._roomHasDenizens and M._roomHasDenizens()) then
    -- Room done. If our icewall from the wall tactic still stands on the funnel
    -- edge, melt it before handing the tick back -- an intact wall makes every
    -- later plain walk on that edge fail (the 008 wall-leap reflex recovers, but
    -- a melted edge walks free). Hardened per review: the melt is balance-gated
    -- and sits in the free queue for a round, so (a) HOLD attack dispatch (a
    -- roamer's arrival would addclearfull the melt away), (b) clear the memory
    -- only on CONFIRMATION (trigger 026 -> onWallMelted) -- a wiped/whiffed melt
    -- re-sends on the next empty assess -- and (c) bound the retries: after 4,
    -- leave the wall to the leap reflex. Consume the tick each attempt so the
    -- explorer's own `queue addclear free` move cannot wipe the queued melt.
    if cur and S.wallRaised and S.wallRaised[cur] then
      S._meltTries = (S._meltRoom == cur) and ((S._meltTries or 0) + 1) or 1
      S._meltRoom = cur
      if S._meltTries > 4 then
        S.wallRaised[cur] = nil
        S._meltRoom, S._meltTries = nil, nil
        S._echo("<grey>wall didn't melt after 4 tries -- leaving it (walks will leap it).")
        return false
      end
      ataxiaTemp.swarmHold = true
      if S._holdT then pcall(killTimer, S._holdT) end
      S._holdT = tempTimer(4, function() S._holdT = nil; ataxiaTemp.swarmHold = nil end)
      local s = S._cfg()
      send("queue addclear free point " .. s.meltId .. " at icewall")
      if M._scheduleTick then M._scheduleTick(2) end
      if S._meltTries == 1 then
        S._echo("room done -- melting our wall so the sweep can walk that edge again.")
      end
      return true
    end
    return false
  end
  if cur and S.noTactics[cur] then return false end
  local n = (M._denizenCount and M._denizenCount()) or 0
  if n < S.threshold() then return false end
  -- Hit-and-run continuation (user doctrine, Putoran-wildcat log 2026-07-26: nothing
  -- follows, so each cycle is one safe swing -- "continue hit and run until the room
  -- is cleared or below 3 denizens"). A re-entry showing PROGRESS since the last pull
  -- -- fewer denizens (a kill), or the SAME focused target chipped lower -- REFUNDS
  -- the pull budget: the loop is working, keep cycling. Only unproductive cycles
  -- (nothing died, no chip -- e.g. a soldier "tending his wounds" back to full while
  -- we funnel) spend budget, so a true stalemate still caps and fights in place.
  local snap = cur and S.entrySnap[cur]
  if snap and (S.pulls[cur] or 0) > 0 then
    local id, hp = S._targetHp()
    local chipped = id and hp and snap.id == id and snap.hp and hp < snap.hp
    if n < snap.n or chipped then
      S.pulls[cur] = 0
      S._echo("progress since last pull ("
        .. (n < snap.n and (snap.n .. "->" .. n .. " denizens") or ("target " .. snap.hp .. "%->" .. hp .. "%"))
        .. ") -- <green>hit-and-run continues<reset>.")
    end
  end
  local shortBack, longBack, shortFwd = S._backDir()
  if not shortBack then
    -- No valid pull route (first grid room, stale fromDir): fight in place.
    if cur and not S.noTactics[cur] then
      S.noTactics[cur] = true
      S._echo(n .. " denizens but <grey>no valid pull route<reset> -- fighting in place.")
    end
    return false
  end
  -- Route by terrain (user-confirmed flow): INDOORS -> wall the door we came through
  -- and leap it (fly is unavailable inside); OUTDOORS -> plain pull, and if the swarm
  -- chases, the funnel branch escalates to the fly-kite.
  --
  -- ROLL HIDE OUTRANKS THE ICEWALL (v4.7.223, user: "if we have roll hide boon, we dont need
  -- to icewall, just tumble out"). The wall was never a barrier -- denizens walk through
  -- icewalls without Maklak's Promise, so it only ever PACED the swarm -- and it costs a
  -- balance-gated `point <bracers>`, a wall-memory entry, and a melt cycle when the room
  -- empties. The boon sheds every pursuer outright, which is strictly better than pacing them
  -- and free of all three costs. So when it is up we take the plain pull and tumble out of it.
  local mode = (S._indoors() and S._cfg().icewall and not mnemRollHide) and "wall" or "pull"
  return S._beginPull(shortBack, longBack, shortFwd, n, mode)
end

-- Vitals-driven emergency wake-up. The explorer tick is EVENT-driven (arrivals,
-- target-list changes, a 30s watchdog): a stationary slugfest generates almost none,
-- and the Pinnacle death crossed the escape threshold and died between ticks -- the
-- single evaluation in the final seconds landed on a potash heal bounce. This runs
-- on every prompt instead, and unlike the tick path it acts even while a pull is in
-- flight (the explorer `moving` guard blinded the old path for the pull's full 8s).
function S.onVitals()
  if S.state == "recovering" then return end -- the hover loop owns it (self-ticking)
  if not S._enabled() then return end
  local s = S._cfg()
  local hp = hppFresh()
  if hp <= 0 then return end -- blackout sentinel: vitals unknown, never "dying"
  local wantPanic = s.panic ~= false and mnemRollHide and S._panicHpHit(hp)
  local wantEscape = s.escape ~= false and hp <= s.escapeAt
  if not (wantPanic or wantEscape) then return end
  if S._lastEmergencyAt and (now() - S._lastEmergencyAt) < EMERGENCY_COOLDOWN then return end
  S._lastEmergencyAt = now()
  if wantPanic and S._maybePanic(hp) then
    if M._disarmMove then M._disarmMove() end -- a stale in-flight move must not gate the aftermath
    return
  end
  if not wantEscape then return end
  if M._disarmMove then M._disarmMove() end -- an in-flight pull dies with the escape's reset
  if S.flying then return S._convertToHover(hp) end
  if S.state ~= "idle" then S.reset("low-hp escape") end
  S._beginEscape()
end

-- The explorer's tactical-move timeout gave up (arrival never came).
function S.onMoveFailed()
  S._clearHold()
  if S.state == "pulling" then
    -- The step-out was eaten (the Pinnacle death: razer stupidity replaces queued
    -- commands with involuntary actions) but the route is still GOOD -- we never
    -- left. _tacticalArm clobbered explore.fromRoom/fromDir with the pull itself,
    -- so without this restore the reassess finds "no valid pull route" and latches
    -- noTactics on exactly the room that most needs tactics. _backDir re-validates
    -- the restored anchor against the exit graph, and MAX_PULLS bounds the retries.
    if M.explore and S.funnelRoom and S.fwdShort
       and M.map and M.map.current == S.swarmRoom then
      M.explore.fromRoom = S.funnelRoom
      M.explore.fromDir = S.fwdShort
    end
    -- RETRY, do not just reassess (v4.7.235). Going idle here relies on the next tick
    -- re-deciding, and the explorer tick is EVENT-driven -- in a stationary slugfest almost
    -- nothing fires it. Against Seasone that gap was FOURTEEN SECONDS between the lost move
    -- and the next escape attempt, by which point both legs were broken and every action was
    -- refused. Re-send immediately, bounded, with the hold re-armed so the same attack
    -- dispatch cannot eat the retry the way it ate the original.
    local tries = (tonumber(S._pullRetries) or 0) + 1
    if tries <= (tonumber(S.PULL_RETRIES) or 2) and S.backShort and M._tacticalArm then
      S._pullRetries = tries
      S._armRecoverHold()
      S._tacticalGo(S.backShort, "<indian_red>pull move lost<reset> -- retry " .. tries)
      return
    end
    S._pullRetries = nil
    S._echo("<grey>pull move lost -- reassessing.")
    S.state = "idle"
  elseif S.state == "reenter" then
    S._echo("<grey>re-entry move lost -- reassessing.")
    S.state = "idle"
  end
end

-- Fed by trigger 022_Flight_Lines: the last CONFIRMED physical airborne state.
-- Distinct from S.flying, the tactic's mode flag -- kiting keeps S.flying true
-- across the per-swing land/fly churn while this flag flaps with the actual game
-- lines. Only the recovery hover's fly re-send consumes it.
-- "A tentacle shoots up from the ground, wraps itself around you, and drags you back
-- to earth." A denizen on THIS RIPPLE can pull us out of the air, which makes the
-- whole airborne branch of the escape ladder a liability: the recovery hover would
-- keep re-sending `fly` every tick (S.flying stays optimistically true until the
-- flight line confirms, and it never will), holding us attack-GATED at crash HP with
-- the denizens still on us. That is strictly worse than never having flown.
--
-- So: latch grounded for the rest of the ripple (S.onRipple clears it), correct the
-- flight state, and if a hover is in progress convert it to the grounded retreat
-- rather than leaving it to spin until RECOVER_MAX.
function S.onDraggedDown()
  if not (ataxiaBasher and ataxiaBasher.inMnemosyne) then return end
  local wasHovering = (S.state == "recovering")
  S.flying = nil
  S.flightConfirmed = nil
  if not S.grounded then
    S.grounded = true
    S._echo("<red>Dragged out of the air<reset> -- no flying on this ripple; escapes go grounded.")
  end
  if wasHovering then
    -- We are on the ground, at low HP, gated. Release the hold and re-run the ladder,
    -- which now takes the retreat branch (or the shield fallback with no route).
    S.state = "idle"
    S._clearHold()
    S._beginEscape()
  end
end

function S.onFlightUp() S.flightConfirmed = true end
function S.onFlightDown() S.flightConfirmed = nil end

-- "You send a lash of fire to strike the icewall to the <dir>, and it quickly
-- melts." (trigger 026): a melt LANDED in this room -- ours or a manual one;
-- either way the wall here is gone, so the memory clears (this is the only
-- non-boundary clear: the melt branch above re-sends until this confirms).
function S.onWallMelted()
  local cur = M.map and M.map.current
  if cur and S.wallRaised then S.wallRaised[cur] = nil end
  S._meltRoom, S._meltTries = nil, nil
  -- Release the melt hold -- but never a hold that belongs to a live tactic
  -- (a manual melt mid-pull must not expose the queued chain to a wipe).
  if S.state == "idle" then S._clearHold() end
end

-- Single teardown. Ripple boundaries are covered by the boon screen (every ripple
-- ends there) + run start; death/leave-tower via _exploreStop; reloads via
-- sysLoadEvent; manual `bash` toggle via the "basher disabled" event.
function S.reset(reason)
  local wasActive = S.state ~= "idle"
  if S._pullFallbackT then pcall(killTimer, S._pullFallbackT); S._pullFallbackT = nil end
  S._clearHold()
  ataxiaTemp.swarmPullDir = nil
  if S.flying then
    send("land") -- never carry flight into a boon screen / wade / the next context
    S.flying = nil
  end
  S.flightConfirmed = nil
  if wasActive then
    send("cq all") -- a queued pull chain must not fire into the new context
    S._echo("<grey>reset" .. (reason and (" (" .. reason .. ")") or "") .. ".")
  end
  S.state = "idle"
  S.mode = nil
  S.recoverGround = nil
  S.recoverDiagnosed = nil
  S._pullRetries = nil
  if S.onTumbleDone then S.onTumbleDone() end
  S.swarmRoom, S.funnelRoom, S.funnelAt = nil, nil, nil
  S.backShort, S.backLong, S.fwdShort = nil, nil, nil
  S.peakFollowers, S.announcedFollow = nil, nil
end

-- Fresh ripple / sweep (re)start: new pull budgets. Called both at GENUINE ripple
-- boundaries (GO resume, ripple line) and on a mid-ripple `mnem explore on`
-- restart -- budgets refresh either way, but WALLS ARE PHYSICAL: wipe the wall
-- memory only when the layout actually changed (review catch: a mid-ripple
-- restart wiped `wallRaised` while the wall still stood, so it could never be
-- melted and the sweep walked into it). If the ripple counter is stale the wipe
-- is skipped -- safe: stale memory degrades to leap-only escapes and a bounded
-- melt whiff, both harmless.
function S.onRipple()
  S.pulls = {}
  S.noTactics = {}
  S.entrySnap = {}
  S.grounded = nil -- the denizen that dragged us down is left behind with its ripple
  local ripple = (M.run and tonumber(M.run.ripple)) or 0
  if S._wallsRipple ~= ripple then
    S.wallRaised = {}
    S._wallsRipple = ripple
  end
  S.reset("new ripple")
end

-- ---------------------------------------------------------------------------
-- Sleuth recon (fullsense)
-- ---------------------------------------------------------------------------

-- Capture a fullsense block raw. Format is being learned from live logs -- until
-- the parser lands, the value is the echo + the stored lines (mnem swarm status).
function S.sense(why)
  if not (M._captureLines and send) then return end
  send("fullsense")
  M._captureLines({
    timeout = SENSE_TIMEOUT,
    onDone = function(lines)
      S.recon = { at = now(), ripple = (M.run and M.run.ripple) or 0, lines = lines }
      S._echo("fullsense captured <cyan>" .. #lines .. "<reset> raw line(s)"
        .. (why and (" (" .. why .. ")") or "") .. " -- stored unparsed (the parser learns from your logs).")
    end,
  })
end

-- ---------------------------------------------------------------------------
-- Bloodscent recon ("You sense out your prey upon entering a ripple.")
-- The boon prints, unprompted on every ripple entry:
--   You sense out the location of your prey...
--   You sense a shadowy basilisk (#371988) at Beneath an ancient tree.
--   ... (one row per denizen in the ripple)
-- Trigger 028 feeds the rows here; a short quiet-window commits the batch into
-- S.recon as PARSED data ({name,id,room} + per-room counts) -- the format the
-- Sleuth raw capture was waiting on. Self-gated on the tower (the "You sense"
-- shape could exist elsewhere).
-- ---------------------------------------------------------------------------
function S.onSenseStart()
  if not (ataxiaBasher and ataxiaBasher.inMnemosyne) then return end
  S._senseRows = {}
end

function S.onSenseRow(name, id, room)
  if not (ataxiaBasher and ataxiaBasher.inMnemosyne) then return end
  S._senseRows = S._senseRows or {}
  S._senseRows[#S._senseRows + 1] = { name = name, id = tostring(id), room = room }
  if S._senseT then pcall(killTimer, S._senseT) end
  S._senseT = tempTimer(1.5, function()
    S._senseT = nil
    S._senseCommit()
  end)
end

-- Commit the batch (quiet window elapsed). Pure aside from the echo; unit-tested.
function S._senseCommit()
  local rows = S._senseRows
  S._senseRows = nil
  if not rows or #rows == 0 then return end
  local byRoom, order = {}, {}
  for _, r in ipairs(rows) do
    if not byRoom[r.room] then byRoom[r.room] = 0; order[#order + 1] = r.room end
    byRoom[r.room] = byRoom[r.room] + 1
  end
  S.recon = {
    at = now(),
    ripple = (M.run and M.run.ripple) or 0,
    mobs = rows, byRoom = byRoom, rooms = order,
  }
  local thr = S.threshold()
  local hot = {}
  for _, room in ipairs(order) do
    if byRoom[room] >= thr then hot[#hot + 1] = room .. " (" .. byRoom[room] .. ")" end
  end
  S._echo("recon: <yellow>" .. #rows .. "<reset> denizens across <yellow>" .. #order
    .. "<reset> rooms" .. (#hot > 0
      and (" -- <indian_red>crowded:<reset> " .. table.concat(hot, ", "))
      or " -- <green>no crowded rooms<reset>") .. ".")
end

-- GO = a new wave. With the Sleuth boon up, recon the ripple before the sweep gets deep.
-- Delayed past the GO burst: onGo's `wade status` (whose effects block runs its own
-- _captureLines) and the explorer's `look` must finish first -- a concurrent capture
-- force-finishes ours and recon would store the wade-status block labeled as fullsense.
-- Returns whether a recon was scheduled (pure gating -- unit-tested).
function S.onGo()
  if not (mnemSleuth and S._cfg().enabled) then return false end
  if not (ataxiaBasher and ataxiaBasher.inMnemosyne) then return false end
  tempTimer(SENSE_DELAY, function() S.sense("Sleuth, on GO") end)
  return true
end

function S.status()
  local s = S._cfg()
  local thr = S.threshold()
  M.echo("<gold>[swarm]<reset> " .. (s.enabled and "<green>ON" or "<grey>off")
    .. "<reset> state=" .. tostring(S.state) .. (S.mode and ("/" .. S.mode) or "")
    .. (S.flying and " <cyan>FLYING<reset>" or "")
    .. " threshold=" .. tostring(thr)
    .. (s.deepAt and (" (deep: >=r" .. tostring(s.deepAt) .. " -> " .. tostring(s.deepThreshold) .. ")") or "")
    .. " icewall=" .. tostring(s.icewall) .. " kite=" .. tostring(s.kite)
    .. " panic=" .. tostring(s.panic) .. "@" .. tostring(s.panicAt) .. "%"
    .. ((tonumber(s.panicHp) or 0) > 0 and ("/" .. tostring(s.panicHp) .. "hp") or "")
    .. " escape=" .. tostring(s.escape) .. "@" .. tostring(s.escapeAt) .. "%->" .. tostring(s.recoverAt) .. "%"
    .. " hold=" .. tostring(ataxiaTemp.swarmHold or false)
    .. " recon=" .. (S.recon and (
      (S.recon.mobs and (#S.recon.mobs .. " mobs/" .. #(S.recon.rooms or {}) .. " rooms")
        or (#(S.recon.lines or {}) .. " raw lines"))
      .. " @r" .. tostring(S.recon.ripple)) or "none"))
end

-- Every prompt: the emergency escape/panic check (see S.onVitals). Cheap fast paths
-- out; guarded by _enabled so it is inert outside an exploring tower run.
if S._vitalsH then pcall(killAnonymousEventHandler, S._vitalsH) end
S._vitalsH = registerAnonymousEventHandler("gmcp.Char.Vitals", function() pcall(S.onVitals) end)

-- Manual `bash` toggle mid-tactic: the basher going away invalidates everything.
if S._bashOffH then pcall(killAnonymousEventHandler, S._bashOffH) end
S._bashOffH = registerAnonymousEventHandler("basher disabled", function()
  if S.state ~= "idle" then S.reset("basher disabled") end
end)

-- Reload: timers are gone; state must not survive half-alive.
if S._loadH then pcall(killAnonymousEventHandler, S._loadH) end
S._loadH = registerAnonymousEventHandler("sysLoadEvent", function()
  S.state = "idle"
  S.pulls, S.noTactics = {}, {}
  ataxiaTemp.swarmHold = nil
  ataxiaTemp.swarmPullDir = nil
end)
