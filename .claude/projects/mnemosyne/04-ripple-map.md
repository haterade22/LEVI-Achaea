# Ripple Mini-Map

A per-ripple room mini-map, independent of telemetry. Each Mnemosyne ripple is a fresh room layout, so the map builds a room graph as you walk and wipes it each ripple. Mnemosyne is an unmapped instance (`gmcp.Room.Info.area == ""`), but `num`/`name`/`exits` still arrive, so rooms are plotted on a self-managed grid. Data model lives in `005_Ripple_Map.lua` (`ataxia.mnemosyne.map`, aliased `MAP`); the widget in `006_Ripple_Map_Window.lua`.

## Room Record

```lua
{ num, name, x, y,
  exits = {dir = dest|true},   -- every exit the game reports (dir -> dest id/true)
  edges = {dir = nbNum},       -- exits we've actually WALKED (dir -> neighbour num)
  visited = bool }             -- true once we've arrived (vs. a propagation stub)
```

`exits` vs `edges` distinguishes reported-but-unexplored exits from walked ones — used both for the gold "unexplored" markers and for BFS pathfinding over `edges` only.

## Direction Handling

| Table | Purpose |
|-------|---------|
| `MAP.OFFSETS` | Planar `dir → {dx, dy}` (+y = north). up/down/in/out are non-planar — tracked as edges, not placed on the grid |
| `MAP.OPPOSITE` | `dir → reverse dir` (records the back-edge on arrival) |
| `DIRNORM` | Any form (short/long) → canonical long form; via `MAP.normDir(d)` |
| `DIRSHORT` | Long → short form for sending moves; via `MAP.shortDir(d)` |

## Building the Graph (`MAP.onRoom`)

Called on each room arrival with `(num, name, exits, moveDir)`:

1. Create the room record if new (append to `MAP.order`); mark `visited=true`; update `name`.
2. Rebuild `room.exits` from the gmcp exits table (normalise dir keys; coerce dest ids to numbers so they compare against room nums).
3. **Determine the move direction** from `from` to here, in priority: explicit `moveDir` → gmcp exits-dest fallback (which `from` exit points at this num) → `MAP._lastMoveDir` (last movement command).
4. **Assign coordinates:** the first room becomes `origin` at `(0,0)`; otherwise `x/y = from + OFFSETS[dir]` when a direction and placed `from` exist.
5. **Record the traversed edge both ways** (`from.edges[dir]=num`, `room.edges[opp]=from.num`).
6. **`MAP._propagate(room)`** — the key trick.

### Topology propagation (`_propagate`)

The game reports each room's exits as `dir → neighbour num`. So once a room is placed, its neighbours can be positioned straight from the exit graph — **without knowing which way you moved**. `_propagate` creates each numbered exit-dest neighbour as an unvisited **stub** (coords only) at `room + OFFSETS[dir]`. Stubs gain a name/exits and start rendering only once actually visited. This is what makes the grid fill in reliably even when the movement direction is unknown (the fix in v4.7.44 — previously only the origin ever got coordinates).

## Pathfinding & Bounds

- **`MAP.path(fromNum, toNum)`** — BFS over **walked edges** only; returns a list of short-form direction steps, or nil if unreachable. Used by click-to-walk.
- **`MAP.unexploredExits(num)` / `hasUnexplored(num)`** — exits present in `exits` but not `edges`.
- **`MAP.bounds()`** — grid extent over **visited** rooms only (propagation stubs carry coords but must not stretch the grid).

## Per-Ripple Reset

| Hook | Trigger |
|------|---------|
| `MAP.reset()` | Clears `rooms`, `order`, `current`, `origin`, `_lastMoveDir` |
| `MAP.onRipple(n)` | On ripple change: `reset()`, set `_ripple=n`, **re-seed** the current gmcp room (the ripple line fires while you already stand in the new level's first room), then `render()` |

`onRipple` is called from the telemetry `onRipple` handler (`004_Parsers.lua`), independent of whether reporting is on.

## Runtime Hooks (`005`)

| Handler | Event | Behaviour |
|---------|-------|-----------|
| `MAP._sendHandler` | `sysDataSendRequest` | While `inMnem()`, capture the trailing direction word of outgoing commands into `MAP._lastMoveDir` (movement aliases send `".. <dir>"`); self-correcting |
| `MAP._roomHandler` | `gmcp.Room` | On a fresh Mnemosyne entry (`inMnem` newly true) reset; then `autoShow()`; while inside, `onRoom(...)` + `render()` |

**`MAP.inMnem()`** — true when `ataxiaBasher.inMnemosyne` is set **OR** a telemetry run is active. The survey flag is set opportunistically by the SURVEY line and can be missed between floors, so either signal counts.

## The Widget (`006_Ripple_Map_Window.lua`)

Draggable `Adjustable.Container` grid (`ataxia.mnemosyne.map.window`), position auto-persists (name-keyed). Built once at load and again on `sysLoadEvent` if `main` wasn't ready.

- **`GRID_MAX = 11`** cells per side; if the map is larger the view windows onto the current room.
- **Cell colours** (`STYLE`): current room green, rooms with unexplored exits gold-bordered with a `?`, others grey.
- **`MAP.render()`** — computes bounds, clamps to the `GRID_MAX` window centred on the current room, places one Geyser label per **visited** room (north/higher-y at the top), sets style/tooltip (room name), and a click callback.
- **Show/hide (`MAP.autoShow`)** — visible only when `MAP._enabled()` (config `mapEnabled`, default true) AND `inMnem()`. Note `autoShow` uses a local `inMnem()` that checks **only** `ataxiaBasher.inMnemosyne` (stricter than `MAP.inMnem()`).

### Click-to-walk (`MAP.walkTo`)

```lua
local steps = MAP.path(MAP.current, num)   -- BFS over walked edges
send("queue addclear free " .. steps[1])
for i = 2, #steps do send("queue add free " .. steps[i]) end
```

Queues moves via the game's **free queue** (same mechanism the movement aliases use) so they execute one per balance, in order. No known path → echoes an error (you may not have walked a route there yet).

## Diagnostics

`mnem map status` → `MAP.status()`: echoes `inMnem`, `enabled`, room/visited/placed counts, `current`, `lastMove`, `ripple`, `bounds`, and **dumps the current gmcp exits** (`dir->dest`) so you can see whether the game is handing back real neighbour room-nums (usable for placement) or unmapped placeholders.
