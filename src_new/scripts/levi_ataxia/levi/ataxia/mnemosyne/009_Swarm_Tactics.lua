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

local FOLLOW_WINDOW = 4     -- seconds to wait in the funnel room for followers
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

-- Reload-safety: ataxiaTemp persists across a SYSUPDATE reload; a stranded hold or
-- armed decorator would silently gate the whole basher / decorate a random attack.
ataxiaTemp = ataxiaTemp or {}
ataxiaTemp.swarmHold = nil
ataxiaTemp.swarmPullDir = nil

S.state = "idle" -- idle | pulling | funnel | reenter
S.pulls = S.pulls or {}       -- [roomNum] = pull count this ripple
S.noTactics = S.noTactics or {} -- [roomNum] = true -> fight in place (gave up)
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
  send("queue addclear free stand" .. sep .. dirShort)
  if why then S._echo(why .. " -> <cyan>" .. dirShort .. "<reset>.") end
end

-- The escape suffix appended to the decorated attack, by mode:
--   pull:  ";<backdir>"                          -- plain step out
--   wall:  ";point <bracers> <LONG back>;leap <back>" -- raise the icewall on the exit
--          we came through, then LEAP over our own wall (chitin greaves; the manual
--          ragepull alias proves leap-over-own-wall works). One queue entry keeps the
--          order: swing -> wall -> leap, all on the same balance.
function S._escapeSuffix(sep)
  local s = S._cfg()
  if S.mode == "wall" then
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
    -- Our own icewall may still block the way back: melt it first (Bracers of Flame --
    -- the fli alias shape), then walk. If the wall already broke, the melt is a harmless
    -- miss and the walk proceeds; if the WALK still fails, the tactical-move timeout
    -- hands us back to assess without condemning the edge.
    if not (M._tacticalArm and S.fwdShort) then return S.reset("no tactical mover") end
    M._tacticalArm(S.fwdShort)
    local sep = (ataxia.settings and ataxia.settings.separator) or ";"
    local s = S._cfg()
    send("queue addclear free point " .. s.meltId .. " at icewall" .. sep .. "stand" .. sep .. S.fwdShort)
    S._echo("trickle over (peak followers: " .. followers .. ") -- melting our wall and re-entering -> <cyan>" .. S.fwdShort .. "<reset>.")
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
  local fallback
  for d in pairs(room.exits) do
    if MAP.OFFSETS and MAP.OFFSETS[d] then
      if d ~= fwd then return MAP.shortDir(d) end
      fallback = MAP.shortDir(d)
    end
  end
  return fallback
end

function S._maybePanic()
  local s = S._cfg()
  if s.panic == false or not mnemRollHide then return false end
  if hpp() > s.panicAt then return false end
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
  S._echo("<indian_red>PANIC (" .. hpp() .. "% hp)<reset> -- Roll Hide tumble <cyan>" .. dir .. "<reset> sheds all pursuers.")
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
function S._beginEscape()
  local s = S._cfg()
  if not S._indoors() then
    S.state = "recovering"
    S.recoverStarted = now()
    S.flying = true
    local sep = (ataxia.settings and ataxia.settings.separator) or ";"
    send("queue addclear free stand" .. sep .. "fly")
    S._armRecoverHold()
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
      return false -- normal flow (fight/assess) resumes this very tick
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
        S.state = "recovering"
        S.recoverStarted = now()
        S._armRecoverHold()
        S._echo("<indian_red>LOW HP (" .. hpp() .. "%)<reset> -- staying airborne to recover.")
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
      if n >= S.threshold() and s.kite and not S.flying
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
  if not (M._roomHasDenizens and M._roomHasDenizens()) then return false end
  if cur and S.noTactics[cur] then return false end
  local n = (M._denizenCount and M._denizenCount()) or 0
  if n < S.threshold() then return false end
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

-- The explorer's tactical-move timeout gave up (arrival never came).
function S.onMoveFailed()
  S._clearHold()
  if S.state == "pulling" then
    S._echo("<grey>pull move lost -- reassessing.")
    S.state = "idle"
  elseif S.state == "reenter" then
    S._echo("<grey>re-entry move lost -- reassessing.")
    S.state = "idle"
  end
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

-- Fresh ripple: new layout, new pull budgets.
function S.onRipple()
  S.pulls = {}
  S.noTactics = {}
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
    .. " recon=" .. (S.recon and (#(S.recon.lines or {}) .. " lines @r" .. tostring(S.recon.ripple)) or "none"))
end

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
