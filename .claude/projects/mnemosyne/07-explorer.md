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

**A told-zero room HOLDS, it does not stop** (v4.7.263). When the game has answered
`There are no obvious exits.` for the room we are standing in (`room.exitsTextZero`, see
[04-ripple-map.md](04-ripple-map.md)), the sweep waits — bounded, ~40 × 3s — instead of falling
through to `_exploreStop("nowhere left to patrol")`. Stopping there would be unrecoverable for the
run: `_exploreStop` restores the basher and clears `explore.on`, and `exploreOnGo` only
*un-pauses* (it requires `pausedAtBoon`), so nothing would restart it. The holding room is exactly
that case — it prints the zero line every ripple and its `down` opens on GO.

**"Nowhere left to patrol" prints its refusals** (v4.7.260). The stop used to state a conclusion
about the ripple when it was really reporting our own ignorance; it now lists each remaining exit
and why `_stepRefusal` declined it.

### Boon-screen pause

The boon-offer screen marks the ripple swept, but it no longer **stops** the sweep — it **pauses** it. `M.onBoonScreen()` (called straight from the boon-offer trigger **regardless of telemetry state**) sets `explore.pausedAtBoon = true`, clears `moving`, and kills the tick / move / watchdog timers — but it leaves `explore.on = true` and the basher exactly as the sweep set it (**enabled + manual + autoLearn + no-flee**). Nothing is restored or disabled here: the basher stays on through the boon pick and into the next ripple. `_prevBasher` is preserved so the eventual real stop still restores the *original* pre-sweep basher state.

#### What a pause suspends — and what it must not (v4.7.263)

The axis is **not** paused/not-paused. Every site belongs to exactly one of three classes:

| Class | Examples | Rule |
|---|---|---|
| **INITIATION** | sweep step, backtrack, patrol, pull, funnel re-entry, boss chase, map upkeep, wall melt | **suspend** |
| **COMPLETION** | a move in flight landing, failing, slipping, being retried | **never suspend** — doing so strands `explore.moving`, `swarmHold` and `S.state` |
| **SELF-PRESERVATION** | lava, the escape ladder, the panic tumble, the recovery loop, the tincture, a forced disengage | **never suspend** |

`M._navRefusal()` is the single owner, returning a **reason string or nil** in the same shape as
`_stepRefusal` / `_chaseRefusal`. It answers *"is navigation suspended"*, deliberately **not**
*"is the sweep running"* — the boss chase legitimately works with the explorer off — and folds in
nothing else (`inMnem` means *stop*, not suspend; `roomLava` outranks every pause; `moving` means
*wait*, not refuse). A guard that answers every question refuses everything.

Consumers: `_exploreTick` (below the swarm delegation), `_watchdogNudge` and both watchdog re-arm
sites, `_chaseRefusal`, and the **idle assess** inside `S.onTick`.

**Two traps, both of which this code fell into before v4.7.263:**

1. **`S._enabled()` (009) is deliberately NOT pause-aware.** It gates `S.onVitals`, `S.disengage`
   *and* `S.onTick` together, so adding the pause there — the obvious one-line fix — kills the
   escape ladder, the panic tumble, the tincture and the forced disengage at a stroke: the
   reported bug with its sign flipped. The gate belongs on the idle assess, at its single call
   site, never inside `_beginPull` (which *stamps* `pulls`/`entrySnap`/`swarmPullDir`).
2. **The old gate was in the wrong place**, third line of `_exploreTick`, **above** the swarm
   delegation. Every swarm state machine self-ticks through `M._scheduleTick`, so pausing the
   sweep froze the recovery loop too: at the boon screen the escape ladder fired **once** and then
   disabled itself (`S.onVitals` returns early while `recovering`, and only the tick can leave that
   state). Nothing landed, nothing re-sent an eaten `fly`, nothing enforced `RECOVER_MAX`, until
   GO — which needs the user at the keyboard, i.e. exactly the case a pause exists to survive.

The gate now sits **below** the delegation, so the swarm finishes what is in flight and the sweep
starts nothing new.

**The arrival tick is still re-armed while paused, deliberately.** A tick under suspension is a
*decision point*, not an action, and it is the only clock `S._beginEscape`'s indoor branch has —
that branch sets `state = "pulling"`, arms the hold, sends the retreat and does **not**
self-schedule. Suppress it and an indoor escape taken during the pause never reaches `recovering`,
`swarmHold` self-clears at 8s, and the basher resumes swinging at crash HP with the recovery
abandoned (the v4.7.235 / v4.7.252 family). The **watchdog** is navigation-only and does not
re-arm; `onBoonScreen` killed the outstanding one, and both resume paths arm a fresh one.

The `inMnem()` leave-tower check stays **above** the nav gate, so leaving the tower, dying, or
`mnem explore off` during the pause still runs the normal lifecycle and restores the basher.

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

**A TACTICAL slip is a different problem (v4.7.243).** `_exploreMove` sends a bare `stand;<dir>` **walk**. That is exactly right for a sweep step and exactly wrong for a swarm retreat, which was a `leap`/`backflip` — and a walk into our own standing icewall fails *silently*. The caves-beneath-Kuthalebak death log shows the loop: `pull move lost -- retry 1 -> n`, then `You slip and fall on the ice as you try to leave`, then `slipped on the ice -- up and going again`, against a room reporting `An icewall is here, blocking passage to the north`. Fifteen of those is **thirteen seconds** standing in the room we are fleeing, at ~2,150 HP/s.

So when `M.explore.tacticalMove` is set, `onIceSlip` does **not** call `_exploreMove`. It clears `moving`, kills the move timer and hands back to `S.onMoveFailed()`, which restores the route anchor, re-arms the hold and re-sends the swarm's **own** verb via `_tacticalGo`, bounded by `S.PULL_RETRIES`. The budget is separate too: `MAX_TACTICAL_ICE_SLIPS = 3`, because fifteen re-sends is defensible for an idle sweep and indefensible under fire.

`onIceSlip`, `onWallBlocked` and `_exploreMove` all also refuse outright while `S.moveLocked()` — see the movement lock in the swarm section. A tactical slip under the lock is not even counted against the budget.

## Tuning constants

| Constant | Value | Meaning |
|----------|-------|---------|
| `TICK_DELAY` | `0.5` | Debounce on **arrival**; let the new room's `Char.Items` (denizens) load before deciding |
| `FAST_TICK` | `0.15` | Debounce on a **denizen change** (a kill); `denizensHere` is already current, so react fast |
| `MOVE_TIMEOUT` | `5` | A move producing no arrival within this → retry / unstick |
| `MOVE_RETRIES` | `1` | Re-send a stalled move this many times before condemning the exit |
| `WATCHDOG` | `30` | Seconds of no progress before a soft nudge / notify |
| `MAX_PATROL_LOOPS` | `3` | Fruitless full boss-hunt patrol loops before giving up |
| `MAX_ICE_SLIPS` | `15` | Re-send a *sweep* move this many times after an ice slip before condemning the exit |
| `MAX_TACTICAL_ICE_SLIPS` | `3` | The same budget for a swarm retreat, where each attempt costs a second under fire (v4.7.243) |

## Commands

Dispatched from `003_Commands.lua`; a bare `mnem explore` toggles.

| Command | Function | Effect |
|---------|----------|--------|
| `mnem explore on` | `M.exploreOn()` | Start (guarded by `canStart`), **or resume** if paused at a boon (`_exploreResume`) |
| `mnem explore off` | `M.exploreOff()` | Stop and restore the basher |
| `mnem explore status` | `M.exploreStatus()` | Echo `ON` / `paused (boon screen)` / `off`, `inMnem`, `denizens`, `moving`, `next` |
| `mnem explore why` | `M.exploreWhy()` | **Why is the sweep not moving?** Per-exit refusal reasons, the grid bounding box (a box wider than `GRID` means the coordinates are wrong and every geometric refusal is suspect), the nav-suspension state, the **lava ledger** with provenance, and the map's witnessed arrival beside the explorer's armed pair — seeing those two disagree *is* the diagnosis (v4.7.259, extended v4.7.262) |
| `mnem explore` | `M.exploreToggle()` | Flip on/off |

See [05-commands.md](05-commands.md) for the full `mnem` dispatch.

## Testing

The **pure logic** is unit-tested — `M._nextExploreStep` and `M._roomHasDenizens` are exercised directly against a mocked `MAP`/`ataxia.denizensHere`, locking in the pick-here-then-backtrack order, the planar/failed filtering, and the own-denizen guard. The **timer/event state machine** (debounced ticks, the `moving` guard, move timeout, watchdog) depends on live tempTimers and GMCP and is validated in-game.

**Every fix here must be broken back**: revert the hunk and confirm the named assertion fails.
This is not ceremony — three tests in this suite have passed against reverted code and had to be
rewritten (an assertion that was nil in both worlds; a helper that *reimplemented* the code under
test; an adjacency test whose anchor tripped an earlier guard instead of the one under test).

`test_swarm_tactics.lua` mocks `ataxia.mnemosyne` because 008 is not loaded there, so any predicate
009 consults needs a **faithful stand-in** in that mock (`roomIsLava`, `edgeIsLava`, `_navRefusal`).
Without one the tests pass while the guard is simply absent — the file says so in a comment, and it
is worth re-reading before adding a cross-module guard.

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
  (`_tacticalGo` sends `stand;<jump> <dir>` — see *Which jump* below; review CRITICAL: the indoor low-HP retreat
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
  funnel, and `S._canFly()` (see *When flight is not an option* below) → `fly`; the
  decorator turns every attack into `land;<attack>;fly` (ground contact
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
  HP-gated ONLY (a two-mob chip-down killed below the swarm threshold). Outdoors, and only
  where hovering is actually viable (`S._canHover()` — see *When flight is not an option*
  below) -> fly and hover (state `recovering`, attacks hold-gated, 2s re-checks, 60s cap) --
  flight works with every limb broken, unlike `touch shield`; land + resume when healed.
  **LIVE-VALIDATED
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
- **Roll Hide OUTRANKS the icewall (v4.7.223)**: the wall was never a barrier -- denizens
  walk through icewalls without Maklak's Promise, so it only PACED the swarm, at the cost of a
  balance-gated `point`, a wall-memory entry and a later melt. With `mnemRollHide` up, indoors
  takes `mode = "pull"` and `_escapeSuffix` returns `;tumble <back>`: shedding every pursuer
  beats pacing them, and the funnel/kite branches then never fire at all. Safe inside the single
  queue entry for the reason the wall chain already proves -- the entry's commands do NOT all run
  on one balance (`point` on the next balance, `leap` on eq), so a balance-gated tumble is HELD
  rather than rejected.

- **Roll Hide panic** (`swarm.panic`, default on, needs the `mnemRollHide` boon): at
  `swarm.panicAt`% HP (default **35** since v4.7.218 — the old 40 is migrated once, behind a
  persisted `panicAt35` marker so `mnem swarm panic 40` stays typeable) OR the absolute
  `panicHp` floor (3000), tumble out through a non-swarm exit — the boon sheds ALL pursuers.
  10s cooldown.
  **Then it HEALS THERE (v4.7.218)** rather than dropping to `idle`. Until v4.7.218 the tumble
  handed straight back to the explorer and the `swarmHold` self-cleared in `HOLD_TIMEOUT`
  (~8s), so we navigated back into the room we had just fled, still at panic HP — the boon's
  entire value spent on an immediate return. It now enters `recovering` with
  `S.recoverGround = true`, held until `recoverAt`% AND affliction-free, then hands back for
  the next run-in. That is the hit-and-run cycle the boon exists for (user, 2026-08-06: "the
  denizens wont follow so we can use this to our advantage to heal up and then do hit and run
  tactics").
  A **ground** recovery is not a hover and differs in two ways: a denizen arriving ENDS it
  (standing attack-gated at panic HP while something hits us is worse than fighting it), and
  it never sends `land` — it never left the ground. `_maybePanic` also refuses while
  `state == "recovering"`: Roll Hide already shed them, so a repeat tumble sheds nothing and
  only walks us off the sweep (previously only the 10s cooldown stood between a slow heal and
  a tumble every ten seconds).

- **Vitalising Tincture** (`S._maybeTincture`, v4.7.241, needs the boon): 33% of maximum
  health on a 20s cooldown -- the largest single heal in the system, ~6,000 at tower pools, and
  the ladder previously ignored it. Fires at `escapeAt` from `S.onVitals` **before** the
  flee/panic decision, because a third of our health back may mean the retreat is unnecessary.
  **`ataxia.mnemosyne.tinctureCmd` is nil by default** -- the command that imbibes a nutritional
  formulation is unconfirmed, and guessing commands is how bare `BOONS`/`PERFORMANCE` shipped
  broken. Inert until set.

- **Forced disengage** (`S.disengage(reason)`, v4.7.215): leave on a TACTICAL judgement rather
  than an HP reading. The ladder above is entirely reactive, which is useless against an enemy
  whose kill pattern is "apply an unsurvivable lock, then wait" — by the time HP crosses
  `escapeAt` we are locked, and a locked character cannot be relied on to execute an escape at
  all. Callers that can RECOGNISE a losing pattern get to leave while we can still obey.
  Everything downstream is the proven ladder (hover outdoors / pull back indoors) including
  the recovery gate, which is what makes it a real disengage: we do not return until the lock
  is gone. Returns **false** rather than pretending — disabled, on cooldown
  (`DISENGAGE_COOLDOWN` 10s), or indoors with no validated route — and a FAILED attempt does
  not stamp the cooldown, so a caller that read the fight as lethal retries the moment a route
  exists. First consumer: Seasone's second phial burst (see 03-parsing-triggers).

**Re-entry readiness (`S._reenterReady`, v4.7.242)**: the funnel does NOT go back in just
because the trickle stopped. `_beginReenter` used to decide on one question -- *"did anything
follow?"* -- and **"nothing followed" is not the same fact as "we are ready"**: 0 followers means
the retreat worked perfectly, which it read as permission to undo it. A death log has it walking
back onto Seasone **two seconds** after a successful disengage, at 28% HP and still soft-locked.
Re-entry now needs `recoverAt`% AND affliction-free -- the SAME gate the hover uses -- and when
we are not ready it enters `recovering` (ground recovery: diagnose confirm, tumble-on-company,
`RECOVER_MAX` cap) rather than inventing a second wait.

Worth knowing why nothing else caught it: the low-HP ladder runs BEFORE the funnel branch and
would have fired at 28%, but `_beginEscape` needs a back-route and we were already standing in
the room it would have retreated to -- so it returned false and fell through. **The one moment
the ladder could not help was the one moment we walked back in.**

**The escape pull HOLDS the attack dispatcher (v4.7.235)**: `_beginEscape`'s hover branch always
armed the hold; the indoor pull branch did not, so the next attack's `queue addclearfull` --
which clears the FULL queue -- threw the queued escape away. A Seasone log shows three complete
attack rounds between the disengage and `pull move lost`. General rule for this module:
**anything we queue that is not an attack must hold the dispatcher.**

**A lost move is RETRIED (v4.7.235)**: `onMoveFailed` used to go idle and rely on the next tick.
The tick is EVENT-driven, and in a stationary slugfest the gap measured **fourteen seconds**.
Bounded by `S.PULL_RETRIES`, hold re-armed on each retry.

**Tumble confirmation (v4.7.233/234)**: `"You begin to tumble agilely to the <dir>."` is the
START of a two-stage action -- paralysis, prone or a stun between the halves cancels it, which
killed us once. `"You tumble out of the room."` is the completion line (trigger
`misc_alerts/005`); the room-change fallback fires only after `S.TUMBLE_CONFIRM` = **5s**,
because a real tumble takes **4.0s** and the first version's 2s window would have re-sent a
tumble that was working. *A retry window must outlast the action it guards.*

**Which jump — `S.moveVerb(dir)` (v4.7.217)**: `_tacticalGo` sends **`backflip`** for a Bard
and **`leap`** for everyone else. Acrobatics BACKFLIP recovers quicker than the chitin-greaves
LEAP (user, 2026-08-06: "it is faster balance"), and every tactical move here is a retreat made
because something is going badly — the balance we get back is the balance we spend curing. The
normal sweep already WALKS (`_exploreMove` sends a bare direction), so there was never balance
to save there.

**LEAP is kept wherever a wall is known to stand** — `_escapeSuffix` wall-mode (both branches),
the wall-mode re-entry, and the explorer's "a wall blocks the way". Those jumps exist to clear
our OWN icewall, and greaves-LEAP is the ability confirmed to do that in both directions.
Whether BACKFLIP crosses an icewall is **not confirmed**, and guessing wrong is not a slow move
— it is a silent no-op in the indoor low-HP escape, i.e. the anti-death ladder livelocking at
crash HP, the exact failure the LEAP was introduced to fix. `moveVerb` disambiguates from
`wallRaised[room]` (the same field the panic tumble reads to avoid its own ice) and falls back
to LEAP when the wall state cannot be resolved — the conservative answer is the one that still
moves us. *If backflip turns out to clear icewalls, the wall branch can be dropped.*

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

**When flight is not an option (`S._canFly` / `S._canHover`)**: the escape ladder's outdoor
branch and the fly-kite both go UP, so both need to know when up is a trap. `S._canFly()` is
`not mnemDeluge and not S.grounded` — "we cannot get airborne at all"; `S._canHover()` is
`_canFly()` plus `M.roomAblaze()` — "and even if we could, hanging there is no safer than the
ground". Three things now feed them:

- **Deluge** (affix, trigger 037, run-wide): all rooms are underwater, so FLY is simply
  rejected — the ladder and the kite take their grounded branches.
- **Dragged out of the air** (v4.7.168): *"A tentacle shoots up from the ground, wraps itself
  around you, and drags you back to earth."* A DENIZEN can pull us down. This is the third way
  flight fails, after Deluge and an eaten FLY, and the worst of the three because it was SILENT
  to the state machine: the recovery hover keeps `S.flying` optimistically true until a flight
  line confirms (the *Flight confirmation* guard above, which exists precisely because
  stupidity eats queued commands) — and after a drag that confirmation never comes, so the
  hover re-sent `fly` EVERY TICK while the tentacle yanked us straight back down, holding us
  attack-GATED at crash HP with the swarm still on us until `RECOVER_MAX` (60s) expired.
  Strictly worse than never having flown. `S.onDraggedDown()` (trigger `mnemosyne/050`,
  `inMnemosyne`-gated) latches `S.grounded`, clears both flight flags to correct the state,
  and — if a hover was already running — drops to `idle`, releases the attack hold and re-runs
  `_beginEscape()`, which now falls through to the grounded retreat (`pulling`, or the
  shield-in-place fallback with no route; a test that asserted it should land back in
  `recovering` was the thing that was wrong). **Per-ripple, not per-run** (user call): the
  denizen that dragged us lives on this ripple and will do it again, but the next ripple is a
  different room set — `S.onRipple` clears `S.grounded`.
- **Burning rooms** (v4.7.167): `The area is ablaze!` in the room text, then *"The roaring
  inferno engulfs you as you fight to find a way out."* for ~800 every few seconds,
  indefinitely — ~6% of max HP a tick on top of whatever the denizens are doing. `M.roomAblaze()`
  (fed by trigger `mnemosyne/049` -> `M.onAblazeBurn`, in `004_Parsers.lua`) latches on the
  **burn line, not the room description**: the description arrives mid-line ("The sky darkens
  with the onset of night. The area is ablaze!"), and more importantly the burn line is the
  thing that proves the fire is still hurting *us* — so a lazy `ABLAZE_STALE` (12s) expiry
  clears it when we leave, with no "the fire goes out" line, which we have never captured. It
  gates the **hover** only: flying up to heal is a fine plan in a normal room and a bad one
  over a fire that follows you, since the hover then spends its whole budget out-healing the
  floor and lands no better off. (Contrast the Blazing affix's ~511 asphyxiation per 5s, which
  the hover was measured to out-heal — same mechanism, smaller number.) The **kite is
  deliberately not gated**: it lands for every swing anyway, so it is not a way of avoiding the
  ground, and grounding a kite mid-swarm is worse. The gate is on *going up* — an
  already-airborne kite still converts to a hover in place (`_convertToHover`), the cheaper of
  the two evils.

**The general rule** the drag cost us, worth carrying forward: *an optimistic state flag
cleared only by a CONFIRMATION line becomes a livelock the moment something makes that
confirmation impossible.* `S.flying` was right to be optimistic (a queued fly can be eaten)
and the re-send loop was right to keep trying — but between them they had no way to represent
"this will never confirm". Such a flag needs a third input: the line that says the thing can
never happen at all.

**Tactical moves never condemn exits**: `M._tacticalArm(dir)` sets `explore.moving` +
`explore.tacticalMove`; the three condemn paths (move-timeout give-up, ice-slip cap,
`Room.WrongDir`) skip the `explore.failed` write when the flag is up — these are WALKED edges,
condemning them would poison the sweep — and notify `swarm.onMoveFailed()` instead.
`M._disarmMove()` is the no-callback cancel (emergency escape owns the teardown).

**Resets** (`swarm.reset`): boon screen (every ripple ends there), `_exploreStop`
(death/leave-tower/off), `basher disabled`, `sysLoadEvent` (plus load-time clears of
`ataxiaTemp.swarmHold`/`swarmPullDir` — they'd otherwise survive a SYSUPDATE and silently gate
the basher). `swarm.onRipple` (exploreOn/_exploreResume) wipes per-ripple pull budgets and the
dragged-down `grounded` latch.

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


### The movement lock (v4.7.243)

> "If we tumble and then leap or walk in a direction it cancels the tumble." — user, 2026-08-10

A tumble is a **two-stage action spanning ~4 seconds** (`You begin to tumble agilely to the <dir>.` → `You tumble out of the room.`), and any other movement inside that window cancels it. Five of our own paths could send one, so movement is now **serialised**:

```lua
function S.moveLocked()
  return (ataxiaTemp and ataxiaTemp.tumbleDir ~= nil) or false
end
```

It reads state that already existed — `ataxiaTemp.tumbleDir`, armed by `S.onTumbleStart` and released by `S.onTumbleDone` (the game's own completion line via `misc_alerts/005`, or the `S.TUMBLE_CONFIRM` = 5s fallback) — so there is no second lifecycle to keep in sync.

Guarded sites: `_tacticalGo`, `_beginPull`'s arm-timeout fallback, `_maybePanic`, `_beginEscape`'s hover branch, `_beginReenter`'s wall branch, the mid-recovery tumble, and in the explorer `_exploreMove`, `onIceSlip`, `onWallBlocked`.

**`S.onVitals` is the one that mattered.** A Roll Hide pull tumble leaves `S.state == "pulling"`, and the only early return in `onVitals` is the `recovering` one — so two seconds into a four-second tumble it fired `cq all` + `_beginEscape` → `stand;leap <dir>`, throwing away a tumble that was about to land. It is also the single path independent of every existing hold, which is what makes it valuable *and* dangerous.

`_maybeTincture` sits **outside** the lock, deliberately: healing is not movement, and mid-tumble at crash HP is when it is worth most.

Also cleared on `sysLoadEvent` alongside `escapeMode` — both are timer-backed and the timers do not survive a reload.

### The tumble chain, and the line that says a tumble failed (v4.7.245)

> "Seems like tumble is a tad bit broken." — user, 2026-08-10

Live log: **four tumbles in nineteen seconds**, four rooms, while the Ablaze affix took ~1,200 per tick. HP 31% → 14% and stuck — *a recovery that keeps moving never recovers*. Two causes, neither of them the movement lock, which behaved correctly: these were **sequential** tumbles, not concurrent ones.

**Cause 1 — the mid-recovery tumble decided on a stale denizen list.** `M._roomHasDenizens()` reads `ataxia.denizensHere`, fed by gmcp `Char.Items`, which lags the room change. The recovery tick that fires *on arrival* therefore reads the room we just left. The arrival rooms in the log name no denizens at all ("Glowing pools of heat", "Upon a sluggish stream") — Roll Hide had shed the pursuers exactly as advertised, and we fled an empty room three times.

Same class as the v4.7.125 catch (airborne `Char.Items` reflects the sky, so a mob-filled ground room reads as clear), sign flipped. The explorer already carries a settle window for this; the swarm's recovery branch did not.

| Guard | Value | Why |
|---|---|---|
| `S.ARRIVE_SETTLE` | 1.5s from the tumble **resolving** (stamped in `onTumbleDone`) | inside it the tick is consumed and re-scheduled, not decided — the next look is at real data |
| `S.RECOVER_TUMBLES` | 2, **per recovery** | Roll Hide sheds pursuers, so a third tumble means our reading of the room is wrong; every hop pays the affix damage again and heals nothing |
| `since >= 0` | — | a future-dated stamp cannot hold the settle open. Impossible on a monotonic clock, but the failure direction — silently disabling the re-tumble forever — is the one that hurts |

Past the budget we fall through to standing and fighting, which the v4.7.233 comment already argues is better than being attack-gated while something hits us.

**Cause 2 — `You cease your tumbling.` was never wired to anything.** `misc_alerts/003` has printed a banner and sent `cq all` for a long time without ever telling the swarm. So a cancelled tumble was invisible to the only system that depends on tumbles landing: `ataxiaTemp.tumbleDir` stayed set until the `TUMBLE_CONFIRM` fallback expired — and since v4.7.243 made that state a **movement lock**, those were seconds in which nothing could move at all.

The log measures the cost: cancel at **11:40:41.115**, retry at **11:40:45.938**. Four and a half seconds at 14% HP in a burning room, waiting out a timer, while the line that said *this failed* was already on screen in a box.

`S.onTumbleCanceled()` retries immediately, sharing `S._tumbleRetry()` with the timer path so both honour `TUMBLE_RETRIES`. It is ordered **after** the trigger's existing `cq all` — that flush would otherwise wipe the retry it is about to queue — and is inert outside Mnemosyne and when no tumble is tracked, so the manual/PvP uses of the line are unaffected.

**A fallback timer is for when the game says NOTHING. When it names the failure, use it.**

### Boiling lava - the only unconditional "leave now" (v4.7.254, hardened v4.7.256)

```
Molten lava bubbles and churns. ...
You splash into boiling lava!
Health lost: 5890 (unblockable).
You continue to struggle in the boiling grasp of the lava as it eats away at your body.
```

**5,890 unblockable per tick against a 10,939 pool** - 54% of the pool, two ticks is a death,
and *unblockable* means no shield, no barrier, no resistance. Ablaze is ~1,200 and merely gates
the hover; this cannot be traded with at all.

**It is the exception to the validated-route rule.** The escape ladder refuses unvalidated exits
by user decision (v4.7.243) because a wrong door costs a move and some HP. Here staying costs
half the pool per tick, so any door beats the floor - including one we have never walked.

| | |
|---|---|
| Exit order | back the way we came (provably safe - we just stood there) -> any planar exit not into a known lava room -> any planar -> `down` |
| Attack hold | escape mode, so the next `queue addclearfull` cannot wipe the move |
| Tactics | any swarm tactic in flight is reset - a funnel is a plan for a room we can survive |
| Repeat | re-sends every tick; an eaten move must be retried against a two-tick death |
| No exit known | `ql` (the exits line is parsed) and **MOVE MANUALLY** - the one case the sweep cannot save us from |

Both lines are used: the splash is entry, the struggle is the tick, and the tick fires without
an entry line when we were already standing in it.

#### v4.7.256 - the death, and why marking the room was not enough

Marking the lava room caught the unexplored-exit chooser. **Three other paths still led back
in**, and the log shows all of them inside twenty seconds:

| Path | Why |
|---|---|
| Sweep **backtrack** | once the room was walked, its exits stopped counting as unexplored - but the unexplored exit *beyond* it made lava the shortest path, and `MAP.path` has no hazard filter |
| `S._backDir` | the room we came from is normally the safest square on the grid |
| `S._panicDir` | avoided icewalls and the forward edge, not lava |

**Remember the EDGE, not just the room.** Room-keyed marking is unusable from the room next
door: `_exitTarget` returns nil whenever gmcp has not filled a destination id, which is exactly
the case for a neighbour we have not visited. At the instant we splash we know which room we
came *from* and which way we walked - `M.explore.lavaEdges[from][dir]` needs no id from anyone.
Shared predicates `M.roomIsLava` / `M.edgeIsLava` now feed all four consumers.

The backtrack checks only the **first step**: every step is re-decided on arrival, so a route we
never enter is a route we never traverse. `S._backDir` returning nil drops the ladder to
shield-in-place - bad, and not fatal. **"We walked through it" is not the same fact as "it is
survivable."**

Both exit scans are **sorted**, because an unordered choice makes the log unreadable *and* made
the guards untestable.

#### The witness, not the intent (v4.7.262)

The `from ~= cur` guard shipped in v4.7.256 was **not an adjacency check** — every other room on
the grid satisfies it — and the bill arrived as a phantom refusal:
`67777 northwest: leads into lava`, on a door the user glanced through and found an ordinary room.
There had never been lava there.

`M.explore.fromRoom` / `fromDir` are a record of the move we last **ARMED**. Nothing on any arrival
path confirms, rewrites or clears them, so after any *unarmed* room change — panic tumble, recovery
tumble, drag, forced move, and the lava escape itself — they name a room we are not next to, and
the next lava tick condemns an edge out of *that* room permanently.

The map already knew the truth and never published it. `MAP.onRoom` resolves the traversed
direction for **every** arrival however caused (it survives a tumble because `MAP._lastMoveDir` is
captured from `sysDataSendRequest`, which sees `...;tumble ne` exactly as it sees `...;nw`) and
then *proves* adjacency by writing the edge both ways. It now publishes `MAP._lastArrival`, and
**`M._inbound()` is the single owner of "how did we get into this room"**: prefer the witnessed
arrival, accept the armed pair only where the map can corroborate it, and return the **reason**
when it cannot — echoed in red at the moment the edge is declined.

Four more faults surfaced in the same code, all confirmed by executing the real modules:

- **A trailing struggle tick spoke for a room we had already left.** The splash is the ENTRY, the
  struggle is the TICK, and they shared one script with no way to tell them apart — so a buffered
  tick processed after the escape's `gmcp.Room` marked the *safe* room we had just reached and
  condemned the escape edge. Trigger 064 now passes `line`. Bounded at **one** discarded tick: a
  second identical tick means we really are burning and the entry line was missed, so it is
  adopted. **Never raise `LAVA_STRAY_TICKS` above 1** — two discarded ticks is 11,780 unblockable.
- **The escape flipped direction mid-episode.** `_tacticalArm` overwrites `fromDir` with the
  *escape* direction, so from tick 2 "back the way we came" resolved to its OPPOSITE. Since each
  send is `queue addclear` (it *replaces* the queued line), the last tick before balance is the one
  that executed — a coin flip over which way we left, re-flipped every tick, and invisible because
  only tick 1 prints a banner. The door is now chosen **once per episode** and re-validated.
- **The banner never re-armed** (`first` was `not ataxiaTemp.mnemLavaAt`, and nothing nils that
  stamp), so every lava episode after the first in a session was silent — a large part of why
  phantom marks accumulated unnoticed.
- **`_beginPull` armed a move it then never sent** — the arm ran *before* the `moveLocked()` bail.
  A bail must precede the state it would strand.

**Marks are records, not booleans** (`at`, `ripple`, `cur`, `why`), `_stepRefusal` names *which* of
the two independent lava facts fired (a remembered inbound edge, or a known lava destination room —
different repair paths), and `mnem explore why` prints the whole ledger.

#### Ripple-scoped, because a room number is not a place (v4.7.260)

The tower draws each ripple's 4×4 from a **pool of real rooms**, so the same gmcp id returns on a
later level with a different layout and different affixes. `lavaRooms`, `lavaEdges`, `failed` and
the boss-chase counter are all keyed by room number and were cleared **only on a package reload** —
so lava learned on one level condemned that id for the rest of the session.

`M.onRippleReset()` hangs off `MAP.reset()`, which already draws exactly that line (ripple change +
fresh tower entry). **When you add a table keyed by an id, name the scope in which that id means
something, and clear it there.**

**Residual, by design:** if a lava room is the only route to unexplored territory the sweep
refuses and returns nil, so a ripple can end partially swept. That is the intended trade.

### A boss that runs away (v4.7.255)

```
Lyaeus, the travelling bard flails in panic.
His fingers plucking a plaintive melody on his lyre, a satyri bard strolls out to the southeast...
```

**The two lines name him differently** - proper name on the panic, generic denizen description
on the departure. Neither suffices alone: the panic says *who*, the departure says *where*, and
they are paired within `PANIC_WINDOW` (6s). A boss ripple only ends when the boss dies, so a
boss that walks out is not a fight we can decline - the opposite of every other "should we
move?" decision here.

`M._chaseRefusal(dir)` is split from the send so the decision is testable and every refusal is
named: `nothing panicked recently`, `escaping` / `recovering` / `lava`, `too hurt to chase`,
`chase budget spent` (4/ripple), `basher off`, `not in the tower`. **Never chase while leaving**
- adding a pursuit to a retreat is how a retreat becomes a death. The HP guard is **defaulted**
(35) rather than conditional, because a guard that evaporates on a missing config key would
chase at crash HP on a fresh profile.

**Two grammars** (v4.7.272). `out to the <direction>` was Lyaeus's wording, not a shared one:
`Celepharn, High Priest of Life` departs as `The muted rustling of fabric accompanies Celepharn as
he departs east.` -- a different syntactic FRAME, so the panic latched, the departure never matched
and the boss walked. The pattern is now `(?:out to the|departs?(?: to the)?)\s+<dir>`. **One boss is
not a sample** -- the generalisation held on the verb axis and failed on the frame axis.

The line is passed to `M.onDenizenFled(dir, line)` as corroboration that can only STRENGTHEN:
Celepharn's departure names him, Lyaeus's names nobody ("a satyri bard"), so a match proves identity
and a non-match proves nothing and is still followed. `M._fledLineNames` compares the FIRST WORD of
the panicked name, since the panic line carries a comma-title the room line does not repeat. The
follow echo reports which evidence fired -- proof by name, or inference from the 6s window.

Trigger `mnemosyne/066` matches the **fragment** with the directions
enumerated - every denizen words its exit differently ("strolls", "prowls", "stomps"), and
enumerating verbs gives a trigger that works for the boss you captured and silently misses the
next. Safe because it decides nothing on its own.

### A tumble in flight is not "nowhere to go" (v4.7.252)

The mid-recovery re-tumble computed its direction as

```lua
local dir = (not S.moveLocked()) and (spent < budget) and mnemRollHide and S._panicDir()
```

and the fall-through below treated a falsy `dir` as *we cannot leave* — handing back to the
basher. So while a tumble was **mid-air** the v4.7.243 move lock made `dir` falsy and the
recovery was abandoned, the attack hold cleared, and we fought on with the escape still
resolving. The log times it: tumble east at 13.736, "nowhere to go — handing back" at 14.841,
two attack rounds, then "You tumble out of the room."

Four conditions were `and`-ed into one value and the else-branch gave them all the same meaning
— but **"already leaving" means WAIT and "no route" means GIVE UP**. The lock now consumes the
tick and re-schedules; a genuine dead end still hands back, because standing attack-gated while
something hits us is the one thing worse than trading.

### Truthseeker: phantom `?` wedge the same gate (v4.7.257)

`S._afflicted()` also reads `ataxia.afflictions.unknown > 0` as a real affliction. That counter
only ever goes **up** in `gotUnknownAff` -- nothing decrements it -- and under the **Truthseeker**
boon ("perceive the truth of all hidden afflictions") there are no hidden afflictions, so every
increment is a phantom. A live screenshot showed ~20 banked: `S._reenterReady()` could never
pass and every hover burned its full 60s cap for the rest of the run.

Same failure as manaleech below, reached by a different field, which is the point -- this gate
has now been wedged shut twice by inputs that were never real afflictions. Fixed at the
**source** (`gotUnknownAff` returns before even arming its next-line capture) rather than in the
gate, because the boon means the input is wrong and the prompt and the `diagnose` trigger read
it too. The flag-setting paths also clear what is already banked, since they are how the flag
returns after a reload or mid-run re-latch.

### Manaleech must not hold a recovery (v4.7.252)

`manaleech` is a real affliction at PvP priority 13 — under the PARKED floor, so `parkedAff`
did not excuse it. While it was up `S._afflicted()` was permanently TRUE, `S._reenterReady()`
could never pass, and **every hover burned its full 60s cap**. In the tower it is re-applied
faster than it is cured, so that is not a wait that ends.

It is now in `AFF_IGNORE` beside the kept defences, and the reasoning generalises: the cost runs
the *opposite* way from every other affliction there. Blindness or a broken limb is a state that
waiting **fixes**; a leech is a state that waiting **pays for**. Only the first belongs in a gate
whose action is "stand still longer" — especially as mana is a kill condition for several routes.

### Escape mode (v4.7.243)

> "We should've stopped attacking here and put a priority on leaving the room." — user, 2026-08-10

Before this there were three ad-hoc holds — `swarmHold` (8s), `bardComposeHold` (3s), `phialHold` (4s) — armed inconsistently, and `_beginReenter` and `_beginPull`'s fallback armed nothing at all. Each really means "protect *this* queued command", not "we are leaving".

`ataxiaTemp.escapeMode` is the single authoritative answer, read by **both** `ataxiaBasher_attack()` and `ataxiaBasher_tryAttack()`. (`tryAttack` was also missing `bardComposeHold`/`phialHold` entirely: `attack()` returns immediately for them, but reaching it still burns the 0.3s re-queue cooldown — which is what makes the next real dispatch late.)

| Armed at | Why |
|---|---|
| `S._tacticalGo` | the choke point **every** tactical move passes through — escape, retry, re-entry |
| `S._maybePanic` | the Roll Hide tumble |
| `_beginPull`'s no-swing fallback | this branch armed nothing at all before |
| `S._onPullSent` | the pull chain is now queued and another `addclearfull` would wipe it |

| Cleared by | Why |
|---|---|
| `S.escapeCheckRoom` on `gmcp.Room` | the room number changing is the **only** real proof we got out |
| `S.reset` | the tactic is over either way; a new escape re-arms it |
| `S.ESCAPE_MODE_MAX` (12s) | a wedged escape must never mute the basher indefinitely |
| `_beginEscape`'s no-route branch | fighting in place is then the best answer available |

Two placements are load-bearing:

- **It arms at `_onPullSent`, never `_beginPull`.** A pull's escape *rides* the next attack — `ataxiaTemp.swarmPullDir` decorates the assembled round into `<attack>;<backdir>` as one queued line. Gating attacks at arm time would starve the very swing carrying the step-out, and every pull would degrade to its timeout fallback. A guard that disables the feature it protects.
- **`_beginEscape` clears it when `_backDir()` returns nil.** Indoors with no validated route back, shield-in-place is the fallback and muting the basher there would be lethal.

The room-change handler is registered on `gmcp.Room` in 009 itself, **not** inside the explorer's handler, which is gated on `M.explore.on`: a flag that mutes the basher must not depend on a second subsystem still running in order to be released.

### The danger alarm now runs here too (v4.7.243)

`ataxiaBasher_isDamageRateExtreme()` is called from `S.onVitals` (as well as from `dangerLevel()` for non-tower bashing). `onVitals` runs on every prompt and reads none of the holds, so the alarm keeps working while an escape is in flight — which is exactly when it went silent before. It ORs with the HP gate: the HP gate answers "we are nearly dead", this answers "we will be dead in six seconds", and at ~2,150 HP/s that fires at ~12,000 HP rather than at 1,024. See `basher/05-safety-systems.md` for the rewrite itself.

### The thrall grasp lines (v4.7.243)

`As the thrall draws near, it wildly grasps at your arms and legs, disrupting your focus.` and `A mindless thrall hurls itself at you in a frenzy, disrupting your countermeasures.` matched **nothing** in the package until now — the mechanic eating our escapes was invisible in the logs. Both come from the **Necromantic** affix ("Denizens may revive as mindless thralls"), captured in v4.7.196 and deliberately left unhandled pending observation.

Trigger `denizen_attacks_misc_lines/025_Thrall_Move_Disruption` stamps `ataxiaTemp.moveDisruptedAt` and echoes while a tactic is running. It **re-sends nothing**: with the movement lock, a disruption landing mid-tumble must wait for the lock to resolve, and a reflexive re-send is exactly the tumble-cancelling move the lock exists to prevent.

### The icewall we could not see (v4.7.243)

`An icewall is here, blocking passage to the <dir>.` was **highlight-only**, and `S.wallRaised` was written in exactly one place: optimistically, from our own `_escapeSuffix` send. So a wall we did not place — an affix's, a denizen's, or one of ours that survived a reload — was invisible to both consumers: `S.moveVerb` (which decides BACKFLIP vs LEAP, and only LEAP is confirmed to clear an icewall) and `S._panicDir` (which avoids tumbling into a walled edge).

`highlighting/001_Icewall` now captures the direction and writes `S.wallRaised[MAP.current] = <long dir>`. Keyed on the Mnemosyne map's current room, which is nil outside the tower — that is what keeps real-world rooms out of the table without a second area check.

## Re-latching boon flags (v4.7.188, guard corrected v4.7.192)

`M._relatchBoons()` sends `BOONS` once per run so every owned boon flag re-latches from the
list rows. It exists because the two normal latch signals -- the `BOON CLAIM` alias and a
BOONS row -- both miss a boon that was already owned before its handling shipped.

Called from `M.onRipple` **and** both explorer entry points. The onRipple call is what covers
manual-mode users, who never touch `mnem explore` and would otherwise never re-latch.

The once-per-run guard is on **`ataxiaTemp`**. It was originally on `ataxia.mnemosyne`, which
is serialized -- so after a reload the guard came back `true` from disk while the bare-global
boon flags came back `nil`, and the relatch silently no-opped on precisely the path it was
built for.

## Wearing armour before a dive (v4.7.175)

`M._wearArmour()` sends `WEAR ARMOUR`, and is called from **both** explorer entry points:

- `M.exploreOn()` — the explicit `mnem explore on`.
- `M._exploreResume()` — the **per-ripple** entry. `GO` calls it after every boon screen.

The second is the one that earns its keep. A run is 5–25 ripples, so wiring only the explicit
turn-on would have covered a small fraction of the actual exposure. **General rule for this
module: a start-of-work safety belongs on both — `exploreOn` is the session start,
`_exploreResume` is the loop.**

Sent **directly, not queued**: the basher rebuilds its command every prompt with
`queue addclearfull`, which wipes queued lines — the same reason the hyena/falcon passive
orders and the disarm recovery bypass the queue. `WEAR` costs no balance, so it rides any
round.

Deliberately **not** gated on a "already wearing?" check. There is no reliable worn-state to
read, and the failure mode of guessing wrong — skipping the wear because we believe armour is
on — is exactly the situation this exists to prevent. An unconditional free command is the
better trade.

Consequence: `"You are already wearing this item."` prints once per ripple in the common
case. Left **ungagged** — it is a real refusal line, and silencing it would also bury the
pre-existing login-path double-send found in the v4.7.167 audit.


## Post-clear pacing holds (v4.7.196)

Two affixes make the moment a room goes quiet the *worst* moment to walk, so `_exploreTick`
carries two post-clear holds. Both re-check every 1.5s, both echo once on engaging, and both
gate on 90% HP (`HAEMO_MOVE_HP`). Either one holding is sufficient; Haemophiliac is evaluated
first only so its echo wins when both are up.

| affix | predicate | waits on |
|---|---|---|
| Haemophiliac | `M._haemoHold()` | bleed clotted (`< 50`) **AND** HP >= 90 |
| Last Word | `M._lastWordHold()` | HP >= 90 only |

The difference is the damage's shape, and it matters: haemophiliac damage is a **bleed** that
SSC clots down (`curing clotat 30`), so standing still is doing work. A Last Word explosion is
**instantaneous** -- there is nothing to clot, only HP to regain, so waiting on a bleed reading
would just idle the sweep. At 95% HP with 900 bleed the haemophiliac hold holds and the Last
Word hold does not.
