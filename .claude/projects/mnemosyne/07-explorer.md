# Auto-Explorer

`mnem explore` sweeps a Mnemosyne ripple hands-free: it walks the fixed 4×4 room grid, lets the autobasher clear the denizens in each room, and **stops the instant the boon-selection screen appears** so you pick a boon and wade deeper. It writes no attack logic — it only navigates. One file: `008_Explorer.lua`, everything hanging off `ataxia.mnemosyne` (`local M`) and reusing the ripple map's graph API (`local MAP = ataxia.mnemosyne.map`).

## Division of labour

The explorer deliberately owns nothing about combat. Two existing systems do the fighting and the mapping; this module is only the glue that decides *when to step and where*.

| Concern | Owner | How |
|---------|-------|-----|
| **Combat** | the autobasher in **MANUAL** mode | Manual mode attacks whatever is in the room but never mapper-moves (its auto-move is Mudlet-mapper based and can't route the unmapped tower). No-flee/shield is already handled by `ataxiaBasher.inMnemosyne` — see the [basher no-flee doc](../basher/05-safety-systems.md#no-flee-areas) |
| **Mapping** | the ripple map (`005_Ripple_Map.lua`, `MAP`) | The 4×4 room graph, unexplored-exit detection and BFS pathfinding are all reused, not reimplemented — see [04-ripple-map.md](04-ripple-map.md) |
| **Navigation** | this module | One move per room-clear, toward the nearest unwalked exit; stop on the boon screen |

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

The loop is event-driven, not polled. Handlers on `gmcp.Room` (arrival) and `targets updated` (a denizen killed / left / arrived) fire a **debounced** `_scheduleTick`, which waits `TICK_DELAY` for the room contents to settle and then runs the single decision function `_exploreTick`.

```
gmcp.Room / targets updated
      │
      ▼
_scheduleTick()  ── tempTimer(TICK_DELAY) ──▶  _exploreTick()
```

```
_exploreTick():
  not explore.on            -> return
  not inMnem()              -> _exploreStop("left Mnemosyne")
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
| the sole exit of a room with **no planar exit at all** (even if non-planar) | — | The ripple's entry is a *holding room whose only exit is `down`* into the 4×4; without this exception the sweep couldn't even descend into the grid (it instantly reported "fully swept") |
| not in `explore.failed[num]` | condemned exits | So a timed-out wall isn't retried, and a room whose only unexplored exits are failed counts as swept (no infinite backtrack) |

The vertical-exit rule reduces to: take `up`/`down`/`in`/`out` **only from a pure-vertical room** (the holding room), never from a 4×4 room (which always has planar exits). The same `usableUnexplored` gates both the current-room pick **and** backtrack candidacy, so "does this visited room still have somewhere to go?" has exactly one definition. Backtracking uses `MAP.path`, which is BFS over **walked edges only**, so the explorer only ever routes back through doors it has confirmed by walking.

## Stop conditions

| Trigger | Path | Notes |
|---------|------|-------|
| Boon screen appears | `M.onBoonScreen()` → `_exploreStop("boon screen")` | The ripple is complete. Called straight from the boon-offer trigger **regardless of telemetry state**, so it stops even with reporting off |
| Left Mnemosyne | `_exploreTick` → `_exploreStop("left Mnemosyne")` | `inMnem()` is the **strict** check `ataxiaBasher.inMnemosyne == true`; the room-update clears that flag the instant you enter any real (mapped) area, so the sweep stops walking/fighting immediately |
| Grid fully swept | `_nextExploreStep()` returns `nil` → `_exploreStop("grid fully swept")` | No reachable room has a usable unexplored exit |
| Manual off | `mnem explore off` → `M.exploreOff()` | |
| Reload / auto-update | `sysLoadEvent` handler marks it off | See [Reload safety](#reload-safety) |

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

## Safety extras

### Stall watchdog

`M._armWatchdog()` arms `M._explWatchT` for `WATCHDOG` seconds and is **re-armed on every progress event** (arrival, denizen change). If it ever actually fires, nothing progressed for that long:

- room still has denizens → echo a hint that the basher may be mid-fight (`mnem explore off` if stuck) — a wandered-in unlearned mob or a hard affliction can park a room;
- room is clear but somehow parked → nudge `_exploreTick` to re-decide.

It never hard-stops on its own; it re-arms and keeps watching.

### Reload safety

`M` and `M.explore` persist across an uninstall→install, but the tempTimers do not — so a live sweep would be left half-alive with the basher still force-mutated. The `sysLoadEvent` handler zeroes `explore.on`/`explore.moving` and drops `_prevBasher`, so a reload never resurrects a partial sweep; you re-issue `mnem explore on`.

### Progress echoes

The sweep narrates itself (`M._exploreEcho`, prefix `[explore]`) so you can follow it live:

- each step: `room clear -> moving <dir>.` (a stalled retry echoes `retrying <dir> (no arrival)`);
- once per occupied room (tracked by `explore.fightingRoom`, not every tick): `clearing this room (N denizen(s)) -- basher on it.` — `N` from `denizenCount()` (killable, own-denizen-excluded);
- the start / stop / boon-screen / fully-swept transitions each announce themselves.

## Tuning constants

| Constant | Value | Meaning |
|----------|-------|---------|
| `TICK_DELAY` | `0.5` | Debounce; let room contents settle after an event before deciding |
| `MOVE_TIMEOUT` | `5` | A move producing no arrival within this → retry / unstick |
| `MOVE_RETRIES` | `1` | Re-send a stalled move this many times before condemning the exit |
| `WATCHDOG` | `30` | Seconds of no progress before a soft nudge / notify |

## Commands

Dispatched from `003_Commands.lua`; a bare `mnem explore` toggles.

| Command | Function | Effect |
|---------|----------|--------|
| `mnem explore on` | `M.exploreOn()` | Start (guarded by `canStart`) |
| `mnem explore off` | `M.exploreOff()` | Stop and restore the basher |
| `mnem explore status` | `M.exploreStatus()` | Echo `on/off`, `inMnem`, `denizens`, `moving`, `next` |
| `mnem explore` | `M.exploreToggle()` | Flip on/off |

See [05-commands.md](05-commands.md) for the full `mnem` dispatch.

## Testing

The **pure logic** is unit-tested — `M._nextExploreStep` and `M._roomHasDenizens` are exercised directly against a mocked `MAP`/`ataxia.denizensHere`, locking in the pick-here-then-backtrack order, the planar/failed filtering, and the own-denizen guard. The **timer/event state machine** (debounced ticks, the `moving` guard, move timeout, watchdog) depends on live tempTimers and GMCP and is validated in-game.

---

See also: [04-ripple-map.md](04-ripple-map.md) (the `MAP` graph API this reuses), [05-commands.md](05-commands.md) (`mnem` dispatch), [01-architecture.md](01-architecture.md) (run lifecycle / gating).
