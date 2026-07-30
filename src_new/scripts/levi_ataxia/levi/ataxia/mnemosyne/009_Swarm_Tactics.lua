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
  s.panicAt = tonumber(s.panicAt) or 40         -- HP% that triggers the panic tumble
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
function S._afflicted()
  local a = ataxia and ataxia.afflictions
  if type(a) ~= "table" then return false end
  for k, v in pairs(a) do
    if not AFF_IGNORE[k] then
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
  if s.deepAt and s.deepThreshold and ripple >= tonumber(s.deepAt) then
    return tonumber(s.deepThreshold)
  end
  return s.threshold
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
function S._tacticalGo(dirShort, why)
  if not (M._tacticalArm and dirShort) then return S.reset("no tactical mover") end
  M._tacticalArm(dirShort)
  local sep = (ataxia.settings and ataxia.settings.separator) or ";"
  -- LEAP, never walk (review CRITICAL): a tactical retreat can cross our OWN
  -- standing icewall -- the indoor low-HP escape retreats through the walled
  -- funnel edge, where a plain walk silently fails and the anti-death ladder
  -- livelocks at crash HP. A chitin-greaves leap clears any wall (ours or an
  -- affix's) and is plain movement when there is none. Eq-gated; the tactical
  -- timeout still hands back to assess if the jump never lands.
  send("queue addclear free stand" .. sep .. "leap " .. dirShort)
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
-- pursuers. Direction: any planar exit of the funnel room that is NOT back toward
-- the swarm room (falls back to the swarm-room direction if it's the only exit --
-- still better than dying in place).
function S._panicDir()
  local MAP = M.map
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

function S._maybePanic(hpNow)
  local hp = tonumber(hpNow) or hpp()
  local s = S._cfg()
  if s.panic == false or not mnemRollHide then return false end
  if hp > s.panicAt then return false end
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
  S._echo("<indian_red>PANIC (" .. hp .. "% hp)<reset> -- Roll Hide tumble <cyan>" .. dir .. "<reset> sheds all pursuers.")
  return true
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

function S._beginEscape()
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
  S._tacticalGo(shortBack, "<indian_red>LOW HP (" .. hpp() .. "%)<reset> -- retreating to recover")
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
    local healed = hpp() >= s.recoverAt and not S._afflicted()
    if healed or (now() - (S.recoverStarted or 0)) > RECOVER_MAX then
      S.flying = nil
      send("land")
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
  local mode = (S._indoors() and S._cfg().icewall) and "wall" or "pull"
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
  local wantPanic = s.panic ~= false and mnemRollHide and hp <= s.panicAt
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
