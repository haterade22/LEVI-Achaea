# Auto-Explorer

`mnem explore` sweeps a Mnemosyne ripple hands-free: it walks the fixed 4×4 room grid, lets the autobasher clear the denizens in each room, and **pauses the instant the boon-selection screen appears** so you pick a boon and wade deeper. The pause keeps the basher fully on (`explore.on` stays `true`), and picking a boon + wading auto-resumes the sweep on the next wave (see [Boon-screen pause](#boon-screen-pause)). It writes no attack logic — it only navigates. One file: `008_Explorer.lua`, everything hanging off `ataxia.mnemosyne` (`local M`) and reusing the ripple map's graph API (`local MAP = ataxia.mnemosyne.map`).

## Division of labour

The explorer deliberately owns nothing about combat. Two existing systems do the fighting and the mapping; this module is only the glue that decides *when to step and where*.

| Concern | Owner | How |
|---------|-------|-----|
| **Combat** | the autobasher in **MANUAL** mode | Manual mode attacks whatever is in the room but never mapper-moves (its auto-move is Mudlet-mapper based and can't route the unmapped tower). No-flee/shield is already handled by `ataxiaBasher.inMnemosyne` — see the [basher no-flee doc](../basher/05-safety-systems.md#no-flee-areas) |
| **Mapping** | the ripple map (`005_Ripple_Map.lua`, `MAP`) | The 4×4 room graph, unexplored-exit detection and BFS pathfinding are all reused, not reimplemented — see [04-ripple-map.md](04-ripple-map.md) |
| **Navigation** | this module | One move per room-clear, toward the nearest unwalked exit; pause on the boon screen |

Depends on `001` (echo), `002` (run state) and `005` (`MAP`), and loads after them.

## Room-clear signal

"Room clear" is GMCP ground truth, not a text trigger: `M._roomHasDenizens()` scans `ataxia.denizensHere` and returns `true` if any entry is **not** one of your own pets/summons.

```
_roomHasDenizens():
  dz = ataxia.denizensHere
  for name in dz:
    if not isOwnDenizen(name): return true   -- a real kill target remains
  return false
```

`isOwnDenizen(name)` guards `ataxiaBasher_isOwnDenizen` in a `pcall` and treats an absent basher or any error as "not own" — so an unrecognised name safely counts as a real denizen and the sweep waits rather than walking off mid-fight.

## Movement command

Every step is one send:

```lua
local sep = (ataxia.settings and ataxia.settings.separator) or ";"
send("queue addclear free stand" .. sep .. dir)
```

`queue addclear free` is the only routing that works in the unmapped tower (the same free-queue the movement aliases and click-to-walk use). It **stands first** because you are frequently prone right after a fight and a bare `free <dir>` would silently fail; the queue runs `stand` then `<dir>` one per balance.

## State machine

The loop is event-driven, not polled. Handlers on `gmcp.Room` (arrival) and `targets updated` (a denizen killed / left / arrived) fire a **debounced** `_scheduleTick(delay)`, which waits `delay` and then runs the single decision function `_exploreTick`. The delay depends on the event: an **arrival** waits `TICK_DELAY` (0.5s) so the new room's `Char.Items` (denizens) can load before we decide — otherwise we could walk past a room whose mobs hadn't arrived; a **denizen change** (the "killed the last mob → move on" case) uses `FAST_TICK` (0.15s), because `denizensHere` is already current when `targets updated` fires, so there's nothing to wait for.

```
gmcp.Room (arrival) ── _scheduleTick(TICK_DELAY 0.5s) ──▶  _exploreTick()
targets updated (kill) ── _scheduleTick(FAST_TICK 0.15s) ──▶  _exploreTick()
```

```
_exploreTick():
  not explore.on            -> return
  not inMnem()              -> _exploreStop("left Mnemosyne")   -- leave-tower check runs BEFORE the pause gate
  explore.pausedAtBoon      -> return          -- paused at the boon screen; don't navigate
  explore.moving            -> return          -- one move per clear; await arrival
  _roomHasDenizens()        -> return          -- basher is clearing; wait
  dir = _nextExploreStep()
  if dir: _exploreMove(dir)
  else:   _exploreStop("grid fully swept")
```

The `explore.moving` flag is the **one-move-per-clear guard**: `_exploreMove` sets it, and it clears only on the `gmcp.Room` arrival (or the move timeout below), so a burst of `targets updated` events during a fight can't stack up steps.

### Move retry / timeout

A step that produces no arrival within `MOVE_TIMEOUT` is retried, then condemned. `_exploreMove` records `fromRoom`/`fromDir` and arms `M._explMoveT`:

```
after MOVE_TIMEOUT:
  if MAP.current is still fromRoom:            -- the move didn't take
    if tries < MOVE_RETRIES: re-send same exit  -- lag / transient prone
    else: mark exit failed[fromRoom][normDir(dir)] = true   -- stop retrying a wall
  moving = false; _exploreTick()
```

A condemned exit is recorded per-room in `explore.failed` (keyed by canonical `MAP.normDir`) so the sweep never retries a wall forever and never re-picks it.

### `Room.WrongDir` — server-authoritative wall (v4.7.99)

The `MOVE_TIMEOUT` path above is the *fallback*. When the server knows the direction doesn't exist it sends `gmcp.Room.WrongDir` (body = the direction), and `M.onWrongDir(dir)` condemns it **instantly** instead of eating the ~10s timeout+retry: it marks `explore.failed[fromRoom][normDir(dir)] = true`, **prunes the exit from `MAP.rooms[fromRoom].exits`** (so `pathKnown`/relayout stop routing through a dementia-faked exit — the fragmentation behind "nowhere left to patrol"), kills `_explMoveT`, clears `moving`, and `_scheduleTick`s. It only acts on an in-flight explorer move (`explore.on and explore.moving`) and normalises the server's short-form direction (`"n"` → `"north"`). Because `WrongDir` fires *only* for a genuinely nonexistent exit, it never fires for an ice-slip/prone/lag (which keep `onIceSlip`/`MOVE_TIMEOUT`), so condemning outright is safe. Handler registered reload-safe (`M._explWrongDirH`, kill-before-register).

## Navigation

`M._nextExploreStep()` returns the next single **short** direction to send, or `nil` when the reachable grid is fully swept. It is a DFS sweep with BFS backtracking:

```
_nextExploreStep():
  un = usableUnexplored(current)
  if #un > 0: return shortDir(un[1])            -- 1) unwalked exit here

  best = nil                                     -- 2) else backtrack
  for num, r in MAP.rooms:
    if r.visited and num ~= current and #usableUnexplored(num) > 0:
      steps = MAP.path(current, num)             -- BFS over WALKED edges
      if steps and (not best or #steps < #best): best = steps
  return best and best[1] or nil
```

`usableUnexplored(num)` is the filter that makes the sweep both correct and terminating. It takes `MAP.unexploredExits(num)` (reported but not yet walked) and keeps only exits that are:

| Kept | Rejected | Why |
|------|----------|-----|
| planar (`MAP.OFFSETS`: n/s/e/w + diagonals) | a non-planar `up`/`down`/`in`/`out` **when the room also has a planar exit** | A grid room's *deeper* vertical exit would walk off the level and skip the boon — the 4×4 is flat |
| a `down` exit from a room with **no planar exit at all** | any `up`/`in`/`out`, and any `down` from a room that *does* have a planar exit | The ripple's entry is a *holding room whose only exit is `down`* into the 4×4 — the one non-planar move in Mnemosyne. `up`/`in`/`out` don't exist here, so they're never taken |
| not in `explore.failed[num]` | condemned exits | So a timed-out wall isn't retried, and a room whose only unexplored exits are failed counts as swept (no infinite backtrack) |

The rule reduces to: **only `down`, and only from a pure-vertical room** (the holding room) — never `up`/`in`/`out`, and never a `down` from a 4×4 room (which always has planar exits). This closes a v4.7.56 bug where a room reporting a spurious `up` exit made the explorer loop on `moving u`. The same `usableUnexplored` gates both the current-room pick **and** backtrack candidacy, so "does this visited room still have somewhere to go?" has exactly one definition. Backtracking prefers `MAP.path` (BFS over **walked edges**, doors confirmed by walking), then falls back to **`MAP.pathKnown`** (BFS over the known-exit graph ∪ walked edges) — the walked graph can fragment (dementia fakes gmcp exits, so a move's direction isn't always determinable and its walked edge is dropped), leaving a *placed*, still-`?` room the walked BFS can't reach; `pathKnown` uses the same exit graph `relayout` places all rooms from, so it still routes there (a faked exit just fails the move and self-corrects). **Failed-exit one-shot (v4.7.95):** before quitting "nowhere left to patrol", if any exit was blacklisted this ripple, clear `explore.failed` and re-decide once (`explore._retriedFailed`) — a spurious move-timeout/prone shouldn't strand a real exit forever.

### Boss hunt (patrol)

On a **boss ripple** (every 5th) the boss spawns *at the end* — after the regular waves are cleared — in one of the already-swept rooms, so "no unexplored exit left" is **not** the end of the ripple. When `_nextExploreStep()` returns `nil`, the explorer therefore does **not** stop; it enters **patrol** (`explore.hunting`) and calls `M._nextPatrolStep()`:

```
_nextPatrolStep():
  if patrolQueue empty:
    refill with all visited rooms (sorted, != current); patrolLoops += 1
  target = front of queue; drop it if it's current / gone
  return first step of MAP.path(current, target); else advance / nil
```

It re-visits rooms round-robin and lets the basher clear whatever it finds (the boss, or a straggler). The **boon screen is still the real per-ripple terminus** (which now *pauses* rather than stops — see [Boon-screen pause](#boon-screen-pause)); the patrol is only capped at `MAX_PATROL_LOOPS` *fruitless* full loops — `patrolLoops` resets to `0` whenever a room has denizens (so a real boss fight keeps it going), and finding new ground to sweep exits patrol entirely.

The patrol queue is built from visited **grid** rooms only: `roomHasPlanarExit` excludes the pure-vertical entry **holding room** (its only exit is `down`), because the boss spawns in the 4×4, never there — and, crucially, `MAP.path` back to the holding room returns the `up` edge, which is how the sweep used to walk `up` out of the grid. As a second guard, both patrol and backtrack reject any path whose **first step is non-planar** (`planarStep`), so `up`/`in`/`out`/`down` are never *walked* as a routing step. (The one legitimate non-planar move — the initial `down` from the holding room into the grid — is a `usableUnexplored` pick, not a path step, so it's unaffected.)

## Stop conditions

| Trigger | Path | Notes |
|---------|------|-------|
| Left Mnemosyne | `_exploreTick` → `_exploreStop("left Mnemosyne")` | `inMnem()` is the **strict** check `ataxiaBasher.inMnemosyne == true`; the room-update clears that flag the instant you enter any real (mapped) area, so the sweep stops walking/fighting immediately |
| Patrol exhausted | `MAX_PATROL_LOOPS` fruitless patrol loops → `_exploreStop("nothing left")` | The grid is swept **and** no boss/straggler turned up after patrolling (see [Boss hunt](#boss-hunt-patrol)); or the patrol has nowhere reachable left |
| Slain | `007_Death.lua` → `M.exploreOnDeath(killer)` → `_exploreStop("slain")` | Death boots you out of the ripple (you respawn elsewhere), so a running sweep would walk/fight from the wrong place. Fires **regardless of telemetry** (the sweep runs off `inMnemosyne`, not the tracked run); no-op if not sweeping |
| Manual off | `mnem explore off` → `M.exploreOff()` | |
| Reload / auto-update | `sysLoadEvent` handler marks it off | See [Reload safety](#reload-safety) |

The **boon screen is deliberately not in this table** — it *pauses*, it doesn't stop (see below).

### Boon-screen pause

The boon-offer screen marks the ripple swept, but it no longer **stops** the sweep — it **pauses** it. `M.onBoonScreen()` (called straight from the boon-offer trigger **regardless of telemetry state**) sets `explore.pausedAtBoon = true`, clears `moving`, and kills the tick / move / watchdog timers — but it leaves `explore.on = true` and the basher exactly as the sweep set it (**enabled + manual + autoLearn + no-flee**). Nothing is restored or disabled here: the basher stays on through the boon pick and into the next ripple. `_prevBasher` is preserved so the eventual real stop still restores the *original* pre-sweep basher state.

While paused, `_exploreTick` short-circuits on the `explore.pausedAtBoon` gate — but that gate sits **after** the `inMnem()` leave-tower check, so leaving the tower, dying, or `mnem explore off` during the pause still runs the normal lifecycle and restores the basher. `_watchdogNudge` / `_armWatchdog` also bail while `pausedAtBoon`, so a paused sweep never `ql`-nudges.

**Resume** is shared in `M._exploreResume(reason)`: it re-asserts the explore-mode basher config (idempotent — guards a flag that flickered during the pause, notably `inMnemosyne` missed between floors), clears `pausedAtBoon`, resets the per-ripple progress (`failed`, `hunting`, `patrolQueue`, `patrolLoops`, `iceSlips`) and opens the settle window, then schedules a tick and re-arms the watchdog — mirroring the fresh-start path so the next ripple starts clean. It does **not** re-save `_prevBasher`.

Two things resume:

| Path | Trigger | Behaviour |
|------|---------|-----------|
| **GO auto-resume** | `006_Go.lua` (`^GO!$`) → `M.exploreOnGo()` | No-op unless `pausedAtBoon`. Sends `look` first (to re-establish the ripple's holding room — its only exit is `down` into the 4×4, and dementia can otherwise leave a stale room around us), then `_exploreResume("GO")`. So picking a boon + wading continues the sweep hands-free |
| **Manual** | `mnem explore on` → `M.exploreOn()` | If already `on` **and** `pausedAtBoon`, it un-pauses via `_exploreResume()` instead of complaining "already running" |

### Start guard

`M.exploreOn()` refuses unless `canStart()` passes, which requires **both** `MAP.inMnem()` **and** `gmcp.Room.Info.area == ""`. Requiring the empty area directly means a telemetry run that outlived your presence (a missed `/run_end`) can't kick off a sweep in a real, mapped area off a stale map — you must physically be in the unmapped tower.

## Basher save/restore

To drive combat, `exploreOn` forces the basher into the right mode and remembers exactly what it changed so `_exploreStop` can put it back.

```
exploreOn saves _prevBasher = { enabled, manual, areabash, autoLearn }
           _raisedBasher = (not ataxiaBasher.enabled)   -- did WE turn it on?
  forces:  enabled=true  manual=true  areabash=false  autoLearn=true  inMnemosyne=true
           if _raisedBasher: raiseEvent("basher enabled")

_exploreStop restores manual / areabash / autoLearn
           if _raisedBasher: enabled=prev; raiseEvent("basher disabled")
```

`autoLearn=true` lets Mnemosyne denizens populate `targetList[""]`; `manual=true` keeps the basher attacking-in-place; `areabash=false` stops it trying to route. The **asymmetric enable** matters: it only raises `basher enabled` if the basher was off (`_raisedBasher`), and on stop only lowers it back if it was the one that raised it — so an already-running basher is left running when the sweep ends.

This save/restore is tied to the *real* stop only. The [boon-screen pause](#boon-screen-pause) restores **nothing** — it holds `_prevBasher` untouched and re-asserts the forced config on resume — so the basher keeps fighting across the boon pick and every ripple until the sweep truly stops.

## Safety extras

### Stall watchdog

`M._armWatchdog()` arms `M._explWatchT` for `WATCHDOG` seconds and is **re-armed on every progress event** (arrival, denizen change). If it ever actually fires, nothing progressed for that long — and the usual cause is a **stale GMCP snapshot**: we actually moved, or the room actually cleared, but Achaea never pushed a fresh `Room.Info` / `Char.Items`, so no event ever woke the machine. The fire body is extracted to `M._watchdogNudge()` (so it's unit-testable without a live timer), which:

- **no-ops while a move is in flight** (`M.explore.moving`) — the move machinery owns that: `MOVE_TIMEOUT` for a lost move, `onIceSlip`'s `MAX_ICE_SLIPS` cap for a stuck icy exit. A `ql` here would be seen by the arrival handler as an arrival and reset the ice-slip counter, livelocking the sweep on one exit (an adversarial-review finding);
- otherwise sends **`ql`** (quicklook — the codebase idiom for a room/denizen refresh, needs no balance) to force the server to re-push room + contents. That fires `gmcp.Room` / `"targets updated"` — the events the explorer already listens on — which re-arm and re-tick it on fresh data, unsticking a stale-GMCP park;
- calls `_scheduleTick()` directly too, so it re-decides even if the `ql` yields no event (clear-but-parked room → the tick moves on);
- if denizens are still present, also echoes the mid-fight hint (`mnem explore off` if stuck) — a wandered-in unlearned mob or a hard affliction can genuinely park a room.

It never hard-stops on its own; it re-arms and keeps watching.

The **arrival handler** (`M._onExploreRoom`, extracted for testing) closes the other half of that livelock: `gmcp.Room` fires for *any* room re-push, not just a move, so it only ends a move (`moving=false`, kills the move timeout) on a **genuine arrival** — "moving AND the room actually changed from `explore.fromRoom`". A same-room re-push (our watchdog `ql`, the target-not-here `ql`, a stray re-send) is treated as *not arrived yet*, leaving the in-flight move / ice-slip loop intact.

### Reload safety

`M` and `M.explore` persist across an uninstall→install, but the tempTimers do not — so a live sweep would be left half-alive with the basher still force-mutated. The `sysLoadEvent` handler zeroes `explore.on`/`explore.pausedAtBoon`/`explore.moving` and drops `_prevBasher`, so a reload never resurrects a partial sweep (or a leftover boon-screen pause); you re-issue `mnem explore on`.

### Progress echoes

The sweep narrates itself (`M._exploreEcho`, prefix `[explore]`) so you can follow it live:

- each step: `room clear -> moving <dir>.` (a stalled retry echoes `retrying <dir> (no arrival)`);
- once per occupied room (tracked by `explore.fightingRoom`, not every tick): `clearing this room (N denizen(s)) -- basher on it.` — `N` from `denizenCount()` (killable, own-denizen-excluded);
- the start / stop / boon-screen pause / resume / fully-swept transitions each announce themselves (the boon-screen echo says the basher stays on and to `mnem explore on` to resume; resume echoes `resuming the sweep (<reason>)`).

### Icy rooms

Some rooms are icy: leaving can print **"You slip and fall on the ice as you try to leave."** — the move fails (you fall prone) but the *exit is fine*. Trigger `011_Ice_Slip.lua` calls `M.onIceSlip()`, which (while a sweep move is in flight) re-sends the stand+move and re-arms the move timeout, **without** touching the failed-exit budget — so the explorer keeps trying until it actually leaves rather than condemning a good exit. Capped at `MAX_ICE_SLIPS` re-sends (then the exit is marked failed, so a permanently stuck exit still yields). `explore.iceSlips` resets on each fresh move.

## Tuning constants

| Constant | Value | Meaning |
|----------|-------|---------|
| `TICK_DELAY` | `0.5` | Debounce on **arrival**; let the new room's `Char.Items` (denizens) load before deciding |
| `FAST_TICK` | `0.15` | Debounce on a **denizen change** (a kill); `denizensHere` is already current, so react fast |
| `MOVE_TIMEOUT` | `5` | A move producing no arrival within this → retry / unstick |
| `MOVE_RETRIES` | `1` | Re-send a stalled move this many times before condemning the exit |
| `WATCHDOG` | `30` | Seconds of no progress before a soft nudge / notify |
| `MAX_PATROL_LOOPS` | `3` | Fruitless full boss-hunt patrol loops before giving up |
| `MAX_ICE_SLIPS` | `15` | Re-send a move this many times after an ice slip before condemning the exit |

## Commands

Dispatched from `003_Commands.lua`; a bare `mnem explore` toggles.

| Command | Function | Effect |
|---------|----------|--------|
| `mnem explore on` | `M.exploreOn()` | Start (guarded by `canStart`), **or resume** if paused at a boon (`_exploreResume`) |
| `mnem explore off` | `M.exploreOff()` | Stop and restore the basher |
| `mnem explore status` | `M.exploreStatus()` | Echo `ON` / `paused (boon screen)` / `off`, `inMnem`, `denizens`, `moving`, `next` |
| `mnem explore` | `M.exploreToggle()` | Flip on/off |

See [05-commands.md](05-commands.md) for the full `mnem` dispatch.

## Testing

The **pure logic** is unit-tested — `M._nextExploreStep` and `M._roomHasDenizens` are exercised directly against a mocked `MAP`/`ataxia.denizensHere`, locking in the pick-here-then-backtrack order, the planar/failed filtering, and the own-denizen guard. The **timer/event state machine** (debounced ticks, the `moving` guard, move timeout, watchdog) depends on live tempTimers and GMCP and is validated in-game.

---

## Swarm tactics (multi-mob rooms) — `009_Swarm_Tactics.lua`

Deep ripples pack 3-4+ roaming denizens per room. On every decidable tick the explorer
delegates first to `ataxia.mnemosyne.swarm.onTick()` (a consumed tick = no navigation/announce
this tick). Stage 1 = the **pull & funnel** loop:

- **Assess** (idle, settled arrival): killable count (`M._denizenCount()`) >= threshold
  (`mnem swarm assess <n>`, default 3; optional depth scaling `mnem swarm deep <ripple> <n>`)
  AND a **validated back-route**: planar + adjacency-verified
  (`MAP.rooms[cur].exits[OPPOSITE[fromDir]] == fromRoom`) — never "up" out of the first grid
  room, never a stale `fromDir`. No route -> fight in place (room marked no-tactics).
- **Pull**: arm a ONE-SHOT decorator (`ataxiaTemp.swarmPullDir`); the next
  `ataxiaBasher_assembleAttack` send becomes `"<attack>;<backdir>"` — swing + step-out as one
  queued line, atomic on balance (the manual ragepull shape). Consumption arms
  `ataxiaTemp.swarmHold` (gates `ataxiaBasher_tryAttack` so the next `queue addclearfull`
  can't wipe the chain; self-clears after 5s), clears `found_target` (stale-target race) and
  kills `ataxiaTemp.mobshieldtimer` (cross-room re-settarget). If no swing comes within 2.5s
  (shield branch, no target), the fallback walks out plain.
- **Funnel**: arrival in the previous room -> hold navigation; the basher fights whatever
  follows (followers arrive via `Char.Items.Add` -> "targets updated"; one `ql` re-Lists for
  never-Listed spawns). Fighting refreshes the 4s follow window; when it expires empty ->
  **re-enter** and re-assess. `MAX_PULLS` (3) per room counts only UNPRODUCTIVE cycles —
  progress refunds the budget (hit-and-run continuation, v4.7.117 below) — then the room
  is fought in place.
- **Indoors route** (`swarm.icewall`, default on): the first escape suffix is
  `;point <bracersId> <LONG back>;leap <back>` — swing, WALL the door we came through, LEAP
  over our own wall, all one queue entry (order preserved; a split send could wall the wrong
  edge from the wrong room). Hold behind the wall with the longer `WALL_WINDOW`. **The wall
  STAYS UP across cycles** (v4.7.119, user-confirmed: chitin-greaves LEAP clears our own
  wall in BOTH directions): re-entry is a single eq-gated `leap <fwd>` — no melt, no walk —
  and while `S.wallRaised[room]` is set, follow-up escapes go **leap-only** (skip the
  point), firing a full balance-round sooner. A broken/expired wall degrades leap-only to a
  plain unwalled pull — acceptable, since denizens walk through walls anyway without the
  boon. The wall is melted (`point <meltId> at icewall`) only when the room is DONE — the
  assess sees zero denizens, consumes the tick so the explorer's own `queue addclear free`
  move can't wipe the queued melt, arms a short `swarmHold` (a roamer's `addclearfull`
  can't wipe it either), and — review HIGH — clears the memory only on the melt
  CONFIRMATION line (trigger 026 → `onWallMelted`); unconfirmed melts re-send on later
  empty assesses, bounded at 4 tries, after which the wall is left to the leap reflex.
  `wallRaised` stores the walled edge's LONG dir (the panic tumble avoids it) and is wiped
  only on a GENUINE ripple change (`S._wallsRipple`) — a mid-ripple `mnem explore off/on`
  restart keeps it (review MEDIUM: walls are physical). ALL tactical moves LEAP
  (`_tacticalGo` sends `stand;leap <dir>`, review CRITICAL: the indoor low-HP retreat
  crosses the walled funnel edge — a plain walk livelocked the anti-death ladder).

**Wall-leap navigation** (`M.onWallBlocked`, trigger 025, v4.7.119, user-directed): "A
wall blocks your way." / "A wall bars your path." during an in-flight explorer move —
ANY wall, ours or an affix's — replaces the walk with `stand;leap <dir>`. The exit is
real, so it is never condemned; the already-armed move timer keeps watching (its
walk-retry just earns another wall line → another leap), and the ice-slip budget bounds
it. The legacy `766_Wall` manual-walk branches are gated off while exploring — they
leapt the raw `command` string and `addclearfull`-wiped the explorer's queue.
  **Live-validated 2026-07-26** (3-troll room, no deaths, melt-era cycle). Lines: leap "You
  bunch your powerful muscles and launch yourself in a majestic leap <dir>wards."; melt
  "You send a lash of fire to strike the icewall to the <dir>, and it quickly melts." NOT
  atomic: `point` fires on the NEXT balance, `leap` on equilibrium (~7s escape; the 8s
  swarmHold covered it; leap-only cycles are faster). **Without Maklak's Promise denizens
  WALK THROUGH icewalls** — the wall paces the fight rather than barring it; with the boon
  it should actually impede (still to observe).
- **Outdoors swarm-followed** (`swarm.kite`, default on): followers >= threshold in the
  funnel → `fly`; the decorator turns every attack into `land;<attack>;fly` (ground contact
  only for the swing). Below threshold → `land` and finish grounded. If FLY needs balance the
  trailing fly is simply rejected that round — degrades to grounded fighting, never wedges.
  Flight is landed on every reset (boon screen / stop / death) so it can't leak into a wade.
  **Live-confirmed 2026-07-26** (ring of flying): fly line `The ring of shining metal carries
  you up into the skies.`; land lines `You begin to descend, the wind whistling past you...`
  + `You land easily, back on the ground again.` While airborne, melee cannot reach us and
  our passive psychic damage keeps ticking; the grounded swing window absorbs one round
  (observed: thrall hinder + treemite leg break) — the kite's designed price. Still open:
  whether the TRAILING fly fires after the swing consumes balance (watch for "carries you
  up" after every swing round; two consecutive grounded rounds = balance-gated → switch to
  the dispatch-gated fallback).
- **Low-HP escape** (`swarm.escape`, default on, `escapeAt` 35%, land at `recoverAt` 95%
  AND affliction-free — broken limbs are afflictions, so restoration finishes airborne;
  kept defences blindness/deafness/curseward/insomnia never hold the hover):
  HP-gated ONLY (a two-mob chip-down killed below the swarm threshold). Outdoors -> fly and
  hover (state `recovering`, attacks hold-gated, 2s re-checks, 60s cap) -- flight works with
  every limb broken, unlike `touch shield`; land + resume when healed. **LIVE-VALIDATED
  end-to-end 2026-07-27** (Blazing mountainside: 19% -> fly -> hover-heal to 99% through the
  smoke -> land -> resume). **Landing settles, never decides** (v4.7.125): airborne gmcp
  Char.Items reflects the SKY (denizensHere empty), so the landing tick is CONSUMED and the
  arrival settle window opened -- the land's Room/Items re-push supplies real ground data;
  handing the tick back immediately walked out of a still-mob-filled room as "clear".
  Blazing affix: ~725 fire on grounded entry, ~511 asphyxiation per ~5s while hovering (the
  hover still out-heals it). Indoors -> plain
  retreat to the cleared room (no swing) and cure while fighting the trickle; no route ->
  shield-in-place remains. SLC's both-arms flee is inert in the tower (fixed-direction blind
  runs); the swarm module owns tower escapes.
- **Roll Hide panic** (`swarm.panic`, default on, needs the `mnemRollHide` boon): at
  `swarm.panicAt`% HP (default 40) mid-funnel, tumble out through a non-swarm exit — the boon
  sheds ALL pursuers — then full reset (10s cooldown).

**Hit-and-run continuation (v4.7.117)**: the pull budget (`MAX_PULLS` 3) exists to stop
POINTLESS ping-pong — but the Putoran-wildcat log showed non-chasing mobs ("peak
followers: 0" every cycle) where each cycle was one free swing chipping the soldier
94→83→78→71% with a kill on cycle two. Doctrine: "continue hit and run until the room is
cleared or below 3 denizens." Each pull snapshots `entrySnap[room] = {n, id, hp}` (count +
focused-target hp via `S._targetHp()` — denizen-state `hpp` / `IRE.Target.Info.hpperc`,
the HUD mob-bar chain). On the next assess, count dropped OR same-target hp dropped →
`pulls[room] = 0` ("hit-and-run continues" echo). Only unproductive cycles spend budget —
denizens REGEN while we funnel ("a wildcat soldier ceases tending to his wounds"), so a
true stalemate still caps and fights in place, with the escape ladder as backstop. Also
learned: flying renames the GMCP room to "Flying above <room>" (same room otherwise —
watch that the room NUM stays stable for the kite/hover room guards).

**Vitals-driven emergency wake-up (`S.onVitals`, v4.7.116)**: the explorer tick is
EVENT-driven (arrivals, target-list changes, a 30s watchdog) — a stationary slugfest
generates almost none. The Pinnacle death (2026-07-26, 3 angelic razers + a roamed-in
inquisitor angel) crossed the 35% escape threshold and died ~3s later with the single
tick-driven evaluation landing on a potash heal bounce. A `gmcp.Char.Vitals` handler now
runs the panic/escape gates on EVERY prompt: reads HP fresh from the gmcp payload (the
shared `ataxia.vitals` may be one prompt stale — same event, registration order),
`hp <= 0` is treated as blackout-unknown (never "dying"), 2s cooldown between actions,
and — unlike the tick path — it acts even while a pull is in flight (the explorer
`moving` guard blinded the old path for the pull's full 8s): `M._disarmMove()` releases
the move machinery without condemning, the escape's reset `cq all`s the doomed chain.
The recovery hover also self-ticks now (`_scheduleTick(RECOVER_TICK)` at hover start,
not just in the loop) so landing never waits on an outside event.

**Pull retry after a lost move (v4.7.116)**: razer stupidity replaces queued commands
with involuntary actions ("You pull down your pants and moon the world" — that ate the
Pinnacle step-out). `_tacticalArm` clobbers `explore.fromRoom/fromDir` with the pull
itself, so a lost pull used to make the reassess find "no valid pull route" and latch
`noTactics` on exactly the room that most needs tactics. `onMoveFailed` now restores the
anchor from the tactic's own saved route (`S.funnelRoom`/`S.fwdShort`, only when still in
the swarm room; `_backDir` re-validates against the exit graph) so the reassess re-pulls;
`MAX_PULLS` still bounds it.

**Flight confirmation (v4.7.116)**: the escape's own fly can be eaten too. `S.flying` is
the MODE flag (optimistic); `S.flightConfirmed` is the last confirmed physical state, fed
by trigger `022_Flight_Lines` ("The ring of shining metal carries you up into the skies."
/ "You land easily, back on the ground again."). The recovery hover re-sends
`queue addclear free stand;fly` each 2s tick until confirmed — grounded-but-gated is the
worst of both worlds. Unknown fly sources just re-send harmlessly ("You are already
flying."). Kiting flaps the flag freely; only the hover consumes it.

**Tactical moves never condemn exits**: `M._tacticalArm(dir)` sets `explore.moving` +
`explore.tacticalMove`; the three condemn paths (move-timeout give-up, ice-slip cap,
`Room.WrongDir`) skip the `explore.failed` write when the flag is up — these are WALKED edges,
condemning them would poison the sweep — and notify `swarm.onMoveFailed()` instead.
`M._disarmMove()` is the no-callback cancel (emergency escape owns the teardown).

**Resets** (`swarm.reset`): boon screen (every ripple ends there), `_exploreStop`
(death/leave-tower/off), `basher disabled`, `sysLoadEvent` (plus load-time clears of
`ataxiaTemp.swarmHold`/`swarmPullDir` — they'd otherwise survive a SYSUPDATE and silently gate
the basher). `swarm.onRipple` (exploreOn/_exploreResume) wipes per-ripple pull budgets.

**Recon — Bloodscent (parsed) + Sleuth (raw)**: the **Bloodscent** boon ("You sense out
your prey upon entering a ripple.", flag `mnemBloodscent`) prints, unprompted per ripple
entry, one `You sense <mob> (#id) at <room>.` row per denizen (live-captured 2026-07-26 —
the parsed format the recon system was waiting for). Trigger 028 feeds
`swarm.onSenseStart/onSenseRow`; a 1.5s quiet window commits `swarm.recon = { mobs =
{{name,id,room}}, byRoom, rooms, ripple, at }` and echoes a summary with **crowded-room
callouts** (rooms holding >= the swarm threshold). Both handlers self-gate on
`ataxiaBasher.inMnemosyne`. With **Sleuth** (`mnemSleuth`), GO fires `fullsense` captured
raw via `_captureLines`; if its rows share the sense-line shape they feed the same parser.
`mnem sense` re-scans manually (denizens ROAM; recon is a snapshot — per-arrival assess
stays authoritative). Recon-driven ROUTING remains stage 3+. `mnemRollHide` (tumble sheds
pursuers) is captured for the panic abort.

**Haemophiliac pacing** (affix, v4.7.119, user-directed "wade significantly slower"): the
effect row "Defeating a denizen causes you to bleed significantly and your mana costs are
increased by 20%." (trigger 029 → `onHaemophiliacSeen`, Splinterbark's shape:
inMnemosyne-gated, transition-guarded, cleared run start/confirmed end) bleeds THOUSANDS
per kill. While `mnemHaemophiliac` is set, `_exploreTick` holds post-clear navigation
until the bleed is **CLOTTED** (user spec) — `ataxia.vitals.bleed < 50` (live per prompt
from gmcp charstats; SSC's `curing clotat 30` does the actual clotting, at the affix's
+20% mana cost — our job is standing still while it works) — AND `hpp >= 90`
(`M._haemoHold`, pure/tested; 1.5s re-checks; one echo per wait, with the bleed value).
A missing bleed reading counts as 0, so the hold can never wedge. Mid-fight behavior
(swarm pulls, attacks) is deliberately untouched: the bleed comes from KILLS, and pacing
belongs between rooms.

Pure logic (threshold, `_backDir`, the state machine, decorator, resets) is unit-tested in
`test_swarm_tactics.lua`; timer-fired paths are validated in-game.

---

See also: [04-ripple-map.md](04-ripple-map.md) (the `MAP` graph API this reuses), [05-commands.md](05-commands.md) (`mnem` dispatch), [01-architecture.md](01-architecture.md) (run lifecycle / gating).
