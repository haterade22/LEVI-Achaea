--[[mudlet
type: script
name: Magi Kite
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
    THE MAGI KITE (v4.7.530): cast, step out, come back
    ============================================================================
    User, 2026-11-27: "Cooldown Abilities via Boons > Stormhammer if not in danger (health) > Run if
    in danger (health) > hit and run with stormhammer". Hit and run is "Cast, step out, return":
    cast, step to a near room, come back when equilibrium is up, cast again. Danger is the escape
    line the tower retreat already uses (`mnem swarm escapeat`, S._cfg().escapeAt, default 35%).
    And: "stormhammer only for denizens 3 plus, not 1 or 2. Staffcast is better usage there."

    WHO: a Magi (gmcp class), in the tower (ataxiaBasher.inMnemosyne), with the swarm module able to
    move (S._enabled: explorer on, basher on, manual movement). Nobody else: every entry point asks
    K.wanted first, and for any other class or outside the tower the kite answers no and changes
    nothing (test_magi_tower_kite.lua proves both).

    THE CYCLE, one phase at a time, state on ataxiaTemp.magiKite (session state: never saved):
      cast  in the fight room. The basher's round carries the kite's hit (basher/002
            ataxiaBasher_magiKiteHit: stormhammer at 3 when 3+ denizens and the mana allow it,
            else `staff cast horripilation`). Attacks are NOT held.
      out   the game's CAST LINE came (K.onCast, triggers magi_offense_tracking/022 and 023): the
            step to a near cleared room is queued as one entry (S._queueMove, alias lvmove), the
            queue is cleared first, and ataxiaTemp.magiKiteHold holds the attack dispatcher
            (basher/001) so the next round's `queue addclearfull` cannot delete the step. Movement
            waits for equilibrium ("You are recovering equilibrium and cannot move yet.",
            kb/mechanics/balance-and-queueing.md), so the step goes when the cast's equilibrium is
            back, not at once.
      away  landed. After K.SETTLE (the denizen list lags the room change) a room with denizens in
            it is the new fight room (they followed: the user's rule, hit them there the same way).
            An empty one: if going back is safe (K.healthPermits), step back in, held the same way.
      back  landed in the fight room again: the cast phase.
    The step-out is stamped on the game's line, never when the round is built or the key is pressed
    (.claude/AGENTS.md, "Stamp on the confirmation line").

    THE END: in the cast phase, health back to `returnAt` (85%) and cured (S._mayReturn) -- the bar
    the U-turn rule and the ground recovery use for going back into a room we fled, and the kite
    goes back into its fight room every cycle. One definition, not a second opinion that drifts.

    WHAT IT REPLACES AND WHAT IT OBEYS (the full table: .claude/projects/mnemosyne/08-magi-kite.md):
      * the one-retreat rule (v4.7.482) and the U-turn rule: the kite's steps are neither read nor
        spent as retreats. It leaves and re-enters the SAME fight, which is what "kill what is in
        this room" wanted; the ping-pong between two fights that rule stopped is stopped here by
        K.FOLLOW_MAX.
      * it does not start (K.wanted) on Prey, pursuit (S._pursued), a boon that sheds pursuers (the
        panic tumble owns that), a lethal hit here (the ladder leaves without a cast), lava, a
        recovery, a tumble or escape in flight, or a last stand already holding.
      * it stops (K.stop, with the reason echoed) on: no cleared room next door, a step that never
        happened, the denizens following K.FOLLOW_MAX steps in a row, a lethal hit in the cast phase,
        going back being unsafe (then the ground recovery heals here, S._recoverHere), the fight
        room clear, the cast line not seen K.MISS_MAX times, the tower left, the swarm off.
        A stop that is a failure leaves the room to the ladder for K.COOL seconds.
    ============================================================================
]]--

ataxia.mnemosyne = ataxia.mnemosyne or {}
local M = ataxia.mnemosyne
M.magiKite = M.magiKite or {}
local K = M.magiKite

K.SETTLE = 1.5     -- seconds after a move before the denizen list is the new room's (S.PURSUIT_SETTLE)
K.MOVE_MAX = 12    -- a step not landed this long after it was queued is lost: stormhammer's 6.00 s BASE
                   -- equilibrium, then the move, with room to spare (S.MOVE_WATCH_MAX is the same 12)
K.CAST_GRACE = 1.0 -- our equilibrium went in the cast phase; the cast line must come within this
K.MISS_MAX = 2     -- equilibrium spent this many times in a row with no cast line: the kite stops
K.FOLLOW_MAX = 2   -- steps in a row that the denizens followed: the kite stops and we fight there
K.COOL = 10        -- after a failure stop, the ladder has the room for this long
K.HIT_MEMORY = 30  -- the lethal-hit window (S.LETHAL_HIT_MEMORY)
K.TICK = 0.5       -- the kite's own clock while it runs (a quiet room sends no prompts)
K.AWAY_MAX = 20    -- seconds we may wait in the near room for balance and equilibrium before healing there

ataxiaTemp = ataxiaTemp or {}
-- Reload-safety: timers do not survive a reload, so no kite does either.
if ataxiaTemp.magiKiteT then pcall(killTimer, ataxiaTemp.magiKiteT) end
ataxiaTemp.magiKite, ataxiaTemp.magiKiteT, ataxiaTemp.magiKiteHold = nil, nil, nil

local function now() return (getEpoch and getEpoch()) or os.time() end
local function st() return ataxiaTemp and ataxiaTemp.magiKite end
local function S() return M.swarm end
local function cur() return M.map and M.map.current end

local function echo(msg)
  local sw = S()
  if sw and sw._echo then sw._echo("<orchid>[kite]<reset> " .. tostring(msg))
  elseif ataxiaEcho then ataxiaEcho("[kite] " .. tostring(msg)) end
end

-- One line per reason, at most every 5 s: these run on every prompt.
local function sayOnce(key, msg)
  local t = now()
  if ataxiaTemp.magiKiteSaid == key and (t - (tonumber(ataxiaTemp.magiKiteSaidAt) or 0)) < 5 then return end
  ataxiaTemp.magiKiteSaid, ataxiaTemp.magiKiteSaidAt = key, t
  echo(msg)
end

local function hpNow(hp)
  return tonumber(hp) or (ataxia_effHpp and ataxia_effHpp())
    or tonumber(ataxia and ataxia.vitals and ataxia.vitals.hpp) or 100
end

local function denizens()
  if ataxiaBasher_magiRoomIds then return #ataxiaBasher_magiRoomIds() end
  return (M._denizenCount and M._denizenCount()) or 0
end

local function isMagi()
  local c = gmcp and gmcp.Char and gmcp.Char.Status and gmcp.Char.Status.class
  return type(c) == "string" and c:lower():find("magi", 1, true) == 1
end

function K.enabled()
  local sw = S()
  local c = sw and sw._cfg and sw._cfg()
  return not (c and c.magiKite == false)
end

function K.active() return st() ~= nil end

-- The cast phase, in the fight room: the round carries the kite's hit (basher/002).
function K.castReady()
  local k = st()
  if not k then return false, "no kite" end
  if k.phase ~= "cast" then return false, "the kite is " .. tostring(k.phase) end
  if cur() ~= k.fight then return false, "not in the fight room" end
  return true
end

-- ---------------------------------------------------------------------------
-- Where to step: a CLEARED room next door (S._exitRank 1: visited, not just fled, not the swarm
-- room), never lava, never our own standing icewall, planar only. The room we came in by first
-- (S._backDir, the walked edge), then the rest in sorted order, so a room picks the same door each
-- time. An unexplored room is refused: the kite goes there every cycle, and it can hold anything.
-- ---------------------------------------------------------------------------
function K.outDir()
  local sw, MAP = S(), M.map
  local here = cur()
  if not (sw and MAP and here) then return nil, "no map" end
  local room = MAP.rooms and MAP.rooms[here]
  if not (room and room.exits) then return nil, "this room's exits are not known" end
  local walled = sw.wallRaised and sw.wallRaised[here]
  walled = (type(walled) == "string" and MAP.normDir and MAP.normDir(walled)) or nil
  local function ok(short)
    local long = short and MAP.normDir and MAP.normDir(short)
    if not long or long == walled then return false end
    if not (MAP.OFFSETS and MAP.OFFSETS[long]) then return false end
    if M.edgeIsLava and M.edgeIsLava(here, long) then return false end
    return sw._exitRank and sw._exitRank(short) == 1
  end
  local back = sw._backDir and select(1, sw._backDir())
  if back and ok(back) then return back end
  local dirs = {}
  for d in pairs(room.exits) do dirs[#dirs + 1] = d end
  table.sort(dirs)
  for _, d in ipairs(dirs) do
    local short = MAP.shortDir and MAP.shortDir(d) or d
    if ok(short) then return short end
  end
  return nil, "no cleared room next door"
end

-- Is going back into the fight room safe? Not dying fast (the damage watchdog, or raw health at the
-- panic floor), and no single attack of the last K.HIT_MEMORY seconds as big as our health (the
-- lethal rule of v4.7.514, read for any room: the fight room is where those hits were taken).
function K.healthPermits()
  local sw = S()
  if sw and sw._dyingFast and sw._dyingFast() then return false, "dying fast (damage rate or the panic floor)" end
  if ataxiaBasher_biggestHitHere then
    local big = ataxiaBasher_biggestHitHere(K.HIT_MEMORY, true)
    local hp = (ataxiaBasher_safeHp and ataxiaBasher_safeHp()) or tonumber(ataxia.vitals and ataxia.vitals.hp)
    if big and hp and hp > 0 and big >= hp then
      return false, "one hit in there took " .. big .. " and we have " .. hp
    end
  end
  return true
end

-- ---------------------------------------------------------------------------
-- Should a kite start now? Side-effect-free. Returns true, or false, the reason and whether the
-- reason is worth saying (a context gate that is false for every other class, or above the line,
-- is not news on every prompt; it is kept in ataxiaTemp.magiKiteWhyNot for `mnem swarm magikite`).
-- ---------------------------------------------------------------------------
function K.wanted(hp)
  local sw = S()
  if not isMagi() then return false, "not a Magi" end
  if not (ataxiaBasher and ataxiaBasher.inMnemosyne) then return false, "not in the tower" end
  if not sw then return false, "the swarm module is not loaded" end
  if not K.enabled() then return false, "the kite is off (mnem swarm magikite on)" end
  local s = sw._cfg()
  hp = hpNow(hp)
  if hp <= 0 then return false, "health unknown" end
  if hp > (tonumber(s.escapeAt) or 35) then
    return false, "health " .. hp .. "% is above the escape line " .. (tonumber(s.escapeAt) or 35) .. "%"
  end
  if not sw._enabled() then return false, (sw._enabledWhyNot and sw._enabledWhyNot()) or "swarm tactics are off", true end
  local cool = tonumber(ataxiaTemp.magiKiteCoolUntil)
  if cool and now() < cool then
    return false, "the kite stopped (" .. tostring(ataxiaTemp.magiKiteCoolWhy) .. "); the ladder has the room for "
      .. string.format("%.0f", cool - now()) .. "s", true
  end
  if sw.state == "recovering" then return false, "a recovery owns it", true end
  if sw.moveLocked and sw.moveLocked() then return false, "a tumble is in flight", true end
  if sw._escapeOwns and sw._escapeOwns() then return false, "an escape is under way", true end
  if ataxiaBasher_lastStandHolding and ataxiaBasher_lastStandHolding() then return false, "a last stand holds", true end
  if M.roomLava and M.roomLava() then return false, "standing in lava: the lava escape owns the move", true end
  if sw._shedsPursuers and sw._shedsPursuers() then
    return false, "a boon sheds pursuers (Roll Hide / Terror): leaving ends the fight, so the panic and the ladder own it", true
  end
  if sw._preyTracks and sw._preyTracks() then return false, "Prey: every denizen tracks a step out", true end
  if sw._pursued and sw._pursued() then return false, "the swarm follows every retreat", true end
  local lethal, lwhy = false, nil
  if sw._lethalHit then lethal, lwhy = sw._lethalHit() end
  if lethal then return false, "LETHAL: " .. tostring(lwhy) .. " -- no cast here, the ladder leaves now", true end
  if denizens() == 0 then return false, "no denizen here", true end
  local dir, dwhy = K.outDir()
  if not dir then return false, dwhy or "no exit", true end
  return true
end

-- ---------------------------------------------------------------------------
-- The guarded pair: start and stop
-- ---------------------------------------------------------------------------
local function armTick()
  if ataxiaTemp.magiKiteT then pcall(killTimer, ataxiaTemp.magiKiteT) end
  ataxiaTemp.magiKiteT = tempTimer(K.TICK, function()
    ataxiaTemp.magiKiteT = nil
    if not st() then return end
    pcall(K.step)
    if st() and not ataxiaTemp.magiKiteT then armTick() end
  end)
end

function K.start(hp)
  if st() then return false, "already kiting" end
  local sw = S()
  if sw.state ~= "idle" then sw.reset("magi kite") end -- the ladder resets the same way before it leaves
  local s = sw._cfg()
  local t = now()
  ataxiaTemp.magiKiteCoolUntil, ataxiaTemp.magiKiteCoolWhy = nil, nil
  ataxiaTemp.magiKite = { phase = "cast", fight = cur(), at = t, phaseAt = t, arrivedAt = t - K.SETTLE,
                          follows = 0, cycles = 0, misses = 0 }
  armTick()
  echo("<indian_red>MAGI KITE<reset> -- " .. hpNow(hp) .. "% (line " .. (tonumber(s.escapeAt) or 35)
    .. "%): cast, step out, come back. Stormhammer at 3+ denizens, the staffcast at 1-2. Ends at "
    .. (tonumber(s.returnAt) or 85) .. "% and cured.")
  return true
end

-- Start one if it is wanted, and say why not when the reason is news. True when a kite runs.
function K.tryStart(hp)
  if st() then return true end
  local ok, why, say = K.wanted(hp)
  ataxiaTemp.magiKiteWhyNot = (not ok) and why or nil
  if not ok then
    if say then sayOnce("no:" .. tostring(why), "<grey>not kiting<reset>: " .. tostring(why) .. ".") end
    return false
  end
  return K.start(hp)
end

-- Does the kite own this moment? Read by the basher's danger level (basher/001).
function K.owns(hp)
  if st() then return true end
  return K.tryStart(hp)
end

-- opts.cool: a failure; the ladder has the room for K.COOL (or opts.coolFor) seconds.
-- opts.recover: heal here first (S._recoverHere), the ground recovery the ladder lands in.
function K.stop(why, opts)
  local k = st()
  if not k then return false end
  opts = opts or {}
  local sw = S()
  if ataxiaTemp.magiKiteT then pcall(killTimer, ataxiaTemp.magiKiteT); ataxiaTemp.magiKiteT = nil end
  ataxiaTemp.magiKite = nil
  ataxiaTemp.magiKiteHold = nil
  if k.phase == "out" or k.phase == "back" then
    -- A queued step is still ours: take it back, so it cannot fire into the next decision.
    if sw and sw._stopMoveWatch then sw._stopMoveWatch("kite stopped") end
    if M._disarmMove then M._disarmMove() end
    if not (M.roomLava and M.roomLava()) then send("cq all") end
  end
  if opts.cool then
    ataxiaTemp.magiKiteCoolUntil = now() + (tonumber(opts.coolFor) or K.COOL)
    ataxiaTemp.magiKiteCoolWhy = why
  end
  ataxiaTemp.magiKiteLastStop = why
  echo("<grey>MAGI KITE ends<reset> -- " .. tostring(why) .. " (" .. k.cycles .. " cycle(s)).")
  if opts.recover and sw and sw._recoverHere then sw._recoverHere("kite: " .. tostring(why)) end
  return true
end

-- ---------------------------------------------------------------------------
-- The move. One queue entry (S._queueMove), the verb the swarm uses (S.moveVerb: leap, or tumble on
-- ice or a bad leg, mountjump mounted), the explorer armed for K.MOVE_MAX so it neither navigates
-- nor times out first, the swarm's move watch to re-send a lost one, and the dispatcher held.
-- ---------------------------------------------------------------------------
local function queueStep(dir)
  local sw = S()
  local verb = sw.moveVerb(dir)
  ataxiaTemp.magiKiteHold = now()
  sw._queueMove({ "stand", verb .. " " .. dir })
  sw._noteTumbleSent(verb .. " " .. dir)
  if verb ~= "tumble" and ataxiaBasher_jumpSent then ataxiaBasher_jumpSent(dir, verb) end
  return verb
end

local function go(dir, phase, why)
  local k = st()
  local sw = S()
  local from = cur()
  if M._tacticalArm then M._tacticalArm(dir, K.MOVE_MAX) end
  -- The cast's round is spent; whatever the basher queued behind it would take the equilibrium the
  -- step waits for. Never in lava (the lava escape lives in the queue).
  if not (M.roomLava and M.roomLava()) then send("cq all") end
  local verb = queueStep(dir)
  sw._watchMove(dir, function() if st() then queueStep(dir) end end)
  k.phase, k.phaseAt, k.dir, k.from = phase, now(), dir, from
  echo(why .. " -> <cyan>" .. verb .. " " .. dir .. "<reset>.")
end

-- THE GAME'S CAST LINE (triggers magi_offense_tracking/022 stormhammer, 023 staffcast). `kind` is
-- which one. Only in the cast phase, in the fight room: any other stormhammer is not the kite's.
function K.onCast(kind)
  ataxiaTemp.magiKiteCastAt = now()
  local k = st()
  if not k or k.phase ~= "cast" or cur() ~= k.fight then return false end
  k.misses, k.eqSpentAt = 0, nil
  k.cycles = k.cycles + 1
  local dir, why = K.outDir()
  if not dir then
    K.stop(why or "no exit", { cool = true })
    return false
  end
  go(dir, "out", tostring(kind or "cast") .. " is out (cycle " .. k.cycles .. ") -- stepping out")
  return true
end

-- Is the move we queued lost? The swarm's watch says so, or K.MOVE_MAX passed.
local function moveLost(k)
  local sw = S()
  local stv, why = nil, nil
  if sw._escapeMoveState then stv, why = sw._escapeMoveState() end
  if stv == "lost" then return true, why end
  if now() - (tonumber(k.phaseAt) or 0) > K.MOVE_MAX then
    return true, "not landed " .. K.MOVE_MAX .. "s after it was queued" .. (why and (" (" .. tostring(why) .. ")") or "")
  end
  return false
end

-- The cast line never came (UNCONFIRMED lines, see the triggers). A LAPSE IS NOT A CONFIRMATION
-- (.claude/AGENTS.md): it never moves us. Our equilibrium going in the cast phase with no cast line,
-- and no boon cast line either, inside K.CAST_GRACE, counts once; K.MISS_MAX in a row stop the kite,
-- so a line that does not match cannot leave us standing in the fight with the ladder held off.
local function watchLapse(k)
  local v = gmcp and gmcp.Char and gmcp.Char.Vitals
  local eq = v and tostring(v.eq)
  local t = now()
  if k.lastEq == "1" and eq == "0" then k.eqSpentAt = t end
  k.lastEq = eq
  if not k.eqSpentAt or (t - k.eqSpentAt) < K.CAST_GRACE then return false end
  local spent = k.eqSpentAt
  k.eqSpentAt = nil
  local function since(key) local a = tonumber(ataxiaTemp[key]) return a and a >= spent - 0.5 end
  if since("magiKiteCastAt") or since("simultaneityCastAt") or since("hellfumesCastAt") or since("quakeCastAt") then
    return false
  end
  k.misses = k.misses + 1
  echo("<indian_red>equilibrium spent with no cast line seen<reset> (" .. k.misses .. "/" .. K.MISS_MAX
    .. "): the kite's cast lines are UNCONFIRMED -- paste the line you see.")
  if k.misses >= K.MISS_MAX then
    K.stop("no cast line seen after " .. k.misses .. " equilibrium spends (the line is UNCONFIRMED)", { cool = true })
    return true
  end
  return false
end

-- ---------------------------------------------------------------------------
-- One look. Run on every prompt (S.onVitals), every explorer tick (S.onTick) and the kite's own
-- K.TICK clock. Returns true while the kite owns the moment; false when it stopped (the caller's
-- normal flow then decides, on the same prompt).
-- ---------------------------------------------------------------------------
function K.step(hp)
  local k = st()
  if not k then return false end
  local sw = S()
  if not (ataxiaBasher and ataxiaBasher.inMnemosyne) then K.stop("left the tower"); return false end
  if not isMagi() then K.stop("not a Magi any more"); return false end
  if not (sw and sw._enabled and sw._enabled()) then
    K.stop((sw and sw._enabledWhyNot and sw._enabledWhyNot()) or "swarm tactics are off"); return false
  end
  if sw.moveLocked and sw.moveLocked() then return true end -- a tumble of ours is landing
  local here, t = cur(), now()

  if k.phase == "cast" then
    if here ~= k.fight then
      -- Moved by something else (a forced move, a fling). A room with denizens is the fight now.
      if denizens() > 0 then k.fight, k.arrivedAt = here, t
      else K.stop("moved out of the fight room by something else"); return false end
    end
    local settled = (t - (tonumber(k.arrivedAt) or t)) >= K.SETTLE
    if settled and denizens() == 0 then
      local fit = sw._mayReturn and sw._mayReturn()
      K.stop("the fight room is clear", { recover = not fit })
      return false
    end
    if sw._mayReturn and sw._mayReturn() then
      K.stop("health is back (" .. hpNow(hp) .. "%, cured): fighting here as usual")
      return false
    end
    local lethal, lwhy = false, nil
    if sw._lethalHit then lethal, lwhy = sw._lethalHit() end
    if lethal then
      K.stop("LETHAL: " .. tostring(lwhy) .. " -- the ladder leaves now", { cool = true })
      return false
    end
    if settled and watchLapse(k) then return false end
    return true
  end

  if k.phase == "out" or k.phase == "back" then
    local target = (k.phase == "out") and nil or k.fight
    local landed = here ~= nil and ((k.phase == "out" and here ~= k.from) or (k.phase == "back" and here == target))
    if landed then
      if sw._stopMoveWatch then sw._stopMoveWatch("arrived") end
      if k.phase == "out" then
        k.phase, k.away, k.arrivedAt, k.phaseAt = "away", here, t, t
        -- Still held: in this room we step back, and an attack would delete the step.
        ataxiaTemp.magiKiteHold = t
      else
        k.phase, k.arrivedAt, k.phaseAt = "cast", t, t
        ataxiaTemp.magiKiteHold = nil
      end
      return true
    end
    if k.phase == "back" and here ~= k.from then
      K.stop("lost on the way back (in another room)", { cool = true })
      return false
    end
    local lost, lwhy = moveLost(k)
    if lost then
      K.stop("the step " .. (k.phase == "out" and "out" or "back in") .. " never happened: " .. tostring(lwhy),
        { cool = true })
      return false
    end
    return true
  end

  if k.phase == "away" then
    if here ~= k.away then
      if here == k.fight then k.phase, k.arrivedAt, k.phaseAt = "cast", t, t; ataxiaTemp.magiKiteHold = nil; return true end
      K.stop("moved off the kite's rooms by something else"); return false
    end
    ataxiaTemp.magiKiteHold = t -- refreshed while we wait here
    if (t - (tonumber(k.arrivedAt) or t)) < K.SETTLE then return true end
    if denizens() > 0 then
      k.follows = k.follows + 1
      if k.follows >= K.FOLLOW_MAX then
        sw.pursuedAt = t -- the swarm's own word for it: no ground retreat or pull while it is fresh
        K.stop("the denizens followed " .. k.follows .. " steps in a row: fighting here",
          { cool = true, coolFor = tonumber(sw.PURSUIT_MEMORY) or 45 })
        return false
      end
      k.fight, k.phase, k.phaseAt = here, "cast", t
      ataxiaTemp.magiKiteHold = nil
      echo("<indian_red>they followed<reset> (" .. k.follows .. "/" .. K.FOLLOW_MAX .. ") -- hitting them here.")
      return true
    end
    local ok, why = K.healthPermits()
    if not ok then
      K.stop("going back in is not safe: " .. tostring(why), { recover = true })
      return false
    end
    -- "Come back when eq is up" (user): the step is queued only once balance and equilibrium are
    -- back and nothing binds us (S._moveAble, what the free queue waits for), so it never sits in
    -- the queue while something else could take the round. Bounded by K.AWAY_MAX.
    local able, awhy = true, nil
    if sw._moveAble then able, awhy = sw._moveAble() end
    if not able then
      if (t - (tonumber(k.arrivedAt) or t)) > K.AWAY_MAX then
        K.stop("could not move back for " .. K.AWAY_MAX .. "s (" .. tostring(awhy) .. ")", { recover = true })
        return false
      end
      return true
    end
    local MAP = M.map
    local long = MAP.normDir and MAP.normDir(k.dir)
    local backLong = long and MAP.OPPOSITE and MAP.OPPOSITE[long]
    local backShort = backLong and MAP.shortDir and MAP.shortDir(backLong)
    local room = MAP.rooms and MAP.rooms[here]
    if not (backShort and room and room.exits and room.exits[backLong] ~= nil) then
      K.stop("no way back into the fight room from here", { recover = true })
      return false
    end
    go(backShort, "back", "equilibrium up, back in")
    return true
  end

  K.stop("an unknown phase (" .. tostring(k.phase) .. ")")
  return false
end

-- Status for `mnem swarm magikite`.
function K.status()
  local k = st()
  if k then
    return "kiting: phase " .. tostring(k.phase) .. ", fight room " .. tostring(k.fight)
      .. ", " .. k.cycles .. " cycle(s), " .. k.follows .. " follow(s), " .. k.misses .. " missed line(s)"
  end
  return "not kiting" .. (ataxiaTemp.magiKiteWhyNot and (" (" .. ataxiaTemp.magiKiteWhyNot .. ")") or "")
    .. (ataxiaTemp.magiKiteLastStop and ("; last stop: " .. ataxiaTemp.magiKiteLastStop) or "")
end
